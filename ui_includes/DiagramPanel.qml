import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Pane {
    id: diagramPanelRoot

    signal openGroupPanel(int id)

    background: Background {}

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
