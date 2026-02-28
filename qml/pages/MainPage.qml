import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property var profile: null
    property var weightLog: null
    property var waterLog: null
    property var calorieLog: null
    property int vaccineCount: 0

    function updateData() {
        var profiles = DataManager.getProfiles();
        if (profiles.length > 0) {
            profile = profiles[0];
            weightLog = DataManager.getLatestLog(profile.id, "weight");
            waterLog = DataManager.getLatestLog(profile.id, "water");
            calorieLog = DataManager.getLatestLog(profile.id, "calories");
            vaccineCount = DataManager.getVaccineCount(profile.id);
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            updateData();
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: qsTr("Settings / Profiles")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("chooseProfile.qml"))
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
                text: profile ? qsTr("Hello, %1").arg(profile.firstName) : qsTr("No Profile Selected")
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

                // Weight Card
                SummaryCard {
                    width: (dashboardGrid.width - dashboardGrid.spacing) / 2
                    title: qsTr("Weight")
                    value: weightLog ? weightLog.value : "--"
                    unit: weightLog ? weightLog.unit : "kg"
                    icon: "image://theme/icon-m-health"
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("MetricDetails.qml"), {
                        profileId: profile ? profile.id : 1,
                        metricId: 1, 
                        metricName: "weight",
                        metricUnit: "kg"
                    })
                }

                // Water Card
                SummaryCard {
                    width: (dashboardGrid.width - dashboardGrid.spacing) / 2
                    title: qsTr("Water")
                    value: waterLog ? waterLog.value : "0"
                    unit: "L"
                    icon: "image://theme/icon-m-levels"
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("Nutrition.qml"), {profileId: profile ? profile.id : 1})
                }

                // Calories Card
                SummaryCard {
                    width: (dashboardGrid.width - dashboardGrid.spacing) / 2
                    title: qsTr("Calories")
                    value: calorieLog ? calorieLog.value : "0"
                    unit: "kcal"
                    icon: "image://theme/icon-m-levels"
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("Nutrition.qml"), {profileId: profile ? profile.id : 1})
                }

                // Vaccines Card
                SummaryCard {
                    width: (dashboardGrid.width - dashboardGrid.spacing) / 2
                    title: qsTr("Vaccines")
                    value: vaccineCount
                    unit: qsTr("records")
                    icon: "image://theme/icon-m-certificates"
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("VaccinesList.qml"), {profileId: profile ? profile.id : 1})
                }
            }

            SectionHeader {
                text: qsTr("Quick Actions")
            }

            Row {
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingMedium

                Button {
                    width: (parent.width - Theme.paddingMedium) / 2
                    text: qsTr("Log Water")
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddnewData.qml"), {
                        profileId: profile ? profile.id : 1,
                        metricType: "water"
                    })
                }
                Button {
                    width: (parent.width - Theme.paddingMedium) / 2
                    text: qsTr("Log Weight")
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("addEntryMetric.qml"), {
                        profileId: profile ? profile.id : 1,
                        metricId: 1,
                        metricName: "weight",
                        metricUnit: "kg"
                    })
                }
            }

            SectionHeader {
                text: qsTr("All Modules")
            }

            ButtonLayout {
                Button {
                    text: qsTr("Meditation")
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("MeditationMenu.qml"), {profileId: profile ? profile.id : 1})
                }
                Button {
                    text: qsTr("Health Condition")
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainHealthCondition.qml"), {profileId: profile ? profile.id : 1})
                }
                Button {
                    text: qsTr("Menstruation")
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("Menstruation.qml"), {profileId: profile ? profile.id : 1})
                }
            }
        }
    }

    Component.onCompleted: updateData()
}

