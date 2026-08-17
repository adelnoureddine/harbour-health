import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge

            Item {
                width: parent.width
                height: childrenRect.height

                PageHeader {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    title: qsTr("Health")
                }
            }

            Label {
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
                width: parent.width - ( 2 * Theme.horizontalPageMargin )
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Health is a health and fitness tracker")
                font.pixelSize: Theme.fontSizeSmall
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
            }

            Item {
                width: parent.width
                height: childrenRect.height

                SectionHeader {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    text: qsTr("Privacy and medical use")
                }
            }

            Label {
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
                width: parent.width - (2 * Theme.horizontalPageMargin)
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Your health data is stored only on this device. Health is not medical advice and must not be used for diagnosis or treatment decisions.")
                font.pixelSize: Theme.fontSizeSmall
            }

            Item {
                width: parent.width
                height: childrenRect.height

                SectionHeader {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    text: qsTr("Maintainer and Current Developers")
                }
            }

            Label {
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
                width: parent.width - ( 2 * Theme.horizontalPageMargin )
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Adel Noureddine (project lead and maintainer) © 2022-2026")
                font.pixelSize: Theme.fontSizeSmall
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
            }

            Item {
                width: parent.width
                height: childrenRect.height

                SectionHeader {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    text: qsTr("Students and Contributors")
                }
            }

            Column {

                width: parent.width

                Label {
                    text: "Dylan Mignot-Bousseau © 2022"
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Label {
                    text: "Lucille Rey © 2022"
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Label {
                    text: "Mathieu Vazquez © 2022"
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Label {
                    text: "Angel Gezat © 2022"
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Label {
                    text: "Bienvenu Akoun © 2022"
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Label {
                    text: "Thomas Abadie © 2022"
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Label {
                    text: "Ashraf Ajouka © 2022"
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Label {
                    text: "Jose Buepoyo Sopale © 2022"
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Label {
                    text: "Charlotte Ortali © 2022"
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Label {
                    text: "Maarten Vanraes © 2026"
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Label {
                    text: "Ilies Hamadene © 2026"
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                }

            }

            Item {
                width: parent.width
                height: childrenRect.height

                SectionHeader {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    text: qsTr("Source Code")
                }
            }

            Label {
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
                width: parent.width - ( 2 * Theme.horizontalPageMargin )
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Licensed under the GNU GPL 3 license only (GPL-3.0-only)")
                font.pixelSize: Theme.fontSizeSmall
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
            }

            Icon {
                 source: "image://theme/icon-s-cloud-download"
                 anchors {
                     horizontalCenter: parent.horizontalCenter
                 }
             }

            Text {
                text: "<a href=\"https://github.com/adelnoureddine/harbour-health\">" + qsTr("View source code on GitHub") + "</a>"
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
                font.pixelSize: Theme.fontSizeSmall
                linkColor: Theme.highlightColor

                onLinkActivated: Qt.openUrlExternally("https://github.com/adelnoureddine/harbour-health")
            }
        }
    }
}
