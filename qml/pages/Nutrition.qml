import QtQuick 2.0
import Sailfish.Silica 1.0

import "../js/fichierUtils.js" as WtUtils

Page {
    id: root

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.Al

    property variant usercodes: []
    property int currentProfileIndex
    property string user_description;
    property string user_calories;
    property string user_litres;
    property string user_code;
    property double recommended_min_Littre: 0.0;
    property double recommended_max_Littre: 0.0;
    property string recommended_Littre_description;
    property double recommended_min_calories: 0.0;
    property double recommended_max_calories: 0.0;
    property string recommended_calorie_description;
    property variant wtData;
    property double amount: 0.0;
    property double quantity: 0.0;
    property string u_cal;
    property string u_liquid;
    property string category_liquid;
    property string category_liquid_icon;
    property string category_liquid_description;
    property string category_cal;
    property string category_cal_icon;
    property string category_cal_description;
    property string slider_color;
    property bool profiles;






    // function to get profile
    function getProfiles(){
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        db.transaction(
            function(tx){
                var rs = tx.executeSql('SELECT * FROM Profiles');
                if(rs.rows.length > 0){
                    profiles = true;
                }
                else profiles=false;
        })
    }


    function load() {
        wtData = WtUtils.info_user(user_code);
        user_description = "Welcome " + wtData.firstname + " " + wtData.lastname + "!"
        getProfiles();
        calculateCal();
        calculateLit();

    }

    function loadUser(val) {
        user_code=val;
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        db.transaction(
            function(tx){
                tx.executeSql('UPDATE SETTINGS USER_CODE=?',[user_code]);
            })
    }

    function calculateCal() {
        var user_calories = wtData.Calories
        if (wtData.Calories > 0) {
            cal = wtData.Calories;
            recommended_min_calories = 2.000
            recommended_max_calories = 2.500
            recommended_calorie_description = "The recommended Calories for you is between " + recommended_min_calories.toFixed(2) + " °C and " + recommended_max_calories.toFixed(2) + " °C "
            calculate_Calorie_category();
        }
    }


    function calculateLit() {
        var user_litres = wtData.Littre
        if (wtData.Calories > 0) {
            cal = wtData.Littre;
            recommended_min_Littre = 2.7
            recommended_max_Littre = 3.7
            recommended_Littre_description = "The recommended Calories for you is between " + recommended_min_Littre.toFixed(2) + " °Ltr and " + recommended_max_Littre.toFixed(2) + " °Ltr "
            calculate_Littre_category();
        }
    }


    function calculate_litre_category() {
        if (quantity < 1.5) {
            category_liquid = "Not Hydrated";
            slider_color = "#2eb3db";
            category_liquid_icon = "image://theme/icon-l-weather-n211-light"
            category_liquid_description = "Your liquid intake is under the recommended values. Take more liquid."
        }

        else if (quantity < 3) {
            category_liquid = "hydration is Normal";
            slider_color = "#14f52a";
            category_liquid_icon = "image://theme/icon-l-weather-d000-light"
            category_liquid_description = "Your liquid intake is in the normal category for adults."
        }

        else if (quantity < 4) {
            category_liquid = "Over liquid consumtion";
            slider_color = "yellow";
            category_liquid_icon = "image://theme/icon-l-weather-d210-light"
            category_liquid_description = "Your liquid intake is above the recommended values. Take in less and do some sports."
        }  else {
            category_liquid = "Unkown category";
            slider_color = "white";
            category_liquid_icon = "image://theme/icon-l-clear"
            category_liquid_description = " No data"
        }
    }



    function calculate_calorie_category() {

        if (amount < 1.500) {
            category_cal = "Not Enough ";
            slider_color = "#2eb3db";
            category_cal_icon = "image://theme/icon-l-weather-n211-light"
            category_cal_description = "Your calorie intake is under the recommended values."
        }

        else if (amount < 2.300) {
            category_cal = "recomended Calories";
            slider_color = "#14f52a";
            category_cal_icon = "image://theme/icon-l-weather-d000-light"
            category_cal_description = "Your liquid intake is in the normal category for adults."
        }

        else if (amount < 3.000) {
            category_cal = "OverConsumtion of Calories";
            slider_color = "yellow";
            category_cal_icon = "image://theme/icon-l-weather-d210-light"
            category_cal_description = "Your calories intake is above the recommended values. Take in less and do some sports."
        }  else {
            category_cal = "Unkown category";
            slider_color = "white";
            category_cal_icon = "image://theme/icon-l-clear"
            category_cal_description = " No data"
        }
    }


    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {

            MenuItem {
                visible: user_code!=''
                text: "About"
                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./About.qml'))
            }


            MenuItem {
                visible: user_code!=''
                text: qsTr("Add new Data")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./AddnewData.qml'))
            }
            MenuItem {
                visible: user_code!=''
                text: "Consult History"
                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./ConsultHistory.qml'))
            }


            MenuItem {
                visible: user_code!=''
                text: "Welcome Page"
                onClicked: pageStack.animatorPush(Qt.resolvedUrl('./MainPage.qml'))
            }

            MenuLabel { text: "Menu" }

        }



        // Tell SilicaFlickable the height of its content.
        contentHeight: column.height

        // Place our content in a Column.  The PageHeader is always placed at the top
        // of the page, followed by our content.
        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("Graphical Report Consomation")
            }

            ViewPlaceholder {
                enabled: user_code=='' && profiles==false
                text: "No profile created"
                hintText: "Go to home to the principale page to create one  !"
            }

            ViewPlaceholder {
                enabled: user_code=='' && profiles==true
                text: "No profile selected"
                hintText: "Go to home to the principale page select one !"
            }




            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("Welcome to Nutrition Page")
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeExtraLarge
            }



           //Welcome user
            Label {
                visible: user_code!=''
                x: Theme.horizontalPageMargin
                width: parent.width
                text: user_description
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeLarge
            }

            ViewPlaceholder {
                enabled: wtData.Littre==0 && user_code!=''
                text: "No data available"
                hintText: "Pull down to add a new Liquid data"
            }

            // Liquid
            Label {
                visible: user_code!=''
                wrapMode: Text.Wrap
                width: parent.width
                text: u_liquid
                color: 'white'
            }


                 ViewPlaceholder {
                enabled: wtData.Calories==0 && user_code!=''
                text: "No data available"
                hintText: "Pull down to add a new Calorie data"
            }

            // Calories
            Label {
                visible: wtData.Calories!==0
                wrapMode: Text.Wrap
                width: parent.width
                text: u_cal
                color: 'white'
            }



            // for calories slider view

            Slider {
                visible: wtData.Calories!==0
                id: changingSlider
                value: amount
                minimumValue: 0
                maximumValue: 50
                stepSize: 10
                width: parent.width
                handleVisible: false
                enabled: handleVisible
                valueText : amount.toFixed(2)
                label: category_cal
                valueLabelColor: slider_color
                backgroundColor: slider_color
                color: slider_color
           }

           Icon {
                source: category_cal_icon
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
            }




           //for liquid slider


           Slider {
               visible: wtData.Littre!==0
               id: changingSliderliquid
               value: quantity
               minimumValue: 0
               maximumValue: 50
               stepSize: 10
               width: parent.width
               handleVisible: false
               enabled: handleVisible
               valueText : quantity.toFixed(2)
               label: category_liquid
               valueLabelColor: slider_color
               backgroundColor: slider_color
               color: slider_color
          }

          Icon {
               source: category_liquid_icon
               anchors {
                   horizontalCenter: parent.horizontalCenter
               }
           }





            // Description
            Label {
                visible: wtData.Calories!==0
                text: "Description"
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeLarge
                anchors.left: parent.left
                anchors.leftMargin: 30
            }

            Label {
                visible: wtData.Littre!==0
                //text: "Description"
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeLarge
                anchors.left: parent.left
                anchors.leftMargin: 30
            }



            // Recommended liquid intake
            Label {
                visible: wtData.Littre!==0
                wrapMode: Text.Wrap
                width: parent.width
                text: recommended_Littre_description
                color: 'white'
            }

            //recomended Calories intake
            Label {
                visible: wtData.Calories!==0
                wrapMode: Text.Wrap
                width: parent.width
                text: recommended_calorie_description
                color: 'white'
            }


            // Liquid category description
            Label {
                visible: wtData.weight!==0
                wrapMode: Text.Wrap
                width: parent.width
                text: category_liquid_description
                color: 'white'
            }


            // Calories category description
            Label {
                visible: wtData.weight!==0
                wrapMode: Text.Wrap
                width: parent.width
                text: category_cal_description
                color: 'white'
            }


        }

        Component.onCompleted:{
                       load()
        }
    }
}
