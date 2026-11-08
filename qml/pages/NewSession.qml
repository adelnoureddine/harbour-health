import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Page {
    id: page
    allowedOrientations: Orientation.All
    // Swiping back used to throw a running session away without a word. Pause first.
    backNavigation: !running

    property int profileId: -1
    property string sessionName: qsTr("Meditation session")
    property string profileName: ""

    /*
     * Elapsed time comes from the wall clock, not from counting Timer ticks. A
     * 1-second Timer drifts and can be throttled outright while the app is in the
     * background, so a counted session could end up far shorter than the real one.
     * The Timer now only drives the display.
     */
    property bool running: false
    property double startedAt: 0        // ms, while running
    property int accumulated: 0         // seconds banked from previous runs
    property int elapsed: 0             // seconds, what is displayed

    // Optional target in minutes. Without one the ring shows the current ten minutes.
    property int targetMinutes: 0
    readonly property var targetChoices: [0, 5, 10, 15, 20, 30, 45, 60]
    readonly property int ringSeconds: targetMinutes > 0 ? targetMinutes * 60 : 600
    readonly property bool targetReached: targetMinutes > 0 && elapsed >= ringSeconds

    function currentElapsed() {
        if (!running) {
            return accumulated;
        }
        return accumulated + Math.floor((Date.now() - startedAt) / 1000);
    }

    function start() {
        startedAt = Date.now();
        running = true;
        ticker.start();
    }

    function pause() {
        accumulated = currentElapsed();
        running = false;
        ticker.stop();
        elapsed = accumulated;
    }

    function reset() {
        running = false;
        ticker.stop();
        accumulated = 0;
        elapsed = 0;
    }

    // "4:05", or "1:04:05" past an hour.
    function formatDuration(seconds) {
        var hours = Math.floor(seconds / 3600);
        var minutes = Math.floor((seconds % 3600) / 60);
        var remainder = seconds % 60;
        var tail = (remainder < 10 ? "0" : "") + remainder;
        if (hours > 0) {
            return hours + ":" + (minutes < 10 ? "0" : "") + minutes + ":" + tail;
        }
        return minutes + ":" + tail;
    }

    function statusText() {
        if (targetReached) {
            return qsTr("Target reached");
        }
        if (!running && elapsed > 0) {
            return qsTr("Paused");
        }
        //: Under the timer: the chosen target, e.g. "of 10 min"
        return targetMinutes > 0 ? qsTr("of %n min", "", targetMinutes) : "";
    }

    RemorsePopup {
        id: resetRemorse
    }

    Timer {
        id: ticker
        interval: 500
        repeat: true
        onTriggered: page.elapsed = page.currentElapsed()
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("New session")
                description: page.profileName
            }

            Item {
                width: parent.width
                height: ring.height

                ProgressCircle {
                    id: ring
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(Theme.itemSizeHuge * 2, Math.min(page.width, page.height) * 0.6)
                    height: width
                    value: page.targetMinutes > 0 ? Math.min(1, page.elapsed / page.ringSeconds)
                                                  : (page.elapsed % page.ringSeconds) / page.ringSeconds
                    progressColor: page.targetReached ? Utils.constraintColor("green") : Theme.highlightColor
                    backgroundColor: Theme.rgba(Theme.primaryColor, 0.2)
                }

                Column {
                    anchors.centerIn: ring
                    width: ring.width * 0.75

                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: page.formatDuration(page.elapsed)
                        font.pixelSize: Theme.fontSizeHuge * 1.15
                        // Past an hour the extra digits must still fit inside the ring.
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: Theme.fontSizeLarge
                        color: page.running ? Theme.highlightColor : Theme.primaryColor
                    }
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        truncationMode: TruncationMode.Fade
                        text: page.statusText()
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryHighlightColor
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge

                Button {
                    text: page.running ? qsTr("Pause") : qsTr("Start")
                    onClicked: page.running ? page.pause() : page.start()
                }

                Button {
                    text: qsTr("Reset")
                    enabled: page.elapsed > 0 || page.running
                    onClicked: resetRemorse.execute(qsTr("Resetting timer"), function() {
                        page.reset();
                    })
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Save and finish")
                // `elapsed` is what the ticker updates. currentElapsed() read the clock,
                // which a binding never re-evaluates, so the button stayed disabled
                // through the whole first run.
                enabled: page.profileId >= 0 && page.elapsed > 0
                onClicked: {
                    page.pause();
                    var name = page.sessionName.trim();
                    // Stored in seconds: rounding up to whole minutes turned a
                    // ten-second sitting into a one-minute session.
                    DataManager.addMeditationSession(page.profileId, page.accumulated,
                                                     name !== "" ? name : qsTr("Meditation session"),
                                                     new Date());
                    pageStack.pop();
                }
            }

            SectionHeader {
                text: qsTr("Session")
            }

            TextField {
                id: nameField
                width: parent.width
                label: qsTr("Session name")
                text: sessionName
                onTextChanged: sessionName = text
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
            }

            ComboBox {
                id: targetBox
                width: parent.width
                label: qsTr("Target")
                description: page.targetMinutes > 0 ? ""
                                                    : qsTr("Without a target the ring shows the current ten minutes")
                // One item per choice, in the same order, so currentIndex indexes
                // targetChoices.
                menu: ContextMenu {
                    Repeater {
                        model: page.targetChoices
                        MenuItem {
                            text: modelData === 0
                                  //: No meditation target
                                  ? qsTr("None")
                                  //: Meditation target in minutes
                                  : qsTr("%n min", "", modelData)
                        }
                    }
                }
                onCurrentIndexChanged: page.targetMinutes = page.targetChoices[currentIndex] || 0
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: {
        if (profileId >= 0) {
            var profile = DataManager.getProfile(profileId);
            profileName = profile ? profile.firstName : "";
        }
    }

    // Leaving the page must not leave the ticker running.
    Component.onDestruction: ticker.stop()
}

// vim:et:ts=4:sw=4
