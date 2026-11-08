import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

// Daily goal behind a dashboard ring (water, calories).
Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string metricName
    property string metricUnit

    // What a day usually adds up to, to pick a goal against. Empty without readings.
    property string averageText: ""

    canAccept: profileId >= 0 && goalField.acceptableInput
               && parseFloat(goalField.text.replace(',', '.')) > 0

    onAccepted: DataManager.setGoal(profileId, metricName, parseFloat(goalField.text.replace(',', '.')))

    // Days with nothing logged are left out: they are gaps in the log, not zero days.
    function dailyAverageText() {
        var stats = DataManager.getSeriesStats(profileId, metricName, DataManager.sinceForDays(30, true),
                                               DataManager.SERIES_DAILY_SUM);
        if (!stats || stats.count === 0 || stats.avg === null) {
            return "";
        }
        //: Under the goal field; %1 is an amount with its unit, e.g. "1.6 L"
        return qsTr("Your daily average over the last 30 days: %1")
                .arg(Utils.formatValue(stats.avg, Utils.metricDecimals(metricName))
                     + (metricUnit ? " " + metricUnit : ""));
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: qsTr("Daily goal")
                acceptText: qsTr("Save")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                truncationMode: TruncationMode.Fade
                text: Utils.metricDisplayName(dialog.metricName)
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.highlightColor
            }

            Column {
                width: parent.width
                spacing: Theme.paddingSmall

                TextField {
                    id: goalField
                    width: parent.width
                    label: dialog.metricUnit ? qsTr("Goal per day (%1)").arg(dialog.metricUnit) : qsTr("Goal per day")
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: RegExpValidator { regExp: /^\d{1,6}([.,]\d{1,3})?$/ }
                    focus: true
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.enabled: dialog.canAccept
                    EnterKey.onClicked: dialog.accept()
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    text: dialog.averageText
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    visible: goalField.text !== "" && !(parseFloat(goalField.text.replace(',', '.')) > 0)
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.errorColor
                    text: qsTr("The goal must be more than zero.")
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                // The day border in the user's own clock format: "4:00" read oddly in a
                // 12-hour locale.
                //: %1 is the time the day's total resets, e.g. "04:00" or "4:00 AM"
                text: qsTr("Shown as a ring on the dashboard. The day's total starts again at %1.")
                      .arg(Utils.formatTime(DataManager.dayStart()))
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: {
        goalField.text = Utils.formatInput(DataManager.getGoal(profileId, metricName));
        averageText = dailyAverageText();
    }
}

// vim:et:ts=4:sw=4
