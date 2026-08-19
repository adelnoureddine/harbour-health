import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
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

    function updateData() {
        mainPage.profileCount = DataManager.countProfiles();
        mainPage.profileId = mainPage.profileCount > 0 ? DataManager.lastUsedProfileId() : -1;
        if (mainPage.profileId >= 0) {
            mainPage.profile = DataManager.getProfile(mainPage.profileId);
            refreshModules();
        } else {
            mainPage.profile = undefined;
            modelModules.clear();
        }
    }

    function refreshModules() {
        modelModules.clear();
        DataManager.addModulesToModel(mainPage.profileId, modelModules, true);
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
                title: qsTr("My Health")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: profile ? profile.firstName : qsTr("No Profile Selected")
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
            title: model.name
            profileId: mainPage.profileId
            metricName: model.type == DataManager.MODULE_TYPE_METRIC ? model.uses : (model.name == DataManager.MODULE_BP ? DataManager.METRIC_BP_SYS : '')
            metricName2: model.name == DataManager.MODULE_BP ? DataManager.METRIC_BP_DIA : ''
            unit: model.unit ? model.unit : undefined
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

    Component.onCompleted: updateData()
}

// vim:et:ts=4:sw=4
