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
    if sys.platform == "linux": #TODO check
        sys_path = f"/sys/class/tty/{comport.device}/device/address"
        if not os.path.exists(sys_path):
            raise FileNotFoundError(f"A megadott port ({comport.device}) nem található vagy nem aktív.")
        with open(sys_path, "r") as f:
            mac_address = f.read().strip().upper()
        dbus_mac = mac_address.replace(":", "_")  # BlueZ D-Bus formátumhoz a kettőspontokat aláhúzásra kell cserélni
        bus = dbus.SystemBus()  # Kapcsolódás a BlueZ-hez D-Bus-on keresztül
        device_path = f"/org/bluez/hci0/dev_{dbus_mac}"  # Feltételezzük az alapértelmezett hci0 adaptert
        try:
            device = bus.get("org.bluez", device_path)
            return device.Class  # A Class tulajdonság egy 32 bites egész szám (uint32)

        except dbus.exceptions.Error as e:
            raise FileNotFoundError(f"Nem sikerült lekérni a D-Bus adatokat a {mac_address} eszközhöz. Hiba: {e}")

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
