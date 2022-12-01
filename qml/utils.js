.pragma library
.import QtQuick.LocalStorage 2.0 as Sql

function getLastUser() {
    var user_id = null;
    var db = Sql.LocalStorage.openDatabaseSync("HealthApp", "1.0", "Health App", 100000);

    db.transaction(
        function(tx) {

            var rs = tx.executeSql('SELECT * FROM SETTINGS');
            if(rs.rows.length > 0) {
                user_id =  rs.rows.item(0).USER_ID;
                print("nbr de ligne : " +rs.rows.length)

            } else {
                user_id = null;
                tx.executeSql('INSERT Into Settings VALUES (0)')
                print("test");
            }

    })

    print("user actif : "+ user_id)
    return user_id;

}
