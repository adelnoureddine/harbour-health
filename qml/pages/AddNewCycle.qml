import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property date startDate: new Date()
    property string note

    canAccept: true

    onAccepted: {
        var profiles = DataManager.getProfiles();
        if (profiles.length > 0) {
            var profileId = profiles[0].id;
            var startStr = startDate.toISOString().split('T')[0];
            DataManager.addMenstrualCycle(profileId, startStr, null, notesField.text);
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
                title: qsTr("Record New Cycle")
                acceptText: qsTr("Start")
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
