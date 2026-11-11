import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string profileName: ""
    // What the page last loaded (see DataManager.dataKey). Coming back from a cycle's
    // details or a cancelled edit does not reload.
    property string loadedFrom: ""
    // Keeps the placeholder from flashing while the page is pushed.
    property bool loaded: false

    /*
     * Length in days, matching the average on the cycle page: from this cycle's start
     * to the next one's. The latest cycle is still in progress (-1), whether or not its
     * period has ended: it used to show the length of its period there ("5 days") above
     * rows of 28.
     */
    function cycleLength(cycles, i) {
        var toNext = i > 0 ? Utils.daysBetween(cycles[i].startDate, cycles[i - 1].startDate) : null;
        return toNext === null ? -1 : toNext;
    }

    // Days of the period, first and last included; -1 when its end was not recorded.
    function periodLength(cycle) {
        var days = cycle.endDate ? Utils.daysBetween(cycle.startDate, cycle.endDate) : null;
        return days === null ? -1 : days + 1;
    }

    function refresh() {
        if (profileId >= 0) {
            var key = DataManager.dataKey();
            var profile = DataManager.getProfile(profileId);
            profileName = profile ? profile.firstName : "";
            var cycles = DataManager.getMenstrualCycles(profileId);
            var rows = [];
            for (var i = 0; i < cycles.length; i++) {
                rows.push({ id: cycles[i].id, startDate: cycles[i].startDate,
                            endDate: cycles[i].endDate ? cycles[i].endDate : "",
                            note: cycles[i].note ? cycles[i].note : "",
                            lengthDays: cycleLength(cycles, i),
                            periodDays: periodLength(cycles[i]),
                            // Newest first: the cycle after this one is the row before.
                            nextStart: i > 0 ? String(cycles[i - 1].startDate) : "" });
            }
            listModel.clear();
            if (rows.length > 0) {
                listModel.append(rows);
            }
            loaded = true;
            loadedFrom = key;
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: listModel
        spacing: Theme.paddingMedium

        header: PageHeader {
            width: listView.width
            title: qsTr("Cycle history")
            description: page.profileName
        }

        footer: Item {
            width: listView.width
            height: Theme.paddingLarge
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
            contentHeight: cycleColumn.height + 2 * Theme.paddingLarge
            // The card shows the pressed state itself.
            highlightedColor: "transparent"

            // On the row, not in the menu: the menu is destroyed as soon as it closes,
            // before the remorse runs out, and its model.id with it.
            function remove() {
                // Read now: the rows are rebuilt if anything is saved during the countdown.
                var id = model.id;
                cycleItem.remorseDelete(function() {
                    DataManager.deleteMenstrualCycle(id);
                    // Reloaded rather than removed: the neighbouring cycle's length
                    // depends on this one.
                    page.refresh();
                })
            }

            // Built when first opened. Created with every row, the menu made each
            // row about ten times slower to build, which showed while scrolling.
            menu: Component {
                ContextMenu {
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
                        onClicked: cycleItem.remove()
                    }
                }
            }

            CardBackground {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: parent.height
                highlighted: cycleItem.highlighted
            }

            Column {
                id: cycleColumn
                x: Theme.horizontalPageMargin + Theme.paddingLarge
                y: Theme.paddingLarge
                width: parent.width - 2 * (Theme.horizontalPageMargin + Theme.paddingLarge)
                spacing: Theme.paddingSmall

                Item {
                    width: parent.width
                    height: Math.max(rangeLabel.height, lengthLabel.height, progressPill.height)

                    Label {
                        id: rangeLabel
                        anchors.left: parent.left
                        anchors.right: model.lengthDays >= 0 ? lengthLabel.left : progressPill.left
                        anchors.rightMargin: Theme.paddingMedium
                        anchors.verticalCenter: parent.verticalCenter
                        truncationMode: TruncationMode.Fade
                        text: qsTr("Started on %1").arg(Utils.formatDate(model.startDate))
                        color: cycleItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                    }
                    Label {
                        id: lengthLabel
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: model.lengthDays >= 0
                        text: model.lengthDays >= 0 ? qsTr("%n day(s)", "", model.lengthDays) : ""
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryHighlightColor
                    }
                    StatusPill {
                        id: progressPill
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: model.lengthDays < 0 ? qsTr("In progress") : ""
                        dotColor: Theme.highlightColor
                    }
                }

                // How long the period lasted, apart from the length of the cycle above.
                Label {
                    width: parent.width
                    visible: model.periodDays >= 0
                    truncationMode: TruncationMode.Fade
                    //: In the cycle history: how many days the period of a cycle lasted
                    text: model.periodDays >= 0 ? qsTr("Period of %n day(s)", "", model.periodDays) : ""
                    font.pixelSize: Theme.fontSizeExtraSmall
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
                note: model.note,
                lengthDays: model.lengthDays,
                nextStart: model.nextStart
            })
        }

        VerticalScrollDecorator {}

        ViewPlaceholder {
            enabled: page.loaded && listModel.count === 0
            text: qsTr("No cycles recorded")
            hintText: qsTr("Pull down to record a new cycle")
        }
    }

    ListModel {
        id: listModel
    }

    onStatusChanged: {
        if (status === PageStatus.Active && DataManager.dataKey() !== loadedFrom) {
            refresh();
        }
    }
}

// vim:et:ts=4:sw=4
