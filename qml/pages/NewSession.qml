import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0 //used to play music
import QtQml 2.0


Page {
    id: newSession
    allowedOrientations: Orientation.All
    property bool running: false

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
                id: monTimer
                text: timePicker.hour + " : " + timePicker.minute
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

            IconComboBox { //maybe change with musicPicker; need import
                id: musicSelection
                icon.source: "image://theme/icon-m-music"
                label: "Musics"
                width: parent.width / 1.5
                menu: ContextMenu {
                    //change with data from database
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
                id: play_pause_button
                icon.source: "image://theme/icon-l-play"
                y: musicSelection.y + musicSelection.height / 2 - this.height/2

                onClicked: function (){
                    if(registerButton.checked){
                        console.log("register")
                        //register session in database
                    }
                    updateState()

                }
            }

            Timer{
                id: timer
                interval: 1000; repeat: true
                onTriggered: {
                    if(timePicker.minute == 0 && timePicker.hour == 0){
                        updateState()
                    }

                    if(timePicker.minute == 0 && timePicker.hour>0){
                        timePicker.hour -= 1
                        timePicker.minute = 60
                    }

                    timePicker.minute -= 1
                }
            }

            //audio player
            Audio{//maybe change with MediaPlayer
                id: music
                source: musicSelection.value
            }
        }
    }

    function updateState(){
        //State change
        running = !running

        play_pause_button.icon.source = running ? "image://theme/icon-l-pause" : "image://theme/icon-l-play"

        //play/pause music
        if(running){
            music.play()
            console.log("play " + music.source + " for " + timePicker.hour + " hours and " + timePicker.minute + " minutes")
            timer.running = true
        }else{
            music.pause()
            timer.running = false
        }
    }
}
