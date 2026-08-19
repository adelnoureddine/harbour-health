import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.health.FileWriter 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

/*
 * Backup and restore.
 *
 * Health keeps everything on the device and has no network access, so an exported
 * file is the only way to move data to a new phone or survive a reinstall.
 */
Page {
    id: page
    allowedOrientations: Orientation.All

    property string statusMessage: ""
    property bool statusIsError: false

    FileWriter {
        id: fileWriter
    }

    function timestampedName(prefix, extension) {
        var now = new Date();
        return prefix + "-" + Utils.toLocalDateString(now) + "-"
                + Utils.pad2(now.getHours()) + Utils.pad2(now.getMinutes()) + extension;
    }

    function report(message, isError) {
        statusMessage = message;
        statusIsError = isError === true;
    }

    function exportJson() {
        var directory = fileWriter.exportDirectory();
        if (directory === "") {
            report(fileWriter.lastError(), true);
            return;
        }
        var path = directory + "/" + timestampedName("health-backup", ".json");
        var content;
        try {
            content = JSON.stringify(DataManager.exportAll(), null, 2);
        } catch (error) {
            report(qsTr("Could not read the database: %1").arg(error.message), true);
            return;
        }
        if (fileWriter.writeFile(path, content)) {
            report(qsTr("Saved to %1").arg(path), false);
            refreshBackups();
        } else {
            report(fileWriter.lastError(), true);
        }
    }

    function exportCsv() {
        var directory = fileWriter.exportDirectory();
        if (directory === "") {
            report(fileWriter.lastError(), true);
            return;
        }
        var path = directory + "/" + timestampedName("health-measurements", ".csv");
        if (fileWriter.writeFile(path, DataManager.exportMeasurementsCsv())) {
            report(qsTr("Saved to %1").arg(path), false);
        } else {
            report(fileWriter.lastError(), true);
        }
    }

    function restore(path) {
        var content = fileWriter.readFile(path);
        if (content === "") {
            report(fileWriter.lastError(), true);
            return;
        }
        try {
            DataManager.restoreAll(JSON.parse(content));
        } catch (error) {
            report(qsTr("Restore failed: %1").arg(error.message), true);
            return;
        }
        report(qsTr("Restored from %1").arg(path), false);
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
        var files = fileWriter.listFiles(directory, ".json");
        for (var i = 0; i < files.length; i++) {
            var path = String(files[i]);
            backupModel.append({ path: path, name: path.substring(path.lastIndexOf("/") + 1) });
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: backupModel

        header: Column {
            width: listView.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Backup and restore")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                text: qsTr("A backup covers every profile and all of its data, not just the one you are using. Files are written to the Health folder in your Documents, in readable form — keep them somewhere private.")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Export full backup")
                onClicked: page.exportJson()
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Export measurements as CSV")
                onClicked: page.exportCsv()
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: page.statusIsError ? Theme.errorColor : Theme.highlightColor
                visible: page.statusMessage !== ""
                text: page.statusMessage
            }

            SectionHeader {
                text: qsTr("Restore")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                text: qsTr("Restoring replaces everything currently in the app — every profile and all of its data — with the contents of the backup. Export a backup first if you are unsure.")
            }
        }

        delegate: ListItem {
            id: backupItem
            contentHeight: Theme.itemSizeSmall

            onClicked: backupItem.remorseAction(qsTr("Replacing all data"), function() {
                page.restore(model.path);
            })

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: model.name
                truncationMode: TruncationMode.Fade
                color: backupItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
        }

        ViewPlaceholder {
            enabled: backupModel.count === 0
            text: qsTr("No backups found")
            hintText: qsTr("Export one first, or copy a backup file into Documents/Health")
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: backupModel
    }

    Component.onCompleted: refreshBackups()
}

// vim:et:ts=4:sw=4
