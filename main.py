import sys
from os import environ, path

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

import canopen_app  # noqa: F401

if sys.platform == "win32":
    environ["QT_SCALE_FACTOR"] = "0.66" # In Windows 10 the scaling factor is 150%

if __name__ == "__main__":
    base_dir = str(path.dirname(__file__))
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    qml_file = path.join(base_dir, "includes", "Main.qml")
    engine.load(qml_file)
    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())
