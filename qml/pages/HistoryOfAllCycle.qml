import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1

    function refresh() {
        if (profileId >= 0) {
            var cycles = DataManager.getMenstrualCycles(profileId);
            listModel.clear();
            for (var i = 0; i < cycles.length; i++) {
                listModel.append(cycles[i]);
            }
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: listModel

        header: PageHeader {
            width: listView.width
            title: qsTr("Cycle History")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("New Cycle")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddNewCycle.qml"), {
                    profileId: page.profileId
                })
            }
        }

        delegate: ListItem {
            id: cycleItem
            contentHeight: Theme.itemSizeMedium

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: cycleItem.remorseDelete(function() {
                        DataManager.deleteMenstrualCycle(model.id);
                        listModel.remove(index);
                    })
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                
                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: model.endDate
                          ? qsTr("%1 to %2").arg(Utils.formatDate(model.startDate))
                                            .arg(Utils.formatDate(model.endDate))
                          : qsTr("Started on %1").arg(Utils.formatDate(model.startDate))
                    color: cycleItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: model.note ? model.note : ""
                    font.pixelSize: Theme.fontSizeSmall
                    color: cycleItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    visible: text !== ""
                }
            }

            onClicked: pageStack.animatorPush(Qt.resolvedUrl("HistoryOfOneCycle.qml"), {
                profileId: page.profileId,
                startDate: model.startDate,
                endDate: model.endDate ? model.endDate : "",
                note: model.note ? model.note : ""
            })
        }

        VerticalScrollDecorator {}

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No cycles recorded")
        }
    }

    ListModel {
        id: listModel
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            refresh();
        }
    }
}
