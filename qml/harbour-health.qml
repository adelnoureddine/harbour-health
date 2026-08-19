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

    Component.onCompleted: {
        try {
            DataManager.init();
        } catch (error) {
            // A failed schema upgrade must not leave a blank, unexplained window.
            databaseError = error.message ? error.message : String(error);
            return;
        }

        if (DataManager.countProfiles() === 0) {
            pageStack.push(Qt.resolvedUrl("pages/createProfile.qml"));
        }
    }
}

// vim:et:ts=4:sw=4
