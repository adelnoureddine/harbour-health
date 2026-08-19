import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property var lastCycle: null
    property var todayLog: null
    property int dayOfCycle: 0
    property var averageCycleLength: null

    readonly property bool cycleOpen: lastCycle !== null && !lastCycle.endDate

    function refresh() {
        if (profileId < 0) {
            return;
        }

        var cycles = DataManager.getMenstrualCycles(profileId);
        if (cycles.length > 0) {
            lastCycle = cycles[0];
            // Both sides parsed as local dates: new Date("2026-08-19") would be UTC
            // midnight and could land a day off once compared with local midnight.
            var start = Utils.fromLocalDateString(lastCycle.startDate);
            var today = new Date();
            today.setHours(0, 0, 0, 0);
            dayOfCycle = start === null ? 0
                       : Math.floor((today - start) / 86400000) + 1;
        } else {
            lastCycle = null;
            dayOfCycle = 0;
        }

        averageCycleLength = DataManager.getAverageCycleLength(profileId);

        var logs = DataManager.getMenstrualLogs(profileId, Utils.toLocalDateString(new Date()));
        todayLog = logs.length > 0 ? logs[0] : null;
    }

    function endCurrentCycle() {
        if (lastCycle === null) {
            return;
        }
        DataManager.updateMenstrualCycle(lastCycle.id, lastCycle.startDate,
                                         Utils.toLocalDateString(new Date()), lastCycle.note);
        refresh();
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("New Cycle")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddNewCycle.qml"), {profileId: page.profileId})
            }
            MenuItem {
                text: qsTr("End current cycle")
                visible: page.cycleOpen
                onClicked: endRemorse.execute(qsTr("Ending cycle"), function() { page.endCurrentCycle(); })
            }
            MenuItem {
                text: qsTr("History")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("HistoryOfAllCycle.qml"), {profileId: page.profileId})
            }
            MenuItem {
                text: qsTr("Add Today's Data")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddTodayInfo.qml"), {profileId: page.profileId})
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Menstrual Cycle")
            }

            SectionHeader {
                text: qsTr("Current Cycle")
            }

            Column {
                width: parent.width
                spacing: Theme.paddingMedium
                visible: lastCycle !== null

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    truncationMode: TruncationMode.Fade
                    text: page.cycleOpen ? qsTr("Day %1").arg(dayOfCycle) : qsTr("Cycle ended")
                    font.pixelSize: Theme.fontSizeExtraLarge
                    color: Theme.highlightColor
                }

                DetailItem {
                    label: qsTr("Started on")
                    value: lastCycle ? Utils.formatDate(lastCycle.startDate) : ""
                }

                DetailItem {
                    label: qsTr("Ended on")
                    value: lastCycle && lastCycle.endDate ? Utils.formatDate(lastCycle.endDate) : ""
                    visible: lastCycle !== null && lastCycle.endDate
                }

                DetailItem {
                    label: qsTr("Average cycle")
                    value: averageCycleLength === null ? "" : qsTr("%1 days").arg(averageCycleLength)
                    visible: averageCycleLength !== null
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    // Without this the day counter just kept climbing indefinitely.
                    visible: page.cycleOpen && dayOfCycle > 60
                    text: qsTr("This cycle has been open for a long time. Pull down to end it or start a new one.")
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("No cycle recorded. Pull down to start a new cycle.")
                visible: lastCycle === null
                wrapMode: Text.Wrap
                color: Theme.secondaryColor
            }

            SectionHeader {
                text: qsTr("Today's Summary")
                visible: todayLog !== null
            }

            Column {
                width: parent.width
                visible: todayLog !== null

                DetailItem {
                    label: qsTr("Flow")
                    value: todayLog ? todayLog.flow : ""
                }
                DetailItem {
                    label: qsTr("Pain")
                    value: todayLog ? todayLog.pain : ""
                }
                DetailItem {
                    label: qsTr("Energy")
                    value: todayLog ? todayLog.energy : ""
                }
                DetailItem {
                    label: qsTr("Sleep")
                    value: todayLog ? qsTr("%1 hours").arg(Utils.formatValue(todayLog.sleepTime, 1)) : ""
                }
                DetailItem {
                    label: qsTr("Note")
                    value: todayLog && todayLog.note ? todayLog.note : ""
                    visible: value !== ""
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("Nothing recorded today. Pull down to add today's data.")
                visible: todayLog === null
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
            }
        }

        VerticalScrollDecorator {}
    }

    RemorsePopup { id: endRemorse }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            refresh();
        }
    }
}

// vim:et:ts=4:sw=4
