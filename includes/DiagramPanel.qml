import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Pane {
    id: diagramPanelRoot

    signal openGroupPanel(int id)

    background: Rectangle {
        color: "#60000000"
        border.color: "white"
        border.width: 1
        radius: 8
    }

    SwipeView {
        id: diagramSwipeView

        anchors.fill: parent
        currentIndex: 0
        spacing: 0
        clip: true

        onCurrentIndexChanged: controller.set_diagram_type(currentIndex)

        GraphMain {
            title: "Average"
            onOpenGroupPanel: function (groupId) {diagramPanelRoot.openGroupPanel(groupId)}
        }

        GraphMain {
            title: "Minimum"
            onOpenGroupPanel: function (groupId) {diagramPanelRoot.openGroupPanel(groupId)}
        }

        GraphMain {
            title: "Maximum"
            onOpenGroupPanel: function (groupId) {diagramPanelRoot.openGroupPanel(groupId)}
        }

        GraphMain {
            title: "Top 8"
            onOpenGroupPanel: function (groupId) {diagramPanelRoot.openGroupPanel(groupId)}
        }

        GraphMinMax {
            onOpenGroupPanel: function (groupId) {diagramPanelRoot.openGroupPanel(groupId)}
        }
    }
}
