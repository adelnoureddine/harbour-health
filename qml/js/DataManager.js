.pragma library
.import QtQuick.LocalStorage 2.0 as Sql

// Database constants
// A new name deliberately separates the public v1 database from pre-release data.
var DB_NAME = "HarbourHealthV1";
var DB_VERSION = "1.0";
var DB_DESCRIPTION = "Harbour Health Application Database";
var DB_SIZE = 1000000;
var DB_SCHEMA_VERSION = 1;

// Category
var CATEGORY_BODY = "Body";
var CATEGORY_NUTRITION = "Nutrition";
var CATEGORY_BLOOD = "Blood";
var CATEGORY_OTHER = "Other";

// Metrics
var METRIC_WEIGHT = "weight";
var METRIC_HEIGHT = "height";
var METRIC_WATER = "water";
var METRIC_CALORIES = "calories";
var METRIC_HEARTRATE = "heartrate";
var METRIC_BP_SYS = "systolic blood pressure";
var METRIC_BP_DIA = "diastolic blood pressure";
var METRIC_GLUCOSE = "glucose";

// Modules
var MODULE_WEIGHT = "Weight";
var MODULE_HEIGHT = "Height";
var MODULE_BMI = "BMI";
var MODULE_CALORIES = "Calories";
var MODULE_WATER = "Water";
var MODULE_HEARTRATE = "Heartrate";
var MODULE_BP = "Blood Pressure";
var MODULE_GLUCOSE = "Glucose";
var MODULE_CONDITION = "Health Condition";
var MODULE_VACCINATION = "Vaccination";
var MODULE_MEDITATION = "Meditation";
var MODULE_MENSTRUATION = "Menstruation";

// Module Types
var MODULE_TYPE_METRIC = "Metric";
var MODULE_TYPE_CALC = "Calc";
var MODULE_TYPE_SUMMARY = "Summary";

// local time day border -> 04:00:00
var DAY_START_TIME = "04:00:00";

// Series aggregation modes for the history charts
var SERIES_RAW = "raw";
var SERIES_DAILY_SUM = "dailySum";
var SERIES_DAILY_AVG = "dailyAvg";

// Every profile-owned table. Used by deleteProfile() so the cascade cannot drift.
var PROFILE_TABLES = ["HealthLogs", "Injections", "Treatments", "HealthConditions",
                      "MenstrualCycles", "MenstrualLogs", "MeditationSessions",
                      "MedicationLogs", "ProfileModules"];

// Tables covered by export/restore, parents before children.
var ALL_TABLES = ["Profiles", "Metrics", "Modules", "ProfileModules", "MetricConstraints",
                  "HealthLogs", "Vaccines", "Injections", "Medications", "Treatments",
                  "MedicationLogs", "HealthConditions", "MenstrualCycles", "MenstrualLogs",
                  "MeditationSessions"];

/*
 * openDatabaseSync() was previously called afresh by every single function. Returning
 * to the dashboard rebuilds a dozen cards, each running several of them, so the
 * handle is memoised for the lifetime of the engine.
 */
var _db = null;

function db() {
    if (_db === null) {
        _db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    }
    return _db;
}

function _pad2(n) {
    return (n < 10 ? "0" : "") + n;
}

/*
 * Canonical storage format for a point in time: local "YYYY-MM-DDTHH:MM:SS".
 *
 * Timestamps used to be bound as JS Date objects and left to Qt's implicit
 * conversion. Writing the string ourselves keeps the format explicit, keeps it in
 * local time (matching the local calendar dates stored elsewhere), and keeps it in a
 * shape SQLite's date()/datetime() functions accept.
 */
function toTimestamp(value) {
    if (!value) {
        value = new Date();
    }
    if (typeof value === "string") {
        return value;
    }
    return value.getFullYear() + "-" + _pad2(value.getMonth() + 1) + "-" + _pad2(value.getDate())
            + "T" + _pad2(value.getHours()) + ":" + _pad2(value.getMinutes())
            + ":" + _pad2(value.getSeconds());
}

// Milliseconds since epoch for a stored timestamp or date, parsed as local time.
function timestampToMs(s) {
    if (!s) {
        return NaN;
    }
    var halves = String(s).replace(" ", "T").split("T");
    var d = halves[0].split("-");
    if (d.length < 3) {
        return NaN;
    }
    var date = new Date(parseInt(d[0], 10), parseInt(d[1], 10) - 1, parseInt(d[2], 10));
    if (halves.length > 1) {
        var t = halves[1].split(".")[0].split("Z")[0].split("+")[0].split(":");
        date.setHours(parseInt(t[0], 10) || 0, parseInt(t[1], 10) || 0, parseInt(t[2], 10) || 0, 0);
    }
    return date.getTime();
}

/*
 * Schema upgrades.
 *
 * Add one `if (version < N)` block per new schema version, ending by assigning N.
 * Everything runs inside init()'s transaction, so a failed upgrade rolls back whole.
 * Bump DB_SCHEMA_VERSION in the same commit as the block that reaches it.
 */
function migrateDatabase(tx, fromVersion) {
    var version = fromVersion;

    // if (version < 2) {
    //     tx.executeSql('ALTER TABLE Profiles ADD COLUMN example TEXT');
    //     version = 2;
    // }

    if (version !== DB_SCHEMA_VERSION) {
        throw new Error("No migration path from schema version " + fromVersion
                        + " to " + DB_SCHEMA_VERSION);
    }
    return version;
}

// Initialize the database and tables
function init() {
    db().transaction(function (tx) {
        tx.executeSql('CREATE TABLE IF NOT EXISTS SchemaInfo (' +
            'version INTEGER PRIMARY KEY)');
        var rs = tx.executeSql('SELECT version FROM SchemaInfo ORDER BY version DESC LIMIT 1');
        var hasSchemaVersion = rs.rows.length > 0;
        if (hasSchemaVersion) {
            var currentVersion = rs.rows.item(0).version;
            if (currentVersion > DB_SCHEMA_VERSION) {
                throw new Error("Database schema is newer than this app version");
            }
            if (currentVersion < DB_SCHEMA_VERSION) {
                migrateDatabase(tx, currentVersion);
                tx.executeSql('DELETE FROM SchemaInfo');
                tx.executeSql('INSERT INTO SchemaInfo (version) VALUES (?)', [DB_SCHEMA_VERSION]);
            }
        }

        // PROFILES
        tx.executeSql('CREATE TABLE IF NOT EXISTS Profiles (' +
            'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
            'firstName TEXT NOT NULL, ' +
            'lastName TEXT NOT NULL, ' +
            'gender TEXT NOT NULL, ' +
            'birthDate DATE NOT NULL, ' +
            'created DATETIME DEFAULT CURRENT_TIMESTAMP, ' +
            'lastUsed DATETIME, ' +
            "coverMetric1 TEXT DEFAULT 'weight', " +
            "coverMetric2 TEXT DEFAULT 'water')");

        // METRICS Definitions
        tx.executeSql('CREATE TABLE IF NOT EXISTS Metrics (' +
            'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
            'name TEXT NOT NULL, ' +
            'unit TEXT NOT NULL, ' +
            'grouped BOOLEAN DEFAULT FALSE, ' +
            'category TEXT)');

        // HEALTH LOGS (Universal table for measurements)
        tx.executeSql('CREATE TABLE IF NOT EXISTS HealthLogs (' +
            'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
            'profileId INTEGER NOT NULL, ' +
            'metricId INTEGER NOT NULL, ' +
            'timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, ' +
            'value REAL NOT NULL, ' +
            'note TEXT, ' +
            'FOREIGN KEY(profileId) REFERENCES Profiles(id), ' +
            'FOREIGN KEY(metricId) REFERENCES Metrics(id))');

        // VACCINES
        tx.executeSql('CREATE TABLE IF NOT EXISTS Vaccines (' +
            'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
            'name TEXT NOT NULL, ' +
            'isMandatory BOOLEAN, ' +
            'boosterCount INTEGER)');

        // INJECTIONS
        tx.executeSql('CREATE TABLE IF NOT EXISTS Injections (' +
            'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
            'profileId INTEGER NOT NULL, ' +
            'vaccineId INTEGER NOT NULL, ' +
            'date DATE NOT NULL, ' +
            'note TEXT, ' +
            'FOREIGN KEY(profileId) REFERENCES Profiles(id), ' +
            'FOREIGN KEY(vaccineId) REFERENCES Vaccines(id))');

        // MEDICATIONS
        tx.executeSql('CREATE TABLE IF NOT EXISTS Medications (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, type TEXT, unit TEXT)');

        // TREATMENT
        tx.executeSql('CREATE TABLE IF NOT EXISTS Treatments (id INTEGER PRIMARY KEY AUTOINCREMENT, profileId INTEGER, medicationId INTEGER, conditionId INTEGER, dosage TEXT, frequency TEXT, startDate TEXT, endDate TEXT, note TEXT)');

        // MODULES
        tx.executeSql('CREATE TABLE IF NOT EXISTS Modules (' +
            'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
            'name TEXT NOT NULL, ' +
            'type TEXT NOT NULL, ' +
            'uses TEXT NOT NULL, ' +
            'unit TEXT NULL, ' +
            'bydefault BOOLEAN DEFAULT TRUE, ' +
            'category TEXT, ' +
            'icon TEXT)');

        // PROFILE MODULES
        tx.executeSql('CREATE TABLE IF NOT EXISTS ProfileModules (' +
            'profileId INTEGER NOT NULL, ' +
            'moduleId INTEGER NOT NULL, ' +
            'PRIMARY KEY(profileId,moduleId) ' +
            'FOREIGN KEY(profileId) REFERENCES Profiles(id), ' +
            'FOREIGN KEY(moduleId) REFERENCES Modules(id))');

        // HEALTH CONDITIONS
        tx.executeSql('CREATE TABLE IF NOT EXISTS HealthConditions (id INTEGER PRIMARY KEY AUTOINCREMENT, profileId INTEGER, name TEXT, status TEXT, startDate TEXT, endDate TEXT, note TEXT)');
        tx.executeSql('CREATE TABLE IF NOT EXISTS MenstrualCycles (id INTEGER PRIMARY KEY AUTOINCREMENT, profileId INTEGER, startDate TEXT, endDate TEXT, note TEXT)');
        tx.executeSql('CREATE TABLE IF NOT EXISTS MenstrualLogs (id INTEGER PRIMARY KEY AUTOINCREMENT, profileId INTEGER, date TEXT, flow TEXT, pain TEXT, energy TEXT, sleepTime REAL, note TEXT)');
        tx.executeSql('CREATE TABLE IF NOT EXISTS MeditationSessions (id INTEGER PRIMARY KEY AUTOINCREMENT, profileId INTEGER, date DATETIME DEFAULT CURRENT_TIMESTAMP, duration INTEGER, name TEXT)');
        tx.executeSql('CREATE TABLE IF NOT EXISTS MedicationLogs (id INTEGER PRIMARY KEY AUTOINCREMENT, profileId INTEGER NOT NULL, medicationId INTEGER NOT NULL, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, note TEXT, FOREIGN KEY(profileId) REFERENCES Profiles(id), FOREIGN KEY(medicationId) REFERENCES Medications(id))');
        tx.executeSql('CREATE TABLE IF NOT EXISTS MetricConstraints (' +
            'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
            'metricName TEXT NOT NULL, ' +
            'label TEXT, ' +
            'minValue REAL, ' +
            'maxValue REAL, ' +
            'color TEXT NOT NULL)');

        // Indexes. Every history, dashboard and chart query filters on these.
        tx.executeSql('CREATE INDEX IF NOT EXISTS idx_healthlogs_lookup ON HealthLogs(profileId, metricId, timestamp)');
        tx.executeSql('CREATE INDEX IF NOT EXISTS idx_medlogs_lookup ON MedicationLogs(profileId, medicationId, timestamp)');
        tx.executeSql('CREATE INDEX IF NOT EXISTS idx_injections_lookup ON Injections(profileId, vaccineId, date)');
        tx.executeSql('CREATE INDEX IF NOT EXISTS idx_treatments_lookup ON Treatments(profileId, conditionId)');
        tx.executeSql('CREATE INDEX IF NOT EXISTS idx_constraints_metric ON MetricConstraints(metricName)');

        // addMenstrualLog() relies on INSERT OR REPLACE, which needs this constraint to
        // do anything at all. Older duplicates are collapsed first so it can be created.
        tx.executeSql('DELETE FROM MenstrualLogs WHERE id NOT IN ' +
            '(SELECT MAX(id) FROM MenstrualLogs GROUP BY profileId, date)');
        tx.executeSql('CREATE UNIQUE INDEX IF NOT EXISTS idx_menstruallogs_day ON MenstrualLogs(profileId, date)');

        // Seed default metrics if empty
        var rsMetrics = tx.executeSql('SELECT count(*) as count FROM Metrics');
        if (rsMetrics.rows.item(0).count === 0) {
            tx.executeSql('INSERT INTO Metrics (name, unit, grouped, category) VALUES (?,?,?,?)', [METRIC_WEIGHT, "kg", false, CATEGORY_BODY]);
            tx.executeSql('INSERT INTO Metrics (name, unit, grouped, category) VALUES (?,?,?,?)', [METRIC_HEIGHT, "cm", false, CATEGORY_BODY]);
            tx.executeSql('INSERT INTO Metrics (name, unit, grouped, category) VALUES (?,?,?,?)', [METRIC_CALORIES, "kcal", true, CATEGORY_NUTRITION]);
            tx.executeSql('INSERT INTO Metrics (name, unit, grouped, category) VALUES (?,?,?,?)', [METRIC_WATER, "L", true, CATEGORY_NUTRITION]);
            tx.executeSql('INSERT INTO Metrics (name, unit, grouped, category) VALUES (?,?,?,?)', [METRIC_HEARTRATE, "bpm", false, CATEGORY_BLOOD]);
            tx.executeSql('INSERT INTO Metrics (name, unit, grouped, category) VALUES (?,?,?,?)', [METRIC_BP_SYS, "mmHg", false, CATEGORY_BLOOD]);
            tx.executeSql('INSERT INTO Metrics (name, unit, grouped, category) VALUES (?,?,?,?)', [METRIC_BP_DIA, "mmHg", false, CATEGORY_BLOOD]);
            tx.executeSql('INSERT INTO Metrics (name, unit, grouped, category) VALUES (?,?,?,?)', [METRIC_GLUCOSE, "mg/dL", false, CATEGORY_BLOOD]);
        }

        // Seed default modules if empty
        var rsModules = tx.executeSql('SELECT count(*) as count FROM Modules');
        if (rsModules.rows.item(0).count === 0) {
            tx.executeSql('INSERT INTO Modules (name, type, uses, bydefault, category, icon) VALUES (?,?,?,?,?,?)', [MODULE_WEIGHT, MODULE_TYPE_METRIC, METRIC_WEIGHT, true, CATEGORY_BODY, "scale.png"]);
            tx.executeSql('INSERT INTO Modules (name, type, uses, bydefault, category, icon) VALUES (?,?,?,?,?,?)', [MODULE_HEIGHT, MODULE_TYPE_METRIC, METRIC_HEIGHT, true, CATEGORY_BODY, "height.png"]);
            tx.executeSql('INSERT INTO Modules (name, type, uses, bydefault, category, icon) VALUES (?,?,?,?,?,?)', [MODULE_BMI, MODULE_TYPE_CALC, "bmi", true, CATEGORY_BODY, "gauge.png"]);
            tx.executeSql('INSERT INTO Modules (name, type, uses, bydefault, category, icon) VALUES (?,?,?,?,?,?)', [MODULE_CALORIES, MODULE_TYPE_METRIC, METRIC_CALORIES, true, CATEGORY_NUTRITION, "fire.png"]);
            tx.executeSql('INSERT INTO Modules (name, type, uses, bydefault, category, icon) VALUES (?,?,?,?,?,?)', [MODULE_WATER, MODULE_TYPE_METRIC, METRIC_WATER, true, CATEGORY_NUTRITION, "water.png"]);
            tx.executeSql('INSERT INTO Modules (name, type, uses, bydefault, category, icon) VALUES (?,?,?,?,?,?)', [MODULE_HEARTRATE, MODULE_TYPE_METRIC, METRIC_HEARTRATE, true, CATEGORY_BLOOD, "heart-pulse.png"]);
            tx.executeSql('INSERT INTO Modules (name, type, uses, bydefault, category, icon) VALUES (?,?,?,?,?,?)', [MODULE_BP, MODULE_TYPE_CALC, "blood-pressure", true, CATEGORY_BLOOD, "blood-pressure.svg"]);
            tx.executeSql('INSERT INTO Modules (name, type, uses, bydefault, category, icon) VALUES (?,?,?,?,?,?)', [MODULE_GLUCOSE, MODULE_TYPE_METRIC, METRIC_GLUCOSE, true, CATEGORY_BLOOD, "diabetes.png"]);
            tx.executeSql('INSERT INTO Modules (name, type, uses, bydefault, category, icon) VALUES (?,?,?,?,?,?)', [MODULE_CONDITION, MODULE_TYPE_SUMMARY, "MainHealthCondition", true, CATEGORY_OTHER, "medical-bag.png"]);
            tx.executeSql('INSERT INTO Modules (name, type, uses, bydefault, category, icon) VALUES (?,?,?,?,?,?)', [MODULE_VACCINATION, MODULE_TYPE_SUMMARY, "VaccinesList", true, CATEGORY_OTHER, "needle.png"]);
            tx.executeSql('INSERT INTO Modules (name, type, uses, bydefault, category, icon) VALUES (?,?,?,?,?,?)', [MODULE_MEDITATION, MODULE_TYPE_SUMMARY, "MeditationMenu", true, CATEGORY_OTHER, "meditation.png"]);
            tx.executeSql('INSERT INTO Modules (name, type, uses, bydefault, category, icon) VALUES (?,?,?,?,?,?)', [MODULE_MENSTRUATION, MODULE_TYPE_SUMMARY, "Menstruation", true, CATEGORY_OTHER, "calendar-heart.png"]);
        }

        seedDefaultConstraints(tx);

        if (!hasSchemaVersion) {
            tx.executeSql('INSERT INTO SchemaInfo (version) VALUES (?)', [DB_SCHEMA_VERSION]);
        }
    });
}

/*
 * Reference bands drawn behind the charts and used to colour dashboard values.
 *
 * These are widely published general reference ranges, not a diagnosis: the About
 * page carries the disclaimer, and every band can be edited or deleted by the user.
 * Guarded per metric, so a new set added in a later release still reaches existing
 * databases -- the BMI bands used to sit inside the "modules are empty" guard and
 * were therefore skipped by anything but a brand new install.
 */
function seedDefaultConstraints(tx) {
    var defaults = {};
    defaults["BMI"] = [
        ["Underweight", null, 18.5, "blue"],
        ["Normal", 18.5, 25.0, "green"],
        ["Overweight", 25.0, 30.0, "orange"],
        ["Obese", 30.0, null, "red"]
    ];
    defaults[METRIC_BP_SYS] = [
        ["Low", null, 90, "blue"],
        ["Normal", 90, 130, "green"],
        ["Elevated", 130, 140, "orange"],
        ["High", 140, null, "red"]
    ];
    defaults[METRIC_BP_DIA] = [
        ["Low", null, 60, "blue"],
        ["Normal", 60, 85, "green"],
        ["Elevated", 85, 90, "orange"],
        ["High", 90, null, "red"]
    ];
    defaults[METRIC_HEARTRATE] = [
        ["Low", null, 50, "blue"],
        ["Normal", 50, 100, "green"],
        ["High", 100, null, "orange"]
    ];

    for (var metric in defaults) {
        var rs = tx.executeSql('SELECT count(*) AS count FROM MetricConstraints WHERE metricName=?', [metric]);
        if (rs.rows.item(0).count > 0) {
            continue;
        }
        var rows = defaults[metric];
        for (var i = 0; i < rows.length; i++) {
            tx.executeSql('INSERT INTO MetricConstraints (metricName, label, minValue, maxValue, color) VALUES (?,?,?,?,?)',
                [metric, rows[i][0], rows[i][1], rows[i][2], rows[i][3]]);
        }
    }
}

// Profile Operations
function countProfiles() {
    var count = 0;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT COUNT(*) AS count FROM Profiles');
        if (rs.rows.length > 0) {
            count = rs.rows.item(0).count;
        }
    });
    return count;
}

function lastUsedProfileId() {
    var id = -1;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT id FROM Profiles ORDER BY lastUsed DESC, id ASC LIMIT 1');
        if (rs.rows.length > 0) {
            id = rs.rows.item(0).id;
        }
    });
    return id;
}

function useProfile(profile_id) {
    db().transaction(function (tx) {
        tx.executeSql('UPDATE Profiles SET lastUsed=? WHERE id=?', [toTimestamp(new Date()), profile_id]);
    });
}

function getProfile(profile_id) {
    var profile;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT id, firstName, lastName, gender, birthDate FROM Profiles WHERE id=?', [profile_id]);
        if (rs.rows.length > 0) {
            profile = rs.rows.item(0);
        }
    });
    return profile;
}

function addProfile(firstName, lastName, gender, birthDate) {
    var id;
    db().transaction(function (tx) {
        var rs = tx.executeSql('INSERT INTO Profiles (firstName, lastName, gender, birthDate) VALUES (?,?,?,?)',
            [firstName, lastName, gender, birthDate]);
        id = rs.insertId;
        tx.executeSql('INSERT INTO ProfileModules (profileId,moduleId) SELECT ?,id FROM Modules WHERE bydefault', [id]);
    });
    return id;
}

function updateProfile(id, firstName, lastName, gender, birthDate) {
    db().transaction(function (tx) {
        tx.executeSql('UPDATE Profiles SET firstName=?, lastName=?, gender=?, birthDate=? WHERE id=?', [firstName, lastName, gender, birthDate, id]);
    });
}

function getCoverMetrics(profileId) {
    var metrics = { metric1: METRIC_WEIGHT, metric2: METRIC_WATER };
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT coverMetric1, coverMetric2 FROM Profiles WHERE id=?', [profileId]);
        if (rs.rows.length > 0) {
            metrics.metric1 = rs.rows.item(0).coverMetric1 || METRIC_WEIGHT;
            metrics.metric2 = rs.rows.item(0).coverMetric2 || METRIC_WATER;
        }
    });
    return metrics;
}

function updateCoverMetrics(profileId, metric1, metric2) {
    db().transaction(function (tx) {
        tx.executeSql('UPDATE Profiles SET coverMetric1=?, coverMetric2=? WHERE id=?',
            [metric1, metric2, profileId]);
    });
}

function deleteProfile(id) {
    db().transaction(function (tx) {
        // Delete all profile-owned records before the profile itself. SQLite does
        // not enable foreign-key cascading by default for LocalStorage databases.
        for (var i = 0; i < PROFILE_TABLES.length; i++) {
            tx.executeSql('DELETE FROM ' + PROFILE_TABLES[i] + ' WHERE profileId=?', [id]);
        }
        tx.executeSql('DELETE FROM Profiles WHERE id=?', [id]);
    });
}

function getProfiles() {
    var profiles = [];
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM Profiles ORDER BY lastUsed DESC, id ASC');
        for (var i = 0; i < rs.rows.length; i++) {
            profiles.push(rs.rows.item(i));
        }
    });
    return profiles;
}

// Metric operations

function getMetricUnit(metricName) {
    var unit;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT unit FROM Metrics WHERE name=?', [metricName]);
        if (rs.rows.length > 0) {
            unit = rs.rows.item(0).unit;
        }
    });
    return unit;
}

function getMetricGrouped(metricName) {
    var grouped = false;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT grouped FROM Metrics WHERE name=?', [metricName]);
        if (rs.rows.length > 0) {
            grouped = rs.rows.item(0).grouped;
        }
    });
    return grouped;
}

function getMetrics() {
    var metrics = [];
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM Metrics ORDER BY category,name');
        for (var i = 0; i < rs.rows.length; i++) {
            metrics.push(rs.rows.item(i));
        }
    });
    return metrics;
}

function getMetricsToModel(a_model) {
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM Metrics ORDER BY category,name');
        a_model.clear();
        for (var i = 0; i < rs.rows.length; i++) {
            a_model.append(rs.rows.item(i));
        }
    });
}

function calculateMetrics(profileId, calculate) {
    if (calculate === "bmi") {
        var bmi = calcBMI(profileId);
        return bmi === null ? null : Math.round(bmi * 10) / 10;
    }
    if (calculate === "blood-pressure") {
        var systolic = getLatestLogValue(profileId, METRIC_BP_SYS);
        var diastolic = getLatestLogValue(profileId, METRIC_BP_DIA);
        if (systolic === null || diastolic === null) {
            return null;
        }
        return systolic + "/" + diastolic;
    }
    return null;
}

// Log Operations
function addLog(profileId, metricName, value, timestamp, note) {
    var inserted = false;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT id FROM Metrics WHERE name=?', [metricName]);
        if (rs.rows.length > 0) {
            var metricId = rs.rows.item(0).id;
            tx.executeSql('INSERT INTO HealthLogs (profileId, metricId, value, timestamp, note) VALUES (?,?,?,?,?)',
                [profileId, metricId, value, toTimestamp(timestamp), note || ""]);
            inserted = true;
        }
    });
    return inserted;
}

function updateLog(id, value, timestamp, note) {
    db().transaction(function (tx) {
        tx.executeSql('UPDATE HealthLogs SET value=?, timestamp=?, note=? WHERE id=?',
            [value, toTimestamp(timestamp), note || "", id]);
    });
}

function getLog(id) {
    var log = null;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT l.*, m.name AS metricName, m.unit FROM HealthLogs l ' +
            'LEFT JOIN Metrics m ON l.metricId = m.id WHERE l.id=?', [id]);
        if (rs.rows.length > 0) {
            log = rs.rows.item(0);
        }
    });
    return log;
}

function deleteLog(id) {
    db().transaction(function (tx) {
        tx.executeSql('DELETE FROM HealthLogs WHERE id=?', [id]);
    });
}

function getLatestLog(profileId, metricName) {
    var log = null;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT l.*, m.unit FROM HealthLogs l LEFT JOIN Metrics m ON l.metricId = m.id ' +
            'WHERE l.profileId=? AND m.name=? ORDER BY l.timestamp DESC LIMIT 1', [profileId, metricName]);
        if (rs.rows.length > 0) {
            log = rs.rows.item(0);
        }
    });
    return log;
}

function getLatestLogValue(profileId, metricName) {
    var value = null;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT l.value FROM HealthLogs l LEFT JOIN Metrics m ON l.metricId = m.id ' +
            'WHERE l.profileId=? AND m.name=? ORDER BY l.timestamp DESC LIMIT 1', [profileId, metricName]);
        if (rs.rows.length > 0) {
            value = rs.rows.item(0).value;
        }
    });
    return value;
}

function getLatestDayLogValue(profileId, metricName) {
    var value = null;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT SUM(l.value) AS total, date(l.timestamp, ?) AS day FROM HealthLogs l LEFT JOIN Metrics m ON l.metricId = m.id ' +
            'WHERE l.profileId=? AND m.name=? GROUP BY day ORDER BY day DESC LIMIT 1', ["-" + DAY_START_TIME, profileId, metricName]);
        if (rs.rows.length > 0) {
            value = rs.rows.item(0).total;
        }
    });
    return value;
}

/*
 * History rows for one metric, newest first.
 *
 * For grouped metrics each row also carries `day` (the 04:00-border day it belongs
 * to) and `dayTotal`, so the section headers no longer have to re-sum the entire
 * model on every binding evaluation.
 */
function addLogsToModel(profileId, metricName, a_model, grouped) {
    db().transaction(function (tx) {
        var rs;
        if (grouped) {
            var border = "-" + DAY_START_TIME;
            rs = tx.executeSql('SELECT l.id, l.timestamp, l.value, l.note, DATE(l.timestamp, ?) AS day, ' +
                '(SELECT SUM(l2.value) FROM HealthLogs l2 WHERE l2.profileId=l.profileId ' +
                'AND l2.metricId=l.metricId AND DATE(l2.timestamp, ?)=DATE(l.timestamp, ?)) AS dayTotal ' +
                'FROM HealthLogs AS l LEFT JOIN Metrics ON l.metricId=Metrics.id ' +
                'WHERE l.profileId=? AND Metrics.name=? ORDER BY l.timestamp DESC',
                [border, border, border, profileId, metricName]);
        }
        else {
            rs = tx.executeSql('SELECT HealthLogs.id, timestamp, value, note FROM HealthLogs ' +
                'LEFT JOIN Metrics ON HealthLogs.metricId=Metrics.id ' +
                'WHERE profileId=? AND Metrics.name=? ORDER BY timestamp DESC', [profileId, metricName]);
        }
        for (var i = 0; i < rs.rows.length; i++) {
            a_model.append(rs.rows.item(i));
        }
    });
}

// Timestamp-ordered logs (oldest first) as a plain array. Used for chart pairing.
function getLogsAscending(profileId, metricName, sinceIso) {
    var logs = [];
    db().transaction(function (tx) {
        var query = 'SELECT l.id, l.timestamp, l.value, l.note FROM HealthLogs l ' +
            'JOIN Metrics m ON l.metricId = m.id WHERE l.profileId=? AND m.name=?';
        var params = [profileId, metricName];
        if (sinceIso) {
            query += ' AND l.timestamp >= ?';
            params.push(sinceIso);
        }
        query += ' ORDER BY l.timestamp ASC';
        var rs = tx.executeSql(query, params);
        for (var i = 0; i < rs.rows.length; i++) {
            logs.push(rs.rows.item(i));
        }
    });
    return logs;
}

/*
 * Chart series: [{t: <ms since epoch>, v: <number>}], oldest first.
 *
 * mode is SERIES_RAW (every reading), SERIES_DAILY_SUM (grouped metrics such as water
 * and calories -- same 04:00 day border the dashboard uses) or SERIES_DAILY_AVG
 * (long ranges, so the canvas never has to plot thousands of points).
 */
function getSeries(profileId, metricName, sinceIso, mode) {
    var points = [];
    db().transaction(function (tx) {
        var query;
        var params;
        var rs;
        var i;

        if (mode === SERIES_DAILY_SUM || mode === SERIES_DAILY_AVG) {
            var agg = (mode === SERIES_DAILY_SUM) ? "SUM" : "AVG";
            query = 'SELECT DATE(l.timestamp, ?) AS day, ' + agg + '(l.value) AS v ' +
                'FROM HealthLogs l JOIN Metrics m ON l.metricId = m.id ' +
                'WHERE l.profileId=? AND m.name=?';
            params = ["-" + DAY_START_TIME, profileId, metricName];
            if (sinceIso) {
                query += ' AND l.timestamp >= ?';
                params.push(sinceIso);
            }
            query += ' GROUP BY day ORDER BY day ASC';
            rs = tx.executeSql(query, params);
            for (i = 0; i < rs.rows.length; i++) {
                points.push({ t: timestampToMs(rs.rows.item(i).day), v: rs.rows.item(i).v });
            }
        } else {
            query = 'SELECT l.timestamp AS ts, l.value AS v FROM HealthLogs l ' +
                'JOIN Metrics m ON l.metricId = m.id WHERE l.profileId=? AND m.name=?';
            params = [profileId, metricName];
            if (sinceIso) {
                query += ' AND l.timestamp >= ?';
                params.push(sinceIso);
            }
            query += ' ORDER BY l.timestamp ASC';
            rs = tx.executeSql(query, params);
            for (i = 0; i < rs.rows.length; i++) {
                points.push({ t: timestampToMs(rs.rows.item(i).ts), v: rs.rows.item(i).v });
            }
        }
    });
    return points;
}

// min / max / average / count over the same window, aggregated by SQLite.
function getSeriesStats(profileId, metricName, sinceIso, mode) {
    var stats = { min: null, max: null, avg: null, count: 0 };
    db().transaction(function (tx) {
        var query;
        var params;

        if (mode === SERIES_DAILY_SUM || mode === SERIES_DAILY_AVG) {
            var agg = (mode === SERIES_DAILY_SUM) ? "SUM" : "AVG";
            var inner = 'SELECT ' + agg + '(l.value) AS v FROM HealthLogs l ' +
                'JOIN Metrics m ON l.metricId = m.id WHERE l.profileId=? AND m.name=?';
            params = [profileId, metricName];
            if (sinceIso) {
                inner += ' AND l.timestamp >= ?';
                params.push(sinceIso);
            }
            inner += ' GROUP BY DATE(l.timestamp, ?)';
            params.push("-" + DAY_START_TIME);
            query = 'SELECT MIN(v) AS mn, MAX(v) AS mx, AVG(v) AS av, COUNT(*) AS ct FROM (' + inner + ')';
        } else {
            query = 'SELECT MIN(l.value) AS mn, MAX(l.value) AS mx, AVG(l.value) AS av, COUNT(*) AS ct ' +
                'FROM HealthLogs l JOIN Metrics m ON l.metricId = m.id WHERE l.profileId=? AND m.name=?';
            params = [profileId, metricName];
            if (sinceIso) {
                query += ' AND l.timestamp >= ?';
                params.push(sinceIso);
            }
        }

        var rs = tx.executeSql(query, params);
        if (rs.rows.length > 0) {
            var row = rs.rows.item(0);
            stats.min = row.mn;
            stats.max = row.mx;
            stats.avg = row.av;
            stats.count = row.ct;
        }
    });
    return stats;
}

// Plain min/max/avg over an already-computed series (BMI, which has no table).
function statsFromPoints(points) {
    var stats = { min: null, max: null, avg: null, count: 0 };
    if (!points || points.length === 0) {
        return stats;
    }
    var total = 0;
    stats.min = points[0].v;
    stats.max = points[0].v;
    for (var i = 0; i < points.length; i++) {
        var v = points[i].v;
        if (v < stats.min) {
            stats.min = v;
        }
        if (v > stats.max) {
            stats.max = v;
        }
        total += v;
    }
    stats.count = points.length;
    stats.avg = total / points.length;
    return stats;
}

// BMI from Logs
function calcBMI(profileId) {
    var height = getLatestLogValue(profileId, METRIC_HEIGHT);
    var weight = getLatestLogValue(profileId, METRIC_WEIGHT);
    if (!height || !weight) {
        return null;
    }
    var squareheight_cm = height * height / 10000;
    return weight / squareheight_cm;
}

/*
 * BMI history: one point per weight reading, using the height that was current at
 * that moment. Both series arrive sorted, so a single merge pass is enough.
 */
function getBMISeries(profileId, sinceIso) {
    // Height changes rarely, so the whole height history is needed even for a short
    // window -- the applicable height may have been recorded long before it.
    var heights = getLogsAscending(profileId, METRIC_HEIGHT, null);
    var weights = getLogsAscending(profileId, METRIC_WEIGHT, sinceIso);
    var points = [];
    if (heights.length === 0) {
        return points;
    }

    var hIndex = 0;
    // Before the first height reading there is nothing better to use than the first one.
    var currentHeight = heights[0].value;
    for (var i = 0; i < weights.length; i++) {
        var w = weights[i];
        var wMs = timestampToMs(w.timestamp);
        while (hIndex < heights.length && timestampToMs(heights[hIndex].timestamp) <= wMs) {
            currentHeight = heights[hIndex].value;
            hIndex++;
        }
        if (!currentHeight || !w.value) {
            continue;
        }
        var metres = currentHeight / 100;
        points.push({ t: wMs, v: Math.round((w.value / (metres * metres)) * 10) / 10 });
    }
    return points;
}

// Vaccine Operations
function getVaccinesToModel(profileId, a_model) {
    a_model.clear();
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT DISTINCT v.* FROM Vaccines v ' +
            'LEFT JOIN Injections i ON v.id = i.vaccineId AND i.profileId = ? ' +
            'WHERE v.isMandatory = 1 OR i.id IS NOT NULL ORDER BY v.name', [profileId]);
        for (var i = 0; i < rs.rows.length; i++) {
            a_model.append(rs.rows.item(i));
        }
    });
}

function getVaccineCount(profileId) {
    var count = 0;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT count(DISTINCT v.id) as count FROM Vaccines v ' +
            'INNER JOIN Injections i ON v.id = i.vaccineId WHERE i.profileId = ?', [profileId]);
        count = rs.rows.item(0).count;
    });
    return count;
}

function getOrCreateVaccine(name, isMandatory) {
    var id;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT id FROM Vaccines WHERE name=? COLLATE NOCASE', [name]);
        if (rs.rows.length > 0) {
            id = rs.rows.item(0).id;
        } else {
            var rs2 = tx.executeSql('INSERT INTO Vaccines (name, isMandatory) VALUES (?,?)', [name, isMandatory ? 1 : 0]);
            id = rs2.insertId;
        }
    });
    return id;
}

function addVaccineLog(profileId, vaccineId, date, note) {
    db().transaction(function (tx) {
        tx.executeSql('INSERT INTO Injections (profileId, vaccineId, date, note) VALUES (?, ?, ?, ?)', [profileId, vaccineId, date, note || ""]);
    });
}

function deleteVaccineLog(id) {
    db().transaction(function (tx) {
        tx.executeSql('DELETE FROM Injections WHERE id=?', [id]);
    });
}

function getVaccineLogsToModel(profileId, vaccineId, a_model) {
    a_model.clear();
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM Injections WHERE profileId=? AND vaccineId=? ORDER BY date DESC', [profileId, vaccineId]);
        for (var i = 0; i < rs.rows.length; i++) {
            a_model.append(rs.rows.item(i));
        }
    });
}

// Medication & Treatment Operations
function getMedications(profileId) {
    var medications = [];
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT DISTINCT m.* FROM Medications m ' +
            'JOIN Treatments t ON m.id = t.medicationId ' +
            'WHERE t.profileId = ? ORDER BY m.name', [profileId]);
        for (var i = 0; i < rs.rows.length; i++) {
            medications.push(rs.rows.item(i));
        }
    });
    return medications;
}

function addMedication(name, type, unit) {
    var medicationId = 0;
    db().transaction(function (tx) {
        var rs = tx.executeSql('INSERT INTO Medications (name, type, unit) VALUES (?, ?, ?)', [name, type, unit]);
        medicationId = rs.insertId;
    });
    return medicationId;
}

function getTreatments(profileId, medicationId, conditionId) {
    var treatments = [];
    db().transaction(function (tx) {
        var query = 'SELECT t.*, m.name as medicationName FROM Treatments t JOIN Medications m ON t.medicationId = m.id WHERE t.profileId=?';
        var params = [profileId];
        if (medicationId !== undefined && medicationId !== -1) {
            query += ' AND t.medicationId=?';
            params.push(medicationId);
        }
        if (conditionId !== undefined && conditionId !== -1) {
            query += ' AND t.conditionId=?';
            params.push(conditionId);
        }
        query += ' ORDER BY t.startDate DESC';
        var rs = tx.executeSql(query, params);
        for (var i = 0; i < rs.rows.length; i++) {
            treatments.push(rs.rows.item(i));
        }
    });
    return treatments;
}

function getTreatment(id) {
    var treatment = null;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT t.*, m.name AS medicationName FROM Treatments t ' +
            'JOIN Medications m ON t.medicationId = m.id WHERE t.id=?', [id]);
        if (rs.rows.length > 0) {
            treatment = rs.rows.item(0);
        }
    });
    return treatment;
}

function addTreatment(profileId, medicationId, conditionId, dosage, frequency, startDate, endDate, note) {
    db().transaction(function (tx) {
        tx.executeSql('INSERT INTO Treatments (profileId, medicationId, conditionId, dosage, frequency, startDate, endDate, note) ' +
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?)', [profileId, medicationId, conditionId, dosage, frequency, startDate, endDate, note]);
    });
}

function updateTreatment(id, dosage, frequency, startDate, endDate, note) {
    db().transaction(function (tx) {
        tx.executeSql('UPDATE Treatments SET dosage=?, frequency=?, startDate=?, endDate=?, note=? WHERE id=?',
            [dosage, frequency, startDate, endDate, note, id]);
    });
}

function deleteTreatment(id) {
    db().transaction(function (tx) {
        tx.executeSql('DELETE FROM Treatments WHERE id=?', [id]);
    });
}

// Condition Operations
function getConditions(profileId) {
    var conditions = [];
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM HealthConditions WHERE profileId=? ORDER BY startDate DESC', [profileId]);
        for (var i = 0; i < rs.rows.length; i++) {
            conditions.push(rs.rows.item(i));
        }
    });
    return conditions;
}

function getCondition(id) {
    var condition = null;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM HealthConditions WHERE id=?', [id]);
        if (rs.rows.length > 0) {
            condition = rs.rows.item(0);
        }
    });
    return condition;
}

function updateCondition(id, name, status, startDate, endDate, note) {
    db().transaction(function (tx) {
        tx.executeSql('UPDATE HealthConditions SET name=?, status=?, startDate=?, endDate=?, note=? WHERE id=?', [name, status, startDate, endDate, note, id]);
    });
}

function addCondition(profileId, name, status, startDate, endDate, note) {
    db().transaction(function (tx) {
        tx.executeSql('INSERT INTO HealthConditions (profileId, name, status, startDate, endDate, note) ' +
            'VALUES (?, ?, ?, ?, ?, ?)', [profileId, name, status, startDate, endDate, note]);
    });
}

function deleteCondition(id) {
    db().transaction(function (tx) {
        // Treatments hang off the condition and would otherwise be orphaned.
        tx.executeSql('DELETE FROM Treatments WHERE conditionId=?', [id]);
        tx.executeSql('DELETE FROM HealthConditions WHERE id=?', [id]);
    });
}

// Menstrual Operations
function getMenstrualCycles(profileId) {
    var cycles = [];
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM MenstrualCycles WHERE profileId=? ORDER BY startDate DESC', [profileId]);
        for (var i = 0; i < rs.rows.length; i++) {
            cycles.push(rs.rows.item(i));
        }
    });
    return cycles;
}

function addMenstrualCycle(profileId, startDate, endDate, note) {
    db().transaction(function (tx) {
        tx.executeSql('INSERT INTO MenstrualCycles (profileId, startDate, endDate, note) VALUES (?, ?, ?, ?)', [profileId, startDate, endDate, note]);
    });
}

function updateMenstrualCycle(id, startDate, endDate, note) {
    db().transaction(function (tx) {
        tx.executeSql('UPDATE MenstrualCycles SET startDate=?, endDate=?, note=? WHERE id=?', [startDate, endDate, note, id]);
    });
}

function deleteMenstrualCycle(id) {
    db().transaction(function (tx) {
        tx.executeSql('DELETE FROM MenstrualCycles WHERE id=?', [id]);
    });
}

function getMenstrualLogs(profileId, date) {
    var logs = [];
    db().transaction(function (tx) {
        var query = 'SELECT * FROM MenstrualLogs WHERE profileId=?';
        var params = [profileId];
        if (date) {
            query += ' AND date=?';
            params.push(date);
        }
        query += ' ORDER BY date DESC';
        var rs = tx.executeSql(query, params);
        for (var i = 0; i < rs.rows.length; i++) {
            logs.push(rs.rows.item(i));
        }
    });
    return logs;
}

function addMenstrualLog(profileId, date, flow, pain, energy, sleepTime, note) {
    db().transaction(function (tx) {
        // Replaces any existing entry for the same day (see idx_menstruallogs_day).
        tx.executeSql('INSERT OR REPLACE INTO MenstrualLogs (profileId, date, flow, pain, energy, sleepTime, note) ' +
            'VALUES (?, ?, ?, ?, ?, ?, ?)', [profileId, date, flow, pain, energy, sleepTime, note]);
    });
}

/*
 * Average number of days between consecutive cycle starts. null until there are at
 * least two cycles to measure between.
 */
function getAverageCycleLength(profileId) {
    var cycles = getMenstrualCycles(profileId);
    if (cycles.length < 2) {
        return null;
    }
    var total = 0;
    var samples = 0;
    // Ordered newest first, so each pair is (newer, older).
    for (var i = 0; i < cycles.length - 1; i++) {
        var newer = timestampToMs(cycles[i].startDate);
        var older = timestampToMs(cycles[i + 1].startDate);
        if (isNaN(newer) || isNaN(older)) {
            continue;
        }
        var days = Math.round((newer - older) / 86400000);
        // Ignore implausible gaps rather than letting one bad row skew the average.
        if (days > 0 && days < 180) {
            total += days;
            samples++;
        }
    }
    return samples === 0 ? null : Math.round(total / samples);
}

// Meditation Operations
function getMeditationSessions(profileId) {
    var sessions = [];
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM MeditationSessions WHERE profileId=? ORDER BY date DESC', [profileId]);
        for (var i = 0; i < rs.rows.length; i++) {
            sessions.push(rs.rows.item(i));
        }
    });
    return sessions;
}

// duration is stored in seconds.
function addMeditationSession(profileId, duration, name, date) {
    db().transaction(function (tx) {
        tx.executeSql('INSERT INTO MeditationSessions (profileId, duration, name, date) VALUES (?, ?, ?, ?)',
            [profileId, duration, name, toTimestamp(date)]);
    });
}

function deleteMeditationSession(id) {
    db().transaction(function (tx) {
        tx.executeSql('DELETE FROM MeditationSessions WHERE id=?', [id]);
    });
}

function deleteMeditationHistory(profileId) {
    db().transaction(function (tx) {
        tx.executeSql('DELETE FROM MeditationSessions WHERE profileId=?', [profileId]);
    });
}

// Medication Log Operations
function addMedicationLog(profileId, medicationId, timestamp, note) {
    db().transaction(function (tx) {
        tx.executeSql('INSERT INTO MedicationLogs (profileId, medicationId, timestamp, note) VALUES (?, ?, ?, ?)',
            [profileId, medicationId, toTimestamp(timestamp), note || ""]);
    });
}

function deleteMedicationLog(id) {
    db().transaction(function (tx) {
        tx.executeSql('DELETE FROM MedicationLogs WHERE id=?', [id]);
    });
}

function getMedicationLogsToday(profileId, medicationId) {
    var logs = [];
    db().transaction(function (tx) {
        // Timestamps are local, so "today" has to be local too -- date('now') is UTC.
        var rs = tx.executeSql(
            "SELECT * FROM MedicationLogs WHERE profileId=? AND medicationId=? " +
            "AND date(timestamp)=date('now','localtime') ORDER BY timestamp DESC",
            [profileId, medicationId]);
        for (var i = 0; i < rs.rows.length; i++) {
            logs.push(rs.rows.item(i));
        }
    });
    return logs;
}

function getMedicationLogsHistory(profileId, medicationId) {
    var logs = [];
    db().transaction(function (tx) {
        var rs = tx.executeSql(
            'SELECT * FROM MedicationLogs WHERE profileId=? AND medicationId=? ORDER BY timestamp DESC',
            [profileId, medicationId]);
        for (var i = 0; i < rs.rows.length; i++) {
            logs.push(rs.rows.item(i));
        }
    });
    return logs;
}

// Module Settings
function addModulesToModel(profileId, a_model, on_only) {
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT id,name,type,category,uses,icon,( SELECT ProfileModules.profileId FROM ProfileModules WHERE Modules.id=ProfileModules.moduleId AND ProfileModules.profileId=? ) IS NOT NULL AS is_on FROM Modules ' + (on_only ? 'WHERE is_on' : '') + ' ORDER BY category,name', [profileId]);
        for (var i = 0; i < rs.rows.length; i++) {
            a_model.append(rs.rows.item(i));
        }
    });
}

function addProfileModule(profileId, moduleId) {
    db().transaction(function (tx) {
        tx.executeSql('INSERT OR IGNORE INTO ProfileModules (profileId, moduleId) VALUES (?, ?)', [profileId, moduleId]);
    });
}

function removeProfileModule(profileId, moduleId) {
    db().transaction(function (tx) {
        tx.executeSql('DELETE FROM ProfileModules WHERE profileId=? AND moduleId=?', [profileId, moduleId]);
    });
}

// Constraints
function getConstraintsForMetric(metricName) {
    var constraints = [];
    db().transaction(function (tx) {
        // NULL minimum means "no lower bound", so it has to sort first.
        var rs = tx.executeSql('SELECT * FROM MetricConstraints WHERE metricName=? ' +
            'ORDER BY minValue IS NOT NULL, minValue ASC', [metricName]);
        for (var i = 0; i < rs.rows.length; i++) {
            constraints.push(rs.rows.item(i));
        }
    });
    return constraints;
}

/*
 * The band a value falls into, as {label, color}, or null. Single implementation --
 * the dashboard card used to carry its own copy of this loop.
 */
function matchConstraint(metricName, value) {
    if (value === null || value === undefined || value === "" || isNaN(value)) {
        return null;
    }
    var val = parseFloat(value);
    var constraints = getConstraintsForMetric(metricName);
    for (var i = 0; i < constraints.length; i++) {
        var c = constraints[i];
        if ((c.minValue === null || val >= c.minValue) && (c.maxValue === null || val < c.maxValue)) {
            return { label: c.label || "", color: c.color };
        }
    }
    return null;
}

function addConstraint(metricName, label, minValue, maxValue, color) {
    db().transaction(function (tx) {
        tx.executeSql('INSERT INTO MetricConstraints (metricName, label, minValue, maxValue, color) VALUES (?,?,?,?,?)',
            [metricName, label, minValue, maxValue, color]);
    });
}

function updateConstraint(id, label, minValue, maxValue, color) {
    db().transaction(function (tx) {
        tx.executeSql('UPDATE MetricConstraints SET label=?, minValue=?, maxValue=?, color=? WHERE id=?',
            [label, minValue, maxValue, color, id]);
    });
}

function deleteConstraint(id) {
    db().transaction(function (tx) {
        tx.executeSql('DELETE FROM MetricConstraints WHERE id=?', [id]);
    });
}

/*
 * Export / restore
 *
 * exportAll() returns every row of every table as plain objects, so the JSON backup
 * is a faithful copy including primary keys -- which is what lets restoreAll() put
 * the cross-table references back exactly as they were.
 */
function exportAll() {
    var dump = {
        format: "harbour-health-backup",
        schemaVersion: DB_SCHEMA_VERSION,
        exportedAt: toTimestamp(new Date()),
        tables: {}
    };
    db().transaction(function (tx) {
        for (var i = 0; i < ALL_TABLES.length; i++) {
            var table = ALL_TABLES[i];
            var rows = [];
            var rs = tx.executeSql('SELECT * FROM ' + table);
            for (var j = 0; j < rs.rows.length; j++) {
                var item = rs.rows.item(j);
                var plain = {};
                for (var key in item) {
                    plain[key] = item[key];
                }
                rows.push(plain);
            }
            dump.tables[table] = rows;
        }
    });
    return dump;
}

// Flat CSV of every measurement, for spreadsheets.
function exportMeasurementsCsv() {
    function quote(v) {
        if (v === null || v === undefined) {
            return "";
        }
        return '"' + String(v).replace(/"/g, '""') + '"';
    }

    var lines = ["profile,metric,unit,timestamp,value,note"];
    db().transaction(function (tx) {
        var rs = tx.executeSql("SELECT p.firstName || ' ' || p.lastName AS profile, " +
            'm.name AS metric, m.unit AS unit, l.timestamp AS ts, l.value AS value, l.note AS note ' +
            'FROM HealthLogs l JOIN Metrics m ON l.metricId = m.id ' +
            'JOIN Profiles p ON l.profileId = p.id ORDER BY p.id, m.name, l.timestamp');
        for (var i = 0; i < rs.rows.length; i++) {
            var r = rs.rows.item(i);
            lines.push([quote(r.profile), quote(r.metric), quote(r.unit),
                        quote(r.ts), quote(r.value), quote(r.note)].join(","));
        }
    });
    return lines.join("\n") + "\n";
}

/*
 * Replaces the entire database contents with a previous export.
 *
 * Destructive by design and guarded in the UI. Everything happens in one
 * transaction, so a malformed backup leaves the existing data untouched.
 */
function restoreAll(dump) {
    if (!dump || dump.format !== "harbour-health-backup" || !dump.tables) {
        throw new Error("Not a Health backup file");
    }
    if (dump.schemaVersion > DB_SCHEMA_VERSION) {
        throw new Error("This backup was made by a newer version of Health");
    }

    db().transaction(function (tx) {
        var i;
        // Children first, so nothing references a row that is already gone.
        for (i = ALL_TABLES.length - 1; i >= 0; i--) {
            tx.executeSql('DELETE FROM ' + ALL_TABLES[i]);
        }
        for (i = 0; i < ALL_TABLES.length; i++) {
            var table = ALL_TABLES[i];
            var rows = dump.tables[table];
            if (!rows || rows.length === 0) {
                continue;
            }
            for (var j = 0; j < rows.length; j++) {
                var row = rows[j];
                var columns = [];
                var placeholders = [];
                var values = [];
                for (var column in row) {
                    columns.push(column);
                    placeholders.push("?");
                    values.push(row[column]);
                }
                if (columns.length === 0) {
                    continue;
                }
                tx.executeSql('INSERT OR REPLACE INTO ' + table + ' (' + columns.join(",") +
                    ') VALUES (' + placeholders.join(",") + ')', values);
            }
        }
    });
}

// vim:et:ts=4:sw=4
