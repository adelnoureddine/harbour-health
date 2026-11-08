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

    // Start days of the profile's other cycles, and the latest of them for context.
    property var otherStarts: []
    property string previousStart: ""

    readonly property string startDay: Utils.toLocalDateString(startDate)
    // Compared as days: both defaults are "now", a few milliseconds apart, so comparing
    // the dates themselves could flag today as before today.
    readonly property bool endBeforeStart: hasEndDate && Utils.toLocalDateString(endDate) < startDay
    // Two cycles on one day make a zero-day cycle, which the lengths and the average skip.
    readonly property bool startTaken: otherStarts.indexOf(startDay) >= 0

    canAccept: profileId >= 0 && !endBeforeStart && !startTaken

    onAccepted: {
        var startStr = Utils.toLocalDateString(startDate);
        var endStr = hasEndDate ? Utils.toLocalDateString(endDate) : null;
        var noteText = notesField.text.trim();
        if (editing) {
            DataManager.updateMenstrualCycle(cycleId, startStr, endStr, noteText);
        } else {
            DataManager.addMenstrualCycle(profileId, startStr, endStr, noteText);
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

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
                //: Context under a new cycle's start date; %1 is a date
                description: !dialog.editing && dialog.previousStart !== ""
                             ? qsTr("Last cycle started on %1").arg(Utils.formatDate(dialog.previousStart))
                             : ""
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: dialog.startDate
                    })
                    dateDialog.accepted.connect(function() {
                        dialog.startDate = dateDialog.date
                    })
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.errorColor
                visible: dialog.startTaken
                text: qsTr("Another cycle already starts on this day.")
            }

            TextSwitch {
                text: qsTr("Has end date")
                description: qsTr("Leave off while the cycle is still going on.")
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
                visible: dialog.endBeforeStart
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
        if (profileId >= 0) {
            var cycles = DataManager.getMenstrualCycles(profileId);
            var starts = [];
            for (var i = 0; i < cycles.length; i++) {
                if (cycles[i].id !== cycleId) {
                    starts.push(String(cycles[i].startDate));
                }
            }
            otherStarts = starts;
            // Newest first.
            previousStart = starts.length > 0 ? starts[0] : "";
        }
    }
}
