import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: page
    allowedOrientations: Orientation.All
    SilicaFlickable {
        anchors.fill: parent
        property int numberProfile;



        function load (){
            nbrProfile()
        }

        function nbrProfile (){
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){
                    var rs = tx.executeSql('SELECT * FROM Profiles')
                        numberProfile = rs.rows.length
                        print("taille : " +rs.rows.length)


                }
            )
        }
        PullDownMenu {
            MenuItem {
                text: qsTr("Accueil")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainPage.qml")) // Changer l'url pour mettre la page de l'autre groupe
            }
            MenuItem { // Si un nbrProfil = 0, ne pas afficher l'onglet information profil
                text: qsTr("Information profil")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("infosProfile.qml"))
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
        }
    }
    Component.onCompleted:{
        load()
    }
}
