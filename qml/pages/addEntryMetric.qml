import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string metricName
    property string metricUnit
    property date selectedDate: new Date()

    // Set when editing an existing reading rather than adding one.
    property int logId: -1
    // Set when the metric is already decided by the page that opened this dialog.
    property bool lockMetric: false

    readonly property bool editing: logId >= 0

    // Under the value field; follows the type picker (updateContext). Empty when editing:
    // the value being edited is the last one.
    property string contextText: ""

    /*
     * metricUnit is the stored unit (Metrics.unit). The value is typed in shownUnit,
     * the unit chosen in Units, and converted back on saving; limits are what the
     * measurement can plausibly be, in that same unit (null without any).
     */
    property string shownUnit: ""
    property var limits: null
    property int limitDecimals: 2

    /*
     * Editing: the stored value and the text the field opened with. When the text was
     * not touched, the stored value is saved back as it is. Converted to pounds, shown
     * rounded and converted back, 72.5 kg would otherwise come back as 72.4999 after
     * changing nothing but the time.
     */
    property var originalValue: null
    property string originalText: ""
    readonly property bool untouched: editing && originalValue !== null && metricValue.text === originalText

    function typedValue() {
        return parseFloat(metricValue.text.replace(',', '.'));
    }

    readonly property bool inRange: {
        if (limits === null || metricValue.text === "" || !metricValue.acceptableInput) {
            return true;
        }
        var v = typedValue();
        return isNaN(v) || (v >= limits.min - 1e-9 && v <= limits.max + 1e-9);
    }

    // A value saved before there were limits can still have its time or note edited.
    canAccept: profileId >= 0 && metricValue.text !== "" && dialog.metricName !== ""
               && metricValue.acceptableInput && !isNaN(typedValue())
               && (untouched || inRange) && !whenRow.inFuture

    /*
     * Systolic and diastolic are one reading, logged together in the blood pressure
     * dialog. Offered here on their own (the cover's "+" opens this picker), either
     * half could be saved alone and showed up as "120 / —". Sorted by translated name:
     * the stored English names made the order look random once translated.
     */
    function loadMetricTypes() {
        var metrics = DataManager.getMetrics().filter(function (m) {
            return m.name !== DataManager.METRIC_BP_SYS && m.name !== DataManager.METRIC_BP_DIA;
        });
        metrics.sort(function (a, b) {
            return Utils.metricDisplayName(a.name).localeCompare(Utils.metricDisplayName(b.name));
        });
        metricTypeModel.clear();
        if (metrics.length > 0) {
            metricTypeModel.append(metrics);
        }
    }

    /*
     * The reading to type the new one against, under the value field: a slip such as
     * 665 for 66.5 stands out next to it. Water and calories add up over the day, so
     * they show today's total once there is one.
     */
    function lastReadingText(name, unit, grouped) {
        if (profileId < 0 || name === "" || editing) {
            return "";
        }
        var suffix = unit ? " " + unit : "";
        var decimals = DataManager.displayDecimals(name, 2);
        if (grouped) {
            var total = DataManager.getTodayTotal(profileId, name);
            if (total !== null) {
                //: Under the value field: today's total so far, %1 is the amount with its unit
                return qsTr("Today so far: %1").arg(Utils.formatValue(DataManager.toDisplay(name, total), decimals) + suffix);
            }
        }
        var log = DataManager.getLatestLog(profileId, name);
        return log ? Utils.lastReadingText(Utils.formatValue(DataManager.toDisplay(name, log.value), decimals) + suffix,
                                           log.timestamp) : "";
    }

    // Once name and unit are both set: a binding ran the queries for each of them, the
    // first time with the previous type's unit.
    function updateContext() {
        var grouped = false;
        for (var i = 0; i < metricTypeModel.count; i++) {
            if (metricTypeModel.get(i).name === dialog.metricName) {
                grouped = metricTypeModel.get(i).grouped ? true : false;
                break;
            }
        }
        shownUnit = DataManager.displayUnit(dialog.metricName, dialog.metricUnit);
        var stored = DataManager.metricLimits(dialog.metricName);
        limits = stored === null ? null : { min: DataManager.toDisplay(dialog.metricName, stored.min),
                                            max: DataManager.toDisplay(dialog.metricName, stored.max) };
        limitDecimals = DataManager.displayDecimals(dialog.metricName, 2);
        contextText = lastReadingText(dialog.metricName, shownUnit, grouped);
    }

    function load() {
        loadMetricTypes();
        if (!lockMetric && !editing && (dialog.metricName === DataManager.METRIC_BP_SYS
                                        || dialog.metricName === DataManager.METRIC_BP_DIA)) {
            // Never preselect half a pair: the type has to be picked.
            dialog.metricName = "";
            dialog.metricUnit = "";
        }

        if (editing) {
            var log = DataManager.getLog(logId);
            if (log) {
                dialog.metricName = log.metricName;
                dialog.metricUnit = log.unit;
                // Three decimals, as many as the field accepts: rounding to two here
                // silently changed 1.755 to 1.76 when only the time was edited.
                metricValue.text = Utils.formatInput(DataManager.toDisplay(log.metricName, log.value));
                originalValue = log.value;
                originalText = metricValue.text;
                noteField.text = log.note ? log.note : "";
                var parsed = Utils.parseTimestamp(log.timestamp);
                if (parsed !== null) {
                    dialog.selectedDate = parsed;
                }
            }
        }

        // Preselect the metric that was passed in. The combo box used to always open
        // on the first entry regardless of which metric the user had tapped.
        for (var i = 0; i < metricTypeModel.count; i++) {
            if (metricTypeModel.get(i).name === dialog.metricName) {
                metricField.currentIndex = i;
                break;
            }
        }
        metricField.value = Utils.metricDisplayName(dialog.metricName);
        updateContext();
    }


    onAccepted: {
        var value = untouched ? originalValue : DataManager.fromDisplay(dialog.metricName, typedValue());
        if (editing) {
            DataManager.updateLog(logId, value, selectedDate, noteField.text);
        } else {
            DataManager.addLog(profileId, dialog.metricName, value, selectedDate, noteField.text);
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
                // Opened without a metric to preselect, no type is picked yet.
                title: dialog.metricName === "" ? qsTr("Add measurement")
                       : dialog.editing
                       //: Dialog title; %1 is a measurement name such as "Weight"
                       ? qsTr("Edit %1").arg(Utils.metricDisplayName(dialog.metricName))
                       //: Dialog title; %1 is a measurement name such as "Weight"
                       : qsTr("Add %1").arg(Utils.metricDisplayName(dialog.metricName))
                acceptText: qsTr("Save")
            }

            ComboBox {
                id: metricField
                width: parent.width
                label: qsTr("Type")
                // Pointless once the metric is fixed by the calling page.
                visible: !dialog.lockMetric && !dialog.editing

                menu: ContextMenu {
                    Repeater {
                        model: ListModel {
                            id: metricTypeModel
                        }
                        MenuItem {
                            text: Utils.metricDisplayName(model.name)
                            onClicked: {
                                dialog.metricName = model.name;
                                dialog.metricUnit = model.unit;
                                dialog.updateContext();
                            }
                        }
                    }
                }
            }

            // The value with what helps to type it: the last reading, where to measure.
            Column {
                width: parent.width
                spacing: Theme.paddingSmall

                TextField {
                    id: metricValue
                    width: parent.width
                    label: dialog.shownUnit ? qsTr("Value (%1)").arg(dialog.shownUnit) : qsTr("Value")
                    placeholderText: qsTr("Enter %1").arg(Utils.metricDisplayName(dialog.metricName))
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    // The old pattern was [\.|,], a character class that also accepted a
                    // literal pipe, so "12|5" passed validation and then parsed as 12.
                    validator: RegExpValidator { regExp: /^\d{1,6}([.,]\d{1,3})?$/ }
                    focus: true
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

                // 250 typed into a field of litres, a height in metres, 665 for 66.5.
                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    visible: dialog.limits !== null && !dialog.inRange && !dialog.untouched
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.errorColor
                    text: dialog.limits === null ? ""
                          : Utils.rangeText(dialog.limits.min, dialog.limits.max, dialog.shownUnit, dialog.limitDecimals)
                }

                // Where to measure, for metrics whose reading depends on it (waist).
                // Follows the type picker, so it appears and disappears with the metric.
                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    text: Utils.metricHint(dialog.metricName)
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryHighlightColor
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

    // Loaded once. Reloading on PageStatus.Active would overwrite whatever the user
    // had typed every time they came back from the date or time picker.
    Component.onCompleted: load()
}

// vim:et:ts=4:sw=4
