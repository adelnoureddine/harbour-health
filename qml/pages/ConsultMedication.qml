import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: consultIlness
    property string user_id
    property Page pageConsuleIllness
    property string illness_id
    property string id_medication
    property string name_medication
    property string medication_date
    property string duration

    allowedOrientations: Orientation.All
    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge
        contentWidth: parent.width

        VerticalScrollDecorator {}

        PullDownMenu {
            MenuItem {
                text: qsTr("Medication list")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("ConsultIllness.qml"))
            }
        }

        Column {
            id: column
            spacing: Theme.paddingLarge
            //anchors.fill: parent
            width: parent.width

            PageHeader {
                title: "Consult medication"
            }

            SectionHeader {
                text: "Information about this medication"
            }
            Rectangle {
                color: "black"
                height: Theme.itemSizeSmall
                width: page.width
                Label {
                    color: Theme.lightPrimaryColor
                    text: "the name : " +name_medication
                    anchors.centerIn: parent
                }
            }

            Rectangle {
                color: "black"
                height: Theme.itemSizeSmall
                width: page.width
                Label {
                    color: Theme.lightPrimaryColor
                    text: "Date :" +medication_date
                    anchors.centerIn: parent
                }
            }

            Rectangle {
                color: "black"
                height: Theme.itemSizeSmall
                width: page.width
                Label {
                    color: Theme.lightPrimaryColor
                    text: "Duration :" +duration
                    anchors.centerIn: parent
                }
            }
        }
    }

    Component.onCompleted: {
        pageConsuleIllness=previousPage()
        user_id = pageConsuleIllness.user_id
        illness_id = pageConsuleIllness.illness_id
        id_medication = pageConsuleIllness.id_medication


        function load(){
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){
                    var res1 =  tx.executeSql('SELECT medication_date,duration FROM HaveMedication WHERE illness_id=? AND id_profile =? AND id_medication=?',[illness_id,user_id,id_medication]);
                    medication_date = res1.rows.item(0).medication_date;
                    duration = res1.rows.item(0).duration;
                    var res2 = tx.executeSql('SELECT name FROM Medication WHERE id_medication=?',[id_medication]);
                    name_medication = res2.rows.item(0).name;
                }
                )
        }

    }
}


