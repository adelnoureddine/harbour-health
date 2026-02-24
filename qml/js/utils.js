.pragma library
.import QtQuick.LocalStorage 2.0 as Sql

function useProfile(user_id) {
    var db = Sql.LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
    db.transaction(
        function(tx){
            tx.executeSql('UPDATE Profiles SET lastUsed=CURRENT_TIMESTAMP WHERE id_profile=(?)', [user_id]);
        }
    )
}

function lastUsedProfile() {
    var db = Sql.LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
    var user_id;
    db.transaction(
        function(tx){
            var rs = tx.executeSql('SELECT id_profile FROM Profiles ORDER BY lastUsed DESC LIMIT 1');
            if (rs.rows.length > 0) {
                user_id = rs.rows.item(0).id_profile;
            }
        }
    )
    return user_id;
}

function loadAllProfiles(a_model) {
    var db = Sql.LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
    db.transaction(
        function(tx){
            var rs = tx.executeSql('SELECT id_profile, firstname FROM Profiles')
            for (var i = 0; i < rs.rows.length; i++) {
                a_model.append({user_id: rs.rows.item(i).id_profile, text: rs.rows.item(i).firstname})
            }
        }
    )
}

function addProfile(firstname, lastname, gender, birthday) {
    var db = Sql.LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
    var user_id;
    db.transaction(
        function(tx){
            var rs = tx.executeSql('SELECT MAX(IFNULL(id_profile, 0)) + 1 AS next_profile FROM Profiles');
	    print("new profile SQL: " + rs.rows.length);
	    user_id = rs.rows.item(0).next_profile;
	    print("new profile with user_id: " + user_id);
            tx.executeSql('INSERT INTO Profiles (id_profile,firstname,lastname,gender,birthday) VALUES (?,?,?,?,?)', [user_id, firstname, lastname, gender, birthday]);
	}
    );
    return user_id;
}

function modifyProfile(user_id, firstname, lastname, gender, birthday) {
    var db = Sql.LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
    db.transaction(
        function(tx){
            tx.executeSql('UPDATE Profiles SET firstname = ?,lastname = ?,gender = ?,birthday = ? WHERE id_profile = ?', [firstname, lastname, gender, birthday, user_id]);
	}
    );
}

function deleteProfile(user_id) {
    var db = Sql.LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
    db.transaction(
        function(tx){
            tx.executeSql('DELETE FROM Profiles WHERE id_profile=(?)', [user_id]);
        }
    )
}

function getProfile(user_id) {
    var db = Sql.LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
    var profile = {firstname: "", lastname: "", gender: "", birthday: ""};
    db.transaction(
        function(tx){
            var rs = tx.executeSql('SELECT firstname, lastname, gender, birthday FROM Profiles WHERE id_profile=(?)', [user_id]);
	    if (rs.rows.length > 0) {
	        profile.firstname = rs.rows.item(0).firstname;
	        profile.lastname = rs.rows.item(0).lastname;
	        profile.gender = rs.rows.item(0).gender;
	        profile.birthday = rs.rows.item(0).birthday;
	    }
	}
    );
    return profile;
}

function getLastMetricValue(user_id, metric_type) {
    var db = Sql.LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
    var value;
    db.transaction(
        function(tx){
            var rs = tx.executeSql('SELECT value_metric AS value FROM MetricValue LEFT JOIN Metrics USING(id_metric) WHERE id_profile=? AND name=? ORDER BY date_metric DESC LIMIT 1', [user_id, metric_type]);
            if (rs.rows.length > 0) {
                value = parseFloat(rs.rows.item(0).value);
            }
        }
    );
    return value;
}

function getLastMetric(user_id, metric_type) {
    var db = Sql.LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
    var value;
    db.transaction(
        function(tx){
            var rs = tx.executeSql('SELECT CONCAT(value_metric,unit) AS value FROM MetricValue LEFT JOIN Metrics USING(id_metric) WHERE id_profile=? AND name=? ORDER BY date_metric DESC LIMIT 1', [user_id, metric_type]);
            if (rs.rows.length > 0) {
                value = rs.rows.item(0).value;
            }
        }
    );
    return value;
}

