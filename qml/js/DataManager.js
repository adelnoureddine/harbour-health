.pragma library
    .import QtQuick.LocalStorage 2.0 as Sql

// Database constants
var DB_NAME = "HarbourHealth";
var DB_VERSION = "2.0";
var DB_DESCRIPTION = "Harbour Health Application Database";
var DB_SIZE = 1000000;

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
            tx.executeSql('INSERT INTO Metrics (name, unit, category) VALUES (?,?,?)', ["weight", "kg", "Body"]);
            tx.executeSql('INSERT INTO Metrics (name, unit, category) VALUES (?,?,?)', ["height", "cm", "Body"]);
            tx.executeSql('INSERT INTO Metrics (name, unit, category) VALUES (?,?,?)', ["calories", "kcal", "Nutrition"]);
            tx.executeSql('INSERT INTO Metrics (name, unit, category) VALUES (?,?,?)', ["water", "L", "Nutrition"]);
        }
    });
}

// Profile Operations
function addProfile(firstName, lastName, gender, birthDate) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var id;
    db.transaction(function (tx) {
        var rs = tx.executeSql('INSERT INTO Profiles (firstName, lastName, gender, birthDate, lastUsed) VALUES (?,?,?,?,CURRENT_TIMESTAMP)',
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

// Log Operations
function addLog(profileId, metricName, value, note) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT id FROM Metrics WHERE name=?', [metricName]);
        if (rs.rows.length > 0) {
            var metricId = rs.rows.item(0).id;
            tx.executeSql('INSERT INTO HealthLogs (profileId, metricId, value, note) VALUES (?,?,?,?)',
                [profileId, metricId, value, note || ""]);
        }
    });
}

function deleteLog(id) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    db.transaction(function (tx) {
        tx.executeSql('DELETE FROM HealthLogs WHERE id=?', [id]);
    });
}

function getLatestLog(profileId, metricName) {
    var db = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    var log = null;
    db.transaction(function (tx) {
        var rs = tx.executeSql('SELECT l.*, m.unit FROM HealthLogs l JOIN Metrics m ON l.metricId = m.id ' +
            'WHERE l.profileId=? AND m.name=? ORDER BY l.timestamp DESC LIMIT 1', [profileId, metricName]);
        if (rs.rows.length > 0) {
            log = rs.rows.item(0);
        }
    });
    return log;
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
