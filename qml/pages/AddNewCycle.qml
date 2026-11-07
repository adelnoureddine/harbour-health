import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

/*
 * Starts a new cycle, or corrects one from the cycle history. Past cycles could only
 * be deleted before, so a wrong date could not be fixed.
 */
Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    // Set when editing, together with the stored dates ("YYYY-MM-DD"; end may be "").
    property int cycleId: -1
    property string initialStart: ""
    property string initialEnd: ""
    property string note

    readonly property bool editing: cycleId >= 0
    property date startDate: new Date()
    property date endDate: new Date()
    property bool hasEndDate: false

    canAccept: profileId >= 0 && (!hasEndDate || endDate >= startDate)

    onAccepted: {
        var startStr = Utils.toLocalDateString(startDate);
        var endStr = hasEndDate ? Utils.toLocalDateString(endDate) : null;
        if (editing) {
            DataManager.updateMenstrualCycle(cycleId, startStr, endStr, notesField.text);
        } else {
            DataManager.addMenstrualCycle(profileId, startStr, endStr, notesField.text);
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
                title: dialog.editing ? qsTr("Edit cycle") : qsTr("Record new cycle")
                // "Start" only fits a cycle that is starting; a past one is saved.
                acceptText: (dialog.editing || dialog.hasEndDate) ? qsTr("Save") : qsTr("Start")
            }

            ValueButton {
                label: qsTr("Start date")
                value: Qt.formatDate(dialog.startDate, Qt.DefaultLocaleShortDate)
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: dialog.startDate
                    })
                    dateDialog.accepted.connect(function() {
                        dialog.startDate = dateDialog.date
                    })
                }
            }

            TextSwitch {
                text: qsTr("Has end date")
                checked: dialog.hasEndDate
                automaticCheck: false
                onClicked: dialog.hasEndDate = !dialog.hasEndDate
            }

            ValueButton {
                label: qsTr("End date")
                value: Qt.formatDate(dialog.endDate, Qt.DefaultLocaleShortDate)
                visible: dialog.hasEndDate
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: dialog.endDate
                    })
                    dateDialog.accepted.connect(function() {
                        dialog.endDate = dateDialog.date
                    })
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.errorColor
                visible: dialog.hasEndDate && dialog.endDate < dialog.startDate
                text: qsTr("The end date is before the start date.")
            }

            TextField {
                id: notesField
                width: parent.width
                label: qsTr("Notes")
                text: dialog.note
                placeholderText: qsTr("Optional notes")
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.enabled: dialog.canAccept
                EnterKey.onClicked: dialog.accept()
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: {
        var start = Utils.fromLocalDateString(initialStart);
        if (start !== null) {
            startDate = start;
        }
        var end = Utils.fromLocalDateString(initialEnd);
        if (end !== null) {
            endDate = end;
            hasEndDate = true;
        }
    }
}
