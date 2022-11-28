import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: history


    SilicaListView{
        anchors.fill: parent

        header: PageHeader {
            title: "Session history"
        }

        ViewPlaceholder {
            enabled: (listModel.populated && listModel.count === 0)
            text: "No content"
            hintText: "Pull down to add content"
        }


        model: ListModel{

            ListElement{ nom: "test" ;
                date: "02/12/2022"
            }
            ListElement{ nom: "test4" ;
                date: "013/12/2022"
            }

        }
        delegate: Item {
            width: ListView.view.width
            height: Theme.itemSizeSmall
            Label{
                text: nom + "   " + date
            }
        }
    }

    ListModel{
        id: listModel
        property bool populated
        property int userId: 1

        Component.onCompleted: {
            load()
        }


        function load(){
            db.transaction(
                function(tx) {
                    var rs = tx.executeSql("SELECT * FROM Meditation JOIN Musics ON Meditation.id_music = Musics.id_music WHERE id_profile = ?", [userId]);
                    var entries = rs.rows.length;
                    for (var index = 0; index < entries ; index++) {
                        listModel.append({"text": rs.rows.item(i).meditation_date +
                            "  " + rs.row.item(i).duration +
                            "  " + rs.row.item(i).Musics.name
                            })
                    }
                }
            );
        }

    }
}
