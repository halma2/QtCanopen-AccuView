import threading

import can.exceptions
import serial.tools.list_ports
from can import CanInitializationError
from canopen import SdoCommunicationError
from PySide6.QtCore import Property, QObject, QThread, Signal, Slot

from canopen_app.can_service import CanService, CanServiceError
from canopen_app.connection_test import TestWorker
from canopen_app.measurement_processor import DiagramType, MeasurementProcessor
from canopen_app.ui_adapter import UiAdapter


class ApplicationController(QObject):
    portListChanged = Signal("QVariant")
    graphDataChanged = Signal("QVariant")
    groupDataChanged = Signal("QVariant", "QVariant")
    statDataChanged = Signal("QVariant")
    testFinished = Signal(bool)
    errorOccurred = Signal(str)
    selectedGroupIdChanged = Signal(int)
    groupCountChanged = Signal(int)
    availablePortsChanged = Signal()

    def __init__(self, _eds_path):
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
            self.can_service = CanService(_eds_path)
        except CanServiceError as error:
            self.can_service = None
            self.startup_error = error
            self.ui.report_error(error)
        self.worker = None
        self.read_stop_event = threading.Event()
        self.read_stop_event.set()
        self.test_thread = None
        self.test_worker = None

    @Slot()
    def start_reading(self):
        if self.worker is not None and self.worker.is_alive():
            return
        if self.can_service is None:
            if self.startup_error is not None:
                self.ui.report_error(self.startup_error)
            return

        try:
            self.can_service.connect()
            self.read_stop_event.clear()
            self.worker = threading.Thread(target=self.bus_reading)
            self.worker.start()
        except (
            CanServiceError,
            CanInitializationError,
            can.exceptions.CanError,
            OSError,
            TypeError,
        ) as e:
            self.read_stop_event.set()
            self.worker = None
            self.can_service.disconnect()
            self.ui.report_error(e)

    @Slot()
    def stop_reading(self):
        self.read_stop_event.set()
        worker = self.worker
        if worker is not None and worker is not threading.current_thread():
            worker.join(1000)
        if worker is not None and worker.is_alive():
            return
        self.worker = None
        if self.can_service is not None:
            self.can_service.disconnect()

    def bus_reading(self):
        if self.can_service is None:
            return
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
            can.exceptions.CanOperationError,
            AttributeError,
            RuntimeError,
            ValueError,
        ) as e:
            self.ui.report_error(e)
            self.read_stop_event.set()
            self.can_service.disconnect()

    def shutdown(self):
        self.stop_reading()
        self.stop_test()

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
        except (TypeError, ValueError):
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

    @Slot()
    def start_test(self):
        if not self.read_stop_event.is_set():
            self.ui.finish_test(True)
            return
        if self.can_service is None:
            if self.startup_error is not None:
                self.ui.report_error(self.startup_error)
            return
        if not self.can_service.port:
            self.ui.report_error("CAN-port is not selected!")
            return
        if self.test_thread is not None and self.test_thread.isRunning():
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

    def stop_test(self):
        if self.test_worker is not None:
            try:
                self.test_worker.stop_process()
            except RuntimeError:
                self.test_worker = None
        if self.test_thread is not None:
            try:
                if self.test_thread.isRunning():
                    self.test_thread.quit()
                    if self.test_thread.wait(1000):
                        self.test_thread = None
                        self.test_worker = None
                else:
                    self.test_thread = None
                    self.test_worker = None
            except RuntimeError:
                self.test_thread = None

    @Slot()
    def _test_finished(self):
        self.test_thread = None
        self.test_worker = None

    @Slot()
    def _test_thread_destroyed(self):
        self.test_thread = None
