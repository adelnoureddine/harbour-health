import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

/*
 * Meditation at a glance: this week's sessions and minutes, when the last one was, and
 * the latest few sessions. The page used to be two bare buttons; starting a session
 * and the history are in the pull-down menu now.
 */
Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1

    property string profileName: ""
    property int totalSessions: 0
    property int weekSessions: 0
    property int weekSeconds: 0
    property string lastDate: ""
    property int lastDuration: 0
    readonly property int recentLimit: 3

    // What the page last loaded (see DataManager.dataKey). Coming back from the history
    // or a cancelled session does not reload.
    property string loadedFrom: ""
    property bool loaded: false

    // Local midnight starting this calendar week, by the locale's first day of the week
    // (Locale.Sunday is 0, as in Date.getDay()).
    function weekStart() {
        var first = Qt.locale().firstDayOfWeek;
        if (first === undefined || first === null || isNaN(first)) {
            first = 1;
        }
        var d = new Date();
        d.setHours(0, 0, 0, 0);
        d.setDate(d.getDate() - ((d.getDay() - first + 7) % 7));
        return d;
    }

    function refresh() {
        if (profileId < 0) {
            return;
        }
        var key = DataManager.dataKey();
        var profile = DataManager.getProfile(profileId);
        profileName = profile ? profile.firstName : "";

        var summary = DataManager.getMeditationSummary(profileId, weekStart(), recentLimit);
        var recent = summary.recent;
        totalSessions = summary.total;
        weekSessions = summary.weekCount;
        weekSeconds = summary.weekSeconds;
        lastDate = recent.length > 0 ? recent[0].date : "";
        lastDuration = recent.length > 0 ? recent[0].duration : 0;

        recentModel.clear();
        if (recent.length > 0) {
            recentModel.append(recent);
        }
        loaded = true;
        loadedFrom = key;
    }

    function openHistory() {
        pageStack.animatorPush(Qt.resolvedUrl("History.qml"), { profileId: page.profileId });
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        PullDownMenu {
            // Minutes a day, shown on the Today page once set.
            MenuItem {
                text: qsTr("Daily goal")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("setGoal.qml"), {
                    profileId: page.profileId,
                    metricName: DataManager.GOAL_MEDITATION,
                    metricUnit: qsTr("min")
                })
            }
            MenuItem {
                text: qsTr("History")
                onClicked: page.openHistory()
            }
            MenuItem {
                text: qsTr("New session")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("NewSession.qml"), { profileId: page.profileId })
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Meditation")
                description: page.profileName
            }

            Card {
                visible: page.totalSessions > 0
                spacing: Theme.paddingMedium

                Row {
                    width: parent.width
                    spacing: Theme.paddingSmall

                    HighlightImage {
                        id: weekIcon
                        width: Theme.iconSizeSmall
                        height: Theme.iconSizeSmall
                        sourceSize.width: Theme.iconSizeSmall
                        sourceSize.height: Theme.iconSizeSmall
                        source: Qt.resolvedUrl("../icons/meditation.svg")
                        color: Theme.secondaryHighlightColor
                    }
                    Label {
                        width: parent.width - weekIcon.width - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        truncationMode: TruncationMode.Fade
                        text: qsTr("This week")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryHighlightColor
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.paddingLarge

                    Column {
                        width: (parent.width - parent.spacing) / 2
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            //: Caption over the number of meditation sessions this week
                            text: qsTr("Sessions")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: page.weekSessions
                            font.pixelSize: Theme.fontSizeHuge
                            color: Theme.primaryColor
                        }
                    }
                    Column {
                        width: (parent.width - parent.spacing) / 2
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            //: Caption over the meditation minutes this week
                            text: qsTr("Minutes")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: Utils.wholeMinutes(page.weekSeconds)
                            font.pixelSize: Theme.fontSizeHuge
                            color: Theme.primaryColor
                        }
                    }
                }

                Label {
                    width: parent.width
                    visible: page.lastDate !== ""
                    wrapMode: Text.Wrap
                    //: %1 is when the latest session was ("Yesterday", "Today, 07:40"), %2 its length
                    text: qsTr("Last session: %1 · %2").arg(Utils.relativeTime(page.lastDate, true))
                                                       .arg(Utils.formatDuration(page.lastDuration))
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
            }

            Column {
                width: parent.width
                visible: recentModel.count > 0

                SectionHeader {
                    text: qsTr("Recent sessions")
                }

                Repeater {
                    model: recentModel

                    ListItem {
                        id: sessionItem
                        contentHeight: Theme.itemSizeMedium
                        onClicked: page.openHistory()

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            x: Theme.horizontalPageMargin
                            width: parent.width - 2 * Theme.horizontalPageMargin - whenLabel.width - Theme.paddingMedium

                            Label {
                                width: parent.width
                                truncationMode: TruncationMode.Fade
                                text: Utils.formatDuration(model.duration)
                                color: sessionItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                            }
                            Label {
                                width: parent.width
                                truncationMode: TruncationMode.Fade
                                text: model.name !== "" ? model.name : qsTr("Meditation session")
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: sessionItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                            }
                        }

                        Label {
                            id: whenLabel
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.horizontalPageMargin
                            anchors.verticalCenter: parent.verticalCenter
                            text: Utils.relativeTime(model.date, true)
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: sessionItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                    }
                }
            }
        }

        ViewPlaceholder {
            enabled: page.loaded && page.totalSessions === 0
            text: qsTr("No sessions yet")
            hintText: qsTr("Pull down to start a new session")
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: recentModel
    }

    onStatusChanged: {
        if (status === PageStatus.Active && DataManager.dataKey() !== loadedFrom) {
            refresh();
        }
    }
}

// vim:et:ts=4:sw=4
