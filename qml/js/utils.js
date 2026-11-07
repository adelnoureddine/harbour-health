/*
 * Shared formatting helpers.
 *
 * Deliberately NOT a .pragma library: qsTr() only resolves in a JS resource that
 * runs in the importing component's scope, and metricDisplayName() needs it.
 *
 * It must also keep having no .import lines of its own: a script without imports
 * borrows those of the page importing it, which is how Format and Formatter
 * (Sailfish.Silica) are visible here.
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

// Silica's formatter follows the system 12/24-hour setting; Qt's own formats only
// know the locale, and "hh:mm" knew neither.
function formatTime(s) {
    var d = parseTimestamp(s);
    return d === null ? "" : Format.formatDate(d, Formatter.TimeValue);
}

function formatDateTime(s) {
    var d = parseTimestamp(s);
    return d === null ? "" : Qt.formatDate(d, Qt.DefaultLocaleShortDate) + " "
                                + Format.formatDate(d, Formatter.TimeValue);
}

var _decimalPoint = Qt.locale().decimalPoint;

/*
 * Trims binary floating point noise. SUM() over 0.5 + 0.6 + 0.7 yields
 * 1.7999999999999998, which was reaching the dashboard verbatim.
 *
 * Uses the locale's decimal separator ("72,5" in Swedish or French). Display only:
 * every number field accepts either separator and converts back before parsing.
 * No thousands separators, which those fields would not accept.
 */
function formatValue(v, decimals) {
    if (v === null || v === undefined || v === "" || isNaN(v)) {
        return "";
    }
    var d = (decimals === undefined || decimals === null) ? 2 : decimals;
    var factor = Math.pow(10, d);
    return String(Math.round(Number(v) * factor) / factor).replace(".", _decimalPoint);
}

/*
 * Decimals worth showing for a metric's chart axis, readout and statistics. Averages
 * of whole numbers otherwise came out as "72.4 bpm", and 0.25 l of water as 0.3.
 */
function metricDecimals(name) {
    switch (name) {
    case "heartrate":
    case "calories":
    case "systolic blood pressure":
    case "diastolic blood pressure":
        return 0;
    case "water":
    case "whtr":
    case "WHtR":
        return 2;
    default:
        return 1;
    }
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
    case "waist":                     return qsTr("Waist");
    case "bmi":
    case "BMI":                       return qsTr("BMI");
    case "whtr":
    case "WHtR":                      return qsTr("Waist-to-height ratio");
    case "blood-pressure":            return qsTr("Blood pressure");
    default:                          return capitalize(name);
    }
}

/*
 * One-line guidance shown when logging a metric, where how it is measured changes
 * the reading enough to matter. Empty for everything else.
 */
function metricHint(name) {
    switch (name) {
    case "waist":
        return qsTr("Measure midway between your lowest rib and the top of your hip bone, after breathing out normally. Use the same spot every time.");
    default:
        return "";
    }
}

/*
 * Module and category names are stored in the database in English and double as
 * identifiers (dashboard wiring, reference-band keys, sort order), so the stored
 * value never changes. Only what reaches the screen is translated, here.
 */
function moduleDisplayName(name) {
    switch (name) {
    case "Weight":            return qsTr("Weight");
    case "Height":            return qsTr("Height");
    case "BMI":               return qsTr("BMI");
    case "Calories":          return qsTr("Calories");
    case "Water":             return qsTr("Water");
    case "Heartrate":         return qsTr("Heart rate");
    case "Blood Pressure":    return qsTr("Blood pressure");
    case "Glucose":           return qsTr("Glucose");
    case "Health Condition":  return qsTr("Health condition");
    case "Vaccination":       return qsTr("Vaccination");
    case "Meditation":        return qsTr("Meditation");
    case "Menstruation":      return qsTr("Menstruation");
    case "Waist":             return qsTr("Waist");
    case "WHtR":              return qsTr("Waist-to-height ratio");
    default:                  return name ? name : "";
    }
}

function categoryDisplayName(category) {
    switch (category) {
    case "Body":       return qsTr("Body");
    case "Nutrition":  return qsTr("Nutrition");
    case "Blood":      return qsTr("Blood");
    case "Other":      return qsTr("Other");
    default:           return category ? category : "";
    }
}

/*
 * Reference band labels are user data: they can be renamed freely. Only the
 * labels seeded by default are translated; anything the user typed is shown as is.
 */
function constraintLabelDisplayName(label) {
    switch (label) {
    case "Underweight":  return qsTr("Underweight");
    case "Normal":       return qsTr("Normal");
    case "Overweight":   return qsTr("Overweight");
    case "Obese":        return qsTr("Obese");
    case "Low":          return qsTr("Low");
    case "Elevated":     return qsTr("Elevated");
    case "High":         return qsTr("High");
    case "Below 0.5":    return qsTr("Below 0.5");
    case "0.5 to 0.6":   return qsTr("0.5 to 0.6");
    case "0.6 and above": return qsTr("0.6 and above");
    default:             return label ? label : "";
    }
}

// Daily cycle entries are stored with English keys, like genders.
function flowDisplayName(flow) {
    switch (flow) {
    case "None":      return qsTr("None");
    case "Spotting":  return qsTr("Spotting");
    case "Light":     return qsTr("Light");
    case "Medium":    return qsTr("Medium");
    case "Heavy":     return qsTr("Heavy");
    default:          return flow ? flow : "";
    }
}

function painDisplayName(pain) {
    switch (pain) {
    case "None":      return qsTr("None");
    case "Mild":      return qsTr("Mild");
    case "Moderate":  return qsTr("Moderate");
    case "Severe":    return qsTr("Severe");
    default:          return pain ? pain : "";
    }
}

function energyDisplayName(energy) {
    switch (energy) {
    case "Exhausted": return qsTr("Exhausted");
    case "Low":       return qsTr("Low");
    case "Normal":    return qsTr("Normal");
    case "High":      return qsTr("High");
    case "Peak":      return qsTr("Peak");
    default:          return energy ? energy : "";
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
