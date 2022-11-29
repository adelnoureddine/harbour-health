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


/*****




import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import QtQuick.LocalStorage 2.0

ApplicationWindow
{
    initialPage: Component { MainPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations


    Component.onCompleted: {
        createLastUser()
        setProfil();
        setMetric();
    }

    function createLastUser() {
        var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);

        var createUsersTable = 'CREATE TABLE IF NOT EXISTS SETTINGS(
                                    USER_CODE INTEGER NOT NULL,
                                    PRIMARY KEY(USER_CODE)
                                 );';
        db.transaction(
            function(tx){
                tx.executeSql(createUsersTable);
            }
        )
    }


    function setProfil() {
        var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);

        var createUsersTable = 'CREATE TABLE IF NOT EXISTS USERS(
                                    USER_CODE INTEGER NOT NULL,
                                    LASTNAME VARCHAR(30) NOT NULL,
                                    FIRSTNAME VARCHAR(30) NOT NULL,
                                    GENDER CHAR(1) NOT NULL,
                                    BIRTHDAY DATE NOT NULL,
                                    HEIGHT INTEGER NOT NULL,
                                    PRIMARY KEY(USER_CODE)
                                 );';
        db.transaction(
            function(tx){
                tx.executeSql(createUsersTable);
            }
        )
    }

    function setMetric() {
        var db = LocalStorage.openDatabaseSync("WeightTracker", "1.0", "Database application", 100000);

        var createMetricsTable = 'CREATE TABLE IF NOT EXISTS METRICS(
                                       USER_CODE INTEGER NOT NULL,
                                       METRIC_CODE INTEGER NOT NULL,
                                       METRIC_DATE DATE NOT NULL,
                                       CATEGORIE VARCHAR(20) NOT NULL,
                                       VAL DECIMAL(3,2) NOT NULL,
                                       PRIMARY KEY(USER_CODE,METRIC_CODE),
                                       FOREIGN KEY(USER_CODE) REFERENCES USERS(USER_CODE)
                                    );';
        db.transaction(
            function(tx){
                tx.executeSql(createMetricsTable);
            }
        )
    }
}




















***/
