import QtQuick 2.0

import Sailfish.Silica 1.0

import QtQuick.LocalStorage 2.0

import "../utils.js" as WtUtils


Dialog {

    //id: newMetric

    backNavigation: true

    allowedOrientations: Orientation.All

    id: page

     property string user_firstname;

     property string user_id;

     property string resultDayOfCycle;

     property string user_birthday;

     property string user_dateOfCurrentCycle

     property string selectFlow : "Spotting"

     property string selectFeeling : "Happy"

     property string selectPain : "Cramps"

     property string selectEnergy : "Invigorated"

     property string selectSleepTime : "0 - 3 hours"


    function setFirstname (){

        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);

        db.transaction(

            function(tx){

                var rs = tx.executeSql('SELECT * FROM Profiles WHERE id_profile=?',[user_id]) // MANQUE LE WHERE = ID PROFILE

                if(rs.rows.length > 0){

                   user_firstname = rs.rows.item(0).firstname;

                    print(user_firstname)

                }

            }

        )

    }


    function setBirthday (){

        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);

        db.transaction(

            function(tx){

                var rs = tx.executeSql('SELECT * FROM Profiles WHERE id_profile=?',[user_id]) // MANQUE LE WHERE = ID PROFILE

                if(rs.rows.length > 0){

                    user_birthday = rs.rows.item(0).birthday;

                }

            }

        )

    }


    function dateCurrentCycle (){

        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);

        db.transaction(

            function(tx){

                var rs = tx.executeSql('SELECT * FROM MenstrualCycles WHERE id_profile=?',[user_id])

                if(rs.rows.length > 0){

                    var rs2 = tx.executeSql('SELECT MAX(id_menstrual) AS id_MAXCycle FROM MenstrualCycles');

                    var i = (rs2.rows.item(0).id_MAXCycle) ;

                    i-=1;

                    user_dateOfCurrentCycle = rs.rows.item(i).menstrual_date ;

                    print("i : " + i)  ;

                    print("Date cycle actuel : " + user_dateOfCurrentCycle)  ;


                    }

                }

        )

    }



    function addFeelings (){

        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);

        db.transaction(

                    function(tx){
                        var i = 0 ;
                        var rs1 = tx.executeSql('SELECT id_menstrual FROM MenstrualCycles');
                        if(rs1.rows.length >0)

                        {

                           i = 1

                        }

                        else{
                            var rs2 = tx.executeSql('SELECT MAX(id_menstrual) AS id_MAXCycle FROM MenstrualCycles');
                            i = (rs2.rows.item(0).id_MAXCycle) + 1 ;

                        }
                        print("user_id : " + user_id) ;
                        print("flow : " + selectFlow) ;
                        print("feeling : " +selectFeeling) ;
                        print("Pain : " +selectPain) ;
                        print("Energy : " +selectEnergy) ;
                        print("Time : " +selectSleepTime) ;
                        print("menstrualdate : " + menstrualDate.value) ;
                        print("i : " + i) ;

                        tx.executeSql('INSERT INTO MenstrualFeelings VALUES (?,?,?,?,?,?,?)',[i,menstrualDate,selectFlow,selectFeeling,selectPain,selectEnergy,selectSleepTime]);
                    }

        )

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
                 text: 'Managing the Menstrual Cycle'
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

                     id: menstrualDate
                     label: "Date : "
                     value: Qt.formatDate(new Date())
                     width: parent.width
                     onClicked: openDateDialog()
                 }


                 ComboBox{
                          label:  "Flow : "
                          menu: ContextMenu{
                              MenuItem{ text: "Spotting"
                              onClicked: selectFlow = "Spotting"}
                              MenuItem{ text: "Light losses"
                              onClicked: selectFlow = "Light losses"}
                              MenuItem{ text: "Medium losses"
                              onClicked: selectFlow = "Medium losses"}
                              MenuItem{ text: "Heavy spotting"
                              onClicked: selectFlow = "Heavy spotting"}
                                         }
                                     width:parent.width
                         }


                    ComboBox{
                             label:  "Feeling : "
                             menu: ContextMenu{
                                     MenuItem{ text: "Happy"
                                     onClicked: selectFeeling = "Happy"}
                                     MenuItem{ text: "Sensitive"
                                     onClicked: selectFeeling = "Sensitive"}
                                     MenuItem{ text: "Sad"
                                     onClicked: selectFeeling = "Sad"}
                                     MenuItem{ text: "SPM"
                                     onClicked: selectFeeling = "SPM"}
                                           }

                                        width:parent.width

                            }


                    ComboBox{
                             label:  "Pain : "

                             menu: ContextMenu{

                                     MenuItem{ text: "Cramps"

                                     onClicked: selectPain = "Cramps"}

                                     MenuItem{ text: "Headaches"

                                     onClicked: selectPain = "Headaches"}

                                     MenuItem{ text: "Ovulation"

                                     onClicked: selectPain = "Ovulation"}

                                     MenuItem{ text: "Tender breasts"

                                     onClicked: selectPain = "Tender breasts"}

                                            }

                                        width:parent.width

                            }


                    ComboBox{

                             label:  "Energy : "

                             menu: ContextMenu{

                                 MenuItem{ text: "Invigorated"

                                 onClicked: selectEnergy = "Invigorated"}

                                 MenuItem{ text: "Full of energy"

                                 onClicked: selectEnergy = "Full of energy"}

                                 MenuItem{ text: "No energy"

                                 onClicked: selectEnergy = "No energy"}

                                 MenuItem{ text: "Exhausted"

                                 onClicked: selectEnergy = "Exhausted"}

                                            }

                                        width:parent.width

                            }


                    ComboBox{

                             label:  "Sleep time : "

                             menu: ContextMenu{

                                     MenuItem{ text: "0 - 3 hours"

                                     onClicked: selectSleepTime = "0 - 3 hours"}

                                     MenuItem{ text: "3 - 6 hours"

                                     onClicked: selectSleepTime = "3 - 6 hours"}

                                     MenuItem{ text: "6 - 9 hours"

                                     onClicked: selectSleepTime = "6 - 9 hours"}

                                     MenuItem{ text: "9 hours or more"

                                     onClicked: selectSleepTime = "9 hours or more"}

                                            }

                                        width:parent.width

                            }

        }


        Component.onCompleted:{

            user_id = WtUtils.getLastUser()

            print("id de l'user actif : " + user_id)

            setFirstname()

            setBirthday()

            dateCurrentCycle()

            addFeelings()

        }


    }

}


