import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: newSession
    allowedOrientations: Orientation.All

    PageHeader{
        title:  session
    }

    Column{
        id: column
        width: newSession.width

        anchors.verticalCenter: parent.verticalCenter

        //TimePicker
        Item{
            id: clockItem

            width: timePicker.width//Item take the width and height of the TimePicker
            height: timePicker.height

            anchors.horizontalCenter: parent.horizontalCenter

            TimePicker{
                id: timePicker
                hour: 0
                minute: 0
                hourMode: DateTime.TwentyFourHours
                onRotationChanged: console.log("test")
            }
            Label{
                text: timePicker.timeText
                anchors.centerIn: parent //Put the label in the center of the timePicker
                font.pixelSize: Theme.fontSizeHuge
            }

        }

        TextSwitch{
            id: registerButton
            text: "Register"
        }

        Row{
            width: parent.width

            IconComboBox {
                id: musicSelection
                icon.source: "image://theme/icon-m-music"
                label: "Musics"
                width: parent.width / 1.5
                menu: ContextMenu {
                    MenuItem {text: "option a"}
                    MenuItem { text: "sdfqsdfsqdfqsdfqsfqsdf"}
                    MenuItem { text: "option c" }
                    MenuItem { text: "option d" }
                    MenuItem { text: "option e" }
                    MenuItem { text: "option f" }
                    MenuItem { text: "option g" }
                    MenuItem { text: "option h" }
                    MenuItem { text: "option i" }
                    MenuItem { text: "option j" }
                    MenuItem { text: "option k" }
                    MenuItem { text: "option l" }
                    MenuItem { text: "option m" }
                    MenuItem { text: "option n" }
                    MenuItem { text: "option o" }
                    MenuItem { text: "option p" }
                    MenuItem { text: "option q" }
                    MenuItem { text: "option r" }
                    MenuItem { text: "option s" }
                    MenuItem { text: "option t" }
                }
            }

            IconButton{
                icon.source: "image://theme/icon-l-play"
                y: musicSelection.y + musicSelection.height / 2 - this.height/2

                onClicked: function (){
                    if(registerButton.checked){
                        console.log("register")
                        //register session in database
                    }

                    this.icon.source = this.icon.source == "image://theme/icon-l-play" ? "image://theme/icon-l-pause" : "image://theme/icon-l-play"

                    console.log("play")
                    //play/pause music ; launch/pause chronometer
                }
            }
        }
    }
}
