import sys
from os import path
from subprocess import PIPE, STDOUT, Popen

from PySide6.QtCore import QObject, Signal, Slot


class TestWorker(QObject):
    """Külön szálon egy egyszeri olvasást kísérel meg."""
    finished = Signal(bool)

    def __init__(self, port, eds_file):
        super().__init__()
        self.port = port
        self.process = None
        self.eds_file = eds_file

    def stop_process(self):
        if self.process is not None and self.process.poll() is None:
            self.process.terminate()

    @Slot()
    def run(self):
        try:
            command = [
                sys.executable,
                "-u",
                path.join(str(path.dirname(__file__)), "../tools/canopen_client_short.py"),
                str(self.port),
                str(self.eds_file)
            ]

            self.process = Popen(
                command,
                stdout=PIPE,
                stderr=STDOUT,
                text=True,
                bufsize=1,
            )

            stdout = self.process.stdout
            if stdout is None:
                raise RuntimeError("A test stdout channel is not available.")

            for line in stdout:
                print(f"[test] {line}", end="", flush=True)

            return_code = self.process.wait()
            print(f"Test has ended: {return_code}", flush=True)
            self.finished.emit(return_code == 0)
        except Exception as error:  # noqa: BLE001
            print(f"Test error: {error}", flush=True)
            self.stop_process()
            if self.process is not None:
                self.process.wait()
            self.finished.emit(False)
