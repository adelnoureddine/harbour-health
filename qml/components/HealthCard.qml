import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

GridItem {
    id: root
    
    property int profileId: -1
    property string metricName
    property string title
    property string icon
    property bool grouped: false
    property var value
    property var unit
    property var clickThrough
    property var calculate
    property var invalidateSignal

    function refreshValue() {
        print("MetricCard " + root.metricName + ": refreshValue is called for profile " + root.profileId);
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
                    print("MetricCard " + root.metricName + ": value is now " + root.value + " for profile " + root.profileId);
                }
                else {
                    root.value = DataManager.getLatestLogValue(root.profileId, root.metricName);
                    print("MetricCard " + root.metricName + ": value is now " + root.value + " for profile " + root.profileId);
                }
            }
        }
    }

    function invalidateMetric(metricName) {
        if (metricName == root.metricName) {
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
            spacing: Theme.paddingSmall

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

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingSmall
                
                Label {
                    text: root.value != undefined ? root.value : '?'
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.primaryColor
                }
                
                Label {
                    text: root.unit ? root.unit : ''
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.paddingSmall
                }
            }
        }
    }

    onClicked: {
        if (root.profileId >= 0 && root.metricName) {
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
                profileId: mainPage.profileId
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
        if (root.invalidateSignal) {
            root.invalidateSignal.connect(root.invalidateMetric);
        }
    }
}

// vim:et:ts=4:sw=4
