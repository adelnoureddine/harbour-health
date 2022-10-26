import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    SilicaListView
       {
            anchors.fill: parent
            contentHeight: column.height

            Column {
                id: column
                width: parent.width
                spacing: Theme.paddingLarge

                PageHeader { title: 'Consult Health History' }

                TextField {
                    id: metricField
                    width: parent.width
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    label: "Ltr/°C"
                    placeholderText: "Nutrition Data"
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: phoneField.focus = true
                    validator: RegExpValidator { regExp: /^\d+([\.|,]\d{1,2})?$/ }
                    focus: true
                }
                Button {
                    text: 'Add Data'
                    anchors.horizontalCenter: parent.horizontalCenter
                    enabled:metricField.acceptableInput
                    onClicked: addMetric(metricField.text)
                }
            }
        }
}


/*
{
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader { title: 'Add new weight data' }

            TextField {
                id: metricField
                width: parent.width
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                label: "kg"
                placeholderText: "Weight"
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: phoneField.focus = true
                validator: RegExpValidator { regExp: /^\d+([\.|,]\d{1,2})?$/ }
                focus: true
            }
            Button {
                text: 'Add'
                anchors.horizontalCenter: parent.horizontalCenter
                enabled:metricField.acceptableInput
                onClicked: addMetric(metricField.text)
            }
        }
    }

  */

