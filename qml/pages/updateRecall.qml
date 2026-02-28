import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property int vaccineId: -1
    property date selectedDate: new Date()
    property string note

    canAccept: vaccineId !== -1

    onAccepted: {
        var dateStr = selectedDate.toISOString().split('T')[0];
        DataManager.addVaccineLog(profileId, vaccineId, dateStr, note);
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: qsTr("Record Injection")
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
                        selectedDate = dateDialog.date
                    })
                }
            }

            TextField {
                width: parent.width
                label: qsTr("Notes")
                placeholderText: qsTr("Optional notes")
                text: note
                onTextChanged: note = text
            }
        }
    }
}
