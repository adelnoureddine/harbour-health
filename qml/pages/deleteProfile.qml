import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property var profile: null

    // Nothing is deleted unless the requested profile was actually found. The old
    // code fell back to profiles[0], so a stale id destroyed a different profile
    // than the one named in this dialog.
    canAccept: profile !== null

    function load() {
        profile = DataManager.getProfile(profileId);
    }

    onAccepted: {
        if (!profile) {
            return;
        }
        DataManager.deleteProfile(profile.id);
        if (DataManager.countProfiles() === 0) {
            pageStack.replace(Qt.resolvedUrl("createProfile.qml"));
        } else {
            pageStack.pop();
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: qsTr("Delete Profile")
                acceptText: qsTr("Delete")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("Are you sure you want to delete this profile? This action cannot be undone and all associated data will be lost.")
                color: Theme.highlightColor
                wrapMode: Text.Wrap
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: qsTr("This profile could not be found. Nothing will be deleted.")
                color: Theme.errorColor
                wrapMode: Text.Wrap
                visible: profile === null
            }

            SectionHeader {
                text: qsTr("Profile to Delete")
                visible: profile !== null
            }

            DetailItem {
                label: qsTr("Name")
                value: profile ? (profile.firstName + " " + profile.lastName) : ""
                visible: profile !== null
            }

            DetailItem {
                label: qsTr("Gender")
                value: profile ? Utils.genderDisplayName(profile.gender) : ""
                visible: profile !== null
            }

            DetailItem {
                label: qsTr("Birthday")
                value: profile ? Utils.formatDate(profile.birthDate) : ""
                visible: profile !== null
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: load()
}

// vim:et:ts=4:sw=4
