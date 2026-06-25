import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string metricName1
    property string metricName2
    property string metricUnit: "mmHg"
    property date selectedDate: new Date()
    property var invalidateSignal

    canAccept: profileId >= 0 && value1Field.text !== "" && value2Field.text !== ""

    onAccepted: {
        var timestamp = selectedDate;
        DataManager.addLog(profileId, metricName1, parseFloat(value1Field.text.replace(',', '.')), timestamp, noteField.text);
        DataManager.addLog(profileId, metricName2, parseFloat(value2Field.text.replace(',', '.')), timestamp, noteField.text);
        if (invalidateSignal) {
            invalidateSignal(metricName1);
            invalidateSignal(metricName2);
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
                title: qsTr("Add Blood Pressure")
                acceptText: qsTr("Save")
            }

            TextField {
                id: value1Field
                width: parent.width
                label: qsTr("Systolic (mmHg)")
                placeholderText: qsTr("Systolic — e.g. 120")
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: RegExpValidator { regExp: /^\d+([\.|,]\d{1,2})?$/ }
                focus: true
                EnterKey.onClicked: value2Field.focus = true
            }

            TextField {
                id: value2Field
                width: parent.width
                label: qsTr("Diastolic (mmHg)")
                placeholderText: qsTr("Diastolic — e.g. 80")
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: RegExpValidator { regExp: /^\d+([\.|,]\d{1,2})?$/ }
                EnterKey.onClicked: noteField.focus = true
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
                placeholderText: qsTr("Optional")
            }
        }
    }
}
