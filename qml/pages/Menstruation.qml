import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property var lastCycle: null
    property var todayLog: null
    property int dayOfCycle: 0

    function refresh() {
        if (profileId >= 0) {
            var cycles = DataManager.getMenstrualCycles(profileId);
            if (cycles.length > 0) {
                lastCycle = cycles[0];
                var start = new Date(lastCycle.startDate);
                var today = new Date();
                today.setHours(0,0,0,0);
                dayOfCycle = Math.floor((today - start) / (1000 * 60 * 60 * 24)) + 1;
            } else {
                lastCycle = null;
                dayOfCycle = 0;
            }

            var todayStr = new Date().toISOString().split('T')[0];
            var logs = DataManager.getMenstrualLogs(profileId, todayStr);
            todayLog = logs.length > 0 ? logs[0] : null;
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Add Today's Data")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddTodayInfo.qml"), {profileId: page.profileId})
            }
            MenuItem {
                text: qsTr("History")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("HistoryOfAllCycle.qml"), {profileId: page.profileId})
            }
            MenuItem {
                text: qsTr("New Cycle")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddNewCycle.qml"), {profileId: page.profileId})
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            Item { width: parent.width; height: childrenRect.height
                PageHeader { anchors.right: parent.right; anchors.rightMargin: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin; title: qsTr("Menstrual Cycle") }
            }

            Item { width: parent.width; height: childrenRect.height
                SectionHeader { anchors.right: parent.right; anchors.rightMargin: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin; text: qsTr("Current Cycle") }
            }

            Column {
                width: parent.width
                spacing: Theme.paddingMedium
                visible: lastCycle !== null

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    text: qsTr("Day %1").arg(dayOfCycle)
                    font.pixelSize: Theme.fontSizeExtraLarge
                    color: Theme.highlightColor
                }

                DetailItem {
                    label: qsTr("Started on")
                    value: lastCycle ? lastCycle.startDate : ""
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

            Item { width: parent.width; height: childrenRect.height; visible: todayLog !== null
                SectionHeader { anchors.right: parent.right; anchors.rightMargin: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin; text: qsTr("Today's Summary") }
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
                    value: todayLog ? qsTr("%1 hours").arg(todayLog.sleepTime) : ""
                }
            }
        }

        VerticalScrollDecorator {}
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            refresh();
        }
    }

    Component.onCompleted: refresh()
}
