import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Dialog {
    id: updateRecall
    property Page rootPage: previousPage()
    property bool isUpdate: rootPage.isUpdate
    property int userId: rootPage.userId
    property int vaccineId: rootPage.vaccineId
    property int injectionId: rootPage.injectionId
    canAccept: recallButton.value != ""

    onAcceptPendingChanged: {
        if (acceptPending) {
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){
                    if(isUpdate == true){
                        var rs = tx.executeSql('INSERT INTO Injection VALUES(?,?,?,?)', [null, userId, vaccineId, recallButton.value ]);
                    }else{
                        tx.executeSql("UPDATE Injection SET injection_date = ? WHERE id_injection = ?", [ recallButton.value,injectionId]);
                    }
                    //Reload the page before comming back, to see updates
                    rootPage.loadModel()

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

            Label{
                x: Theme.horizontalPageMargin
                text: "Next Recall: "
            }
            Row{
                Icon{
                    source: "image://theme/icon-m-date"
                }


                ValueButton {
                    id: recallButton
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
}
