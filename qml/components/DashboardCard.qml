import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

/*
 * Dashboard card for a module with a reading of its own: a metric, BMI or the
 * waist-to-height ratio, blood pressure. Weight is drawn wide with its 30-day trend.
 * With nothing to show yet, the card shrinks to a one-line "No readings yet" row.
 * Tapping always opens the history; adding goes through the long-press menu.
 *
 * It loads its own data, and the dashboard calls refresh() again when something was
 * saved elsewhere, so it is updated in place instead of rebuilt.
 */
ListItem {
    id: card

    property int profileId: -1
    property var module: ({})
    property real halfWidth: 0
    property real fullWidth: 0
    property real cardHeight: Theme.itemSizeHuge

    readonly property string moduleName: module && module.name ? module.name : ""
    readonly property bool isBP: moduleName === DataManager.MODULE_BP
    readonly property bool isCalc: module && module.type === DataManager.MODULE_TYPE_CALC && !isBP
    readonly property string metricName: module && module.type === DataManager.MODULE_TYPE_METRIC ? module.uses
                                       : (isBP ? DataManager.METRIC_BP_SYS : "")
    readonly property string unit: module && module.unit ? module.unit : ""
    readonly property string iconSource: Qt.resolvedUrl("../icons/" + Utils.moduleIcon(moduleName, module.icon))
    readonly property string title: Utils.moduleDisplayName(moduleName)

    property var value: null
    property string timestamp: ""
    property string bandLabel: ""
    property color bandColor: "transparent"
    property var trend: []
    property string changeText: ""

    readonly property bool empty: value === null || value === undefined
    // Weight is the one most people follow over time: shown wide, with its trend, once
    // there are at least two readings to draw one from.
    readonly property bool hero: !empty && metricName === DataManager.METRIC_WEIGHT && trend.length >= 2

    // A wide card takes a whole row. The dashboard may also widen a half card that
    // would otherwise sit alone on its row.
    readonly property bool wantsWide: empty || hero
    property bool wide: wantsWide

    width: wide ? fullWidth : halfWidth
    readonly property real layoutHeight: layout.item ? layout.item.height : 0
    readonly property real naturalHeight: empty ? Theme.itemSizeMedium
                 : hero ? layoutHeight + 2 * Theme.paddingLarge
                 : Math.max(cardHeight, layoutHeight + 2 * Theme.paddingLarge)
    // Set by the dashboard so two cards sharing a row are the same height.
    property real rowHeight: 0
    contentHeight: Math.max(naturalHeight, rowHeight)

    // A half card's title takes one line or two (titleNaturalHeight). The dashboard
    // sets titleHeight to the taller title of the row, so the two values stay level.
    readonly property real titleNaturalHeight: !empty && !hero && layout.item
                                               && layout.item.titleNaturalHeight !== undefined
                                               ? layout.item.titleNaturalHeight : 0
    property real titleHeight: 0
    // The rounded background below shows the press instead of a full-width block.
    highlightedColor: "transparent"

    function refresh() {
        if (profileId < 0 || moduleName === "") {
            return;
        }
        var v = null;
        var ts = "";
        var match = null;
        var points = [];
        var change = "";

        if (isBP) {
            var bp = DataManager.getLatestBloodPressure(profileId);
            if (bp !== null && bp.systolic !== null && bp.diastolic !== null) {
                v = bp.systolic + "/" + bp.diastolic;
                match = DataManager.matchWorstConstraint([
                    { metricName: DataManager.METRIC_BP_SYS, value: bp.systolic },
                    { metricName: DataManager.METRIC_BP_DIA, value: bp.diastolic }
                ]);
            }
        } else if (isCalc) {
            v = DataManager.calculateMetrics(profileId, module.uses);
            if (v !== null) {
                match = DataManager.matchConstraint(moduleName, v);
            }
        } else if (metricName === DataManager.METRIC_WEIGHT) {
            // The trend ends with the latest reading, so it is the reading too.
            var series = DataManager.getTrend(profileId, metricName);
            if (series.length > 0) {
                var last = series[series.length - 1];
                v = last.v;
                ts = DataManager.toTimestamp(new Date(last.t));
                match = DataManager.matchConstraint(metricName, v);
                for (var i = 0; i < series.length; i++) {
                    points.push(series[i].v);
                }
                change = Utils.changeSinceText(series, unit, Utils.metricDecimals(metricName));
            }
        } else if (metricName !== "") {
            var log = DataManager.getLatestLog(profileId, metricName);
            if (log) {
                v = log.value;
                ts = log.timestamp;
                match = DataManager.matchConstraint(metricName, v);
            }
        }

        var band = Utils.bandFor(match);
        timestamp = ts;
        trend = points;
        changeText = change;
        bandLabel = band.label;
        bandColor = band.color;
        value = v;
    }

    function openDetails() {
        if (isBP) {
            pageStack.animatorPush(Qt.resolvedUrl("../pages/MultiMetricDetails.qml"), {
                profileId: card.profileId,
                metricName1: DataManager.METRIC_BP_SYS,
                metricName2: DataManager.METRIC_BP_DIA
            });
        } else if (isCalc) {
            pageStack.animatorPush(Qt.resolvedUrl("../pages/CalcMetricDetails.qml"), {
                profileId: card.profileId,
                calculate: card.module.uses,
                title: card.title,
                constraintKey: card.moduleName,
                metricUnit: ""
            });
        } else {
            pageStack.animatorPush(Qt.resolvedUrl("../pages/MetricDetails.qml"), {
                profileId: card.profileId,
                grouped: card.module.grouped ? true : false,
                metricName: card.metricName,
                metricUnit: card.unit
            });
        }
    }

    function openAdd() {
        if (isBP) {
            pageStack.animatorPush(Qt.resolvedUrl("../pages/addEntryMultiMetric.qml"), {
                profileId: card.profileId,
                metricName1: DataManager.METRIC_BP_SYS,
                metricName2: DataManager.METRIC_BP_DIA,
                metricUnit: card.unit
            });
        } else {
            pageStack.animatorPush(Qt.resolvedUrl("../pages/addEntryMetric.qml"), {
                profileId: card.profileId,
                metricName: card.metricName,
                metricUnit: card.unit,
                lockMetric: true
            });
        }
    }

    // The dashboard only shows. Even an empty card opens its history page, which
    // says how to add the first entry.
    onClicked: openDetails()

    // Built when first opened, like every list menu in the app. Derived values have
    // nothing to type in, so they have no menu.
    menu: isCalc ? null : menuComponent

    Component {
        id: menuComponent
        ContextMenu {
            MenuItem {
                text: qsTr("Add entry")
                onClicked: card.openAdd()
            }
            MenuItem {
                text: qsTr("History")
                onClicked: card.openDetails()
            }
        }
    }

    CardBackground {
        anchors.fill: parent
        highlighted: card.highlighted
        subtle: card.empty
    }

    // Only the layout the card shows is created: a dozen cards each carrying all three
    // (and a trend canvas) made the dashboard slow to build without a disk cache.
    Loader {
        id: layout
        x: card.empty ? 0 : Theme.paddingLarge
        y: card.empty ? 0 : Theme.paddingLarge
        sourceComponent: card.empty ? emptyLayout : card.hero ? heroLayout : halfLayout
    }

    // --- nothing recorded yet: one line ---------------------------------------------
    Component {
        id: emptyLayout
        Item {
            width: card.width
            height: card.height

            HighlightImage {
                id: emptyIcon
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.iconSizeSmall
                height: Theme.iconSizeSmall
                sourceSize.width: Theme.iconSizeSmall
                sourceSize.height: Theme.iconSizeSmall
                source: card.iconSource
                color: Theme.secondaryColor
                highlighted: card.highlighted
            }
            Label {
                anchors.left: emptyIcon.right
                anchors.leftMargin: Theme.paddingMedium
                anchors.right: emptyHint.left
                anchors.rightMargin: Theme.paddingMedium
                anchors.verticalCenter: parent.verticalCenter
                truncationMode: TruncationMode.Fade
                text: card.title
                color: card.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            Label {
                id: emptyHint
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: Theme.fontSizeSmall
                color: card.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                text: card.moduleName === DataManager.MODULE_BMI ? qsTr("Needs height and weight")
                    : card.moduleName === DataManager.MODULE_WHTR ? qsTr("Needs height and waist")
                    : qsTr("No readings yet")
            }
        }
    }

    // --- wide card with the trend (weight) ------------------------------------------
    Component {
        id: heroLayout
        Column {
            width: card.width - 2 * Theme.paddingLarge
            spacing: Theme.paddingSmall

            Item {
                width: parent.width
                height: Theme.iconSizeSmall
                HighlightImage {
                    id: heroIcon
                    width: Theme.iconSizeSmall
                    height: Theme.iconSizeSmall
                    sourceSize.width: Theme.iconSizeSmall
                    sourceSize.height: Theme.iconSizeSmall
                    source: card.iconSource
                    color: Theme.secondaryHighlightColor
                    highlighted: card.highlighted
                }
                Label {
                    anchors.left: heroIcon.right
                    anchors.leftMargin: Theme.paddingSmall
                    anchors.right: heroTime.left
                    anchors.rightMargin: Theme.paddingSmall
                    anchors.verticalCenter: parent.verticalCenter
                    truncationMode: TruncationMode.Fade
                    text: card.title
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                }
                Label {
                    id: heroTime
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Utils.measuredWhen(card.timestamp)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: card.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }

            Item {
                width: parent.width
                height: heroValue.height
                Label {
                    id: heroValue
                    text: Utils.formatValue(card.value)
                    // The regular face: the light heading face was too thin to read
                    // against a textured wallpaper.
                    font.pixelSize: Theme.fontSizeHuge
                    color: card.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    anchors.left: heroValue.right
                    anchors.leftMargin: Theme.paddingSmall
                    anchors.baseline: heroValue.baseline
                    text: card.unit
                    font.pixelSize: Theme.fontSizeMedium
                    color: card.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
                Label {
                    anchors.right: parent.right
                    anchors.baseline: heroValue.baseline
                    text: card.changeText
                    font.pixelSize: Theme.fontSizeSmall
                    color: card.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
            }

            Sparkline {
                width: parent.width
                height: Theme.itemSizeExtraSmall
                points: card.trend
                lineColor: Theme.highlightColor
            }
        }
    }

    // --- half-width card --------------------------------------------------------------
    Component {
        id: halfLayout
        Column {
            readonly property real titleNaturalHeight: Math.max(cardIcon.height, cardTitle.implicitHeight)

            width: card.width - 2 * Theme.paddingLarge
            spacing: Theme.paddingSmall

            // A long title ("Waist-to-height ratio") wraps instead of fading out half way.
            Item {
                width: parent.width
                height: Math.max(parent.titleNaturalHeight, card.titleHeight)

                HighlightImage {
                    id: cardIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.iconSizeSmall
                    height: Theme.iconSizeSmall
                    sourceSize.width: Theme.iconSizeSmall
                    sourceSize.height: Theme.iconSizeSmall
                    source: card.iconSource
                    color: Theme.secondaryHighlightColor
                    highlighted: card.highlighted
                }
                Label {
                    id: cardTitle
                    anchors.left: cardIcon.right
                    anchors.leftMargin: Theme.paddingSmall
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    truncationMode: TruncationMode.Elide
                    text: card.title
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                }
            }

            Row {
                width: parent.width
                spacing: Theme.paddingSmall
                Label {
                    id: cardValue
                    width: Math.min(implicitWidth, parent.width - (cardUnit.text !== "" ? cardUnit.width + parent.spacing : 0))
                    truncationMode: TruncationMode.Fade
                    text: card.isBP ? String(card.value) : Utils.formatValue(card.value)
                    font.pixelSize: Theme.fontSizeExtraLarge
                    color: card.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    id: cardUnit
                    anchors.baseline: cardValue.baseline
                    text: card.unit
                    font.pixelSize: Theme.fontSizeSmall
                    color: card.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }

            // Its reference band when it has one, otherwise when it was measured.
            StatusPill {
                text: card.bandLabel
                dotColor: card.bandColor
                maximumWidth: parent.width
                highlighted: card.highlighted
            }
            Label {
                visible: card.bandLabel === "" && card.timestamp !== ""
                width: parent.width
                truncationMode: TruncationMode.Fade
                text: Utils.measuredWhen(card.timestamp)
                font.pixelSize: Theme.fontSizeExtraSmall
                color: card.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            }
        }
    }

    // The module and profile are fixed for a card's lifetime: the dashboard builds new
    // cards when they change.
    Component.onCompleted: refresh()
}

// vim:et:ts=4:sw=4
