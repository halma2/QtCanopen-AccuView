import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Column {
    id: settingsPanelRoot

    property var theme

    anchors.fill: parent
    leftPadding: 0
    topPadding: 40

    Label {
        text: "Szabad portok"
    }
    ComboBox {
        id: portInput

        font.bold: false
        height: 120
        indicator: null
        property var ports: controller ? controller.availablePorts : []

        model: ports
        width: parent.width

        delegate: ItemDelegate {
            height: 120
            width: parent.width

            contentItem: Label {
                font.bold: false
                font.pixelSize: settingsPanelRoot.theme.fontPixelSize
                text: modelData
                verticalAlignment: Text.AlignVCenter
            }
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

            font.pixelSize: 60
            text: "📋☑"

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
