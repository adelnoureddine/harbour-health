import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property int conditionId: -1
    property string conditionName
    property string status: "Active"
    property date startDate: new Date()
    property date endDate: new Date()
    property bool hasEndDate: false
    property string note

    onStatusChanged: {
        if (status === PageStatus.Active && conditionId !== -1) {
            var c = DataManager.getCondition(conditionId);
            if (c) {
                conditionName = c.name;
                status = c.status;
                startDate = new Date(c.startDate);
                if (c.endDate) {
                    endDate = new Date(c.endDate);
                    hasEndDate = true;
                }
                note = c.note;
            }
        }
    }

    canAccept: profileId >=0 && nameField.text !== ""

    onAccepted: {
        var startStr = startDate.toISOString().split('T')[0];
        var endStr = hasEndDate ? endDate.toISOString().split('T')[0] : null;
        
        if (conditionId === -1) {
            DataManager.addCondition(profileId, nameField.text, statusField.text, startStr, endStr, notesField.text);
        } else {
            DataManager.updateCondition(conditionId, nameField.text, statusField.text, startStr, endStr, notesField.text);
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
                title: conditionId === -1 ? qsTr("Add Condition") : qsTr("Edit Condition")
                acceptText: qsTr("Save")
            }

            TextField {
                id: nameField
                width: parent.width
                label: qsTr("Condition Name")
                text: conditionName
                placeholderText: label
                focus: true
                EnterKey.onClicked: statusField.focus = true
            }

            TextField {
                id: statusField
                width: parent.width
                label: qsTr("Status")
                text: status
                placeholderText: qsTr("e.g. Active, Recovered")
                EnterKey.onClicked: notesField.focus = true
            }

            TextField {
                id: notesField
                width: parent.width
                label: qsTr("Notes")
                text: note
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
