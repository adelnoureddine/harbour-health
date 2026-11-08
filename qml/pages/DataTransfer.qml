import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.health.FileWriter 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

/*
 * Backup and restore.
 *
 * Health keeps everything on the device and has no network access, so an exported
 * file is the only way to move data to a new phone or survive a reinstall.
 *
 * One card per job: a full backup, restoring one, and a CSV for spreadsheets. Each
 * card reports the outcome of its own action, where the user is looking.
 */
Page {
    id: page
    allowedOrientations: Orientation.All

    property string statusMessage: ""
    property bool statusIsError: false
    // The card the message belongs to: "backup", "restore" or "csv".
    property string statusFor: ""

    FileWriter {
        id: fileWriter
    }

    function timestampedName(prefix, extension) {
        var now = new Date();
        return prefix + "-" + Utils.toLocalDateString(now) + "-"
                + Utils.pad2(now.getHours()) + Utils.pad2(now.getMinutes()) + extension;
    }

    function report(message, isError, section) {
        statusMessage = message;
        statusIsError = isError === true;
        statusFor = section;
    }

    /*
     * When a backup was made, read from the name exportJson() gives it
     * ("health-backup-2026-11-08-0740.json"). FileWriter has no file dates or sizes,
     * so a file named otherwise gets "" and shows its name only.
     */
    function backupTimestamp(name) {
        var match = /(\d{4}-\d{2}-\d{2})-(\d{2})(\d{2})\.json$/.exec(name);
        return match ? match[1] + "T" + match[2] + ":" + match[3] + ":00" : "";
    }

    function exportJson() {
        var directory = fileWriter.exportDirectory();
        if (directory === "") {
            report(fileWriter.lastError(), true, "backup");
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
        if (fileWriter.writeFile(path, content)) {
            report(qsTr("Saved to %1").arg(path), false, "backup");
            refreshBackups();
        } else {
            report(fileWriter.lastError(), true, "backup");
        }
    }

    function exportCsv() {
        var directory = fileWriter.exportDirectory();
        if (directory === "") {
            report(fileWriter.lastError(), true, "csv");
            return;
        }
        var path = directory + "/" + timestampedName("health-measurements", ".csv");
        if (fileWriter.writeFile(path, DataManager.exportMeasurementsCsv())) {
            report(qsTr("Saved to %1").arg(path), false, "csv");
        } else {
            report(fileWriter.lastError(), true, "csv");
        }
    }

    function restore(path) {
        var content = fileWriter.readFile(path);
        if (content === "") {
            // An empty file reads without any error, which left the message blank.
            report(fileWriter.lastError() || qsTr("This backup file is empty."), true, "restore");
            return;
        }
        try {
            DataManager.restoreAll(JSON.parse(content));
        } catch (error) {
            report(qsTr("Restore failed: %1").arg(error.message), true, "restore");
            return;
        }
        report(qsTr("Restored from %1").arg(path), false, "restore");
        // Every page below is showing data that no longer exists.
        var dashboard = pageStack.find(function(candidate) {
            return candidate.objectName === "dashboardPage";
        });
        if (dashboard) {
            pageStack.pop(dashboard);
        }
    }

    function refreshBackups() {
        backupModel.clear();
        var directory = fileWriter.exportDirectory();
        if (directory === "") {
            return;
        }
        // Newest first (FileWriter.listFiles sorts by modification time).
        var files = fileWriter.listFiles(directory, ".json");
        for (var i = 0; i < files.length; i++) {
            var path = String(files[i]);
            var name = path.substring(path.lastIndexOf("/") + 1);
            backupModel.append({ path: path, name: name, when: backupTimestamp(name) });
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

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
                    onClicked: page.exportJson()
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
                    text: qsTr("Tap a backup to restore it. There are a few seconds to cancel before anything is replaced.")
                }

                // Backups found in Documents/Health, newest first. The rows span the
                // whole card so their pressed highlight does too.
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

                            onClicked: {
                                var path = model.path;
                                backupItem.remorseAction(qsTr("Replacing all data"), function() {
                                    page.restore(path);
                                })
                            }

                            Column {
                                id: backupText
                                x: restoreCard.padding
                                width: parent.width - 2 * restoreCard.padding
                                       - (latestPill.visible ? latestPill.width + Theme.paddingMedium : 0)
                                anchors.verticalCenter: parent.verticalCenter

                                Label {
                                    width: parent.width
                                    truncationMode: TruncationMode.Fade
                                    text: model.name
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: backupItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                                }
                                Label {
                                    width: parent.width
                                    visible: text !== ""
                                    truncationMode: TruncationMode.Fade
                                    text: model.when !== "" ? Utils.relativeTime(model.when, true) : ""
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    color: backupItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                                }
                            }

                            StatusPill {
                                id: latestPill
                                anchors.right: parent.right
                                anchors.rightMargin: restoreCard.padding
                                anchors.verticalCenter: parent.verticalCenter
                                //: Marks the newest backup file in the list
                                text: index === 0 ? qsTr("Latest") : ""
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

                Label {
                    width: parent.width
                    visible: page.statusFor === "restore" && page.statusMessage !== ""
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
                    text: qsTr("Every measurement of every profile in one table, to open in a spreadsheet. It is saved in the same folder, but a CSV file cannot be restored.")
                }

                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Export CSV")
                    onClicked: page.exportCsv()
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

    ListModel {
        id: backupModel
    }

    Component.onCompleted: refreshBackups()
}

// vim:et:ts=4:sw=4
