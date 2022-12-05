import QtQuick 2.6
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "../utils.js" as WtUtils

Dialog {
    id: dialog
    canAccept: firstnameField.text!="" && secondnameField.text!="" && genderField.text!="" && birthdayField.value!=""

    property string user_lastname;
    property string user_firstname;
    property string user_birthday;
    property string user_gender;
    property string user_id;

    function setFirstname (){
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM Profiles WHERE id_profile = ?',[user_id]) // MANQUE LE WHERE = ID PROFILE
                if(rs.rows.length > 0){
                    user_firstname = rs.rows.item(0).firstname;
                }
            }
        )
    }
    function setLastname (){
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM Profiles WHERE id_profile = ?',[user_id]) // MANQUE LE WHERE = ID PROFILE
                if(rs.rows.length > 0){
                    user_lastname = rs.rows.item(0).lastname;
                }
            }
        )
    }
    function setGender (){
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM Profiles WHERE id_profile = ?',[user_id]) // MANQUE LE WHERE = ID PROFILE
                if(rs.rows.length > 0){
                    user_gender = rs.rows.item(0).gender;
                }
            }
        )
    }

    function setBirthday (){
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM Profiles WHERE id_profile = ?',[user_id]) // MANQUE LE WHERE = ID PROFILE
                if(rs.rows.length > 0){
                    user_birthday = rs.rows.item(0).birthday;
                }
            }
        )
    }


    onAcceptPendingChanged: {
        if (acceptPending) {
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){
                   tx.executeSql('UPDATE Profiles SET firstname = ?,lastname = ?,gender = ?,birthday = ? WHERE id_profile = ?',[firstnameField.text,secondnameField.text,genderField.currentItem.text,birthdayField.value,user_id]);



                }
            )
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
                title: "Modify a profile"

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
        Component.onCompleted:{
            user_id = WtUtils.getLastUser()

            setFirstname()
            setLastname()
            setGender()
            setBirthday()
        }
    }
}


