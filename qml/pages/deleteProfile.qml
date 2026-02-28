import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: 1
    property var profile: null

    function load() {
        var profiles = DataManager.getProfiles();
        if (profiles.length > 0) {
            var found = false;
            for (var i=0; i<profiles.length; i++) {
                if (profiles[i].id === profileId) {
                    profile = profiles[i];
                    found = true;
                    break;
                }
            }
            if (!found) profile = profiles[0];
        }
    }

    onAccepted: {
        if (profile) {
            DataManager.deleteProfile(profile.id);
            var remaining = DataManager.getProfiles();
            if (remaining.length === 0) {
                pageStack.replace(Qt.resolvedUrl("createProfile.qml"));
            } else {
                pageStack.pop();
            }
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

            SectionHeader {
                text: qsTr("Profile to Delete")
            }

            DetailItem {
                label: qsTr("Name")
                value: profile ? (profile.firstName + " " + profile.lastName) : ""
            }
            
            DetailItem {
                label: qsTr("Gender")
                value: profile ? profile.gender : ""
            }

            DetailItem {
                label: qsTr("Birthday")
                value: profile ? profile.birthDate : ""
            }
        }
    }

    Component.onCompleted: load()
}

