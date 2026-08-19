/*
 * Shared formatting helpers.
 *
 * Deliberately NOT a .pragma library: qsTr() only resolves in a JS resource that
 * runs in the importing component's scope, and metricDisplayName() needs it.
 */

function pad2(n) {
    return (n < 10 ? "0" : "") + n;
}

/*
 * Dates are stored as plain local calendar days ("YYYY-MM-DD").
 *
 * Date.toISOString() must never be used for this: DatePickerDialog hands back local
 * midnight, and toISOString() converts to UTC, so every user east of Greenwich would
 * store the previous day.
 */
function toLocalDateString(d) {
    if (!d) {
        return "";
    }
    return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate());
}

// Parses "YYYY-MM-DD" as a local date. new Date("2026-08-19") would parse as UTC.
function fromLocalDateString(s) {
    if (!s) {
        return null;
    }
    var parts = String(s).split("T")[0].split(" ")[0].split("-");
    if (parts.length < 3) {
        return null;
    }
    return new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
}

// Timestamps are stored as local "YYYY-MM-DDTHH:MM:SS" -- the format SQLite's
// date()/datetime() functions understand, with no timezone suffix.
function toLocalTimestamp(d) {
    if (!d) {
        return "";
    }
    return toLocalDateString(d) + "T" + pad2(d.getHours()) + ":" + pad2(d.getMinutes())
            + ":" + pad2(d.getSeconds());
}

// Accepts both the "T" form we write and the " " form SQLite's CURRENT_TIMESTAMP wrote.
function parseTimestamp(s) {
    if (!s) {
        return null;
    }
    if (s instanceof Date) {
        return s;
    }
    var str = String(s).replace(" ", "T");
    var halves = str.split("T");
    var date = fromLocalDateString(halves[0]);
    if (date === null) {
        return null;
    }
    if (halves.length > 1) {
        var time = halves[1].split(".")[0].split("Z")[0].split("+")[0].split(":");
        date.setHours(parseInt(time[0], 10) || 0,
                      parseInt(time[1], 10) || 0,
                      parseInt(time[2], 10) || 0, 0);
    }
    return date;
}

function formatDate(s) {
    var d = parseTimestamp(s);
    return d === null ? "" : Qt.formatDate(d, Qt.DefaultLocaleShortDate);
}

function formatTime(s) {
    var d = parseTimestamp(s);
    return d === null ? "" : Qt.formatTime(d, "hh:mm");
}

function formatDateTime(s) {
    var d = parseTimestamp(s);
    return d === null ? "" : Qt.formatDateTime(d, Qt.DefaultLocaleShortDate);
}

/*
 * Trims binary floating point noise. SUM() over 0.5 + 0.6 + 0.7 yields
 * 1.7999999999999998, which was reaching the dashboard verbatim.
 */
function formatValue(v, decimals) {
    if (v === null || v === undefined || v === "" || isNaN(v)) {
        return "";
    }
    var d = (decimals === undefined || decimals === null) ? 2 : decimals;
    var factor = Math.pow(10, d);
    return String(Math.round(Number(v) * factor) / factor);
}

function capitalize(s) {
    if (!s) {
        return "";
    }
    return s.charAt(0).toUpperCase() + s.slice(1);
}

/*
 * Metric names are internal identifiers stored in the database ("systolic blood
 * pressure"). They must never reach the screen raw: they are lowercase and cannot
 * be translated. Custom metrics fall through to plain capitalisation.
 */
function metricDisplayName(name) {
    switch (name) {
    case "weight":                    return qsTr("Weight");
    case "height":                    return qsTr("Height");
    case "water":                     return qsTr("Water");
    case "calories":                  return qsTr("Calories");
    case "heartrate":                 return qsTr("Heart rate");
    case "systolic blood pressure":   return qsTr("Systolic");
    case "diastolic blood pressure":  return qsTr("Diastolic");
    case "glucose":                   return qsTr("Glucose");
    case "bmi":
    case "BMI":                       return qsTr("BMI");
    case "blood-pressure":            return qsTr("Blood pressure");
    default:                          return capitalize(name);
    }
}

function genderDisplayName(gender) {
    switch (gender) {
    case "female": return qsTr("Female");
    case "male":   return qsTr("Male");
    case "other":  return qsTr("Other");
    // Profiles created before genders were stored canonically kept the translated label.
    default:       return gender ? gender : "";
    }
}

// Constraint colours are stored as stable names so the palette can change freely.
function constraintColor(name) {
    switch (name) {
    case "green":  return "#2ecc71";
    case "orange": return "#e67e22";
    case "red":    return "#e74c3c";
    case "blue":   return "#3498db";
    default:       return "";
    }
}

// vim:et:ts=4:sw=4
