import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Pane {
    id: diagramPanelRoot

    property var diagramDefinitions: [ "average", "minimum", "maximum", "top8", "minMax" ]
    property string selectedDiagramId: diagramDefinitions[diagramSwipeView.currentIndex]
    property var theme

    signal openGroupPanel(int id)

    Layout.bottomMargin: 20
    Layout.fillHeight: true
    Layout.fillWidth: true
    Layout.topMargin: 20
    clip: true
    padding: 0

    SwipeView {
        id: diagramSwipeView

        activeFocusOnTab: true
        anchors.fill: parent
        currentIndex: 0
        spacing: 0

        onCurrentIndexChanged: {
            controller.set_diagram_type(currentIndex);
        }

        Repeater {
            id: diagramRepeater

            model: diagramDefinitions

            delegate: Rectangle {

                activeFocusOnTab: false
                border.color: diagramSwipeView.visualFocus ?
                    diagramPanelRoot.theme.palette.highlight : diagramPanelRoot.theme.borderColor
                border.width: 1
                radius: 8

                ColumnLayout {
                    anchors.fill: parent

                    Text {
                        Layout.fillWidth: true
                        Layout.preferredHeight: implicitHeight
                        Layout.topMargin: 10
                        font.bold: true
                        font.pixelSize: diagramPanelRoot.theme.fontPixelSize
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        verticalAlignment: Text.AlignVCenter
                    }
                    GraphMain {
                        id: graphMain

                        Layout.margins: 10
                        theme: diagramPanelRoot.theme
                        selectedDiagramId: diagramPanelRoot.selectedDiagramId
                        visible: diagramPanelRoot.selectedDiagramId !== "minMax"

                        onOpenGroupPanel: function (groupId) {
                            diagramPanelRoot.openGroupPanel(groupId);
                        }
                    }
                    GraphMinMax {
                        id: graphMinMax

                        Layout.margins: 10
                        theme: diagramPanelRoot.theme
                        visible: diagramPanelRoot.selectedDiagramId === "minMax"

                        onOpenGroupPanel: function (groupId) {
                            diagramPanelRoot.openGroupPanel(groupId);
                        }
                    }
                }
            }
        }
    }
}
