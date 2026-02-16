import QtQuick 2.0

import Sailfish.Silica 1.0

import QtQuick.LocalStorage 2.0

import "../utils.js" as WtUtils


Dialog {

    backNavigation: true
    allowedOrientations: Orientation.All
    id: newMenstrual

    property string user_id ;

    onAcceptPendingChanged: {

        if (acceptPending) {

            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);

            db.transaction(

                function(tx){

                    var code = 0 ;

                    var rs1 = tx.executeSql('SELECT id_menstrual FROM MenstrualCycles');

                    if(rs1.rows.length <= 0)

                    {

                       code = 1

                    }

                    else{

                        var rs2 = tx.executeSql('SELECT MAX(id_menstrual) AS id_MAXCycle FROM MenstrualCycles');

                        code = (rs2.rows.item(0).id_MAXCycle) + 1 ;

                    }

                    tx.executeSql('INSERT INTO MenstrualCycles VALUES (?,?,?)',[user_id,code,dateMenstrual.value]);


                    print("user_id : " + user_id) ;

                    print("code : " + code) ;

                    print("menstrualdate : " + dateMenstrual.value) ;

                  // tx.executeSql('TRUNCATE TABLE MenstrualCycles') ;

                  // tx.executeSql('ALTER TABLE MenstrualCycles AUTO_INCREMENT=0') ;


                }

            )

        }

    }




    SilicaFlickable {

        anchors.fill: parent
        contentHeight: column.height
        VerticalScrollDecorator {}   /* ----------- */
        Column {

            id: column
            width: parent.width
            spacing: Theme.paddingLarge


/* ***************************************************************** */

            /* Titre de la page */

            PageHeader {

                title: 'Managing the Menstrual Cycle' }


            Dialog {

                DialogHeader {

                    acceptText: "Save"

                    title: 'Add todays informations'

                }

            }


            Label {

                 text: 'Add new menstrual cycle'

            }

/* ***************************************************************** */


            /* Sélection de la date */


                 ValueButton {

                     property date selectedDate
                     function openDateDialog() {
                         var obj = pageStack.animatorPush("Sailfish.Silica.DatePickerDialog",
                                                          { date: selectedDate })

                         obj.pageCompleted.connect(function(page) {
                             page.accepted.connect(function() {

                                 value = page.dateText

                                 selectedDate = page.date

                             })

                         })

                     }


                     label: "Date : "

                     id: dateMenstrual

                     value: Qt.formatDate(new Date())

                     width: parent.width

                     onClicked: openDateDialog()

                 }


        }


        Component.onCompleted: {

            user_id = WtUtils.getLastUser()


        }


    }


}
