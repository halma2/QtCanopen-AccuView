import sys
from os import environ, path

from canopen_app.application_controller import ApplicationController

if sys.platform == "win32":
    environ["QT_SCALE_FACTOR"] = "0.66" # In Windows 10 the scaling factor is 150%

if __name__ == "__main__":
    base_dir = str(path.dirname(__file__))
    eds_name = "DS301_modified.eds"
    application = ApplicationController(base_dir, eds_name)
