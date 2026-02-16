import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "../utils.js" as WtUtils


Page {
    id: metricDetails
    property Page rootPage
    property int metricId
    property int userId: WtUtils.getLastUser()


    SilicaListView{
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("add an entry")
                onClicked: {
                    metricDetails.metricId = metricId
                    pageStack.animatorPush(Qt.resolvedUrl("addEntryMetric.qml"))
                }
            }
            MenuItem {
                text: qsTr("Menu")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainPage.qml"))
            }
            MenuItem{
                text: qsTr("Delete Values")
                onClicked:{
                    var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
                    db.transaction(
                        function(tx){
                            var size = listModel.count
                            for(var i = 0; i < size; i++){
                                listModel.remove(0);
                            }
                            tx.executeSql("DELETE FROM MetricValue WHERE id_profile = ? AND id_metric = ?", [userId, metricId]);
                    });

                }
            }

        }

        header: PageHeader {
            title: rootPage.metricName + " Details"
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
                        text: model.text + " " + model.unit + "     " + model.date
                        truncationMode: TruncationMode.Fade
                        font.capitalization: Font.Capitalize
                    }

                }
            }

            ListModel{
                id: listModel


                Component.onCompleted: {
                    rootPage = previousPage()
                    metricId = rootPage.metricId

                    console.log("metric: " + metricId + " userId = " + userId)
                    console.log("SELECT * FROM MetricValue WHERE id_profile = ? ", [userId])
                    //utils.js pour récupérer le dernier id_utilisateur
                    load()
                }



            }
            function load(){
                var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
                var size = listModel.count
                for(var i=0; i < size; i++){
                    listModel.remove(0)
                }

                db.transaction(
                    function(tx){
                        var rs = tx.executeSql("SELECT * FROM MetricValue INNER JOIN Metrics on Metrics.id_metric = MetricValue.id_metric  WHERE id_profile = ? AND MetricValue.id_metric = ?",[userId,metricId]);
                        for(var i = 0; i < rs.rows.length; i++){
                            console.log(rs.rows.item(i).id_profile)
                            console.log(rs.rows.item(i).id_metric)
                            console.log(rs.rows.item(i).value_metric)
                            listModel.append({"text": rs.rows.item(i).value_metric,
                                                "unit": rs.rows.item(i).unit,
                                                 "date": rs.rows.item(i).date_metric,
                                             })
                        }
                    }
                );
            }

        }
