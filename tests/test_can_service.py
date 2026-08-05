import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

from canopen_app.can_service import CanService, CanServiceError


class CanServiceTest(unittest.TestCase):
    def _service_with_measurement(self, voltage_bytes, temperature_bytes):
        network = Mock()
        network.add_node.return_value = Mock()
        network.add_node.return_value.sdo = {
            "Voltage": Mock(raw=voltage_bytes),
            "Temperature": Mock(raw=temperature_bytes),
        }
        with patch("canopen_app.can_service.Network", return_value=network):
            return CanService("valid.eds")
    def test_missing_eds_file_raises_can_service_error(self):
        with patch("canopen_app.can_service.Network") as network_type:
            network_type.return_value.add_node.side_effect = FileNotFoundError(
                "EDS file not found"
            )

            with self.assertRaisesRegex(CanServiceError, "EDS file not found"):
                CanService("missing.eds")

    def test_invalid_eds_file_raises_can_service_error(self):
        with tempfile.TemporaryDirectory() as directory:
            eds_path = Path(directory) / "invalid.eds"
            eds_path.write_text("not an EDS file", encoding="utf-8")

            with patch("canopen_app.can_service.Network") as network_type:
                network_type.return_value.add_node.side_effect = ValueError(
                    "invalid EDS"
                )

                with self.assertRaisesRegex(CanServiceError, "invalid EDS"):
                    CanService(str(eds_path))

    def test_disconnect_without_connection_is_safe(self):
        with patch("canopen_app.can_service.Network") as network_type:
            service = CanService("valid.eds")

        service.disconnect()
        service.disconnect()

        network_type.return_value.disconnect.assert_not_called()

    def test_disconnect_can_be_called_repeatedly_after_connect(self):
        network = Mock()
        network.add_node.return_value = Mock()
        with patch("canopen_app.can_service.Network", return_value=network):
            service = CanService("valid.eds")

        service.connect()
        service.disconnect()
        service.disconnect()

        network.sync.stop.assert_called_once_with()
        network.disconnect.assert_called_once_with()

    def test_read_measurement_infers_ten_groups_from_payload_length(self):
        service = self._service_with_measurement(
            bytes(10 * 12 * 2), bytes(10 * 2 * 2)
        )

        voltages, temperatures = service.read_measurement()

        self.assertEqual(service.group_count, 10)
        self.assertEqual(len(voltages), 10 * 12)
        self.assertEqual(len(temperatures), 10 * 2)

    def test_read_measurement_infers_one_group_from_payload_length(self):
        service = self._service_with_measurement(bytes(12 * 2), bytes(2 * 2))

        voltages, temperatures = service.read_measurement()

        self.assertEqual(service.group_count, 1)
        self.assertEqual(len(voltages), 12)
        self.assertEqual(len(temperatures), 2)

    def test_read_measurement_rejects_odd_payload_length(self):
        service = self._service_with_measurement(bytes(23), bytes(4))

        with self.assertRaisesRegex(ValueError, "Voltage data has an odd byte length"):
            service.read_measurement()

    def test_read_measurement_rejects_mismatched_temperature_length(self):
        service = self._service_with_measurement(bytes(12 * 2), bytes(3 * 2))

        with self.assertRaisesRegex(
            ValueError, "Temperature data contains an unexpected number"
        ):
            service.read_measurement()

if __name__ == "__main__":
    unittest.main()