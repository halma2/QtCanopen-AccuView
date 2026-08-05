import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Pane {
    id: buttonBarRoot

    property bool busActive: false
    property var anyPanel
    property alias activePanelIndex: buttonBar.activePanelIndex
    property var diagramPanel
    property int groupCount: 0
    property var groupPanel
    property alias listView: buttonBar
    property bool panelOpened: false
    property var settingsPanel
    property var sidePanel
    property var theme

    Layout.bottomMargin: 20
    Layout.fillHeight: true
    Layout.preferredWidth: 140
    Layout.topMargin: 20

    signal panelCloseRequested
    signal panelOpenRequested(var panel)

    function activatePanel(panel) { // used by DiagramPanel
        const items = buttonBar.model;
        for (let index = 0; index < items.length; index++) {
            if (items[index].panel === panel) {
                activePanelIndex = index;
                return;
            }
        }
    }

    Connections {
        target: controller
        function onErrorOccurred() {
            busActive = false
        }
    }

    background: Rectangle {
        border.color: buttonBarRoot.theme.borderColor
        border.width: 1
        color: buttonBarRoot.theme.sideBarBackgroundColor
        radius: 8
    }

    ListView {
        id: buttonBar

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
            highlighted: listView.activePanelIndex === index && barRoot.panelOpened
            text: modelData.icon
            width: listView.width

            background: Rectangle {
                border.color: barButton.activeFocus ? barButton.barRoot.theme.projectPalette.highlight : barButton.barRoot.theme.borderColor
                border.width: barButton.activeFocus ? 1 + 1 : 1
                color: {
                    if (parent.down)
                        return barButton.barRoot.theme.buttonPressedColor;
                    else if (barButton.highlighted)
                        return barButton.barRoot.theme.buttonHighlightedColor;
                    return barButton.barRoot.theme.buttonBackgroundColor;
                }
                height: parent.height
                radius: 8
                width: parent.width
            }

            Keys.onDownPressed: {
                switchButtonFocus(1);
            }
            Keys.onRightPressed: {
                if (barRoot.panelOpened)
                    barRoot.sidePanel.focusLoadedPanel();
                else
                    barRoot.diagramPanel.swipeView.forceActiveFocus();
            }
            Keys.onUpPressed: {
                switchButtonFocus(-1);
            }

            onClicked: {
                if (modelData.action === "connect") {
                    if (barRoot.busActive)
                        controller.stop_reading()
                    else
                        controller.start_reading()
                    busActive = !busActive;
                    return;
                }
                if (modelData.action === "exit") {
                    Qt.quit();
                    return;
                }
                // Close sidePanel
                if (barRoot.panelOpened && listView.activePanelIndex === index) {
                    barRoot.panelCloseRequested();
                    return;
                } // Open sidePanel
                listView.activePanelIndex = index;
                barRoot.panelOpenRequested(modelData.panel);
                if (modelData.action === "openGroupPanel") {
                    controller.get_cell_group(controller.selected_group_id);
                }
            }
        }
    }
}
