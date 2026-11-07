import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

Page {
    id: mainPage
    // Looked up by DataTransfer after a restore, to unwind back to a clean dashboard.
    objectName: "dashboardPage"

    signal invalidateMetric(string metricName)

    allowedOrientations: Orientation.All

    property int profileCount: 0
    property int profileId: -1
    property var profile

    /*
     * What the tiles were last built from. Coming back to the dashboard used to destroy
     * and rebuild every tile (a few dozen queries, and the scroll position was lost)
     * even after just looking at a chart. Now it rebuilds only when something was
     * written -- a reading, a module switched, another profile chosen, a restore -- or
     * a new day has started for the water and calories tiles.
     */
    property string builtFrom: ""

    function updateData() {
        var key = DataManager.dataKey();
        if (key === builtFrom) {
            return;
        }

        // Cleared before profileId changes, or every old tile would first refresh
        // itself against the new profile just to be destroyed.
        modelModules.clear();
        mainPage.profileCount = DataManager.countProfiles();
        mainPage.profileId = mainPage.profileCount > 0 ? DataManager.lastUsedProfileId() : -1;
        if (mainPage.profileId >= 0) {
            mainPage.profile = DataManager.getProfile(mainPage.profileId);
            DataManager.addModulesToModel(mainPage.profileId, modelModules, true);
        } else {
            mainPage.profile = undefined;
        }
        // Recorded last, so a build that failed half way is tried again next time.
        builtFrom = key;
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            updateData();
        }
    }

    // The grid owns the pull-down menu directly. It used to sit on a SilicaFlickable
    // wrapped around the grid, so the two competed for the same drag gesture.
    SilicaGridView {
        id: dashboardGrid
        anchors.fill: parent

        // Two columns in portrait, four in landscape.
        cellWidth: width / (width > height ? 4 : 2)
        cellHeight: Theme.itemSizeHuge

        header: Column {
            width: dashboardGrid.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("My health")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: profile ? profile.firstName : qsTr("No profile selected")
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeExtraLarge
                color: Theme.highlightColor
            }

            // Positioner padding needs a newer QtQuick import than this file uses.
            Item { width: 1; height: Theme.paddingLarge }
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: qsTr("Profiles")
                visible: profileCount > 0
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("chooseProfile.qml"))
            }
            MenuItem {
                text: qsTr("Create a new profile")
                visible: profileCount === 0
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("createProfile.qml"))
            }
            MenuItem {
                text: qsTr("Backup and restore")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("DataTransfer.qml"))
            }
            MenuItem {
                text: qsTr("Settings")
                visible: mainPage.profileId >= 0
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("moduleSettings.qml"), {
                    profileId: mainPage.profileId
                })
            }
        }

        model: modelModules

        delegate: HealthCard {
            width: dashboardGrid.cellWidth
            height: dashboardGrid.cellHeight
            icon: model.icon ? Qt.resolvedUrl("../icons/" + model.icon) : "image://theme/icon-m-health"
            title: Utils.moduleDisplayName(model.name)
            // The stored (English) module name is the key reference bands are saved under.
            constraintKey: model.name
            profileId: mainPage.profileId
            metricName: model.type == DataManager.MODULE_TYPE_METRIC ? model.uses : (model.name == DataManager.MODULE_BP ? DataManager.METRIC_BP_SYS : '')
            metricName2: model.name == DataManager.MODULE_BP ? DataManager.METRIC_BP_DIA : ''
            unit: model.unit ? model.unit : undefined
            grouped: model.grouped ? true : false
            clickThrough: model.type == DataManager.MODULE_TYPE_SUMMARY ? model.uses : undefined
            calculate: model.type == DataManager.MODULE_TYPE_CALC ? model.uses : undefined
            invalidateSignal: mainPage.invalidateMetric
        }

        ViewPlaceholder {
            enabled: modelModules.count === 0
            text: mainPage.profileId >= 0 ? qsTr("No modules enabled") : qsTr("No profile yet")
            hintText: mainPage.profileId >= 0
                      ? qsTr("Pull down to open Settings and choose what to track")
                      : qsTr("Pull down to create a profile")
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: modelModules
    }

    // Shown only when the database itself could not be opened or upgraded.
    Rectangle {
        anchors.fill: parent
        color: Theme.overlayBackgroundColor
        visible: appWindow.databaseError !== ""

        Column {
            anchors.centerIn: parent
            width: parent.width - 2 * Theme.horizontalPageMargin
            spacing: Theme.paddingLarge

            Label {
                width: parent.width
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.highlightColor
                text: qsTr("Health could not open its database")
            }

            Label {
                width: parent.width
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                text: appWindow.databaseError
            }
        }
    }

    // No Component.onCompleted call: the page turning Active covers startup too, and
    // the dashboard used to be built twice in a row on every launch.
}

// vim:et:ts=4:sw=4
