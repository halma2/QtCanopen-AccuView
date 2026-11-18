import sys
import os
from serial.tools.list_ports_common import ListPortInfo

if sys.platform == "win32":
    import winreg
    import re
else:
    import dbus

def is_bluetooth_device(comport: ListPortInfo)-> bool:
    if sys.platform == "win32":
        return comport.hwid.startswith("BTHENUM\\")
    return comport.device.startswith("/dev/rfcomm")

def check_bluetooth_class(comport: ListPortInfo) -> int:
    if sys.platform == "linux":
        sys_path = f"/sys/class/tty/{comport.name}/address"
        if not os.path.exists(sys_path):
            raise FileNotFoundError(f"The given port ({comport.name}) not found or not active.")
        with open(sys_path, "r") as f:
            mac_address = f.read().strip().upper()
        dbus_mac = mac_address.replace(":", "_")  # BlueZ D-Bus format
        bus = dbus.SystemBus()  # connect to BlueZ through D-Bus
        device_path = f"/org/bluez/hci0/dev_{dbus_mac}"  # first adapter: hci0
        try:
            proxy = bus.get_object("org.bluez", device_path) # eg.: /org/bluez/hci0/dev_1C_69_20_A4_D1_F2
            props = dbus.Interface(proxy, "org.freedesktop.DBus.Properties")
            return props.Get("org.bluez.Device1", "Class")
        except Exception as e:
            raise FileNotFoundError(f"Cannot access data through D-Bus to device {mac_address}.\n"
                                    "Try turning the power and scan on in Bluetooth settings (bluetoothctl)!\n"
                                    f"Exception: {e}")

    else: # Windows:
        # example hwid: BTHENUM\{00001101-0000-1000-8000-00805F9B34FB}_LOCALMFG&0002\7&5776ED3&0&1C6920A4D1F2_C00000000
        # -> match: 1C6920A4D1F2
        match = re.search(r"([0-9A-F]{12})_", comport.hwid, re.IGNORECASE)
        mac_address = match.group(1).lower()

        bt_reg_path = f"SYSTEM\\CurrentControlSet\\Services\\BTHPORT\\Parameters\\Devices\\{mac_address}"
        try:
            with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, bt_reg_path) as bth_key:
                class_data, _ = winreg.QueryValueEx(bth_key, "COD")
                return class_data
        except FileNotFoundError: # input bt comport (no use) if MAC=0 (duplicated)
            raise RuntimeError(f"Device with MAC: ({mac_address}) not found in Registry.")
