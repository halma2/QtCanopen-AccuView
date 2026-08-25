import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ColumnLayout {
    id: groupPanelRoot

    property int selectedGroupId: controller ? controller.selected_group_id : 0
    property int groupCount: 16
    property var selectedGroupVoltList: []
    property var selectedGroupTempList: []

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

    SwipeView {
        id: moduleSwipeView

        currentIndex: groupPanelRoot.selectedGroupId
        height: parent.height
        Layout.fillWidth: true
        spacing: 10

        onCurrentIndexChanged: {
            if (controller)
                controller.get_cell_group(currentIndex);
        }

        Repeater {
            model: groupPanelRoot.groupCount

            delegate: Rectangle {
                color: "#60000000"
                border.color: "white"
                border.width: 1
                radius: 8

                ColumnLayout {
                    width: parent.width
                    spacing: 10

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
                                    width: contentWidth
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
