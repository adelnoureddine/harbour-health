import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

/*
 * Daily goal behind a dashboard ring (water, calories), the daily meditation goal, or
 * the target of a measurement followed over time (weight, waist), drawn as a line on
 * its chart. All three are a row of the Goals table under the metric's name.
 */
Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string metricName
    // The stored unit (Metrics.unit); the goal is typed in shownUnit, chosen in Units.
    property string metricUnit

    // Minutes of meditation: not a measurement, and shown on the Today page only.
    readonly property bool meditation: metricName === DataManager.GOAL_MEDITATION
    // A value to reach rather than a daily total.
    readonly property bool target: DataManager.hasTarget(metricName)

    property string shownUnit: metricUnit
    // What the goal can be, in shownUnit; null without limits.
    property var limits: null
    property int limitDecimals: 2

    // What a day usually adds up to, or the latest reading, to pick a goal against.
    property string contextText: ""

    /*
     * The stored goal and the text the field opened with: left untouched, the stored
     * value is kept as it is rather than converted to the shown unit and back.
     */
    property var originalValue: null
    property string originalText: ""
    readonly property bool untouched: originalValue !== null && goalField.text === originalText

    function typedValue() {
        return parseFloat(goalField.text.replace(',', '.'));
    }

    readonly property bool inRange: {
        if (limits === null || goalField.text === "" || !goalField.acceptableInput) {
            return true;
        }
        var v = typedValue();
        return isNaN(v) || (v >= limits.min - 1e-9 && v <= limits.max + 1e-9);
    }

    // Switched off, there is nothing to type: a goal could not be removed once set.
    canAccept: profileId >= 0 && (!goalSwitch.checked
                                  || (goalField.acceptableInput && typedValue() > 0 && (untouched || inRange)))

    onAccepted: {
        if (!goalSwitch.checked) {
            DataManager.setGoal(profileId, metricName, 0);
        } else {
            DataManager.setGoal(profileId, metricName,
                                untouched ? originalValue : DataManager.fromDisplay(metricName, typedValue()));
        }
    }

    // Days with nothing logged are left out: they are gaps in the log, not zero days.
    function dailyAverageText() {
        var stats = DataManager.getSeriesStats(profileId, metricName, DataManager.sinceForDays(30, true),
                                               DataManager.SERIES_DAILY_SUM);
        if (!stats || stats.count === 0 || stats.avg === null) {
            return "";
        }
        //: Under the goal field; %1 is an amount with its unit, e.g. "1.6 L"
        return qsTr("Your daily average over the last 30 days: %1")
                .arg(Utils.formatValue(DataManager.toDisplay(metricName, stats.avg),
                                       DataManager.displayDecimals(metricName, Utils.metricDecimals(metricName)))
                     + (shownUnit ? " " + shownUnit : ""));
    }

    function latestReadingText() {
        var log = DataManager.getLatestLog(profileId, metricName);
        return log ? Utils.lastReadingText(Utils.formatValue(DataManager.toDisplay(metricName, log.value),
                                                             DataManager.displayDecimals(metricName, 2))
                                           + (shownUnit ? " " + shownUnit : ""), log.timestamp)
                   : "";
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                //: Dialog title: the value a measurement such as weight should reach
                title: dialog.target ? qsTr("Target") : qsTr("Daily goal")
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

            TextSwitch {
                id: goalSwitch
                //: Switch in the goal dialog: whether the measurement has a target at all
                text: dialog.target ? qsTr("Follow a target")
                                    //: Switch in the goal dialog: whether there is a daily goal at all
                                    : qsTr("Use a daily goal")
                description: checked ? ""
                             : dialog.target ? qsTr("Without a target no line is drawn on the chart.")
                             : dialog.meditation ? qsTr("Without a goal meditation is not on the Today page.")
                             : qsTr("Without a goal the dashboard shows the day's total only.")
            }

            Column {
                width: parent.width
                spacing: Theme.paddingSmall
                visible: goalSwitch.checked

                TextField {
                    id: goalField
                    width: parent.width
                    label: dialog.target
                           //: Label of the target field; %1 is a unit
                           ? (dialog.shownUnit ? qsTr("Target (%1)").arg(dialog.shownUnit) : qsTr("Target"))
                           : (dialog.shownUnit ? qsTr("Goal per day (%1)").arg(dialog.shownUnit) : qsTr("Goal per day"))
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: RegExpValidator { regExp: /^\d{1,6}([.,]\d{1,3})?$/ }
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.enabled: dialog.canAccept
                    EnterKey.onClicked: dialog.accept()
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    text: dialog.contextText
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    visible: goalField.text !== "" && !(dialog.typedValue() > 0)
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.errorColor
                    text: qsTr("The goal must be more than zero.")
                }

                // 2000 typed for two litres of water.
                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    visible: dialog.limits !== null && dialog.typedValue() > 0 && !dialog.inRange && !dialog.untouched
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.errorColor
                    text: dialog.limits === null ? ""
                          : Utils.rangeText(dialog.limits.min, dialog.limits.max, dialog.shownUnit, dialog.limitDecimals)
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: goalSwitch.checked
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                // The day border in the user's own clock format: "4:00" read oddly in a
                // 12-hour locale.
                text: dialog.target
                      ? qsTr("Shown as a line on the chart, with how far there is to go.")
                      : (dialog.meditation
                         //: %1 is the time a new day starts, e.g. "04:00" or "4:00 AM"
                         ? qsTr("Shown on the Today page. A new day starts at %1.")
                         //: %1 is the time the day's total resets, e.g. "04:00" or "4:00 AM"
                         : qsTr("Shown as a ring on the dashboard. The day's total starts again at %1."))
                        .arg(Utils.formatTime(DataManager.dayStart()))
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: {
        shownUnit = DataManager.displayUnit(metricName, metricUnit);
        var stored = DataManager.goalLimits(metricName);
        limits = stored === null ? null : { min: DataManager.toDisplay(metricName, stored.min),
                                            max: DataManager.toDisplay(metricName, stored.max) };
        limitDecimals = DataManager.displayDecimals(metricName, 2);

        // The goal in use: the user's, or the default one of water and calories. 0 is
        // a goal switched off. Without any yet (a target, the meditation goal) the
        // dialog was opened to set one, so the field is there to type in.
        var goal = DataManager.getGoal(profileId, metricName);
        var active = goal !== null && goal > 0;
        goalSwitch.checked = active || goal === null;
        if (active) {
            goalField.text = Utils.formatInput(DataManager.toDisplay(metricName, goal));
            originalValue = goal;
            originalText = goalField.text;
        }
        contextText = meditation ? "" : target ? latestReadingText() : dailyAverageText();
        if (goalSwitch.checked) {
            goalField.focus = true;
        }
    }
}

// vim:et:ts=4:sw=4
