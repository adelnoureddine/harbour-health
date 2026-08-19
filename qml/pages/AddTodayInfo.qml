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

    canAccept: profileId >= 0

    /*
     * A day has at most one entry, and saving replaces it. Load whatever is already
     * recorded for the chosen day so saving never silently drops fields the user
     * did not retype.
     */
    function loadForDate() {
        if (profileId < 0) {
            return;
        }
        var logs = DataManager.getMenstrualLogs(profileId, Utils.toLocalDateString(logDate));
        if (logs.length === 0) {
            return;
        }
        var log = logs[0];
        flow = log.flow;
        pain = log.pain;
        energy = log.energy;
        sleepHours = log.sleepTime;
        sleepSlider.value = log.sleepTime;
        notesField.text = log.note ? log.note : "";
    }

    onAccepted: {
            var dateStr = Utils.toLocalDateString(logDate);
            DataManager.addMenstrualLog(profileId, dateStr, flow, pain, energy, sleepHours, notesField.text);
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: qsTr("Record Daily Data")
                acceptText: qsTr("Save")
            }

            ValueButton {
                label: qsTr("Date")
                value: Qt.formatDate(logDate, Qt.DefaultLocaleShortDate)
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
                width: parent.width
                label: qsTr("Flow")
                currentIndex: ["None", "Spotting", "Light", "Medium", "Heavy"].indexOf(flow)
                menu: ContextMenu {
                    MenuItem { text: qsTr("None"); onClicked: flow = "None" }
                    MenuItem { text: qsTr("Spotting"); onClicked: flow = "Spotting" }
                    MenuItem { text: qsTr("Light"); onClicked: flow = "Light" }
                    MenuItem { text: qsTr("Medium"); onClicked: flow = "Medium" }
                    MenuItem { text: qsTr("Heavy"); onClicked: flow = "Heavy" }
                }
            }

            ComboBox {
                width: parent.width
                label: qsTr("Pain")
                currentIndex: ["None", "Mild", "Moderate", "Severe"].indexOf(pain)
                menu: ContextMenu {
                    MenuItem { text: qsTr("None"); onClicked: pain = "None" }
                    MenuItem { text: qsTr("Mild"); onClicked: pain = "Mild" }
                    MenuItem { text: qsTr("Moderate"); onClicked: pain = "Moderate" }
                    MenuItem { text: qsTr("Severe"); onClicked: pain = "Severe" }
                }
            }

            ComboBox {
                width: parent.width
                label: qsTr("Energy")
                currentIndex: ["Exhausted", "Low", "Normal", "High", "Peak"].indexOf(energy)
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
            }
        }
    }

    Component.onCompleted: loadForDate()
}
