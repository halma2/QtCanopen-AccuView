import QtQuick
import QtGraphs
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "QtGraphAutoAxisY.js" as QtGraphAutoAxisY

GridLayout {
    id: graphMainRoot

    property string title: ""

    signal openGroupPanel(int groupId)
    Connections {
        target: controller

        function onGraphDataChanged(dataList) {
            if (title === "Top 8") {
                graph1.values = dataList[0];
                graph1.indexes = dataList[1];
                graph1.marginRight = 40;
            } else if (title === "Average" || title === "Maximum" || title === "Minimum") {
                graph1.marginRight = 0;
                graph1.values = dataList;
            }
        }
    }

    Label {
        text: graphMainRoot.title
        Layout.alignment: Qt.AlignCenter
    }

    GraphsView {
        id: graph1

        Layout.row: 1
        Layout.column: 0
        property var indexes: []
        property real margin: 0.02
        property real minWindowSize: 0.5
        property var values: []
        Layout.fillHeight: true
        Layout.fillWidth: true

        theme: GraphsTheme {
            theme: GraphsTheme.Theme.BlueSeries
            colorScheme: GraphsTheme.ColorScheme.Dark

            plotAreaBackgroundVisible: false
            backgroundVisible: false
            axisXLabelFont.pixelSize: 28
            axisYLabelFont.pixelSize: 28
        }

        marginLeft: 30
        orientation: Qt.Horizontal
        panStyle: GraphsView.PanStyle.None
        zoomStyle: GraphsView.ZoomStyle.None

        axisX: BarCategoryAxis {
            categories: []
        }
        axisY: ValueAxis {
            alignment: Qt.AlignRight // if graph.orientation: Qt.Horizontal
            max: 0.5
            tickInterval: 1
        }

        onIndexesChanged: {
            if (graphMainRoot.title === "Top 8")
                axisX.categories = indexes;
        }
        onValuesChanged: {
            dataBarSet.clear();
            let displayedIndexes = indexes;
            if (graphMainRoot.title !== "Top 8") {
                displayedIndexes = [];
                for (let i = 0; i < values.length; i++)
                    displayedIndexes.push(i + 1);
            }
            for (let i = 0; i < values.length; i++) {
                dataBarSet.append(Number(values[i]));
            }
            axisX.categories = displayedIndexes;
            let currentMinMax = QtGraphAutoAxisY.get_custom_axisY(values, graph1);
            axisY.min = currentMinMax[0];
            axisY.max = currentMinMax[1];
            axisY.tickInterval = 0.1;
            axisY.subTickCount = 10;
        }

        BarSeries {
            id: dataBarSeries

            selectable: true
            BarSet {
                id: dataBarSet
                selectedColor: color
            }
            onClicked: function (index) {
                if (graphMainRoot.title === "Top 8") // Adott csoportot hívja meg
                    openGroupPanel(graph1.indexes[index].split("/")[0] - 1)
                else
                    openGroupPanel(index)
                dataBarSet.deselectAllBars();
            }
        }
    }

    Item {
        Layout.row: 1
        Layout.column: 1
        Layout.fillHeight: true
        Layout.preferredWidth: 120

        Repeater {
            model: graph1.values

            delegate: Item {
                height: graph1.plotArea.height / graph1.values.length
                width: parent.width
                y: graph1.plotArea.y + index * height

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    font.bold: true
                    color: "white"
                    text: Number(modelData).toFixed(3) + " V"
                }
            }
        }
    }
}
