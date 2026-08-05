import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Pane {
    id: sidePanelRoot

    property int currentPanelWidth: opened ? expandedWidth : 0
    property int expandedWidth: 240
    property alias loader: sidePanelLoader
    property bool opened: false
    property var theme

    function closePanel() {
        opened = false;
        sidePanelLoader.sourceComponent = null;
    }

    function focusLoadedPanel() {
        if (sidePanelLoader.item && sidePanelLoader.item.focusInitialWidget) {
            sidePanelLoader.item.focusInitialWidget();
        }
    }

    function openPanel(panel) {
        sidePanelLoader.sourceComponent = panel;
        opened = true;
    }

    Layout.bottomMargin: 20
    Layout.fillHeight: true
    Layout.maximumWidth: expandedWidth
    Layout.minimumWidth: 0
    Layout.preferredWidth: currentPanelWidth
    Layout.topMargin: 20
    clip: true

    background: Rectangle {
        border.color: sidePanelRoot.theme.borderColor
        border.width: 1
        color: sidePanelRoot.theme.sidePanelBackgroundColor
        radius: 8
    }
    Behavior on currentPanelWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.InOutQuad
        }
    }

    Loader {
        id: sidePanelLoader

        anchors.fill: parent
    }
}
