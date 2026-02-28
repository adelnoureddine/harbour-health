import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import "js/DataManager.js" as DataManager

ApplicationWindow {
    initialPage: Component { MainPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations
    property var activeProfile: null

    Component.onCompleted: {
        DataManager.init();
        loadActiveProfile();
    }

    function loadActiveProfile() {
        var profiles = DataManager.getProfiles();
        if (profiles.length > 0) {
            activeProfile = profiles[0];
        }
    }
}
