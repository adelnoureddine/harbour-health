import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All

    property int duration: 0
    property bool running: false
    property string sessionName: qsTr("Meditation Session")

    Timer {
        id: timer
        interval: 1000
        repeat: true
        onTriggered: {
            duration++;
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("New Session")
            }

            TextField {
                id: nameField
                width: parent.width
                label: qsTr("Session Name")
                text: sessionName
                onTextChanged: sessionName = text
            }

            SectionHeader {
                text: qsTr("Timer")
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("%1:%2").arg(Math.floor(duration / 60)).arg((duration % 60 < 10 ? "0" : "") + (duration % 60))
                font.pixelSize: Theme.fontSizeHuge
                color: Theme.highlightColor
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge

                Button {
                    text: running ? qsTr("Pause") : qsTr("Start")
                    onClicked: {
                        running = !running;
                        timer.running = running;
                    }
                }

                Button {
                    text: qsTr("Reset")
                    onClicked: {
                        running = false;
                        timer.running = false;
                        duration = 0;
                    }
                }
            }

            SectionHeader {
                text: qsTr("Summary")
            }

            DetailItem {
                label: qsTr("Elapsed Time")
                value: qsTr("%1 minutes").arg(Math.ceil(duration / 60))
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Save and Finish")
                enabled: duration > 0
                onClicked: {
                    var profiles = DataManager.getProfiles();
                    if (profiles.length > 0) {
                        DataManager.addMeditationSession(profiles[0].id, Math.ceil(duration / 60), sessionName);
                        pageStack.pop();
                    }
                }
            }
        }
    }
}
