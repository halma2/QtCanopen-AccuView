import struct
import sys
import time

import canopen

"""This example is firstly for canopen_accu_simulator.py"""

port = '/dev/ttyACM0'
if sys.platform == 'win32':
    port = 'COM3'

network = canopen.Network()
network.connect(bustype='slcan', channel=port ,bitrate=250_000)
node = network.add_node(1, "../DS301_modified.eds")

while True:
    data_raw = node.sdo[0x2001].raw
    #print(data_raw)
    data = struct.unpack("<192H", data_raw) # if the length of the array is 192
    print(data)

    data_raw_t = node.sdo[0x2002].raw
    data_t = struct.unpack("<32H", data_raw_t)
    data_t_orig = [(float(i) - 32768) / 10 for i in data_t]
    print(data_t_orig)
    time.sleep(1)