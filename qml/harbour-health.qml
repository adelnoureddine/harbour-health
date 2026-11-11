import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.health.FileWriter 1.0
import "pages"
import "components"
import "js/DataManager.js" as DataManager

ApplicationWindow {
    id: appWindow
    initialPage: Component { MainPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    // Empty unless the database could not be opened or upgraded.
    property string databaseError: ""
    // Why, when the app knows: "schema-newer" for data saved by a newer version.
    property string databaseErrorReason: ""

    // File access and the app's own backup copies, for every page.
    property alias files: fileWriter
    property alias backups: backupStore

    /*
     * What the app remembers that is not health data: the units values are shown in and
     * the profiles that have seen the "what's new" card. Kept in a file of its own in
     * the private folder (FileWriter.stateFile), so the database holds the same thing
     * whatever is chosen here. Read once, written on every change.
     *
     * Read on first use (ensureSettings), not at a fixed point of the start-up: the
     * dashboard can be built before this window's own Component.onCompleted runs. It
     * then found no settings, marked its profile as having seen the "what's new" card,
     * and that write replaced the file -- the chosen units were gone.
     */
    property var settings: ({})
    property bool settingsLoaded: false

    function ensureSettings() {
        if (settingsLoaded) {
            return;
        }
        settingsLoaded = true;
        var loaded = {};
        var text = fileWriter.readFile(fileWriter.stateFile());
        if (text !== "") {
            try {
                var parsed = JSON.parse(text);
                if (parsed && typeof parsed === "object") {
                    loaded = parsed;
                }
            } catch (error) {
                // A damaged settings file only loses these choices.
            }
        }
        settings = loaded;
        DataManager.setUnits(loaded.units);
    }

    function setSetting(key, value) {
        ensureSettings();
        var copy = {};
        for (var name in settings) {
            copy[name] = settings[name];
        }
        copy[key] = value;
        settings = copy;
        fileWriter.writeFile(fileWriter.stateFile(), JSON.stringify(copy));
    }

    // The units values are shown and typed in ({mass, length, volume, glucose}).
    function setUnits(choices) {
        ensureSettings();
        if (DataManager.setUnits(choices)) {
            setSetting("units", DataManager.units());
        }
    }

    /*
     * Asks whatever is on screen to look again: the app came back to the foreground
     * (water may have been added from the cover) or the day turned while it was open.
     * The page on top reloads if its data key changed (reloadIfStale, on the pages that
     * show something that can go stale); the cover listens to the signal.
     */
    signal dataRefreshRequested()

    /*
     * The calendar day, "YYYY-MM-DD", for the texts that say how long ago something was
     * (Utils.measuredWhen and relativeTime take it): they change with the day although
     * the reading they describe did not. The dashboard left open over midnight had the
     * new date in its header and "Measured today" under yesterday's weight.
     */
    property string today: Qt.formatDate(new Date(), "yyyy-MM-dd")

    function refreshWhatIsShown() {
        today = Qt.formatDate(new Date(), "yyyy-MM-dd");
        dataRefreshRequested();
        var page = pageStack.currentPage;
        if (page && !pageStack.busy && typeof page.reloadIfStale === "function") {
            page.reloadIfStale();
        }
    }

    function armDayTimer() {
        dayTimer.interval = DataManager.msUntilNextDay() + 1000;
        dayTimer.restart();
    }

    onApplicationActiveChanged: {
        if (applicationActive) {
            automaticBackupTimer.stop();
            refreshWhatIsShown();
            armDayTimer();
        } else {
            dayTimer.stop();
            // Not at once: the switch to the home screen should not stutter, and a
            // quick peek at another app is not worth a copy.
            automaticBackupTimer.restart();
        }
    }

    // Fires when "today" changes (midnight and DAY_START_TIME) while the app is open.
    Timer {
        id: dayTimer
        onTriggered: {
            appWindow.refreshWhatIsShown();
            appWindow.armDayTimer();
        }
    }

    Timer {
        id: automaticBackupTimer
        interval: 3000
        onTriggered: {
            if (!appWindow.applicationActive && appWindow.databaseError === "") {
                backupStore.runAutomatic();
            }
        }
    }

    FileWriter {
        id: fileWriter
    }

    BackupStore {
        id: backupStore
        files: fileWriter
    }

    /*
     * The database creates or upgrades itself on first use, whichever of the dashboard,
     * the cover or this comes first. An upgrade is the exception: it waits for the copy
     * of the old data made here (DataManager.pendingMigration and the functions next to
     * it), and nothing is upgraded if that copy cannot be written.
     *
     * A failure is kept for the dashboard to show, so a failed open or upgrade does not
     * leave a blank, unexplained window.
     *
     * Without a profile the dashboard shows its welcome screen, which explains the app
     * and offers creating a profile or restoring a backup.
     */
    function openDatabase() {
        try {
            var pending = DataManager.pendingMigration();
            if (pending !== null) {
                if (backupStore.snapshot("before-upgrade-v" + pending.from,
                                         DataManager.exportBeforeMigration()) === "") {
                    throw new Error(fileWriter.lastError());
                }
                DataManager.approveMigration();
            }
            DataManager.init();
        } catch (error) {
            databaseErrorReason = error.reason ? error.reason : "";
            databaseError = error.message ? error.message : String(error);
        }
    }

    Component.onCompleted: {
        ensureSettings();
        openDatabase();
        // A dashboard that asked before an upgrade was approved gets its data now.
        refreshWhatIsShown();
        if (applicationActive) {
            armDayTimer();
        }
    }
}

// vim:et:ts=4:sw=4
