import QtQuick 2.6
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Dialog {
    id: dialog
    canAccept: firstnameField.text!="" && secondnameField.text!="" && genderField.text!="" && birthdayField.value!=""

    property string user_lastname;
    property string user_firstname;
    property string birth;
    property string gender;
    property string user_id;




    onAcceptPendingChanged: {
        if (acceptPending) {
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){
                    var code
                    var rs = tx.executeSql('SELECT MAX(id_profile) AS id_profile FROM Profiles');
                    if(rs.rows.item(0)===null) code = 1
                    else{
                        code = (rs.rows.item(0).id_profile) + 1;
                    }
                    tx.executeSql('INSERT INTO Profiles VALUES (?,?,?,?,?)',[code,firstnameField.text,secondnameField.text,genderField.currentItem.text,birthdayField.value]);

                    user_id=code;
                }
            )
        }
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


