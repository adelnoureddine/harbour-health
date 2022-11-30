import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: vaccineDetails
    property Page previousPage

    SilicaListView{
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Update")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("UpdateVaccine.qml"))
            }
            MenuItem {
                text: qsTr("Menu")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainPage.qml"))
            }
        }

        header: PageHeader {
            title: "Vaccines details"
        }

        model: listModel

        delegate: ListItem{

            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: "Edit"
                        onClicked: pageStack.animatorPush(Qt.resolvedUrl("UpdateRecall.qml"))
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
        property int userId

        Component.onCompleted: {
            load()
            previousPage = previousPage()
            userId = previousPage.userId
            //utils.js pour récupérer le dernier id_utilisateur
        }

        function load(){
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){
                    var rs = tx.executeSql("SELECT * FROM Injection WHERE id_profile = ? AND id_vaccine = ? ", [userId, vaccineId]);
                    for(var i = 0; i < rs.rows.length; i++){
                        listModel.append({"text": rs.rows.item(i).name})
                    }
                }
            );
        }

    }

}
