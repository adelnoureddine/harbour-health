import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Page {
    id: root
    allowedOrientations: Orientation.All

    property int activeProfileId: -1

    function refreshProfiles() {
        activeProfileId = DataManager.lastUsedProfileId();
        modelProfiles.clear();
        var profiles = DataManager.getProfiles();
        profiles.forEach(function(profile) {
            modelProfiles.append(profile);
        });
    }

    SilicaListView {
        anchors.fill: parent
        id: listView
        model: modelProfiles

        header: PageHeader {
            width: listView.width
            title: qsTr("Profiles")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Create New Profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("createProfile.qml"))
            }
        }

        delegate: ListItem {
            id: profileItem
            contentHeight: Theme.itemSizeMedium

            readonly property bool isActive: model.id === root.activeProfileId

            onClicked: {
                DataManager.useProfile(model.id);
                pageStack.pop();
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin - activeIcon.width
                Label {
                    width: parent.width
                    text: model.firstName + " " + model.lastName
                    truncationMode: TruncationMode.Fade
                    color: profileItem.isActive || profileItem.highlighted ? Theme.highlightColor
                                                                          : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: qsTr("%1 · born %2").arg(Utils.genderDisplayName(model.gender))
                                              .arg(Utils.formatDate(model.birthDate))
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
            }

            Icon {
                id: activeIcon
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                source: "image://theme/icon-s-installed"
                visible: profileItem.isActive
            }

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Edit")
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("modifyProfile.qml"), {
                        profileId: model.id
                    })
                }
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("deleteProfile.qml"), {
                        profileId: model.id
                    })
                }
            }
        }

        ViewPlaceholder {
            enabled: modelProfiles.count === 0
            text: qsTr("No profiles found")
            hintText: qsTr("Pull down to create one")
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: modelProfiles
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            refreshProfiles();
        }
    }
}

// vim:et:ts=4:sw=4
