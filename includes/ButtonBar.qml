import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Pane {
    id: buttonBarRoot

    property bool busActive: false
    property var appController
    property var settingsPanel
    property var anyPanel
    property var diagramPanel
    property var groupPanel
    property var sidePanelContainer
    property var theme

    Layout.bottomMargin: 20
    Layout.fillHeight: true
    Layout.preferredWidth: 140
    Layout.topMargin: 20

    function activatePanel(panel) { // used by DiagramPanel: opening group panel
        const items = buttonBarView.model;
        for (let index = 0; index < items.length; index++) {
            if (items[index].panel === panel) {
                buttonBarView.activePanelIndex = index;
                return;
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
                panel: buttonBarRoot.settingsPanel
            },
            {
                icon: "-",
                action: "openPanel",
                panel: buttonBarRoot.anyPanel
            },
            {
                icon: "🔢",
                action: "openGroupPanel",
                panel: buttonBarRoot.groupPanel
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

            function switchButtonFocus(step) {
                let button = listView.itemAtIndex(index + step);
                if (button)
                    button.forceActiveFocus();
            }

            activeFocusOnTab: true
            font.pixelSize: 70
            height: parent.width
            highlighted: listView.activePanelIndex === index && barRoot.sidePanelContainer.opened
            text: modelData.icon
            width: listView.width

            background: Rectangle {
                border.color: barButton.activeFocus ?
                    barRoot.theme.projectPalette.highlight : barRoot.theme.borderColor
                border.width: barButton.activeFocus ? 1 + 1 : 1
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

            Keys.onDownPressed: {
                switchButtonFocus(1);
            }
            Keys.onRightPressed: {
                if (barRoot.sidePanelContainer.opened)
                    barRoot.sidePanelContainer.focusLoadedPanel();
                else
                    barRoot.diagramPanel.view.forceActiveFocus();
            }
            Keys.onUpPressed: {
                switchButtonFocus(-1);
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
                if (barRoot.sidePanelContainer.opened && listView.activePanelIndex === index) {
                    barRoot.sidePanelContainer.closePanel(modelData.panel)
                    return
                } // Open sidePanelContainer
                listView.activePanelIndex = index
                barRoot.sidePanelContainer.openPanel(modelData.panel)
                if (modelData.action === "openGroupPanel")
                    barRoot.appController.get_cell_group(barRoot.appController.selected_group_id)
            }
        }
    }
}
