import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

/*
 * Starts a new cycle, or corrects one from the cycle history. Past cycles could only
 * be deleted before, so a wrong date could not be fixed.
 *
 * A cycle starts with a period and runs until the next cycle starts; its end date is
 * the last day of that period.
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
    // The other cycles as [{start, end}] ("YYYY-MM-DD", end "" when not recorded).
    property var others: []

    readonly property string startDay: Utils.toLocalDateString(startDate)
    readonly property string endDay: hasEndDate ? Utils.toLocalDateString(endDate) : ""
    readonly property string today: Utils.toLocalDateString(new Date())
    // Compared as days: both defaults are "now", a few milliseconds apart, so comparing
    // the dates themselves could flag today as before today.
    readonly property bool endBeforeStart: hasEndDate && endDay < startDay
    // Two cycles on one day make a zero-day cycle, which the lengths and the average skip.
    readonly property bool startTaken: otherStarts.indexOf(startDay) >= 0
    // A start next week gave "Day -3" on the cycle page.
    readonly property bool inFuture: startDay > today || (hasEndDate && endDay > today)
    // The period would run into another cycle: it starts before an earlier period has
    // ended, or ends on or after the day the next cycle starts.
    readonly property bool overlaps: {
        for (var i = 0; i < others.length; i++) {
            var other = others[i];
            if (other.start < startDay && other.end !== "" && other.end >= startDay) {
                return true;
            }
            if (other.start > startDay && endDay !== "" && endDay >= other.start) {
                return true;
            }
        }
        return false;
    }

    canAccept: profileId >= 0 && !endBeforeStart && !startTaken && !inFuture && !overlaps

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
                //: Switch in the cycle dialog: the period of this cycle is over
                text: qsTr("The period has ended")
                description: qsTr("Leave off while the period is still going on. The cycle itself runs until the next one starts.")
                checked: dialog.hasEndDate
                automaticCheck: false
                onClicked: dialog.hasEndDate = !dialog.hasEndDate
            }

            ValueButton {
                //: Label of the date the period of a cycle ended
                label: qsTr("Last day of the period")
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

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.errorColor
                visible: dialog.inFuture
                text: qsTr("A cycle is recorded once it has started: this date is in the future.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.errorColor
                visible: dialog.overlaps && !dialog.endBeforeStart && !dialog.startTaken
                text: qsTr("These dates run into the period of another cycle.")
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
            var rest = [];
            for (var i = 0; i < cycles.length; i++) {
                if (cycles[i].id !== cycleId) {
                    starts.push(String(cycles[i].startDate));
                    rest.push({ start: String(cycles[i].startDate),
                                end: cycles[i].endDate ? String(cycles[i].endDate) : "" });
                }
            }
            otherStarts = starts;
            others = rest;
            // Newest first.
            previousStart = starts.length > 0 ? starts[0] : "";
        }
    }
}
