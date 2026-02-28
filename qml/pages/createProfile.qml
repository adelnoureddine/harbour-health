import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property date birthDate: new Date()
    canAccept: firstnameField.text !== "" && lastnameField.text !== ""

    onAccepted: {
        var dateStr = birthDate.toISOString().split('T')[0];
        DataManager.addProfile(firstnameField.text, lastnameField.text, genderField.value, dateStr);
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
                currentIndex: 0
                menu: ContextMenu {
                    MenuItem { text: qsTr("Female") }
                    MenuItem { text: qsTr("Male") }
                    MenuItem { text: qsTr("Other") }
                }
            }

            ValueButton {
                id: birthdayField
                label: qsTr("Birthday")
                value: birthDate.toLocaleDateString()
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: birthDate
                    })
                    dateDialog.accepted.connect(function() {
                        birthDate = dateDialog.date
                    })
                }
            }
        }
    }
}


