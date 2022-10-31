import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"

// For database
import QtQuick.LocalStorage 2.0

ApplicationWindow {
    initialPage: Component { MainPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    Component.onCompleted: {
        initDatabase();
    }
    property string session: "New Session"

    function initDatabase() {
        var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
        var createXXTable = "CREATE TABLE IF NOT EXISTS XXXX";
        var createXYTable = "CREATE TABLE IF NOT EXISTS XXXX";
        var createYYTable = "CREATE TABLE IF NOT EXISTS XXXX";
        var createYXTable = "CREATE TABLE IF NOT EXISTS XXXX";
        db.transaction(
                function(tx) {
                    tx.executeSql(createXXTable);
                    tx.executeSql(createXYTable);
                    tx.executeSql(createYYTable);
                    tx.executeSql(createYXTable);
                }
            );
    }
}
