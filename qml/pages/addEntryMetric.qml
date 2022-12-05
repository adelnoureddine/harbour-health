import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Dialog {
    id: addEntry
    property Page rootPage: previousPage()
    property int userId: rootPage.userId
    property int metricId: rootPage.metricId
    property bool isUpdate: true
    canAccept: dateButton.value != "" && metricValue.text != ""

    onAcceptPendingChanged: {
        if (acceptPending) {
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){
                    if(isUpdate === true){
                        console.log('INSERT INTO MetricValue VALUES(?,?,?,?,?)', [null, userId, metricId, dateButton.value, parseInt(metricValue.text)])
                        var rs = tx.executeSql('INSERT INTO MetricValue VALUES(?,?,?,?,?)', [null, userId, metricId, dateButton.value, parseInt(metricValue.text)]);
                    }else{
                        //tx.executeSql('INSERT INTO MetricValue VALUES(?,?,?,?,?)', [null, vaccineName.text, 0,parseInt(boostersNumber.text)]);
                    }
                    //Reload the page before comming back, to see updates
                    rootPage.load()
                }
            )
        }
    }


    SilicaFlickable{
        anchors.fill: parent
        contentHeight: column.height

        Column{
            id: column
            width: parent.width



            DialogHeader {
                acceptText: "Save"
                title: "Add Entry"

            }

            TextField{
                id : metricValue
                width:parent.width
                placeholderText: "Value"

            }

            ValueButton {
                id: dateButton
                property date selectedDate

                function openDateDialog() {
                    var obj = pageStack.animatorPush("Sailfish.Silica.DatePickerDialog",
                                                     { date: selectedDate })

                    obj.pageCompleted.connect(function(page) {
                        page.accepted.connect(function() {
                            selectedDate = page.date
                            value = selectedDate.toLocaleDateString(Locale.ShortFormat)
                        })
                    })
                }
                label: "Choose a date"
                width: parent.width
                onClicked: openDateDialog()
            }


        }
    }
}
