import struct
import sys
from sys import argv

import canopen


def word_count(raw_data: bytes, name: str) -> int:
    """Meghatározza a cella csoport számot a byte adatok méretéből."""
    if len(raw_data) % 2:
        raise ValueError(f"{name} data has an odd byte length: {len(raw_data)}")
    return len(raw_data) // 2


network = canopen.Network()
network.connect(bustype='slcan', channel=argv[1] ,bitrate=250_000)
node = network.add_node(1, argv[2])

data_raw = node.sdo[0x2001].raw
voltage_count = word_count(data_raw, "Voltage")
group_count = voltage_count // 12

data_v_orig = struct.unpack(f"<{group_count*12}H", data_raw)

data_raw_t = node.sdo[0x2002].raw
data_t = struct.unpack(f"<{group_count*2}H", data_raw_t)
data_t_orig = [(float(i) - 32768) / 10 for i in data_t]

print(data_v_orig, data_t_orig)

sys.exit(0)