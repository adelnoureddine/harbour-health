import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property date logDate: new Date()
    property string flow: "None"
    property string pain: "None"
    property string energy: "Normal"
    property real sleepHours: 8.0

    // Context for the chosen day: its number in the cycle (0 outside one) and whether
    // it already has an entry, which saving replaces.
    property int cycleDay: 0
    property bool hasEntry: false

    readonly property var flowValues: ["None", "Spotting", "Light", "Medium", "Heavy"]
    readonly property var painValues: ["None", "Mild", "Moderate", "Severe"]
    readonly property var energyValues: ["Exhausted", "Low", "Normal", "High", "Peak"]

    // Picking a menu item replaces a ComboBox's currentIndex binding, so after the
    // first pick the boxes no longer follow the properties. Set them explicitly.
    function syncFields() {
        flowBox.currentIndex = flowValues.indexOf(flow);
        painBox.currentIndex = painValues.indexOf(pain);
        energyBox.currentIndex = energyValues.indexOf(energy);
        sleepSlider.value = sleepHours;
    }

    canAccept: profileId >= 0

    // Day of the cycle `dateStr` falls in, counted like the cycle details page: from the
    // latest start on or before it, while that cycle is open or not yet ended.
    function dayInCycle(dateStr) {
        var cycles = DataManager.getMenstrualCycles(profileId);
        for (var i = 0; i < cycles.length; i++) {
            var c = cycles[i];
            if (c.startDate <= dateStr) {
                if (c.endDate && dateStr > c.endDate) {
                    return 0;
                }
                var days = Utils.daysBetween(c.startDate, dateStr);
                return days === null ? 0 : days + 1;
            }
        }
        return 0;
    }

    /*
     * A day has at most one entry, and saving replaces it. Load whatever is already
     * recorded for the chosen day so saving never silently drops fields the user
     * did not retype.
     */
    function loadForDate() {
        if (profileId < 0) {
            return;
        }
        var dateStr = Utils.toLocalDateString(logDate);
        cycleDay = dayInCycle(dateStr);
        var logs = DataManager.getMenstrualLogs(profileId, dateStr);
        hasEntry = logs.length > 0;
        if (logs.length === 0) {
            // Start the new day clean. The previous day's values used to stay in the
            // form and were saved to this day as if the user had entered them.
            flow = "None";
            pain = "None";
            energy = "Normal";
            sleepHours = 8.0;
            notesField.text = "";
            syncFields();
            return;
        }
        var log = logs[0];
        flow = log.flow;
        pain = log.pain;
        energy = log.energy;
        sleepHours = log.sleepTime;
        notesField.text = log.note ? log.note : "";
        syncFields();
    }

    onAccepted: {
        var dateStr = Utils.toLocalDateString(logDate);
        DataManager.addMenstrualLog(profileId, dateStr, flow, pain, energy, sleepHours, notesField.text.trim());
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: qsTr("Record daily data")
                acceptText: qsTr("Save")
            }

            ValueButton {
                label: qsTr("Date")
                value: Qt.formatDate(logDate, Qt.DefaultLocaleShortDate)
                description: [
                    //: Context under the date: the day's number in the current cycle
                    dialog.cycleDay > 0 ? qsTr("Day %1 of the cycle").arg(dialog.cycleDay) : "",
                    dialog.hasEntry ? qsTr("Already recorded: saving replaces it") : ""
                ].filter(function (part) { return part !== ""; }).join(" · ")
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: logDate
                    })
                    dateDialog.accepted.connect(function() {
                        logDate = dateDialog.date;
                        loadForDate();
                    })
                }
            }

            ComboBox {
                id: flowBox
                width: parent.width
                label: qsTr("Flow")
                currentIndex: dialog.flowValues.indexOf(flow)
                menu: ContextMenu {
                    MenuItem { text: qsTr("None"); onClicked: flow = "None" }
                    MenuItem { text: qsTr("Spotting"); onClicked: flow = "Spotting" }
                    MenuItem { text: qsTr("Light"); onClicked: flow = "Light" }
                    MenuItem { text: qsTr("Medium"); onClicked: flow = "Medium" }
                    MenuItem { text: qsTr("Heavy"); onClicked: flow = "Heavy" }
                }
            }

            ComboBox {
                id: painBox
                width: parent.width
                label: qsTr("Pain")
                currentIndex: dialog.painValues.indexOf(pain)
                menu: ContextMenu {
                    MenuItem { text: qsTr("None"); onClicked: pain = "None" }
                    MenuItem { text: qsTr("Mild"); onClicked: pain = "Mild" }
                    MenuItem { text: qsTr("Moderate"); onClicked: pain = "Moderate" }
                    MenuItem { text: qsTr("Severe"); onClicked: pain = "Severe" }
                }
            }

            ComboBox {
                id: energyBox
                width: parent.width
                label: qsTr("Energy")
                currentIndex: dialog.energyValues.indexOf(energy)
                menu: ContextMenu {
                    MenuItem { text: qsTr("Exhausted"); onClicked: energy = "Exhausted" }
                    MenuItem { text: qsTr("Low"); onClicked: energy = "Low" }
                    MenuItem { text: qsTr("Normal"); onClicked: energy = "Normal" }
                    MenuItem { text: qsTr("High"); onClicked: energy = "High" }
                    MenuItem { text: qsTr("Peak"); onClicked: energy = "Peak" }
                }
            }

            Slider {
                id: sleepSlider
                width: parent.width
                label: qsTr("Sleep")
                minimumValue: 0
                maximumValue: 24
                stepSize: 0.5
                value: sleepHours
                valueText: qsTr("%1 hours").arg(Utils.formatValue(value, 1))
                onValueChanged: sleepHours = value
            }

            TextField {
                id: notesField
                width: parent.width
                label: qsTr("Notes")
                placeholderText: qsTr("How are you feeling?")
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.enabled: dialog.canAccept
                EnterKey.onClicked: dialog.accept()
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: loadForDate()
}
