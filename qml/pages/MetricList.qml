import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: metricList
    property Page rootPage
    property int metricId
    property int userId
    property string metricName

    signal nameSignal(string txt)

    SilicaListView{
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Menu")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainPage.qml"))
            }
        }

        header: PageHeader {
            title: "Metrics list"
        }


        model: listModel

        delegate: ListItem{

            function remove() {
                remorseDelete(function() { listModel.remove(index) })
            }

            onClicked:{
                metricList.metricId = metric
                metricList.metricName = model.name
                pageStack.animatorPush(Qt.resolvedUrl("MetricDetails.qml"))
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
        property int userId

        Component.onCompleted: {
            rootPage = previousPage()
            userId = rootPage.userId
            load()
            //utils.js pour récupérer le dernier id_utilisateur
        }

        function load(){
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){
                    var rs = tx.executeSql("SELECT * FROM Metrics");
                    for(var i = 0; i < rs.rows.length; i++){
                        listModel.append({"text": rs.rows.item(i).name,
                                             "metric": rs.rows.item(i).id_metric,
                                             "name": rs.rows.item(i).name
                                         })
                    }
                }
            );
        }



    }
}
