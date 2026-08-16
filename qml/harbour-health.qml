import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import "js/DataManager.js" as DataManager

ApplicationWindow {
    id: appWindow
    initialPage: Component { MainPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations
    property var profileId

    Component.onCompleted: {
        DataManager.init();
        loadActiveProfile();
        if (DataManager.countProfiles() === 0) {
            pageStack.push(Qt.resolvedUrl("pages/createProfile.qml"));
        }
    }

    function loadActiveProfile() {
        var profiles = DataManager.getProfiles();
        if (profiles.length > 0) {
            profileId = profiles[0].id;
        }
    }
}

// vim:et:ts=4:sw=4
