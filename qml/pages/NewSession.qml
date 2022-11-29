import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0 //used to play music
import QtQml 2.0
import Sailfish.Pickers 1.0
import QtQuick.LocalStorage 2.0


Page {
    id: newSession
    allowedOrientations: Orientation.All
    property bool running: false
    property string selectedMusicFile
    property bool registered: false
    property int userId

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
                text: { //Display time -> hh:mm
                    var hour = timePicker.hour
                    var minute = timePicker.minute
                    var string = ""

                    hour<10 ? string += "0" : ""
                    string += hour + ":"
                    minute<10 ? string += "0" : ""
                    string += minute
                    //console.log(string)
                    return string
            }

                anchors.centerIn: parent //Put the label in the center of the timePicker
                font.pixelSize: Theme.fontSizeHuge
            }

        }

        //Register or not the session in database when starting session
        TextSwitch{
            id: registerButton
            text: "Register"
        }

        Row{
            width: parent.width

            Icon{
                source: "image://theme/icon-m-music"
            }

            ValueButton { //Song selector
                id: songSelector
                label: "Song"
                value: selectedMusicFile ? selectedMusicFile : "None"
                width: parent.width / 2
                onClicked: pageStack.push(musicPickerPage)
            }

            IconButton{ //Play/pause button
                id: play_pause_button
                icon.source: "image://theme/icon-l-play"
                onClicked: function (){
                    if(registerButton.checked && registered==false){
                        //register session in database
                        registered = true
                        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
                        db.transaction(
                            function(tx) {
                                var musicId = tx.executeSql("SELECT * FROM Musics WHERE name = ?", [songSelector.valye])// still need to fetch id from result
                                tx.executeSql("INSERT INTO Meditation VALUES (?,?,?,?,?)", [null,userId , musicId,new Date().toDateString(),"00:" + monTimer.text])//modify date with smaller format jj/mm/yyyy
                                console.log("Session registered")
                            }
                        );

                    }
                    updateState()
                }
            }

            //Song selector component
            Component {
                id: musicPickerPage
                MusicPickerPage {
                    onSelectedContentPropertiesChanged: {
                        page.selectedMusicFile = selectedContentProperties.filePath
                    }
                }
            }

            Timer{
                id: timer
                interval: 1000; repeat: true
                onTriggered: {
                    if(timePicker.minute == 0 && timePicker.hour == 0){
                        updateState()
                    }else if(timePicker.minute == 0 && timePicker.hour>0){
                        timePicker.hour -= 1
                        timePicker.minute = 60
                    }
                    timePicker.minute -= 1
                }
            }

            //audio player
            Audio{//maybe change with MediaPlayer
                id: music
                source: songSelector.value
            } 
        }
    }


    //Alternate between pause/play for function of different component
    function updateState(){
        //State change
        running = !running

        //Change the button Icon
        play_pause_button.icon.source = running ? "image://theme/icon-l-pause" : "image://theme/icon-l-play"

        //play/pause music and timer
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
