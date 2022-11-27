import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
Page {
    property Page mainHealthCondition
    property bool editIllness
    property string user_id
    property string illness_id
    property string name_illnes
    property string start_date
    property string end_date
    property string comments



    id:addAndEditIllness
    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All


    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column1.height
        PullDownMenu {
             MenuItem {
                 text: qsTr("Illness list")
                 onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainHealthCondition.qml"))
             }
        }

        Column{
            id : column1
            width: parent.width

            PageHeader { title: if(!editIllness) { "Add illness" }else{"Edit illness"}
            }

            Rectangle {
                color: "black"
                height: Theme.itemSizeSmall
                width: page.width
                ValueButton {
                    label: "Start"
                    onClicked:{
                        if(!editIllness){ pageStack.animatorPush(dialog1)} else{pageStack.animatorPush(dialog2)}
                    }

                }
            }

            Component{
                id:dialog1
                Dialog {
                    id: addIllness
                    acceptDestination: addAndEditIllness
                    acceptDestinationAction: PageStackAction.Pop
                    //Sets whether the user can accept the dialog or not
                    canAccept: nameIllness.acceptableInput
                    //This signal handler is called when dialog accept is attempted while canAccept is false
                    onAcceptBlocked: {
                        if (!nameIllness.acceptableInput) {
                            nameIllness.errorHighlight = true
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

                                    PageHeader { title:"Add illness"}
                                    SectionHeader {
                                        text: "Information about an illness"
                                    }
                                    Label{
                                        text: "Illness name: "
                                    }
                                    TextField {
                                        id:nameIllness
                                        onActiveFocusChanged: if (!activeFocus) errorHighlight = !acceptableInput
                                        onAcceptableInputChanged: if (acceptableInput) errorHighlight = false

                                        label: "The name"
                                        description: errorHighlight ? "word is too short" : ""
                                        acceptableInput: text.length >= 1
                                        focus: true
                                    }

                                    Label{
                                        text: "Start date: "
                                    }

                                    ValueButton {
                                        id:startDate
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
                                        text: "End date: "
                                    }

                                    ValueButton {
                                        id:endDate
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
                                        label: "To"
                                        value: Qt.formatDate(new Date())
                                        onClicked: openDateDialog()

                                    }

                                    Label{
                                        text: "Comments: "
                                    }
                                    TextArea {
                                        id:txtcomments
                                        label: "Multi-line-Comment"
                                    }
                        }
                    }
                    onAccepted: {
                         addIllnes(nameIllness.text,startDate.value,endDate.value,txtcomments.text)
                    }
                }
            }
            Component{
                id:dialog2
                Dialog {
                    id: edditIllness
                    acceptDestination: addAndEditIllness
                    acceptDestinationAction: PageStackAction.Pop
                    //Sets whether the user can accept the dialog or not
                    canAccept: nameIllness.acceptableInput
                    //This signal handler is called when dialog accept is attempted while canAccept is false
                    onAcceptBlocked: {
                           if (!nameIllness.acceptableInput) {
                                nameIllness.errorHighlight = true
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

                            PageHeader { title: "Edit illness"}
                            SectionHeader {
                                 text: "Information about an illness"
                             }
                            Label{
                                 text: "Illness name: "
                             }
                            TextField {
                                id:nameIllness
                                onActiveFocusChanged: if (!activeFocus) errorHighlight = !acceptableInput
                                onAcceptableInputChanged: if (acceptableInput) errorHighlight = false

                                label: "The name"
                                text: name_illnes
                                description: errorHighlight ? "word is too short" : ""
                                acceptableInput: text.length >= 1
                                focus: true
                              }

                            Label{
                                text: "Start date: "
                             }

                            ValueButton {
                                id:startDate
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
                                value: start_date
                                onClicked: openDateDialog()

                             }

                            Label{
                                text: "End date: "
                             }

                            ValueButton {
                                id:endDate
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
                                 label: "To"
                                 value: end_date
                                 onClicked: openDateDialog()

                             }

                            Label{
                                text: "Comments: "
                             }
                            TextArea {
                                id:txtcomments
                                text: comments
                             }
                        }
                    }
                    onAccepted: {
                        edditIllnes(nameIllness.text,startDate.value,endDate.value,txtcomments.text)
                    }
                }
            }
            Component.onCompleted:{
                mainHealthCondition=previousPage()
                editIllness=mainHealthCondition.editIllness
                user_id =mainHealthCondition.user_id
                illness_id =mainHealthCondition.illness_id
                name_illnes =mainHealthCondition.name_illnes
                start_date =mainHealthCondition.start_date
                end_date =mainHealthCondition.end_date
                comments =mainHealthCondition.comments
           }
        }
    }

    function edditIllnes(val1,val2,val3,val4){
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        db.transaction(
            function(tx){
                print("modifier illnes");
                print(val1,val2,val3,val4);
                var rs1 = tx.executeSql("UPDATE Illness SET name=? WHERE illness_id=?",[val1,illness_id]);
                var res2 = tx.executeSql("UPDATE HaveIllness SET start_date=?, end_date=?,comments=? WHERE id_profile=? AND illness_id=?",[val2,val3,val4,user_id,illness_id]);
            }
        )
    }
    function addIllnes(val1,val2,val3,val4){
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        db.transaction(
            function(tx){
                print("add illnes");
                print(val1,val2,val3,val4);
                var rs1 = tx.executeSql("INSERT INTO Illness(name) VALUES(?)",val1);
                rs1 = tx.executeSql("SELECT illness_id AS LastInsert FROM Illness ORDER BY LastInsert DESC LIMIT 0,1");
                var lasteInsetIllnes = rs1.rows.item(0).LastInsert;
                rs1 = tx.executeSql("INSERT INTO HaveIllness VALUES(?,?,?,?,?)",[user_id,lasteInsetIllnes,val2,val3,val4]);
            }
         )
    }
}
