import QtQuick
import QtGraphs
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "QtGraphAutoAxisY.js" as QtGraph_autoAxisY
ColumnLayout {
    id: graphMinMaxRoot

    signal openGroupPanel(int groupId)

    Label {
        text: "Min-Max"
        Layout.alignment: Qt.AlignCenter
    }

    GraphsView {
        id: graphMinMax

        Layout.fillHeight: true
        Layout.fillWidth: true

        Connections {
            target: controller

            function onGraphDataChanged(dataList) {
                if (!graphMinMax.visible)
                    return;
                graphMinMax.maxValues = dataList[1];
                graphMinMax.minValues = dataList[0];
            }
        }

        property real barMargin: 0.1
        property var indexes: []
        property real margin: 0.02
        property var maxValues: []
        property var minValues: []
        property real minWindowSize: 0.5
        property real tick_num: 5
        property string title: "Min-Max"

        marginLeft: 30
        orientation: Qt.Horizontal
        panStyle: GraphsView.PanStyle.None
        zoomStyle: GraphsView.ZoomStyle.None
        theme: GraphsTheme {
            theme: GraphsTheme.Theme.BlueSeries
            colorScheme: GraphsTheme.ColorScheme.Dark

            plotAreaBackgroundVisible: false
            backgroundVisible: false
            axisXLabelFont.pixelSize: 28
            axisYLabelFont.pixelSize: 28
        }

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
            graphMinMax.indexes = [];
            for (let i = 0; i < minValues.length; i++) {
                graphMinMax.indexes.push(i + 1);
                minSet.append(Number(minValues[i]));
                deltaSet.append(Number(maxValues[i]) - Number(minValues[i]));
            }
            axisX.categories = graphMinMax.indexes;
            let newValues = [];
            for (let i = 0; i < minValues.length; i++) {
                newValues.push(Number(maxValues[i]));
                newValues.push(Number(minValues[i]));
            }
            let currentMinMax = QtGraph_autoAxisY.get_custom_axisY(newValues, graphMinMax);
            axisY.min = currentMinMax[0];
            axisY.max = currentMinMax[1];
            axisY.tickInterval = 0.1;
            axisY.subTickCount = 10;
        }
        BarSeries {
            barsType: BarSeries.BarsType.Stacked
            selectable: true

            // Series Index 0: Lower boundary padding spacers (True transparent)
            BarSet {
                id: minSet

                borderWidth: 0
                color: Qt.rgba(100, 10, 100, 0.005)
                selectedColor: Qt.rgba(255,255,255, 0.005)
                values: []
            }

            // Series Index 1: Delta heights (The active visible floating color blocks)
            BarSet {
                id: deltaSet
                values: []
            }
            onClicked: function (index, barSet) {
                deltaSet.deselectAllBars();
                if (barSet === deltaSet) {
                    deltaSet.selectBar(index);
                    openGroupPanel(index);
                }
            }
        }
    }
}
