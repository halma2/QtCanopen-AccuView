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
    property int sidePanelWidth: groupPanelTitleSample.maxWidth//240

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

    // Sablonok------------------------------------------------------------------------------------------
    Text {
        id: graphIndexSample

        font: applicationWindow.font
        text: "/14" // Talán a GraphsView az indexnek valamennyi helyet fenntart
        visible: false // A diagram y-tengely feliratainak számolja ki a méretet (ha a formátum "14/14")
    }
    Text {
        id: groupPanelTitleSample

        property real maxWidth: contentWidth + 20 // cím.szélesség + belső margó

        font: applicationWindow.font
        text: "Szabad portok"
        visible: false // Ez adja meg a sidePanel minimum szélességét, hogy minden adat kiférjen.
    }
    //--------------------------------------------------------------------------------------------------------

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

            expandedWidth: applicationWindow.sidePanelWidth
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
            Layout.maximumWidth: tempPanel.maxLength + Layout.margins * 2
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
