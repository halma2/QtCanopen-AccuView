import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ColumnLayout {
    id: settingsPanelRoot

    Label {
        text: "Port"
    }
    ComboBox {
        id: portInput

        font.bold: false
        Layout.preferredHeight: 150
        Layout.fillWidth: true
        //indicator: null
        property var ports: controller ? controller.available_ports : []
        model: ports
        currentValue: controller ? controller.current_port : ""

        hoverEnabled: true
        ToolTip.visible: hovered
        ToolTip.text: currentText
        ToolTip.delay: 500

        delegate: ItemDelegate {
            width: portInput.width
            height: 150
            text: modelData
            highlighted: portInput.highlightedIndex === index

            hoverEnabled: true
            ToolTip.visible: hovered
            ToolTip.text: modelData
            ToolTip.delay: 500
        }

        onActivated: {
            controller.set_port(currentText)
        }
    }
    Button {
        id: refreshButton

        font.pixelSize: 90
        Layout.preferredHeight: 150
        Layout.preferredWidth: 150
        text: "🔄"

        onClicked: controller.search_ports()
    }
}
