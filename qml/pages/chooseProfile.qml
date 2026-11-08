import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

/*
 * Every profile as a card: its initials, name, gender and age, with the one in use
 * marked. Tapping a card switches to that profile and goes back to the dashboard.
 */
Page {
    id: root
    allowedOrientations: Orientation.All

    property int activeProfileId: -1
    // What the list last loaded (see DataManager.dataKey). Coming back from a cancelled
    // dialog keeps the list as it was.
    property string loadedFrom: ""

    function refreshProfiles() {
        var key = DataManager.dataKey();
        activeProfileId = DataManager.lastUsedProfileId();
        modelProfiles.clear();
        var profiles = DataManager.getProfiles();
        for (var i = 0; i < profiles.length; i++) {
            // Only what the rows show: a NULL column of an older profile has no role type.
            modelProfiles.append({
                id: profiles[i].id,
                firstName: profiles[i].firstName || "",
                lastName: profiles[i].lastName || "",
                gender: profiles[i].gender || "",
                birthDate: profiles[i].birthDate || ""
            });
        }
        loadedFrom = key;
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: modelProfiles
        spacing: Theme.paddingMedium

        header: PageHeader {
            width: listView.width
            title: qsTr("Profiles")
            description: modelProfiles.count > 1 ? qsTr("Tap a profile to switch to it") : ""
        }

        footer: Item {
            width: listView.width
            height: Theme.paddingLarge
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Create new profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("createProfile.qml"))
            }
        }

        delegate: ListItem {
            id: profileItem
            width: listView.width
            contentHeight: Math.max(Theme.itemSizeLarge, textColumn.height + 2 * Theme.paddingMedium)
            highlightedColor: "transparent"

            readonly property bool isActive: model.id === root.activeProfileId

            onClicked: {
                DataManager.useProfile(model.id);
                pageStack.pop();
            }

            CardBackground {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: parent.height
                highlighted: profileItem.highlighted
            }

            // The same initials circle as the dashboard header.
            Rectangle {
                id: avatar
                x: Theme.horizontalPageMargin + Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.itemSizeSmall
                height: width
                radius: width / 2
                color: Theme.rgba(Theme.highlightColor, 0.3)

                Label {
                    anchors.centerIn: parent
                    text: Utils.initials(model.firstName, model.lastName)
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.highlightColor
                }
            }

            Column {
                id: textColumn
                anchors.left: avatar.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x - Theme.horizontalPageMargin - Theme.paddingLarge
                       - (activePill.visible ? activePill.width + Theme.paddingMedium : 0)

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: (model.firstName + " " + model.lastName).trim()
                    color: profileItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    visible: text !== ""
                    truncationMode: TruncationMode.Fade
                    text: Utils.profileDetailLine(model.gender, model.birthDate)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: profileItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }

            StatusPill {
                id: activePill
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin + Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                //: Marks the profile currently in use on the profiles list
                text: profileItem.isActive ? qsTr("In use") : ""
            }

            // Built when first opened. Created with every row, the menu made each
            // row about ten times slower to build, which showed while scrolling.
            menu: Component {
                ContextMenu {
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
        if (status === PageStatus.Active && DataManager.dataKey() !== loadedFrom) {
            refreshProfiles();
        }
    }
}

// vim:et:ts=4:sw=4
