import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string metricName
    property string metricUnit
    property date selectedDate: new Date()
    property var invalidateSignal

    // Set when editing an existing reading rather than adding one.
    property int logId: -1
    // Set when the metric is already decided by the page that opened this dialog.
    property bool lockMetric: false

    readonly property bool editing: logId >= 0

    canAccept: profileId >= 0 && metricValue.text !== "" && dialog.metricName !== ""
               && metricValue.acceptableInput
               && !isNaN(parseFloat(metricValue.text.replace(',', '.')))

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
                metricValue.text = Utils.formatInput(log.value);
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
    }

    onAccepted: {
        var value = parseFloat(metricValue.text.replace(',', '.'));
        if (editing) {
            DataManager.updateLog(logId, value, selectedDate, noteField.text);
        } else {
            DataManager.addLog(profileId, dialog.metricName, value, selectedDate, noteField.text);
        }
        if (dialog.invalidateSignal) {
            dialog.invalidateSignal(dialog.metricName);
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
                title: dialog.editing
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
                            }
                        }
                    }
                }
            }

            TextField {
                id: metricValue
                width: parent.width
                label: dialog.metricUnit ? qsTr("Value (%1)").arg(dialog.metricUnit) : qsTr("Value")
                placeholderText: qsTr("Enter %1").arg(Utils.metricDisplayName(dialog.metricName))
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                // The old pattern was [\.|,], a character class that also accepted a
                // literal pipe, so "12|5" passed validation and then parsed as 12.
                validator: RegExpValidator { regExp: /^\d{1,6}([.,]\d{1,3})?$/ }
                focus: true
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: noteField.focus = true
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

            ValueButton {
                id: dateButton
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
                id: timeButton
                label: qsTr("Time")
                // Follows the system 12/24-hour setting.
                value: Format.formatDate(dialog.selectedDate, Formatter.TimeValue)
                onClicked: {
                    var timeDialog = pageStack.push("Sailfish.Silica.TimePickerDialog", {
                        hour: dialog.selectedDate.getHours(),
                        minute: dialog.selectedDate.getMinutes()
                    })
                    timeDialog.accepted.connect(function() {
                        // timeText is locale formatted -- in a 12-hour locale, parsing
                        // it recorded 1 pm as 01:00. The numeric properties are exact.
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

    // Loaded once. Reloading on PageStatus.Active would overwrite whatever the user
    // had typed every time they came back from the date or time picker.
    Component.onCompleted: load()
}

// vim:et:ts=4:sw=4
