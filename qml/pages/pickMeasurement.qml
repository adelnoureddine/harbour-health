import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

/*
 * The dashboard's "Add measurement": the types this profile logged last, then every
 * type as a tile. It used to open the entry dialog straight away, where the type had
 * to be picked from a combo box first. Picking a type here replaces this page with
 * its dialog, so Back (or saving) returns to the dashboard, not to the picker.
 */
Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string profileName: ""

    // [{name, unit}] for the tiles, and [{name, unit, hint}] for the recent rows.
    property var types: []
    property var recent: []
    // What the page last loaded (see DataManager.dataKey).
    property string loadedFrom: ""

    // Systolic and diastolic are one reading, logged together: offered as one type.
    readonly property string bpKey: DataManager.CALC_BP

    // Three tiles a row in portrait, five in landscape.
    readonly property int columns: isLandscape ? 5 : 3
    readonly property real gap: Theme.paddingMedium
    readonly property real tileWidth: Math.floor((width - 2 * Theme.horizontalPageMargin
                                                  - (columns - 1) * gap) / columns)
    // Room for two lines of label in every tile, so the icons of a row line up.
    readonly property real tileHeight: 2 * Theme.paddingLarge + Theme.iconSizeMedium
                                       + Theme.paddingSmall + twoLines.height

    // Body, then intake, then blood, as on the dashboard. Anything else follows by name.
    readonly property var typeOrder: [DataManager.METRIC_WEIGHT, DataManager.METRIC_HEIGHT,
                                      DataManager.METRIC_WAIST, DataManager.METRIC_WATER,
                                      DataManager.METRIC_CALORIES, DataManager.METRIC_CALORIES_BURNED,
                                      DataManager.METRIC_HEARTRATE,
                                      bpKey, DataManager.METRIC_GLUCOSE]

    function iconSource(name) {
        var file = Utils.moduleIcon(name);
        return file !== "" ? Qt.resolvedUrl("../icons/" + file) : "image://theme/icon-m-add";
    }

    function rank(name) {
        var i = typeOrder.indexOf(name);
        return i >= 0 ? i : typeOrder.length;
    }

    /*
     * The latest reading of a type as {ms, hint}, or null when it was never logged.
     * `latest` is DataManager.getLatestLogs(): every type in one query, not one each.
     */
    function lastReading(latest, name, unit) {
        var valueText;
        var timestamp;
        if (name === bpKey) {
            var bp = DataManager.bloodPressureFrom(latest[DataManager.METRIC_BP_SYS] || null,
                                                   latest[DataManager.METRIC_BP_DIA] || null);
            if (bp === null) {
                return null;
            }
            valueText = Utils.formatBloodPressure(bp, unit);
            timestamp = bp.timestamp;
        } else {
            var log = latest[name];
            if (!log) {
                return null;
            }
            var shownUnit = DataManager.displayUnit(name, unit);
            valueText = Utils.formatValue(DataManager.toDisplay(name, log.value), DataManager.displayDecimals(name, 2))
                    + (shownUnit ? " " + shownUnit : "");
            timestamp = log.timestamp;
        }
        return { ms: DataManager.timestampToMs(timestamp), hint: Utils.lastReadingText(valueText, timestamp) };
    }

    function load() {
        var key = DataManager.dataKey();
        var profile = DataManager.getProfile(profileId);
        profileName = profile ? profile.firstName : "";

        var list = [];
        var bpUnit = null;
        var metrics = DataManager.getMetrics();
        for (var i = 0; i < metrics.length; i++) {
            var m = metrics[i];
            if (m.name === DataManager.METRIC_BP_SYS || m.name === DataManager.METRIC_BP_DIA) {
                bpUnit = m.unit ? m.unit : (bpUnit || "");
                continue;
            }
            list.push({ name: m.name, unit: m.unit ? m.unit : "" });
        }
        if (bpUnit !== null) {
            list.push({ name: bpKey, unit: bpUnit });
        }
        list.sort(function (a, b) {
            var byRank = rank(a.name) - rank(b.name);
            return byRank !== 0 ? byRank
                                : Utils.metricDisplayName(a.name).localeCompare(Utils.metricDisplayName(b.name));
        });

        var latest = DataManager.getLatestLogs(profileId);
        var logged = [];
        for (var j = 0; j < list.length; j++) {
            var last = lastReading(latest, list[j].name, list[j].unit);
            if (last !== null) {
                logged.push({ name: list[j].name, unit: list[j].unit, hint: last.hint, ms: last.ms });
            }
        }
        logged.sort(function (a, b) { return b.ms - a.ms; });

        types = list;
        recent = logged.slice(0, 3);
        loadedFrom = key;
    }

    function openEntry(name, unit) {
        if (name === bpKey) {
            pageStack.replace(Qt.resolvedUrl("addEntryMultiMetric.qml"), {
                profileId: page.profileId,
                metricName1: DataManager.METRIC_BP_SYS,
                metricName2: DataManager.METRIC_BP_DIA,
                metricUnit: unit
            });
        } else {
            pageStack.replace(Qt.resolvedUrl("addEntryMetric.qml"), {
                profileId: page.profileId,
                metricName: name,
                metricUnit: unit,
                lockMetric: true
            });
        }
    }

    // Two lines of tile label, measured once: every tile is sized for the longest name.
    Label {
        id: twoLines
        visible: false
        text: "X\nX"
        font.pixelSize: Theme.fontSizeSmall
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        Column {
            id: content
            width: parent.width

            PageHeader {
                title: qsTr("Add measurement")
                description: page.profileName
            }

            SectionHeader {
                //: Section of the Add measurement picker: the types logged most recently
                text: qsTr("Recent")
                visible: page.recent.length > 0
            }

            Column {
                width: parent.width
                spacing: page.gap
                visible: page.recent.length > 0

                Repeater {
                    model: page.recent

                    delegate: ListItem {
                        id: recentRow
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        contentHeight: Math.max(Theme.itemSizeMedium, recentText.height + 2 * Theme.paddingMedium)
                        // The card below shows the press instead of a full-width block.
                        highlightedColor: "transparent"
                        onClicked: page.openEntry(modelData.name, modelData.unit)

                        CardBackground {
                            anchors.fill: parent
                            highlighted: recentRow.highlighted
                        }

                        HighlightImage {
                            id: recentIcon
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.paddingLarge
                            anchors.verticalCenter: parent.verticalCenter
                            width: Theme.iconSizeMedium
                            height: Theme.iconSizeMedium
                            sourceSize.width: Theme.iconSizeMedium
                            sourceSize.height: Theme.iconSizeMedium
                            source: page.iconSource(modelData.name)
                            color: Theme.secondaryHighlightColor
                            highlighted: recentRow.highlighted
                        }

                        Column {
                            id: recentText
                            anchors.left: recentIcon.right
                            anchors.leftMargin: Theme.paddingLarge
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.paddingLarge
                            anchors.verticalCenter: parent.verticalCenter

                            Label {
                                width: parent.width
                                truncationMode: TruncationMode.Fade
                                text: Utils.metricDisplayName(modelData.name)
                                color: recentRow.highlighted ? Theme.highlightColor : Theme.primaryColor
                            }
                            Label {
                                width: parent.width
                                truncationMode: TruncationMode.Fade
                                text: modelData.hint
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: recentRow.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                            }
                        }
                    }
                }
            }

            SectionHeader {
                //: Section of the Add measurement picker that lists every measurement type
                text: qsTr("Everything")
            }

            Grid {
                x: Theme.horizontalPageMargin
                columns: page.columns
                spacing: page.gap

                Repeater {
                    model: page.types

                    delegate: BackgroundItem {
                        id: tile
                        width: page.tileWidth
                        height: page.tileHeight
                        highlightedColor: "transparent"
                        onClicked: page.openEntry(modelData.name, modelData.unit)

                        CardBackground {
                            anchors.fill: parent
                            highlighted: tile.highlighted
                        }

                        HighlightImage {
                            id: tileIcon
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: Theme.paddingLarge
                            width: Theme.iconSizeMedium
                            height: Theme.iconSizeMedium
                            sourceSize.width: Theme.iconSizeMedium
                            sourceSize.height: Theme.iconSizeMedium
                            source: page.iconSource(modelData.name)
                            color: Theme.secondaryHighlightColor
                            highlighted: tile.highlighted
                        }

                        Label {
                            anchors.top: tileIcon.bottom
                            anchors.topMargin: Theme.paddingSmall
                            x: Theme.paddingSmall
                            width: parent.width - 2 * Theme.paddingSmall
                            height: twoLines.height
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            truncationMode: TruncationMode.Elide
                            text: Utils.metricDisplayName(modelData.name)
                            font.pixelSize: Theme.fontSizeSmall
                            color: tile.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }

    // Loaded before the page slides in, so it does not fill up during the animation.
    Component.onCompleted: load()

    onStatusChanged: {
        if (status === PageStatus.Active && DataManager.dataKey() !== loadedFrom) {
            load();
        }
    }
}

// vim:et:ts=4:sw=4
