import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "../utils.js" as WtUtils


Page {
    id: page

    property variant usercodes: []
    property string usernewID;
    property variant nameProfiles: []

    property int numberProfile;
    property string user_id;

    allowedOrientations: Orientation.All

    function nbrProfile (){
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM Profiles')
                    numberProfile = rs.rows.length
            }
        )
    }
    function setLID (val){
        usernewID = val
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
                db.transaction(
                    function(tx){
                        tx.executeSql('UPDATE SETTINGS SET USER_ID=? WHERE USER_ID=?',[usernewID,user_id]);
                    })
    }


    function remplirListeUser() {
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM Profiles');
                for(var i =0; i< rs.rows.length;i++){
                    nameProfiles[i]= rs.rows.item(i).firstname;
                    usercodes[i]=rs.rows.item(i).id_profile;
                }
            }
        )
    }

    SilicaFlickable {
        anchors.fill: parent





        PullDownMenu {
            MenuItem {
                text: qsTr("Accueil")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainPage.qml")) // Changer l'url pour mettre la page de l'autre groupe
            }
            MenuItem { // Si un nbrProfil = 0, ne pas afficher l'onglet information profil
                text: qsTr("Information profil")
                onClicked: pageStack.push(Qt.resolvedUrl("infosProfile.qml"))
            }

            MenuItem {
                text: qsTr("Créer un profil")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("createProfile.qml"))
            }
        }

        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("Profils")
            }
            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("Choisissez un profil")
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeExtraLarge
            }
            Row{
                Button {
                    id:btnID
                    onClicked: {

                        setLID(btnID.text);
                    }
                    x: Theme.horizontalPageMargin
                    text: "2"


                }
            }
        }
    }

    Component.onCompleted:{
        user_id = WtUtils.getLastUser()

        nbrProfile()
        remplirListeUser()
        print("id user: "+ usercodes[user_id-1]);
        print("nbr profil total : " + numberProfile);
        print("nom du profil : " + nameProfiles[user_id-1]);
    }
}
