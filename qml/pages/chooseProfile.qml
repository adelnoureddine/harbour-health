import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "../utils.js" as WtUtils


Page {
    id: root

    property variant usercodes: []
    property string usernewID;
    property variant nameProfiles: []
    property int numberProfile;
    property int test;

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
    function setLID (oui){
        var code = oui
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
                db.transaction(
                    function(tx){
                        tx.executeSql('UPDATE SETTINGS set USER_ID=(?)',[code]);
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

    function loadAllProfile (){
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        var user_nameProfile, user_idProfile;

        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM Profiles')
                if(rs.rows.length > 0){
                    for(var i=0 ; i<<rs.rows.length-nbrProfile() ; i++ ){
                        user_nameProfile = rs.rows.item(i).firstname;
                        user_idProfile = rs.rows.item(i).id_profile;
                        listModel.append({"text": user_nameProfile})
                    }
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
                   enabled: (listModel.populated && listModel.count === 0) || root.deletingItems
                   text: "No content"
                   hintText: "Pull down to add content"
               }
        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                text: qsTr("Home")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainPage.qml")) // Changer l'url pour mettre la page de l'autre groupe
            }
            MenuItem { // Si un nbrProfil = 0, ne pas afficher l'onglet information profil

                text: qsTr("Profile information")
                onClicked: pageStack.push(Qt.resolvedUrl("infosProfile.qml"))
            }

            MenuItem {
                text: qsTr("Create a profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("createProfile.qml"))
            }
        }
        delegate: GridItem {

                    onClicked: {
                        if (!menuOpen && pageStack.depth == 2) {
                            setLID(model.index+1)
                            pageStack.animatorPush(Qt.resolvedUrl("./infosProfile.qml"))
                        }
                    }

                    enabled: !root.deletingItems
                    opacity: enabled ? 1.0 : 0.0
                    Behavior on opacity { FadeAnimator {}}

                    Column {
                        id: content

                        x: Theme.paddingLarge
                        y: Theme.paddingLarge
                        width: parent.width - 2 * x
                        height: parent.height - y
                        spacing: Theme.paddingMedium

                        Label {
                            width: parent.width
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            text: "User : " + model.text
                            wrapMode: Text.Wrap
                            font.capitalization: Font.Capitalize
                        }

                    }

                    OpacityRampEffect {
                        sourceItem: content
                        slope: 1
                        offset: 0
                        direction: OpacityRamp.TopToBottom
                    }
                }
                VerticalScrollDecorator {}
            }

            ListModel {
                id: listModel

                }

    Component.onCompleted:{
        user_id = WtUtils.getLastUser()
    loadAllProfile()
        nbrProfile()
        remplirListeUser()

    }
}

