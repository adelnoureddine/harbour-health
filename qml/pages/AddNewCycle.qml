import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property date startDate: new Date()
    property string note

    canAccept: profileId >= 0

    onAccepted: {
            var startStr = Utils.toLocalDateString(startDate);
            DataManager.addMenstrualCycle(profileId, startStr, null, notesField.text);
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: qsTr("Record New Cycle")
                acceptText: qsTr("Start")
            }

            ValueButton {
                label: qsTr("Start Date")
                value: Qt.formatDate(startDate, Qt.DefaultLocaleShortDate)
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: startDate
                    })
                    dateDialog.accepted.connect(function() {
                        startDate = dateDialog.date
                    })
                }
            }

            TextField {
                id: notesField
                width: parent.width
                label: qsTr("Notes")
                text: note
                placeholderText: qsTr("Optional notes")
            }
        }
    }
}
