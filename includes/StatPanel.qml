import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Pane {
    id: statPanelRoot

    property var labels: [qsTr("Min"), qsTr("Avg"), qsTr("Max")]
    property var statList: [0, 0, 0]
    property int decimalPlaces: 3
    property string title: ""
    property string unit: ""

    background: Background {}

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
                    text: statPanelRoot.statList[index].toFixed(decimalPlaces) + " " + statPanelRoot.unit
                }
            }
        }
    }
}
