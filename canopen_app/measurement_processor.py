from dataclasses import dataclass
from enum import IntEnum
from heapq import nlargest, nsmallest
from statistics import mean


class DiagramType(IntEnum):
    AVERAGE = 0
    MINIMUM = 1
    MAXIMUM = 2
    TOP_K = 3
    MIN_MAX = 4


@dataclass
class Statistics:
    minimum: float
    average: float
    maximum: float


@dataclass
class MeasurementSnapshot:
    voltage_statistics: Statistics
    temperature_statistics: Statistics
    graph_data: object
    group_voltages: list[float] | None = None
    group_temperatures: list[float] | None = None


class MeasurementProcessor:
    """
    Szűri az érvényes adatokat, majd előállítja a statisztikai adatokat,
    ill. a megfelelő diagramhoz szükséges adatokat.

    :var v_count: (12) feszültségcellák száma egy cella csoportban
    """
    def __init__(self):
        self.v_count = 12
        self.min_valid_voltage = 0
        self.max_valid_voltage = 6.5
        self.group_count = 0

    def process(self,
                voltages: list[float],
                temperatures: list[float],
                diagram_type: DiagramType = DiagramType.AVERAGE,
                requested_group_id: int | None = None):
        if len(voltages) == 0 or len(voltages) % self.v_count:
            raise ValueError(
                "Voltage data contains an invalid number of values: "
                f"{len(voltages)}"
            )
        self.group_count = len(voltages) // self.v_count
        valid_voltages = [v for v in voltages if self.min_valid_voltage < v < self.max_valid_voltage]
        voltage_statistics = Statistics(
            min(valid_voltages), 
            mean(valid_voltages), 
            max(valid_voltages))
        temperature_statistics = Statistics(
            min(temperatures), 
            mean(temperatures), 
            max(temperatures))

        # TODO hiba legyen vagy autoconfig, ha változik? Azonban a readingBus fixen ez alapján dekódol!
        #self.group_count = len(voltages) // self.v_count
        graph_data = self._create_graph_data(voltages, diagram_type)

        group_voltages = None
        group_temperatures = None
        if requested_group_id is not None:
            start_v_index = requested_group_id * self.v_count
            group_voltages = voltages[start_v_index:start_v_index + self.v_count]
            start_t_index = requested_group_id * 2
            group_temperatures = temperatures[start_t_index:start_t_index + 2]

        return MeasurementSnapshot(voltage_statistics, temperature_statistics, graph_data,
                                   group_voltages, group_temperatures, )


    def _create_graph_data(self, voltages, diagram_type: DiagramType = DiagramType.AVERAGE):
        """Csoportokra szedi a bejövő adatokat (érvényes tartományra szűrve), majd csoportonként a diagram szerint
         választja ki a megjelenítendő adatokat."""
        groups = [
            [
                value
                for value in voltages[
                    2 + i * self.v_count: self.v_count - 1 + i * self.v_count
                ]
                if self.min_valid_voltage < value < self.max_valid_voltage
            ]
            for i in range(self.group_count)
        ]

        match diagram_type:
            case DiagramType.AVERAGE:
                return [round(mean(group), 3) for group in groups]
            case DiagramType.MINIMUM:
                return [min(group) for group in groups]
            case DiagramType.MAXIMUM:
                return [max(group) for group in groups]
            case DiagramType.TOP_K:
                return self._top_k(voltages)
            case DiagramType.MIN_MAX:
                return [
                    [min(group) for group in groups],
                    [max(group) for group in groups]
                ]


    def _top_k(self, arr, k = 8):
        """A teljes adathalmazból visszatér az első k legnagyobb és k legkisebb értékkel, ill. a cellapozíciójukkal"""
        top_i_v = nlargest(
            k,
            (
                (i, v)
                for i, v in enumerate(arr)
                if self.min_valid_voltage < v < self.max_valid_voltage
            ),
            key=lambda x: x[1],
        )
        top_i_v.sort(key=lambda x: x[1])
        bottom_i_v = nsmallest(
            k,
            (
                (i, v)
                for i, v in enumerate(arr)
                if self.min_valid_voltage < v < self.max_valid_voltage
            ),
            key=lambda x: x[1],
        )
        value_list = [v for i, v in bottom_i_v + top_i_v]
        indices_list = [i for i, v in bottom_i_v + top_i_v]
        renamed_indices = [
            str(x // self.v_count + 1) + "/" + str(x % self.v_count + 1)
            for x in indices_list
        ]
        return [value_list, renamed_indices]
