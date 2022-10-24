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
        //PROFILE
        var createProfilesTable = "CREATE TABLE IF NOT EXISTS Profiles(
                                    id_profile INTEGER NOT NULL,
                                    name VARCHAR(30) NOT NULL,
                                    first_name VARCHAR(30) NOT NULL,
                                    gender CHAR(1) NOT NULL,
                                    birth_date DATE NOT NULL,
                                    PRIMARY KEY(user_id)
                                 );";
        //Metrics
        var createMetricsTable = "CREATE TABLE IF NOT EXISTS Metrics(
                                    id_metric INTEGER NOT NULL,
                                    metric_name VARCHAR(30) NOT NULL,
                                    metric_unit VARCHAR(10) NOT NULL,
                                    PRIMARY KEY(id_metric)
                                  );";

        var createMetricValueTable = "CREATE TABLE IF NOT EXISTS MetricValue(
                                    id_profile INTEGER NOT NULL,
                                    id_metric INTEGER NOT NULL,
                                    metric_date DATE NOT NULL,
                                    metric_value INTEGER NOT NULL,
                                    PRIMARY KEY(id_profile, id_metric),
                                    FOREIGN KEY(id_profile) REFERENCE Profile(id_profile),
                                    FOREIGN KEY(id_metric) REFERENCE Metrics(id_metric)
                                  );";

        //MEDITATION
        var createMusicTable = "CREATE TABLE IF NOT EXISTS Musics(
                                    id_music INTEGER NOT NULL,
                                    music_name VARCHAR(50) NOT NULL,
                                    url VARCHA(50) NOT NULL,
                                    PRIMARY KEY(id_music)
                                );";

        var createMeditationTable = "CREATE TABLE IF NOT EXISTS Meditation(
                                        id_session INTEGER NOT NULL,
                                        id_profile INTEGER NOT NULL,
                                        id_music INTEGER NOT NULL,
                                        meditation_date DATE NOT NULL,
                                        meditation_time TIME NOT NULL,
                                        PRIMARY KEY(id_session),
                                        FOREIGN KEY(id_profile) REFERENCE Profile(id_profile),
                                        FOREIGN KEY(id_music) REFERENCE Musics(id_music)
                                     );";

        //VACCINES
        var createVaccinesTable = "CREATE TABLE IF NOT EXISTS Vaccines(
                                        id_vaccine INTEGER NOT NULL,
                                        vaccine_name VARCHAR(30) NOT NULL,
                                        nb_recall INTEGER NOT NULL,
                                        PRIMARY KEY(id_vaccine)
                                     );";

        var createInjectionTable = "CREATE TABLE IF NOT EXISTS Injection(
                                        id_profile INTEGER NOT NULL,
                                        id_vaccine INTEGER NOT NULL,
                                        taken_date DATE NOT NULL,
                                        PRIMARY KEY(id_profile, id_vaccine),
                                        FOREIGN KEY(id_profile) REFERENCE Profile(id_profile),
                                        FOREIGN KEY(id_vaccine) REFERENCE Vaccines(id_vaccine)
                                     );";

        var createRecallTable = "CREATE TABLE IF NOT EXISTS Recall(
                                        id_recall INTEGER NOT NULL,
                                        id_vaccine INTEGER NOT NULL,
                                        recall_number INTEGER NOT NULL,
                                        recall_date DATE NOT NULL,
                                        PRIMARY KEY(id_recall),
                                        FOREIGN KEY(id_vaccine) REFERENCE Vaccines(id_vaccine)
                                     );";

        var createIntervalTable = "CREATE TABLE IF NOT EXISTS Interval(
                                        id_interval INTEGER NOT NULL,
                                        id_vaccine INTEGER NOT NULL,
                                        recall_number INTEGER NOT NULL,
                                        next_recall Integer NOT NULL,
                                        PRIMARY KEY(id_interval),
                                        FOREIGN KEY(id_vaccine) REFERENCE Vaccines(id_vaccine)
                                     );";

        //HEALTH CONDITION
        var createXXTable = "CREATE TABLE IF NOT EXISTS XX";

        //NUTRITION
        var createXYTable = "CREATE TABLE IF NOT EXISTS XY";

        //MENSTRUATION
        var createYXTable = "CREATE TABLE IF NOT EXISTS YX";

        db.transaction(
                function(tx) {
                    tx.executeSql(createProfilesTable);
                    tx.executeSql(createMetricsTable);
                    tx.executeSql(createMetricValueTable);
                    tx.executeSql(createMusicTable);
                    tx.executeSql(createMeditationTable);
                }
            );
    }
}
