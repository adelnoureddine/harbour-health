import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string metricName1
    property string metricName2
    property string metricUnit: "mmHg"
    property date selectedDate: new Date()
    property var invalidateSignal

    // Set when editing an existing pair of readings.
    property int logId1: -1
    property int logId2: -1

    readonly property bool editing: logId1 >= 0 && logId2 >= 0

    canAccept: profileId >= 0 && value1Field.text !== "" && value2Field.text !== ""
               && value1Field.acceptableInput && value2Field.acceptableInput
               && !isNaN(parseFloat(value1Field.text.replace(',', '.')))
               && !isNaN(parseFloat(value2Field.text.replace(',', '.')))

    // Systolic below diastolic is a transposed entry, not a reading.
    readonly property bool valuesLookSwapped: {
        if (value1Field.text === "" || value2Field.text === "") {
            return false;
        }
        var systolic = parseFloat(value1Field.text.replace(',', '.'));
        var diastolic = parseFloat(value2Field.text.replace(',', '.'));
        return !isNaN(systolic) && !isNaN(diastolic) && systolic <= diastolic;
    }

    function load() {
        if (!editing) {
            return;
        }
        var log1 = DataManager.getLog(logId1);
        var log2 = DataManager.getLog(logId2);
        if (log1) {
            value1Field.text = Utils.formatValue(log1.value, 3);
            noteField.text = log1.note ? log1.note : "";
            var parsed = Utils.parseTimestamp(log1.timestamp);
            if (parsed !== null) {
                dialog.selectedDate = parsed;
            }
        }
        if (log2) {
            value2Field.text = Utils.formatValue(log2.value, 3);
        }
    }

    onAccepted: {
        var systolic = parseFloat(value1Field.text.replace(',', '.'));
        var diastolic = parseFloat(value2Field.text.replace(',', '.'));
        // Both halves in one transaction: one disk sync, and never half a pair saved.
        if (editing) {
            DataManager.updateLogs([{ id: logId1, value: systolic }, { id: logId2, value: diastolic }],
                                   selectedDate, noteField.text);
        } else {
            // Both rows share one timestamp; that is what pairs them again on the
            // history page.
            DataManager.addLogs(profileId, [{ metricName: metricName1, value: systolic },
                                            { metricName: metricName2, value: diastolic }],
                                selectedDate, noteField.text);
        }
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
                title: dialog.editing ? qsTr("Edit blood pressure") : qsTr("Add blood pressure")
                acceptText: qsTr("Save")
            }

            TextField {
                id: value1Field
                width: parent.width
                label: qsTr("Systolic (%1)").arg(dialog.metricUnit)
                placeholderText: qsTr("Systolic — e.g. 120")
                // Blood pressure monitors only ever show whole numbers.
                inputMethodHints: Qt.ImhDigitsOnly
                validator: RegExpValidator { regExp: /^\d{2,3}$/ }
                EnterKey.enabled: acceptableInput
                focus: true
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: value2Field.focus = true
            }

            TextField {
                id: value2Field
                width: parent.width
                label: qsTr("Diastolic (%1)").arg(dialog.metricUnit)
                placeholderText: qsTr("Diastolic — e.g. 80")
                inputMethodHints: Qt.ImhDigitsOnly
                validator: RegExpValidator { regExp: /^\d{2,3}$/ }
                EnterKey.enabled: acceptableInput
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: noteField.focus = true
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                visible: dialog.valuesLookSwapped
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.errorColor
                text: qsTr("Systolic is usually the higher of the two — check the order.")
            }

            ValueButton {
                label: qsTr("Date")
                value: Qt.formatDate(dialog.selectedDate, Qt.DefaultLocaleShortDate)
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: dialog.selectedDate
                    })
                    dateDialog.accepted.connect(function() {
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
                value: Format.formatDate(dialog.selectedDate, Formatter.TimeValue)
                onClicked: {
                    var timeDialog = pageStack.push("Sailfish.Silica.TimePickerDialog", {
                        hour: dialog.selectedDate.getHours(),
                        minute: dialog.selectedDate.getMinutes()
                    })
                    timeDialog.accepted.connect(function() {
                        // Numeric properties rather than the locale-formatted timeText.
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
                placeholderText: qsTr("Optional")
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.enabled: dialog.canAccept
                EnterKey.onClicked: dialog.accept()
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: load()
}

// vim:et:ts=4:sw=4
