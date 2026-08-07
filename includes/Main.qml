import QtQuick
import QtGraphs // Qt 6.11
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQml

ApplicationWindow {
    id: applicationWindow

    font.pixelSize: themeSettings.fontPixelSize
    font.bold: true
    palette: themeSettings.projectPalette
    visibility: Window.FullScreen
    visible: true

    Theme {
        id: themeSettings

        isMinMaxplot: diagramPanel.selectedDiagramId === "minMax"
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        ButtonBar {
            id: buttonBar

            appController: controller
            containerOpened: sidePanel.opened
            theme: themeSettings

            onOpenPanel: function (panel_name) {
                let panel_dict = {
                    "settings": settingsPanel,
                    "group": groupPanel,
                    "any": anyPanel
                }
                sidePanel.openPanel(panel_dict[panel_name])
            }
            onClosePanel: sidePanel.closePanel()
        }
        SidePanelContainer {
            id: sidePanel

            theme: themeSettings
        }
        DiagramPanel {
            id: diagramPanel

            theme: themeSettings

            onOpenGroupPanel: function (groupId) {
                controller.get_cell_group(groupId);
                buttonBar.activatePanel(groupPanel);
                sidePanel.openPanel(groupPanel);
            }
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.margins: 20
            Layout.maximumWidth: 230
            spacing: 15

            StatPanel {
                id: voltPanel

                Layout.fillWidth: true
                statOffset: 0
                decimalPlaces: 3
                header: "Feszültség:"
                theme: themeSettings
                unit: "V"
            }
            StatPanel {
                id: tempPanel

                Layout.fillWidth: true
                statOffset: 3
                decimalPlaces: 1
                theme: themeSettings
                header: "Hőmérséklet:"
                unit: "°C"
            }
        }
    }
    MessageDialog {
        id: errMsgBox

        buttons: MessageDialog.Ok
        title: "Hiba"

        Connections {
            target: controller
            function onErrorOccurred(msg) {
                errMsgBox.text = msg;
                errMsgBox.open()
            }
        }
    }
    Component {
        id: settingsPanel

        SettingsPanel {
            theme: themeSettings
        }
    }
    Component {
        id: groupPanel

        GroupPanel {
            theme: themeSettings
        }
    }
    Component {
        id: anyPanel

        AnyPanel {
        }
    }
}
