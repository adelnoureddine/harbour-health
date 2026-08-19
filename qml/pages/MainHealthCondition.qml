import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Page {
    id: root
    allowedOrientations: Orientation.All

    property int profileId: -1

    function refresh() {
        listModel.clear();
        if (profileId >= 0) {
            var conditions = DataManager.getConditions(profileId);
            conditions.forEach(function(c) {
                listModel.append(c);
            });
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent

        header: PageHeader {
            width: listView.width
            title: qsTr("Health Conditions")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add Condition")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddAndEditIllness.qml"), {profileId: root.profileId})
            }
            MenuItem {
                    text: qsTr("All Medications")
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("AllMedications.qml"), {profileId: root.profileId})
            }
        }

        model: listModel

        delegate: ListItem {
            id: conditionItem
            contentHeight: Theme.itemSizeMedium
            onClicked: {
                pageStack.animatorPush(Qt.resolvedUrl("ConsultIllness.qml"), {
                    profileId: root.profileId,
                    conditionId: model.id,
                    conditionName: model.name
                })
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: model.name
                    color: conditionItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: qsTr("Status: %1").arg(model.status)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: qsTr("Since: %1").arg(Utils.formatDate(model.startDate))
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    visible: model.startDate !== "" && model.startDate !== null
                }
            }

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Edit")
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddAndEditIllness.qml"), {
                        profileId: root.profileId,
                        conditionId: model.id
                    })
                }
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: conditionItem.remorseDelete(function() {
                        // Removes the condition together with its treatments.
                        DataManager.deleteCondition(model.id);
                        listModel.remove(index);
                    })
                }
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No health conditions recorded")
            hintText: qsTr("Pull down to add a condition")
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

