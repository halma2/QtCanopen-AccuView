import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ColumnLayout {
    id: groupPanelRoot

    property int selectedGroupId: controller ? controller.selected_group_id : 0
    property int groupCount: 0
    property var selectedGroupVoltList: []
    property var selectedGroupTempList: []
    property var previousPanel
    property var theme


    Layout.fillWidth: true
    Layout.alignment: Qt.AlignHCenter
    anchors.topMargin: 10
    focus: true

    Connections {
        target: controller
        function onGroupDataChanged(vList, tList) {
            selectedGroupVoltList = vList;
            selectedGroupTempList = tList;
        }
    }

    function focusInitialWidget() {
        moduleSwipeView.forceActiveFocus();
    }

    function selectGroup(groupId) {
        let nextGroupId = Math.max(0, Math.min(groupCount - 1, groupId));
        if (controller)
            controller.get_cell_group(nextGroupId);
        else
            selectedGroupId = nextGroupId;
    }

    SwipeView {
        id: moduleSwipeView

        // Megakadályozza a visszacsatolást inicializáláskor
        property bool blockSync: false

        activeFocusOnTab: true
        currentIndex: groupPanelRoot.selectedGroupId
        height: parent.height
        Layout.fillWidth: true
        spacing: 40

        onCurrentIndexChanged: {
            if (blockSync)
                return;
            if (controller && groupPanelRoot.selectedGroupId !== currentIndex)
                controller.get_cell_group(currentIndex);
        }

        Connections {
            target: groupPanelRoot

            function onSelectedGroupIdChanged() {
                if (moduleSwipeView.currentIndex !== groupPanelRoot.selectedGroupId) {
                    moduleSwipeView.blockSync = true;
                    moduleSwipeView.currentIndex = groupPanelRoot.selectedGroupId;
                    moduleSwipeView.blockSync = false;
                }
            }
        }

        Repeater {
            model: groupPanelRoot.groupCount

            delegate: Rectangle {
                activeFocusOnTab: false
                border.color: moduleSwipeView.activeFocus ? theme.palette.highlight : theme.borderColor
                border.width: moduleSwipeView.activeFocus ? 1+1 : 1
                color: theme.groupSwipeBackgroundColor
                focus: false
                radius: 8

                Keys.onUpPressed: groupPanelRoot.previousPanel.forceActiveFocus();

                ColumnLayout {
                    width: parent.width
                    spacing: 40

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 30
                        text: modelData + 1 + ". modul"
                    }
                    Grid {
                        Layout.alignment: Qt.AlignHCenter
                        columns: 1
                        spacing: 2

                        Repeater {
                            model: groupPanelRoot.selectedGroupVoltList

                            delegate: Row {
                                spacing: 10

                                Label {
                                    horizontalAlignment: Text.AlignRight
                                    text: "U" + ((index < 9) ? "0" : "") + Number(index + 1) + ":"
                                    width: contentWidth // 40
                                }
                                Label {
                                    text: Number(modelData).toFixed(3) + " V"
                                }
                            }
                        }
                    }

                    Column {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 2

                        Repeater {
                            model: groupPanelRoot.selectedGroupTempList

                            delegate: Row {
                                spacing: 10

                                Label {
                                    horizontalAlignment: Text.AlignRight
                                    text: "T" + Number(index + 1) + ":"
                                    width: contentWidth
                                }
                                Label {
                                    text: Number(modelData).toFixed(1) + " °C"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
