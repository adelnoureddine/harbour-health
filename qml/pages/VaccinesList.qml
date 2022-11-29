import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: vaccinesList

    SilicaListView{
        anchors.fill: parent


        PullDownMenu {
            MenuItem {
                text: qsTr("Add a vaccine")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("NewVaccine.qml"))
            }
            MenuItem {
                text: qsTr("Menu")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainPage.qml"))
            }
        }

        header: PageHeader {
            title: "Vaccines list"
        }


        model: listModel

        delegate: ListItem{

            function remove() {
                remorseDelete(function() { listModel.remove(index) })
            }

            onClicked: {
                pageStack.animatorPush(Qt.resolvedUrl("VaccineDetails.qml"))
            }


            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: "Edit"

                    }
                    MenuItem {
                        text: "Delete"
                        onClicked: remove()
                    }
                }
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                anchors.verticalCenter: parent.verticalCenter
                text: model.text
                truncationMode: TruncationMode.Fade
                font.capitalization: Font.Capitalize
            }
        }
    }

    ListModel{
        id: listModel
        property int userId: 0

        Component.onCompleted: {
            load()
            //utils.js pour récupérer le dernier id_utilisateur
        }

        function load(){
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){
                    var rs = tx.executeSql("SELECT * FROM Vaccines");
                    for(var i = 0; i < rs.rows.length; i++){
                        listModel.append({"text": rs.rows.item(i).name})
                    }
                }
            );
        }

    }
}
