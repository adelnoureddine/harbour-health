import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: 1
    property int medicationId: -1
    property int conditionId: -1
    property string medicationName
    property string dosage
    property string frequency
    property date startDate: new Date()
    property date endDate: new Date()
    property bool hasEndDate: false
    property string note

    canAccept: nameField.text !== "" && dosageField.text !== ""

    onAccepted: {
        var medId = medicationId;
        if (medId === -1) {
            medId = DataManager.addMedication(nameField.text, "pill", "mg");
        }
        
        var startStr = startDate.toISOString().split('T')[0];
        var endStr = hasEndDate ? endDate.toISOString().split('T')[0] : null;
        
        DataManager.addTreatment(profileId, medId, conditionId, dosageField.text, frequencyField.text, startStr, endStr, notesField.text);
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: medicationId === -1 ? qsTr("Add Treatment") : qsTr("Edit Treatment")
                acceptText: qsTr("Save")
            }

            TextField {
                id: nameField
                width: parent.width
                label: qsTr("Medication Name")
                text: medicationName
                placeholderText: label
                enabled: medicationId === -1
                focus: true
                EnterKey.onClicked: dosageField.focus = true
            }

            TextField {
                id: dosageField
                width: parent.width
                label: qsTr("Dosage")
                text: dosage
                placeholderText: qsTr("e.g. 500mg")
                EnterKey.onClicked: frequencyField.focus = true
            }

            TextField {
                id: frequencyField
                width: parent.width
                label: qsTr("Frequency")
                text: frequency
                placeholderText: qsTr("e.g. Twice a day")
                EnterKey.onClicked: notesField.focus = true
            }

            TextField {
                id: notesField
                width: parent.width
                label: qsTr("Notes")
                placeholderText: qsTr("Optional notes")
            }

            ValueButton {
                label: qsTr("Start Date")
                value: startDate.toLocaleDateString()
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: startDate
                    })
                    dateDialog.accepted.connect(function() {
                        startDate = dateDialog.date
                    })
                }
            }

            TextSwitch {
                id: endDateSwitch
                text: qsTr("Has end date")
                checked: hasEndDate
                onCheckedChanged: hasEndDate = checked
            }

            ValueButton {
                label: qsTr("End Date")
                value: endDate.toLocaleDateString()
                visible: hasEndDate
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: endDate
                    })
                    dateDialog.accepted.connect(function() {
                        endDate = dateDialog.date
                    })
                }
            }
        }
    }
}




