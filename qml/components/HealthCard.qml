import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

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

    function updateConstraintColor() {
        if (root.value !== undefined && root.value !== null && root.value !== '?') {
            var name = root.metricName !== "" ? root.metricName : root.title;
            var constraints = DataManager.getConstraintsForMetric(name);
            var val = parseFloat(root.value);
            constraintColor = "";
            constraintLabel = "";
            for (var i = 0; i < constraints.length; i++) {
                var c = constraints[i];
                var min = c.minValue;
                var max = c.maxValue;
                if ((min === null || val >= min) && (max === null || val < max)) {
                    constraintLabel = c.label || "";
                    var col = c.color;
                    if (col === "green") constraintColor = "#2ecc71";
                    else if (col === "orange") constraintColor = "#e67e22";
                    else if (col === "red") constraintColor = "#e74c3c";
                    else if (col === "blue") constraintColor = "#3498db";
                    break;
                }
            }
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
        if (root && metricName !== null && metricName === root.metricName) {
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
            spacing: 2

            Image {
                source: root.icon
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.iconSizeMedium
                height: Theme.iconSizeMedium
                fillMode: Image.PreserveAspectFit
                smooth: true
                opacity: highlighted ? 1.0 : 0.8
                layer.enabled: true
                layer.effect: ShaderEffect {
                    fragmentShader: "
                        uniform lowp sampler2D source;
                        uniform lowp float qt_Opacity;
                        varying highp vec2 qt_TexCoord0;
                        void main() {
                            lowp vec4 tex = texture2D(source, qt_TexCoord0);
                            gl_FragColor = vec4(tex.a, tex.a, tex.a, tex.a) * qt_Opacity;
                        }"
                }
            }

            Label {
                text: root.title
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 0

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.paddingSmall
                    Label {
                        text: root.value != undefined ? root.value : '?'
                        font.pixelSize: Theme.fontSizeLarge
                        color: root.constraintColor !== "" ? root.constraintColor : Theme.primaryColor
                    }
                    Label {
                        text: root.unit ? root.unit : ''
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryColor
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Theme.paddingSmall
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.constraintLabel
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: root.constraintColor !== "" ? root.constraintColor : Theme.secondaryColor
                    visible: root.constraintLabel !== ""
                }
            }
        }
    }

    onClicked: {
        if (root.profileId >= 0 && root.metricName2 !== "") {
            pageStack.animatorPush(Qt.resolvedUrl("../pages/MultiMetricDetails.qml"), {
                profileId: root.profileId,
                metricName1: root.metricName,
                metricName2: root.metricName2,
                invalidateSignal: root.invalidateSignal
            });
        }
        else if (root.profileId >= 0 && root.metricName) {
            pageStack.animatorPush(Qt.resolvedUrl("../pages/MetricDetails.qml"), {
                profileId: root.profileId,
                grouped: root.grouped,
                metricName: root.metricName,
                metricUnit: root.unit,
                invalidateSignal: root.invalidateSignal
            });
        }
        else if (root.profileId >= 0 && root.clickThrough) {
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
