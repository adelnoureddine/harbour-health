import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: consultIlness
    property string user_id
    property Page mainPagehealth
    property string illness_id
    property string name_illnes
    property string start_date
    property string end_date
    property string comments
    property bool edditMedication: false
    property string medication_id
    property variant medications_ids : []

    allowedOrientations: Orientation.All
    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + content.height + Theme.paddingLarge
        contentWidth: parent.width

        VerticalScrollDecorator {}

        PullDownMenu {
            MenuItem {
                text: qsTr("Illness list")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainHealthCondition.qml"))
            }

            MenuItem {
                text: qsTr("Add medication")
                onClicked:{
                    edditMedication = false
                    pageStack.animatorPush(Qt.resolvedUrl("AddAndEditMedication.qml"))}
            }
        }

        Column {
            id: column
            spacing: Theme.paddingLarge
            //anchors.fill: parent
            width: parent.width

            PageHeader {
                title: "Consult illness"
            }

            SectionHeader {
                text: "Information about this illness"
            }
            Rectangle {
                color: "black"
                height: Theme.itemSizeSmall
                width: page.width
                Label {
                    color: Theme.lightPrimaryColor
                    text: "the name : " +name_illnes
                    anchors.centerIn: parent
                }
            }

            Rectangle {
                color: "black"
                height: Theme.itemSizeSmall
                width: page.width
                Label {
                    color: Theme.lightPrimaryColor
                    text: "Start date :" +start_date
                    anchors.centerIn: parent
                }
            }

            Rectangle {
                color: "black"
                height: Theme.itemSizeSmall
                width: page.width
                Label {
                    color: Theme.lightPrimaryColor
                    text: "End date :" +end_date
                    anchors.centerIn: parent
                }
            }

            Rectangle {
                color: "black"
                height: Theme.itemSizeSmall
                width: page.width
                Label {
                    color: Theme.lightPrimaryColor
                    text: "Comments :" +comments
                    anchors.centerIn: parent
                }
            }

            SectionHeader {
                id: titleMedication
                text: "the medication(s) for this illness"
            }

            SilicaGridView {
                width: parent.width
                height: titleMedication.height + 2
                model: listModel
                readonly property int columnCount: Math.floor(width/(Screen.width/2))
                cellWidth: parent.width/columnCount
                cellHeight: cellWidth

                ViewPlaceholder {
                     enabled: listModel.count === 0
                     text: "No medications"
                     hintText: "Pull down to add medications"
                 }

                delegate: ListItem {

                    function remove() {
                        remorseDelete(function() { listModel.remove(index) })
                    }

                    function removeFromData() {
                        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
                        medication_id = medications_ids[index];
                        db.transaction(
                           function(tx){
                                tx.executeSql('DELETE FROM HaveMedication WHERE id_profile=? AND id_illness =? AND id_medication=?',[user_id,illness_id,medication_id]);
                                tx.executeSql('DELETE FROM Medication WHERE id_medication =?',medication_id);
                            })
                    }


                    onClicked: {
                        medication_id = medications_ids[index];
                        pageStack.animatorPush(Qt.resolvedUrl("ConsultMedication.qml"))
                    }


                    menu: Component {
                        ContextMenu {
                            MenuItem {
                                text: "Edit"
                                onClicked:{
                                    edditMedication = true
                                    pageStack.animatorPush(Qt.resolvedUrl("AddAndEditMedication.qml"))
                                }

                            }
                            MenuItem {
                                text: "Delete"
                                onClicked: {
                                    remove()
                                    removeFromData()
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
                    VerticalScrollDecorator {}
           }

        }
        }
    }

    ListModel {
        id: listModel
        Component.onCompleted:{
            mainPagehealth=previousPage()
            user_id = mainPagehealth.user_id
            illness_id = mainPagehealth.illness_id
            name_illnes = mainPagehealth.name_illnes
            start_date = mainPagehealth.start_date
            end_date = mainPagehealth.end_date
            comments = mainPagehealth.comments
            loadData()
        }
        // pour charger les maladies de la base de données
        function loadData(){
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){
                    var res1 = tx.executeSql('SELECT * FROM HaveMedication WHERE id_illness=? AND id_profile =?',[illness_id,user_id]);
                    if(res1.rows.length > 0){
                        var res2;
                        var name_medication;
                        var medication_id;
                        for(var i=0;i<res1.rows.length;i++){
                            medication_id = res1.rows.item(i).medication_id;
                            medications_ids[i]= medication_id;
                            res2 = tx.executeSql('SELECT * FROM Medication WHERE id_medication=?',[medication_id]);
                            name_medication = res2.rows.item(0).name;
                            listModel.append({"text": name_medication});
                        }

                    }

                }
                )

        }

    }
}


