import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ColumnLayout {
    id: groupPanelRoot

    property int selectedGroupId: controller ? controller.selected_group_id : 0
    property int groupCount: 16
    property var selectedGroupVoltList: []
    property var selectedGroupTempList: []
    property var theme

    Layout.alignment: Qt.AlignHCenter
    anchors.topMargin: 10

    Connections {
        target: controller
        function onGroupCountChanged(count) {
            groupCount = count;
        }
        function onGroupDataChanged(vList, tList) {
            selectedGroupVoltList = vList;
            selectedGroupTempList = tList;
        }
    }

    function selectGroup(groupId) {
        let nextGroupId = Math.max(0, Math.min(groupCount - 1, groupId));
        if (controller)
            controller.get_cell_group(nextGroupId);
        else
            selectedGroupId = nextGroupId;//TODO
    }

    SwipeView {
        id: moduleSwipeView

        currentIndex: groupPanelRoot.selectedGroupId
        height: parent.height
        Layout.fillWidth: true
        spacing: 40

        onCurrentIndexChanged: {
            if (controller)
                controller.get_cell_group(currentIndex);
        }

        Repeater {
            model: groupPanelRoot.groupCount

            delegate: Rectangle {
                border.color: moduleSwipeView.visualFocus ? theme.palette.highlight : theme.borderColor
                border.width: 1
                color: theme.groupSwipeBackgroundColor
                radius: 8

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
