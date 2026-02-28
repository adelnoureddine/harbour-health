import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: 1
    property int metricId
    property string metricName
    property string metricUnit
    property date selectedDate: new Date()

    canAccept: metricValue.text !== ""

    onAccepted: {
        var dateStr = selectedDate.toISOString().split('T')[0];
        DataManager.addLog(profileId, metricName, parseFloat(metricValue.text.replace(',', '.')), "");
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: qsTr("Add %1").arg(metricName)
                acceptText: qsTr("Save")
            }

            TextField {
                id: metricValue
                width: parent.width
                label: qsTr("Value (%1)").arg(metricUnit)
                placeholderText: qsTr("Enter %1").arg(metricName)
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: RegExpValidator { regExp: /^\d+([\.|,]\d{1,2})?$/ }
                focus: true
                EnterKey.onClicked: dateButton.focus = true
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
                        selectedDate = dateDialog.date
                    })
                }
            }
        }
    }
}
