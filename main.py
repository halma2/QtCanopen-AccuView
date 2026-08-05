import sys
from os import environ, path

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from canopen_app.ApplicationController import ApplicationController

if sys.platform == "win32":
    environ["QT_SCALE_FACTOR"] = "0.66" # In Windows 10 the scaling factor is 150%


if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    basedir = str(path.dirname(__file__))
    eds_path = path.join(basedir, "DS301_modified.eds")
    controller = ApplicationController(eds_path)
    engine.rootContext().setContextProperty("controller", controller)
    engine.load(path.join(basedir, "includes", "Main.qml"))
    if not engine.rootObjects():
        sys.exit(-1)

    app.aboutToQuit.connect(controller.shutdown)
    controller.search_ports()
    sys.exit(app.exec())
