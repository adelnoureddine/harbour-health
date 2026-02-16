
import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: page
    allowedOrientations: Orientation.All

    property bool deletingItems
    property Page rootPage
    property variant metric_tab: []

    function load(){
        listModel.load()
    }

    SilicaListView {
        id: listView
        model: listModel
        anchors.fill: parent

        header: PageHeader {
            title: qsTr("History Consultation")
        }

        ViewPlaceholder {
            enabled: (listModel.populated && listModel.count === 0) || page.deletingItems
            text: "Empty history"
            hintText: "Pull down to add data"
        }

        PullDownMenu {
            id: pullDownMenu

            MenuItem {
                text: "Clear all History Data"
                visible: listView.count
                onClicked: {
                    page.deletingItems = true
                    var remorse = Remorse.popupAction(
                                page, "Cleared",
                                function() {
                                    var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
                                    db.transaction(
                                        function(tx){
                                            tx.executeSql('DELETE FROM MetricValue WHERE id_profile=?',[rootPage.user_code])
                                        }
                                    )
                                    listModel.clear()
                                    rootPage.load()
                                })
                    remorse.canceled.connect(function() { page.deletingItems = false })
                }
            }

            MenuItem {
                text: qsTr("Add new data")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddnewData.qml"))

           }


            MenuLabel {
                text: "Options"
            }
        }

        delegate: ListItem {
            id: list
            function remove() {
                remorseDelete(function() {
                    var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
                    db.transaction(
                        function(tx){
                            tx.executeSql('DELETE FROM MetricValue WHERE id_metric=?',[metric_tab[index]])
                        }
                    )
                    listModel.remove(index)
                    rootPage.load()
                })
            }
            function edit(value) {
                value = value.replace(',', '.');
                var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
                db.transaction(
                    function(tx){
                        tx.executeSql('UPDATE MetricValue SET VAL=? WHERE id_metric=?',[parseFloat(value),metric_tab[index]])
                    }
                )
                rootPage.load()
                listModel.load();
            }

            ListView.onRemove: animateRemoval()
            enabled: !page.deletingItems
            opacity: enabled ? 1.0 : 0.0
            Behavior on opacity { FadeAnimator {}}

            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: "Edit"
                        onClicked: pageStack.animatorPush(editData)
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
            Component {
                id: editData
                Dialog{
                    acceptDestination: page
                    acceptDestinationAction: PageStackAction.Pop
                    canAccept: metricField.acceptableInput
                    onAccepted: {
                        edit(metricField.text)
                    }
                    SilicaFlickable {
                        anchors.fill: parent
                        contentHeight: column.height

                        Column {
                            id: column
                            width: parent.width
                            spacing: Theme.paddingLarge

                            DialogHeader { title: 'Edit this data:' }

                            TextField {
                                id: metricField
                                width: parent.width
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                label: "Ltr/°C"
                                placeholderText: "Littre/Calories"
                                focus: true
                                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                                EnterKey.onClicked: phoneField.focus = true
                                validator: RegExpValidator { regExp: /^\d+([\.|,]\d{1,2})?$/ }
                            }

                            ComboBox{
                                id : selectData
                                label:  "Choice"
                                    menu: ContextMenu{
                                        MenuItem{ text: "Input Calorie" }
                                        MenuItem{ text: "Input Liquid Quantity" }
                                    }
                                width:parent.width/2
                            }
                        }
                    }
                }
            }

        }
    }

    ListModel {
        id: listModel

        property bool populated
        property string metric_code;
        property int user_code;

        Component.onCompleted:{
            rootPage=previousPage()
            user_code=rootPage.user_code
            load()
        }

        function load() {
            listModel.clear()
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){

                    var rs = tx.executeSql('SELECT * FROM MetricValue WHERE id_profile=? ORDER BY id_metric DESC',[user_code]);
                    var entries = rs.rows.length;
                    for(var i =0; i< rs.rows.length;i++){
                        metric_tab[i] = rs.rows.item(i).id_metric;
                        listModel.append({"text": rs.rows.item(i).date_metric + "                               " + rs.rows.item(i).VAL + " Ltr/°C"});
                    }
                }
            )
            page.deletingItems = false
            populated = true
        }
    }

}

