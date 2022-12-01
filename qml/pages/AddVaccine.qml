import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Dialog {
    id: addvaccine
    property Page rootPage: previousPage()
    property bool isUpdate: rootPage.isUpdate
    property int userId: rootPage.userId
    property int vaccineId: rootPage.vaccineId
    canAccept: vaccineName.text!="" && boostersNumber.text!="" && nextRecallButton.value!="" && firstTakeButton.value!=""

    onAcceptPendingChanged: {
        if (acceptPending) {
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){
                    if(isUpdate == true){
                        var rs = tx.executeSql('INSERT INTO Vaccines VALUES(?,?,?,?)', [null, vaccineName.text, parseInt(boostersNumber.text), 0]);
                    }else{
                        tx.executeSql('INSERT INTO Vaccines VALUES(?,?,?,?)', [null, vaccineName.text, 0,parseInt(boostersNumber.text)]);
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
                title: "Update Recall"

            }

            TextField{
                id : vaccineName
                width:parent.width
                placeholderText: "Name"
            }
            TextField{
                id : boostersNumber
                width:parent.width
                placeholderText: "Number of boosters"
            }

            /*
            Row{

                Icon{
                    source: "image://theme/icon-m-date"
                }
*/


                ValueButton {
                    id: firstTakeButton
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
                    label: "Date of first take"
                    width: parent.width
                    onClicked: openDateDialog()
                }
            //}

            /*
            Row{

                Icon{
                    source: "image://theme/icon-m-date"
                }
                */

                ValueButton {
                    id: nextRecallButton
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
                    label: "Date of next recall"
                    width: parent.width
                    onClicked: openDateDialog()
                }
            //}

        }
    }
}
