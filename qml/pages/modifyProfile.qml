import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: 1
    property string firstName
    property string lastName
    property string gender: "Female"
    property string birthDate

    canAccept: firstnameField.text !== "" && lastnameField.text !== ""

    function load() {
        var profiles = DataManager.getProfiles();
        var profile = null;
        for (var i=0; i<profiles.length; i++) {
            if (profiles[i].id === profileId) {
                profile = profiles[i];
                break;
            }
        }
        
        if (profile) {
            firstName = profile.firstName;
            lastName = profile.lastName;
            gender = profile.gender;
            birthDate = profile.birthDate;
        }
    }

    onAccepted: {
        DataManager.updateProfile(profileId, firstnameField.text, lastnameField.text, genderField.value, birthDateBtn.value);
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: qsTr("Edit Profile")
                acceptText: qsTr("Save")
            }

            TextField {
                id: firstnameField
                width: parent.width
                label: qsTr("First Name")
                text: firstName
                placeholderText: label
            }

            TextField {
                id: lastnameField
                width: parent.width
                label: qsTr("Last Name")
                text: lastName
                placeholderText: label
            }

            ComboBox {
                id: genderField
                width: parent.width
                label: qsTr("Gender")
                currentIndex: gender === "Male" ? 1 : (gender === "Other" ? 2 : 0)
                menu: ContextMenu {
                    MenuItem { text: qsTr("Female") }
                    MenuItem { text: qsTr("Male") }
                    MenuItem { text: qsTr("Other") }
                }
            }

            ValueButton {
                id: birthDateBtn
                label: qsTr("Birthday")
                value: birthDate
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: birthDate ? new Date(birthDate) : new Date()
                    })
                    dateDialog.accepted.connect(function() {
                        birthDate = dateDialog.date.toISOString().split('T')[0]
                    })
                }
            }
        }
    }

    Component.onCompleted: load()
}


