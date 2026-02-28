import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: 1
    property string metricType: "water" // Default, can be passed when pushing page

    function addData(value) {
        value = value.replace(',', '.');
        var selectedMetric = selectData.currentItem.text === "Input Calorie" ? "calories" : "water";
        DataManager.addLog(profileId, selectedMetric, parseFloat(value), "");
    }

    SilicaListView {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: qsTr("Add Health Data")
                acceptText: qsTr("Save")
            }

            TextField {
                id: dataField
                width: parent.width
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                label: selectData.currentItem ? selectData.currentItem.text : qsTr("Value")
                placeholderText: qsTr("Enter value")
                validator: RegExpValidator { regExp: /^\d+([\.|,]\d{1,2})?$/ }
                focus: true
                EnterKey.onClicked: dialog.addData(text)
            }

            ComboBox {
                id: selectData
                label: qsTr("Type")
                currentIndex: metricType === "calories" ? 0 : 1
                menu: ContextMenu {
                    MenuItem { text: qsTr("Input Calorie") }
                    MenuItem { text: qsTr("Input Liquid Quantity") }
                }
            }
        }
    }

    onAccepted: addData(dataField.text)
}



