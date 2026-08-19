import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

GridItem {
    id: root

    property int profileId: -1
    property string metricName
    property string metricName2: ""
    property string title
    property string icon
    property bool grouped: false
    property var value
    property var unit
    property var clickThrough
    property var calculate
    property var invalidateSignal
    property string constraintColor: ""
    property string constraintLabel: ""

    // Displayed value, with binary floating point noise trimmed. A summed day of
    // water intake arrives as 1.7999999999999998.
    readonly property string displayValue: {
        // Summary tiles are a link to another page and carry no reading of their own.
        if (clickThrough) {
            return "";
        }
        if (value === undefined || value === null || value === "") {
            return "—";
        }
        // Blood pressure is already formatted as "120/80".
        return isNaN(value) ? String(value) : Utils.formatValue(value);
    }

    function updateConstraintColor() {
        constraintColor = "";
        constraintLabel = "";
        if (root.value === undefined || root.value === null || isNaN(root.value)) {
            return;
        }
        var name = root.metricName !== "" ? root.metricName : root.title;
        var match = DataManager.matchConstraint(name, root.value);
        if (match !== null) {
            constraintLabel = match.label;
            constraintColor = Utils.constraintColor(match.color);
        }
    }

    function refreshValue() {
        if (root.clickThrough) {
            root.value = '';
        }
        if (root.profileId >= 0) {
            if (root.calculate) {
                root.value = DataManager.calculateMetrics(root.profileId, root.calculate);
            }
            else if (root.metricName) {
                root.grouped = DataManager.getMetricGrouped(root.metricName);
                if (root.grouped) {
                    root.value = DataManager.getLatestDayLogValue(root.profileId, root.metricName);
                }
                else {
                    root.value = DataManager.getLatestLogValue(root.profileId, root.metricName);
                }
            }
        }
        updateConstraintColor();
    }

    function invalidateMetric(metricName) {
        // A dashboard card can be destroyed while a dialog is closing. Ignore a
        // late invalidation instead of dereferencing the destroyed QML object.
        if (!root || metricName === null) {
            return;
        }
        // Derived cards have no metric of their own but depend on other metrics,
        // so they refresh whenever anything changes.
        if (root.calculate || metricName === root.metricName || metricName === root.metricName2) {
            refreshValue();
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.paddingSmall
        color: highlighted ? Theme.highlightBackgroundColor : Theme.rgba(Theme.primaryColor, 0.05)
        radius: Theme.paddingMedium

        Column {
            anchors.centerIn: parent
            width: parent.width - Theme.paddingMedium
            spacing: 2

            // HighlightImage recolours the monochrome icon natively. This used to be
            // a per-card ShaderEffect on a layer, i.e. one FBO per dashboard tile.
            HighlightImage {
                source: root.icon
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.iconSizeMedium
                height: Theme.iconSizeMedium
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                opacity: highlighted ? 1.0 : 0.8
            }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                truncationMode: TruncationMode.Fade
                text: root.title
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 0

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.paddingSmall
                    Label {
                        // Bounded so an out-of-range reading fades rather than
                        // spilling out of the tile.
                        width: Math.min(implicitWidth, root.width - 2 * Theme.paddingMedium)
                        truncationMode: TruncationMode.Fade
                        text: root.displayValue
                        font.pixelSize: Theme.fontSizeLarge
                        color: root.constraintColor !== "" ? root.constraintColor : Theme.primaryColor
                    }
                    Label {
                        width: Math.min(implicitWidth, root.width / 3)
                        truncationMode: TruncationMode.Fade
                        text: root.unit ? root.unit : ''
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryColor
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Theme.paddingSmall
                        visible: root.value !== undefined && root.value !== null && root.value !== ''
                    }
                }

                Label {
                    width: root.width - 2 * Theme.paddingMedium
                    horizontalAlignment: Text.AlignHCenter
                    truncationMode: TruncationMode.Fade
                    text: root.constraintLabel
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: root.constraintColor !== "" ? root.constraintColor : Theme.secondaryColor
                    visible: root.constraintLabel !== ""
                }
            }
        }
    }

    onClicked: {
        if (root.profileId < 0) {
            return;
        }
        if (root.metricName2 !== "") {
            pageStack.animatorPush(Qt.resolvedUrl("../pages/MultiMetricDetails.qml"), {
                profileId: root.profileId,
                metricName1: root.metricName,
                metricName2: root.metricName2,
                invalidateSignal: root.invalidateSignal
            });
        }
        else if (root.metricName) {
            pageStack.animatorPush(Qt.resolvedUrl("../pages/MetricDetails.qml"), {
                profileId: root.profileId,
                grouped: root.grouped,
                metricName: root.metricName,
                metricUnit: root.unit,
                invalidateSignal: root.invalidateSignal
            });
        }
        else if (root.calculate) {
            // Derived metrics (BMI) previously had no destination at all, which left
            // the card inert and its reference bands unreachable.
            pageStack.animatorPush(Qt.resolvedUrl("../pages/CalcMetricDetails.qml"), {
                profileId: root.profileId,
                calculate: root.calculate,
                title: root.title,
                metricUnit: root.unit ? root.unit : "",
                invalidateSignal: root.invalidateSignal
            });
        }
        else if (root.clickThrough) {
            pageStack.animatorPush(Qt.resolvedUrl('../pages/' + root.clickThrough + ".qml"), {
                profileId: root.profileId
            });
        }
    }

    onMetricNameChanged: {
        if (root.metricName && root.unit == undefined) {
            root.unit = DataManager.getMetricUnit(root.metricName);
        }
    }

    onProfileIdChanged: refreshValue();

    Component.onCompleted: {
        if (root.invalidateSignal && root.invalidateSignal.connect) {
            root.invalidateSignal.connect(root.invalidateMetric);
        }
    }

    Component.onDestruction: {
        if (invalidateSignal && invalidateSignal.disconnect) {
            invalidateSignal.disconnect(invalidateMetric);
        }
    }
}

// vim:et:ts=4:sw=4
