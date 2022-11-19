import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: page
    property Page previousPageID;
    property variant usercodes: []

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
    function setLID (){
        user_id=btnID.text;
        print(user_id);
    }
    function setUserID (){
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM Profiles')
                    if(user_id==null){
                        user_id=0
                    }else{
                        user_id = rs.rows.item(0).id_profile;
                        print(user_id)
                    }
            }
        )
    }

    function remplirListeUser() {
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM Profiles');
                for(var i =0; i< rs.rows.length;i++){
                    nameProfiles[i]= rs.rows.item(i).firstname;
                    usercodes[i]=rs.rows.item(i).id_profile;
                    print(nameProfiles[i]);
                    print(usercodes[i]);

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
                        setLID();
                    }
                    x: Theme.horizontalPageMargin
                    text: nameProfiles[1]

                }
            }
        }
    }
    Component.onCompleted:{
        nbrProfile()
        setUserID ()
        remplirListeUser()
        print("id user: "+user_id);
        print("nbr profil : " + numberProfile);
        print(nameProfiles[1])

    }
}
