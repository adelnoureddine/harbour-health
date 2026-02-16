import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
   // allowedOrientations: Orientation.All



    // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
    PullDownMenu {
        MenuItem {
            text: qsTr("Consult History")
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("ConsultHistory.qml"))
        }

        MenuLabel { text: "Menu" }
    }

    property string metric_code;
    property string user_code;




    function addnewData(value){
        value = value.replace(',', '.');
        //load user_code from homepage, if(depth==3)adding from history else from homepage
        if(depth==3) user_code=previousPage().rootPage.user_code;
        else user_code=previousPage().user_code;
        var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT MAX(id_metric) AS MetricValue FROM MetricValue  ');
                if(rs.rows.item(0).METRIC===null) metric_code="1"
                else{
                    metric_code = rs.rows.item(0).MetricValue;
                    metric_code = parseInt(metric_code) +1;
                }
                var date = new Date();
                date = Qt.formatDate(date, "yyyy-MM-dd");
                rs = tx.executeSql('INSERT INTO MetricValue VALUES (?,?,?,?,?)',[user_code,metric_code,date,"Calorie",value]);
                rs = tx.executeSql('SELECT * FROM MetricValue WHERE id_profile=?',[user_code]);
            }
        )

        //reload homepage if adding from homepage or history if adding metric from history page
        previousPage().load();
        //reload homepage if add from history page
        if(depth==3) previousPage().rootPage.load();
        navigateBack(PageStackAction.Animated);



    }

    SilicaListView
       {
            anchors.fill: parent
            contentHeight: column.height

            Column {
                id: column
                width: parent.width
                spacing: Theme.paddingLarge

                DialogHeader {
                    acceptText: "save"
                    anchors.horizontalCenter: parent.horizontalCenter
                    enabled: nutritionTF.acceptableInput
                    onClicked: addnewData(nutritionTF.text)

                    title: 'Add new Data' }

                TextField {
                    id: nutritionTF
                    width: parent.width
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    label: "Ltr/°C"
                    placeholderText: "Nutrition Data"
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: phoneField.focus = true
                    validator: RegExpValidator { regExp: /^\d+([\.|,]\d{1,2})?$/ }
                    focus: true
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



