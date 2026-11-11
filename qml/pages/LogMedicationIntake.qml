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
    // What was already taken today, so a dose is not logged twice by mistake.
    property string todayText: ""

    // An intake is something that happened. The clock is looked at again every few
    // seconds while the time is ahead: a binding on new Date() is evaluated once, so a
    // time picked a minute too far stayed refused until it was picked again.
    property double now: Date.now()
    readonly property bool inFuture: selectedDate.getTime() > now + 60000
    onSelectedDateChanged: now = Date.now()

    Timer {
        interval: 10000
        repeat: true
        running: dialog.inFuture
        onTriggered: dialog.now = Date.now()
    }

    canAccept: profileId >= 0 && medicationId >= 0 && !inFuture

    onAccepted: {
        DataManager.addMedicationLog(profileId, medicationId, selectedDate, noteField.text.trim());
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                // The medication is named below: in the title it was cut off.
                title: qsTr("Log intake")
                acceptText: qsTr("Save")
            }

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: dialog.medicationName
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.highlightColor
                }
                Label {
                    width: parent.width
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    text: dialog.todayText
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryHighlightColor
                }
            }

            ValueButton {
                label: qsTr("Date")
                value: Utils.formatDate(dialog.selectedDate)
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
                // Follows the system 12/24-hour setting.
                value: Utils.formatTime(dialog.selectedDate)
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

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.errorColor
                visible: dialog.inFuture
                text: qsTr("The intake time is in the future.")
            }

            TextField {
                id: noteField
                width: parent.width
                label: qsTr("Note")
                placeholderText: qsTr("e.g. after meal, morning dose...")
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.enabled: dialog.canAccept
                EnterKey.onClicked: dialog.accept()
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: {
        if (profileId < 0 || medicationId < 0) {
            return;
        }
        // Newest first, so the first one is the latest intake.
        var today = DataManager.getMedicationLogsToday(profileId, medicationId);
        todayText = Utils.medicationTodayText(today.length, today.length > 0 ? today[0].timestamp : "");
    }
}

// vim:et:ts=4:sw=4
