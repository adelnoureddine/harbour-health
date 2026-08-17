import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: 1
    property var profile: null

    function refresh() {
        var profiles = DataManager.getProfiles();
        if (profiles.length > 0) {
            // Find profile by ID or fallback to first one
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

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Edit Profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("modifyProfile.qml"), {profileId: profile.id})
            }
            MenuItem {
                text: qsTr("Delete Profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("deleteProfile.qml"), {profileId: profile.id})
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            Item { width: parent.width; height: childrenRect.height
                PageHeader { anchors.right: parent.right; anchors.rightMargin: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin; title: qsTr("Profile") }
            }

            Item { width: parent.width; height: childrenRect.height
                SectionHeader { anchors.right: parent.right; anchors.rightMargin: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin; text: qsTr("Personal Information") }
            }

            DetailItem {
                label: qsTr("First Name")
                value: profile ? profile.firstName : ""
            }

            DetailItem {
                label: qsTr("Last Name")
                value: profile ? profile.lastName : ""
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

        VerticalScrollDecorator {}
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            refresh();
        }
    }

    Component.onCompleted: refresh()
}
