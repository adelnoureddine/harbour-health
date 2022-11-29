import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: history


    SilicaListView{
        anchors.fill: parent

        //pullDownMenu: delete all session record

        header: PageHeader {
            title: "Session history"
        }

        ViewPlaceholder {
            enabled: (listModel.count === 0)
            text: "No content"
            hintText: "No session registered yet"
        }

        model: listModel
        /*
        model: ListModel{

            ListElement{ nom: "test" ;
                date: "02/12/2022"
            }
            ListElement{ nom: "test4" ;
                date: "013/12/2022"
            }
        }
        */

        delegate: Item {
            width: ListView.view.width
            height: Theme.itemSizeSmall

            Label{
                text: model.text
            }
        }
    }

    ListModel{
        id: listModel
        property bool populated
        property int userId:0

        Component.onCompleted: {
            load()
            //utils.js pour récupérer le dernier id_utilisateur
        }


        function load(){
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx) {
                    var rs = tx.executeSql("SELECT * FROM Meditation WHERE id_profile = ?", [userId]);//INNER JOIN Musics ON Musics.id_music == Meditation.id_music
                    var entries = rs.rows.length;
                    console.log("nombre de lignes: " + entries)
                    for (var i = 0; i < entries ; i++) {
                        listModel.append({"text": rs.rows.item(i).meditation_date +
                            "  " + rs.rows.item(i).duration +
                            "  " + rs.rows.item(i).name
                            })
                    }
                }
            );
        }

    }
}
