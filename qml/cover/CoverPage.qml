import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

CoverBackground {

    property int profileId: -1
    property var profile: null
    property var weightValue: null
    property var waterValue: null

    function refresh() {
        profileId = DataManager.lastUsedProfileId();
        if (profileId >= 0) {
            profile = DataManager.getProfile(profileId);
            weightValue = DataManager.getLatestDayLogValue(profileId, DataManager.METRIC_CALORIES);
            waterValue = DataManager.getLatestDayLogValue(profileId, DataManager.METRIC_WATER);
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
                    text: qsTr("Calories")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Label {
                    text: weightValue ? weightValue + " kcal" : "?"
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
                    text: qsTr("Water")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Label {
                    text: waterValue ? waterValue + " L" : "?"
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
