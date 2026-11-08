import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page

    allowedOrientations: Orientation.All

    readonly property string sourceUrl: "https://github.com/adelnoureddine/harbour-health"
    readonly property string licenseUrl: "https://www.gnu.org/licenses/gpl-3.0.html"
    // Set by the C++ launcher. Undefined when the page is loaded without it (qmlscene).
    readonly property string version: typeof appVersion !== "undefined" ? String(appVersion) : ""

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
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("About")
            }

            // The app icon, name and version.
            Column {
                width: parent.width
                spacing: Theme.paddingSmall

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Theme.iconSizeExtraLarge
                    height: width
                    sourceSize.width: width
                    sourceSize.height: height
                    fillMode: Image.PreserveAspectFit
                    // The launcher icon installed with the app (SAILFISHAPP_ICONS), at its
                    // largest size since it is shown large here.
                    source: "/usr/share/icons/hicolor/172x172/apps/harbour-health.png"
                }

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    //: The app's name
                    text: qsTr("Health")
                    font.pixelSize: Theme.fontSizeExtraLarge
                    color: Theme.primaryColor
                }

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    visible: page.version !== ""
                    text: qsTr("Version %1").arg(page.version)
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                }

                Item { width: 1; height: Theme.paddingMedium }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("A private health tracker. Everything stays on this device.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                }
            }

            Card {
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("Privacy and medical use")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("Your health data is stored only on this device. Health is not medical advice and must not be used for diagnosis or treatment decisions.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                }
            }

            Card {
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("Maintainer and current developers")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("Adel Noureddine (project lead and maintainer) © 2022-2026")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                }

                Item { width: 1; height: Theme.paddingMedium }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("Students and contributors")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                }

                Repeater {
                    model: page.contributors

                    Label {
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: modelData
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.primaryColor
                    }
                }
            }

            SectionHeader {
                text: qsTr("Source code")
            }

            // Opened in the browser. Rows rather than buttons, like the app's other lists.
            Column {
                width: parent.width
                spacing: Theme.paddingMedium

                Repeater {
                    model: [
                        {
                            title: qsTr("View source code"),
                            detail: page.sourceUrl.replace("https://", ""),
                            url: page.sourceUrl,
                            icon: "image://theme/icon-m-developer-mode"
                        },
                        {
                            //: Link to the text of the app's software license
                            title: qsTr("License"),
                            detail: qsTr("Licensed under the GNU GPL 3 license only (GPL-3.0-only)"),
                            url: page.licenseUrl,
                            icon: "image://theme/icon-m-document"
                        }
                    ]

                    delegate: BackgroundItem {
                        id: linkRow
                        width: column.width
                        height: Math.max(Theme.itemSizeMedium, linkText.height + 2 * Theme.paddingMedium)
                        highlightedColor: "transparent"
                        onClicked: Qt.openUrlExternally(modelData.url)

                        CardBackground {
                            x: Theme.horizontalPageMargin
                            width: parent.width - 2 * Theme.horizontalPageMargin
                            height: parent.height
                            highlighted: linkRow.highlighted
                        }

                        Icon {
                            id: linkIcon
                            x: Theme.horizontalPageMargin + Theme.paddingLarge
                            anchors.verticalCenter: parent.verticalCenter
                            source: modelData.icon
                            highlighted: linkRow.highlighted
                        }

                        Column {
                            id: linkText
                            anchors.left: linkIcon.right
                            anchors.leftMargin: Theme.paddingLarge
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.horizontalPageMargin + Theme.paddingLarge
                            anchors.verticalCenter: parent.verticalCenter

                            Label {
                                width: parent.width
                                truncationMode: TruncationMode.Fade
                                text: modelData.title
                                color: linkRow.highlighted ? Theme.highlightColor : Theme.primaryColor
                            }
                            Label {
                                width: parent.width
                                wrapMode: Text.Wrap
                                text: modelData.detail
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: linkRow.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                            }
                        }
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }
}

// vim:et:ts=4:sw=4
