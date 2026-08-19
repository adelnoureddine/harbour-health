import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/utils.js" as Utils

/*
 * Line chart for one or more metric histories.
 *
 * QtCharts is not available to Harbour applications, so this draws onto a plain
 * QtQuick Canvas. Reference bands from MetricConstraints are painted behind the
 * lines, which is what makes a reading legible at a glance.
 *
 * series: [{ points: [{t: <ms>, v: <number>}, ...], color: <color>, label: <string> }]
 * bands:  [{ minValue: <number|null>, maxValue: <number|null>, color: <string> }]
 */
Item {
    id: root

    property var series: []
    property var bands: []
    property string unit: ""
    property bool showAverage: true
    property string emptyText: qsTr("Not enough data yet")

    // Point nearest the finger while the chart is being touched, or null.
    property var highlightedPoint: null
    property int highlightedSeries: -1

    height: Theme.itemSizeHuge * 1.6

    readonly property real _leftGutter: Theme.fontSizeExtraSmall * 4
    readonly property real _rightGutter: Theme.paddingMedium
    readonly property real _topGutter: Theme.paddingMedium
    readonly property real _bottomGutter: Theme.fontSizeExtraSmall * 2

    readonly property real _plotX: _leftGutter
    readonly property real _plotY: _topGutter
    readonly property real _plotWidth: Math.max(1, width - _leftGutter - _rightGutter)
    readonly property real _plotHeight: Math.max(1, height - _topGutter - _bottomGutter)

    // Ambience changes swap every Theme colour; repainting on one of them is enough.
    readonly property color themeColorSentinel: Theme.primaryColor

    function pointCount() {
        var total = 0;
        for (var i = 0; i < series.length; i++) {
            if (series[i] && series[i].points) {
                total += series[i].points.length;
            }
        }
        return total;
    }

    /*
     * Value and time extent across every series, padded so lines never touch the
     * frame. A flat series (or a single reading) has no natural range, so it gets an
     * artificial one rather than dividing by zero.
     */
    function bounds() {
        var b = { xMin: 0, xMax: 1, yMin: 0, yMax: 1, valid: false };
        var first = true;

        for (var i = 0; i < series.length; i++) {
            var points = series[i] ? series[i].points : null;
            if (!points) {
                continue;
            }
            for (var j = 0; j < points.length; j++) {
                var p = points[j];
                if (p === null || p === undefined || isNaN(p.v) || isNaN(p.t)) {
                    continue;
                }
                if (first) {
                    b.xMin = b.xMax = p.t;
                    b.yMin = b.yMax = p.v;
                    first = false;
                } else {
                    if (p.t < b.xMin) b.xMin = p.t;
                    if (p.t > b.xMax) b.xMax = p.t;
                    if (p.v < b.yMin) b.yMin = p.v;
                    if (p.v > b.yMax) b.yMax = p.v;
                }
                b.valid = true;
            }
        }
        if (!b.valid) {
            return b;
        }

        if (b.xMax === b.xMin) {
            // A single reading: give it a day of room so it lands mid-chart.
            b.xMin -= 43200000;
            b.xMax += 43200000;
        }
        if (b.yMax === b.yMin) {
            var spread = Math.abs(b.yMax) * 0.1;
            if (spread < 0.5) {
                spread = 0.5;
            }
            b.yMin -= spread;
            b.yMax += spread;
        } else {
            var margin = (b.yMax - b.yMin) * 0.1;
            b.yMin -= margin;
            b.yMax += margin;
        }
        return b;
    }

    onSeriesChanged: canvas.requestPaint()
    onBandsChanged: canvas.requestPaint()
    onThemeColorSentinelChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Immediate

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);

            var b = root.bounds();
            if (!b.valid) {
                return;
            }

            var px = root._plotX;
            var py = root._plotY;
            var pw = root._plotWidth;
            var ph = root._plotHeight;

            function xAt(t) {
                return px + ((t - b.xMin) / (b.xMax - b.xMin)) * pw;
            }
            function yAt(v) {
                return py + ph - ((v - b.yMin) / (b.yMax - b.yMin)) * ph;
            }

            // --- reference bands -------------------------------------------------
            for (var i = 0; i < root.bands.length; i++) {
                var band = root.bands[i];
                var colorName = Utils.constraintColor(band.color);
                if (colorName === "") {
                    continue;
                }
                // An open-ended band is clamped to the visible range.
                var top = (band.maxValue === null || band.maxValue === undefined)
                        ? b.yMax : Math.min(band.maxValue, b.yMax);
                var bottom = (band.minValue === null || band.minValue === undefined)
                        ? b.yMin : Math.max(band.minValue, b.yMin);
                if (top <= bottom) {
                    continue;
                }
                ctx.fillStyle = Theme.rgba(colorName, 0.16);
                ctx.fillRect(px, yAt(top), pw, yAt(bottom) - yAt(top));
            }

            // --- gridlines and value labels --------------------------------------
            ctx.font = Math.round(Theme.fontSizeExtraSmall) + "px sans-serif";
            ctx.textAlign = "right";
            ctx.textBaseline = "middle";
            ctx.lineWidth = 1;
            ctx.strokeStyle = Theme.rgba(Theme.primaryColor, 0.15);
            ctx.fillStyle = Theme.secondaryColor;

            var gridLines = 4;
            for (var g = 0; g <= gridLines; g++) {
                var value = b.yMin + (b.yMax - b.yMin) * (g / gridLines);
                var y = yAt(value);
                ctx.beginPath();
                ctx.moveTo(px, y);
                ctx.lineTo(px + pw, y);
                ctx.stroke();
                ctx.fillText(Utils.formatValue(value, 1), px - Theme.paddingSmall, y);
            }

            // --- date labels -----------------------------------------------------
            ctx.textBaseline = "top";
            var dateLabels = pw > Theme.itemSizeHuge * 3 ? 3 : 2;
            for (var d = 0; d <= dateLabels; d++) {
                var t = b.xMin + (b.xMax - b.xMin) * (d / dateLabels);
                var lx = xAt(t);
                if (d === 0) {
                    ctx.textAlign = "left";
                } else if (d === dateLabels) {
                    ctx.textAlign = "right";
                } else {
                    ctx.textAlign = "center";
                }
                ctx.fillText(Qt.formatDate(new Date(t), "d MMM"), lx, py + ph + Theme.paddingSmall);
            }

            // --- series ----------------------------------------------------------
            for (var s = 0; s < root.series.length; s++) {
                var set = root.series[s];
                if (!set || !set.points || set.points.length === 0) {
                    continue;
                }
                var lineColor = set.color ? set.color : Theme.highlightColor;

                ctx.strokeStyle = lineColor;
                ctx.lineWidth = 2;
                ctx.lineJoin = "round";
                ctx.beginPath();
                for (var k = 0; k < set.points.length; k++) {
                    var pt = set.points[k];
                    if (k === 0) {
                        ctx.moveTo(xAt(pt.t), yAt(pt.v));
                    } else {
                        ctx.lineTo(xAt(pt.t), yAt(pt.v));
                    }
                }
                ctx.stroke();

                // Individual readings are only marked while they stay distinguishable.
                if (set.points.length <= 60) {
                    ctx.fillStyle = lineColor;
                    for (var m = 0; m < set.points.length; m++) {
                        ctx.beginPath();
                        ctx.arc(xAt(set.points[m].t), yAt(set.points[m].v), 3, 0, 2 * Math.PI);
                        ctx.fill();
                    }
                }

                // --- average ------------------------------------------------------
                if (root.showAverage && set.points.length > 1) {
                    var total = 0;
                    for (var a = 0; a < set.points.length; a++) {
                        total += set.points[a].v;
                    }
                    var avgY = yAt(total / set.points.length);
                    // Drawn as explicit segments: setLineDash is not dependable here.
                    ctx.strokeStyle = Theme.rgba(lineColor, 0.5);
                    ctx.lineWidth = 1;
                    ctx.beginPath();
                    for (var dash = px; dash < px + pw; dash += 12) {
                        ctx.moveTo(dash, avgY);
                        ctx.lineTo(Math.min(dash + 6, px + pw), avgY);
                    }
                    ctx.stroke();
                }
            }

            // --- touch marker ----------------------------------------------------
            if (root.highlightedPoint !== null) {
                var hx = xAt(root.highlightedPoint.t);
                ctx.strokeStyle = Theme.rgba(Theme.highlightColor, 0.6);
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.moveTo(hx, py);
                ctx.lineTo(hx, py + ph);
                ctx.stroke();

                ctx.fillStyle = Theme.highlightColor;
                ctx.beginPath();
                ctx.arc(hx, yAt(root.highlightedPoint.v), 5, 0, 2 * Math.PI);
                ctx.fill();
            }
        }
    }

    // Drag anywhere across the plot to read individual values off the line.
    MouseArea {
        anchors.fill: parent
        enabled: root.pointCount() > 0

        function pick(mouseX) {
            var b = root.bounds();
            if (!b.valid) {
                return;
            }
            var t = b.xMin + ((mouseX - root._plotX) / root._plotWidth) * (b.xMax - b.xMin);
            var best = null;
            var bestSeries = -1;
            var bestDistance = Number.MAX_VALUE;
            for (var s = 0; s < root.series.length; s++) {
                var points = root.series[s] ? root.series[s].points : null;
                if (!points) {
                    continue;
                }
                for (var i = 0; i < points.length; i++) {
                    var distance = Math.abs(points[i].t - t);
                    if (distance < bestDistance) {
                        bestDistance = distance;
                        best = points[i];
                        bestSeries = s;
                    }
                }
            }
            root.highlightedPoint = best;
            root.highlightedSeries = bestSeries;
            canvas.requestPaint();
        }

        onPressed: pick(mouse.x)
        onPositionChanged: pick(mouse.x)
        onReleased: {
            root.highlightedPoint = null;
            root.highlightedSeries = -1;
            canvas.requestPaint();
        }
        onCanceled: {
            root.highlightedPoint = null;
            root.highlightedSeries = -1;
            canvas.requestPaint();
        }
    }

    // Readout for the touched point, floating over the top of the plot.
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: readout.width + 2 * Theme.paddingMedium
        height: readout.height + Theme.paddingSmall
        radius: Theme.paddingSmall
        color: Theme.rgba(Theme.highlightBackgroundColor, 0.9)
        visible: root.highlightedPoint !== null

        Label {
            id: readout
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.primaryColor
            text: root.highlightedPoint === null ? ""
                  : Utils.formatValue(root.highlightedPoint.v) + " " + root.unit + "  ·  "
                    + Qt.formatDate(new Date(root.highlightedPoint.t), Qt.DefaultLocaleShortDate)
        }
    }

    Label {
        anchors.centerIn: parent
        text: root.emptyText
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.secondaryColor
        visible: root.pointCount() === 0
    }
}

// vim:et:ts=4:sw=4
