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

/*
 * A date without the year when it is this year's: "17 Aug", "17 Aug 2025". What the
 * dashboard, the history pages and the cover say for an earlier day.
 */
function shortDate(d) {
    return Format.formatDate(d, d.getFullYear() === new Date().getFullYear() ? Formatter.DateMediumWithoutYear
                                                                             : Formatter.DateMedium);
}

function _calendarDay(v) {
    if (v instanceof Date) {
        return new Date(v.getFullYear(), v.getMonth(), v.getDate());
    }
    return fromLocalDateString(v);
}

/*
 * Whole days from one calendar day to another, each a Date or a stored "YYYY-MM-DD",
 * or null when either is missing. Rounded: across the spring clock change two local
 * midnights are an hour short of a whole day, and flooring lost a day.
 */
function daysBetween(from, to) {
    var a = _calendarDay(from);
    var b = _calendarDay(to);
    return a === null || b === null ? null : Math.round((b - a) / 86400000);
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
 * A stored number put back into a text field for editing (up to three decimals, as
 * many as the fields accept). The fields take "." or "," and nothing else, so the
 * locale's separator is only used when it is ","; a locale with another one (Arabic
 * "٫") would otherwise pre-fill a value its own field refuses.
 */
function formatInput(v, decimals) {
    if (v === null || v === undefined || v === "" || isNaN(v)) {
        return "";
    }
    var d = (decimals === undefined || decimals === null) ? 3 : decimals;
    var factor = Math.pow(10, d);
    var s = String(Math.round(Number(v) * factor) / factor);
    return _decimalPoint === "," ? s.replace(".", ",") : s;
}

/*
 * Decimals worth showing for a metric's chart axis, readout and statistics. Averages
 * of whole numbers otherwise came out as "72.4 bpm", and 0.25 l of water as 0.3.
 */
function metricDecimals(name) {
    switch (name) {
    case "heartrate":
    case "calories":
    case "calories burned":
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
    // "Calories" alone became ambiguous next to the calories burned.
    case "calories":                  return qsTr("Calories eaten");
    case "calories burned":           return qsTr("Calories burned");
    case "meditation":                return qsTr("Meditation");
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
    case "calories burned":
        return qsTr("Write what you did in the note, for example \"Cycling, 45 min\".");
    default:
        return "";
    }
}

/*
 * Module names are stored in the database in English and double as
 * identifiers (dashboard wiring, reference-band keys, sort order), so the stored
 * value never changes. Only what reaches the screen is translated, here.
 */
function moduleDisplayName(name) {
    switch (name) {
    case "Weight":            return qsTr("Weight");
    case "Height":            return qsTr("Height");
    case "BMI":               return qsTr("BMI");
    case "Calories":          return qsTr("Calories eaten");
    case "Activity":          return qsTr("Activity");
    case "Today":             return qsTr("Today");
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

// Condition statuses are stored as English keys. Statuses typed freely by older
// versions are shown as they were written.
function conditionStatusDisplayName(status) {
    switch (status) {
    case "Active":     return qsTr("Active");
    case "Chronic":    return qsTr("Chronic");
    case "Recovered":  return qsTr("Recovered");
    default:           return status ? status : "";
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

/*
 * The line icon for a module, by its stored name, or for a metric by its name (the
 * measurement picker). Anything unknown keeps the icon stored with the module.
 */
function moduleIcon(name, storedIcon) {
    switch (name) {
    case "Weight":
    case "weight":            return "weight.svg";
    case "Height":
    case "height":            return "height.svg";
    case "BMI":               return "bmi.svg";
    case "Waist":
    case "waist":             return "waist.svg";
    case "WHtR":              return "whtr.svg";
    case "Calories":
    case "calories":          return "calories.svg";
    case "calories burned":   return "activity.svg";
    case "Water":
    case "water":             return "water.svg";
    case "Heartrate":
    case "heartrate":         return "heartrate.svg";
    case "Blood Pressure":
    case "blood-pressure":    return "blood-pressure.svg";
    case "Glucose":
    case "glucose":           return "glucose.svg";
    case "Health Condition":  return "condition.svg";
    case "Vaccination":       return "vaccine.svg";
    case "Meditation":        return "meditation.svg";
    case "Menstruation":      return "cycle.svg";
    default:                  return storedIcon ? storedIcon : "";
    }
}

/*
 * How long ago a reading was, the way the dashboard says it: "Today, 07:40" (or just
 * "Today"), "Yesterday", "3 days ago", then the date. Calendar days, not the 04:00
 * border: this is about when it was measured, not which day's total it counts for.
 */
function relativeTime(s, withTime) {
    var d = parseTimestamp(s);
    if (d === null) {
        return "";
    }
    var days = daysBetween(d, new Date());
    if (days <= 0) {
        return withTime ? qsTr("Today, %1").arg(Format.formatDate(d, Formatter.TimeValue)) : qsTr("Today");
    }
    if (days === 1) {
        return qsTr("Yesterday");
    }
    if (days < 7) {
        return qsTr("%n day(s) ago", "", days);
    }
    return shortDate(d);
}

/*
 * When a card's reading was taken, spelled out: a bare "17 Aug" or "Today" under a
 * value did not say what the date was.
 */
function measuredWhen(s) {
    var d = parseTimestamp(s);
    if (d === null) {
        return "";
    }
    var days = daysBetween(d, new Date());
    if (days <= 0) {
        return qsTr("Measured today");
    }
    if (days === 1) {
        return qsTr("Measured yesterday");
    }
    if (days < 7) {
        return qsTr("Measured %n day(s) ago", "", days);
    }
    //: %1 is a date, e.g. "Measured 17 Aug"
    return qsTr("Measured %1").arg(shortDate(d));
}

/*
 * Heading for a day in a history list ("YYYY-MM-DD"): "Today", "Yesterday", then the
 * weekday and date, with the year only when it is not this one. `currentDay` is the
 * day that counts as today: daily totals pass the 04:00-border day, so a glass of
 * water at 01:00 is under "Today" together with the evening before it.
 */
function dayTitle(day, currentDay) {
    var d = fromLocalDateString(day);
    if (d === null) {
        return "";
    }
    var today = currentDay ? currentDay : new Date();
    var days = daysBetween(d, today);
    if (days === 0) {
        return qsTr("Today");
    }
    if (days === 1) {
        return qsTr("Yesterday");
    }
    return Format.formatDate(d, d.getFullYear() === today.getFullYear() ? Formatter.DateFullWithoutYear
                                                                         : Formatter.DateFull);
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

/*
 * A reference band match (DataManager.matchConstraint) as what is shown for it:
 * {label, color}, an empty label and a transparent colour without one.
 */
function bandFor(match) {
    var colour = match ? constraintColor(match.color) : "";
    return {
        label: match ? constraintLabelDisplayName(match.label) : "",
        color: colour !== "" ? colour : "transparent"
    };
}

// "−0.8 kg since 9 Oct", from the first to the last of chart points [{t, v}]; "" with fewer than two.
function changeSinceText(points, unit, decimals) {
    if (!points || points.length < 2) {
        return "";
    }
    var delta = points[points.length - 1].v - points[0].v;
    //: Change of a measurement over the chart period, e.g. "−0.8 kg since 9 Oct"
    return qsTr("%1 since %2").arg((delta < 0 ? "−" : delta > 0 ? "+" : "±")
                                   + formatValue(Math.abs(delta), decimals)
                                   + (unit ? " " + unit : ""))
                              .arg(shortDate(new Date(points[0].t)));
}

// A blood pressure (DataManager.bloodPressureFrom) as "128/82 mmHg", "—" for a missing half.
function formatBloodPressure(bp, unit) {
    return (bp.systolic !== null ? formatValue(bp.systolic, 0) : "—") + "/"
            + (bp.diastolic !== null ? formatValue(bp.diastolic, 0) : "—")
            + (unit ? " " + unit : "");
}

// The previous reading to type a new one against: "Last: 66.5 kg, 19/08/2026".
function lastReadingText(valueText, timestamp) {
    //: The previous reading of a measurement: %1 is the value with its unit, %2 its date
    return qsTr("Last: %1, %2").arg(valueText).arg(formatDate(timestamp));
}

// Age in whole years on a birthday (a Date or "YYYY-MM-DD"), or -1 when unknown.
function ageFrom(birthDate) {
    var born = _calendarDay(birthDate);
    if (born === null || isNaN(born.getTime())) {
        return -1;
    }
    var today = new Date();
    var age = today.getFullYear() - born.getFullYear();
    if (today.getMonth() < born.getMonth()
            || (today.getMonth() === born.getMonth() && today.getDate() < born.getDate())) {
        age--;
    }
    return age >= 0 ? age : -1;
}

// "Female · 36 years", the line under a profile's name.
function profileDetailLine(gender, birthDate) {
    var parts = [];
    var genderText = genderDisplayName(gender);
    if (genderText !== "") {
        parts.push(genderText);
    }
    var age = ageFrom(birthDate);
    if (age >= 0) {
        //: A profile's age
        parts.push(qsTr("%n year(s)", "", age));
    }
    return parts.join(" · ");
}

// The letters in a profile's round badge.
function initials(firstName, lastName) {
    return ((firstName ? firstName.charAt(0) : "") + (lastName ? lastName.charAt(0) : "")).toUpperCase();
}

// The latest moment a birthday can be picked: a birthday cannot be in the future.
function endOfToday() {
    var d = new Date();
    d.setHours(23, 59, 59, 999);
    return d;
}

// Dot colour of a condition's status.
function conditionStatusColor(status) {
    switch (status) {
    case "Active":     return constraintColor("orange");
    case "Chronic":    return constraintColor("blue");
    case "Recovered":  return constraintColor("green");
    default:           return Theme.highlightColor;
    }
}

// The dates of a condition or treatment: "3 Mar to 9 Mar", "Since 3 Mar", "Until 9 Mar".
function periodText(startDate, endDate) {
    if (startDate && endDate) {
        //: Period of a health condition or treatment: start date to end date
        return qsTr("%1 to %2").arg(formatDate(startDate)).arg(formatDate(endDate));
    }
    if (startDate) {
        //: Start of an ongoing health condition or treatment; %1 is a date
        return qsTr("Since %1").arg(formatDate(startDate));
    }
    if (endDate) {
        //: End of a health condition or treatment without a start date; %1 is a date
        return qsTr("Until %1").arg(formatDate(endDate));
    }
    return "";
}

/*
 * Dot colour of a day's flow, pain or energy: green where things are fine, then blue,
 * orange and red with intensity. Neutral values use the highlight colour.
 */
function cycleLevelColor(kind, value) {
    var scale = {
        flow: { "Spotting": "blue", "Light": "blue", "Medium": "orange", "Heavy": "red" },
        pain: { "None": "green", "Mild": "blue", "Moderate": "orange", "Severe": "red" },
        energy: { "Exhausted": "red", "Low": "orange", "Normal": "green", "High": "green", "Peak": "green" }
    };
    var name = scale[kind] ? scale[kind][value] : undefined;
    var colour = name ? constraintColor(name) : "";
    return colour !== "" ? colour : Theme.highlightColor;
}

// A meditation session's length: "45 s", "10 min", "10 min 30 s".
function formatDuration(seconds) {
    if (seconds === null || seconds === undefined) {
        return "";
    }
    if (seconds < 60) {
        //: Meditation session length under a minute, in seconds
        return qsTr("%1 s").arg(seconds);
    }
    var minutes = Math.floor(seconds / 60);
    var remainder = seconds % 60;
    //: Meditation session length in whole minutes
    return remainder === 0 ? qsTr("%1 min").arg(minutes)
                             //: Meditation session length, minutes and seconds
                           : qsTr("%1 min %2 s").arg(minutes).arg(remainder);
}

// Whole minutes, but never 0 for a session that happened.
function wholeMinutes(seconds) {
    return seconds > 0 ? Math.max(1, Math.round(seconds / 60)) : 0;
}

// "Taken 2 times today, last at 08:30", or that a medication was not taken yet today.
function medicationTodayText(count, lastTimestamp) {
    if (count === 0) {
        return qsTr("Not taken today");
    }
    //: Medication intakes logged today; %1 is the time of the latest one
    return qsTr("Taken %n time(s) today, last at %1", "", count).arg(formatTime(lastTimestamp));
}

/*
 * The day's to-do items (DataManager.getTodayPlan) as text, shared by the Today page,
 * its dashboard row and the cover.
 */

// What an item is: "Water", "Meditation", or the medication's name.
function todayItemTitle(item) {
    return item.kind === "medication" ? item.name : metricDisplayName(item.metricName);
}

// Where it stands: "1.2 of 2 L", "5 of 10 min", "Taken 2 times today, last at 08:30".
function todayItemProgress(item) {
    if (item.kind === "medication") {
        return medicationTodayText(item.count, item.last);
    }
    if (item.kind === "meditation") {
        //: Minutes meditated today against the daily goal, e.g. "5 of 10 min"
        return qsTr("%1 of %2 min").arg(Math.floor(item.total)).arg(formatValue(item.goal, 1));
    }
    var decimals = metricDecimals(item.metricName);
    //: Today's total against its daily goal, e.g. "1.2 of 2 L"
    return qsTr("%1 of %2").arg(formatValue(item.total, decimals))
            .arg(formatValue(item.goal, decimals) + (item.unit ? " " + item.unit : ""));
}

// The amount still to go for a goal: "0.8 L", "5 min"; "" for a medication.
function todayItemRemaining(item) {
    if (item.kind === "medication") {
        return "";
    }
    if (item.kind === "meditation") {
        //: Minutes still to meditate today
        return qsTr("%n min", "", Math.max(1, Math.ceil(item.goal - item.total)));
    }
    return formatValue(Math.max(0, item.goal - item.total), metricDecimals(item.metricName))
            + (item.unit ? " " + item.unit : "");
}

// What is left: "0.8 L left", "Not taken yet", "Done".
function todayItemLeft(item) {
    if (item.done) {
        //: A daily goal or medication of the Today list that is done for today
        return qsTr("Done");
    }
    if (item.kind === "medication") {
        return qsTr("Not taken yet");
    }
    //: Amount still to reach today's goal, e.g. "0.8 L left"
    return qsTr("%1 left").arg(todayItemRemaining(item));
}

// How far along an item is, from 0 to 1.
function todayItemFraction(item) {
    if (item.kind === "medication") {
        return item.done ? 1 : 0;
    }
    return item.goal > 0 ? Math.max(0, Math.min(1, item.total / item.goal)) : 0;
}

// vim:et:ts=4:sw=4
