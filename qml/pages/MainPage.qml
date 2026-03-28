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
            bmiCard.calculate();
            mainPage.countVaccines = DataManager.getVaccineCount(mainPage.profileId);
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            print("page status changed");
            updateData();
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

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
                text: qsTr("Add entry")
		        visible: mainPage.profileId >= 0
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("addEntryMetric.qml"), {
                    profileId: mainPage.profileId
                })
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

            // Dashboard Grid
            Grid {
                id: dashboardGrid
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 2
                spacing: Theme.paddingMedium
		        visible: profile

                // height Card
                MetricCard {
                    width: (dashboardGrid.width - dashboardGrid.spacing) / 2
                    icon: "image://theme/icon-m-health"
                    title: qsTr("Height")
                    profileId: mainPage.profileId
                    metricName: DataManager.METRIC_HEIGHT
                    invalidateSignal: mainPage.invalidateMetric
                }

                // Weight Card
                MetricCard {
                    width: (dashboardGrid.width - dashboardGrid.spacing) / 2
                    icon: "image://theme/icon-m-health"
                    title: qsTr("Weight")
                    profileId: mainPage.profileId
                    metricName: DataManager.METRIC_WEIGHT
                    invalidateSignal: mainPage.invalidateMetric
                }

                // BMI Card
                SummaryCard {
                    id: bmiCard

                    width: (dashboardGrid.width - dashboardGrid.spacing) / 2
                    icon: "image://theme/icon-m-health"
                    title: qsTr("BMI")
                    value: '?'

                    function calculate() {
                        var bmi = DataManager.calcBMI(mainPage.profileId)
                        bmiCard.value = bmi ? bmi.toFixed(1) : '?';
                    }
                }

                // Water Card
                MetricCard {
                    width: (dashboardGrid.width - dashboardGrid.spacing) / 2
                    title: qsTr("Water")
                    icon: "image://theme/icon-m-levels"
                    grouped: true
                    profileId: mainPage.profileId
                    metricName: DataManager.METRIC_WATER
                    invalidateSignal: mainPage.invalidateMetric
                }

                // Calories Card
                MetricCard {
                    width: (dashboardGrid.width - dashboardGrid.spacing) / 2
                    title: qsTr("Calories")
                    icon: "image://theme/icon-m-levels"
                    grouped: true
                    profileId: mainPage.profileId
                    metricName: DataManager.METRIC_CALORIES
                    invalidateSignal: mainPage.invalidateMetric
                }

                // Vaccines Card
                SummaryCard {
                    width: (dashboardGrid.width - dashboardGrid.spacing) / 2
                    title: qsTr("Vaccines")
                    value: countVaccines
		            visible: mainPage.profileId >= 0
                    unit: qsTr("records")
                    icon: "image://theme/icon-m-certificates"
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("VaccinesList.qml"), {
                        profileId: mainPage.profileId
                    })
                }
            }

            SectionHeader {
                text: qsTr("Other Modules")
            }

            ButtonLayout {
                Button {
                    text: qsTr("Meditation")
		            visible: mainPage.profileId >= 0
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("MeditationMenu.qml"), {
                        profileId: mainPage.profileId
                    })
                }
                Button {
                    text: qsTr("Health Condition")
		            visible: mainPage.profileId >= 0
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainHealthCondition.qml"), {
                        profileId: mainPage.profileId
                    })
                }
                Button {
                    text: qsTr("Menstruation")
		            visible: mainPage.profileId >= 0
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("Menstruation.qml"), {
                        profileId: mainPage.profileId
                    })
                }
            }
        }
    }

    onInvalidateMetric: {
        if (metricName == DataManager.METRIC_HEIGHT || metricName == DataManager.METRIC_WEIGHT) {
            bmiCard.calculate();
        }
    }

    Component.onCompleted: updateData()
}

// vim:et:ts=4:sw=4
