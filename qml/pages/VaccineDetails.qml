import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: vaccineDetails
    property Page rootPage
    property int vaccineId
    property int userId

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

        ViewPlaceholder {
            enabled: model.count ==  0
            text: "No injection for this vaccine"
            hintText: "Swipe down to add one !"
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


        Component.onCompleted: {
            //get vaccineId and userId from previousPage
            rootPage = previousPage()
            vaccineId = rootPage.vaccineId
            userId = rootPage.userId

            //load the model from database
            loadModel()
        }

        function loadModel(){
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){
                    console.log("id_user: " + userId)
                    var rs = tx.executeSql("SELECT * FROM Injection WHERE id_profile = ? AND id_vaccine = ? ", [userId,vaccineId]);
                    console.log("number of boosters: " + rs.rows.length)
                    for(var i = 0; i < rs.rows.length; i++){
                        listModel.append({"text": rs.rows.item(i).injection_date})
                    }
                }
            );
        }

    }

}
