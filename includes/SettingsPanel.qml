import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Column {
    id: settingsPanelRoot

    property int buttonSize: 120
    property var focusMap: [portInput, refreshButton, testButton]
    property string testStatus: ""
    property var availablePorts: controller ? controller.availablePorts : []
    property var theme

    Connections {
        target: controller
        function onTestFinished(ok) {
            settingsPanelRoot.testStatus = ok ? '✔' : '❌'
        }
    }

    function focusInitialWidget() {
        portInput.forceActiveFocus();
    }
    function moveFocus(step) {
        let focusIndex = 0;
        for (let i = 0; i < focusMap.length; i++) {
            if (focusMap[i].activeFocus) {
                focusIndex = i;
                break;
            }
        }
        focusIndex = Math.max(0, Math.min(focusMap.length - 1, focusIndex + step));
        focusMap[focusIndex].forceActiveFocus();
    }

    anchors.fill: parent
    leftPadding: 0
    topPadding: 40

    Keys.onDownPressed: {
        moveFocus(1);
    }
    Keys.onLeftPressed: {
        buttonBar.forceActiveFocus();
    }
    Keys.onRightPressed: {
        diagramPanel.swipeView.forceActiveFocus();
    }
    Keys.onUpPressed: {
        moveFocus(-1);
    }

    Label {
        text: "Szabad portok"
    }
    ComboBox {
        id: portInput

        font.bold: false
        height: settingsPanelRoot.buttonSize
        indicator: null
        model: settingsPanelRoot.availablePorts
        width: parent.width

        delegate: ItemDelegate {
            height: settingsPanelRoot.buttonSize
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
        height: settingsPanelRoot.buttonSize
        text: "🔄"
        width: settingsPanelRoot.buttonSize

        onClicked: controller.search_ports()
    }
    RowLayout {
        Button {
            id: testButton

            font.pixelSize: 60
            text: "📋☑"

            onClicked:  {
                settingsPanelRoot.testStatus = "⏳"
                controller.start_test()
            }
        }
        Label {
            text: settingsPanelRoot.testStatus
        }
    }
}
