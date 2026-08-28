import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtQuick.Dialogs


ApplicationWindow {
    id: applicationWindow

    font.pixelSize: 28
    font.bold: true
    font.family: "Arial"
    visibility: Window.FullScreen
    visible: true
    palette.windowText: "white"

    onClosing: controller.shutdown()

    background: Rectangle {
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#FF202020"
            }
            GradientStop {
                position: 1.0
                color: "seagreen"
            }
        }
    }

    GridLayout {
        anchors.fill: parent
        columns: 4
        rows: 2
        anchors.margins: 20
        columnSpacing: 10

        ButtonBar {
            id: buttonBar

            Layout.fillHeight: true
            Layout.preferredWidth: 140
            Layout.column: 0
            Layout.row: 0
            Layout.rowSpan: 2

            appController: controller
            containerOpened: sidePanel.opened

            onOpenPanel: function (panel_name) {
                // Új gomb hozzáadásakor az új komponenst és a ButtonBar-model nevét itt kell megadni.
                let panel_dict = {
                    // "ButtonBar.buttonBarView.modelData.panel_name" : component,
                    "settings": settingsComponent,
                    "group": groupComponent,
                    "any": anyComponent
                }
                sidePanel.openPanel(panel_dict[panel_name])
            }
            onClosePanel: sidePanel.closePanel()
        }
        SidePanelContainer {
            id: sidePanel

            Layout.column: 1
            Layout.row: 0
            Layout.rowSpan: 2
            Layout.fillHeight: true
            Layout.maximumWidth: 245
        }
        DiagramPanel {
            id: diagramPanel

            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.row: 0
            Layout.rowSpan: 2
            Layout.column: 2

            onOpenGroupPanel: function (groupId) {
                controller.get_cell_group(groupId);
                buttonBar.groupPanelOpenedFromDiagram()
                sidePanel.openPanel(groupComponent);
            }
        }
        StatPanel {
            id: voltPanel

            Layout.row: 0
            Layout.column: 3
            Layout.maximumWidth: 230
            Layout.minimumWidth: 230
            Layout.fillHeight: true
            statList: controller.statVoltages
            decimalPlaces: 3
            title: "Voltage:"
            unit: "V"
        }
        StatPanel {
            id: tempPanel

            Layout.row: 1
            Layout.column: 3
            Layout.maximumWidth: 230
            Layout.minimumWidth: 230
            Layout.fillHeight: true
            statList: controller.statTemperatures
            decimalPlaces: 1
            title: "Temperature:"
            unit: "°C"
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
        id: settingsComponent

        SettingsComponent {}
    }
    Component {
        id: groupComponent

        GroupComponent {}
    }
    Component {
        id: anyComponent

        AnyComponent {}
    }
}
