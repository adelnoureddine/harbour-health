import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

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
        anchors.fill: parent

        header: PageHeader {
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
                    text: model.name
                    color: Theme.primaryColor
                }
                Label {
                    text: qsTr("Status: %1").arg(model.status)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
                Label {
                    text: qsTr("Since: %1").arg(model.startDate)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    visible: model.startDate !== ""
                }
            }

            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("Edit")
                        onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddAndEditIllness.qml"), {
                            profileId: root.profileId,
                            conditionId: model.id
                        })
                    }
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

