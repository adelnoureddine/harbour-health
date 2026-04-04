.pragma library
.import QtQuick.LocalStorage 2.0 as Sql

// Database constants
var DB_NAME = "HarbourHealth";
var DB_VERSION = "2.0";
var DB_DESCRIPTION = "Harbour Health Application Database";
var DB_SIZE = 1000000;

// Metrics
var METRIC_WEIGHT = "weight";
var METRIC_HEIGHT = "height";
var METRIC_WATER = "water";
var METRIC_CALORIES = "calories";

// local time day border -> 04:00:00
var DAY_START_TIME = "04:00:00";

function allFields(data) {
    var fields = [];
    for (var i in data) {
        for (var index in data[i]) {
            if (fields.indexOf(index) < 0) {
                fields.push(index);
            }
        }
    }
    return fields;
}

function getValues(o) {
    var results = [];
    for (var k in o) {
        results.push(o[k]);
    }
    return results;
}

function debugDB(q, headers) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var data = [];
    db.transaction(function (tx) {
        var rs = tx.executeSql(q);
        for (var i = 0; i < rs.rows.length; i++) {
            data.push(rs.rows.item(i));
        }
    });
    if (headers) {
        var fields = allFields(data);
        var o = {};
        for (var i in fields) {
            o[fields[i]] = fields[i];
        }
        data.unshift(o);
    }
    return data;
}

function debugDBToModel(q, a_model) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        var rs = tx.executeSql(q);
        var fields = [];
        a_model.clear();
        for (var i = 0; i < rs.rows.length; i++) {
            for (var k in rs.rows.item(i)) {
                if (fields.indexOf(k) < 0) {
                    fields.push(k);
                }
            }
            a_model.append({line: getValues(rs.rows.item(i)).join(',')});
        }
        a_model.insert(0, {line: "fields: " + fields.join(',')})
    });
}

function modelItemMatchFilter(item, a_filter) {
    for (var k in a_filter) {
        if (item[k] != a_filter[k]) {
            return false;
        }
    }
    return true;
}

function filteredSumFromModel(a_model, a_filter, a_field) {
    var total = 0;
    // loop through model, filter on the dict fields, and summate
    for (var i = 0; i < a_model.count; i++) {
        var item = a_model.get(i);
        if (modelItemMatchFilter(item, a_filter)) {
            total += item[a_field];
        }
    }
    return total;
}

// Initialize the database and tables
function init() {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        // PROFILES
        tx.executeSql('CREATE TABLE IF NOT EXISTS Profiles (' +
            'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
            'firstName TEXT NOT NULL, ' +
            'lastName TEXT NOT NULL, ' +
            'gender TEXT NOT NULL, ' +
            'birthDate DATE NOT NULL, ' +
            'created DATETIME DEFAULT CURRENT_TIMESTAMP, ' +
            'lastUsed DATETIME)');

        // METRICS Definitions
        tx.executeSql('CREATE TABLE IF NOT EXISTS Metrics (' +
            'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
            'name TEXT NOT NULL, ' +
            'unit TEXT NOT NULL, ' +
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

        // HEALTH CONDITIONS
        tx.executeSql('CREATE TABLE IF NOT EXISTS HealthConditions (id INTEGER PRIMARY KEY AUTOINCREMENT, profileId INTEGER, name TEXT, status TEXT, startDate TEXT, endDate TEXT, note TEXT)');
        tx.executeSql('CREATE TABLE IF NOT EXISTS MenstrualCycles (id INTEGER PRIMARY KEY AUTOINCREMENT, profileId INTEGER, startDate TEXT, endDate TEXT, note TEXT)');
        tx.executeSql('CREATE TABLE IF NOT EXISTS MenstrualLogs (id INTEGER PRIMARY KEY AUTOINCREMENT, profileId INTEGER, date TEXT, flow TEXT, pain TEXT, energy TEXT, sleepTime REAL, note TEXT)');
        tx.executeSql('CREATE TABLE IF NOT EXISTS MeditationSessions (id INTEGER PRIMARY KEY AUTOINCREMENT, profileId INTEGER, date DATETIME DEFAULT CURRENT_TIMESTAMP, duration INTEGER, name TEXT)');

        // Seed default metrics if empty
        var rs = tx.executeSql('SELECT count(*) as count FROM Metrics');
        if (rs.rows.item(0).count === 0) {
            tx.executeSql('INSERT INTO Metrics (name, unit, category) VALUES (?,?,?)', [METRIC_WEIGHT, "kg", "Body"]);
            tx.executeSql('INSERT INTO Metrics (name, unit, category) VALUES (?,?,?)', [METRIC_HEIGHT, "cm", "Body"]);
            tx.executeSql('INSERT INTO Metrics (name, unit, category) VALUES (?,?,?)', [METRIC_CALORIES, "kcal", "Nutrition"]);
            tx.executeSql('INSERT INTO Metrics (name, unit, category) VALUES (?,?,?)', [METRIC_WATER, "l", "Nutrition"]);
        }
    });
}

// Profile Operations
function countProfiles() {
    var count = 0;
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(
        function(tx){
            var rs = tx.executeSql('SELECT COUNT(*) AS count FROM Profiles');
            if (rs.rows.length > 0) {
                count = rs.rows.item(0).count;
            }
        }
    )
    return count;
}

function lastUsedProfileId() {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var id = -1;
    db.transaction(
        function(tx){
            var rs = tx.executeSql('SELECT id FROM Profiles ORDER BY lastUsed DESC LIMIT 1');
            if (rs.rows.length > 0) {
                id = rs.rows.item(0).id;
            }
        }
    )
    return id;
}

function useProfile(profile_id) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(
        function(tx){
            tx.executeSql('UPDATE Profiles SET lastUsed=CURRENT_TIMESTAMP WHERE id=?', [profile_id]);
        }
    )
}

function getProfile(profile_id) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var profile;
    db.transaction(
        function(tx){
            var rs = tx.executeSql('SELECT id, firstname, lastname, gender, birthDate FROM Profiles WHERE id=?', [profile_id]);
	        if (rs.rows.length > 0) {
	            profile = rs.rows.item(0);
	        }
	    }
    );
    return profile;
}

function loadAllProfiles(a_model) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(
        function(tx){
            var rs = tx.executeSql('SELECT id, firstname, lastname, birthDate FROM Profiles')
            for (var i = 0; i < rs.rows.length; i++) {
                a_model.append(rs.rows.item(i));
            }
        }
    )
}

function addProfile(firstName, lastName, gender, birthDate) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var id;
    db.transaction(function (tx) {
        var rs = tx.executeSql('INSERT INTO Profiles (firstName, lastName, gender, birthDate) VALUES (?,?,?,?)',
            [firstName, lastName, gender, birthDate]);
        id = rs.insertId;
    });
    return id;
}

function updateProfile(id, firstName, lastName, gender, birthDate) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        tx.executeSql('UPDATE Profiles SET firstName=?, lastName=?, gender=?, birthDate=? WHERE id=?', [firstName, lastName, gender, birthDate, id]);
    });
}

function deleteProfile(id) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        tx.executeSql('DELETE FROM Profiles WHERE id=?', [id]);
        tx.executeSql('DELETE FROM HealthLogs WHERE profileId=?', [id]);
        tx.executeSql('DELETE FROM Injections WHERE profileId=?', [id]);
        tx.executeSql('DELETE FROM Treatments WHERE profileId=?', [id]);
        tx.executeSql('DELETE FROM HealthConditions WHERE profileId=?', [id]);
        tx.executeSql('DELETE FROM MenstrualCycles WHERE profileId=?', [id]);
        tx.executeSql('DELETE FROM MenstrualLogs WHERE profileId=?', [id]);
        tx.executeSql('DELETE FROM MeditationSessions WHERE profileId=?', [id]);
    });
}

function getProfiles() {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var profiles = [];
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM Profiles ORDER BY lastUsed DESC');
        for (var i = 0; i < rs.rows.length; i++) {
            profiles.push(rs.rows.item(i));
        }
    });
    return profiles;
}

// Metric operations

function getMetricId(metricName) {
    var id;
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT id FROM Metrics WHERE name=?', [metricName]);
        if (rs.rows.length > 0) {
            id = rs.rows.item(0).id;
        }
    });
    return id;
}

function getMetricUnit(metricName) {
    var unit;
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT unit FROM Metrics WHERE name=?', [metricName]);
        if (rs.rows.length > 0) {
            unit = rs.rows.item(0).unit;
        }
    });
    return unit;
}

function getMetrics() {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var metrics = [];
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM Metrics');
        for (var i = 0; i < rs.rows.length; i++) {
            metrics.push(rs.rows.item(i));
        }
    });
    return metrics;
}

function getMetricsToModel(a_model) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT id,name,unit FROM Metrics');
        a_model.clear();
        for (var i = 0; i < rs.rows.length; i++) {
            a_model.append(rs.rows.item(i));
        }
    });
}

// Log Operations
function addLog(profileId, metricName, value, timestamp, note) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT id FROM Metrics WHERE name=?', [metricName]);
        print("found " + metricName + ": " + rs.rows.length);
        if (rs.rows.length > 0) {
            var metricId = rs.rows.item(0).id;
            print("found " + metricName + " = " + metricId);
            var rs2 = tx.executeSql('INSERT INTO HealthLogs (profileId, metricId, value, timestamp, note) VALUES (?,?,?,?,?)',
                [profileId, metricId, value, timestamp, note || ""]);
            var id = rs2.insertId;
            print("inserted: " + id);
        }
    });
}

function deleteLog(id) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        print("deleting from logs: " + id);
        tx.executeSql('DELETE FROM HealthLogs WHERE id=?', [id]);
    });
}

function getLatestLog(profileId, metricName) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var log = null;
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT l.*, m.unit FROM HealthLogs l LEFT JOIN Metrics m ON l.metricId = m.id ' +
            'WHERE l.profileId=? AND m.name=? ORDER BY l.timestamp DESC LIMIT 1', [profileId, metricName]);
        if (rs.rows.length > 0) {
            log = rs.rows.item(0);
        }
    });
    return log;
}

function getLatestLogValue(profileId, metricName) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var value = null;
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT l.value FROM HealthLogs l LEFT JOIN Metrics m ON l.metricId = m.id ' +
            'WHERE l.profileId=? AND m.name=? ORDER BY l.timestamp DESC LIMIT 1', [profileId, metricName]);
        if (rs.rows.length > 0) {
            value = rs.rows.item(0).value;
        }
    });
    return value;
}

function getLatestDayLogValue(profileId, metricName) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var value = null;
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT SUM(l.value) AS total, date(l.timestamp, ?) AS day FROM HealthLogs l LEFT JOIN Metrics m ON l.metricId = m.id ' +
            'WHERE l.profileId=? AND m.name=? GROUP BY day ORDER BY day DESC LIMIT 1', ["-" + DAY_START_TIME, profileId, metricName]);
        if (rs.rows.length > 0) {
            print("day " + rs.rows.item(0).day + " has " + rs.rows.item(0).total);
            value = rs.rows.item(0).total;
        }
    });
    return value;
}

function getLatestLogText(profileId, metricName) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var text = "";
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT (l.value || m.unit) AS text FROM HealthLogs l LEFT JOIN Metrics m ON l.metricId = m.id ' +
            'WHERE l.profileId=? AND m.name=? ORDER BY l.timestamp DESC LIMIT 1', [profileId, metricName]);
        if (rs.rows.length > 0) {
            text = rs.rows.item(0).text;
        }
    });
    return text;
}

function addLogsToModel(profileId, metricName, a_model) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT HealthLogs.id,timestamp,value FROM HealthLogs LEFT JOIN Metrics ON HealthLogs.MetricId=Metrics.id WHERE profileId=? AND Metrics.name=? ORDER BY timestamp DESC', [profileId, metricName]);
        print("found logs for " + metricName + ": " + rs.rows.length);
        for (var i = 0; i < rs.rows.length; i++) {
            a_model.append(rs.rows.item(i));
        }
    });
}

function addDayLogsToModel(profileId, metricName, a_model) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT DATE(l.timestamp, ?) AS day,l.id,timestamp,l.value FROM HealthLogs AS l LEFT JOIN Metrics ON l.MetricId=Metrics.id WHERE l.profileId=? AND Metrics.name=? ORDER BY timestamp DESC', ["-" + DAY_START_TIME, profileId, metricName]);
        print("found day logs for " + metricName + ": " + rs.rows.length);
        for (var i = 0; i < rs.rows.length; i++) {
            a_model.append(rs.rows.item(i));
        }
    });
}

function getLogs(profileId, metricId) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var logs = [];
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM HealthLogs WHERE profileId=? AND metricId=? ORDER BY timestamp DESC', [profileId, metricId]);
        for (var i = 0; i < rs.rows.length; i++) {
            logs.push(rs.rows.item(i));
        }
    });
    return logs;
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

// Vaccine Operations
function getVaccines(profileId) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var vaccines = [];
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT DISTINCT v.* FROM Vaccines v ' +
            'LEFT JOIN Injections i ON v.id = i.vaccineId AND i.profileId = ? ' +
            'WHERE v.isMandatory = 1 OR i.id IS NOT NULL', [profileId]);
        for (var i = 0; i < rs.rows.length; i++) {
            vaccines.push(rs.rows.item(i));
        }
    });
    return vaccines;
}

function getVaccinesToModel(profileId, a_model) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    a_model.clear();
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT DISTINCT v.* FROM Vaccines v ' +
            'LEFT JOIN Injections i ON v.id = i.vaccineId AND i.profileId = ? ' +
            'WHERE v.isMandatory = 1 OR i.id IS NOT NULL', [profileId]);
        for (var i = 0; i < rs.rows.length; i++) {
            a_model.append(rs.rows.item(i));
        }
    });
}

function getVaccineCount(profileId) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var count = 0;
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT count(DISTINCT v.id) as count FROM Vaccines v ' +
            'INNER JOIN Injections i ON v.id = i.vaccineId WHERE i.profileId = ?', [profileId]);
        count = rs.rows.item(0).count;
    });
    return count;
}

function getOrCreateVaccine(name, isMandatory) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var id;
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT id FROM Vaccines WHERE name=?', [name]);
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
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        tx.executeSql('INSERT INTO Injections (profileId, vaccineId, date, note) VALUES (?, ?, ?, ?)', [profileId, vaccineId, date, note]);
    });
}

function getVaccineLogs(profileId, vaccineId) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var logs = [];
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM Injections WHERE profileId=? AND vaccineId=? ORDER BY date DESC', [profileId, vaccineId]);
        for (var i = 0; i < rs.rows.length; i++) {
            logs.push(rs.rows.item(i));
        }
    });
    return logs;
}

function getVaccineLogsToModel(profileId, vaccineId, a_model) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    a_model.clear();
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM Injections WHERE profileId=? AND vaccineId=? ORDER BY date DESC', [profileId, vaccineId]);
        for (var i = 0; i < rs.rows.length; i++) {
            a_model.append(rs.rows.item(i));
        }
    });
}

// Medication & Treatment Operations
function getMedications(profileId) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var medications = [];
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT DISTINCT m.* FROM Medications m ' +
            'JOIN Treatments t ON m.id = t.medicationId ' +
            'WHERE t.profileId = ?', [profileId]);
        for (var i = 0; i < rs.rows.length; i++) {
            medications.push(rs.rows.item(i));
        }
    });
    return medications;
}

function addMedication(name, type, unit) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var medicationId = 0;
    db.transaction(function (tx) {
        var rs = tx.executeSql('INSERT INTO Medications (name, type, unit) VALUES (?, ?, ?)', [name, type, unit]);
        medicationId = rs.insertId;
    });
    return medicationId;
}

function getTreatments(profileId, medicationId, conditionId) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var treatments = [];
    db.transaction(function (tx) {
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

function addTreatment(profileId, medicationId, conditionId, dosage, frequency, startDate, endDate, note) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        tx.executeSql('INSERT INTO Treatments (profileId, medicationId, conditionId, dosage, frequency, startDate, endDate, note) ' +
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?)', [profileId, medicationId, conditionId, dosage, frequency, startDate, endDate, note]);
    });
}

// Condition Operations
function getConditions(profileId) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var conditions = [];
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM HealthConditions WHERE profileId=? ORDER BY startDate DESC', [profileId]);
        for (var i = 0; i < rs.rows.length; i++) {
            conditions.push(rs.rows.item(i));
        }
    });
    return conditions;
}

function getCondition(id) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var condition = null;
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM HealthConditions WHERE id=?', [id]);
        if (rs.rows.length > 0) {
            condition = rs.rows.item(0);
        }
    });
    return condition;
}

function updateCondition(id, name, status, startDate, endDate, note) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        tx.executeSql('UPDATE HealthConditions SET name=?, status=?, startDate=?, endDate=?, note=? WHERE id=?', [name, status, startDate, endDate, note, id]);
    });
}

function addCondition(profileId, name, status, startDate, endDate, note) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        tx.executeSql('INSERT INTO HealthConditions (profileId, name, status, startDate, endDate, note) ' +
            'VALUES (?, ?, ?, ?, ?, ?)', [profileId, name, status, startDate, endDate, note]);
    });
}

// Menstrual Operations
function getMenstrualCycles(profileId) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var cycles = [];
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM MenstrualCycles WHERE profileId=? ORDER BY startDate DESC', [profileId]);
        for (var i = 0; i < rs.rows.length; i++) {
            cycles.push(rs.rows.item(i));
        }
    });
    return cycles;
}

function addMenstrualCycle(profileId, startDate, endDate, note) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        tx.executeSql('INSERT INTO MenstrualCycles (profileId, startDate, endDate, note) VALUES (?, ?, ?, ?)', [profileId, startDate, endDate, note]);
    });
}

function getMenstrualLogs(profileId, date) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var logs = [];
    db.transaction(function (tx) {
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
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        tx.executeSql('INSERT OR REPLACE INTO MenstrualLogs (profileId, date, flow, pain, energy, sleepTime, note) ' +
            'VALUES (?, ?, ?, ?, ?, ?, ?)', [profileId, date, flow, pain, energy, sleepTime, note]);
    });
}

// Meditation Operations
function getMeditationSessions(profileId) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var sessions = [];
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM MeditationSessions WHERE profileId=? ORDER BY date DESC', [profileId]);
        for (var i = 0; i < rs.rows.length; i++) {
            sessions.push(rs.rows.item(i));
        }
    });
    return sessions;
}

function addMeditationSession(profileId, duration, name) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        tx.executeSql('INSERT INTO MeditationSessions (profileId, duration, name) VALUES (?, ?, ?)', [profileId, duration, name]);
    });
}

function deleteMeditationHistory(profileId) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        tx.executeSql('DELETE FROM MeditationSessions WHERE profileId=?', [profileId]);
    });
}

// vim:et:ts=4:sw=4
