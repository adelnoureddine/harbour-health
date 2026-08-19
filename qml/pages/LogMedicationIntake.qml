import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

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
                value: Qt.formatDate(dialog.selectedDate, Qt.DefaultLocaleShortDate)
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: dialog.selectedDate
                    })
                    dateDialog.accepted.connect(function() {
                        // This used to rebuild the date by concatenating two UTC
                        // strings and re-parsing them, which shifted the result twice.
                        dialog.selectedDate = new Date(dateDialog.date.getFullYear(),
                                                       dateDialog.date.getMonth(),
                                                       dateDialog.date.getDate(),
                                                       dialog.selectedDate.getHours(),
                                                       dialog.selectedDate.getMinutes(), 0);
                    })
                }
            }

            ValueButton {
                label: qsTr("Time")
                value: Qt.formatTime(dialog.selectedDate, "hh:mm")
                onClicked: {
                    var timeDialog = pageStack.push("Sailfish.Silica.TimePickerDialog", {
                        hour: dialog.selectedDate.getHours(),
                        minute: dialog.selectedDate.getMinutes()
                    })
                    timeDialog.accepted.connect(function() {
                        // timeText is locale formatted: in a 12-hour locale the old
                        // code built "2026-08-19 1:05 pm:00", i.e. an invalid date.
                        dialog.selectedDate = new Date(dialog.selectedDate.getFullYear(),
                                                       dialog.selectedDate.getMonth(),
                                                       dialog.selectedDate.getDate(),
                                                       timeDialog.hour, timeDialog.minute, 0);
                    })
                }
            }

            TextField {
                id: noteField
                width: parent.width
                label: qsTr("Note")
                placeholderText: qsTr("e.g. after meal, morning dose...")
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
            }
        }

        VerticalScrollDecorator {}
    }
}

// vim:et:ts=4:sw=4
