import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: vaccinesList
    property Page rootPage
    property int vaccineId
    property int userId
    property bool isUpdate

    SilicaListView{
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Add a vaccine")
                onClicked: {
                    vaccinesList.isUpdate = false
                    pageStack.animatorPush(Qt.resolvedUrl("AddVaccine.qml"))
                }
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
            property int vaccine: model.vaccine
            function remove() {
                if(model.mandatory === 0){
                    var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
                    db.transaction(
                        function(tx){
                            //remove from database
                            var rs = tx.executeSql("DELETE FROM Vaccines WHERE id_vaccine = ?", model.vaccine);
                        }
                    );
                    //remove from model
                    remorseDelete(function() { listModel.remove(index) })
                }
            }

            onClicked:function (){
                vaccinesList.vaccineId = vaccine
                pageStack.animatorPush(Qt.resolvedUrl("VaccineDetails.qml"))
            }



            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: "Edit"
                    }
                    MenuItem {
                        visible: model.mandatory === 0 //can't delete mandatory vaccine
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

        Component.onCompleted: {
            rootPage = previousPage()
            userId = rootPage.userId
            load()
        }
    }

    function load(){
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        //Clear model before adding new data, to avoid adding the same data twice
        var size = listModel.count
        for(var i = 0; i < size; i++){
            listModel.remove(0);
        }


        db.transaction(
            function(tx){
                var rs = tx.executeSql("SELECT * FROM Vaccines WHERE Vaccines.isMandatory = 1 ");
                for(var i = 0; i < rs.rows.length; i++){
                    listModel.append({"text": rs.rows.item(i).name,
                                         "vaccine": rs.rows.item(i).id_vaccine,
                                         "mandatory": rs.rows.item(i).isMandatory
                                    })
                }

                var rs = tx.executeSql("SELECT * FROM Vaccines INNER JOIN Injection WHERE Injection.id_profile = ? AND Vaccines.isMandatory = 0", [userId]);
                for(var i = 0; i < rs.rows.length; i++){
                    listModel.append({"text": rs.rows.item(i).name,
                                         "vaccine": rs.rows.item(i).id_vaccine,
                                         "mandatory": rs.rows.item(i).isMandatory
                                    });
                }
            }
        );
    }
}
