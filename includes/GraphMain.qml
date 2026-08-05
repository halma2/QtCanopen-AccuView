import QtQuick
import QtGraphs
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "QtGraphAutoAxisY.js" as QtGraph_autoAxisY

Pane {
    id: graphMainRoot

    property var theme
    property string selectedDiagramId: "average"
    property alias values: graph1.values

    signal openGroupPanel(int id)

    Connections {
        target: controller

        function onGraphDataChanged(dataList) {
            if (selectedDiagramId === "minMax")
                return
            if (selectedDiagramId === "top8") {
                graph1.values = dataList[0];
                graph1.indexes = dataList[1];
                graph1.marginRight = 40;
            } else {
                graph1.marginRight = 0;
                graph1.values = dataList;
            }
        }
    }

    Layout.fillHeight: true
    Layout.fillWidth: true

    background: Rectangle {
        border.color: graphMainRoot.theme.borderColor
        border.width: 1
        color: graphMainRoot.theme.graphBackgroundColor
        radius: 5
    }

    RowLayout {
        anchors.fill: parent

        Item {
            id: graphContainer

            Layout.fillHeight: true
            Layout.fillWidth: true

            GraphsView {
                id: graph1

                property var indexes: []
                property real margin: 0.02
                property real minWindowSize: 0.5
                property var values: []

                anchors.fill: parent
                marginBottom: 5
                marginLeft: 25
                marginRight: 0
                marginTop: 0
                orientation: Qt.Horizontal
                panStyle: GraphsView.PanStyle.None
                theme: graphMainRoot.theme.graphTheme
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
                    if (graphMainRoot.selectedDiagramId === "top8")
                        axisX.categories = indexes;
                }
                onValuesChanged: {
                    dataBarSet.clear();
                    let displayedIndexes = indexes;
                    if (graphMainRoot.selectedDiagramId !== "top8") {
                        displayedIndexes = [];
                        for (let i = 0; i < values.length; i++)
                            displayedIndexes.push(i + 1);
                    }
                    for (let i = 0; i < values.length; i++) {
                        dataBarSet.append(Number(values[i]));
                    }
                    axisX.categories = displayedIndexes;
                    let currentMinMax = QtGraph_autoAxisY.get_custom_axisY(values, graph1);
                    axisY.min = currentMinMax[0];
                    axisY.max = currentMinMax[1];
                    axisY.tickInterval = 0.1;
                    axisY.subTickCount = 10;
                }

                BarSeries {
                    BarSet {
                        id: dataBarSet
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onClicked: function (mouse) {
                    if (graphMainRoot.selectedDiagramId === "top8")
                        return;
                    let plot = graph1.plotArea;
                    if (mouse.x < plot.x || mouse.x > plot.x + plot.width || mouse.y < plot.y || mouse.y > plot.y + plot.height)
                        return;
                    let count = dataBarSet.count;
                    if (count === 0)
                        return;
                    let idx = Math.floor((mouse.y - plot.y) / plot.height * count);
                    idx = Math.max(0, Math.min(count - 1, idx));

                    openGroupPanel(idx);
                }
            }
        }

        // separator line
        Rectangle {
            Layout.bottomMargin: 40
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            border.color: graphMainRoot.theme.borderColor
        }

        // Graph-labels
        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: 100

            Repeater {
                model: graph1.values.length

                delegate: Item {
                    height: graph1.plotArea.height / graph1.values.length
                    width: parent.width
                    y: graph1.plotArea.y + index * height

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.bold: true
                        font.pixelSize: graphMainRoot.theme.fontPixelSize
                        text: graph1.values[index].toFixed(3) + " V"
                    }
                }
            }
        }
    }
}
