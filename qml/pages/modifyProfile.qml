import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string firstName
    property string lastName
    property string gender: "female"
    property var birthDate: null

    readonly property var genderValues: ["female", "male", "other"]

    canAccept: profileId >= 0 && firstnameField.text !== "" && lastnameField.text !== ""

    function load() {
        var profile = DataManager.getProfile(profileId);
        if (!profile) {
            return;
        }
        firstName = profile.firstName;
        lastName = profile.lastName;
        // Profiles created before genders were canonical hold a translated label;
        // indexOf then returns -1 and the combo box simply starts unselected.
        gender = profile.gender;
        birthDate = Utils.fromLocalDateString(profile.birthDate);
    }

    onAccepted: {
        var selected = genderField.currentIndex >= 0 ? genderValues[genderField.currentIndex] : gender;
        DataManager.updateProfile(profileId, firstnameField.text, lastnameField.text,
                                  selected, Utils.toLocalDateString(birthDate));
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
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: lastnameField.focus = true
            }

            TextField {
                id: lastnameField
                width: parent.width
                label: qsTr("Last Name")
                text: lastName
                placeholderText: label
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
            }

            ComboBox {
                id: genderField
                width: parent.width
                label: qsTr("Gender")
                currentIndex: dialog.genderValues.indexOf(dialog.gender)
                menu: ContextMenu {
                    MenuItem { text: qsTr("Female") }
                    MenuItem { text: qsTr("Male") }
                    MenuItem { text: qsTr("Other") }
                }
            }

            ValueButton {
                id: birthDateBtn
                label: qsTr("Birthday")
                value: birthDate ? Qt.formatDate(birthDate, Qt.DefaultLocaleShortDate)
                                 : qsTr("Not set")
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: birthDate ? birthDate : new Date()
                    })
                    dateDialog.accepted.connect(function() {
                        birthDate = dateDialog.date;
                    })
                }
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: load()
}

// vim:et:ts=4:sw=4
