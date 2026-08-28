import sys
import threading
from os import path

import can.exceptions
import serial.tools.list_ports
from can import CanInitializationError
from canopen import SdoCommunicationError
from PySide6.QtCore import Property, QObject, QThread, Signal, Slot
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from canopen_app.can_service import CanService, CanServiceError
from canopen_app.connection_test import TestWorker
from canopen_app.measurement_processor import DiagramType, MeasurementProcessor
from canopen_app.ui_adapter import UiAdapter


class ApplicationController(QObject):
    portListChanged = Signal("QVariant")
    graphDataChanged = Signal("QVariant")
    groupDataChanged = Signal("QVariant", "QVariant")
    statVoltDataChanged = Signal("QVariant")
    statTempDataChanged = Signal("QVariant")
    testFinished = Signal(bool)
    errorOccurred = Signal(str)
    selectedGroupIdChanged = Signal(int)
    groupCountChanged = Signal(int)
    availablePortsChanged = Signal()
    busActiveChanged = Signal()
    busBusyChanged = Signal()

    def __init__(self, base_dir, eds_name):
        super().__init__()
        self.time_sec_interval = 1
        self.processor = MeasurementProcessor()
        self.diagram_type: DiagramType = DiagramType.AVERAGE
        self.requested_group_id = None
        self._selected_group_id = 0
        self._available_ports = []
        self.ui = UiAdapter(self)
        self.startup_error = None
        try:
            eds_path = str(path.join(base_dir, eds_name))
            self.can_service = CanService(eds_path)
        except CanServiceError as error:
            self.can_service = None
            self.startup_error = error
            self.ui.report_error(error)
        self.worker = None
        self.read_stop_event = threading.Event()
        self.read_stop_event.set()
        self._bus_state_lock = threading.RLock()
        self._bus_active = False
        self._bus_busy = False
        self.test_thread = None
        self.test_worker = None
        self.app = QGuiApplication(sys.argv)
        self.app.aboutToQuit.connect(self.shutdown)
        self.engine = QQmlApplicationEngine()
        self.engine.load(path.join(base_dir, "includes", "Main.qml"))
        self.engine.rootContext().setContextProperty("controller", self)
        if not self.engine.rootObjects():
            sys.exit(-1)
        self.search_ports()
        sys.exit(self.app.exec_())

    @Slot()
    def start_reading(self):
        self._ensure_bus_state()
        if self.can_service is None:
            if self.startup_error is not None:
                self.ui.report_error(self.startup_error)
            return
        with self._bus_state_lock:
            if self._bus_busy or self._is_can_connected():
                return
            self._set_bus_busy(True)
        try:
            self.can_service.connect()
            self.read_stop_event.clear()
            self.worker = threading.Thread(target=self.bus_reading, daemon=True)
            self.worker.start()
            self._set_bus_active(True)
        except (
            CanServiceError,
            CanInitializationError,
            can.exceptions.CanError,
            OSError,
            TypeError,
        ) as e:
            self.read_stop_event.set()
            self.worker = None
            self._set_bus_active(False)
            self.can_service.disconnect()
            self.ui.report_error(e)
        finally:
            self._set_bus_busy(False)

    @Slot()
    def stop_reading(self):
        self._ensure_bus_state()
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
        if worker is not None and worker is not threading.current_thread():
            worker.join(1.0)
        with self._bus_state_lock:
            if worker is not None and worker.is_alive():
                self._set_bus_busy(False)
                return
            if self.worker is worker:
                self.worker = None
            if self.can_service is not None:
                self.can_service.disconnect()
            self._set_bus_active(False)
            self._set_bus_busy(False)

    def bus_reading(self):
        try:
            while not self.read_stop_event.is_set():
                voltages, temperatures = self.can_service.read_measurement()
                snapshot = self.processor.process(
                    voltages,
                    temperatures,
                    self.diagram_type,
                    self.requested_group_id,
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

    def _ensure_bus_state(self):
        if not hasattr(self, "_bus_state_lock"):
            self._bus_state_lock = threading.RLock()
        if not hasattr(self, "_bus_active"):
            self._bus_active = False
        if not hasattr(self, "_bus_busy"):
            self._bus_busy = False

    def _is_can_connected(self):
        return getattr(self.can_service, "connected", False) is True

    def _set_bus_active(self, active):
        self._ensure_bus_state()
        if self._bus_active == active:
            return
        self._bus_active = active
        self._emit_signal(self.busActiveChanged)

    def _set_bus_busy(self, busy):
        self._ensure_bus_state()
        if self._bus_busy == busy:
            return
        self._bus_busy = busy
        self._emit_signal(self.busBusyChanged)

    def _emit_signal(self, signal):
        try:
            signal.emit()
        except RuntimeError:
            pass

    @Property(bool, notify=busActiveChanged)
    def bus_active(self):
        self._ensure_bus_state()
        return self._bus_active

    @Property(bool, notify=busBusyChanged)
    def bus_busy(self):
        self._ensure_bus_state()
        return self._bus_busy

    @Slot()
    def search_ports(self):
        ports = list(serial.tools.list_ports.comports())
        available_ports = []
        for p in ports:
            try:
                ser = serial.Serial(p.device, timeout=0)
                ser.close()
                available_ports.append(p.device)
            except serial.SerialException:
                pass
        self._available_ports = available_ports
        self.availablePortsChanged.emit()
        self.ui.publish_ports(available_ports)
        if self.can_service is None:
            return
        if (self.can_service.port and self.can_service.port in available_ports) or len(
            available_ports
        ) > 0:
            self.can_service.port = available_ports[0]
        else:
            self.can_service.port = None

    @Property("QVariant", notify=availablePortsChanged)
    def availablePorts(self):
        return self._available_ports

    @Slot(str)
    def set_port(self, new_port):
        if self.can_service is not None:
            self.can_service.port = new_port

    @Slot(int)
    def set_diagram_type(self, type_id):
        try:
            self.diagram_type = DiagramType(type_id)
        except ValueError:
            self.ui.report_error(f"Invalid diagram type: {type_id}")

    @Slot(int)
    def get_cell_group(self, group_id):
        self.requested_group_id = group_id
        if self._selected_group_id != group_id:
            self._selected_group_id = group_id
            self.selectedGroupIdChanged.emit(group_id)

    @Property(int, notify=selectedGroupIdChanged)
    def selected_group_id(self):
        return self._selected_group_id

    @Property("QVariant", notify=statVoltDataChanged)
    def statVoltages(self):
        return self.ui.stat_voltages

    @Property("QVariant", notify=statTempDataChanged)
    def statTemperatures(self):
        return self.ui.stat_temperatures

    @Slot()
    def start_test(self):
        if not self.read_stop_event.is_set():
            self.ui.finish_test(True)
            return
        if self.can_service is None:
            self.ui.report_error(self.startup_error)
            return
        if not self.can_service.port:
            self.ui.report_error("CAN-port is not selected!")
            self.ui.finish_test(False)
            return
        if self.test_thread is not None:
            return

        self.test_thread = QThread()
        self.test_worker = TestWorker(self.can_service.port, self.can_service.eds_path)
        self.test_worker.moveToThread(self.test_thread)

        self.test_thread.started.connect(self.test_worker.run)
        self.test_worker.finished.connect(self.ui.finish_test)
        self.test_worker.finished.connect(self.test_thread.quit)
        self.test_worker.finished.connect(self.test_worker.deleteLater)
        self.test_thread.finished.connect(self.test_thread.deleteLater)
        self.test_thread.finished.connect(self._test_finished)
        self.test_thread.destroyed.connect(self._test_thread_destroyed)
        self.test_thread.start()

    @Slot()
    def _test_finished(self):
        self.test_thread = None
        self.test_worker = None

    @Slot()
    def _test_thread_destroyed(self):
        self.test_thread = None

    @Slot()
    def shutdown(self):
        self._ensure_bus_state()
        self.read_stop_event.set()
        self._stop_reading_for_shutdown()
        self.stop_test()

    def _stop_reading_for_shutdown(self):
        worker = self.worker
        if worker is not None and worker is not threading.current_thread():
            worker.join(1)
        if worker is not None and worker.is_alive():
            self._set_bus_active(False)
            self._set_bus_busy(False)
            return
        self.worker = None
        if self.can_service is not None:
            self.can_service.disconnect()
        self._set_bus_active(False)
        self._set_bus_busy(False)

    @Slot()
    def stop_test(self):
        worker = self.test_worker
        thread = self.test_thread
        if worker is not None:
            worker.stop_process()
        if thread is None:
            self.test_worker = None
            return
        if thread.isRunning():
            thread.quit()
            if not thread.wait(500):
                return
