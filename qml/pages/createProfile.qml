import QtQuick 2.6
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "../utils.js" as WtUtils

Dialog {
    id: dialog
    canAccept: firstnameField.text!="" && secondnameField.text!="" && genderField.text!="" && birthdayField.value!=""

    property string user_lastname;
    property string user_firstname;
    property string birth;
    property string gender;

    onAcceptPendingChanged: {
        if (acceptPending) {
            var user_id = WtUtils.addProfile(firstnameField.text, secondnameField.text, genderField.currentItem.text, birthdayField.value);
	    WtUtils.useProfile(user_id);
        }
        onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainPage.qml"))

    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        VerticalScrollDecorator {}

        Column {
            id: column
            width: parent.width
            bottomPadding: Theme.paddingLarge

            DialogHeader {

                acceptText: "Save"
                title: "Create a profile"

            }


            TextField{
                id : firstnameField
                width:parent.width
                label: "First name";
                placeholderText: label
            }
            TextField{
                id : secondnameField
                width:parent.width
                label: "Second name";
                placeholderText: label
            }
            ComboBox {
                id:genderField
                label: "Gender"
                menu: ContextMenu {
                    MenuItem { text: "F" }
                    MenuItem { text: "M" }
                }
                width: parent.width/2
            }
            ValueButton {
                property date selectedDate

                function openDateDialog() {
                    var obj = pageStack.animatorPush("Sailfish.Silica.DatePickerDialog",
                                                     { date: selectedDate })

                    obj.pageCompleted.connect(function(page) {
                        page.accepted.connect(function() {
                            selectedDate = page.date
                            value = selectedDate.toLocaleDateString("yyyy-MM-dd")
                        })
                    })
                }
                label: "Birthday date"
                id : birthdayField
                width: parent.width
                onClicked: openDateDialog()

            }
        }
    }
}


