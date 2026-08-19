import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property int conditionId
    property string conditionName
    property var conditionData: ({})

    function refresh() {
        conditionData = DataManager.getCondition(conditionId) || {};
        listModel.clear();
        if (profileId >= 0) {
            var treatments = DataManager.getTreatments(profileId, -1, conditionId);
            treatments.forEach(function(t) {
                listModel.append(t);
            });
        }
    }

    SilicaListView {
        anchors.fill: parent

        header: Column {
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: conditionName
            }

            DetailItem {
                label: qsTr("Status")
                value: conditionData.status || ""
            }

            DetailItem {
                label: qsTr("Start Date")
                value: conditionData.startDate ? Utils.formatDate(conditionData.startDate) : ""
            }

            DetailItem {
                label: qsTr("End Date")
                value: conditionData.endDate ? Utils.formatDate(conditionData.endDate)
                                             : qsTr("Ongoing")
            }

            DetailItem {
                label: qsTr("Notes")
                value: conditionData.note || ""
                visible: value !== ""
            }

            SectionHeader {
                text: qsTr("Treatments")
            }
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add Treatment")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddAndEditMedication.qml"), {
                    profileId: profileId,
                    conditionId: conditionId
                })
            }
            MenuItem {
                text: qsTr("Edit Condition")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddAndEditIllness.qml"), {
                    profileId: profileId,
                    conditionId: conditionId
                })
            }
        }

        model: listModel

        delegate: ListItem {
            id: treatmentItem
            contentHeight: Theme.itemSizeMedium
            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: model.medicationName
                    color: treatmentItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: model.frequency ? qsTr("%1 · %2").arg(model.dosage).arg(model.frequency)
                                          : model.dosage
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
            }
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("ConsultMedication.qml"), {
                profileId: profileId,
                medicationId: model.medicationId,
                medicationName: model.medicationName
            })
            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Edit")
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddAndEditMedication.qml"), {
                        profileId: profileId,
                        conditionId: conditionId,
                        treatmentId: model.id
                    })
                }
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: treatmentItem.remorseDelete(function() {
                        DataManager.deleteTreatment(model.id);
                        listModel.remove(index);
                    })
                }
            }

        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No treatments for this condition")
            hintText: qsTr("Pull down to add a treatment")
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: listModel
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            refresh();
        }
    }

    Component.onCompleted: refresh()
}

