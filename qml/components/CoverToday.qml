import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

/*
 * The day's to-do list on the cover (Cover page settings, "Today"): how much is left,
 * then the open items with the amount still to go. Shared with the settings preview.
 */
Column {
    id: root

    property int profileId: -1
    // Open items the cover has room for; the rest are counted.
    property int maxRows: 4

    property var openItems: []
    property int total: 0
    // Whether water is on the list: the cover then offers to add a glass.
    property bool hasWater: false

    function refresh() {
        if (profileId < 0) {
            openItems = [];
            total = 0;
            hasWater = false;
            return;
        }
        var plan = DataManager.getTodayPlan(profileId);
        total = plan.items.length;
        // The open items come first in the plan.
        openItems = plan.items.slice(0, plan.left);
        hasWater = plan.items.some(function (item) {
            return item.kind === "goal" && item.metricName === DataManager.METRIC_WATER;
        });
    }

    spacing: Theme.paddingSmall

    Label {
        width: parent.width
        wrapMode: Text.Wrap
        text: root.total === 0 ? qsTr("No daily goals yet")
              : root.openItems.length === 0 ? qsTr("All done for today")
              //: Cover: things still to do today
              : qsTr("%n left today", "", root.openItems.length)
        font.pixelSize: root.total === 0 ? Theme.fontSizeSmall : Theme.fontSizeLarge
        color: Theme.primaryColor
    }

    Repeater {
        model: root.openItems.slice(0, root.maxRows)

        delegate: Row {
            width: root.width
            spacing: Theme.paddingSmall

            // An open box: these are still to do.
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(Theme.paddingMedium)
                height: width
                radius: width / 2
                color: "transparent"
                border.width: Math.max(1, Math.round(Theme.pixelRatio))
                border.color: Theme.highlightColor
            }

            Label {
                id: itemTitle
                width: parent.width - Theme.paddingMedium - parent.spacing
                       - (remaining.text !== "" ? remaining.width + parent.spacing : 0)
                truncationMode: TruncationMode.Fade
                text: Utils.todayItemTitle(modelData)
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.primaryColor
            }

            Label {
                id: remaining
                visible: text !== ""
                width: Math.min(implicitWidth, root.width / 2)
                truncationMode: TruncationMode.Fade
                text: Utils.todayItemRemaining(modelData)
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.highlightColor
            }
        }
    }

    Label {
        width: parent.width
        visible: root.openItems.length > root.maxRows
        truncationMode: TruncationMode.Fade
        //: Cover: open items of the Today list that did not fit
        text: qsTr("+%n more", "", root.openItems.length - root.maxRows)
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
    }
}

// vim:et:ts=4:sw=4
