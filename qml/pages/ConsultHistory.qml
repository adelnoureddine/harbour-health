
import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: root

    property bool deletingItems

    SilicaGridView {
        id: gridView

        model: listModel
        anchors.fill: parent
        readonly property int columnCount: Math.floor(width/(Screen.width/2))
        cellWidth: parent.width/columnCount
        cellHeight: cellWidth

        header: PageHeader {
            title: "History Consultation"
        }

        ViewPlaceholder {
            enabled: (listModel.populated && listModel.count === 0) || root.deletingItems
            text: "No content"
            hintText: "Pull down to add infromationt"
        }

        PullDownMenu {
            id: pullDownMenu

            /// funtion to delate all the data on the page
            MenuItem {
                text: "Clear all History Data"
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
            MenuItem {
                text: "Add Items"
                visible: !gridView.count
                onClicked: listModel.addItems()
            }
            MenuItem {
                text: "Toggle busy menu"
                onClicked: pullDownMenu.busy = !pullDownMenu.busy
            }
            MenuItem {
                text: qsTr("Add new Information")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddnewData.qml"))


            }
        }

        delegate: GridItem {
            function remove() {
                remorseDelete(function() { listModel.remove(index) })
            }

            onClicked: {
                //when cliked once is to view daily data
                if (!menuOpen && pageStack.depth == 1) {
                    pageStack.animatorPush(Qt.resolvedUrl("Consul-jour.qml"))
                }
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
                        text: qsTr("Edit Information")
                        onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddnewData.qml"))
                    }
                    MenuItem {
                        text: qsTr("Daily Consultation")
                        onClicked: pageStack.animatorPush(Qt.resolvedUrl("Consul-Jour.qml"))


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
                    text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
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
            var entries = 40
            var spaceIpsumWords = ["Since", "long", "run", "every", "planetary", "civilization", "endangered", "impacts", "space", "every", "surviving",
                                   "civilization", "obliged", "become", "spacefaring", "because", "exploratory", "romantic", "zeal", "most", "practical",
                                   "reason", "imaginable", "staying", "alive", "long-term", "survival", "stake", "have", "basic", "responsibility", "species",
                                   "venture", "other", "worlds", "one", "small", "step", "man", "one", "giant", "leap", "mankind", "powered", "flight",
                                   "total", "about", "eight", "half", "minutes", "seemed", "gone", "lash", "gone", "from", "sitting", "still", "launch",
                                   "pad", "Kennedy", "Space", "Center", "traveling", "17500", "miles", "hour", "eight", "half", "minutes", "still",
                                   "recall", "making", "some", "statement", "air", "ground", "radio", "benefit", "fellow", "astronauts", "who", "also",
                                   "program", "long", "time", "well", "worth", "took", "been", "wait", "mind-boggling"]

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
}


/***




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
            title: qsTr("All weight data")
        }

        ViewPlaceholder {
            enabled: (listModel.populated && listModel.count === 0) || page.deletingItems
            text: "Empty history"
            hintText: "Pull down to add metrics"
        }

        PullDownMenu {
            id: pullDownMenu

            MenuItem {
                text: "Clear all data"
                visible: listView.count
                onClicked: {
                    page.deletingItems = true
                    var remorse = Remorse.popupAction(
                                page, "Cleared",
                                function() {
                                    var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
                                    db.transaction(
                                        function(tx){
                                            tx.executeSql('DELETE FROM METRICS WHERE USER_CODE=?',[rootPage.user_code])
                                        }
                                    )
                                    listModel.clear()
                                    rootPage.load()
                                })
                    remorse.canceled.connect(function() { page.deletingItems = false })
                }
            }
            MenuItem {
                text: "Add weight data"
                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./AddMetric.qml'))
            }
            MenuLabel {
                text: "Options"
            }
        }

        delegate: ListItem {
            id: list
            function remove() {
                remorseDelete(function() {
                    var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
                    db.transaction(
                        function(tx){
                            tx.executeSql('DELETE FROM METRICS WHERE METRIC_CODE=?',[metric_tab[index]])
                        }
                    )
                    listModel.remove(index)
                    rootPage.load()
                })
            }
            function edit(value) {
                value = value.replace(',', '.');
                var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
                db.transaction(
                    function(tx){
                        tx.executeSql('UPDATE METRICS SET VAL=? WHERE METRIC_CODE=?',[parseFloat(value),metric_tab[index]])
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
                        onClicked: pageStack.animatorPush(editMetric)
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
                id: editMetric
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

                            DialogHeader { title: 'Edit this weight data:' }

                            TextField {
                                id: metricField
                                width: parent.width
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                label: "kg"
                                placeholderText: "Weight"
                                focus: true
                                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                                EnterKey.onClicked: phoneField.focus = true
                                validator: RegExpValidator { regExp: /^\d+([\.|,]\d{1,2})?$/ }
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
            var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
            db.transaction(
                function(tx){

                    var rs = tx.executeSql('SELECT * FROM METRICS WHERE USER_CODE=? ORDER BY METRIC_CODE DESC',[user_code]);
                    var entries = rs.rows.length;
                    for(var i =0; i< rs.rows.length;i++){
                        metric_tab[i] = rs.rows.item(i).METRIC_CODE;
                        listModel.append({"text": rs.rows.item(i).METRIC_DATE + "                               " + rs.rows.item(i).VAL + " kg"});
                    }
                }
            )
            page.deletingItems = false
            populated = true
        }
    }

}
















  ****/






