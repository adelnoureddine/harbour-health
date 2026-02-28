import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../components"

Page {
    id: root
    allowedOrientations: Orientation.All

    property var profile: null
    property var caloriesLog: null
    property var waterLog: null

    function loadData() {
        var profiles = DataManager.getProfiles();
        if (profiles.length > 0) {
            profile = profiles[0];
            caloriesLog = DataManager.getLatestLog(profile.id, "calories");
            waterLog = DataManager.getLatestLog(profile.id, "water");
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            loadData();
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Add New Data")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddnewData.qml"), {profileId: root.profileId})
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Nutrition & Hydration")
            }

            SectionHeader {
                text: qsTr("Hydration")
            }

            SummaryCard {
                title: qsTr("Daily Water")
                value: waterLog ? waterLog.value : "0"
                unit: "L"
                icon: "image://theme/icon-m-levels"
                // Hydration recommendation logic
                property string recommendation: {
                    var val = waterLog ? waterLog.value : 0;
                    if (val < 1.5) return qsTr("Low hydration. Drink more!");
                    if (val < 3.0) return qsTr("Hydration is normal.");
                    return qsTr("Excellent hydration!");
                }
                
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: parent.recommendation
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryHighlightColor
                    visible: text !== ""
                }
            }

            SectionHeader {
                text: qsTr("Nutrition")
            }

            SummaryCard {
                title: qsTr("Daily Calories")
                value: caloriesLog ? caloriesLog.value : "0"
                unit: "kcal"
                icon: "image://theme/icon-m-levels"
                property string recommendation: {
                    var val = caloriesLog ? caloriesLog.value : 0;
                    if (val < 1500) return qsTr("Calorie intake is low.");
                    if (val < 2500) return qsTr("Calorie intake is within normal range.");
                    return qsTr("Calorie intake is high.");
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: parent.recommendation
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryHighlightColor
                    visible: text !== ""
                }
            }
        }
    }

    Component.onCompleted: loadData()
}
