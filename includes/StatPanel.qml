import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Pane {
    id: statPanelRoot

    property var labels: [qsTr("Min"), qsTr("Avg"), qsTr("Max")]
    property var statList: [0, 0, 0]
    property int statOffset: 0
    property int decimalPlaces: 3
    property string title: ""
    property string unit: ""

    Connections {
        target: controller

        function onStatDataChanged(values) {
            let formattedValues = [];
            for (let i = 0; i < 3; i++)
                formattedValues.push(Number(values[statOffset + i]).toFixed(decimalPlaces));
            statList = formattedValues;
        }
    }

    background: Rectangle {
        color: "#60000000"
        border.color: "white"
        border.width: 1
        radius: 8
    }

    ColumnLayout {
        anchors.fill: parent

        Label {
            id: title

            text: statPanelRoot.title
        }
        Repeater {
            model: statPanelRoot.statList

            delegate: Row {
                spacing: 10

                Label {
                    text: statPanelRoot.labels[index] + ": "
                    width: 70
                }
                Label {
                    text: statPanelRoot.statList[index] + " " + statPanelRoot.unit
                }
            }
        }
    }
}
