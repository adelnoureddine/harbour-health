import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

/*
 * Dashboard card for a metric totalled per day (water, calories): today's total as
 * a ring against the daily goal. The dashboard only shows; adding goes through the
 * long-press menu (quick amounts, other amount, history, the goal itself).
 */
ListItem {
    id: card

    property int profileId: -1
    property var module: ({})
    property real halfWidth: 0
    property real fullWidth: 0

    // Emitted after this card saved something itself, so the dashboard knows its
    // data is current and need not reload when shown again.
    signal saved()

    readonly property string moduleName: module && module.name ? module.name : ""
    readonly property string metricName: module && module.uses ? module.uses : ""
    // The stored unit (Metrics.unit), passed on to the pages; the card shows shownUnit.
    readonly property string unit: module && module.unit ? module.unit : ""
    // Water has quick amounts: glasses.
    readonly property bool water: metricName === DataManager.METRIC_WATER

    // Today's total and the goal as shown, in shownUnit (the unit chosen in Units). The
    // goal is null when there is none or it is switched off.
    property real total: 0
    property var goal: null
    property string shownUnit: unit
    property int decimals: 2
    // The quick-add glass in the unit shown (DataManager.waterGlass).
    property var glass: ({ litres: 0.25, amount: 250, unit: "ml" })

    // Half width, unless the dashboard widens it because it would sit alone on a row.
    readonly property bool wantsWide: false
    property bool wide: false
    width: wide ? fullWidth : halfWidth
    readonly property real naturalHeight: column.height + 2 * Theme.paddingLarge
    // Set by the dashboard so two cards sharing a row are the same height.
    property real rowHeight: 0
    contentHeight: Math.max(naturalHeight, rowHeight)
    highlightedColor: "transparent"

    // The title takes one line or two (titleNaturalHeight). The dashboard sets
    // titleHeight to the taller title of the row, so the two rings stay level.
    readonly property real titleNaturalHeight: Math.max(icon.height, titleLabel.implicitHeight)
    property real titleHeight: 0

    function refresh() {
        if (profileId < 0 || metricName === "") {
            return;
        }
        var t = DataManager.getTodayTotal(profileId, metricName);
        var g = DataManager.getActiveGoal(profileId, metricName);
        shownUnit = DataManager.displayUnit(metricName, unit);
        decimals = DataManager.displayDecimals(metricName, Utils.metricDecimals(metricName));
        glass = DataManager.waterGlass();
        total = DataManager.toDisplay(metricName, t === null ? 0 : t);
        goal = g === null ? null : DataManager.toDisplay(metricName, g);
    }

    // `glasses` of water, in litres whatever unit is shown.
    function quickAdd(glasses) {
        DataManager.addLog(profileId, metricName, glasses * glass.litres, new Date(), "");
        refresh();
        saved();
    }

    function quickAddText(glasses) {
        var amount = glasses * card.glass.amount;
        //: Quick add on the water card; %1 is an amount in millilitres
        return card.glass.unit === "ml" ? qsTr("Add %1 ml").arg(amount)
                                        //: Quick add on the water card; %1 is an amount in US fluid ounces
                                        : qsTr("Add %1 fl oz").arg(amount);
    }

    function openAdd() {
        pageStack.animatorPush(Qt.resolvedUrl("../pages/addEntryMetric.qml"), {
            profileId: card.profileId,
            metricName: card.metricName,
            metricUnit: card.unit,
            lockMetric: true
        });
    }

    function openDetails() {
        pageStack.animatorPush(Qt.resolvedUrl("../pages/MetricDetails.qml"), {
            profileId: card.profileId,
            grouped: true,
            metricName: card.metricName,
            metricUnit: card.unit
        });
    }

    onClicked: openDetails()

    menu: Component {
        ContextMenu {
            MenuItem {
                visible: card.water
                text: card.quickAddText(1)
                onClicked: card.quickAdd(1)
            }
            MenuItem {
                visible: card.water
                text: card.quickAddText(2)
                onClicked: card.quickAdd(2)
            }
            MenuItem {
                text: card.water ? qsTr("Other amount…") : qsTr("Add entry")
                onClicked: card.openAdd()
            }
            MenuItem {
                text: qsTr("History")
                onClicked: card.openDetails()
            }
            MenuItem {
                text: qsTr("Daily goal")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("../pages/setGoal.qml"), {
                    profileId: card.profileId,
                    metricName: card.metricName,
                    metricUnit: card.unit
                })
            }
        }
    }

    CardBackground {
        anchors.fill: parent
        highlighted: card.highlighted
    }

    Column {
        id: column
        x: Theme.paddingLarge
        y: Theme.paddingLarge
        width: parent.width - 2 * Theme.paddingLarge
        spacing: Theme.paddingMedium

        // A long title ("Calories eaten today") wraps instead of fading out half way.
        Item {
            width: parent.width
            height: Math.max(card.titleNaturalHeight, card.titleHeight)

            HighlightImage {
                id: icon
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.iconSizeSmall
                height: Theme.iconSizeSmall
                sourceSize.width: Theme.iconSizeSmall
                sourceSize.height: Theme.iconSizeSmall
                source: Qt.resolvedUrl("../icons/" + Utils.moduleIcon(card.moduleName, card.module.icon))
                color: Theme.secondaryHighlightColor
                highlighted: card.highlighted
            }
            Label {
                id: titleLabel
                anchors.left: icon.right
                anchors.leftMargin: Theme.paddingSmall
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                wrapMode: Text.Wrap
                maximumLineCount: 2
                truncationMode: TruncationMode.Elide
                //: Dashboard card title for a daily total, e.g. "Water today"
                text: qsTr("%1 today").arg(Utils.moduleDisplayName(card.moduleName))
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
            }
        }

        Item {
            width: parent.width
            height: ring.height

            ProgressCircle {
                id: ring
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeExtraLarge
                height: width
                value: card.goal > 0 ? Math.min(1, card.total / card.goal) : 0
                progressColor: Theme.highlightColor
                backgroundColor: Theme.rgba(Theme.primaryColor, 0.25)
            }

            Column {
                anchors.centerIn: ring
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Utils.formatValue(card.total, card.decimals)
                    font.pixelSize: Theme.fontSizeLarge
                    color: card.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                // Without a goal (switched off): the unit alone under the total.
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: card.goal === null && card.shownUnit !== ""
                    text: card.shownUnit
                    font.pixelSize: Theme.fontSizeTiny
                    color: card.highlighted ? Theme.secondaryHighlightColor : Theme.primaryColor
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: card.goal !== null
                    //: Under today's total in the ring, e.g. "of 2 L"
                    text: card.goal === null ? "" : qsTr("of %1 %2").arg(Utils.formatValue(card.goal, card.decimals)).arg(card.shownUnit)
                    font.pixelSize: Theme.fontSizeTiny
                    color: card.highlighted ? Theme.secondaryHighlightColor : Theme.primaryColor
                }
            }
        }
    }

    // Later changes arrive through refresh() calls from the dashboard.
    Component.onCompleted: refresh()
}

// vim:et:ts=4:sw=4
