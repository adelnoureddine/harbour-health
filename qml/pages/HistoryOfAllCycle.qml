import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1

    /*
     * Length in days, matching the average on the cycle page: from this cycle's start
     * to the next one's. The latest cycle runs to its end date if it has one, or is
     * still in progress (-1).
     */
    function cycleLength(cycles, i) {
        var start = Utils.fromLocalDateString(cycles[i].startDate);
        var until = i > 0 ? Utils.fromLocalDateString(cycles[i - 1].startDate) : null;
        if (start === null) {
            return -1;
        }
        if (until !== null) {
            return Math.round((until - start) / 86400000);
        }
        var end = Utils.fromLocalDateString(cycles[i].endDate);
        return end === null ? -1 : Math.round((end - start) / 86400000) + 1;
    }

    function refresh() {
        if (profileId >= 0) {
            var cycles = DataManager.getMenstrualCycles(profileId);
            var rows = [];
            for (var i = 0; i < cycles.length; i++) {
                rows.push({ id: cycles[i].id, startDate: cycles[i].startDate,
                            endDate: cycles[i].endDate ? cycles[i].endDate : "",
                            note: cycles[i].note ? cycles[i].note : "",
                            lengthDays: cycleLength(cycles, i) });
            }
            listModel.clear();
            if (rows.length > 0) {
                listModel.append(rows);
            }
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: listModel

        header: PageHeader {
            width: listView.width
            title: qsTr("Cycle history")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("New cycle")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddNewCycle.qml"), {
                    profileId: page.profileId
                })
            }
        }

        delegate: ListItem {
            id: cycleItem
            contentHeight: Math.max(Theme.itemSizeMedium, cycleColumn.height + 2 * Theme.paddingMedium)

            menu: ContextMenu {
                // Past cycles could only be deleted, never corrected.
                MenuItem {
                    text: qsTr("Edit")
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddNewCycle.qml"), {
                        profileId: page.profileId,
                        cycleId: model.id,
                        initialStart: model.startDate,
                        initialEnd: model.endDate,
                        note: model.note
                    })
                }
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: cycleItem.remorseDelete(function() {
                        DataManager.deleteMenstrualCycle(model.id);
                        // Reloaded rather than removed: the neighbouring cycle's length
                        // depends on this one.
                        page.refresh();
                    })
                }
            }

            Column {
                id: cycleColumn
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
                    text: model.lengthDays >= 0 ? qsTr("%n day(s)", "", model.lengthDays)
                                                : qsTr("In progress")
                    font.pixelSize: Theme.fontSizeSmall
                    color: cycleItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
                Label {
                    width: parent.width
                    text: model.note
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    truncationMode: TruncationMode.Elide
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: cycleItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }

            onClicked: pageStack.animatorPush(Qt.resolvedUrl("HistoryOfOneCycle.qml"), {
                profileId: page.profileId,
                startDate: model.startDate,
                endDate: model.endDate,
                note: model.note
            })
        }

        VerticalScrollDecorator {}

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No cycles recorded")
            hintText: qsTr("Pull down to record a new cycle")
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
