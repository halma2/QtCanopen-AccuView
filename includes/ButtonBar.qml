import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Pane {
    id: buttonBarRoot

    property bool busActive: false
    property bool containerOpened: false
    property var appController
    property var theme

    Layout.bottomMargin: 20
    Layout.fillHeight: true
    Layout.preferredWidth: 140
    Layout.topMargin: 20

    signal openPanel(string panel)
    signal closePanel()
    signal groupPanelOpenedFromDiagram()

    onGroupPanelOpenedFromDiagram: {
        for (let i = 0; i < buttonBarView.model.length; i++) {
            if (buttonBarView.model[i].panel_name === "group") {
                buttonBarView.activePanelIndex = i
                return
            }
        }
    }

    Connections {
        target: buttonBarRoot.appController
        function onErrorOccurred() {
            buttonBarRoot.busActive = false
        }
    }

    background: Rectangle {
        border.color: buttonBarRoot.theme.borderColor
        border.width: 1
        color: buttonBarRoot.theme.sideBarBackgroundColor
        radius: 8
    }

    ListView {
        id: buttonBarView

        property int activePanelIndex: 1
        property var barRoot: buttonBarRoot

        anchors.fill: parent
        anchors.verticalCenter: parent.verticalCenter
        interactive: false
        model: [
            {
                icon: buttonBarRoot.busActive ? "⏹" : "▶",
                action: "connect"
            },
            {
                icon: "⚙",
                action: "openPanel",
                panel_name: "settings"
            },
            {
                icon: "-",
                action: "openPanel",
                panel_name: "any"
            },
            {
                icon: "🔢",
                action: "openGroupPanel",
                panel_name: "group"
            },
            {
                icon: "✖",
                action: "exit"
            }
        ]
        spacing: (height - width * count) / count

        delegate: Button {
            id: barButton

            property var barRoot: listView.barRoot
            property var listView: ListView.view

            activeFocusOnTab: true
            font.pixelSize: 70
            height: parent.width
            highlighted: listView.activePanelIndex === index && barRoot.containerOpened
            text: modelData.icon
            width: listView.width

            background: Rectangle {
                border.color: barButton.visualFocus ?
                    barRoot.theme.projectPalette.highlight : barRoot.theme.borderColor
                border.width: 1
                color: {
                    if (parent.down)
                        return barRoot.theme.buttonPressedColor;
                    else if (barButton.highlighted)
                        return barRoot.theme.buttonHighlightedColor;
                    return barRoot.theme.buttonBackgroundColor;
                }
                height: parent.height
                radius: 8
                width: parent.width
            }

            onClicked: {
                if (modelData.action === "connect") {
                    if (barRoot.busActive) {
                        barRoot.busActive = false;
                        barRoot.appController.stop_reading();
                    } else {
                        barRoot.busActive = true;
                        barRoot.appController.start_reading();
                    }
                    return;
                }
                if (modelData.action === "exit") {
                    Qt.quit();
                    return;
                }
                // Close sidePanelContainer
                if (barRoot.containerOpened && listView.activePanelIndex === index) {
                    closePanel()
                    return
                } // Open sidePanelContainer
                listView.activePanelIndex = index
                openPanel(modelData.panel_name)
                if (modelData.action === "openGroupPanel")
                    barRoot.appController.get_cell_group(barRoot.appController.selected_group_id)
            }
        }
    }
}
