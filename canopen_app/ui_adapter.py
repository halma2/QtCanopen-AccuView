class UiAdapter:
    def __init__(self, controller):
        self.controller = controller
        self._last_group_count = None
        self.stat_voltages = [0, 0 ,0]
        self.stat_temperatures = [0, 0, 0]

    def publish_snapshot(self, snapshot):
        self.stat_voltages = [snapshot.voltage_statistics.minimum,
                              snapshot.voltage_statistics.average,
                              snapshot.voltage_statistics.maximum]
        self.stat_temperatures = [snapshot.temperature_statistics.minimum,
                                  snapshot.temperature_statistics.average,
                                  snapshot.temperature_statistics.maximum]
        self.controller.statVoltDataChanged.emit(self.stat_voltages)
        self.controller.statTempDataChanged.emit(self.stat_temperatures)
        group_count = self.controller.processor.group_count
        if group_count != self._last_group_count:
            self._last_group_count = group_count
            self.controller.groupCountChanged.emit(group_count)
        self.controller.graphDataChanged.emit(snapshot.graph_data)
        if snapshot.group_voltages is not None:
            self.controller.groupDataChanged.emit(
                snapshot.group_voltages,
                snapshot.group_temperatures,
            )

    def report_error(self, error):
        print(error)
        self.controller.errorOccurred.emit(str(error))

    def publish_ports(self, ports):
        self.controller.portListChanged.emit(ports)

    def finish_test(self, result):
        self.controller.testFinished.emit(result)
