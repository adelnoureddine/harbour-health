import QtQuick 2.0
import Nemo.KeepAlive 1.2

/*
 * Keeps the screen on and the phone awake while `active`, for a running meditation
 * session: the screen used to blank a minute in, and a phone that goes to sleep stops
 * the timer that says the target was reached.
 *
 * Loaded through a Loader by the session page, so the page still works should the
 * Nemo.KeepAlive module be missing.
 */
Item {
    id: root

    property bool active: false

    // DisplayBlanking is a singleton of the module, not something to create.
    onActiveChanged: DisplayBlanking.preventBlanking = active
    Component.onDestruction: DisplayBlanking.preventBlanking = false

    KeepAlive {
        enabled: root.active
    }
}
