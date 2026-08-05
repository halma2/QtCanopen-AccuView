import unittest
from unittest.mock import Mock

from canopen_app.measurement_processor import MeasurementSnapshot, Statistics
from canopen_app.ui_adapter import UiAdapter


class UiAdapterTest(unittest.TestCase):
    def setUp(self):
        self.root = Mock()
        self.adapter = UiAdapter(self.root)

    def test_publish_snapshot_emits_statistics_and_graph(self):
        snapshot = MeasurementSnapshot(
            voltage_statistics=Statistics(1, 2, 3),
            temperature_statistics=Statistics(10, 20, 30),
            graph_data=[2, 3],
        )

        self.adapter.publish_snapshot(snapshot)

        self.root.statDataSignal.emit.assert_called_once_with([1, 2, 3, 10, 20, 30])
        self.root.graphDataSignal.emit.assert_called_once_with([2, 3])
        self.root.groupDataSignal.emit.assert_not_called()

    def test_publish_snapshot_emits_requested_group(self):
        snapshot = MeasurementSnapshot(
            voltage_statistics=Statistics(1, 2, 3),
            temperature_statistics=Statistics(10, 20, 30),
            graph_data=[],
            group_voltages=[1, 2],
            group_temperatures=[20],
        )

        self.adapter.publish_snapshot(snapshot)

        self.root.groupDataSignal.emit.assert_called_once_with([1, 2], [20])

    def test_other_events_are_forwarded(self):
        error = RuntimeError("bus error")

        self.adapter.report_error(error)
        self.adapter.publish_ports(["COM1"])
        self.adapter.finish_test(True)

        self.root.errorEvent.emit.assert_called_once_with("bus error")
        self.root.portsSignal.emit.assert_called_once_with(["COM1"])
        self.root.testFinished.emit.assert_called_once_with(True)


if __name__ == "__main__":
    unittest.main()