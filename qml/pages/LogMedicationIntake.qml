import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property int medicationId: -1
    property string medicationName
    property date selectedDate: new Date()

    canAccept: profileId >= 0 && medicationId >= 0

    onAccepted: {
        DataManager.addMedicationLog(profileId, medicationId, selectedDate, noteField.text);
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: qsTr("Log intake — %1").arg(medicationName)
                acceptText: qsTr("Save")
            }

            ValueButton {
                label: qsTr("Date")
                value: selectedDate.toLocaleDateString()
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: selectedDate
                    })
                    dateDialog.accepted.connect(function() {
                        var dateStr = dateDialog.date.toISOString().split('T')[0];
                        var timeStr = selectedDate.toISOString().split('T')[1];
                        selectedDate = new Date(dateStr + ' ' + timeStr);
                    })
                }
            }

            ValueButton {
                label: qsTr("Time")
                value: selectedDate.toLocaleTimeString()
                onClicked: {
                    var timeDialog = pageStack.push("Sailfish.Silica.TimePickerDialog", {
                        hour: selectedDate.getHours(),
                        minute: selectedDate.getMinutes()
                    })
                    timeDialog.accepted.connect(function() {
                        var dateStr = selectedDate.toISOString().split('T')[0];
                        var timeStr = timeDialog.timeText + ":00";
                        selectedDate = new Date(dateStr + ' ' + timeStr);
                    })
                }
            }

            TextField {
                id: noteField
                width: parent.width
                label: qsTr("Note")
                placeholderText: qsTr("e.g. after meal, morning dose...")
            }
        }
    }
}
