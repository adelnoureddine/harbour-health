import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "../utils.js" as WtUtils

Dialog {
    id: dialog

    property string user_firstname;
    property string user_lastname;
    property string user_gender;
    property string user_birthday;
    property string user_id;

    onAcceptPendingChanged: {
        if (acceptPending) {
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){
                    tx.executeSql('DELETE FROM Profiles WHERE id_profile=?',[user_id]); // Reussir a récuperer l'id de l'user
                }
            )
        }
        onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainPage.qml"))

    }

    function load(){
        setFirstname()
        setLastname()
        setGender()
        setBirthday()
    }



    function setFirstname (){
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM Profiles') // MANQUE LE WHERE = ID PROFILE
                if(rs.rows.length > 0){
                    user_firstname = rs.rows.item(0).firstname;
                    print(user_firstname)
                }
            }
        )
    }
    function setLastname (){
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM Profiles WHERE id_profile') // MANQUE LE WHERE = ID PROFILE
                if(rs.rows.length > 0){
                    user_lastname = rs.rows.item(0).lastname;
                    print(user_lastname)
                }
            }
        )
    }
    function setGender (){
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM Profiles') // MANQUE LE WHERE = ID PROFILE
                if(rs.rows.length > 0){
                    user_gender = rs.rows.item(0).gender;
                    print(user_gender)
                }
            }
        )
    }

    function setBirthday (){
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM Profiles') // MANQUE LE WHERE = ID PROFILE
                if(rs.rows.length > 0){
                    user_birthday = rs.rows.item(0).birthday;
                    print(user_birthday)
                }
            }
        )
    }
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        VerticalScrollDecorator {}

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("Supprimer le profil")

            }
            Row{
                Label {
                    x: Theme.horizontalPageMargin
                    width: page.width/2
                    text: qsTr(" First Name : ")
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                }
                Label {
                    width: page.width/2
                    x: Theme.horizontalPageMargin
                    text: user_firstname
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                }
            }

            Row{
                Label {
                    x: Theme.horizontalPageMargin
                    width: page.width/2
                    text: qsTr(" Last Name : ")
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                }
                Label {
                    width: page.width/2
                    x: Theme.horizontalPageMargin
                    text: user_lastname
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                }
            }

            Row{
                Label {
                    x: Theme.horizontalPageMargin
                    width: page.width/2

                    text: qsTr(" Gender : ")
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                }
                Label {
                    width: page.width/2
                    x: Theme.horizontalPageMargin
                    text: user_gender
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                }
            }

            Row{
                Label {
                    x: Theme.horizontalPageMargin
                    width: page.width/2

                    text: qsTr(" Birthday : ")
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                }
                Label {
                    width: page.width/2
                    x: Theme.horizontalPageMargin
                    text: user_birthday
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                }
            }
        }
        Component.onCompleted:{
            user_id = WtUtils.getLastUser()
            print("id de l'user actif : " + user_id)
                        load()

        }

    }
    }

