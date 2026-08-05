import QtQuick
import QtGraphs // Qt 6.11
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQml

ApplicationWindow {
    id: applicationWindow

    property int groupCount: 16
    property string selectedDiagramId: diagramPanel.selectedDiagramId

    Connections {
        target: controller

        function onGroupCountChanged(count) {
            groupCount = count;
        }
        function onErrorOccurred(msg) {
            errMsgBox.text = msg;
            errMsgBox.open();
        }
    }

    font.pixelSize: themeSettings.fontPixelSize
    font.bold: true
    palette: themeSettings.projectPalette
    visibility: Window.FullScreen
    visible: true


    Theme {
        id: themeSettings

        isMinMaxplot: applicationWindow.selectedDiagramId === "minMax"
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        ButtonBar {
            id: buttonBar

            anyPanel: anyPanel
            diagramPanel: diagramPanel
            groupCount: applicationWindow.groupCount
            groupPanel: groupPanel
            panelOpened: sidePanel.opened
            settingsPanel: settingsPanel
            sidePanel: sidePanel
            theme: themeSettings

            onPanelCloseRequested: {
                sidePanel.closePanel();
            }
            onPanelOpenRequested: function (panel) {
                sidePanel.openPanel(panel);
            }
        }
        SidePanel {
            id: sidePanel

            expandedWidth: 240
            theme: themeSettings
        }
        DiagramPanel {
            id: diagramPanel

            previousPanel: buttonBar
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
            groupCount: applicationWindow.groupCount
            previousPanel: buttonBar
            theme: themeSettings
        }
    }
    Component {
        id: anyPanel

        AnyPanel {
        }
    }
}
