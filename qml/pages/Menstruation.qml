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
    property var lastCycle: null
    property var todayLog: null
    property int dayOfCycle: 0
    property var averageCycleLength: null
    // "YYYY-MM-DD" the next cycle is expected to start on, or "" without an average.
    property string nextStart: ""
    // What the page last loaded (see DataManager.dataKey). Coming back from a cancelled
    // dialog or the history does not reload.
    property string loadedFrom: ""
    property bool loaded: false

    readonly property bool cycleOpen: lastCycle !== null && !lastCycle.endDate
    readonly property bool hasAverage: averageCycleLength !== null
    readonly property bool ringShown: cycleOpen && hasAverage && dayOfCycle > 0
    // Days until the expected start; 0 is today, negative once it has passed.
    readonly property int daysToNext: hasAverage ? averageCycleLength - dayOfCycle + 1 : 0

    function refresh() {
        if (profileId < 0) {
            return;
        }
        var key = DataManager.dataKey();
        var profile = DataManager.getProfile(profileId);
        profileName = profile ? profile.firstName : "";

        var status = DataManager.getCycleStatus(profileId);
        averageCycleLength = status.averageLength;
        lastCycle = status.last;
        dayOfCycle = status.dayOfCycle;
        nextStart = status.nextStart;

        var logs = DataManager.getMenstrualLogs(profileId, Utils.toLocalDateString(new Date()));
        todayLog = logs.length > 0 ? logs[0] : null;
        loaded = true;
        loadedFrom = key;
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
        contentHeight: column.height + Theme.paddingLarge

        // The daily entry, used most, is closest at the bottom.
        PullDownMenu {
            MenuItem {
                text: qsTr("History")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("HistoryOfAllCycle.qml"), {profileId: page.profileId})
            }
            MenuItem {
                text: qsTr("New cycle")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddNewCycle.qml"), {profileId: page.profileId})
            }
            MenuItem {
                text: qsTr("End current cycle")
                visible: page.cycleOpen
                onClicked: endRemorse.execute(qsTr("Ending cycle"), function() { page.endCurrentCycle(); })
            }
            MenuItem {
                // The dialog loads what is already saved for the day.
                text: page.todayLog !== null ? qsTr("Edit today's data") : qsTr("Add today's data")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddTodayInfo.qml"), {profileId: page.profileId})
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Menstrual cycle")
                description: page.profileName
            }

            Card {
                visible: page.lastCycle !== null
                spacing: Theme.paddingMedium

                Row {
                    width: parent.width
                    spacing: Theme.paddingSmall

                    HighlightImage {
                        id: cycleIcon
                        width: Theme.iconSizeSmall
                        height: Theme.iconSizeSmall
                        sourceSize.width: Theme.iconSizeSmall
                        sourceSize.height: Theme.iconSizeSmall
                        source: Qt.resolvedUrl("../icons/cycle.svg")
                        color: Theme.secondaryHighlightColor
                    }
                    Label {
                        width: parent.width - cycleIcon.width - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        truncationMode: TruncationMode.Fade
                        text: page.cycleOpen ? qsTr("Current cycle") : qsTr("Last cycle")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryHighlightColor
                    }
                }

                // The day against the average length, once there are two cycles to
                // measure it from.
                Item {
                    width: parent.width
                    height: ring.height
                    visible: page.ringShown

                    ProgressCircle {
                        id: ring
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Theme.itemSizeHuge
                        height: width
                        value: page.hasAverage && page.averageCycleLength > 0
                               ? Math.min(1, page.dayOfCycle / page.averageCycleLength) : 0
                        progressColor: page.daysToNext < 0 ? Utils.constraintColor("orange") : Theme.highlightColor
                        backgroundColor: Theme.rgba(Theme.primaryColor, 0.2)
                    }

                    Column {
                        anchors.centerIn: ring
                        width: ring.width * 0.8

                        Label {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            fontSizeMode: Text.HorizontalFit
                            minimumPixelSize: Theme.fontSizeMedium
                            text: qsTr("Day %1").arg(page.dayOfCycle)
                            font.pixelSize: Theme.fontSizeExtraLarge
                            color: Theme.primaryColor
                        }
                        Label {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            truncationMode: TruncationMode.Fade
                            //: Under "Day 12" in the ring: the average cycle length
                            text: page.hasAverage ? qsTr("of %n day(s)", "", page.averageCycleLength) : ""
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryHighlightColor
                        }
                    }
                }

                Label {
                    width: parent.width
                    visible: !page.ringShown
                    truncationMode: TruncationMode.Fade
                    text: page.cycleOpen ? qsTr("Day %1").arg(page.dayOfCycle) : qsTr("Cycle ended")
                    font.pixelSize: Theme.fontSizeHuge
                    color: Theme.primaryColor
                }

                Grid {
                    id: facts
                    width: parent.width
                    columns: 2
                    columnSpacing: Theme.paddingLarge
                    rowSpacing: Theme.paddingMedium

                    readonly property real cellWidth: (width - columnSpacing) / 2

                    Column {
                        width: facts.cellWidth
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: qsTr("Started on")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: page.lastCycle ? Utils.formatDate(page.lastCycle.startDate) : ""
                            color: Theme.primaryColor
                        }
                    }

                    Column {
                        width: facts.cellWidth
                        visible: page.lastCycle !== null && !!page.lastCycle.endDate
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: qsTr("Ended on")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: page.lastCycle && page.lastCycle.endDate ? Utils.formatDate(page.lastCycle.endDate) : ""
                            color: Theme.primaryColor
                        }
                    }

                    Column {
                        width: facts.cellWidth
                        visible: page.nextStart !== ""
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            //: Caption over the date the next cycle should start on
                            text: qsTr("Next expected")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: Utils.formatDate(page.nextStart)
                            color: Theme.primaryColor
                        }
                        Label {
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: page.daysToNext > 0 ? qsTr("In about %n day(s)", "", page.daysToNext)
                                : page.daysToNext === 0 ? qsTr("Expected today")
                                //: The next cycle has not started although the average says it should have
                                : qsTr("%n day(s) later than usual", "", -page.daysToNext)
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                        }
                    }

                    Column {
                        width: facts.cellWidth
                        visible: page.hasAverage
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: qsTr("Average cycle")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: page.hasAverage ? qsTr("%n day(s)", "", page.averageCycleLength) : ""
                            color: Theme.primaryColor
                        }
                    }
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    // Without this the day counter just kept climbing indefinitely.
                    visible: page.cycleOpen && page.dayOfCycle > 60
                    text: qsTr("This cycle has been open for a long time. Pull down to end it or start a new one.")
                }
            }

            Card {
                subtle: true
                visible: page.loaded && page.lastCycle === null

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("No cycle recorded. Pull down to start a new cycle.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                }
            }

            Card {
                visible: page.todayLog !== null
                spacing: Theme.paddingMedium

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: qsTr("Today")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                }

                Flow {
                    width: parent.width
                    spacing: Theme.paddingLarge

                    Column {
                        spacing: Theme.paddingSmall
                        Label {
                            text: qsTr("Flow")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        StatusPill {
                            text: page.todayLog ? Utils.flowDisplayName(page.todayLog.flow) : ""
                            dotColor: page.todayLog ? Utils.cycleLevelColor("flow", page.todayLog.flow) : Theme.highlightColor
                        }
                    }
                    Column {
                        spacing: Theme.paddingSmall
                        Label {
                            text: qsTr("Pain")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        StatusPill {
                            text: page.todayLog ? Utils.painDisplayName(page.todayLog.pain) : ""
                            dotColor: page.todayLog ? Utils.cycleLevelColor("pain", page.todayLog.pain) : Theme.highlightColor
                        }
                    }
                    Column {
                        spacing: Theme.paddingSmall
                        Label {
                            text: qsTr("Energy")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        StatusPill {
                            text: page.todayLog ? Utils.energyDisplayName(page.todayLog.energy) : ""
                            dotColor: page.todayLog ? Utils.cycleLevelColor("energy", page.todayLog.energy) : Theme.highlightColor
                        }
                    }
                    Column {
                        spacing: Theme.paddingSmall
                        Label {
                            text: qsTr("Sleep")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        Label {
                            text: page.todayLog ? qsTr("%1 hours").arg(Utils.formatValue(page.todayLog.sleepTime, 1)) : ""
                            color: Theme.primaryColor
                        }
                    }
                }

                Label {
                    width: parent.width
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    text: page.todayLog && page.todayLog.note ? page.todayLog.note : ""
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
            }

            Card {
                subtle: true
                visible: page.loaded && page.todayLog === null

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("Nothing recorded today. Pull down to add today's data.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                }
            }
        }

        VerticalScrollDecorator {}
    }

    RemorsePopup { id: endRemorse }

    onStatusChanged: {
        if (status === PageStatus.Active && DataManager.dataKey() !== loadedFrom) {
            refresh();
        }
    }
}

// vim:et:ts=4:sw=4
