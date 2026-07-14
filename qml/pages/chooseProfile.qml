import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: root
    allowedOrientations: Orientation.All

    function refreshProfiles() {
        modelProfiles.clear();
        var profiles = DataManager.getProfiles();
        profiles.forEach(function(p) {
            modelProfiles.append(p);
        });
    }

    SilicaListView {
        anchors.fill: parent
        id: listView
        model: modelProfiles

        header: PageHeader {
            title: qsTr("Profiles")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Create New Profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("createProfile.qml"))
            }
        }

        delegate: ListItem {
            contentHeight: Theme.itemSizeMedium
            onClicked: {
                DataManager.useProfile(model.id);
                pageStack.pop();
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                Label {
                    text: model.firstName + " " + model.lastName
                    color: Theme.primaryColor
                }
                Label {
                    text: qsTr("Gender: %1 | Birthday: %2").arg(model.gender).arg(model.birthDate)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
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

    Component.onCompleted: refreshProfiles()
}

