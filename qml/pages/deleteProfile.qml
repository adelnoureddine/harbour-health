import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property var profile: null

    // Nothing is deleted unless the requested profile was actually found. The old
    // code fell back to profiles[0], so a stale id destroyed a different profile
    // than the one named in this dialog.
    canAccept: profile !== null

    // Where accepting leads is decided up front and left to the dialog. Pushing or
    // popping pages from onAccepted raced the dialog closing itself.
    property bool lastProfile: false
    acceptDestination: lastProfile ? Qt.resolvedUrl("createProfile.qml") : null
    acceptDestinationAction: PageStackAction.Replace

    readonly property string fullName: profile ? ((profile.firstName || "") + " " + (profile.lastName || "")).trim() : ""

    function load() {
        // getProfile() returns undefined when nothing matches, which `!== null` let through.
        profile = DataManager.getProfile(profileId) || null;
        // Deleting the last profile goes straight on to creating a new one.
        lastProfile = profile !== null && DataManager.countProfiles() === 1;
    }

    onAccepted: {
        if (profile) {
            DataManager.deleteProfile(profile.id);
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: qsTr("Delete profile")
                acceptText: qsTr("Delete")
            }

            // The profile as on the profiles list, then what deleting it means.
            Card {
                visible: dialog.profile !== null
                spacing: Theme.paddingLarge

                Item {
                    width: parent.width
                    height: Math.max(avatar.height, nameColumn.height)

                    Rectangle {
                        id: avatar
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.itemSizeSmall
                        height: width
                        radius: width / 2
                        color: Theme.rgba(Theme.highlightColor, 0.3)

                        Label {
                            anchors.centerIn: parent
                            text: dialog.profile ? Utils.initials(dialog.profile.firstName, dialog.profile.lastName) : ""
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.highlightColor
                        }
                    }

                    Column {
                        id: nameColumn
                        anchors.left: avatar.right
                        anchors.leftMargin: Theme.paddingLarge
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        Label {
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: dialog.fullName
                            font.pixelSize: Theme.fontSizeLarge
                            color: Theme.primaryColor
                        }
                        Label {
                            width: parent.width
                            visible: text !== ""
                            truncationMode: TruncationMode.Fade
                            text: dialog.profile ? Utils.profileDetailLine(dialog.profile.gender, dialog.profile.birthDate) : ""
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.paddingMedium

                    Icon {
                        id: warningIcon
                        source: "image://theme/icon-m-warning"
                        color: Theme.highlightColor
                    }

                    Label {
                        width: parent.width - warningIcon.width - parent.spacing
                        // Centred on the icon only while shorter than it.
                        y: Math.max(0, (warningIcon.height - height) / 2)
                        wrapMode: Text.Wrap
                        //: %1 is the full name of the profile being deleted
                        text: qsTr("Everything recorded for %1 will be deleted: measurements, conditions, vaccines, medications, meditation sessions and cycles. This cannot be undone.")
                              .arg(dialog.fullName)
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.highlightColor
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.paddingSmall

                    Label {
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: qsTr("To keep a copy, cancel and export a backup first.")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                    }
                    Label {
                        width: parent.width
                        visible: dialog.lastProfile
                        wrapMode: Text.Wrap
                        text: qsTr("This is the only profile, so you will be asked to create a new one.")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("This profile could not be found. Nothing will be deleted.")
                color: Theme.errorColor
                wrapMode: Text.Wrap
                visible: dialog.profile === null
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: load()
}

// vim:et:ts=4:sw=4
