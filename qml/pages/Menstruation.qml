import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "../utils.js" as WtUtils

Page {

    id: page
     property string user_firstname;
     property string user_id;
     property string resultDayOfCycle;
     property string user_birthday;
     property string user_dateOfCurrentCycle ;

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
                var rs = tx.executeSql('SELECT * FROM MenstrualCycles WHERE id_profile=?',user_id);
                if(rs.rows.length > 0){                    var rs2 = tx.executeSql('SELECT MAX(id_menstrual) AS id_MAXCycle FROM MenstrualCycles');
                    var i = (rs2.rows.item(0).id_MAXCycle);
                    i-=1;
                    user_dateOfCurrentCycle = rs.rows.item(i).menstrual_date ;
                    print("i : " + i)  ;
                    print("Date cycle actuel : " + user_dateOfCurrentCycle) ;

                    }

                }
        )

    }

        function dayOfCycle(){

            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){
                    var rs = tx.executeSql('SELECT * FROM MenstrualCycles WHERE id_profile=?',[user_id])
                    if(rs.rows.item(0).id_menstrual > 0){
                        var dateLastCycle = user_dateOfCurrentCycle
                        print("Last cycle date : " + dateLastCycle) ;

                        var dateJour = new Date()
                        dateJour = Qt.formatDate(dateJour, "yyyy-MM-dd");

                       // QDate:currentDate () ;
                       // print("date today : " + QDate) ;
                       //resultDayOfCycle = dateLastCycle.daysTo(dateJour);
                    //   resultDayOfCycle = dateJour - dateLastCycle ;
                        //resultDayOfCycle = dateJour. ;

                        print("resultat : " + resultDayOfCycle)

                    }

                }

            )

       }


    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All
    // To enable PullDownMenu, place our content in a SilicaFlickable

    SilicaFlickable {
        anchors.fill: parent
        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
                text: qsTr("Add today's informations")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./AddTodayInfo.qml'))
            }

            MenuItem {
                text: qsTr("Consult history of all cycles")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./HistoryOfAllCycle.qml'))
            }

            MenuItem {
                text: qsTr("Add new cycle")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./AddNewCycle.qml'))
            }

            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./AboutPage.qml'))
            }

/*
            MenuItem {
                text: qsTr("Create profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./createProfile.qml'))
            }


            MenuItem {
                text: qsTr("Delete profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./deleteProfile.qml'))
            }


            MenuItem {
                text: qsTr("Infos profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./infosProfile.qml'))
            }
            */
        }

        // Tell SilicaFlickable the height of its content.
        contentHeight: column.height

        // Place our content in a Column.  The PageHeader is always placed at the top
        // of the page, followed by our content.


        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge


            /* Titre de la page */
            PageHeader {
                title: 'Managing the Menstrual Cycle' }

            Row {

                id : row1
                    Label {
                         id : txtHello
                         text: 'Hello    '
                        /* color: "red"  */
                    }

                    Label {
                         id : nameUser
                         text: user_firstname
                    }

            }  /* Fin Row 1*/

            Row {
                id : row2
                Label {
                     id : textday
                     text: "It's day "
                }


                Label {
                     id : numberOfDay
                     text: "555"
                }

                Label {
                     id : textMenstrual
                     text: ' of your menstrual cycle.'
                }

             }  /* Fin row 2 */


            Row {
                id : row3
                Label {
                     id : textAnalysis
                     text: '----------------------- ANALYSIS -----------------------'
                }
                } /* Fin row 3 */


            Row {
                id : row4
                Label {
                     id : textDureeCycle
                     text: ' • Your last menstrual cycle was : '
                }

                Label {
                     id : dureeCycle
                     text: '5555'
                }

                Label {
                     id : day
                     text: ' days.'
                }

            } /* Fin row4 */

            Row {
                id : row5

                Label {
                     id : textDureeRegle
                     text: ' • Your period lasted : '
                }


                Label {
                     id : dureeRegle
                     text: '5555'
                }


                Label {
                     id : txtday
                     text: ' days.'
                }


             } /* Fin row5 */
            Label {
                 id : txtligneEtoile
                 text: ' ******************************************** '
            }

            Row {
                id : row6
                Label {
                     id : textResume
                     text: 'Summary of : '
                }

                Label {
                     id : txtDateDay
                     text: user_dateOfCurrentCycle
                }

            }  /* Fin row 6 */


            Row {

                id : row7


                Label {

                     id : textFlow

                     text: 'Flow : '

                }

                Label {

                     id : textFlowApp

                     text: ' ------ '

                }

            }  /* Fin row 7 */


            Row {

                id : row8


                Label {

                     id : textPain

                     text: 'Pain : '

                }

                Label {

                     id : textPainApp

                     text: ' ------ '

                }

            }  /* Fin row 8 */


            Row {

                id : row9


                Label {

                     id : textEnergy

                     text: 'Energy : '

                }

                Label {

                     id : textAppEnergy

                     text: ' ------ '

                }

            }  /* Fin row 9 */


            Row {

                id : row10


                Label {

                     id : textSleepTime

                     text: 'Sleep time : '

                }

                Label {

                     id : textAppSleepTime

                     text: ' ------ '

                }

            }  /* Fin row 10 */


            Row {

                id : row11


                Label {

                     id : textCycleTime

                     text: 'Cycle time : '

                }

                Label {

                     id : textAppCycleTime

                     text: ' ------ '

                }

            }  /* Fin row 11 */


            Row {

                id : row12


                Label {

                     id : textPeriodDuration

                     text: 'Period Duration : '

                }

                Label {

                     id : textAppPeriodDuration

                     text: ' ------ '

                }

            }  /* Fin row 12 */



        }  /* Fin column */


        Component.onCompleted:{
            user_id = WtUtils.getLastUser()
            print("id de l'user actif : " + user_id)
            setFirstname()
            setBirthday()
            dateCurrentCycle()
            dayOfCycle()
        }

    }
}


