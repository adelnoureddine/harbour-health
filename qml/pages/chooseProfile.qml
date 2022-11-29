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


    property bool deletingItems


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
                    usercodes[i]=rs.rows.item(i).id_profile;
                    listModel.append({text: rs.rows.item(i).firstname})
                }
            }
        )
    }

     SilicaGridView {
        anchors.fill: parent
        id:gridView
        model: listModel
               readonly property int columnCount: Math.floor(width/(Screen.width/2))
               cellWidth: parent.width/columnCount
               cellHeight: cellWidth

               header: PageHeader {
                   title: "Choose a profile"
               }

               ViewPlaceholder {
                   enabled: (listModel.populated && listModel.count === 0) || page.deletingItems
                   text: "No content"
                   hintText: "Pull down to add content"
               }
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
        delegate: GridItem {
                    function remove() {
                        remorseDelete(function() { listModel.remove(index) })
                    }

                    onClicked: {
                        if (!menuOpen && pageStack.depth == 2) {
                            pageStack.animatorPush(Qt.resolvedUrl("./HistoryOfOneCycle.qml"))
                        }
                    }

                    enabled: !root.deletingItems
                    opacity: enabled ? 1.0 : 0.0
                    Behavior on opacity { FadeAnimator {}}

                    menu: Component {
                        ContextMenu {
                            MenuItem {
                                text: "Delete"
                                onClicked: remove()
                            }
                            MenuItem {
                                text: "Modify"
                            }
                        }
                    }
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge

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
                    text: "0"


                }
            }
        }
        ListModel {
                id: listModel
                property bool populated
                Component.onCompleted: addItems()
                function addItems() {
                    var entries = 2   /* Nombre d'entités par colonnes */
                    for (var index = 0; index < entries; index++) {
                        listModel.append({"text": spaceIpsumWords[index*2] + " " + spaceIpsumWords[index*2+1]})
                    }
                    for (index = 0; index < entries; index++) {
                        listModel.append({"text": spaceIpsumWords[index*2] + " " + spaceIpsumWords[index*2+1]})
                    }
                    page.deletingItems = false
                    populated = true
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
}
