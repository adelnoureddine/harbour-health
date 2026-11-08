import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/utils.js" as Utils

/*
 * When a reading was taken: date and time side by side, each a label over its value,
 * opening the system pickers. As two stacked "Date 19/08/2026" rows, the date was a
 * bare short number and the pair read as one line of settings rather than when the
 * reading was taken. Used by both entry dialogs.
 *
 * It only shows selectedDate; a pick is reported through picked(), so the dialog's
 * binding to it is never broken.
 */
Row {
    id: row

    property date selectedDate: new Date()

    signal picked(date when)

    readonly property real cellHeight: Math.max(Theme.itemSizeMedium,
                                                dateColumn.height + 2 * Theme.paddingMedium,
                                                timeColumn.height + 2 * Theme.paddingMedium)

    function pickDate() {
        var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
            date: row.selectedDate
        });
        dateDialog.accepted.connect(function () {
            // A new day keeps the time of day already chosen.
            row.picked(new Date(dateDialog.date.getFullYear(), dateDialog.date.getMonth(),
                                dateDialog.date.getDate(), row.selectedDate.getHours(),
                                row.selectedDate.getMinutes(), 0));
        });
    }

    function pickTime() {
        var timeDialog = pageStack.push("Sailfish.Silica.TimePickerDialog", {
            hour: row.selectedDate.getHours(),
            minute: row.selectedDate.getMinutes()
        });
        timeDialog.accepted.connect(function () {
            // timeText is locale formatted -- in a 12-hour locale, parsing it recorded
            // 1 pm as 01:00. The numeric properties are exact.
            row.picked(new Date(row.selectedDate.getFullYear(), row.selectedDate.getMonth(),
                                row.selectedDate.getDate(), timeDialog.hour, timeDialog.minute, 0));
        });
    }

    BackgroundItem {
        id: dateButton
        width: Math.round(parent.width / 2)
        height: row.cellHeight
        onClicked: row.pickDate()

        Column {
            id: dateColumn
            x: Theme.horizontalPageMargin
            width: parent.width - x - Theme.paddingMedium
            anchors.verticalCenter: parent.verticalCenter

            Label {
                width: parent.width
                truncationMode: TruncationMode.Fade
                text: qsTr("Date")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
            }
            Label {
                width: parent.width
                wrapMode: Text.Wrap
                // "Today", "Yesterday", else the weekday and date.
                text: Utils.dayTitle(Utils.toLocalDateString(row.selectedDate))
                color: dateButton.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
        }
    }

    BackgroundItem {
        id: timeButton
        width: parent.width - dateButton.width
        height: row.cellHeight
        onClicked: row.pickTime()

        Column {
            id: timeColumn
            x: Theme.paddingMedium
            width: parent.width - x - Theme.horizontalPageMargin
            anchors.verticalCenter: parent.verticalCenter

            Label {
                width: parent.width
                truncationMode: TruncationMode.Fade
                text: qsTr("Time")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
            }
            Label {
                width: parent.width
                truncationMode: TruncationMode.Fade
                // Follows the system 12/24-hour setting.
                text: Utils.formatTime(row.selectedDate)
                color: timeButton.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
        }
    }
}

// vim:et:ts=4:sw=4
