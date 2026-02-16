import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "../utils.js" as WtUtils

Page {
    id: root

    property string user_firstname;
    property string user_lastname;
    property string user_gender;
    property string user_birthday;


    property string user_id;
    property Page previousPageID;





    function setFirstname (){
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM Profiles WHERE id_profile=?',[user_id]) // MANQUE LE WHERE = ID PROFILE
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
                var rs = tx.executeSql('SELECT * FROM Profiles WHERE id_profile=?',[user_id]) // MANQUE LE WHERE = ID PROFILE
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
                var rs = tx.executeSql('SELECT * FROM Profiles WHERE id_profile=?',[user_id]) // MANQUE LE WHERE = ID PROFILE
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
                var rs = tx.executeSql('SELECT * FROM Profiles WHERE id_profile=?',[user_id]) // MANQUE LE WHERE = ID PROFILE
                if(rs.rows.length > 0){
                    user_birthday = rs.rows.item(0).birthday;
                }
            }
        )
    }


    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Show profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainPage.qml"))
            }
            MenuItem {
                text: qsTr("Change profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("modifyProfile.qml"))
            }
            MenuItem {
                text: qsTr("Delete profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("deleteProfile.qml"))
            }
        }

        contentHeight: column.height

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("Profile information")
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

            setFirstname()
            setLastname()
            setGender()
            setBirthday()
        }

    }
}
