import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: vaccineDetails
    property Page rootPage
    property int vaccineId
    property int userId
    property bool isUpdate
    property int injectionId

    SilicaListView{
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Update")

                onClicked:{
                    vaccineDetails.isUpdate = true
                    pageStack.animatorPush(Qt.resolvedUrl("updateRecall.qml"))
                }
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
            enabled: listModel.count ===  0
            text: "No injection for this vaccine"
            hintText: "Swipe down to add one !"
        }


        model: listModel

        delegate: ListItem{
            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: "Edit"
                        onClicked:{
                            vaccineDetails.isUpdate = false
                            vaccineDetails.injectionId = id
                            pageStack.animatorPush(Qt.resolvedUrl("updateRecall.qml"))
                        }
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



    }
    function loadModel(){
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        //Clear model before adding new data; (solved edit recall problem)
        var size = listModel.count
        for(var i=0; i < size; i++){
            listModel.remove(0)
        }

        db.transaction(
            function(tx){
                var rs = tx.executeSql("SELECT * FROM Injection WHERE id_profile = ? AND id_vaccine = ? ", [userId,vaccineId]);
                for(var i = 0; i < rs.rows.length; i++){
                    listModel.append({"text": rs.rows.item(i).injection_date, "id":rs.rows.item(i).id_injection})
                }
            }
        );
    }

}
