import threading
import unittest
from unittest.mock import Mock

from canopen_app.can_service import CanServiceError
from canopen_app.measurement_processor import DiagramType
from main import ApplicationController


class _CanService:
    def __init__(self):
        self.connect_calls = 0

    def connect(self):
        self.connect_calls += 1

    def disconnect(self):
        pass


class ApplicationControllerThreadLifecycleTest(unittest.TestCase):
    def test_start_reading_can_be_called_again_after_worker_finished(self):
        controller = ApplicationController.__new__(ApplicationController)
        controller.can_service = _CanService()
        controller.read_stop_event = threading.Event()
        controller.read_stop_event.set()
        controller.worker = None
        controller.bus_reading = lambda: None

        controller.start_reading()
        controller.worker.join()  # ty:ignore[unresolved-attribute]

        controller.start_reading()
        controller.worker.join()  # ty:ignore[unresolved-attribute]

        self.assertEqual(controller.can_service.connect_calls, 2)

    def test_failed_connection_leaves_controller_ready_for_retry(self):
        controller = ApplicationController.__new__(ApplicationController)
        controller.can_service = Mock()
        connection_error = CanServiceError("offline")
        controller.can_service.connect.side_effect = [connection_error, None]
        controller.read_stop_event = threading.Event()
        controller.read_stop_event.set()
        controller.worker = None
        controller.ui = Mock()
        controller.bus_reading = lambda: None

        controller.start_reading()

        controller.start_reading()
        controller.worker.join()  # ty:ignore[unresolved-attribute]

        controller.stop_reading()
        self.assertIsNone(controller.worker)
        self.assertEqual(controller.can_service.connect.call_count, 2)
        controller.ui.report_error.assert_called_once_with(connection_error)

    def test_reading_error_disconnects_before_retry(self):
        controller = ApplicationController.__new__(ApplicationController)
        controller.can_service = Mock()
        controller.can_service.read_measurement.side_effect = RuntimeError("read failed")
        controller.processor = Mock()
        controller.diagram_type = 0
        controller.requested_group_id = None
        controller.time_sec_interval = 0
        controller.read_stop_event = threading.Event()
        controller.read_stop_event.clear()
        controller.worker = threading.Thread(target=controller.bus_reading)
        controller.ui = Mock()

        controller.worker.start()
        controller.worker.join()

        self.assertTrue(controller.read_stop_event.is_set())
        controller.ui.report_error.assert_called_once_with(
            controller.can_service.read_measurement.side_effect
        )
        controller.can_service.disconnect.assert_called_once_with()
        controller.can_service.disconnect.reset_mock()
        controller.stop_reading()
        controller.can_service.disconnect.assert_called_once_with()

    def test_start_test_does_not_fail_without_can_service(self):
        controller = ApplicationController.__new__(ApplicationController)
        controller.read_stop_event = Mock()
        controller.read_stop_event.set()
        controller.can_service = None
        controller.startup_error = CanServiceError("EDS file not found")
        controller.ui = Mock()

        controller.start_test()

        controller.ui.report_error.assert_called_once_with(controller.startup_error)

    def test_invalid_diagram_type_is_reported(self):
        controller = ApplicationController.__new__(ApplicationController)
        controller.diagram_type = DiagramType.AVERAGE
        controller.ui = Mock()

        controller.set_diagram_type(99)

        self.assertEqual(controller.diagram_type, DiagramType.AVERAGE)
        controller.ui.report_error.assert_called_once_with("Invalid diagram type: 99")

    def test_valid_diagram_type_is_converted_to_enum(self):
        controller = ApplicationController.__new__(ApplicationController)
        controller.ui = Mock()

        controller.set_diagram_type(4)

        self.assertEqual(controller.diagram_type, DiagramType.MIN_MAX)
        self.assertIsInstance(controller.diagram_type, DiagramType)
        controller.ui.report_error.assert_not_called()

    def test_processing_error_requests_stop_and_reports_error(self):
        controller = ApplicationController.__new__(ApplicationController)
        controller.can_service = Mock()
        controller.can_service.read_measurement.return_value = ([1.0], [20.0])
        controller.processor = Mock()
        processing_error = ValueError("invalid measurement data")
        controller.processor.process.side_effect = processing_error
        controller.diagram_type = DiagramType.AVERAGE
        controller.requested_group_id = None
        controller.read_stop_event = threading.Event()
        controller.read_stop_event.clear()
        controller.ui = Mock()

        controller.bus_reading()

        controller.ui.report_error.assert_called_once_with(processing_error)
        self.assertTrue(controller.read_stop_event.is_set())

if __name__ == "__main__":
    unittest.main()
