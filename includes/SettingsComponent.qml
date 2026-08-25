import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ColumnLayout {
    id: settingsPanelRoot

    Label {
        text: "Szabad portok"
    }
    ComboBox {
        id: portInput

        font.bold: false
        Layout.preferredHeight: 120
        Layout.fillWidth: true
        //indicator: null
        property var ports: controller ? controller.availablePorts : []

        model: ports

        delegate: ItemDelegate {
            width: portInput.width
            height: 120
            text: modelData
            highlighted: portInput.highlightedIndex === index
        }

        onActivated: controller.set_port(currentText)
    }
    Button {
        id: refreshButton

        font.pixelSize: 70
        height: 120
        text: "🔄"
        width: 120

        onClicked: controller.search_ports()
    }
    RowLayout {
        Button {
            id: testButton

            font.pixelSize: 70
            text: "📋"

            onClicked:  {
                testStatus.text = "⏳"
                controller.start_test()
            }
            Connections {
                target: controller
                function onTestFinished(ok) {
                    testStatus.text = ok ? '✔' : '❌'
                }
            }
        }
        Label {
            id: testStatus
            text: ""
        }
    }
}
