import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

/*
 * Backup and restore.
 *
 * Health keeps everything on the device and has no network access, so an exported
 * file is the only way to move data to a new phone or survive a reinstall.
 *
 * One card per job: a full backup, restoring one, and CSV files for spreadsheets. Each
 * card reports the outcome of its own action, where the user is looking.
 *
 * The restore list also holds the copies Health makes on its own (BackupStore): one a
 * day while the data changes, and one before every restore, so a restore of the wrong
 * file can be undone from the same list.
 */
Page {
    id: page
    allowedOrientations: Orientation.All

    property string statusMessage: ""
    property bool statusIsError: false
    // The card the message belongs to: "backup", "restore" or "csv".
    property string statusFor: ""
    // The backup file a restore message is about ("" for none): it is shown under that
    // file's row. At the foot of the card, a refusal was a screen away from the tap.
    property string statusPath: ""
    readonly property bool statusOnRow: {
        if (statusFor !== "restore" || statusPath === "") {
            return false;
        }
        for (var i = 0; i < backupModel.count; i++) {
            if (backupModel.get(i).path === statusPath) {
                return true;
            }
        }
        return false;
    }

    // True while an export or a restore runs: the page shows a spinner and takes no taps.
    property bool busy: false
    /*
     * What to do once this page is on top again: {action: "open", path} after the file
     * picker closes, {action: "restore", path, dump} after the confirmation is accepted.
     * Neither can start while the page that asked for it is still sliding away.
     */
    property var pending: null

    readonly property var files: appWindow.files
    readonly property var backups: appWindow.backups

    function timestampedName(prefix, extension) {
        var now = new Date();
        return prefix + "-" + Utils.toLocalDateString(now) + "-"
                + Utils.pad2(now.getHours()) + Utils.pad2(now.getMinutes()) + extension;
    }

    function report(message, isError, section, path) {
        statusMessage = message;
        statusIsError = isError === true;
        statusFor = section;
        statusPath = path ? path : "";
    }

    // Runs `work` after the spinner had a frame to appear; everything here is synchronous.
    function later(work) {
        busy = true;
        deferred.work = work;
        deferred.restart();
    }

    /*
     * When a backup was made, read from the name exportJson() gives it
     * ("health-backup-2026-11-08-0740.json"); "" for a file named otherwise, which then
     * goes by the date of the file itself.
     */
    function backupTimestamp(name) {
        var match = /(\d{4}-\d{2}-\d{2})-(\d{2})(\d{2})\.json$/.exec(name);
        return match ? match[1] + "T" + match[2] + ":" + match[3] + ":00" : "";
    }

    // What went wrong with a backup, in the user's language (DataManager gives a reason).
    function failureText(error) {
        switch (error && error.reason) {
        case "not-a-backup":  return qsTr("This is not a Health backup file.");
        case "newer-backup":  return qsTr("This backup was made by a newer version of Health. Update the app first.");
        case "no-profiles":   return qsTr("This backup contains no profiles.");
        default:
            // The whole restore is undone when any part of it fails.
            return qsTr("Restore failed: %1").arg(error && error.message ? error.message : String(error))
                    + " " + qsTr("Nothing was changed.");
        }
    }

    function exportJson() {
        var directory = files.exportDirectory();
        if (directory === "") {
            report(files.lastError(), true, "backup");
            return;
        }
        var path = directory + "/" + timestampedName("health-backup", ".json");
        var content;
        try {
            content = JSON.stringify(DataManager.exportAll(), null, 2);
        } catch (error) {
            report(qsTr("Could not read the database: %1").arg(error.message), true, "backup");
            return;
        }
        if (files.writeFile(path, content)) {
            report(qsTr("Saved to %1").arg(path), false, "backup");
            refreshBackups();
        } else {
            report(files.lastError(), true, "backup");
        }
    }

    function exportCsv() {
        var directory = files.exportDirectory();
        if (directory === "") {
            report(files.lastError(), true, "csv");
            return;
        }
        var sheets;
        try {
            sheets = DataManager.exportCsvFiles();
        } catch (error) {
            report(qsTr("Could not read the database: %1").arg(error.message), true, "csv");
            return;
        }
        if (sheets.length === 0) {
            report(qsTr("There is nothing to export yet."), false, "csv");
            return;
        }
        // One timestamp for the set, so the files of an export sort together.
        var suffix = timestampedName("", ".csv");
        for (var i = 0; i < sheets.length; i++) {
            if (!files.writeFile(directory + "/health-" + sheets[i].name + suffix, sheets[i].content)) {
                report(files.lastError(), true, "csv");
                return;
            }
        }
        //: After exporting CSV files; %1 is the folder they were written to
        report(qsTr("Saved %n file(s) to %1", "", sheets.length).arg(directory), false, "csv");
    }

    /*
     * Reads a backup and, when it is one this version can restore, asks before
     * replacing anything, showing what the file contains. Nothing has been changed yet
     * when this returns.
     */
    function openBackup(path) {
        var content = files.readFile(path);
        if (content === "") {
            // An empty file reads without any error, which left the message blank.
            report(files.lastError() || qsTr("This backup file is empty."), true, "restore", path);
            return;
        }
        var dump;
        var info;
        try {
            try {
                dump = JSON.parse(content);
            } catch (syntaxError) {
                throw { reason: "not-a-backup" };
            }
            info = DataManager.inspectBackup(dump);
        } catch (error) {
            report(failureText(error), true, "restore", path);
            return;
        }
        report("", false, "");
        var dialog = pageStack.push(confirmComponent, {
            fileName: path.substring(path.lastIndexOf("/") + 1),
            info: info
        });
        dialog.accepted.connect(function () {
            page.pending = { action: "restore", path: path, dump: dump };
        });
    }

    function restore(path, dump) {
        // What is there now is saved first, so a restore of the wrong file can be undone
        // from this list. Without that copy, nothing is replaced.
        if (DataManager.countProfiles() > 0
                && backups.snapshot("before-restore", DataManager.exportAll()) === "") {
            report(qsTr("Could not save a safety copy, so nothing was changed: %1").arg(files.lastError()),
                   true, "restore", path);
            return;
        }
        try {
            DataManager.restoreAll(dump);
        } catch (error) {
            refreshBackups();
            report(failureText(error), true, "restore", path);
            return;
        }
        // Profile ids now belong to the restored profiles: who has seen the "what's new"
        // card is no longer known.
        appWindow.setSetting("whatsNewSeen", []);
        report(qsTr("Restored from %1").arg(path), false, "restore");
        refreshBackups();
        // Every page below is showing data that no longer exists.
        var dashboard = pageStack.find(function(candidate) {
            return candidate.objectName === "dashboardPage";
        });
        if (dashboard) {
            pageStack.pop(dashboard);
        }
    }

    function removeBackup(path) {
        if (!files.removeFile(path)) {
            report(files.lastError(), true, "restore");
        }
        refreshBackups();
    }

    /*
     * The backups in Documents/Health and the app's own copies, newest first. The
     * exported ones show their file name; the app's show when they were made and what
     * they are.
     */
    function refreshBackups() {
        var rows = [];
        var directory = files.exportDirectory();
        var i;
        if (directory !== "") {
            var paths = files.listFiles(directory, ".json");
            for (i = 0; i < paths.length; i++) {
                var path = String(paths[i]);
                var name = path.substring(path.lastIndexOf("/") + 1);
                var modified = files.fileInfo(path).modified;
                rows.push({ path: path, title: name, kind: "", modified: modified,
                            when: backupTimestamp(name) || DataManager.toTimestamp(new Date(modified)) });
            }
        }
        var own = backups.entries();
        for (i = 0; i < own.length; i++) {
            var made = DataManager.toTimestamp(new Date(own[i].modified));
            // Its date is its name: no second line saying "Today, 02:06" under "11 Nov 2026, 02:06".
            rows.push({ path: own[i].path, title: Utils.formatDate(made) + ", " + Utils.formatTime(made),
                        kind: own[i].kind, modified: own[i].modified, when: "" });
        }
        rows.sort(function (a, b) { return b.modified - a.modified; });
        // "Latest" marks the newest exported file, not one of the app's own copies.
        var latestMarked = false;
        for (i = 0; i < rows.length; i++) {
            rows[i].latest = !latestMarked && rows[i].kind === "";
            latestMarked = latestMarked || rows[i].latest;
        }
        backupModel.clear();
        if (rows.length > 0) {
            backupModel.append(rows);
        }
    }

    function pillText(kind, latest) {
        switch (kind) {
        //: Marks a backup copy the app made on its own, in the restore list
        case "auto":            return qsTr("Automatic");
        //: Marks the copy made of the data just before a restore replaced it
        case "before-restore":  return qsTr("Before restore");
        //: Marks the copy made of the data just before an app update changed its format
        case "before-upgrade":  return qsTr("Before update");
        //: Marks the newest backup file in the list
        default:                return latest ? qsTr("Latest") : "";
        }
    }

    Timer {
        id: deferred
        property var work
        interval: 50
        onTriggered: {
            try {
                work();
            } finally {
                page.busy = false;
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active && pending !== null) {
            pendingTimer.restart();
        }
    }

    // Not from the status handler itself: pushing a page while this one is still
    // settling as the active page is a binding loop on its status.
    Timer {
        id: pendingTimer
        interval: 50
        onTriggered: {
            if (page.status !== PageStatus.Active || page.pending === null) {
                return;
            }
            if (pageStack.busy) {
                restart();
                return;
            }
            var todo = page.pending;
            page.pending = null;
            if (todo.action === "restore") {
                page.later(function () { page.restore(todo.path, todo.dump); });
            } else if (todo.action === "open") {
                page.openBackup(todo.path);
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge
        enabled: !page.busy

        PullDownMenu {
            MenuItem {
                //: Menu item: pick a backup file from Downloads or a memory card
                text: qsTr("Restore from another folder")
                onClicked: {
                    var picker = pageStack.push(Qt.resolvedUrl("pickBackupFile.qml"));
                    picker.picked.connect(function (path) {
                        page.pending = { action: "open", path: path };
                    });
                }
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Backup and restore")
                //: Under the page title: backups and restores cover every profile, not only the one in use
                description: qsTr("All profiles")
            }

            // --- backup ----------------------------------------------------------------
            Card {
                spacing: Theme.paddingMedium

                Label {
                    width: parent.width
                    //: Card title: saving everything to a file
                    text: qsTr("Backup")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                    text: qsTr("A backup covers every profile and all of its data, not just the one you are using. Files are written to the Health folder in your Documents, in readable form — keep them somewhere private.")
                }

                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Export backup")
                    onClicked: page.later(page.exportJson)
                }

                Label {
                    width: parent.width
                    visible: page.statusFor === "backup" && page.statusMessage !== ""
                    // Paths have no spaces to wrap at.
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: page.statusIsError ? Theme.errorColor : Theme.highlightColor
                    text: page.statusMessage
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    text: qsTr("Health also keeps automatic copies from the last 7 days in its own storage, where other apps cannot read them. They do not replace an exported backup.")
                }
            }

            // --- restore ---------------------------------------------------------------
            Card {
                id: restoreCard
                spacing: Theme.paddingMedium

                Label {
                    width: parent.width
                    //: Card title: replacing everything with a backup file
                    text: qsTr("Restore")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                }

                Row {
                    width: parent.width
                    spacing: Theme.paddingMedium

                    Icon {
                        id: warningIcon
                        source: "image://theme/icon-m-warning"
                        color: Theme.highlightColor
                    }

                    Label {
                        width: parent.width - warningIcon.width - parent.spacing
                        // Centred on the icon only while shorter than it.
                        y: Math.max(0, (warningIcon.height - height) / 2)
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.highlightColor
                        text: qsTr("Restoring replaces everything currently in the app — every profile and all of its data — with the contents of the backup. Export a backup first if you are unsure.")
                    }
                }

                Label {
                    width: parent.width
                    visible: backupModel.count > 0
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    text: qsTr("Tap a backup to see what it contains before restoring it. Press and hold to delete it.")
                }

                // Exported backups and the app's own copies, newest first. The rows span
                // the whole card so their pressed highlight does too.
                Column {
                    x: -restoreCard.padding
                    width: restoreCard.width
                    visible: backupModel.count > 0

                    Repeater {
                        model: backupModel

                        delegate: ListItem {
                            id: backupItem
                            width: parent.width
                            contentHeight: Math.max(Theme.itemSizeMedium, backupText.height + 2 * Theme.paddingMedium)

                            onClicked: page.openBackup(model.path)

                            menu: Component {
                                ContextMenu {
                                    MenuItem {
                                        text: qsTr("Delete")
                                        onClicked: {
                                            // Captured now: the row may be rebuilt before the countdown ends.
                                            var path = model.path;
                                            backupItem.remorseAction(qsTr("Deleting"), function() {
                                                page.removeBackup(path);
                                            })
                                        }
                                    }
                                }
                            }

                            Column {
                                id: backupText
                                x: restoreCard.padding
                                width: parent.width - 2 * restoreCard.padding
                                       - (kindPill.visible ? kindPill.width + Theme.paddingMedium : 0)
                                anchors.verticalCenter: parent.verticalCenter

                                Label {
                                    width: parent.width
                                    truncationMode: TruncationMode.Fade
                                    text: model.title
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: backupItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                                }
                                Label {
                                    width: parent.width
                                    visible: text !== ""
                                    truncationMode: TruncationMode.Fade
                                    text: model.when !== "" ? Utils.relativeTime(model.when, true, appWindow.today) : ""
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    color: backupItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                                }
                                // What happened to this file, right where it was tapped.
                                Label {
                                    width: backupItem.width - 2 * restoreCard.padding
                                    visible: page.statusOnRow && page.statusPath === model.path
                                             && page.statusMessage !== ""
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                    text: visible ? page.statusMessage : ""
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    color: page.statusIsError ? Theme.errorColor : Theme.highlightColor
                                }
                            }

                            StatusPill {
                                id: kindPill
                                anchors.right: parent.right
                                anchors.rightMargin: restoreCard.padding
                                // Level with the name and date: a message under them
                                // makes the row taller, and takes its whole width.
                                y: (Math.min(backupItem.contentHeight, Theme.itemSizeMedium) - height) / 2
                                maximumWidth: backupItem.width / 2
                                highlighted: backupItem.highlighted
                                text: page.pillText(model.kind, model.latest)
                            }
                        }
                    }
                }

                // In the card rather than a ViewPlaceholder: the other cards fill the page.
                Column {
                    width: parent.width
                    visible: backupModel.count === 0
                    spacing: Theme.paddingSmall

                    Label {
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: qsTr("No backups found")
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.highlightColor
                    }
                    Label {
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: qsTr("Export one first, or copy a backup file into Documents/Health")
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                    }
                }

                // For a file that is not in the list (picked from another folder).
                Label {
                    width: parent.width
                    visible: page.statusFor === "restore" && page.statusMessage !== "" && !page.statusOnRow
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: page.statusIsError ? Theme.errorColor : Theme.highlightColor
                    text: page.statusMessage
                }
            }

            // --- CSV -------------------------------------------------------------------
            Card {
                spacing: Theme.paddingMedium

                Label {
                    width: parent.width
                    text: qsTr("Spreadsheet export (CSV)")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                    text: qsTr("One table per kind of data — measurements, conditions and treatments, medication intakes, vaccines, meditation, cycle — for every profile, to open in a spreadsheet. They are saved in the same folder, but CSV files cannot be restored.")
                }

                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Export CSV")
                    onClicked: page.later(page.exportCsv)
                }

                Label {
                    width: parent.width
                    visible: page.statusFor === "csv" && page.statusMessage !== ""
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: page.statusIsError ? Theme.errorColor : Theme.highlightColor
                    text: page.statusMessage
                }
            }
        }

        VerticalScrollDecorator {}
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: page.busy
    }

    ListModel {
        id: backupModel
    }

    /*
     * What a backup contains, before it replaces anything. Tapping a row used to start
     * the restore after a five-second countdown, with nothing but the file name to go by.
     */
    Component {
        id: confirmComponent

        Dialog {
            id: confirm
            allowedOrientations: Orientation.All

            property string fileName: ""
            // DataManager.inspectBackup: {exportedAt, profiles, entries}.
            property var info: ({ exportedAt: "", profiles: [], entries: 0 })

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: confirmColumn.height + Theme.paddingLarge

                Column {
                    id: confirmColumn
                    width: parent.width
                    spacing: Theme.paddingLarge

                    DialogHeader {
                        title: qsTr("Restore this backup?")
                        acceptText: qsTr("Restore")
                    }

                    Card {
                        spacing: Theme.paddingMedium

                        Label {
                            width: parent.width
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            text: confirm.fileName
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        Label {
                            width: parent.width
                            visible: confirm.info.exportedAt !== ""
                            wrapMode: Text.Wrap
                            //: When a backup was made; %1 is a date and time
                            text: qsTr("Made on %1").arg(Utils.formatDate(confirm.info.exportedAt) + ", "
                                                        + Utils.formatTime(confirm.info.exportedAt))
                            color: Theme.primaryColor
                        }
                        Label {
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: confirm.info.profiles.join(", ")
                            color: Theme.primaryColor
                        }
                        Label {
                            width: parent.width
                            wrapMode: Text.Wrap
                            //: How much a backup holds: measurements, intakes, sessions and so on
                            text: qsTr("%n entries", "", confirm.info.entries)
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryColor
                        }
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.highlightColor
                        text: qsTr("Restoring replaces everything currently in the app — every profile and all of its data — with the contents of the backup. Export a backup first if you are unsure.")
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: qsTr("What is in the app now is kept as a “Before restore” copy in the list, so this can be undone.")
                    }
                }

                VerticalScrollDecorator {}
            }
        }
    }

    Component.onCompleted: refreshBackups()
}

// vim:et:ts=4:sw=4
