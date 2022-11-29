import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    BusyLabel {
        // In real use case replace with a more descriptive title
        text: "Loading page"
        running: simulatedLoading.running
    }

    Timer {
        // When loading takes more than a second start with a busy indication
        id: simulatedLoading
        interval: 1500
        running: true
    }

    SilicaFlickable {
        opacity: simulatedLoading.running ? 0.0 : 1.0
        Behavior on opacity { FadeAnimator { duration: 400 } }

        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        VerticalScrollDecorator {}

        Column {
            id: column
            spacing: Theme.paddingLarge
            width: parent.width

            PageHeader { title: "Progress Indicators" }

            SectionHeader { text: "Busy indicator" }

            Row {
                spacing: Theme.paddingLarge
                anchors.horizontalCenter: parent.horizontalCenter
                BusyIndicator {
                    running: true
                    size: BusyIndicatorSize.ExtraSmall
                    anchors.verticalCenter: parent.verticalCenter
                }
                BusyIndicator {
                    running: true
                    size: BusyIndicatorSize.Small
                    anchors.verticalCenter: parent.verticalCenter
                }
                BusyIndicator {
                    running: true
                    size: BusyIndicatorSize.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
                BusyIndicator {
                    running: true
                    size: BusyIndicatorSize.Large
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            SectionHeader { text: "Progress bar" }
            ProgressBar {
                id: progressBar
                width: parent.width
                maximumValue: 100
                valueText: value
                label: "Progress"
                Timer {
                    interval: 100
                    repeat: true
                    onTriggered: progressBar.value = (progressBar.value + 1) % 100
                    running: Qt.application.active
                }
            }
            ProgressBar {
                width: parent.width
                indeterminate: true
                label: "Indeterminate"
            }
            SectionHeader { text: "Progress circle" }
            ProgressCircle {
                id: progressCircle

                anchors.horizontalCenter: parent.horizontalCenter

                Timer {
                    interval: 32
                    repeat: true
                    onTriggered: progressCircle.value = (progressCircle.value + 0.005) % 1.0
                    running: Qt.application.active
                }
            }
        }
    }
}
