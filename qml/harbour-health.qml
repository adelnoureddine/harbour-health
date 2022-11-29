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
        //PROFILE
        var createProfilesTable = "CREATE TABLE IF NOT EXISTS Profiles(
                                    id_profile INTEGER PRIMARY KEY AUTOINCREMENT ,
                                    firstname VARCHAR(30) NOT NULL,
                                    lastname VARCHAR(30) NOT NULL,
                                    gender CHAR(1) NOT NULL,
                                    birthday DATE NOT NULL
                                 );";



        //Metrics
        var createMetricsTable = "CREATE TABLE IF NOT EXISTS Metrics(
                                    id_metric INTEGER PRIMARY KEY AUTOINCREMENT,
                                    name VARCHAR(30) NOT NULL,
                                    unit VARCHAR(10) NOT NULL
                                  );";

        var createHave_metricsTable = "CREATE TABLE IF NOT EXISTS MetricValue(
                                    id_profile INTEGER NOT NULL,
                                    id_metric INTEGER NOT NULL,
                                    date_metric DATE NOT NULL,
                                    value_metric INTEGER NOT NULL,
                                    PRIMARY KEY(id_profile, id_metric),
                                    FOREIGN KEY(id_profile) REFERENCES Profiles(id_profile),
                                    FOREIGN KEY(id_metric) REFERENCES Metrics(id_metric)
                                  );";

        //MEDITATION
        var createMusicTable = "CREATE TABLE IF NOT EXISTS Musics(
                                    id_music INTEGER PRIMARY KEY AUTOINCREMENT,
                                    name VARCHAR(50) NOT NULL,
                                    path VARCHA(50) NOT NULL
                                );";

        var createMeditationTable = "CREATE TABLE IF NOT EXISTS Meditation(
                                        id_meditation INTEGER PRIMARY KEY AUTOINCREMENT,
                                        id_profile INTEGER NOT NULL,
                                        id_music INTEGER NOT NULL,
                                        meditation_date DATE NOT NULL,
                                        duration TIME NOT NULL,
                                        FOREIGN KEY(id_profile) REFERENCES Profiles(id_profile),
                                        FOREIGN KEY(id_music) REFERENCES Musics(id_music)
                                     );";




        //VACCINES
        var createVaccinesTable = "CREATE TABLE IF NOT EXISTS Vaccines(
                                        id_vaccine INTEGER PRIMARY KEY AUTOINCREMENT ,
                                        name VARCHAR(30) NOT NULL,
                                        number_boosters INTEGER NOT NULL
                                     );";

        var createInjectionsTable = "CREATE TABLE IF NOT EXISTS Injection(
                                        id_profile INTEGER NOT NULL,
                                        id_vaccine INTEGER NOT NULL,
                                        injection_date DATE NOT NULL,
                                        PRIMARY KEY(id_profile, id_vaccine),
                                        FOREIGN KEY(id_profile) REFERENCES Profiles(id_profile),
                                        FOREIGN KEY(id_vaccine) REFERENCES Vaccines(id_vaccine)
                                     );";

        var createVaccine_intervalTable = "CREATE TABLE IF NOT EXISTS Interval(
                                        id_interval INTEGER NOT NULL,
                                        id_vaccine INTEGER NOT NULL,
                                        recall_number INTEGER NOT NULL,
                                        recall_month INTEGER NOT NULL,
                                        PRIMARY KEY(id_interval),
                                        FOREIGN KEY (id_vaccine) REFERENCES Vaccines(id_vaccine)
                                     );";






        //HEALTH CONDITION
        var createXXTable = "CREATE TABLE IF NOT EXISTS XX";

        //NUTRITION
        var createXYTable = "CREATE TABLE IF NOT EXISTS XY";

        //MENSTRUATION
        var createYXTable = "CREATE TABLE IF NOT EXISTS YX";


        db.transaction(
                function(tx) {
                    //drop table
                    //tx.executeSql("DROP TABLE Profiles")
                    //tx.executeSql("DROP TABLE Musics")
                    tx.executeSql("DROP TABLE Meditation")

                    //create table
                    tx.executeSql(createProfilesTable);
                    tx.executeSql(createMetricsTable);
                    tx.executeSql(createHave_metricsTable);
                    tx.executeSql(createMusicTable);
                    tx.executeSql(createMeditationTable);
                    tx.executeSql(createVaccinesTable);
                    tx.executeSql(createInjectionsTable);
                    //tx.executeSql(createHave_intervalTable);
                    tx.executeSql(createVaccine_intervalTable);



                    //insert into
                    var insertProfile = "INSERT INTO Profiles VALUES (0,'nomtest2', 'prenomtest', 'H', '10/04/2000')"
                    var insertMusic = "INSERT INTO Musics VALUES (31, 'nomMusic', '/dfsdf/fdsf')"
                    var insertMeditation = "INSERT INTO Meditation VALUES (null,0, 31, '06/09/2010', '00:10:20')"

                    //tx.executeSql(insertProfile);
                    //tx.executeSql(insertMusic);
                    //tx.executeSql(insertMeditation);
                }
            );
    }
}
