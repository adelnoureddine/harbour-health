import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
   // allowedOrientations: Orientation.All



    // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
    PullDownMenu {
        MenuItem {
            text: qsTr("Consult History")
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("ConsultHistory.qml"))
        }
        MenuItem {
            text: qsTr("Daily Information")
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("Consul-Jour.qml"))
        }
    }


    SilicaListView
       {
            anchors.fill: parent
            contentHeight: column.height

            Column {
                id: column
                width: parent.width
                spacing: Theme.paddingLarge

                DialogHeader {
                    acceptText: "save"
                    title: 'Add new Data' }

                TextField {
                    id: nutritionTF
                    width: parent.width
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    label: "Ltr/°C"
                    placeholderText: "Nutrition Data"
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: phoneField.focus = true
                    validator: RegExpValidator { regExp: /^\d+([\.|,]\d{1,2})?$/ }
                    focus: true
                }

                ComboBox{
                    id : selectData
                    label:  "Choice"
                        menu: ContextMenu{
                            MenuItem{ text: "Input Calorie" }
                            MenuItem{ text: "Input Liquid Quantity" }
                        }
                    width:parent.width/2
                }


            }
        }
}



