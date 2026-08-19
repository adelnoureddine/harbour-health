import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    allowedOrientations: Orientation.All

    readonly property string sourceUrl: "https://github.com/adelnoureddine/harbour-health"

    readonly property var contributors: [
        "Dylan Mignot-Bousseau © 2022",
        "Lucille Rey © 2022",
        "Mathieu Vazquez © 2022",
        "Angel Gezat © 2022",
        "Bienvenu Akoun © 2022",
        "Thomas Abadie © 2022",
        "Ashraf Ajouka © 2022",
        "Jose Buepoyo Sopale © 2022",
        "Charlotte Ortali © 2022",
        "Maarten Vanraes © 2026",
        "Ilies Hamadene © 2026"
    ]

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Health")
                description: qsTr("Version %1").arg(appVersion)
            }

            Label {
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("A private health tracker. Everything stays on this device.")
                font.pixelSize: Theme.fontSizeSmall
            }

            SectionHeader {
                text: qsTr("Privacy and medical use")
            }

            Label {
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Your health data is stored only on this device. Health is not medical advice and must not be used for diagnosis or treatment decisions.")
                font.pixelSize: Theme.fontSizeSmall
            }

            SectionHeader {
                text: qsTr("Maintainer and Current Developers")
            }

            Label {
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Adel Noureddine (project lead and maintainer) © 2022-2026")
                font.pixelSize: Theme.fontSizeSmall
            }

            SectionHeader {
                text: qsTr("Students and Contributors")
            }

            Column {
                width: parent.width

                Repeater {
                    model: page.contributors

                    Label {
                        width: page.width - 2 * Theme.horizontalPageMargin
                        x: Theme.horizontalPageMargin
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        text: modelData
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }

            SectionHeader {
                text: qsTr("Source Code")
            }

            Label {
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Licensed under the GNU GPL 3 license only (GPL-3.0-only)")
                font.pixelSize: Theme.fontSizeSmall
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("View source code")
                onClicked: Qt.openUrlExternally(page.sourceUrl)
            }

            Item { width: 1; height: Theme.paddingLarge }
        }

        VerticalScrollDecorator {}
    }
}

// vim:et:ts=4:sw=4
