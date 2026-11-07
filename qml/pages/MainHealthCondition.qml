import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Page {
    id: root
    allowedOrientations: Orientation.All

    property int profileId: -1

    // What the page last loaded (see DataManager.dataKey). It loads when created, so
    // the content is there as the page slides in, and used to load all over again
    // as soon as it became active.
    property string loadedFrom: ""

    function refresh() {
        loadedFrom = DataManager.dataKey();
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
            title: qsTr("Health conditions")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add condition")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddAndEditIllness.qml"), {profileId: root.profileId})
            }
            MenuItem {
                    text: qsTr("All medications")
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
                    text: qsTr("Status: %1").arg(Utils.conditionStatusDisplayName(model.status))
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

            // Built when first opened. Created with every row, the menu made each
            // row about ten times slower to build, which showed while scrolling.
            menu: Component {
                ContextMenu {
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
        if (status === PageStatus.Active && DataManager.dataKey() !== loadedFrom) {
            refresh();
        }
    }

    Component.onCompleted: refresh()
}

