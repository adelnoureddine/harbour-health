.pragma library
.import QtQuick.LocalStorage 2.0 as Sql

// Database constants
// A new name deliberately separates the public v1 database from pre-release data.
var DB_NAME = "HarbourHealthV1";
// LocalStorage's own version label, kept in its .ini file next to the database. It must
// never change: openDatabaseSync() refuses a database whose label differs, and every
// existing installation would fail to open. Schema changes go through DB_SCHEMA_VERSION.
var DB_VERSION = "1.0";
var DB_DESCRIPTION = "Harbour Health Application Database";
var DB_SIZE = 1000000;
var DB_SCHEMA_VERSION = 1;

// Category
var CATEGORY_BODY = "Body";
var CATEGORY_NUTRITION = "Nutrition";
var CATEGORY_BLOOD = "Blood";
var CATEGORY_OTHER = "Other";
// The day's to-do list, first on the dashboard; activity sits after nutrition.
var CATEGORY_DAILY = "Daily";
var CATEGORY_ACTIVITY = "Activity";
// Dashboard order before the profile arranges it; any other category comes after.
var CATEGORY_ORDER = [CATEGORY_DAILY, CATEGORY_BODY, CATEGORY_NUTRITION, CATEGORY_ACTIVITY, CATEGORY_BLOOD];

// Metrics
var METRIC_WEIGHT = "weight";
var METRIC_HEIGHT = "height";
var METRIC_WATER = "water";
var METRIC_CALORIES = "calories";
var METRIC_HEARTRATE = "heartrate";
var METRIC_BP_SYS = "systolic blood pressure";
var METRIC_BP_DIA = "diastolic blood pressure";
var METRIC_GLUCOSE = "glucose";
var METRIC_WAIST = "waist";
// Energy spent on sports and activities. Its own metric: calories eaten and burned
// each add up per day, and one metric holding both would break the ring and the totals.
var METRIC_CALORIES_BURNED = "calories burned";

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
var MODULE_WAIST = "Waist";
var MODULE_WHTR = "WHtR";
var MODULE_ACTIVITY = "Activity";
var MODULE_TODAY = "Today";

// Module Types
var MODULE_TYPE_METRIC = "Metric";
var MODULE_TYPE_CALC = "Calc";
var MODULE_TYPE_SUMMARY = "Summary";

// Calculated (derived) values, used as Modules.uses for MODULE_TYPE_CALC
var CALC_BMI = "bmi";
var CALC_BP = "blood-pressure";
var CALC_WHTR = "whtr";

/*
 * Built-in metrics and dashboard modules, seeded by name on every launch (see
 * seedDefaultMetricsAndModules), so a row added in a later release also reaches
 * existing databases. Append new rows at the end.
 */
// [name, unit, grouped, category]
var DEFAULT_METRICS = [
    [METRIC_WEIGHT, "kg", false, CATEGORY_BODY],
    [METRIC_HEIGHT, "cm", false, CATEGORY_BODY],
    [METRIC_CALORIES, "kcal", true, CATEGORY_NUTRITION],
    [METRIC_WATER, "L", true, CATEGORY_NUTRITION],
    [METRIC_HEARTRATE, "bpm", false, CATEGORY_BLOOD],
    [METRIC_BP_SYS, "mmHg", false, CATEGORY_BLOOD],
    [METRIC_BP_DIA, "mmHg", false, CATEGORY_BLOOD],
    [METRIC_GLUCOSE, "mg/dL", false, CATEGORY_BLOOD],
    [METRIC_WAIST, "cm", false, CATEGORY_BODY],
    [METRIC_CALORIES_BURNED, "kcal", true, CATEGORY_ACTIVITY]
];

// [name, type, uses, bydefault, category, icon]
var DEFAULT_MODULES = [
    [MODULE_WEIGHT, MODULE_TYPE_METRIC, METRIC_WEIGHT, true, CATEGORY_BODY, "scale.png"],
    [MODULE_HEIGHT, MODULE_TYPE_METRIC, METRIC_HEIGHT, true, CATEGORY_BODY, "height.png"],
    [MODULE_BMI, MODULE_TYPE_CALC, CALC_BMI, true, CATEGORY_BODY, "gauge.png"],
    [MODULE_CALORIES, MODULE_TYPE_METRIC, METRIC_CALORIES, true, CATEGORY_NUTRITION, "fire.png"],
    [MODULE_WATER, MODULE_TYPE_METRIC, METRIC_WATER, true, CATEGORY_NUTRITION, "water.png"],
    [MODULE_HEARTRATE, MODULE_TYPE_METRIC, METRIC_HEARTRATE, true, CATEGORY_BLOOD, "heart-pulse.png"],
    [MODULE_BP, MODULE_TYPE_CALC, CALC_BP, true, CATEGORY_BLOOD, "blood-pressure.svg"],
    [MODULE_GLUCOSE, MODULE_TYPE_METRIC, METRIC_GLUCOSE, true, CATEGORY_BLOOD, "diabetes.png"],
    [MODULE_CONDITION, MODULE_TYPE_SUMMARY, "MainHealthCondition", true, CATEGORY_OTHER, "medical-bag.png"],
    [MODULE_VACCINATION, MODULE_TYPE_SUMMARY, "VaccinesList", true, CATEGORY_OTHER, "needle.png"],
    [MODULE_MEDITATION, MODULE_TYPE_SUMMARY, "MeditationMenu", true, CATEGORY_OTHER, "meditation.png"],
    [MODULE_MENSTRUATION, MODULE_TYPE_SUMMARY, "Menstruation", true, CATEGORY_OTHER, "calendar-heart.png"],
    [MODULE_WAIST, MODULE_TYPE_METRIC, METRIC_WAIST, true, CATEGORY_BODY, "waist.svg"],
    [MODULE_WHTR, MODULE_TYPE_CALC, CALC_WHTR, true, CATEGORY_BODY, "whtr.svg"],
    [MODULE_ACTIVITY, MODULE_TYPE_METRIC, METRIC_CALORIES_BURNED, true, CATEGORY_ACTIVITY, "activity.svg"],
    // `uses` is the page a summary row opens (pages/TodayPage.qml).
    [MODULE_TODAY, MODULE_TYPE_SUMMARY, "TodayPage", true, CATEGORY_DAILY, "today.svg"]
];

// A glass of water, in litres: the quick-add on the cover and on the water card.
var WATER_GLASS_L = 0.25;

// Modules added after version 1.0. An update leaves them switched off for the profiles
// that already exist; the dashboard offers them once (its "what's new" card).
var NEW_MODULES = [MODULE_TODAY, MODULE_ACTIVITY, MODULE_WAIST, MODULE_WHTR];

// local time day border -> 04:00:00
var DAY_START_TIME = "04:00:00";

// Series aggregation modes for the history charts
var SERIES_RAW = "raw";
var SERIES_DAILY_SUM = "dailySum";
var SERIES_DAILY_AVG = "dailyAvg";
// Daily totals averaged per week (Monday first) or per calendar month: one bar per
// week or month on long ranges, still in "per day" units like the goal and the stats.
var SERIES_WEEKLY = "weekly";
var SERIES_MONTHLY = "monthly";

// Every profile-owned table. Used by deleteProfile() so the cascade cannot drift.
var PROFILE_TABLES = ["HealthLogs", "Injections", "Treatments", "HealthConditions",
                      "MenstrualCycles", "MenstrualLogs", "MeditationSessions",
                      "MedicationLogs", "ProfileModules", "Goals", "ModuleOrder"];

// Tables covered by export/restore, parents before children. Goals and ModuleOrder
// came later: an older backup simply has none, and an older app ignores them.
var ALL_TABLES = ["Profiles", "Metrics", "Modules", "ProfileModules", "MetricConstraints",
                  "HealthLogs", "Vaccines", "Injections", "Medications", "Treatments",
                  "MedicationLogs", "HealthConditions", "MenstrualCycles", "MenstrualLogs",
                  "MeditationSessions", "Goals", "ModuleOrder"];

// Daily goals for the metrics totalled per day, shown as rings on the dashboard. These
// apply until the user sets their own (Goals table).
var DEFAULT_GOALS = {};
DEFAULT_GOALS[METRIC_WATER] = 2;
DEFAULT_GOALS[METRIC_CALORIES] = 2000;
DEFAULT_GOALS[METRIC_CALORIES_BURNED] = 300;

// Goals key for the daily meditation goal, in minutes. No default: it is only on the
// Today page once the user sets one.
var GOAL_MEDITATION = "meditation";

/*
 * What a single reading can plausibly be, in the stored unit: [lowest, highest]. Wide
 * on purpose -- a newborn's weight and a marathon's calories are inside -- so it only
 * stops slips: 250 typed into a field of litres (the card says "Add 250 ml"), a height
 * typed in metres, 665 for 66.5. A metric without an entry has no limits.
 */
var METRIC_LIMITS = {};
METRIC_LIMITS[METRIC_WEIGHT] = [0.5, 500];
METRIC_LIMITS[METRIC_HEIGHT] = [30, 280];
METRIC_LIMITS[METRIC_WAIST] = [20, 300];
METRIC_LIMITS[METRIC_WATER] = [0.01, 10];
METRIC_LIMITS[METRIC_CALORIES] = [1, 20000];
METRIC_LIMITS[METRIC_CALORIES_BURNED] = [1, 20000];
METRIC_LIMITS[METRIC_HEARTRATE] = [20, 300];
METRIC_LIMITS[METRIC_BP_SYS] = [40, 300];
METRIC_LIMITS[METRIC_BP_DIA] = [20, 200];
METRIC_LIMITS[METRIC_GLUCOSE] = [10, 1000];

// The same for a whole day's goal. A target (weight, waist) has its metric's limits.
var GOAL_LIMITS = {};
GOAL_LIMITS[METRIC_WATER] = [0.1, 20];
GOAL_LIMITS[METRIC_CALORIES] = [100, 20000];
GOAL_LIMITS[METRIC_CALORIES_BURNED] = [10, 20000];
GOAL_LIMITS[GOAL_MEDITATION] = [1, 1440];

// {min, max} in the stored unit, or null without limits.
function metricLimits(metricName) {
    var limits = METRIC_LIMITS.hasOwnProperty(metricName) ? METRIC_LIMITS[metricName] : null;
    return limits ? { min: limits[0], max: limits[1] } : null;
}

function goalLimits(metricName) {
    var limits = GOAL_LIMITS.hasOwnProperty(metricName) ? GOAL_LIMITS[metricName] : null;
    return limits ? { min: limits[0], max: limits[1] } : metricLimits(metricName);
}

// Metrics that can have a target to reach (a line on their chart), rather than a daily goal.
var TARGET_METRICS = [METRIC_WEIGHT, METRIC_WAIST];

function hasTarget(metricName) {
    return TARGET_METRICS.indexOf(metricName) >= 0;
}

/*
 * Units.
 *
 * Everything is stored in one unit per metric (kg, cm, L, mg/dL: Metrics.unit) and
 * that never changes: readings, goals, reference ranges, limits, backups and CSV files
 * are all in it. The unit chosen here only decides how a value is shown and typed.
 * Pages convert with toDisplay() right before formatting and with fromDisplay() right
 * after parsing; every calculation in between (BMI, bands, totals) is on stored values.
 *
 * The choice is the app's, not a profile's, and is kept in the settings file (the
 * window calls setUnits() at start), so the database is the same whatever is chosen.
 */
var UNIT_CHOICES = {
    mass: ["kg", "lb"],
    length: ["cm", "in"],
    volume: ["L", "fl oz"],
    glucose: ["mg/dL", "mmol/L"]
};
// shown = stored * factor. US fluid ounces; glucose by its molar mass (180.156 g/mol).
var UNIT_FACTORS = {
    "lb": 2.2046226218487757,
    "in": 1 / 2.54,
    "fl oz": 33.814022701843,
    "mmol/L": 1 / 18.0156
};
// Decimals worth showing in a converted unit (the stored units keep Utils.metricDecimals).
var UNIT_DECIMALS = { "lb": 1, "in": 1, "fl oz": 1, "mmol/L": 1 };

var _units = { mass: "kg", length: "cm", volume: "L", glucose: "mg/dL" };
var _unitsRevision = 0;

// The quantity a metric measures, "" when it has one unit only (bpm, mmHg, kcal).
function quantityOf(metricName) {
    switch (metricName) {
    case METRIC_WEIGHT:  return "mass";
    case METRIC_HEIGHT:
    case METRIC_WAIST:   return "length";
    case METRIC_WATER:   return "volume";
    case METRIC_GLUCOSE: return "glucose";
    default:             return "";
    }
}

// The current choice: {mass, length, volume, glucose}.
function units() {
    return { mass: _units.mass, length: _units.length, volume: _units.volume, glucose: _units.glucose };
}

// Takes what the settings file holds; anything missing or unknown keeps its unit.
function setUnits(choices) {
    var changed = false;
    for (var quantity in UNIT_CHOICES) {
        var unit = choices ? choices[quantity] : undefined;
        if (unit !== undefined && UNIT_CHOICES[quantity].indexOf(unit) >= 0 && _units[quantity] !== unit) {
            _units[quantity] = unit;
            changed = true;
        }
    }
    if (changed) {
        _unitsRevision++;
    }
    return changed;
}

function _unitFactor(metricName) {
    var quantity = quantityOf(metricName);
    if (quantity === "") {
        return 1;
    }
    var factor = UNIT_FACTORS[_units[quantity]];
    return factor === undefined ? 1 : factor;
}

// Whether the metric is shown in another unit than the stored one.
function isConverted(metricName) {
    return _unitFactor(metricName) !== 1;
}

// The unit a metric is shown in; storedUnit (Metrics.unit) when it has no choice.
function displayUnit(metricName, storedUnit) {
    var quantity = quantityOf(metricName);
    return quantity === "" ? (storedUnit ? storedUnit : "") : _units[quantity];
}

// A stored value as shown; null, undefined and "" pass through.
function toDisplay(metricName, value) {
    if (value === null || value === undefined || value === "") {
        return value;
    }
    var factor = _unitFactor(metricName);
    return factor === 1 ? value : value * factor;
}

// What was typed, as stored. Not rounded: 150 lb reads back as 150.
function fromDisplay(metricName, value) {
    if (value === null || value === undefined || value === "") {
        return value;
    }
    var factor = _unitFactor(metricName);
    return factor === 1 ? value : value / factor;
}

// Decimals to show: `decimals` (Utils.metricDecimals) in the stored unit.
function displayDecimals(metricName, decimals) {
    var quantity = quantityOf(metricName);
    if (quantity !== "" && UNIT_DECIMALS.hasOwnProperty(_units[quantity])) {
        return UNIT_DECIMALS[_units[quantity]];
    }
    return decimals;
}

// Chart points [{t, v}] as shown. The same array when nothing is converted.
function displayPoints(metricName, points) {
    var factor = _unitFactor(metricName);
    if (factor === 1 || !points) {
        return points;
    }
    var shown = [];
    for (var i = 0; i < points.length; i++) {
        shown.push({ t: points[i].t, v: points[i].v * factor });
    }
    return shown;
}

// {min, max, avg, count} as shown.
function displayStats(metricName, stats) {
    var factor = _unitFactor(metricName);
    if (factor === 1 || !stats) {
        return stats;
    }
    return {
        min: stats.min === null ? null : stats.min * factor,
        max: stats.max === null ? null : stats.max * factor,
        avg: stats.avg === null ? null : stats.avg * factor,
        count: stats.count
    };
}

// Reference bands with their bounds as shown (copies: the originals are cached).
function displayBands(metricName, bands) {
    var factor = _unitFactor(metricName);
    if (factor === 1 || !bands) {
        return bands;
    }
    var shown = [];
    for (var i = 0; i < bands.length; i++) {
        var band = bands[i];
        shown.push({
            id: band.id, metricName: band.metricName, label: band.label, color: band.color,
            minValue: band.minValue === null ? null : band.minValue * factor,
            maxValue: band.maxValue === null ? null : band.maxValue * factor
        });
    }
    return shown;
}

/*
 * The glass the quick-add logs: {litres, amount, unit}. 250 ml, or 8 fl oz (a US cup)
 * when water is shown in fluid ounces, so the button names a round amount either way.
 */
function waterGlass() {
    if (_units.volume === "fl oz") {
        return { litres: 8 / UNIT_FACTORS["fl oz"], amount: 8, unit: "fl oz" };
    }
    return { litres: WATER_GLASS_L, amount: WATER_GLASS_L * 1000, unit: "ml" };
}

// Stored in Profiles.coverMetric1 when the cover shows the day's to-do list instead of
// two metrics. No metric has this name.
var COVER_TODAY = "today";

/*
 * openDatabaseSync() was previously called afresh by every single function. Returning
 * to the dashboard rebuilds a dozen cards, each running several of them, so the
 * handle is memoised for the lifetime of the engine.
 *
 * The first call also creates or upgrades the schema, so whatever queries first -- the
 * dashboard, the cover, the window -- finds the tables in place. The handle is kept
 * only once that succeeded: after a failure the next call tries again (and throws
 * again, which the window shows as a database error).
 */
var _handle = null;     // opened; the schema may not have been checked yet
var _db = null;         // opened, with the schema in place

// The bare connection, for looking at the database before it is created or upgraded.
function _open() {
    if (_handle === null) {
        _handle = Sql.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    }
    return _handle;
}

function db() {
    if (_db === null) {
        var handle = _open();
        _createSchema(handle);
        _db = handle;
    }
    return _db;
}

/*
 * An Error the pages can recognise: `reason` is a stable key they translate
 * (DataTransfer.failureText, the window's database error), `message` the English
 * fallback. Not `code`: LocalStorage's own SQL errors carry a numeric one.
 */
function _failure(reason, message) {
    var error = new Error(message);
    error.reason = reason;
    return error;
}

/*
 * Several statements that take effect together or not at all. Returns what `work`
 * returns.
 *
 * LocalStorage's transaction() does not give that on Qt 5.6: when its callback throws,
 * everything that ran before the error is still committed (checked on Sailfish OS 5.1).
 * A restore failing on one bad row had by then deleted every table. Here the work runs
 * inside a savepoint that is rolled back before transaction() gets to commit, and the
 * error is passed on once it has returned.
 */
function _atomic(handle, work) {
    var failed = false;
    var failure;
    var result;
    handle.transaction(function (tx) {
        tx.executeSql('SAVEPOINT health_atomic');
        try {
            result = work(tx);
        } catch (error) {
            failed = true;
            failure = error;
            tx.executeSql('ROLLBACK TO health_atomic');
        }
        tx.executeSql('RELEASE health_atomic');
    });
    if (failed) {
        throw failure;
    }
    return result;
}

// The same on the app's database. Every write of more than one statement goes through it.
function _write(work) {
    return _atomic(db(), work);
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

/*
 * Start of the day `date` (default: now) belongs to, with the DAY_START_TIME border:
 * a glass of water at 01:00 still counts toward the evening before.
 */
function dayStart(date) {
    var d = date ? new Date(date.getTime()) : new Date();
    var parts = DAY_START_TIME.split(":");
    var start = new Date(d.getFullYear(), d.getMonth(), d.getDate(),
                         parseInt(parts[0], 10), parseInt(parts[1], 10), parseInt(parts[2], 10));
    if (d < start) {
        start.setDate(start.getDate() - 1);
    }
    return start;
}

/*
 * Today, with the DAY_START_TIME border, as the stored-string bounds [start, end) a
 * timestamp column is compared against. Every "today" -- daily totals, medication
 * intakes, meditation -- uses it, so they all start a new day at the same moment.
 * Bound as stored strings: SQLite's datetime() writes a space where the stored values
 * have a "T", and the space sorts first.
 */
function _todayRange() {
    var start = dayStart();
    var end = new Date(start.getTime());
    end.setDate(end.getDate() + 1);
    return [toTimestamp(start), toTimestamp(end)];
}

/*
 * First timestamp of a chart window of `days` days ending today, or null for all
 * time. A week is today and the six days before it: counting back seven days from
 * midnight made "Week" span eight calendar days. Daily series start on the same
 * DAY_START_TIME border their per-day totals use, so the first bar is a whole day.
 */
function sinceForDays(days, daily) {
    if (!days) {
        return null;
    }
    var from = daily ? dayStart() : new Date();
    if (!daily) {
        from.setHours(0, 0, 0, 0);
    }
    from.setDate(from.getDate() - (days - 1));
    return toTimestamp(from);
}

/*
 * Rows written through this connection so far. The handle lives as long as the app,
 * so the number moves on every insert, update or delete anywhere -- the dashboard
 * compares it to skip rebuilding when nothing changed.
 */
function changeCount() {
    var count = 0;
    db().transaction(function (tx) {
        count = tx.executeSql('SELECT total_changes() AS n').rows.item(0).n;
    });
    return count;
}

/*
 * Identifies the data a page was built from: anything written since, a new day (the
 * DAY_START_TIME day of "today" totals and chart windows, and the calendar day of
 * "Today"/"Yesterday" and the dates shown), or another choice of units changes it.
 * Pages compare it when they become active again, when the app comes back to the
 * foreground and when the day turns, and skip reloading when it is the same.
 */
function dataKey() {
    return changeCount() + "|" + toTimestamp(dayStart()) + "|" + new Date().getDate() + "|" + _unitsRevision;
}

/*
 * Milliseconds until the next moment "today" changes: midnight (the dates shown) or the
 * DAY_START_TIME border (the daily totals), whichever comes first. The window re-checks
 * the page on top then, so an app left open overnight does not keep yesterday's totals.
 */
function msUntilNextDay() {
    var now = new Date();
    var border = dayStart(now);
    border.setDate(border.getDate() + 1);
    var midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
    return Math.max(1000, Math.min(border.getTime(), midnight.getTime()) - now.getTime());
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
 * Everything runs inside _createSchema()'s savepoint (see _atomic), so a failed upgrade
 * rolls back whole. Bump DB_SCHEMA_VERSION in the same commit as the block that reaches
 * it, and give _upgradeDump() the matching block.
 */
function migrateDatabase(tx, fromVersion) {
    var version = fromVersion;

    // if (version < 2) {
    //     tx.executeSql('ALTER TABLE Profiles ADD COLUMN example TEXT');
    //     version = 2;
    // }

    if (version !== DB_SCHEMA_VERSION) {
        throw _failure("no-migration-path", "No migration path from schema version " + fromVersion
                       + " to " + DB_SCHEMA_VERSION);
    }
    return version;
}

/*
 * The same steps for a backup made at an older schema version, before it is restored:
 * add one `if (dump.schemaVersion < N)` block next to each block above that changes
 * what the rows of an existing table look like. Without it, backups made before a
 * schema change could no longer be restored after it.
 */
function _upgradeDump(dump) {
    return dump;
}

// Opens the database, creating or upgrading it on first use (db() does the work).
function init() {
    db();
}

/*
 * Before a schema upgrade.
 *
 * An upgrade rewrites the user's only copy of their data, so the window (which can
 * write files; this library cannot) first saves it as it is: pendingMigration() says
 * whether one is due, exportBeforeMigration() reads the data with the old schema, and
 * only approveMigration() lets _createSchema() run the upgrade. Whatever touches the
 * database before that gets a "migration-pending" error instead of upgrading unseen.
 */
var _migrationApproved = false;

// The schema version stored in the database: 0 when it has none yet. Creates nothing.
function storedSchemaVersion() {
    var version = 0;
    _open().readTransaction(function (tx) {
        var rs = tx.executeSql("SELECT count(*) AS found FROM sqlite_master WHERE type='table' AND name='SchemaInfo'");
        if (rs.rows.item(0).found > 0) {
            rs = tx.executeSql('SELECT version FROM SchemaInfo ORDER BY version DESC LIMIT 1');
            if (rs.rows.length > 0) {
                version = rs.rows.item(0).version;
            }
        }
    });
    return version;
}

// {from, to} when the database has an older schema than this version needs, else null.
function pendingMigration() {
    var from = storedSchemaVersion();
    return from > 0 && from < DB_SCHEMA_VERSION ? { from: from, to: DB_SCHEMA_VERSION } : null;
}

// Every table of the old database that a backup covers, stamped with the old version.
function exportBeforeMigration() {
    var handle = _open();
    var tables = [];
    handle.readTransaction(function (tx) {
        var rs = tx.executeSql("SELECT name FROM sqlite_master WHERE type='table'");
        var existing = {};
        for (var i = 0; i < rs.rows.length; i++) {
            existing[rs.rows.item(i).name] = true;
        }
        for (var j = 0; j < ALL_TABLES.length; j++) {
            if (existing[ALL_TABLES[j]] === true) {
                tables.push(ALL_TABLES[j]);
            }
        }
    });
    return _dump(handle, tables, storedSchemaVersion());
}

function approveMigration() {
    _migrationApproved = true;
}

function _createSchema(handle) {
    _atomic(handle, function (tx) {
        tx.executeSql('CREATE TABLE IF NOT EXISTS SchemaInfo (' +
            'version INTEGER PRIMARY KEY)');
        var rs = tx.executeSql('SELECT version FROM SchemaInfo ORDER BY version DESC LIMIT 1');
        var hasSchemaVersion = rs.rows.length > 0;
        if (hasSchemaVersion) {
            var currentVersion = rs.rows.item(0).version;
            if (currentVersion > DB_SCHEMA_VERSION) {
                throw _failure("schema-newer", "Database schema is newer than this app version");
            }
            if (currentVersion < DB_SCHEMA_VERSION) {
                if (!_migrationApproved) {
                    throw _failure("migration-pending", "The database has to be upgraded first");
                }
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
        // Added without a schema version bump: a new table touches no existing data,
        // and CREATE TABLE IF NOT EXISTS reaches every database on its next start.
        tx.executeSql('CREATE TABLE IF NOT EXISTS Goals (profileId INTEGER NOT NULL, metricName TEXT NOT NULL, ' +
            'value REAL NOT NULL, PRIMARY KEY (profileId, metricName))');
        // The dashboard order a profile chose (Arrange dashboard). No row: default order.
        tx.executeSql('CREATE TABLE IF NOT EXISTS ModuleOrder (profileId INTEGER NOT NULL, moduleId INTEGER NOT NULL, ' +
            'position INTEGER NOT NULL, PRIMARY KEY (profileId, moduleId))');
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

        seedDefaultMetricsAndModules(tx);
        seedDefaultConstraints(tx);
        _deleteUnusedVaccines(tx);

        if (!hasSchemaVersion) {
            tx.executeSql('INSERT INTO SchemaInfo (version) VALUES (?)', [DB_SCHEMA_VERSION]);
        }
    });
}

/*
 * Inserts any built-in metric or module that is missing, matched by name.
 *
 * These used to be seeded only into empty tables, so nothing added in a later
 * release (waist, WHtR) could reach an existing database. Missing rows are added
 * here on every launch and after a restore, which would otherwise wipe them when the
 * backup predates them.
 *
 * A module added to an existing database is deliberately not switched on for the
 * existing profiles, so an update never rearranges anyone's dashboard. New profiles
 * get every module flagged bydefault (addProfile).
 */
function seedDefaultMetricsAndModules(tx) {
    var i;
    var rs;
    for (i = 0; i < DEFAULT_METRICS.length; i++) {
        var metricRow = DEFAULT_METRICS[i];
        rs = tx.executeSql('SELECT count(*) AS count FROM Metrics WHERE name=?', [metricRow[0]]);
        if (rs.rows.item(0).count === 0) {
            tx.executeSql('INSERT INTO Metrics (name, unit, grouped, category) VALUES (?,?,?,?)', metricRow);
        }
    }
    for (i = 0; i < DEFAULT_MODULES.length; i++) {
        var moduleRow = DEFAULT_MODULES[i];
        rs = tx.executeSql('SELECT count(*) AS count FROM Modules WHERE name=?', [moduleRow[0]]);
        if (rs.rows.item(0).count === 0) {
            tx.executeSql('INSERT INTO Modules (name, type, uses, bydefault, category, icon) VALUES (?,?,?,?,?,?)', moduleRow);
        }
    }
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
    defaults[MODULE_BMI] = [
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
    // Waist-to-height ratio. 0.5 ("keep your waist below half your height") is the
    // commonly used cut-off, with a higher band from 0.6. Population-level figures that
    // vary with age and ethnicity, hence the neutral labels.
    defaults[MODULE_WHTR] = [
        ["Below 0.5", null, 0.5, "green"],
        ["0.5 to 0.6", 0.5, 0.6, "orange"],
        ["0.6 and above", 0.6, null, "red"]
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
    _write(function (tx) {
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

/*
 * The profile's cover choice: {metric1, metric2}. metric1 is COVER_TODAY when the
 * cover shows the day's to-do list; metric2 then keeps the second metric for when the
 * cover goes back to two metrics.
 */
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
    _write(function (tx) {
        // Delete all profile-owned records before the profile itself. SQLite does
        // not enable foreign-key cascading by default for LocalStorage databases.
        for (var i = 0; i < PROFILE_TABLES.length; i++) {
            tx.executeSql('DELETE FROM ' + PROFILE_TABLES[i] + ' WHERE profileId=?', [id]);
        }
        tx.executeSql('DELETE FROM Profiles WHERE id=?', [id]);
        deleteOrphanedMedications(tx);
        _deleteUnusedVaccines(tx);
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

function calculateMetrics(profileId, calculate) {
    if (calculate === CALC_BMI) {
        var bmi = calcBMI(profileId);
        return bmi === null ? null : Math.round(bmi * 10) / 10;
    }
    if (calculate === CALC_WHTR) {
        var whtr = calcWHtR(profileId);
        return whtr === null ? null : Math.round(whtr * 100) / 100;
    }
    if (calculate === CALC_BP) {
        var bp = getLatestBloodPressure(profileId);
        if (bp === null || bp.systolic === null || bp.diastolic === null) {
            return null;
        }
        return bp.systolic + "/" + bp.diastolic;
    }
    return null;
}

/*
 * Log queries select the metric with `metricId = METRIC_ID` instead of joining Metrics
 * and filtering on its name. With the join SQLite could only use the first column of
 * idx_healthlogs_lookup, so it read and sorted every reading of the profile, all
 * metrics together, for each query. The scalar subquery runs once and the whole
 * (profileId, metricId, timestamp) index applies: the latest value is one lookup.
 */
var METRIC_ID = '(SELECT id FROM Metrics WHERE name=?)';

// Log Operations

/*
 * Readings taken together -- blood pressure is two -- in one transaction: one commit
 * and one disk sync instead of one each, and never half a pair.
 * entries: [{metricName, value}]. Returns how many were stored.
 */
function addLogs(profileId, entries, timestamp, note) {
    var inserted = 0;
    _write(function (tx) {
        for (var i = 0; i < entries.length; i++) {
            var rs = tx.executeSql('SELECT id FROM Metrics WHERE name=?', [entries[i].metricName]);
            if (rs.rows.length > 0) {
                tx.executeSql('INSERT INTO HealthLogs (profileId, metricId, value, timestamp, note) VALUES (?,?,?,?,?)',
                    [profileId, rs.rows.item(0).id, entries[i].value, toTimestamp(timestamp), note || ""]);
                inserted++;
            }
        }
    });
    return inserted;
}

function addLog(profileId, metricName, value, timestamp, note) {
    return addLogs(profileId, [{ metricName: metricName, value: value }], timestamp, note) > 0;
}

// The same for edits. updates: [{id, value}], sharing one timestamp and note.
function updateLogs(updates, timestamp, note) {
    _write(function (tx) {
        for (var i = 0; i < updates.length; i++) {
            tx.executeSql('UPDATE HealthLogs SET value=?, timestamp=?, note=? WHERE id=?',
                [updates[i].value, toTimestamp(timestamp), note || "", updates[i].id]);
        }
    });
}

function updateLog(id, value, timestamp, note) {
    updateLogs([{ id: id, value: value }], timestamp, note);
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
    deleteLogs([id]);
}

// Several readings in one transaction (both halves of a blood pressure entry).
function deleteLogs(ids) {
    _write(function (tx) {
        for (var i = 0; i < ids.length; i++) {
            if (ids[i] >= 0) {
                tx.executeSql('DELETE FROM HealthLogs WHERE id=?', [ids[i]]);
            }
        }
    });
}

/*
 * Whether a profile has entered anything at all (the dashboard's getting-started card,
 * which used to stay for good on a profile that only tracks conditions or the cycle).
 */
function hasAnyData(profileId) {
    var found = false;
    var tables = ["HealthLogs", "HealthConditions", "Injections", "MeditationSessions",
                  "MenstrualCycles", "MenstrualLogs"];
    db().transaction(function (tx) {
        for (var i = 0; i < tables.length && !found; i++) {
            found = tx.executeSql('SELECT EXISTS (SELECT 1 FROM ' + tables[i] + ' WHERE profileId=?) AS found',
                                  [profileId]).rows.item(0).found ? true : false;
        }
    });
    return found;
}

// Whether a profile has any reading at all.
function hasLogs(profileId) {
    var found = false;
    db().transaction(function (tx) {
        found = tx.executeSql('SELECT EXISTS (SELECT 1 FROM HealthLogs WHERE profileId=?) AS found',
                              [profileId]).rows.item(0).found ? true : false;
    });
    return found;
}

function _latestLog(tx, profileId, metricName) {
    var rs = tx.executeSql('SELECT value, timestamp FROM HealthLogs WHERE profileId=? AND metricId=' + METRIC_ID +
        ' ORDER BY timestamp DESC LIMIT 1', [profileId, metricName]);
    return rs.rows.length > 0 ? { value: rs.rows.item(0).value, timestamp: String(rs.rows.item(0).timestamp) }
                              : null;
}

// Latest reading with its time, or null: {value, timestamp}.
function getLatestLog(profileId, metricName) {
    var log = null;
    db().transaction(function (tx) {
        log = _latestLog(tx, profileId, metricName);
    });
    return log;
}

/*
 * The latest reading of every metric the profile has logged, in one statement:
 * {metricName: {value, timestamp}}. Each lookup is one index seek, so this costs about
 * what a single getLatestLog() does, instead of one transaction per type.
 */
function getLatestLogs(profileId) {
    var latest = {};
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT m.name AS name, l.value AS value, l.timestamp AS timestamp ' +
            'FROM Metrics m JOIN HealthLogs l ON l.id = (SELECT id FROM HealthLogs ' +
            'WHERE profileId=? AND metricId=m.id ORDER BY timestamp DESC LIMIT 1)', [profileId]);
        for (var i = 0; i < rs.rows.length; i++) {
            var row = rs.rows.item(i);
            latest[row.name] = { value: row.value, timestamp: String(row.timestamp) };
        }
    });
    return latest;
}

/*
 * Systolic and diastolic latest readings ({value, timestamp} or null each) as one
 * blood pressure: {systolic, diastolic, timestamp}, a missing half null and the time
 * the newer half's. null when neither half was ever logged.
 */
function bloodPressureFrom(systolic, diastolic) {
    if (!systolic && !diastolic) {
        return null;
    }
    var newer = !diastolic || (systolic && timestampToMs(systolic.timestamp) >= timestampToMs(diastolic.timestamp))
            ? systolic : diastolic;
    return {
        systolic: systolic ? systolic.value : null,
        diastolic: diastolic ? diastolic.value : null,
        timestamp: newer.timestamp
    };
}

function getLatestBloodPressure(profileId) {
    var bp = null;
    db().transaction(function (tx) {
        bp = bloodPressureFrom(_latestLog(tx, profileId, METRIC_BP_SYS), _latestLog(tx, profileId, METRIC_BP_DIA));
    });
    return bp;
}

// The last `limit` readings, oldest first, as chart points [{t, v}].
function getRecentReadings(profileId, metricName, limit) {
    var points = [];
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT timestamp, value FROM HealthLogs WHERE profileId=? AND metricId=' + METRIC_ID +
            ' ORDER BY timestamp DESC LIMIT ?', [profileId, metricName, limit]);
        for (var i = rs.rows.length - 1; i >= 0; i--) {
            points.push({ t: timestampToMs(rs.rows.item(i).timestamp), v: rs.rows.item(i).value });
        }
    });
    return points;
}

function getLatestLogValue(profileId, metricName) {
    var log = getLatestLog(profileId, metricName);
    return log ? log.value : null;
}

/*
 * The points a trend line is drawn from (dashboard card, cover): the last 30 days, or
 * the last ten readings when the month has fewer than two, so an old weight still gets
 * its trend. Chart points [{t, v}], oldest first.
 */
function getTrend(profileId, metricName) {
    var points = getSeries(profileId, metricName, sinceForDays(30, false), SERIES_RAW);
    return points.length >= 2 ? points : getRecentReadings(profileId, metricName, 10);
}

/*
 * Today's total for a grouped metric (water, calories), or null when nothing has been
 * logged today. This used to return the last day that had any entries, so water
 * logged three days ago was shown on the dashboard as today's intake.
 */
function getTodayTotal(profileId, metricName) {
    var value = null;
    db().transaction(function (tx) {
        value = _todayTotal(tx, profileId, metricName);
    });
    return value;
}

function _todayTotal(tx, profileId, metricName) {
    var today = _todayRange();
    var rs = tx.executeSql('SELECT SUM(value) AS total FROM HealthLogs WHERE profileId=? AND metricId=' +
        METRIC_ID + ' AND timestamp >= ? AND timestamp < ?',
        [profileId, metricName, today[0], today[1]]);
    return rs.rows.length > 0 ? rs.rows.item(0).total : null;
}

/*
 * History rows for one metric, newest first.
 *
 * For grouped metrics each row also carries `day` (the 04:00-border day it belongs
 * to) and `dayTotal`, so the section headers no longer have to re-sum the entire
 * model on every binding evaluation.
 *
 * Returns the day -> total map as well ({} when not grouped), so the page does not
 * have to read every row back out of the model to rebuild it.
 */
function addLogsToModel(profileId, metricName, a_model, grouped, limit) {
    var rows = [];
    var totals = {};
    // `limit` rows only (the newest): a page showed years of water at once, rebuilt
    // after every write. Without one, everything.
    var page = limit > 0 ? ' LIMIT ' + Math.floor(limit) : '';
    db().transaction(function (tx) {
        var rs;
        var i;
        if (grouped) {
            var border = "-" + DAY_START_TIME;
            // Day totals come from one grouped pass. They used to be a subquery run
            // for every row, each re-reading the metric's entire history: with two
            // years of water entries, opening the page took seconds.
            rs = tx.executeSql('SELECT DATE(timestamp, ?) AS day, SUM(value) AS total FROM HealthLogs ' +
                'WHERE profileId=? AND metricId=' + METRIC_ID + ' GROUP BY day',
                [border, profileId, metricName]);
            for (i = 0; i < rs.rows.length; i++) {
                totals[rs.rows.item(i).day] = rs.rows.item(i).total;
            }
            rs = tx.executeSql('SELECT id, timestamp, value, note, DATE(timestamp, ?) AS day FROM HealthLogs ' +
                'WHERE profileId=? AND metricId=' + METRIC_ID + ' ORDER BY timestamp DESC' + page,
                [border, profileId, metricName]);
            for (i = 0; i < rs.rows.length; i++) {
                var row = rs.rows.item(i);
                rows.push({ id: row.id, timestamp: row.timestamp, value: row.value, note: row.note,
                            day: row.day, dayTotal: totals[row.day] });
            }
        }
        else {
            // `day` is the calendar day here: the history groups readings by the day
            // they were taken (no 04:00 border, which is about daily totals).
            rs = tx.executeSql('SELECT id, timestamp, value, note, DATE(timestamp) AS day FROM HealthLogs ' +
                'WHERE profileId=? AND metricId=' + METRIC_ID + ' ORDER BY timestamp DESC' + page,
                [profileId, metricName]);
            for (i = 0; i < rs.rows.length; i++) {
                rows.push(rs.rows.item(i));
            }
        }
    });
    // One insertion for the whole history instead of one model update per row.
    if (rows.length > 0) {
        a_model.append(rows);
    }
    return totals;
}

// How many readings a metric has, to know whether the history list shows them all.
function countLogs(profileId, metricName) {
    var count = 0;
    db().transaction(function (tx) {
        count = tx.executeSql('SELECT count(*) AS count FROM HealthLogs WHERE profileId=? AND metricId=' + METRIC_ID,
                              [profileId, metricName]).rows.item(0).count;
    });
    return count;
}

// Timestamp-ordered logs (oldest first) as a plain array. Used for chart pairing.
function getLogsAscending(profileId, metricName, sinceIso) {
    var logs = [];
    db().transaction(function (tx) {
        var query = 'SELECT id, timestamp, value, note FROM HealthLogs ' +
            'WHERE profileId=? AND metricId=' + METRIC_ID;
        var params = [profileId, metricName];
        if (sinceIso) {
            query += ' AND timestamp >= ?';
            params.push(sinceIso);
        }
        query += ' ORDER BY timestamp ASC';
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
 *
 * SERIES_WEEKLY and SERIES_MONTHLY are for grouped metrics over long ranges: the daily
 * totals averaged over the days logged in each week (Monday first) or month, so a year
 * is 53 bars rather than 365. An average and not a sum, so the bars read against the
 * daily goal and the per-day statistics, and a week only partly in the range, or with
 * days nothing was logged, is not drawn as a low week. t is the period's first day.
 */
function getSeries(profileId, metricName, sinceIso, mode) {
    var points = [];
    db().transaction(function (tx) {
        var query;
        var params;
        var rs;
        var i;

        if (mode === SERIES_DAILY_SUM || mode === SERIES_DAILY_AVG
                || mode === SERIES_WEEKLY || mode === SERIES_MONTHLY) {
            // One row per day; weekly and monthly bars then average the daily totals.
            var agg = (mode === SERIES_DAILY_AVG) ? "AVG" : "SUM";
            var key = "day";
            query = 'SELECT DATE(timestamp, ?) AS day, ' + agg + '(value) AS v ' +
                'FROM HealthLogs WHERE profileId=? AND metricId=' + METRIC_ID;
            params = ["-" + DAY_START_TIME, profileId, metricName];
            if (sinceIso) {
                query += ' AND timestamp >= ?';
                params.push(sinceIso);
            }
            query += ' GROUP BY day';
            if (mode === SERIES_WEEKLY || mode === SERIES_MONTHLY) {
                // 'weekday 0' moves to the coming Sunday (a Sunday stays put); six days
                // back from it is that week's Monday.
                var period = (mode === SERIES_WEEKLY) ? "DATE(day, 'weekday 0', '-6 days')"
                                                      : "DATE(day, 'start of month')";
                key = "period";
                query = 'SELECT ' + period + ' AS period, AVG(v) AS v FROM (' + query + ') GROUP BY period';
            }
            query += ' ORDER BY ' + key + ' ASC';
            rs = tx.executeSql(query, params);
            for (i = 0; i < rs.rows.length; i++) {
                points.push({ t: timestampToMs(rs.rows.item(i)[key]), v: rs.rows.item(i).v });
            }
        } else {
            query = 'SELECT timestamp AS ts, value AS v FROM HealthLogs ' +
                'WHERE profileId=? AND metricId=' + METRIC_ID;
            params = [profileId, metricName];
            if (sinceIso) {
                query += ' AND timestamp >= ?';
                params.push(sinceIso);
            }
            query += ' ORDER BY timestamp ASC';
            rs = tx.executeSql(query, params);
            for (i = 0; i < rs.rows.length; i++) {
                points.push({ t: timestampToMs(rs.rows.item(i).ts), v: rs.rows.item(i).v });
            }
        }
    });
    return points;
}

// The first reading's timestamp, or null: how far back "All" reaches.
function getFirstLogTimestamp(profileId, metricName) {
    var first = null;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT MIN(timestamp) AS first FROM HealthLogs WHERE profileId=? AND metricId=' +
            METRIC_ID, [profileId, metricName]);
        if (rs.rows.length > 0 && rs.rows.item(0).first) {
            first = String(rs.rows.item(0).first);
        }
    });
    return first;
}

// min / max / average / count over the same window, aggregated by SQLite.
function getSeriesStats(profileId, metricName, sinceIso, mode) {
    var stats = { min: null, max: null, avg: null, count: 0 };
    db().transaction(function (tx) {
        var query;
        var params;

        if (mode === SERIES_DAILY_SUM || mode === SERIES_DAILY_AVG) {
            var agg = (mode === SERIES_DAILY_SUM) ? "SUM" : "AVG";
            var inner = 'SELECT ' + agg + '(value) AS v FROM HealthLogs ' +
                'WHERE profileId=? AND metricId=' + METRIC_ID;
            params = [profileId, metricName];
            if (sinceIso) {
                inner += ' AND timestamp >= ?';
                params.push(sinceIso);
            }
            inner += ' GROUP BY DATE(timestamp, ?)';
            params.push("-" + DAY_START_TIME);
            query = 'SELECT MIN(v) AS mn, MAX(v) AS mx, AVG(v) AS av, COUNT(*) AS ct FROM (' + inner + ')';
        } else {
            query = 'SELECT MIN(value) AS mn, MAX(value) AS mx, AVG(value) AS av, COUNT(*) AS ct ' +
                'FROM HealthLogs WHERE profileId=? AND metricId=' + METRIC_ID;
            params = [profileId, metricName];
            if (sinceIso) {
                query += ' AND timestamp >= ?';
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
 * Waist-to-height ratio from the latest waist and height, both in cm. An estimate
 * of abdominal fat that, unlike BMI, does not count muscle. Null until both exist,
 * which keeps the ratio hidden until it means something.
 */
function calcWHtR(profileId) {
    var height = getLatestLogValue(profileId, METRIC_HEIGHT);
    var waist = getLatestLogValue(profileId, METRIC_WAIST);
    if (!height || !waist) {
        return null;
    }
    return waist / height;
}

/*
 * History of a value derived from another metric and height: one point per reading
 * of metricName, using the height that was current at that moment. Both series
 * arrive sorted, so a single merge pass is enough.
 * compute(value, heightCm) returns the derived value; decimals rounds it.
 */
function getHeightBasedSeries(profileId, sinceIso, metricName, compute, decimals) {
    // Height changes rarely, so the whole height history is needed even for a short
    // window -- the applicable height may have been recorded long before it.
    var heights = getLogsAscending(profileId, METRIC_HEIGHT, null);
    var readings = getLogsAscending(profileId, metricName, sinceIso);
    var points = [];
    if (heights.length === 0) {
        return points;
    }

    var factor = Math.pow(10, decimals);
    var hIndex = 0;
    // Before the first height reading there is nothing better to use than the first one.
    var currentHeight = heights[0].value;
    for (var i = 0; i < readings.length; i++) {
        var r = readings[i];
        var rMs = timestampToMs(r.timestamp);
        while (hIndex < heights.length && timestampToMs(heights[hIndex].timestamp) <= rMs) {
            currentHeight = heights[hIndex].value;
            hIndex++;
        }
        if (!currentHeight || !r.value) {
            continue;
        }
        points.push({ t: rMs, v: Math.round(compute(r.value, currentHeight) * factor) / factor });
    }
    return points;
}

// BMI history: one point per weight reading.
function getBMISeries(profileId, sinceIso) {
    return getHeightBasedSeries(profileId, sinceIso, METRIC_WEIGHT, function (weight, heightCm) {
        var metres = heightCm / 100;
        return weight / (metres * metres);
    }, 1);
}

// Waist-to-height history: one point per waist reading.
function getWHtRSeries(profileId, sinceIso) {
    return getHeightBasedSeries(profileId, sinceIso, METRIC_WAIST, function (waist, heightCm) {
        return waist / heightCm;
    }, 2);
}

// Vaccine Operations
/*
 * The profile's vaccines -- the mandatory ones and any with an injection -- by name,
 * with how many doses were recorded and the latest date: [{id, name, doses, lastDate}].
 * One grouped query; the pages used to fetch every injection of each vaccine in turn.
 */
function getVaccineSummaries(profileId) {
    var vaccines = [];
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT v.id AS id, v.name AS name, COUNT(i.id) AS doses, MAX(i.date) AS lastDate ' +
            'FROM Vaccines v LEFT JOIN Injections i ON v.id = i.vaccineId AND i.profileId = ? ' +
            'WHERE v.isMandatory = 1 OR i.id IS NOT NULL GROUP BY v.id ORDER BY v.name', [profileId]);
        for (var i = 0; i < rs.rows.length; i++) {
            var row = rs.rows.item(i);
            vaccines.push({
                id: row.id,
                name: row.name ? String(row.name) : "",
                doses: row.doses,
                lastDate: row.lastDate ? String(row.lastDate) : ""
            });
        }
    });
    return vaccines;
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

function updateVaccineLog(id, date, note) {
    db().transaction(function (tx) {
        tx.executeSql('UPDATE Injections SET date=?, note=? WHERE id=?', [date, note || "", id]);
    });
}

function getVaccineLog(id) {
    var log = null;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT i.id AS id, i.vaccineId AS vaccineId, i.date AS date, i.note AS note, ' +
            'v.name AS name FROM Injections i JOIN Vaccines v ON v.id = i.vaccineId WHERE i.id=?', [id]);
        if (rs.rows.length > 0) {
            log = rs.rows.item(0);
        }
    });
    return log;
}

/*
 * Vaccine names are shared by all profiles and created on the first injection. One
 * that no injection uses any more (its last dose deleted, or its profile) would stay
 * in every backup for good; the mandatory ones are a fixed list and stay. Run when a
 * profile is deleted and at every start.
 */
function _deleteUnusedVaccines(tx) {
    tx.executeSql('DELETE FROM Vaccines WHERE COALESCE(isMandatory, 0) = 0 ' +
        'AND id NOT IN (SELECT vaccineId FROM Injections)');
}

// The vaccine's name stays for now: its page is still open and can record another
// injection under the same id. Names left without one go at the next start.
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

/*
 * The profile's medication of this name, compared without case, or a new one. Every
 * treatment used to get a medication of its own, so the same one prescribed for two
 * conditions was listed twice, with its intakes counted apart.
 */
function _medicationFor(tx, profileId, name, exceptId) {
    var rs = tx.executeSql('SELECT m.id AS id FROM Medications m JOIN Treatments t ON t.medicationId = m.id ' +
        'WHERE t.profileId=? AND m.name=? COLLATE NOCASE AND m.id<>? ORDER BY m.id LIMIT 1',
        [profileId, name, exceptId === undefined ? -1 : exceptId]);
    if (rs.rows.length > 0) {
        return rs.rows.item(0).id;
    }
    return tx.executeSql('INSERT INTO Medications (name, type, unit) VALUES (?, ?, ?)', [name, "pill", "mg"]).insertId;
}

// A treatment by its medication's name; the medication is found or created with it.
function addTreatmentFor(profileId, medicationName, conditionId, dosage, frequency, startDate, endDate, note) {
    return _write(function (tx) {
        var medicationId = _medicationFor(tx, profileId, medicationName);
        return tx.executeSql('INSERT INTO Treatments (profileId, medicationId, conditionId, dosage, frequency, startDate, endDate, note) ' +
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [profileId, medicationId, conditionId, dosage, frequency, startDate, endDate, note]).insertId;
    });
}

/*
 * Gives a treatment's medication another name, keeping its intakes. The name could not
 * be edited at all, and the only way to fix a typo -- delete the treatment and add it
 * again -- deleted every intake logged for it.
 *
 * Its medication is renamed when no other treatment uses it. When the profile already
 * has one of the new name the treatment joins that one, intakes included. When other
 * treatments share its medication they keep it, with the intakes, and this treatment
 * gets a new one.
 */
function setTreatmentMedicationName(treatmentId, name) {
    _write(function (tx) {
        var rs = tx.executeSql('SELECT t.profileId AS profileId, t.medicationId AS medicationId, m.name AS name ' +
            'FROM Treatments t LEFT JOIN Medications m ON m.id = t.medicationId WHERE t.id=?', [treatmentId]);
        if (rs.rows.length === 0 || rs.rows.item(0).name === name) {
            return;
        }
        var current = rs.rows.item(0);
        var shared = tx.executeSql('SELECT count(*) AS count FROM Treatments WHERE medicationId=? AND id<>?',
                                   [current.medicationId, treatmentId]).rows.item(0).count > 0;
        var existing = tx.executeSql('SELECT m.id AS id FROM Medications m JOIN Treatments t ON t.medicationId = m.id ' +
            'WHERE t.profileId=? AND m.name=? COLLATE NOCASE AND m.id<>? ORDER BY m.id LIMIT 1',
            [current.profileId, name, current.medicationId]);
        if (existing.rows.length > 0) {
            var target = existing.rows.item(0).id;
            tx.executeSql('UPDATE Treatments SET medicationId=? WHERE id=?', [target, treatmentId]);
            if (!shared) {
                tx.executeSql('UPDATE MedicationLogs SET medicationId=? WHERE medicationId=?',
                              [target, current.medicationId]);
            }
        } else if (!shared && current.medicationId !== null) {
            tx.executeSql('UPDATE Medications SET name=? WHERE id=?', [name, current.medicationId]);
        } else {
            var created = tx.executeSql('INSERT INTO Medications (name, type, unit) VALUES (?, ?, ?)',
                                        [name, "pill", "mg"]).insertId;
            tx.executeSql('UPDATE Treatments SET medicationId=? WHERE id=?', [created, treatmentId]);
        }
        deleteOrphanedMedications(tx);
    });
}

/*
 * How many logged intakes go when a treatment, or a condition with its treatments, is
 * deleted: those of the medications nothing else will use afterwards. The delete's
 * countdown says so, where it used to say only "Deleting".
 */
function countIntakesOfTreatment(treatmentId) {
    var count = 0;
    db().transaction(function (tx) {
        count = tx.executeSql('SELECT count(*) AS count FROM MedicationLogs WHERE medicationId IN ' +
            '(SELECT medicationId FROM Treatments WHERE id=?) AND medicationId NOT IN ' +
            '(SELECT medicationId FROM Treatments WHERE id<>? AND medicationId IS NOT NULL)',
            [treatmentId, treatmentId]).rows.item(0).count;
    });
    return count;
}

function countIntakesOfCondition(conditionId) {
    var count = 0;
    db().transaction(function (tx) {
        count = tx.executeSql('SELECT count(*) AS count FROM MedicationLogs WHERE medicationId IN ' +
            '(SELECT medicationId FROM Treatments WHERE conditionId=?) AND medicationId NOT IN ' +
            '(SELECT medicationId FROM Treatments WHERE (conditionId IS NULL OR conditionId<>?) ' +
            'AND medicationId IS NOT NULL)', [conditionId, conditionId]).rows.item(0).count;
    });
    return count;
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

/*
 * Every treatment gets its own Medications row, and intake logs hang off that row.
 * Removing the last treatment (directly, with its condition or with the profile)
 * used to leave both behind, and they still went into every export.
 */
function deleteOrphanedMedications(tx) {
    var used = 'SELECT medicationId FROM Treatments WHERE medicationId IS NOT NULL';
    tx.executeSql('DELETE FROM MedicationLogs WHERE medicationId NOT IN (' + used + ')');
    tx.executeSql('DELETE FROM Medications WHERE id NOT IN (' + used + ')');
}

function deleteTreatment(id) {
    _write(function (tx) {
        tx.executeSql('DELETE FROM Treatments WHERE id=?', [id]);
        deleteOrphanedMedications(tx);
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
    _write(function (tx) {
        // Treatments hang off the condition and would otherwise be orphaned.
        tx.executeSql('DELETE FROM Treatments WHERE conditionId=?', [id]);
        tx.executeSql('DELETE FROM HealthConditions WHERE id=?', [id]);
        deleteOrphanedMedications(tx);
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

/*
 * The daily entries of one cycle, newest first: from its start up to the day before
 * the next cycle starts (nextStart "" for the newest cycle: no upper end). The end
 * date is not the bound -- it is the period's last day, and the days after it belong
 * to the same cycle.
 */
function getMenstrualLogsOfCycle(profileId, startDate, nextStart) {
    var logs = [];
    db().transaction(function (tx) {
        var query = 'SELECT * FROM MenstrualLogs WHERE profileId=? AND date >= ?';
        var params = [profileId, startDate];
        if (nextStart) {
            query += ' AND date < ?';
            params.push(nextStart);
        }
        var rs = tx.executeSql(query + ' ORDER BY date DESC', params);
        for (var i = 0; i < rs.rows.length; i++) {
            logs.push(rs.rows.item(i));
        }
    });
    return logs;
}

function getMenstrualCycle(id) {
    var cycle = null;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT * FROM MenstrualCycles WHERE id=?', [id]);
        if (rs.rows.length > 0) {
            cycle = rs.rows.item(0);
        }
    });
    return cycle;
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
    return averageCycleLength(getMenstrualCycles(profileId));
}

/*
 * Where the cycle stands today, for the cycle page and its dashboard row:
 * {last, periodOpen, dayOfCycle, averageLength, nextStart}. last is the newest cycle
 * (null with none); its start is day 1 (0 without one) and the days count on until the
 * next cycle starts. A cycle's end date is the last day of its period: periodOpen says
 * the period has no end yet. averageLength is null with fewer than two cycles,
 * nextStart "YYYY-MM-DD" or "".
 */
function getCycleStatus(profileId) {
    var cycles = getMenstrualCycles(profileId);
    var status = { last: null, periodOpen: false, dayOfCycle: 0, averageLength: averageCycleLength(cycles), nextStart: "" };
    if (cycles.length === 0) {
        return status;
    }
    status.last = cycles[0];
    status.periodOpen = !cycles[0].endDate;
    var startMs = timestampToMs(cycles[0].startDate);
    if (!isNaN(startMs)) {
        var start = new Date(startMs);
        var today = new Date();
        today.setHours(0, 0, 0, 0);
        // Rounded: across the spring clock change two local midnights are an hour short
        // of whole days, and flooring lost a day.
        status.dayOfCycle = Math.round((today.getTime() - startMs) / 86400000) + 1;
        if (status.averageLength !== null) {
            status.nextStart = toTimestamp(new Date(start.getFullYear(), start.getMonth(),
                                                    start.getDate() + status.averageLength)).substring(0, 10);
        }
    }
    return status;
}

// The same for cycles already loaded (getMenstrualCycles order: newest first).
function averageCycleLength(cycles) {
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

/*
 * What the meditation page shows: {total, weekCount, weekSeconds, recent}, recent being
 * the newest `limit` sessions [{date, duration, name}]. weekStart is a Date, the
 * DAY_START_TIME moment the week begins at, so a session at 01:00 on Monday counts for
 * the week it counts for as a day (Sunday's goal).
 */
function getMeditationSummary(profileId, weekStart, limit) {
    var summary = { total: 0, weekCount: 0, weekSeconds: 0, recent: [] };
    var since = toTimestamp(weekStart);
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT COUNT(*) AS total, ' +
            'SUM(CASE WHEN date >= ? THEN 1 ELSE 0 END) AS weekCount, ' +
            'SUM(CASE WHEN date >= ? THEN COALESCE(duration, 0) ELSE 0 END) AS weekSeconds ' +
            'FROM MeditationSessions WHERE profileId=?', [since, since, profileId]);
        summary.total = rs.rows.item(0).total || 0;
        summary.weekCount = rs.rows.item(0).weekCount || 0;
        summary.weekSeconds = rs.rows.item(0).weekSeconds || 0;
        rs = tx.executeSql('SELECT date, duration, name FROM MeditationSessions WHERE profileId=? ' +
            'ORDER BY date DESC LIMIT ?', [profileId, limit]);
        for (var i = 0; i < rs.rows.length; i++) {
            var row = rs.rows.item(i);
            summary.recent.push({ date: String(row.date), duration: row.duration || 0, name: row.name ? String(row.name) : "" });
        }
    });
    return summary;
}

// Seconds meditated today (the DAY_START_TIME day), for the daily meditation goal.
function getMeditationSecondsToday(profileId) {
    var seconds = 0;
    db().transaction(function (tx) {
        seconds = _meditationSecondsToday(tx, profileId);
    });
    return seconds;
}

function _meditationSecondsToday(tx, profileId) {
    var today = _todayRange();
    var rs = tx.executeSql('SELECT SUM(COALESCE(duration, 0)) AS seconds FROM MeditationSessions ' +
        'WHERE profileId=? AND date >= ? AND date < ?', [profileId, today[0], today[1]]);
    return rs.rows.item(0).seconds || 0;
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

/*
 * Today's intakes. "Today" starts at DAY_START_TIME like the daily totals: it used to
 * start at midnight, so between midnight and 04:00 the medications and the water of
 * the same evening were counted for different days.
 */
function getMedicationLogsToday(profileId, medicationId) {
    var logs = [];
    var today = _todayRange();
    db().transaction(function (tx) {
        var rs = tx.executeSql(
            "SELECT * FROM MedicationLogs WHERE profileId=? AND medicationId=? " +
            "AND timestamp >= ? AND timestamp < ? ORDER BY timestamp DESC",
            [profileId, medicationId, today[0], today[1]]);
        for (var i = 0; i < rs.rows.length; i++) {
            logs.push(rs.rows.item(i));
        }
    });
    return logs;
}

/*
 * Today's intakes of all the profile's medications in one query:
 * {medicationId: {count, last}}, last being the latest timestamp.
 */
function getMedicationTodaySummary(profileId) {
    var summary = {};
    db().transaction(function (tx) {
        summary = _medicationTodaySummary(tx, profileId);
    });
    return summary;
}

function _medicationTodaySummary(tx, profileId) {
    var summary = {};
    var today = _todayRange();
    var rs = tx.executeSql(
        "SELECT medicationId, COUNT(*) AS count, MAX(timestamp) AS last FROM MedicationLogs " +
        "WHERE profileId=? AND timestamp >= ? AND timestamp < ? GROUP BY medicationId",
        [profileId, today[0], today[1]]);
    for (var i = 0; i < rs.rows.length; i++) {
        var row = rs.rows.item(i);
        summary[row.medicationId] = { count: row.count, last: String(row.last) };
    }
    return summary;
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

/*
 * The medications the profile is on today, [{id, name}] by name: a treatment that has
 * started and not ended (an empty date leaves that side open), for a condition that is
 * not recovered or over. Two treatments with the same medication are one entry, as the
 * intakes are logged per medication. Today is the DAY_START_TIME day.
 */
function getActiveMedicationsToday(profileId) {
    var medications = [];
    db().transaction(function (tx) {
        medications = _activeMedicationsToday(tx, profileId);
    });
    return medications;
}

function _activeMedicationsToday(tx, profileId) {
    var medications = [];
    var today = toTimestamp(dayStart()).substring(0, 10);
    var rs = tx.executeSql('SELECT DISTINCT m.id AS id, m.name AS name FROM Treatments t ' +
        'JOIN Medications m ON m.id = t.medicationId ' +
        'LEFT JOIN HealthConditions c ON c.id = t.conditionId ' +
        "WHERE t.profileId=? AND (t.startDate IS NULL OR t.startDate = '' OR t.startDate <= ?) " +
        "AND (t.endDate IS NULL OR t.endDate = '' OR t.endDate >= ?) " +
        'AND (c.id IS NULL OR (' + _ongoingConditionSql("c.") + ')) ORDER BY m.name',
        [profileId, today, today, today]);
    for (var i = 0; i < rs.rows.length; i++) {
        medications.push({ id: rs.rows.item(i).id, name: rs.rows.item(i).name ? String(rs.rows.item(i).name) : "" });
    }
    return medications;
}

// Module Settings
/*
 * Modules in display order: the order the profile arranged (ModuleOrder), then, for
 * anything never arranged, by category and the order they were defined, so related
 * cards sit together (Weight, Height, BMI, Waist, WHtR). Sorting on the stored English
 * names put WHtR before Waist and made no sense once translated.
 *
 * unit and grouped come along for metric modules ('' and 0 otherwise, so the model
 * roles keep one type) -- every tile used to look both up with queries of its own.
 */
function addModulesToModel(profileId, a_model, on_only) {
    var modules = getModules(profileId, on_only);
    if (modules.length > 0) {
        a_model.append(modules);
    }
}

function getModules(profileId, on_only) {
    var modules = [];
    db().transaction(function (tx) {
        modules = _modules(tx, profileId, on_only);
    });
    return modules;
}

function _modules(tx, profileId, on_only) {
    var modules = [];
    var categoryRank = 'CASE Modules.category ' + CATEGORY_ORDER.map(function (category, rank) {
        return 'WHEN ? THEN ' + rank;
    }).join(' ') + ' ELSE ' + CATEGORY_ORDER.length + ' END';
    var rs = tx.executeSql('SELECT Modules.id, Modules.name, Modules.type, Modules.category, Modules.uses, Modules.icon, ' +
        "COALESCE(Metrics.unit, '') AS unit, COALESCE(Metrics.grouped, 0) AS grouped, " +
        '(SELECT ProfileModules.profileId FROM ProfileModules WHERE Modules.id=ProfileModules.moduleId AND ProfileModules.profileId=?) IS NOT NULL AS is_on ' +
        // Blood pressure has no metric of its own: it shows the systolic unit.
        'FROM Modules LEFT JOIN Metrics ON Metrics.name = CASE WHEN Modules.type=? THEN Modules.uses ' +
        'WHEN Modules.uses=? THEN ? END ' +
        'LEFT JOIN ModuleOrder ON ModuleOrder.profileId=? AND ModuleOrder.moduleId=Modules.id ' +
        (on_only ? 'WHERE is_on ' : '') +
        'ORDER BY ModuleOrder.position IS NULL, ModuleOrder.position, ' + categoryRank + ', Modules.id',
        [profileId, MODULE_TYPE_METRIC, CALC_BP, METRIC_BP_SYS, profileId].concat(CATEGORY_ORDER));
    for (var i = 0; i < rs.rows.length; i++) {
        modules.push(rs.rows.item(i));
    }
    return modules;
}

// Saves the dashboard order for a profile: moduleIds first to last, shown or not.
function setModuleOrder(profileId, moduleIds) {
    _write(function (tx) {
        tx.executeSql('DELETE FROM ModuleOrder WHERE profileId=?', [profileId]);
        for (var i = 0; i < moduleIds.length; i++) {
            tx.executeSql('INSERT INTO ModuleOrder (profileId, moduleId, position) VALUES (?,?,?)',
                [profileId, moduleIds[i], i]);
        }
    });
}

// Back to the default order (by category).
function resetModuleOrder(profileId) {
    db().transaction(function (tx) {
        tx.executeSql('DELETE FROM ModuleOrder WHERE profileId=?', [profileId]);
    });
}

// Daily goal for a metric: the user's, else the default, else null (no goal).
function getGoal(profileId, metricName) {
    var goal = null;
    db().transaction(function (tx) {
        goal = _goal(tx, profileId, metricName);
    });
    return goal;
}

function _goal(tx, profileId, metricName) {
    var rs = tx.executeSql('SELECT value FROM Goals WHERE profileId=? AND metricName=?', [profileId, metricName]);
    if (rs.rows.length > 0) {
        return rs.rows.item(0).value;
    }
    return DEFAULT_GOALS.hasOwnProperty(metricName) ? DEFAULT_GOALS[metricName] : null;
}

/*
 * 0 switches a goal off: the ring and the Today item go. A row is kept rather than
 * deleted, because water and calories would fall back to their default goal.
 */
function setGoal(profileId, metricName, value) {
    db().transaction(function (tx) {
        tx.executeSql('INSERT OR REPLACE INTO Goals (profileId, metricName, value) VALUES (?,?,?)',
            [profileId, metricName, value]);
    });
}

// A goal or target that is set: the value, or null when there is none or it is off.
function getActiveGoal(profileId, metricName) {
    var goal = getGoal(profileId, metricName);
    return goal !== null && goal > 0 ? goal : null;
}

/*
 * A health condition that is still going on, as SQL: no end date yet (or one still
 * ahead, bound as a "YYYY-MM-DD" parameter), and not marked recovered. `prefix` is
 * the table alias with its dot ("c."), or "" for none. The status is compared without
 * case: version 1.0 stored whatever was typed, "recovered" included.
 */
function _ongoingConditionSql(prefix) {
    return "(" + prefix + "endDate IS NULL OR " + prefix + "endDate = '' OR " + prefix + "endDate >= ?) " +
        "AND LOWER(TRIM(COALESCE(" + prefix + "status, ''))) <> 'recovered'";
}

/*
 * What the dashboard says about health conditions: how many are ongoing and the
 * newest of those. Ongoing = no end date yet (or one still ahead), and not marked
 * recovered.
 */
function getConditionSummary(profileId) {
    var summary = { total: 0, active: 0, latestActive: "" };
    var today = toTimestamp(new Date()).substring(0, 10);
    var ongoing = _ongoingConditionSql("");
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT COUNT(*) AS total, SUM(CASE WHEN ' + ongoing + ' THEN 1 ELSE 0 END) AS active ' +
            'FROM HealthConditions WHERE profileId=?', [today, profileId]);
        summary.total = rs.rows.item(0).total || 0;
        summary.active = rs.rows.item(0).active || 0;
        rs = tx.executeSql('SELECT name FROM HealthConditions WHERE profileId=? AND ' + ongoing +
            ' ORDER BY startDate DESC LIMIT 1', [profileId, today]);
        if (rs.rows.length > 0) {
            summary.latestActive = rs.rows.item(0).name || "";
        }
    });
    return summary;
}

// Most recent vaccine injection: {name, date}, or null.
function getLatestInjection(profileId) {
    var last = null;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT v.name AS name, i.date AS date FROM Injections i ' +
            'JOIN Vaccines v ON v.id = i.vaccineId WHERE i.profileId=? ORDER BY i.date DESC LIMIT 1', [profileId]);
        if (rs.rows.length > 0) {
            last = { name: rs.rows.item(0).name, date: String(rs.rows.item(0).date) };
        }
    });
    return last;
}

// Most recent meditation session: {date, duration (seconds)}, or null.
function getLatestMeditation(profileId) {
    var last = null;
    db().transaction(function (tx) {
        var rs = tx.executeSql('SELECT date, duration FROM MeditationSessions WHERE profileId=? ORDER BY date DESC LIMIT 1',
            [profileId]);
        if (rs.rows.length > 0) {
            last = { date: String(rs.rows.item(0).date), duration: rs.rows.item(0).duration || 0 };
        }
    });
    return last;
}

/*
 * The day's to-do list (Today page, its dashboard row and the cover): everything with
 * a target for today, from the modules the profile has switched on.
 *
 *  - {kind: "goal", metricName, unit, total, goal, done, shownUnit, factor,
 *    unitDecimals}: each daily total with a goal (water, calories eaten, calories burned);
 *  - {kind: "meditation", metricName: GOAL_MEDITATION, total, goal, done}: once a
 *    meditation goal is set, total and goal in minutes;
 *  - {kind: "medication", medicationId, name, count, last, done}: each medication the
 *    profile is on today. How often it is due is free text, so "done" means taken at
 *    least once today.
 *
 * Returns {items, left}: what is still to do first, in that order, and how many.
 */
// Whether a total meets its goal. Sums of decimals (0.1 + 0.2) fall a hair short.
function _reached(total, goal) {
    return total >= goal - 1e-9;
}

/*
 * How many days in a row a daily goal was met, for the Today page. Counted back from
 * today when today's goal is already met, otherwise from yesterday: a streak is not
 * lost in the morning. Days are DAY_START_TIME days, over the last year at most, and
 * measured against today's goal -- past goals are not kept.
 * metricName is a daily-total metric or GOAL_MEDITATION (goal in minutes).
 */
function getGoalStreak(profileId, metricName, goal) {
    if (!(goal > 0)) {
        return 0;
    }
    var totals = {};
    var since = dayStart();
    since.setDate(since.getDate() - 366);
    var border = "-" + DAY_START_TIME;
    db().transaction(function (tx) {
        var rs;
        if (metricName === GOAL_MEDITATION) {
            rs = tx.executeSql('SELECT DATE(date, ?) AS day, SUM(COALESCE(duration, 0)) / 60.0 AS total ' +
                'FROM MeditationSessions WHERE profileId=? AND date >= ? GROUP BY day',
                [border, profileId, toTimestamp(since)]);
        } else {
            rs = tx.executeSql('SELECT DATE(timestamp, ?) AS day, SUM(value) AS total FROM HealthLogs ' +
                'WHERE profileId=? AND metricId=' + METRIC_ID + ' AND timestamp >= ? GROUP BY day',
                [border, profileId, metricName, toTimestamp(since)]);
        }
        for (var i = 0; i < rs.rows.length; i++) {
            totals[rs.rows.item(i).day] = rs.rows.item(i).total;
        }
    });

    function met(date) {
        var total = totals[toTimestamp(date).substring(0, 10)];
        return total !== undefined && total !== null && _reached(total, goal);
    }
    var day = dayStart();
    if (!met(day)) {
        day.setDate(day.getDate() - 1);
    }
    var streak = 0;
    while (streak < 366 && met(day)) {
        streak++;
        day.setDate(day.getDate() - 1);
    }
    return streak;
}

function getTodayPlan(profileId) {
    var todo = [];
    var done = [];
    function add(item) {
        (item.done ? done : todo).push(item);
    }

    // One transaction for the lot: the dashboard row, the Today page and the cover all
    // build this, and it used to open about ten.
    db().transaction(function (tx) {
        var modules = _modules(tx, profileId, true);
        var meditationOn = false;
        var conditionsOn = false;
        for (var i = 0; i < modules.length; i++) {
            var mod = modules[i];
            if (mod.type === MODULE_TYPE_METRIC && mod.grouped) {
                var goal = _goal(tx, profileId, mod.uses);
                if (goal !== null && goal > 0) {
                    var total = _todayTotal(tx, profileId, mod.uses) || 0;
                    // total and goal are stored values. shownUnit, factor and unitDecimals
                    // are how Utils.todayItem*() show them in the unit chosen in Units
                    // (utils.js cannot ask this library itself).
                    add({ kind: "goal", metricName: mod.uses, unit: mod.unit, total: total, goal: goal,
                          shownUnit: displayUnit(mod.uses, mod.unit), factor: _unitFactor(mod.uses),
                          unitDecimals: displayDecimals(mod.uses, -1),
                          done: _reached(total, goal) });
                }
            } else if (mod.name === MODULE_MEDITATION) {
                meditationOn = true;
            } else if (mod.name === MODULE_CONDITION) {
                conditionsOn = true;
            }
        }

        if (meditationOn) {
            var minutes = _goal(tx, profileId, GOAL_MEDITATION);
            if (minutes !== null && minutes > 0) {
                var seconds = _meditationSecondsToday(tx, profileId);
                add({ kind: "meditation", metricName: GOAL_MEDITATION, total: seconds / 60, goal: minutes,
                      done: seconds >= minutes * 60 });
            }
        }

        if (conditionsOn) {
            var medications = _activeMedicationsToday(tx, profileId);
            var taken = medications.length > 0 ? _medicationTodaySummary(tx, profileId) : {};
            for (var m = 0; m < medications.length; m++) {
                var intake = taken[medications[m].id];
                add({ kind: "medication", medicationId: medications[m].id, name: medications[m].name,
                      count: intake ? intake.count : 0, last: intake ? intake.last : "",
                      done: intake ? true : false });
            }
        }
    });

    return { items: todo.concat(done), left: todo.length };
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
/*
 * Bands per metric, cached: every dashboard card and history page reads them on each
 * refresh, and they only change through the functions below or a restore, which clear
 * the cache.
 */
var _constraintCache = {};

function getConstraintsForMetric(metricName) {
    if (_constraintCache.hasOwnProperty(metricName)) {
        return _constraintCache[metricName];
    }
    var constraints = [];
    db().transaction(function (tx) {
        // NULL minimum means "no lower bound", so it has to sort first.
        var rs = tx.executeSql('SELECT * FROM MetricConstraints WHERE metricName=? ' +
            'ORDER BY minValue IS NOT NULL, minValue ASC', [metricName]);
        for (var i = 0; i < rs.rows.length; i++) {
            constraints.push(rs.rows.item(i));
        }
    });
    _constraintCache[metricName] = constraints;
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

// How concerning a band colour is, for picking one band out of several readings.
var CONSTRAINT_SEVERITY = { "green": 0, "blue": 1, "orange": 2, "red": 3 };

/*
 * The most concerning band across several readings, as {label, color}, or null.
 * Used for paired readings such as blood pressure, where systolic and diastolic each
 * have their own bands: 120/95 is judged by its diastolic half.
 * pairs: [{ metricName, value }, ...]
 */
function matchWorstConstraint(pairs) {
    var worst = null;
    var worstRank = -1;
    for (var i = 0; i < pairs.length; i++) {
        var match = matchConstraint(pairs[i].metricName, pairs[i].value);
        if (match === null) {
            continue;
        }
        var rank = CONSTRAINT_SEVERITY.hasOwnProperty(match.color) ? CONSTRAINT_SEVERITY[match.color] : 0;
        if (rank > worstRank) {
            worst = match;
            worstRank = rank;
        }
    }
    return worst;
}

function addConstraint(metricName, label, minValue, maxValue, color) {
    _constraintCache = {};
    db().transaction(function (tx) {
        tx.executeSql('INSERT INTO MetricConstraints (metricName, label, minValue, maxValue, color) VALUES (?,?,?,?,?)',
            [metricName, label, minValue, maxValue, color]);
    });
}

function updateConstraint(id, label, minValue, maxValue, color) {
    _constraintCache = {};
    db().transaction(function (tx) {
        tx.executeSql('UPDATE MetricConstraints SET label=?, minValue=?, maxValue=?, color=? WHERE id=?',
            [label, minValue, maxValue, color, id]);
    });
}

function deleteConstraint(id) {
    _constraintCache = {};
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
    return _dump(db(), ALL_TABLES, DB_SCHEMA_VERSION);
}

// Every row of `tables`, read in one transaction so the copy is consistent.
function _dump(handle, tables, schemaVersion) {
    var dump = {
        format: "harbour-health-backup",
        schemaVersion: schemaVersion,
        exportedAt: toTimestamp(new Date()),
        tables: {}
    };
    handle.readTransaction(function (tx) {
        for (var i = 0; i < tables.length; i++) {
            var rows = [];
            var rs = tx.executeSql('SELECT * FROM ' + tables[i]);
            for (var j = 0; j < rs.rows.length; j++) {
                var item = rs.rows.item(j);
                var plain = {};
                for (var key in item) {
                    plain[key] = item[key];
                }
                rows.push(plain);
            }
            dump.tables[tables[i]] = rows;
        }
    });
    return dump;
}

/*
 * CSV files for spreadsheets: [{name, content}], one per kind of data, those without a
 * row left out. Measurements used to be the only one; everything else was in the JSON
 * backup alone. Values are in the stored units, named in a column, whatever units the
 * app shows. Each file starts with a byte order mark, which is how spreadsheets tell
 * UTF-8 from the local code page ("Zoé" otherwise comes out as "ZoÃ©").
 */
function exportCsvFiles() {
    function quote(v) {
        if (v === null || v === undefined) {
            return "";
        }
        return '"' + String(v).replace(/"/g, '""') + '"';
    }

    /*
     * [file name, columns, FROM ... of the query]. Each column is "header" or
     * "header=expression"; it is selected under its header's name, so two tables'
     * `name` columns cannot land on one key of the row.
     */
    var sheets = [
        ["measurements",
         ["metric=m.name", "unit=m.unit", "timestamp=l.timestamp", "value=l.value", "note=l.note"],
         'FROM HealthLogs l JOIN Metrics m ON l.metricId = m.id JOIN Profiles p ON l.profileId = p.id ' +
         'ORDER BY p.id, m.name, l.timestamp'],
        ["conditions",
         ["condition=c.name", "status=c.status", "start=c.startDate", "end=c.endDate", "note=c.note"],
         'FROM HealthConditions c JOIN Profiles p ON c.profileId = p.id ORDER BY p.id, c.startDate'],
        ["treatments",
         ["condition=c.name", "medication=m.name", "dosage=t.dosage", "frequency=t.frequency",
          "start=t.startDate", "end=t.endDate", "note=t.note"],
         'FROM Treatments t JOIN Profiles p ON t.profileId = p.id ' +
         'LEFT JOIN HealthConditions c ON c.id = t.conditionId LEFT JOIN Medications m ON m.id = t.medicationId ' +
         'ORDER BY p.id, t.startDate'],
        ["medication-intakes",
         ["medication=m.name", "timestamp=l.timestamp", "note=l.note"],
         'FROM MedicationLogs l JOIN Profiles p ON l.profileId = p.id ' +
         'LEFT JOIN Medications m ON m.id = l.medicationId ORDER BY p.id, m.name, l.timestamp'],
        ["vaccines",
         ["vaccine=v.name", "date=i.date", "note=i.note"],
         'FROM Injections i JOIN Profiles p ON i.profileId = p.id ' +
         'LEFT JOIN Vaccines v ON v.id = i.vaccineId ORDER BY p.id, i.date'],
        ["meditation",
         ["start=s.date", "seconds=s.duration", "name=s.name"],
         'FROM MeditationSessions s JOIN Profiles p ON s.profileId = p.id ORDER BY p.id, s.date'],
        ["cycles",
         ["start=c.startDate", "period_end=c.endDate", "note=c.note"],
         'FROM MenstrualCycles c JOIN Profiles p ON c.profileId = p.id ORDER BY p.id, c.startDate'],
        ["cycle-days",
         ["date=l.date", "flow=l.flow", "pain=l.pain", "energy=l.energy", "sleep_hours=l.sleepTime", "note=l.note"],
         'FROM MenstrualLogs l JOIN Profiles p ON l.profileId = p.id ORDER BY p.id, l.date']
    ];

    var files = [];
    db().readTransaction(function (tx) {
        for (var i = 0; i < sheets.length; i++) {
            var headers = ["profile"];
            var selected = ["p.firstName || ' ' || p.lastName AS \"profile\""];
            for (var c = 0; c < sheets[i][1].length; c++) {
                var column = sheets[i][1][c].split("=");
                headers.push(column[0]);
                selected.push(column[1] + ' AS "' + column[0] + '"');
            }
            var rs = tx.executeSql('SELECT ' + selected.join(", ") + ' ' + sheets[i][2]);
            if (rs.rows.length === 0) {
                continue;
            }
            var lines = [headers.join(",")];
            for (var j = 0; j < rs.rows.length; j++) {
                var row = rs.rows.item(j);
                var cells = [];
                for (var h = 0; h < headers.length; h++) {
                    cells.push(quote(row[headers[h]]));
                }
                lines.push(cells.join(","));
            }
            files.push({ name: sheets[i][0], content: "\uFEFF" + lines.join("\n") + "\n" });
        }
    });
    return files;
}

// The measurements file alone (the first of exportCsvFiles), "" without a reading.
function exportMeasurementsCsv() {
    var files = exportCsvFiles();
    for (var i = 0; i < files.length; i++) {
        if (files[i].name === "measurements") {
            return files[i].content;
        }
    }
    return "";
}

// Tables whose rows are what the user entered, for the "N entries" of a backup's summary.
var ENTRY_TABLES = ["HealthLogs", "Injections", "Treatments", "MedicationLogs", "HealthConditions",
                    "MenstrualCycles", "MenstrualLogs", "MeditationSessions"];

function _isArray(value) {
    return Object.prototype.toString.call(value) === "[object Array]";
}

/*
 * Checks that `dump` is a backup this version can restore and says what is in it:
 * {exportedAt, profiles: [names], entries}. Touches nothing. Throws with a reason of
 * "not-a-backup", "newer-backup" or "no-profiles" (restoring that one would just wipe
 * the app).
 */
function inspectBackup(dump) {
    var invalid = _failure("not-a-backup", "Not a Health backup file");
    if (!dump || typeof dump !== "object" || dump.format !== "harbour-health-backup"
            || !dump.tables || typeof dump.tables !== "object" || _isArray(dump.tables)) {
        throw invalid;
    }
    if (dump.schemaVersion !== undefined && dump.schemaVersion !== null) {
        if (typeof dump.schemaVersion !== "number" || isNaN(dump.schemaVersion)) {
            throw invalid;
        }
        if (dump.schemaVersion > DB_SCHEMA_VERSION) {
            throw _failure("newer-backup", "This backup was made by a newer version of Health");
        }
    }
    var entries = 0;
    for (var i = 0; i < ALL_TABLES.length; i++) {
        var rows = dump.tables[ALL_TABLES[i]];
        if (rows === undefined || rows === null) {
            continue;
        }
        if (!_isArray(rows)) {
            throw invalid;
        }
        for (var j = 0; j < rows.length; j++) {
            var row = rows[j];
            if (!row || typeof row !== "object" || _isArray(row)) {
                throw invalid;
            }
            for (var column in row) {
                var value = row[column];
                if (value !== null && typeof value === "object") {
                    throw invalid;
                }
            }
        }
        if (ENTRY_TABLES.indexOf(ALL_TABLES[i]) >= 0) {
            entries += rows.length;
        }
    }
    var profiles = dump.tables.Profiles;
    if (!profiles || profiles.length === 0) {
        throw _failure("no-profiles", "This backup contains no profiles");
    }
    var names = [];
    for (var p = 0; p < profiles.length; p++) {
        var first = profiles[p].firstName ? String(profiles[p].firstName) : "";
        var last = profiles[p].lastName ? String(profiles[p].lastName) : "";
        names.push((first + " " + last).trim());
    }
    return {
        exportedAt: dump.exportedAt ? String(dump.exportedAt) : "",
        profiles: names,
        entries: entries
    };
}

// The columns a table has in this database, as {name: true}.
function _tableColumns(tx, table) {
    var columns = {};
    var rs = tx.executeSql('PRAGMA table_info(' + table + ')');
    for (var i = 0; i < rs.rows.length; i++) {
        columns[rs.rows.item(i).name] = true;
    }
    return columns;
}

/*
 * Replaces the entire database contents with a previous export.
 *
 * Destructive by design and guarded in the UI. The backup is checked before anything
 * is deleted, and the whole replacement is atomic (_write): a row the database refuses
 * leaves the existing data as it was.
 *
 * Only the tables and columns this database has are written. A backup may carry more
 * (a newer release's additions) or fewer (an older one's): the extra ones are left out
 * rather than failing the restore, and a column name never reaches the SQL unchecked.
 */
function restoreAll(dump) {
    inspectBackup(dump);
    dump = _upgradeDump(dump);
    _constraintCache = {};

    _write(function (tx) {
        var i;
        var columnsOf = {};
        for (i = 0; i < ALL_TABLES.length; i++) {
            columnsOf[ALL_TABLES[i]] = _tableColumns(tx, ALL_TABLES[i]);
        }
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
                    if (columnsOf[table][column] !== true) {
                        continue;
                    }
                    columns.push(column);
                    if (row[column] === "") {
                        // Written into the statement: LocalStorage binds an empty
                        // string as NULL, which would turn every empty note into
                        // NULL and fail a NOT NULL column outright.
                        placeholders.push("''");
                    } else {
                        placeholders.push("?");
                        values.push(row[column]);
                    }
                }
                if (columns.length === 0) {
                    continue;
                }
                tx.executeSql('INSERT OR REPLACE INTO ' + table + ' (' + columns.join(",") +
                    ') VALUES (' + placeholders.join(",") + ')', values);
            }
        }
        if (tx.executeSql('SELECT count(*) AS count FROM Profiles').rows.item(0).count === 0) {
            throw _failure("no-profiles", "This backup contains no profiles");
        }

        // A backup from an older release lacks anything added since (the waist metric,
        // the WHtR module and its bands). Re-add what is missing right away, rather
        // than leaving the dashboard without them until the next launch's init().
        // Restored rows win; only missing ones are added.
        seedDefaultMetricsAndModules(tx);
        seedDefaultConstraints(tx);
    });
    _constraintCache = {};
}

// vim:et:ts=4:sw=4
