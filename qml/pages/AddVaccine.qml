import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property date injectionDate: new Date()
    canAccept: vaccineName.text !== ""

    onAccepted: {
        var profiles = DataManager.getProfiles();
        if (profiles.length > 0) {
            var profileId = profiles[0].id;
        // First add the vaccine record (if it doesn't exist)
        var vaccineId = DataManager.getOrCreateVaccine(vaccineName.text, false);
            var dateStr = injectionDate.toISOString().split('T')[0];
            DataManager.addVaccineLog(profileId, vaccineId, dateStr, notesField.text);
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
                title: qsTr("Add Vaccine Record")
                acceptText: qsTr("Save")
            }

            TextField {
                id: vaccineName
                width: parent.width
                label: qsTr("Vaccine Name")
                placeholderText: label
                focus: true
                EnterKey.onClicked: notesField.focus = true
            }

            TextField {
                id: notesField
                width: parent.width
                label: qsTr("Notes")
                placeholderText: qsTr("Optional notes")
                EnterKey.onClicked: dateButton.focus = true
            }

            ValueButton {
                id: dateButton
                label: qsTr("Injection Date")
                value: injectionDate.toLocaleDateString()
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: injectionDate
                    })
                    dateDialog.accepted.connect(function() {
                        injectionDate = dateDialog.date
                    })
                }
            }
        }
    }
}
