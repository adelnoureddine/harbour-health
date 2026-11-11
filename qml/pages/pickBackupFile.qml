import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0

/*
 * Picks a backup file from anywhere the app may read: Documents, Downloads or a memory
 * card (see Permissions in harbour-health.desktop). A backup received by Bluetooth or
 * downloaded lands in Downloads; without this it had to be moved into Documents/Health
 * with a file manager first.
 *
 * A page of its own so that the Backup and restore page still loads should the
 * Sailfish.Pickers module ever be missing.
 */
FilePickerPage {
    id: picker

    // The path of the file that was chosen. The page closes itself after it.
    signal picked(string path)

    //: Title of the page for choosing a backup file to restore
    title: qsTr("Choose a backup")
    nameFilters: ["*.json"]

    onSelectedContentPropertiesChanged: {
        if (selectedContentProperties !== null && selectedContentProperties.filePath) {
            picker.picked(String(selectedContentProperties.filePath));
        }
    }
}

// vim:et:ts=4:sw=4
