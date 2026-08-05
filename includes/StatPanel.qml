import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Pane {
    id: statPanelRoot

    property var labels: [qsTr("Min"), qsTr("Avg"), qsTr("Max")]
    property var statList: [0, 0, 0]
    property int statOffset: 0
    property int decimalPlaces: 3
    property string header: ""
    property string unit: ""
    property double maxLength: title.contentWidth
    property var theme

    Layout.fillHeight: true
    Layout.fillWidth: true

    Connections {
        target: controller

        function onStatDataChanged(values) {
            let formattedValues = [];
            for (let i = 0; i < 3; i++)
                formattedValues.push(Number(values[statOffset + i]).toFixed(decimalPlaces));
            statList = formattedValues;
        }
    }

    //padding: 30

    background: Rectangle {
        border.color: statPanelRoot.theme.borderColor
        border.width: 1
        color: statPanelRoot.theme.paneBackgroundColor
        radius: 8
    }

    Label {
        id: subTitleTemplate

        property int length: width

        text: labels[0]
        visible: false // célja: a leghosszabb @labels méretét adja meg (contentWidth)
        width: contentWidth

        Component.onCompleted: {
            for (let i = 0; i < labels.length; i++) {
                text = labels[i] + ": ";
                if (contentWidth < length)
                    length = contentWidth;
            }
        }
    }
    ColumnLayout {
        anchors.fill: parent

        Label {
            id: title

            text: statPanelRoot.header
        }
        Repeater {
            model: statPanelRoot.statList

            delegate: Row {
                spacing: 10

                Label {
                    text: statPanelRoot.labels[index] + ": "
                    width: subTitleTemplate.length
                }
                Label {
                    text: statPanelRoot.statList[index] + " " + statPanelRoot.unit
                }
            }
        }
    }
}
