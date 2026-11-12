import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Pane {
    id: sidePanelRoot

    Layout.preferredWidth: opened ? Layout.maximumWidth : 0
    Layout.minimumWidth: 0
    property bool opened: false

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

    clip: true

    background: Background {}

    Behavior on Layout.preferredWidth {
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
