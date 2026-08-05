import unittest
from unittest.mock import Mock, patch

from main import ApplicationController


class ApplicationControllerShutdownTest(unittest.TestCase):
    def test_shutdown_stops_reading_and_test(self):
        controller = ApplicationController.__new__(ApplicationController)
        with (
            patch.object(controller, "stop_reading") as stop_reading,
            patch.object(controller, "stop_test") as stop_test,
        ):
            controller.shutdown()
            stop_reading.assert_called_once_with()
            stop_test.assert_called_once_with()

    def test_shutdown_calls_operations_in_expected_order(self):
        controller = ApplicationController.__new__(ApplicationController)
        calls = []
        controller.stop_reading = lambda: calls.append("reading")
        controller.stop_test = lambda: calls.append("test")
        controller.shutdown()
        self.assertEqual(calls, ["reading", "test"])

    def test_shutdown_can_be_called_twice(self):
        controller = ApplicationController.__new__(ApplicationController)
        with (
            patch.object(controller, "stop_reading") as stop_reading,
            patch.object(controller, "stop_test") as stop_test,
        ):
            controller.shutdown()
            controller.shutdown()

        self.assertEqual(stop_reading.call_count, 2)
        self.assertEqual(stop_test.call_count, 2)

    def test_shutdown_disconnects_can_service(self):
        controller = ApplicationController.__new__(ApplicationController)
        controller.read_stop_event = Mock()
        controller.worker = None
        controller.can_service = Mock()
        controller.test_worker = None
        controller.test_thread = None

        controller.shutdown()

        controller.read_stop_event.set.assert_called_once_with()
        controller.can_service.disconnect.assert_called_once_with()

    def test_stop_reading_keeps_worker_when_join_times_out(self):
        controller = ApplicationController.__new__(ApplicationController)
        controller.read_stop_event = Mock()
        controller.can_service = Mock()

        worker = Mock()
        worker.is_alive.return_value = True
        controller.worker = worker

        controller.stop_reading()

        controller.read_stop_event.set.assert_called_once_with()
        worker.join.assert_called_once_with(1000)
        controller.can_service.disconnect.assert_not_called()
        assert controller.worker is worker

    def test_stop_reading_disconnects_can_without_worker(self):
        controller = ApplicationController.__new__(ApplicationController)
        controller.read_stop_event = Mock()
        controller.worker = None
        controller.can_service = Mock()

        controller.stop_reading()

        controller.read_stop_event.set.assert_called_once_with()
        controller.can_service.disconnect.assert_called_once_with()
        assert controller.worker is None

    def test_shutdown_disconnects_can_when_no_worker_is_running(self):
        controller = ApplicationController.__new__(ApplicationController)
        controller.read_stop_event = Mock()
        controller.worker = None
        controller.can_service = Mock()
        controller.stop_test = Mock()

        controller.shutdown()

        controller.can_service.disconnect.assert_called_once_with()
        controller.stop_test.assert_called_once_with()

    def test_stop_test_clears_references_after_thread_stops(self):
        controller = ApplicationController.__new__(ApplicationController)
        worker = Mock()
        thread = Mock()
        thread.isRunning.return_value = True
        thread.wait.return_value = True
        controller.test_worker = worker
        controller.test_thread = thread

        controller.stop_test()

        worker.stop_process.assert_called_once_with()
        thread.quit.assert_called_once_with()
        thread.wait.assert_called_once_with(1000)
        self.assertIsNone(controller.test_worker)
        self.assertIsNone(controller.test_thread)

    def test_stop_test_keeps_references_when_thread_does_not_stop(self):
        controller = ApplicationController.__new__(ApplicationController)
        worker = Mock()
        thread = Mock()
        thread.isRunning.return_value = True
        thread.wait.return_value = False
        controller.test_worker = worker
        controller.test_thread = thread

        controller.stop_test()

        worker.stop_process.assert_called_once_with()
        thread.quit.assert_called_once_with()
        thread.wait.assert_called_once_with(1000)
        self.assertIs(controller.test_worker, worker)
        self.assertIs(controller.test_thread, thread)