import random
import struct
import sys
import time

import canopen

can_channel = '/dev/ttyACM0'
if sys.platform == 'win32':
    can_channel = 'COM4'

nodes = 16
volt_measures = 12
temp_measures = 2

network = canopen.Network()
network.connect(bustype="slcan", channel=can_channel,bitrate=250000)
node = canopen.LocalNode(1, '../DS301_modified.eds')
network.add_node(node)

volt_data = [random.randint(0, 65535) for _ in range(nodes * volt_measures)] # data_i = v_i * 10^4
# volt_data = [i for i in range(nodes * volt_measures)]
temp_data = [random.randint(-100*10+32768, 1000*10+32768) for _ in range(nodes * temp_measures)]
# data_t_i: uint16 := t_i * 10 + 32768
# temp_data = [i for i in range(nodes * temp_measures)]

# creating byte array
payload_v = struct.pack("<"+str(nodes*volt_measures)+"H", *volt_data) # <: little-endian, H: unsigned short (16 bit)
payload_t = struct.pack("<"+str(nodes*temp_measures)+"H",   *temp_data) # h: short (signed 16 bit)

node.nmt.state = "OPERATIONAL"

node.sdo[0x2001].raw = payload_v  # ty:ignore[invalid-assignment]
node.sdo[0x2002].raw = payload_t  # ty:ignore[invalid-assignment]

# counter: 58000
counter = 10000
scale = 40
is_decreasing = True


while True:
    time.sleep(0.2)
    if is_decreasing:
        counter -= scale
    else:
        counter += scale
    volt_data = [random.randint(500+counter, 500+500+counter) for _ in range(nodes * volt_measures)]
    payload_v = struct.pack("<" + str(nodes * volt_measures) + "H", *volt_data)
    node.sdo[0x2001].raw = payload_v  # ty:ignore[invalid-assignment]

    if is_decreasing:
        if counter <= scale - 500:
            counter = 63500
    else:
        if counter >= 63500: # 65535 - 2000
            counter = 0
