import QtQuick 2.0

import Sailfish.Silica 1.0

import QtQuick.LocalStorage 2.0

import "../utils.js" as WtUtils


Page {

    id: historyOfAllCycle

    property bool deletingItems
    property variant ids_menstrual :[]
    property string idMenstrual
    property string flow
    property string feeling
    property string pain
    property string energy
    property string sleepTime
    property string dateMenstrual


    function loadAllCycle (){

        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);

        db.transaction(

            function(tx){

                var rs = tx.executeSql('SELECT * FROM MenstrualCycles WHERE id_profile=?',[user_id])
                if(rs.rows.length > 0){
                   var user_dateOfCycle;
                    for(var i=0 ; i<rs.rows.length ; i++ ){
                        user_dateOfCycle = rs.rows.item(i).menstrual_date;
                        listModel.append({"text": user_dateOfCycle}) ;
                        ids_menstrual[i] = rs.rows.item(i).id_menstrual
                        print(user_dateOfCycle)  ;
                    }

                }

            }

        )

    }


    SilicaGridView {

        id: gridView
        model: listModel
        anchors.fill: parent
        readonly property int columnCount: Math.floor(width/(Screen.width/2))
        cellWidth: parent.width/columnCount
        cellHeight: cellWidth

        header: PageHeader {
            title: "History of all cycle"
        }


        ViewPlaceholder {
            enabled: listModel.count === 0
            text: "No content"
            hintText: "Pull down to add content"

        }

        PullDownMenu {
            id: pullDownMenu
            MenuItem {

                text: "Clear all"
                visible: gridView.count
                onClicked: {
                    root.deletingItems = true
                    var remorse = Remorse.popupAction(
                                root, "Cleared",
                                function() {
                                    listModel.clear()
                                })
                    remorse.canceled.connect(function() { root.deletingItems = false })
                }
            }

            /* ************************************************ */

            MenuItem {
                text: "Add Items"
                visible: !gridView.count
                onClicked: listModel.addItems()
            }

            /* ************************************************ */

        }

        delegate: GridItem {
            function loadInfosForCyle (){
                var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
                db.transaction(
                    function(tx){

                        idMenstrual =ids_menstrual[index];
                        print("tttttttt " + idMenstrual);
                        var rs = tx.executeSql('SELECT * FROM MenstrualFeelings WHERE id_menstrual=?',idMenstrual)
                        if(rs.rows.length > 0){

                            flow = rs.rows.item(0).flow;
                            feeling = rs.rows.item(0).feeling;
                            pain = rs.rows.item(0).pain;
                            energy = rs.rows.item(0).energy;
                            sleepTime = rs.rows.item(0).sleepTime;
                            dateMenstrual = rs.rows.item(0).feeling_date;
                            print("tttttttt " + dateMenstrual);

                        }

                    }

                )

            }
            function remove() {
                remorseDelete(function() { listModel.remove(index) })
            }
            onClicked: {
                    loadInfosForCyle ()
                    pageStack.animatorPush(Qt.resolvedUrl("./HistoryOfOneCycle.qml"))

            }
            enabled: !root.deletingItems
            opacity: enabled ? 1.0 : 0.0
            Behavior on opacity { FadeAnimator {}}

            menu: Component {

                ContextMenu {
                    MenuItem {
                        text: "Delete"
                        onClicked: remove()

                    }

                    MenuItem {
                        text: "Modify"

                    }

                }

            }


            Column {
                id: content
                x: Theme.paddingLarge
                y: Theme.paddingLarge
                width: parent.width - 2 * x
                height: parent.height - y
                spacing: Theme.paddingMedium


                Label {
                    width: parent.width
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    text: (model.index+1) + ". " + model.text
                    wrapMode: Text.Wrap
                    font.capitalization: Font.Capitalize
                }


                Label {
                    width: parent.width
                    text: "Description du cas"
                    font.pixelSize: Theme.fontSizeSmall
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                }

            }


            OpacityRampEffect {
                sourceItem: content
                slope: 1
                offset: 0
                direction: OpacityRamp.TopToBottom
            }

        }

        VerticalScrollDecorator {}

    }


    ListModel {

        id: listModel
        property bool populated
        Component.onCompleted: addItems()
        function addItems() {
            var entries = 2   // Nombre d'entités par colonnes
            for (var index = 0; index < entries; index++) {
                listModel.append({"text": spaceIpsumWords[index*2] + " " + spaceIpsumWords[index*2+1]})
            }

            for (index = 0; index < entries; index++) {
                listModel.append({"text": spaceIpsumWords[index*2] + " " + spaceIpsumWords[index*2+1]})
            }
            root.deletingItems = false
            populated = true

        }

    }


    Component.onCompleted:{

        user_id = WtUtils.getLastUser()

        print("id de l'user actif : " + user_id)

        loadAllCycle()

    }




}
