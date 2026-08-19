import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

CoverBackground {
    id: cover

    property int profileId: -1
    property var profile: null
    property string metric1: DataManager.METRIC_WEIGHT
    property string metric2: DataManager.METRIC_WATER
    property var value1: null
    property var value2: null

    function metricValue(metricName) {
        if (DataManager.getMetricGrouped(metricName)) {
            return DataManager.getLatestDayLogValue(profileId, metricName);
        }
        return DataManager.getLatestLogValue(profileId, metricName);
    }

    function displayFor(value, metricName) {
        if (value === null || value === undefined) {
            return "—";
        }
        var unit = DataManager.getMetricUnit(metricName);
        return Utils.formatValue(value) + (unit ? " " + unit : "");
    }

    function refresh() {
        profileId = DataManager.lastUsedProfileId();
        if (profileId < 0) {
            profile = null;
            return;
        }
        profile = DataManager.getProfile(profileId);
        var metrics = DataManager.getCoverMetrics(profileId);
        metric1 = metrics.metric1;
        metric2 = metrics.metric2;
        value1 = metricValue(metric1);
        value2 = metricValue(metric2);
    }

    onStatusChanged: {
        if (status === Cover.Active) {
            refresh();
        }
    }

    Component.onCompleted: refresh()

    Column {
        anchors.centerIn: parent
        width: parent.width - 2 * Theme.paddingMedium
        spacing: Theme.paddingSmall

        Image {
            source: "/usr/share/icons/hicolor/128x128/apps/harbour-health.png"
            // Fixed pixel sizes here did not scale across device densities.
            width: Theme.iconSizeLarge
            height: Theme.iconSizeLarge
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            text: qsTr("Health")
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.primaryColor
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            width: parent.width
            text: profile ? profile.firstName : ""
            horizontalAlignment: Text.AlignHCenter
            truncationMode: TruncationMode.Fade
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.highlightColor
            visible: profile !== null
        }

        Separator {
            width: parent.width
            color: Theme.rgba(Theme.primaryColor, 0.3)
            horizontalAlignment: Qt.AlignHCenter
            visible: profile !== null
        }

        Repeater {
            model: profile !== null ? 2 : 0

            Column {
                width: cover.width - 2 * Theme.paddingMedium
                spacing: 0

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    truncationMode: TruncationMode.Fade
                    // The raw internal name ("systolic blood pressure") used to be
                    // shown here, lowercase and untranslated.
                    text: Utils.metricDisplayName(index === 0 ? cover.metric1 : cover.metric2)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    truncationMode: TruncationMode.Fade
                    text: index === 0 ? cover.displayFor(cover.value1, cover.metric1)
                                      : cover.displayFor(cover.value2, cover.metric2)
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    color: Theme.primaryColor
                }
            }
        }
    }

    CoverActionList {
        id: coverAction
        CoverAction {
            iconSource: "image://theme/icon-cover-new"
            onTriggered: {
                if (cover.profileId >= 0) {
                    pageStack.animatorPush(Qt.resolvedUrl("../pages/addEntryMetric.qml"), {
                        profileId: cover.profileId,
                        metricName: cover.metric1,
                        // Pre-selects the first cover metric but still lets the
                        // type be changed. Opened from the cover the dialog used to
                        // have no metric at all, so Save could never be enabled.
                        metricUnit: DataManager.getMetricUnit(cover.metric1)
                    });
                }
                appWindow.activate();
            }
        }
    }
}

// vim:et:ts=4:sw=4
