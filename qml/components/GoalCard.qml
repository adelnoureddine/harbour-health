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
    readonly property string unit: module && module.unit ? module.unit : ""
    // Water is logged in litres, so its quick amounts are glasses.
    readonly property bool litres: unit === "L" || unit === "l"

    property real total: 0
    property var goal: null

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
        total = t === null ? 0 : t;
        goal = DataManager.getGoal(profileId, metricName);
    }

    function quickAdd(amount) {
        DataManager.addLog(profileId, metricName, amount, new Date(), "");
        refresh();
        saved();
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
                visible: card.litres
                //: Quick add on the water card; %1 is an amount in millilitres
                text: qsTr("Add %1 ml").arg(250)
                onClicked: card.quickAdd(0.25)
            }
            MenuItem {
                visible: card.litres
                text: qsTr("Add %1 ml").arg(500)
                onClicked: card.quickAdd(0.5)
            }
            MenuItem {
                text: card.litres ? qsTr("Other amount…") : qsTr("Add entry")
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
                    text: Utils.formatValue(card.total, Utils.metricDecimals(card.metricName))
                    font.pixelSize: Theme.fontSizeLarge
                    color: card.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: card.goal !== null
                    //: Under today's total in the ring, e.g. "of 2 L"
                    text: card.goal === null ? "" : qsTr("of %1 %2").arg(Utils.formatValue(card.goal)).arg(card.unit)
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
