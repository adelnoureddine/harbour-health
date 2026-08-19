import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property int medicationId
    property string medicationName

    function refresh() {
        todayModel.clear();
        historyModel.clear();
        var today = DataManager.getMedicationLogsToday(profileId, medicationId);
        today.forEach(function(l) { todayModel.append(l); });
        var history = DataManager.getMedicationLogsHistory(profileId, medicationId);
        history.forEach(function(l) { historyModel.append(l); });
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Log intake")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("LogMedicationIntake.qml"), {
                    profileId: page.profileId,
                    medicationId: page.medicationId,
                    medicationName: page.medicationName
                })
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: medicationName
            }

            SectionHeader {
                text: qsTr("Today's intakes")
            }

            Repeater {
                model: todayModel
                delegate: ListItem {
                    contentHeight: Theme.itemSizeSmall
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: Utils.formatTime(model.timestamp)
                            color: Theme.highlightColor
                            font.pixelSize: Theme.fontSizeMedium
                        }
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: model.note ? model.note : ""
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                            visible: text !== ""
                        }
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("No intakes today")
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                visible: todayModel.count === 0
            }

            SectionHeader {
                text: qsTr("History")
            }

            Repeater {
                model: historyModel
                delegate: ListItem {
                    contentHeight: Theme.itemSizeSmall
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: Utils.formatDateTime(model.timestamp)
                            color: Theme.primaryColor
                            font.pixelSize: Theme.fontSizeSmall
                        }
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: model.note ? model.note : ""
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                            visible: text !== ""
                        }
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("No intake history")
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                visible: historyModel.count === 0
            }
        }
    }

    ListModel { id: todayModel }
    ListModel { id: historyModel }

    onStatusChanged: {
        if (status === PageStatus.Active) refresh();
    }

    Component.onCompleted: refresh()
}
