import QtQuick 2.0
import "../js/DataManager.js" as DataManager

/*
 * The copies Health makes on its own, kept in its private folder where no other app
 * can read them: one a day while the data changes ("auto"), one before every restore
 * ("before-restore") and one before a schema upgrade ("before-upgrade-vN"). They do not
 * replace an exported backup, which is the one that survives a lost or reset phone.
 *
 * One instance lives on the window (appWindow.backups).
 */
QtObject {
    id: store

    // The window's FileWriter.
    property var files

    // How many of each kind are kept. Separate counts, so a week of daily copies
    // cannot push out the copy made before a restore.
    readonly property int keepAutomatic: 7
    readonly property int keepOthers: 5

    function pad2(n) {
        return (n < 10 ? "0" : "") + n;
    }

    // To the second: two restores within a minute must not overwrite the first copy,
    // which is the one holding the original data.
    function stamp() {
        var now = new Date();
        return now.getFullYear() + "-" + pad2(now.getMonth() + 1) + "-" + pad2(now.getDate()) + "-"
                + pad2(now.getHours()) + pad2(now.getMinutes()) + pad2(now.getSeconds());
    }

    // "auto", "before-restore", "before-upgrade", or "" for a file that is not ours.
    function kindOf(name) {
        var match = /^health-(auto|before-restore|before-upgrade)-/.exec(name);
        return match ? match[1] : "";
    }

    // The private copies, newest first: [{path, name, kind, modified}].
    function entries() {
        var list = [];
        var directory = files.backupDirectory();
        if (directory === "") {
            return list;
        }
        var paths = files.listFiles(directory, ".json");
        for (var i = 0; i < paths.length; i++) {
            var path = String(paths[i]);
            var name = path.substring(path.lastIndexOf("/") + 1);
            var kind = kindOf(name);
            if (kind !== "") {
                list.push({ path: path, name: name, kind: kind, modified: files.fileInfo(path).modified });
            }
        }
        return list;
    }

    function prune(kind) {
        var keep = kind === "auto" ? keepAutomatic : keepOthers;
        var all = entries();
        var seen = 0;
        for (var i = 0; i < all.length; i++) {
            if (all[i].kind === kind && ++seen > keep) {
                files.removeFile(all[i].path);
            }
        }
    }

    /*
     * Writes `dump` (DataManager.exportAll) as a private copy of `kind`, compact rather
     * than indented: nobody reads these by hand. Returns its path, or "" when it could
     * not be written (files.lastError() says why).
     */
    function snapshot(kind, dump) {
        var directory = files.backupDirectory();
        if (directory === "") {
            return "";
        }
        var path = directory + "/health-" + kind + "-" + stamp() + ".json";
        if (!files.writeFile(path, JSON.stringify(dump))) {
            return "";
        }
        prune(kindOf("health-" + kind + "-"));
        return path;
    }

    /*
     * Whether today's automatic copy is still to be made: there is something to copy,
     * none was made today (the DAY_START_TIME day), and the database was written since
     * the last one. The file's own date tells that, across launches, with nothing to
     * keep count of.
     */
    function automaticDue() {
        if (DataManager.countProfiles() === 0) {
            return false;
        }
        var all = entries();
        for (var i = 0; i < all.length; i++) {
            if (all[i].kind === "auto") {
                var made = DataManager.dayStart(new Date(all[i].modified));
                if (made.getTime() === DataManager.dayStart().getTime()) {
                    return false;
                }
                return files.databaseModified() > all[i].modified;
            }
        }
        return true;
    }

    // Called a few seconds after the app goes to the background. Never throws: a copy
    // that could not be made today is simply tried again tomorrow.
    function runAutomatic() {
        try {
            if (automaticDue()) {
                snapshot("auto", DataManager.exportAll());
            }
        } catch (error) {
            console.log("Automatic backup failed: " + error);
        }
    }
}
