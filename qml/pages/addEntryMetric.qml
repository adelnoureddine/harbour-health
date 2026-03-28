import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string metricName
    property string metricUnit
    property date selectedDate: new Date()
    property var invalidateSignal

    canAccept: profileId >= 0 && metricValue.text !== "" && dialog.metricName !== ""

    onAccepted: {
        DataManager.addLog(profileId, metricField.value, parseFloat(metricValue.text.replace(',', '.')), selectedDate, noteField.text);
        dialog.invalidateSignal(dialog.metricName)
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: qsTr("Add %1 (%2)").arg(metricName).arg(metricUnit)
                acceptText: qsTr("Save")
            }

            ComboBox {
                id: metricField
                label: qsTr("Type")
                menu: ContextMenu {
                    Repeater {
                        model: ListModel {
                            id: metricTypeModel
                        }
                        MenuItem {
                            text: model.name
                            onClicked: {
                                metricField.value = model.name;
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
                label: qsTr("Value (%1)").arg(metricUnit)
                placeholderText: qsTr("Enter %1").arg(metricName)
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: RegExpValidator { regExp: /^\d+([\.|,]\d{1,2})?$/ }
                focus: true
            }

            ValueButton {
                id: dateButton
                label: qsTr("Date")
                value: selectedDate.toLocaleDateString()
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: selectedDate
                    })
                    dateDialog.accepted.connect(function() {
			            var dateStr = dateDialog.date.toISOString().split('T')[0];
			            var timeStr = selectedDate.toISOString().split('T')[1];
                        selectedDate = new Date(dateStr + ' ' + timeStr);
                    })
                }
            }

            ValueButton {
                id: timeButton
                label: qsTr("Time")
                value: selectedDate.toLocaleTimeString()
                onClicked: {
                    var timeDialog = pageStack.push("Sailfish.Silica.TimePickerDialog", {
                        hour: selectedDate.getHours(),
                        minute: selectedDate.getMinutes()
                    })
                    timeDialog.accepted.connect(function() {
			            var dateStr = selectedDate.toISOString().split('T')[0];
			            var timeStr = timeDialog.timeText + ":00";
                        selectedDate = new Date(dateStr + ' ' + timeStr);
                    })
                }
            }

            TextField {
                id: noteField
                label: qsTr("Note")
            }
        }
    }

    Component.onCompleted: {
        DataManager.getMetricsToModel(metricTypeModel);
        metricField.value = dialog.metricName;
        // TODO: find a way to select the one that was supplied from the properties
        // extend with (Food: no unit) and that should be a combination of water content/calories content (or other measurables, like fat, or sugar, or ...)
        // and find a way to show nothing if the property was null
        // time field does not start with the entered time
        // metricType does not change, even though the rest does
    }
}

// vim:et:ts=4:sw=4
