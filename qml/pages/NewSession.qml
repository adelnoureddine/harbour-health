import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All
    // Swiping back used to throw a running session away without a word. Pause first.
    backNavigation: !running

    property int profileId: -1
    property string sessionName: qsTr("Meditation session")

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

    function formatDuration(seconds) {
        var minutes = Math.floor(seconds / 60);
        var remainder = seconds % 60;
        return minutes + ":" + (remainder < 10 ? "0" : "") + remainder;
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
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("New session")
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

            SectionHeader {
                text: qsTr("Timer")
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.formatDuration(page.elapsed)
                font.pixelSize: Theme.fontSizeHuge
                color: Theme.highlightColor
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
                    // Stored in seconds: rounding up to whole minutes turned a
                    // ten-second sitting into a one-minute session.
                    DataManager.addMeditationSession(page.profileId, page.accumulated,
                                                     page.sessionName, new Date());
                    pageStack.pop();
                }
            }
        }

        VerticalScrollDecorator {}
    }

    // Leaving the page must not leave the ticker running.
    Component.onDestruction: ticker.stop()
}

// vim:et:ts=4:sw=4
