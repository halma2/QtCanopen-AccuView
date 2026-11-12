from time import sleep
import android_serial
from can.interfaces import slcan
from canopen_app import ApplicationController


def init_android_serial(ctrl: ApplicationController):
    """ Rewrites the port-opening serial class of the original slcan to AndroidSerial (monkey-patch)
        Also the function for searching COM ports is rewritten in Android."""
    slcan.serial.serial_for_url = android_serial.android_serial_for_url
    ctrl.get_serial_ports = search_and_filter_android_ports()

    if not (android_serial.android_usb_host_supported()):
        ctrl.ui.report_error("USB host is not supported on this android device.")

def start_reading_preps(ctrl: ApplicationController):
    """Checking and requesting permission before opening the serial port"""
    if len(ctrl.available_ports) == 0:
        ctrl.ui.report_error("No USB devices available.")
        return
    if android_serial.android_is_bluetooth_device(ctrl.can_service.port):
        if not android_serial.android_bluetooth_permission_granted():
            android_serial.android_bluetooth_request_permission()
            sleep(5)
    elif not android_serial.android_usb_permission_granted(ctrl.can_service.port):
        android_serial.android_usb_request_permission(ctrl.can_service.port)
        sleep(5)

def search_and_filter_android_ports() -> list[str]:
    """List all usb ports and already paired Bluetooth devices and filters those Bluetooth devices
    that has the Bluetooth device class COD id 0x1F00 (uncategorized, used for UART)"""
    available_ports = android_serial.android_search_for_usb_bt_devices()
    for p in list(available_ports):
        if android_serial.android_is_bluetooth_device(p):
            if android_serial.android_bluetooth_get_device_class(p) != int(0x1F00):
                available_ports.remove(p)
    return available_ports