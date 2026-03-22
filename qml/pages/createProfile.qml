import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property var birthDate
    canAccept: firstnameField.text !== "" && lastnameField.text !== "" && genderField.text !== "" && birthDate

    onAccepted: {
        var dateStr = birthDate.toISOString().split('T')[0];
        var profile_id = DataManager.addProfile(firstnameField.text, lastnameField.text, genderField.value, dateStr);
	DataManager.useProfile(profile_id);
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: qsTr("Create Profile")
                acceptText: qsTr("Save")
            }

            TextField {
                id: firstnameField
                width: parent.width
                label: qsTr("First Name")
                placeholderText: label
                EnterKey.onClicked: lastnameField.focus = true
            }

            TextField {
                id: lastnameField
                width: parent.width
                label: qsTr("Last Name")
                placeholderText: label
            }

            ComboBox {
                id: genderField
                label: qsTr("Gender")
                currentIndex: -1
                menu: ContextMenu {
                    MenuItem { text: qsTr("Female") }
                    MenuItem { text: qsTr("Male") }
                    MenuItem { text: qsTr("Other") }
                }
            }

            ValueButton {
                id: birthDateField
                label: qsTr("Birthday")
                value: birthDate ? birthDate.toLocaleDateString() : ''
                onClicked: {
                    var start = {}
		    if (birthDate) {
			    start['date'] = birthDate;
		    }
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", start)
                    dateDialog.accepted.connect(function() {
                        birthDate = dateDialog.date
                    })
                }
            }
        }
    }
}


