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
                                    firstname VARCHAR(30) NOT NULL,
                                    lastname VARCHAR(30) NOT NULL,
                                    gender CHAR(1) NOT NULL,
                                    birthday DATE NOT NULL,
                                    PRIMARY KEY(user_id)
                                 );";
        //Metrics
        var createMetricsTable = "CREATE TABLE IF NOT EXISTS Metrics(
                                    id_metric INTEGER NOT NULL,
                                    name VARCHAR(30) NOT NULL,
                                    unit VARCHAR(10) NOT NULL,
                                    PRIMARY KEY(id_metric)
                                  );";

        var createHave_metricsTable = "CREATE TABLE IF NOT EXISTS MetricValue(
                                    id_profile INTEGER NOT NULL,
                                    id_metric INTEGER NOT NULL,
                                    date_metric DATE NOT NULL,
                                    value_metric INTEGER NOT NULL,
                                    PRIMARY KEY(id_profile, id_metric),
                                    FOREIGN KEY(id_profile) REFERENCE Profile(id_profile),
                                    FOREIGN KEY(id_metric) REFERENCE Metrics(id_metric)
                                  );";

        //MEDITATION
        var createMusicTable = "CREATE TABLE IF NOT EXISTS Musics(
                                    id_music INTEGER NOT NULL,
                                    name VARCHAR(50) NOT NULL,
                                    path VARCHA(50) NOT NULL,
                                    PRIMARY KEY(id_music)
                                );";

        var createMeditationTable = "CREATE TABLE IF NOT EXISTS Meditation(
                                        id_profile INTEGER NOT NULL,
                                        id_music INTEGER NOT NULL,
                                        meditation_date DATE NOT NULL,
                                        duration TIME NOT NULL,
                                        PRIMARY KEY(id_profile, id_music),
                                        FOREIGN KEY(id_profile) REFERENCE Profile(id_profile),
                                        FOREIGN KEY(id_music) REFERENCE Musics(id_music)
                                     );";

        //VACCINES
        var createVaccinesTable = "CREATE TABLE IF NOT EXISTS Vaccines(
                                        id_vaccine INTEGER NOT NULL,
                                        name VARCHAR(30) NOT NULL,
                                        number_boosters INTEGER NOT NULL,
                                        PRIMARY KEY(id_vaccine)
                                     );";

        var createInjectionsTable = "CREATE TABLE IF NOT EXISTS Injection(
                                        id_profile INTEGER NOT NULL,
                                        id_vaccine INTEGER NOT NULL,
                                        injection_date DATE NOT NULL,
                                        PRIMARY KEY(id_profile, id_vaccine),
                                        FOREIGN KEY(id_profile) REFERENCE Profile(id_profile),
                                        FOREIGN KEY(id_vaccine) REFERENCE Vaccines(id_vaccine)
                                     );";

        var createHave_intervalTable = "CREATE TABLE IF NOT EXISTS Injection(
                                        id_vaccine INTEGER NOT NULL,
                                        id_interval INTEGER NOT NULL,
                                        PRIMARY KEY(id_vaccine, id_interval),
                                        FOREIGN KEY(id_vaccine) REFERENCE Vaccines(id_vaccine),
                                        FOREIGN KEY(id_interval) REFERENCE Vaccine_interval(id_interval)
                                     );";


        var createVaccine_intervalTable = "CREATE TABLE IF NOT EXISTS Interval(
                                        id_interval INTEGER NOT NULL,
                                        recall_number INTEGER NOT NULL,
                                        recall_month INTEGER NOT NULL,
                                        PRIMARY KEY(id_interval),

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
                    tx.executeSql(createHave_metricsTable);
                    tx.executeSql(createMusicTable);
                    tx.executeSql(createMeditationTable);
                    tx.executeSql(createVaccinesTable);
                    tx.executeSql(createInjectionsTable);
                    tx.executeSql(createHave_intervalTable);
                    tx.executeSql(createVaccine_intervalTable);
                }
            );
    }
}
