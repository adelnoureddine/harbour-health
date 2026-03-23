.pragma library
.import QtQuick.LocalStorage 2.0 as Sql

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

