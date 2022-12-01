import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
Page {
    property Page mainConsulteIllness
    property bool edditMedication
    property string user_id
    property string illness_id
    property string medication_id
    property string name_medication
    property string medication_date
    property string duration



    id:addAndEditMedication
    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All


    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column1.height
        PullDownMenu {
             MenuItem {
                 text: qsTr("Medication list")
                 onClicked: pageStack.animatorPush(Qt.resolvedUrl("ConsultIllness.qml"))
             }
        }

        Column{
            id : column1
            width: parent.width

            PageHeader { title: if(!edditMedication) { "Add medication" }else{"Edit medication"}
            }

            Rectangle {
                color: "black"
                height: Theme.itemSizeSmall
                width: page.width
                ValueButton {
                    label: "Start"
                    onClicked:{
                        if(!edditMedication){ pageStack.animatorPush(dialog1)} else{pageStack.animatorPush(dialog2)}
                    }

                }
            }

            Component{
                id:dialog1
                Dialog {
                    id: addMedication
                    acceptDestination: addAndEditMedication
                    acceptDestinationAction: PageStackAction.Pop
                    //Sets whether the user can accept the dialog or not
                    canAccept: nameMedication.acceptableInput
                    //This signal handler is called when dialog accept is attempted while canAccept is false
                    onAcceptBlocked: {
                        if (!nameMedication.acceptableInput) {
                            nameMedication.errorHighlight = true
                        }
                    }

                    // To enable PullDownMenu, place our content in a SilicaFlickable
                    Flickable {
                        anchors.fill: parent
                        contentHeight: column2.height + Theme.paddingLarge
                        VerticalScrollDecorator {}
                        Column {
                                    id: column2
                                    width: parent.width

                                    DialogHeader {
                                        acceptText: "Accept"
                                    }

                                    PageHeader { title: "Add medication"}
                                    SectionHeader {
                                        text: "Information about a medication"
                                    }
                                    Label{
                                        text: "medication name: "
                                    }
                                    TextField {
                                        id:nameMedication
                                        onActiveFocusChanged: if (!activeFocus) errorHighlight = !acceptableInput
                                        onAcceptableInputChanged: if (acceptableInput) errorHighlight = false

                                        label: "The name"
                                        description: errorHighlight ? "word is too short" : ""
                                        acceptableInput: text.length >= 1
                                        focus: true
                                    }

                                    Label{
                                        text: "Medication date: "
                                    }

                                    ValueButton {
                                        id:medicationDate
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
                                        label: "On"
                                        value: Qt.formatDate(new Date())
                                        onClicked: openDateDialog()

                                    }
                                    Label{
                                        text: "Duration: "
                                    }
                                    TextField {
                                        id:txtDuration
                                    }
                        }
                    }
                    onAccepted:{
                            addMedication(nameMedication.text,medicationDate.value,txtDuration.text)
                    }

                }


            }
            Component{
                 id:dialog2
                 Dialog {
                     id: edditMedication
                     acceptDestination: addAndEditMedication
                     acceptDestinationAction: PageStackAction.Pop
                     //Sets whether the user can accept the dialog or not
                     canAccept: nameMedication.acceptableInput
                     //This signal handler is called when dialog accept is attempted while canAccept is false
                     onAcceptBlocked: {
                         if (!nameMedication.acceptableInput) {
                             nameMedication.errorHighlight = true
                         }
                     }

                     // To enable PullDownMenu, place our content in a SilicaFlickable
                     Flickable {
                         anchors.fill: parent
                         contentHeight: column2.height + Theme.paddingLarge
                         VerticalScrollDecorator {}
                        Column {
                                     id: column2
                                     width: parent.width

                                     DialogHeader {
                                         acceptText: "Accept"
                                     }

                                     PageHeader { title: "Edit medication"
                                     SectionHeader {
                                         text: "Information about a medication"
                                     }
                                     Label{
                                         text: "Medication name: "
                                     }
                                     TextField {
                                         id:nameMedication
                                         onActiveFocusChanged: if (!activeFocus) errorHighlight = !acceptableInput
                                         onAcceptableInputChanged: if (acceptableInput) errorHighlight = false

                                         label: "The name"
                                         text: name_medication
                                         description: errorHighlight ? "word is too short" : ""
                                         acceptableInput: text.length >= 1
                                         focus: true
                                     }

                                     Label{
                                         text: "Medication date: "
                                     }

                                     ValueButton {
                                         id:medicationDate
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
                                         label: "On"
                                         value: medication_date
                                         onClicked: openDateDialog()

                                     }
                                     Label{
                                         text: "Duration: "
                                     }
                                     TextArea {
                                         id:txtDuration
                                         text: duration
                                     }
                                 }
                        }
                     }
                     onAccepted: {
                         edditMedication(nameIllness.text,startDate.value,endDate.value,txtcomments.text)
                     }
                 }
            }
            Component.onCompleted:{
                    mainConsulteIllness=previousPage()
                    edditMedication=mainConsulteIllness.edditMedication
                    user_id =mainConsulteIllness.user_id
                    illness_id =mainConsulteIllness.illness_id
                    medication_id = mainConsulteIllness.medication_id
                    load()
             }

        }
    }

    function load(){
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){
                    var rs2 = tx.executeSql("SELECT medication_date,duration FROM HaveMedication WHERE id_profile=? AND id_illness=? AND id_medication=?",[user_id,illness_id,medication_id]);
                    var rs1 = tx.executeSql("SELECT name FROM Medication WHERE id_medication=?",medication_id);
                    if(rs1.rows.length > 1){
                        name_medication = rs1.rows.item(0).name;
                    }
                    if(rs2.rows.length > 1){
                        medication_date = rs2.rows.item(0).medication_date;
                        duration = rs2.rows.item(0).duration;
                    }
                }
                )
      }
    function edditMedication(val1,val2,val3){
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){
                    var rs1 = tx.executeSql("UPDATE Medication SET name=? WHERE id_medication=?",[val1,medication_id]);
                    var res2 = tx.executeSql("UPDATE HaveMedication SET medication_date=?, duration=? WHERE id_profile=? AND id_illness=? AND id_medication=?",[val2,val3,user_id,illness_id,medication_id]);
                }
                )
      }
    function addMedication(val1,val2,val3){
            var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
            db.transaction(
                function(tx){
                    var rs1 = tx.executeSql("INSERT INTO Medication(name) VALUES(?)",val1);
                    rs1 = tx.executeSql("SELECT id_medication AS LastInsert FROM Medication ORDER BY LastInsert DESC LIMIT 0,1");
                    var lasteInsetMedication = rs1.rows.item(0).LastInsert;
                    rs1 = tx.executeSql("INSERT INTO HaveMedication VALUES(?,?,?,?,?)",[user_id,illness_id,lasteInsetMedication,val2,val3]);

                }
                )
        }
}




