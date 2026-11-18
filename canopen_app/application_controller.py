import threading
from os import path
import sys

import can.exceptions
import serial.tools.list_ports
from canopen import SdoCommunicationError
from PySide6.QtCore import Property, QObject, Signal, Slot
from PySide6.QtQml import QmlElement

from canopen_app.can_service import CanService, CanServiceError
from canopen_app.measurement_processor import DiagramType, MeasurementProcessor
from canopen_app.ui_adapter import UiAdapter


def is_android_platform() -> bool:
    return hasattr(sys, "getandroidapilevel")

QML_IMPORT_NAME = "canopen_app"
QML_IMPORT_MAJOR_VERSION = 1
QML_IMPORT_MINOR_VERSION = 0

@QmlElement
class ApplicationController(QObject):
    graphDataChanged = Signal("QVariant")
    groupDataChanged = Signal("QVariant", "QVariant")
    statVoltDataChanged = Signal("QVariant")
    statTempDataChanged = Signal("QVariant")
    errorOccurred = Signal(str)
    selectedGroupIdChanged = Signal(int)
    groupCountChanged = Signal(int)
    availablePortsChanged = Signal()
    portChanged = Signal(str)
    busActiveChanged = Signal()
    busBusyChanged = Signal()

    def __init__(self):
        super().__init__()
        self.time_sec_interval = 1
        self.processor = MeasurementProcessor()
        self.diagram_type: DiagramType = DiagramType.AVERAGE
        self._selected_group_id = 0
        self._available_ports = []
        self.ui = UiAdapter(self)
        self.startup_error = None
        self._base_dir = path.dirname(path.dirname(path.abspath(__file__)))
        self._eds_name = "DS301_modified.eds"

        if is_android_platform():
            import canopen_app.app_controller_android_plugin as android
            android.init_android_serial(self)
        try:
            eds_path = path.join(str(self._base_dir), self._eds_name)
            self.can_service = CanService(eds_path)
        except CanServiceError as error:
            self.can_service = None
            self.startup_error = error
            self.ui.report_error(error)
        finally:
            self.worker = None
            self.worker_port_scanner = None
            self.read_stop_event = threading.Event()
            self.read_stop_event.set()
            self._bus_state_lock = threading.RLock()
            self._bus_active = False
            self._bus_busy = False
            self.search_ports()

    @Slot()
    def start_reading(self):
        if self.can_service is None:
            if self.startup_error is not None:
                self.ui.report_error(self.startup_error)
            return
        with self._bus_state_lock:
            if self._bus_busy or self.can_service.connected:
                return
            self._set_bus_busy(True)
        if is_android_platform():
            import canopen_app.app_controller_android_plugin as android
            android.start_reading_preps(self)
        try:
            self.read_stop_event.clear()
            self.worker = threading.Thread(target=self._worker_start_bus_reading, daemon=True)
            self.worker.start()
            self._set_bus_active(True)
        except RuntimeError as e:
            self.read_stop_event.set()
            self.worker = None
            self._set_bus_active(False)
            self.can_service.disconnect()
            self.ui.report_error(e)
        finally:
            self._set_bus_busy(False)

    def _worker_start_bus_reading(self):
        try:
            self.can_service.connect()
        except (can.exceptions.CanError, OSError, ValueError) as e:
            self.ui.report_error(e)
            self._set_bus_active(False)
            self._set_bus_busy(False)
            return
        self._worker_bus_reading()

    def _worker_bus_reading(self):
        try:
            while not self.read_stop_event.is_set():
                voltages, temperatures = self.can_service.read_measurement()
                snapshot = self.processor.process(
                    voltages,
                    temperatures,
                    self.diagram_type,
                    self._selected_group_id,
                )
                self.ui.publish_snapshot(snapshot)
                self.read_stop_event.wait(self.time_sec_interval)
        except (
                SdoCommunicationError,
                CanServiceError,
                can.exceptions.CanOperationError,
                can.exceptions.CanError,
                AttributeError,
                OSError,
                RuntimeError,
                ValueError,
        ) as e:
            self.ui.report_error(e)
            self.read_stop_event.set()
            self.can_service.disconnect()
            self._set_bus_active(False)
            self._set_bus_busy(False)

    @Slot()
    def stop_reading(self):
        with self._bus_state_lock:
            if self._bus_busy:
                return
            self._set_bus_busy(True)
        self.read_stop_event.set()
        worker = self.worker
        if worker is None or not worker.is_alive():
            self._finish_stop_reading()
            return
        threading.Thread(target=self._finish_stop_reading, daemon=True).start()

    def _finish_stop_reading(self):
        worker = self.worker
        if worker and worker is not threading.current_thread():
            worker.join(1.0)
        with self._bus_state_lock:
            if worker and worker.is_alive():
                self._set_bus_busy(False)
                return
            if self.worker is worker:
                self.worker = None
            if self.can_service is not None:
                self.can_service.disconnect()
            self._set_bus_active(False)
            self._set_bus_busy(False)

    def _set_bus_active(self, active: bool):
        if self._bus_active == active:
            return
        self._bus_active = active
        self.busActiveChanged.emit()

    def _set_bus_busy(self, busy: bool):
        if self._bus_busy == busy:
            return
        self._bus_busy = busy
        self.busBusyChanged.emit()

    @Property(bool, notify=busActiveChanged)
    def bus_active(self):
        return self._bus_active

    @Property(bool, notify=busBusyChanged)
    def bus_busy(self):
        return self._bus_busy

    @staticmethod
    def test_serial(port: str) -> bool:
        try:
            with serial.Serial(port):
                return True
        except (serial.SerialException, OSError):
            return False

    def get_serial_ports(self) -> list[str]:
        import canopen_app.bluetooth_class_check as bt_check

        ports = list(serial.tools.list_ports.comports())
        available_ports = []
        for p in ports:
            if p.name == "ttyS0": # Raspberry Pi
                continue
            if p.device == self.can_service.port and self._bus_active:
                available_ports.append(p.device)
                continue
            if bt_check.is_bluetooth_device(p):
                try:
                    if bt_check.check_bluetooth_class(p) == 0x1F00:
                        available_ports.append(p.device)
                        continue
                except (RuntimeError, FileNotFoundError): # input bt comport (no use) if MAC=0 (duplicated)
                    continue
            if ApplicationController.test_serial(p.device):
                available_ports.append(p.device)
        return available_ports

    def _worker_search_ports(self):
        self._available_ports = self.get_serial_ports()
        self.worker_port_scanner = None
        if self.can_service.port in self._available_ports:
            self.availablePortsChanged.emit()
            return
        self.can_service.port = self._available_ports[0] if len(self._available_ports) > 0 else ""
        self.availablePortsChanged.emit()
        self.portChanged.emit(self.can_service.port)

    @Slot()
    def search_ports(self):
        if not self.can_service or self.worker_port_scanner:
            return
        try:
            self.worker_port_scanner = threading.Thread(target=self._worker_search_ports, daemon=True)
            self.worker_port_scanner.start()
        except RuntimeError as error:
            self.worker_port_scanner = None
            self.ui.report_error(error)

    @Property("QVariant", notify=availablePortsChanged)
    def available_ports(self) -> list:
        return self._available_ports

    @Slot(str)
    def set_port(self, new_port):
        if self.can_service:
            self.can_service.port = new_port

    @Property(str, notify=portChanged)
    def current_port(self):
        return self.can_service.port if self.can_service else ""

    @Slot(int)
    def set_diagram_type(self, type_id):
        try:
            self.diagram_type = DiagramType(type_id)
        except ValueError:
            self.ui.report_error(f"Invalid diagram type: {type_id}")

    @Slot(int)
    def get_cell_group(self, group_id):
        if self._selected_group_id != group_id:
            self._selected_group_id = group_id
            self.selectedGroupIdChanged.emit(group_id)

    @Property(int, notify=selectedGroupIdChanged)
    def selected_group_id(self):
        return self._selected_group_id

    @Property("QVariant", notify=statVoltDataChanged)
    def stat_voltages(self):
        return self.ui.stat_voltages

    @Property("QVariant", notify=statTempDataChanged)
    def stat_temperatures(self):
        return self.ui.stat_temperatures
