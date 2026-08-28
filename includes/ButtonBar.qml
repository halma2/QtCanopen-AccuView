import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Pane {
    id: buttonBarRoot

    property bool busActive: appController ? appController.bus_active : false
    property bool busBusy: appController ? appController.bus_busy : false
    property bool containerOpened: false
    property var appController

    signal openPanel(string panel)
    signal closePanel()
    signal groupPanelOpenedFromDiagram()

    onGroupPanelOpenedFromDiagram: {
        for (let i = 0; i < buttonBarRepeater.model.length; i++) {
            if (buttonBarRepeater.model[i].panel_name === "group") {
                buttonBarView.activePanelIndex = i
                return
            }
        }
    }

    background: Background {}

    ColumnLayout {
        id: buttonBarView

        property int activePanelIndex: 1
        property var rootItem: buttonBarRoot

        anchors.fill: parent
        Repeater {
            id: buttonBarRepeater

            property var rootItem: buttonBarRoot
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

            delegate: Button {
                id: barButton

                property var rootItem: buttonBarRepeater.rootItem
                activeFocusOnTab: true
                font.pixelSize: 70
                Layout.fillWidth: true
                Layout.preferredHeight: buttonBarView.width
                enabled: !(modelData.action === "connect" && rootItem.busBusy)
                highlighted: buttonBarView.activePanelIndex === index && buttonBarView.rootItem.containerOpened
                text: modelData.icon

                onClicked: {
                    if (modelData.action === "connect") {
                        if (rootItem.busActive) {
                            rootItem.appController.stop_reading();
                        } else {
                            rootItem.appController.start_reading();
                        }
                        return;
                    }
                    if (modelData.action === "exit") {
                        Qt.quit();
                        return;
                    }
                    // Close sidePanelContainer
                    if (rootItem.containerOpened && buttonBarView.activePanelIndex === index) {
                        rootItem.closePanel()
                        return
                    } // Open sidePanelContainer
                    buttonBarView.activePanelIndex = index
                    rootItem.openPanel(modelData.panel_name)
                    if (modelData.action === "openGroupPanel")
                        rootItem.appController.get_cell_group(rootItem.appController.selected_group_id)
                }
            }
        }
    }
}
