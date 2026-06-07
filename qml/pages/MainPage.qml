import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../components"

Page {
    id: mainPage

    signal invalidateMetric(string metricName)

    allowedOrientations: Orientation.All

    property bool debug: true
    property int profileCount: 0
    property int profileId: -1
    property var profile
    property var weightLog
    property var waterLog
    property var calorieLog
    property var countVaccines


    function updateData() {
	    mainPage.profileCount = DataManager.countProfiles();
	    if (mainPage.profileCount > 0) {
	        mainPage.profileId = DataManager.lastUsedProfileId();
            print("setting profile to id " + mainPage.profileId);
        }
	    if (mainPage.profileId >= 0) {
	        mainPage.profile = DataManager.getProfile(mainPage.profileId);
            refreshModules();
            mainPage.countVaccines = DataManager.getVaccineCount(mainPage.profileId);
        }
    }

    function refreshModules() {
        modelModules.clear();
        DataManager.addModulesToModel(mainPage.profileId, modelModules, true);
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            print("page status changed");
            updateData();
        }
    }

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Debug DB")
                visible: debug
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("DebugDB.qml"))
            }
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
                visible: profileCount == 0
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("createProfile.qml"))
            }
            MenuItem {
                text: qsTr("Settings")
                visible: mainPage.profileId >= 0
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("moduleSettings.qml"), {
                    profileId: mainPage.profileId
                })
            }
            MenuItem {
                text: qsTr("Add entry")
                visible: mainPage.profileId >= 0
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("addEntryMetric.qml"), {
                    profileId: mainPage.profileId,
                    invalidateSignal: mainPage.invalidateMetric
                })
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("My Health")
            }

            Label {
                x: Theme.horizontalPageMargin
                text: profile ? profile.firstName : qsTr("No Profile Selected")
                font.pixelSize: Theme.fontSizeExtraLarge
                color: Theme.highlightColor
            }
        }

        SilicaGridView {
            id: dashboardGrid

            width: parent.width

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: column.bottom
            anchors.bottom: parent.bottom
            anchors.topMargin: Theme.paddingLarge

            cellWidth: dashboardGrid.width / 2
            cellHeight: Theme.itemSizeHuge

            visible: profile

            model: modelModules

            delegate: HealthCard {
                icon: model.icon ? Qt.resolvedUrl("../icons/" + model.icon) : "image://theme/icon-m-health"
                title: model.name
                visible: model.is_on
                profileId: mainPage.profileId
                metricName: model.type == DataManager.MODULE_TYPE_METRIC ? model.uses : ''
                unit: model.unit ? model.unit: undefined
                clickThrough: model.type == DataManager.MODULE_TYPE_SUMMARY ? model.uses : undefined
                calculate: model.type == DataManager.MODULE_TYPE_CALC ? model.uses : undefined
                invalidateSignal: mainPage.invalidateMetric
            }
        }
    }

    ListModel {
        id: modelModules
    }

    Component.onCompleted: updateData()
}

// vim:et:ts=4:sw=4
