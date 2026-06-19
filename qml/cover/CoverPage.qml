import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

CoverBackground {

    property int profileId: -1
    property var profile: null
    property string metric1: "weight"
    property string metric2: "water"
    property var value1: null
    property var value2: null

    function getMetricValue(metricName) {
        var grouped = DataManager.getMetricGrouped(metricName);
        if (grouped) {
            return DataManager.getLatestDayLogValue(profileId, metricName);
        } else {
            return DataManager.getLatestLogValue(profileId, metricName);
        }
    }

    function getMetricUnit(metricName) {
        return DataManager.getMetricUnit(metricName) || "";
    }

    function refresh() {
        profileId = DataManager.lastUsedProfileId();
        if (profileId >= 0) {
            profile = DataManager.getProfile(profileId);
            var metrics = DataManager.getCoverMetrics(profileId);
            metric1 = metrics.metric1;
            metric2 = metrics.metric2;
            value1 = getMetricValue(metric1);
            value2 = getMetricValue(metric2);
        }
    }

    onStatusChanged: {
        if (status === Cover.Active) {
            refresh();
        }
    }

    Component.onCompleted: refresh()

    Column {
        anchors.centerIn: parent
        spacing: Theme.paddingSmall

        Image {
            source: "/usr/share/icons/hicolor/128x128/apps/harbour-health.png"
            width: 80
            height: 80
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            text: "Health"
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.primaryColor
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            text: profile ? profile.firstName : ""
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.highlightColor
            anchors.horizontalCenter: parent.horizontalCenter
            visible: profile !== null
        }

        Rectangle {
            width: 120
            height: 1
            color: Theme.primaryColor
            opacity: 0.3
            anchors.horizontalCenter: parent.horizontalCenter
            visible: profile !== null
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingMedium
            visible: profile !== null

            Column {
                spacing: 2
                Label {
                    text: metric1
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Label {
                    text: value1 ? value1 + " " + getMetricUnit(metric1) : "?"
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    color: Theme.primaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            Rectangle {
                width: 1
                height: 30
                color: Theme.primaryColor
                opacity: 0.3
            }

            Column {
                spacing: 2
                Label {
                    text: metric2
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Label {
                    text: value2 ? value2 + " " + getMetricUnit(metric2) : "?"
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    color: Theme.primaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    CoverActionList {
        id: coverAction
        CoverAction {
            onTriggered: {
                if (profileId >= 0) {
                    pageStack.animatorPush(Qt.resolvedUrl("../pages/addEntryMetric.qml"), {
                        profileId: profileId,
                        invalidateSignal: function() {}
                    });
                }
                appWindow.activate();
            }
            iconSource: "image://theme/icon-cover-new"
        }
    }
}

// vim:et:ts=4:sw=4
