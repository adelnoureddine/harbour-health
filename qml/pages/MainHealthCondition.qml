import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: rootHealthPage
    property bool editIllness: false
    property string user_id
    property Page mainPage
    property string illness_id
    property string name_illnes
    property string start_date
    property string end_date
    property string comments
    property variant ids_illness :[]



    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaGridView {
       id: gridView
       anchors.fill: parent
       model : listModel
       readonly property int columnCount: Math.floor(width/(Screen.width/2))
       cellWidth: parent.width/columnCount
       cellHeight: cellWidth


       header: PageHeader {
            title: qsTr("All illness data")
       }

       ViewPlaceholder {
            enabled: listModel.count === 0
            text: "No illness"
            hintText: "Pull down to add illness"
        }

       PullDownMenu {

            MenuItem {
                text: qsTr(" Add illness")
                onClicked: {
                    editIllness = false
                    pageStack.animatorPush(Qt.resolvedUrl("AddAndEditIllness.qml"))}
            }
        }
       delegate: ListItem {

            function loadInfosIllnes(){
                var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
                illness_id = ids_illness[index];
                name_illnes = listModel.get(index).text;
                db.transaction(
                   function(tx){
                       var rs1 = tx.executeSql('SELECT start_date,end_date,comments FROM HaveIllness WHERE id_profile=? AND illness_id=?',[id_user,illness_id]);
                       if(rs1.rows.length <= 0){
                            print("testeeee");
                       }
                       start_date = rs1.rows.item(0).start_date;
                       end_date = rs1.rows.item(0).end_date;
                       comments = rs1.rows.item(0).comments;
                   }
                   )


            }

            function removeFromDataBase(){
                var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
                illness_id = ids_illness[index];
                db.transaction(
                   function(tx){
                        tx.executeSql('DELETE FROM HaveIllness WHERE id_profile=? AND illness_id =?',[user_id,illness_id]);
                        tx.executeSql('DELETE FROM Illness WHERE illness_id =?',illness_id);
                    })
            }

            function remove() {
                remorseDelete(function() { listModel.remove(index) })
            }

            onClicked: {
                loadInfosIllnes()
                pageStack.animatorPush(Qt.resolvedUrl("ConsultIllness.qml"))
            }
            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: "Edit"
                        onClicked:{
                            loadInfosIllnes()
                            editIllness = true
                            pageStack.animatorPush(Qt.resolvedUrl("AddAndEditIllness.qml"))
                        }

                    }
                    MenuItem {
                        text: "Delete"
                        onClicked:{
                            remove()
                            removeFromDataBase()
                        }
                    }
                }
            }

            Column {
                id: content
                x: Theme.paddingLarge
                y: Theme.paddingLarge
                width: parent.width - 2 * x
                height: parent.height
                spacing: Theme.paddingMedium

                Label {
                    width: parent.width
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    text: (model.index+1) + ". " + model.text
                    wrapMode: Text.Wrap
                    font.capitalization: Font.Capitalize
                }
            }

          }


       VerticalScrollDecorator {}
    }


    ListModel {
        id: listModel
        Component.onCompleted: {
            mainPage=previousPage()
            user_id = mainPage.user_id
            load()
        }

        function load(){
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){
                   var rs1 = tx.executeSql('SELECT * FROM HaveIllness WHERE id_profile=?',user_id);
                    if(rs1.rows.length > 0){
                        var rs2;
                        var name_Illness;
                        var illness_id;
                        for(var i = 0;i<rs1.rows.length;i++){
                            illness_id=rs1.rows.item(i).illness_id;
                            ids_illness[i]= illness_id;
                            rs2 = tx.executeSql('SELECT * FROM Illness WHERE illness_id=?',illness_id);
                            name_Illness=rs2.rows.item(0).name;
                            listModel.append({"text":name_Illness})
                        }

                }
                }
            )

        }


}
}

