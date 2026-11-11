import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string metricName1
    property string metricName2
    property string metricUnit: "mmHg"
    property date selectedDate: new Date()

    // Set when editing an existing pair of readings.
    property int logId1: -1
    property int logId2: -1

    readonly property bool editing: logId1 >= 0 && logId2 >= 0

    // The previous pair under the fields; empty when editing, or with none yet.
    property string contextText: ""

    canAccept: profileId >= 0 && value1Field.text !== "" && value2Field.text !== ""
               && value1Field.acceptableInput && value2Field.acceptableInput
               && !isNaN(parseFloat(value1Field.text.replace(',', '.')))
               && !isNaN(parseFloat(value2Field.text.replace(',', '.')))
               && (untouched || (rangeError(value1Field.text, limits1) === ""
                                 && rangeError(value2Field.text, limits2) === ""))
               && !whenRow.inFuture

    // What each half can plausibly be (DataManager.METRIC_LIMITS): 12 for 120 passed.
    readonly property var limits1: DataManager.metricLimits(metricName1)
    readonly property var limits2: DataManager.metricLimits(metricName2)
    // A pair saved before there were limits can still have its time or note edited.
    property string originalText: ""
    readonly property bool untouched: editing && originalText !== ""
                                      && value1Field.text + "/" + value2Field.text === originalText

    // "" when the text is a value within the limits (or not a value yet).
    function rangeError(text, limits) {
        if (text === "" || limits === null) {
            return "";
        }
        var v = parseFloat(text.replace(',', '.'));
        if (isNaN(v) || (v >= limits.min && v <= limits.max)) {
            return "";
        }
        return Utils.rangeText(limits.min, limits.max, metricUnit, 0);
    }

    // Systolic below diastolic is a transposed entry, not a reading.
    readonly property bool valuesLookSwapped: {
        if (value1Field.text === "" || value2Field.text === "") {
            return false;
        }
        var systolic = parseFloat(value1Field.text.replace(',', '.'));
        var diastolic = parseFloat(value2Field.text.replace(',', '.'));
        return !isNaN(systolic) && !isNaN(diastolic) && systolic <= diastolic;
    }

    // "Last: 128/82 mmHg, 19/08/2026", to type the new pair against.
    function lastReadingText() {
        if (profileId < 0 || editing) {
            return "";
        }
        var bp = DataManager.getLatestBloodPressure(profileId);
        return bp !== null ? Utils.lastReadingText(Utils.formatBloodPressure(bp, metricUnit), bp.timestamp) : "";
    }

    function load() {
        contextText = lastReadingText();
        if (!editing) {
            return;
        }
        var log1 = DataManager.getLog(logId1);
        var log2 = DataManager.getLog(logId2);
        if (log1) {
            value1Field.text = Utils.formatInput(log1.value);
            noteField.text = log1.note ? log1.note : "";
            var parsed = Utils.parseTimestamp(log1.timestamp);
            if (parsed !== null) {
                dialog.selectedDate = parsed;
            }
        }
        if (log2) {
            value2Field.text = Utils.formatInput(log2.value);
        }
        originalText = value1Field.text + "/" + value2Field.text;
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
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: dialog.editing ? qsTr("Edit blood pressure") : qsTr("Add blood pressure")
                acceptText: qsTr("Save")
            }

            // The pair with what helps to type it: the last reading, the order check.
            Column {
                width: parent.width
                spacing: Theme.paddingSmall

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
                    text: dialog.contextText
                    visible: text !== ""
                    truncationMode: TruncationMode.Fade
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
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

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                    visible: text !== "" && !dialog.untouched
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.errorColor
                    text: dialog.rangeError(value1Field.text, dialog.limits1)
                          || dialog.rangeError(value2Field.text, dialog.limits2)
                }
            }

            DateTimeRow {
                id: whenRow
                width: parent.width
                selectedDate: dialog.selectedDate
                onPicked: dialog.selectedDate = when
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
