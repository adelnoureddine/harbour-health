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
                user_id = rs.rows.item(0).user_id;
            }
        }
    )
    return user_id;
}

function loadAllProfiles(a_model) {
    var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
    db.transaction(
        function(tx){
            var rs = tx.executeSql('SELECT id_profile, firstname FROM Profiles')
            for (var i = 0; i < rs.rows.length; i++) {
                a_model.append({user_id: rs.rows.item(i).id_profile, text: rs.rows.item(i).firstname})
            }
        }
    )
}

function addProfile(firstname, secondname, gender, birthday) {
    var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
    var user_id;
    db.transaction(
        function(tx){
            var rs = tx.executeSql('SELECT MAX(IFNULL(id_profile, 0)) + 1 AS next_profile FROM Profiles');
	    user_id = rs.rows.item(0).next_profile;
            tx.executeSql('INSERT INTO Profiles (id_profile,firstname,secondname,gender,birthday) VALUES (?,?,?,?,?)', [user_id, firstname, secondname, gender, birthday]);
	}
    );
    return user_id;
}

function modifyProfile(user_id, firstname, secondname, gender, birthday) {
    var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
    db.transaction(
        function(tx){
            tx.executeSql('UPDATE Profiles SET firstname = ?,lastname = ?,gender = ?,birthday = ? WHERE id_profile = ?', [firstname, secondname, gender, birthday, user_id]);
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
    var db = LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);
    var profile = {firstname: "", secondname: "", gender: "", birthday: ""};
    db.transaction(
        function(tx){
            var rs = tx.executeSql('SELECT firstname, secondname, gender, birthday FROM Profiles WHERE id_profile=(?)', [user_id]);
	    if (rs.rows.length > 0) {
	        profile.firstname = rs.rows.item(0).firstname;
	        profile.secondname = rs.rows.item(0).secondname;
	        profile.gender = rs.rows.item(0).gender;
	        profile.birthday = rs.rows.item(0).birthday;
	    }
	}
    );
    return profile;
}

function getLastUser() {
    var user_id = null;
    var db = Sql.LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);

    db.transaction(
        function(tx) {

            var rs = tx.executeSql('SELECT * FROM SETTINGS');
            if(rs.rows.length > 0) {
                user_id =  rs.rows.item(0).USER_ID;;

            } else {
                tx.executeSql('INSERT INTO SETTINGS VALUES (null)')
                getLastUser();
                user_id = null;
                print("test");
            }
    })
    print("user actif : "+ user_id)
    return user_id;
}
