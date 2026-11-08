import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import "js/DataManager.js" as DataManager

ApplicationWindow {
    id: appWindow
    initialPage: Component { MainPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    // Empty unless the database could not be opened or upgraded.
    property string databaseError: ""

    /*
     * The database creates or upgrades itself on first use, whichever of the dashboard,
     * the cover or this comes first. This only catches a failure, so a failed schema
     * upgrade does not leave a blank, unexplained window.
     *
     * Without a profile the dashboard shows its welcome screen, which explains the app
     * and offers creating a profile or restoring a backup.
     */
    Component.onCompleted: {
        try {
            DataManager.init();
        } catch (error) {
            databaseError = error.message ? error.message : String(error);
        }
    }
}

// vim:et:ts=4:sw=4
