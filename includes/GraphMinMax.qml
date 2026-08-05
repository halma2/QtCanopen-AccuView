import QtQuick
import QtGraphs
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "QtGraphAutoAxisY.js" as QtGraph_autoAxisY

Pane {
    id: graphMinMaxRoot

    property var theme
    signal openGroupPanel(int id)

    Layout.fillHeight: true
    Layout.fillWidth: true

    Connections {
        target: controller
        function onGraphDataChanged(dataList) {
            if (selectedDiagramId === "minMax") {
                graph2.maxValues = dataList[1];
                graph2.minValues = dataList[0];
            }
        }
    }

    background: Rectangle {
        color: graphMinMaxRoot.theme.graphBackgroundColor
        border.color: graphMinMaxRoot.theme.borderColor
        border.width: 1
        radius: 8
    }

    GraphsView {
        id: graph2

        property real barMargin: 0.1
        property var indexes: []
        property real margin: 0.02
        property var maxValues: []
        property var minValues: []
        property real minWindowSize: 0.5
        property real tick_num: 5

        anchors.fill: parent
        marginBottom: 0
        marginLeft: 30
        marginRight: 0
        marginTop: 5
        orientation: Qt.Horizontal
        panStyle: GraphsView.PanStyle.None
        theme: graphMinMaxRoot.theme.graphTheme
        zoomStyle: GraphsView.ZoomStyle.None

        axisX: BarCategoryAxis {
            categories: []
        }
        axisY: ValueAxis {
            alignment: Qt.AlignRight // if graph.orientation: Qt.Horizontal
            max: 0.5
            tickInterval: 1
        }

        onMinValuesChanged: {
            minSet.clear();
            deltaSet.clear();
            graph2.indexes = [];
            for (let i = 0; i < minValues.length; i++) {
                graph2.indexes.push(i + 1);
                minSet.append(Number(minValues[i]));
                deltaSet.append(Number(maxValues[i]) - Number(minValues[i]));
            }
            axisX.categories = graph2.indexes;
            let newValues = [];
            for (let i = 0; i < minValues.length; i++) {
                newValues.push(Number(maxValues[i]));
                newValues.push(Number(minValues[i]));
            }
            let currentMinMax = QtGraph_autoAxisY.get_custom_axisY(newValues, graph2);
            axisY.min = currentMinMax[0];
            axisY.max = currentMinMax[1];
            axisY.tickInterval = 0.1;
            axisY.subTickCount = 10;
        }

        BarSeries {
            barsType: BarSeries.BarsType.Stacked

            // Series Index 0: Lower boundary padding spacers (True transparent)
            BarSet {
                id: minSet

                borderColor: "#00000000"
                borderWidth: 0
                color: "#00000000"
                values: []
            }

            // Series Index 1: Delta heights (The active visible floating color blocks)
            BarSet {
                id: deltaSet

                borderWidth: 2
                values: []
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onClicked: function (mouse) {
            let plot = graph2.plotArea
            if (mouse.x < plot.x || mouse.x > plot.x + plot.width || mouse.y < plot.y || mouse.y > plot.y + plot.height)
                return
            if (minSet.count === 0)
                return
            let idx = Math.floor((mouse.y - plot.y) / plot.height * minSet.count)
            idx = Math.max(0, Math.min(minSet.count - 1, idx));

            openGroupPanel(idx);
        }
    }
}
