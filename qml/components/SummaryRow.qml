import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

/*
 * Dashboard row for a module that is a page of its own (conditions, vaccines,
 * meditation, cycle). It used to be a tile with only an icon and a name; the second
 * line now says where things stand.
 */
ListItem {
    id: row

    property int profileId: -1
    property var module: ({})
    property real fullWidth: 0

    readonly property string moduleName: module && module.name ? module.name : ""
    property string status: ""

    // Always a whole row; on the dashboard it sits among the cards, so it is one too.
    readonly property bool wantsWide: true
    property bool wide: true
    width: fullWidth
    readonly property real naturalHeight: Theme.itemSizeMedium
    property real rowHeight: 0
    contentHeight: naturalHeight
    highlightedColor: "transparent"

    function conditionStatus() {
        var s = DataManager.getConditionSummary(profileId);
        if (s.active > 0) {
            //: Number of ongoing health conditions on the dashboard
            return qsTr("%n active", "", s.active) + (s.latestActive ? " · " + s.latestActive : "");
        }
        return s.total > 0 ? qsTr("None active") : qsTr("Nothing recorded yet");
    }

    function vaccineStatus() {
        var last = DataManager.getLatestInjection(profileId);
        //: Latest vaccine injection: %1 is the vaccine, %2 the date
        return last ? qsTr("Last: %1, %2").arg(last.name).arg(Utils.formatDate(last.date))
                    : qsTr("Nothing recorded yet");
    }

    function meditationStatus() {
        var last = DataManager.getLatestMeditation(profileId);
        if (!last) {
            return qsTr("No session yet");
        }
        //: Length of the latest meditation session in minutes
        return Utils.relativeTime(last.date, false) + " · "
                + qsTr("%n min", "", Math.max(1, Utils.wholeMinutes(last.duration)));
    }

    function cycleStatus() {
        var cycle = DataManager.getCycleStatus(profileId);
        if (cycle.last === null) {
            return qsTr("No cycle recorded");
        }
        if (!cycle.open) {
            return qsTr("Last cycle started %1").arg(Utils.formatDate(cycle.last.startDate));
        }
        var text = qsTr("Day %1").arg(cycle.dayOfCycle);
        if (cycle.averageLength !== null && cycle.dayOfCycle > 0) {
            var left = cycle.averageLength - cycle.dayOfCycle + 1;
            text += " · " + (left > 0 ? qsTr("next in about %n day(s)", "", left) : qsTr("next one due"));
        }
        return text;
    }

    function refresh() {
        if (profileId < 0) {
            return;
        }
        switch (moduleName) {
        case DataManager.MODULE_CONDITION:    status = conditionStatus(); break;
        case DataManager.MODULE_VACCINATION:  status = vaccineStatus(); break;
        case DataManager.MODULE_MEDITATION:   status = meditationStatus(); break;
        case DataManager.MODULE_MENSTRUATION: status = cycleStatus(); break;
        default:                              status = "";
        }
    }

    onClicked: pageStack.animatorPush(Qt.resolvedUrl("../pages/" + module.uses + ".qml"), {
        profileId: row.profileId
    })

    CardBackground {
        anchors.fill: parent
        highlighted: row.highlighted
    }

    HighlightImage {
        id: icon
        anchors.left: parent.left
        anchors.leftMargin: Theme.paddingLarge
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.iconSizeMedium
        height: Theme.iconSizeMedium
        sourceSize.width: Theme.iconSizeMedium
        sourceSize.height: Theme.iconSizeMedium
        source: Qt.resolvedUrl("../icons/" + Utils.moduleIcon(row.moduleName, row.module.icon))
        color: Theme.secondaryHighlightColor
        highlighted: row.highlighted
    }

    Column {
        anchors.left: icon.right
        anchors.leftMargin: Theme.paddingLarge
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingLarge
        anchors.verticalCenter: parent.verticalCenter

        Label {
            width: parent.width
            truncationMode: TruncationMode.Fade
            text: Utils.moduleDisplayName(row.moduleName)
            color: row.highlighted ? Theme.highlightColor : Theme.primaryColor
        }
        Label {
            width: parent.width
            visible: text !== ""
            truncationMode: TruncationMode.Fade
            text: row.status
            font.pixelSize: Theme.fontSizeExtraSmall
            color: row.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        }
    }

    // Later changes arrive through refresh() calls from the dashboard.
    Component.onCompleted: refresh()
}

// vim:et:ts=4:sw=4
