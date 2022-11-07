import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: page

    property string user_firstname;
    property string user_lastname;
    property string user_gender;
    property string user_birthday;
    property int user_id;



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
                    user_firstname = rs.rows.item(user_id+1).firstname;
                    print(user_firstname)
                    print(rs.rows.item(1).id_profile)
                }
                print("taille : " +rs.rows.length)
            }
        )
    }
    function setLastname (){
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM Profiles') // MANQUE LE WHERE = ID PROFILE
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

    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Afficher les profils")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainPage.qml"))
            }
            MenuItem {
                text: qsTr("Modifier le profil")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("createProfile.qml"))
            }
            MenuItem {
                text: qsTr("Supprimer le profil")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("deleteProfile.qml"))
            }
        }

        contentHeight: column.height

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("Information profil")
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
                        load()

        }

    }
}
