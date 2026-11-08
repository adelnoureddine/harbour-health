import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

/*
 * The cover: the profile's two cover metrics (Cover page settings), a daily total as
 * a ring and anything else with its trend. When water is one of them, a cover action
 * logs a glass without opening the app.
 *
 * Or, chosen in the same settings, the day's to-do list. One action then opens the
 * Today page; the other adds a glass of water when water is on the list, otherwise a
 * new measurement.
 */
CoverBackground {
    id: cover

    property int profileId: -1
    property var profile: null
    property string metric1: DataManager.METRIC_WEIGHT
    property string metric2: DataManager.METRIC_WATER
    readonly property bool todayMode: metric1 === DataManager.COVER_TODAY
    readonly property bool waterShown: metric1 === DataManager.METRIC_WATER
                                       || metric2 === DataManager.METRIC_WATER
    // What the cover last showed (see DataManager.dataKey). It becomes active every
    // time the home screen shows, and reloading with nothing written was wasted work.
    property string loadedFrom: ""

    function refresh() {
        var key = DataManager.dataKey();
        if (key === loadedFrom) {
            return;
        }
        profileId = DataManager.lastUsedProfileId();
        profile = profileId >= 0 ? DataManager.getProfile(profileId) || null : null;
        if (profile !== null) {
            var metrics = DataManager.getCoverMetrics(profileId);
            metric1 = metrics.metric1;
            metric2 = metrics.metric2;
            if (todayMode) {
                today.refresh();
            } else {
                first.refresh();
                second.refresh();
            }
        }
        // Recorded last, so a refresh that failed half way is tried again.
        loadedFrom = key;
    }

    // A glass of water, logged without opening the app.
    function addGlass() {
        DataManager.addLog(cover.profileId, DataManager.METRIC_WATER, 0.25, new Date(), "");
        cover.refresh();
    }

    function openToday() {
        if (cover.profileId < 0) {
            return;
        }
        pageStack.animatorPush(Qt.resolvedUrl("../pages/TodayPage.qml"), { profileId: cover.profileId });
        appWindow.activate();
    }

    function openAddEntry() {
        if (cover.profileId < 0) {
            return;
        }
        if (cover.todayMode) {
            // No metric on the cover to preselect: the measurement picker.
            pageStack.animatorPush(Qt.resolvedUrl("../pages/pickMeasurement.qml"), { profileId: cover.profileId });
        } else if (cover.metric1 === DataManager.METRIC_BP_SYS || cover.metric1 === DataManager.METRIC_BP_DIA) {
            // A blood pressure half on the cover opens the dialog for the pair.
            pageStack.animatorPush(Qt.resolvedUrl("../pages/addEntryMultiMetric.qml"), {
                profileId: cover.profileId,
                metricName1: DataManager.METRIC_BP_SYS,
                metricName2: DataManager.METRIC_BP_DIA,
                metricUnit: first.unit
            });
        } else {
            // Pre-selects the first cover metric but still lets the type be changed.
            pageStack.animatorPush(Qt.resolvedUrl("../pages/addEntryMetric.qml"), {
                profileId: cover.profileId,
                metricName: cover.metric1,
                metricUnit: first.unit
            });
        }
        appWindow.activate();
    }

    onStatusChanged: {
        if (status === Cover.Active) {
            refresh();
        }
    }

    Component.onCompleted: refresh()

    Column {
        x: Theme.paddingLarge
        y: Theme.paddingLarge
        width: parent.width - 2 * Theme.paddingLarge
        spacing: Theme.paddingMedium

        Label {
            width: parent.width
            truncationMode: TruncationMode.Fade
            //: Cover header: the app name and the profile's first name
            text: cover.profile ? qsTr("Health · %1").arg(cover.profile.firstName) : qsTr("Health")
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.highlightColor
        }

        CoverMetric {
            id: first
            width: parent.width
            visible: cover.profile !== null && !cover.todayMode
            profileId: cover.profileId
            metricName: cover.metric1
        }

        CoverMetric {
            id: second
            width: parent.width
            visible: cover.profile !== null && !cover.todayMode
            profileId: cover.profileId
            metricName: cover.metric2
        }

        CoverToday {
            id: today
            width: parent.width
            visible: cover.profile !== null && cover.todayMode
            profileId: cover.profileId
        }
    }

    // Two actions while water is on the cover: a glass of water, logged right here,
    // and a new entry in the app. Otherwise only the latter.
    CoverActionList {
        enabled: cover.profile !== null && !cover.todayMode && cover.waterShown
        CoverAction {
            iconSource: Qt.resolvedUrl("../icons/cover-water.svg")
            onTriggered: cover.addGlass()
        }
        CoverAction {
            iconSource: "image://theme/icon-cover-new"
            onTriggered: cover.openAddEntry()
        }
    }

    CoverActionList {
        enabled: cover.profile !== null && !cover.todayMode && !cover.waterShown
        CoverAction {
            iconSource: "image://theme/icon-cover-new"
            onTriggered: cover.openAddEntry()
        }
    }

    // The to-do list on the cover: the Today page takes the second action.
    CoverActionList {
        enabled: cover.profile !== null && cover.todayMode && today.hasWater
        CoverAction {
            iconSource: Qt.resolvedUrl("../icons/cover-water.svg")
            onTriggered: cover.addGlass()
        }
        CoverAction {
            iconSource: Qt.resolvedUrl("../icons/cover-today.svg")
            onTriggered: cover.openToday()
        }
    }

    CoverActionList {
        enabled: cover.profile !== null && cover.todayMode && !today.hasWater
        CoverAction {
            iconSource: "image://theme/icon-cover-new"
            onTriggered: cover.openAddEntry()
        }
        CoverAction {
            iconSource: Qt.resolvedUrl("../icons/cover-today.svg")
            onTriggered: cover.openToday()
        }
    }
}

// vim:et:ts=4:sw=4
