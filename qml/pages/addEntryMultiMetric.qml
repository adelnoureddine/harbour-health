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
            value1Field.text = Utils.formatValue(log1.value);
            noteField.text = log1.note ? log1.note : "";
            var parsed = Utils.parseTimestamp(log1.timestamp);
            if (parsed !== null) {
                dialog.selectedDate = parsed;
            }
        }
        if (log2) {
            value2Field.text = Utils.formatValue(log2.value);
        }
    }

    onAccepted: {
        var systolic = parseFloat(value1Field.text.replace(',', '.'));
        var diastolic = parseFloat(value2Field.text.replace(',', '.'));
        if (editing) {
            DataManager.updateLog(logId1, systolic, selectedDate, noteField.text);
            DataManager.updateLog(logId2, diastolic, selectedDate, noteField.text);
        } else {
            // Both rows share one timestamp; that is what pairs them again on the
            // history page.
            DataManager.addLog(profileId, metricName1, systolic, selectedDate, noteField.text);
            DataManager.addLog(profileId, metricName2, diastolic, selectedDate, noteField.text);
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
                title: dialog.editing ? qsTr("Edit Blood Pressure") : qsTr("Add Blood Pressure")
                acceptText: qsTr("Save")
            }

            TextField {
                id: value1Field
                width: parent.width
                label: qsTr("Systolic (%1)").arg(dialog.metricUnit)
                placeholderText: qsTr("Systolic — e.g. 120")
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: RegExpValidator { regExp: /^\d{1,3}([.,]\d)?$/ }
                focus: true
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: value2Field.focus = true
            }

            TextField {
                id: value2Field
                width: parent.width
                label: qsTr("Diastolic (%1)").arg(dialog.metricUnit)
                placeholderText: qsTr("Diastolic — e.g. 80")
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: RegExpValidator { regExp: /^\d{1,3}([.,]\d)?$/ }
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
                value: Qt.formatTime(dialog.selectedDate, "hh:mm")
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
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: load()
}

// vim:et:ts=4:sw=4
