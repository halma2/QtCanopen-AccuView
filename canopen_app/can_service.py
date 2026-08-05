import struct
import time

from canopen import Network, SdoCommunicationError


class CanServiceError(RuntimeError):
    """A CAN-szolgáltatás inicializálási vagy kapcsolódási hibája."""

class CanService:
    def __init__(
        self,
        eds_path: str,
        g_count: int = 16,
        v_count: int = 12,
        t_count: int = 2,
    ):
        self.group_count = g_count
        self.v_count = v_count
        self.t_count = t_count
        self.port: str | None = None
        self._connected = False
        self.eds_path = eds_path
        self._create_network()

    def _create_network(self):
        self.network = Network()
        try:
            self.node = self.network.add_node(1, self.eds_path)
        except (FileNotFoundError, ValueError) as e:
            raise CanServiceError(str(e)) from e

    def connect(self):
        if self._connected:
            return
        self.network.connect(bustype="slcan", channel=self.port, bitrate=250_000)
        self._connected = True
    
    def read_measurement(self):
        for attempt in range(3):
            try:
                return self._read_measurement_once()
            except SdoCommunicationError:
                if attempt == 2:
                    raise
                self.disconnect()
                time.sleep(0.5)
                self._create_network()
                self.connect()

    def _read_measurement_once(self):
        """Az eds-ben levő indexeken levő SDO üzeneteket kéri le CAN buszon és a megfelelő mértékegységre alaktíja át"""
        voltage_bytes = self.node.sdo["Voltage"].raw
        temperature_bytes = self.node.sdo["Temperature"].raw

        voltage_count = CanService.word_count(voltage_bytes, "Voltage")
        temperature_count = CanService.word_count(temperature_bytes, "Temperature")
        if voltage_count == 0 or voltage_count % self.v_count:
            raise ValueError(
                "Voltage data contains an invalid number of values: "
                f"{voltage_count}"
            )

        group_count = voltage_count // self.v_count
        expected_temperature_count = group_count * self.t_count
        if temperature_count != expected_temperature_count:
            raise ValueError(
                "Temperature data contains an unexpected number of values: "
                f"{temperature_count}; expected {expected_temperature_count}"
            )

        self.group_count = group_count
        v_arr = struct.unpack(f"<{voltage_count}H", voltage_bytes)
        t_arr = struct.unpack(f"<{temperature_count}H", temperature_bytes)
        v_converted = [float(i) / 10000 for i in v_arr]
        t_converted = [(float(i) - 32768) / 10 for i in t_arr]
        return v_converted, t_converted

    @staticmethod
    def word_count(raw_data: bytes, name: str) -> int:
        """Meghatározza a cella csoport számot a byte adatok méretéből."""
        if len(raw_data) % 2:
            raise ValueError(f"{name} data has an odd byte length: {len(raw_data)}")
        return len(raw_data) // 2

    def disconnect(self):
        if not self._connected:
            return
        try:
            self.network.sync.stop()
        finally:
            try:
                self.network.disconnect()
            finally:
                self._connected = False
