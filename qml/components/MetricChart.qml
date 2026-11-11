import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/utils.js" as Utils

/*
 * Line chart for one or more metric histories, or a bar chart for daily totals.
 *
 * QtCharts is not available to Harbour applications, so this draws onto a plain
 * QtQuick Canvas. Reference bands from MetricConstraints are painted behind the
 * lines, which is what makes a reading legible at a glance.
 *
 * series: [{ points: [{t: <ms>, v: <number>}, ...], color: <color>, label: <string> }]
 * bands:  [{ minValue: <number|null>, maxValue: <number|null>, color: <string> }]
 *
 * With `bars`, every point is one period -- a day, a week or a month (`bucket`) that
 * starts at t -- drawn as a bar from zero. Readings stay lines: a bar per reading would
 * say they add up, which only daily totals do.
 *
 * goalValue draws the line to reach (a daily goal, a weight target), named by goalText.
 * rangeStart and rangeEnd (ms) are the period the page asked for: the time axis then
 * spans that period, where it used to shrink to the data, so "Month" with three
 * readings from last week looked the same as "Week".
 */
Item {
    id: root

    property var series: []
    property var bands: []
    property string unit: ""
    property bool showAverage: true
    property string emptyText: qsTr("Not enough data yet")
    // Decimals on the value axis. Ratios such as waist-to-height (0.47) need two.
    property int decimals: 1
    // Bars for daily totals; "day", "week" or "month" is how long each bar's period is.
    property bool bars: false
    property string bucket: "day"
    // The dashed average when the page has it from the database. Weekly bars are each
    // an average of their days, and the mean of those is not the average day.
    property var averageValue: null
    // The value to reach, drawn as a long-dashed line across the plot; null for none.
    property var goalValue: null
    property string goalText: ""
    // The period shown, in ms since the epoch; null to span the data (the "All" range).
    property var rangeStart: null
    property var rangeEnd: null

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

    // Length of one bar's period. A month is its average length: the bars are drawn
    // narrower than their period, so the shorter and longer months never overlap.
    readonly property real _bucketMs: bucket === "week" ? 7 * 86400000
                                    : bucket === "month" ? 30.44 * 86400000 : 86400000

    // Where a point is drawn: a bar sits in the middle of its period, a reading at t.
    function _cx(t) {
        return bars ? t + _bucketMs / 2 : t;
    }

    // The touched point's date: its day, "Week of 3 Mar" or "March 2026".
    function periodText(t) {
        var d = new Date(t);
        if (bucket === "week") {
            //: Chart readout for a weekly bar; %1 is the week's first day, e.g. "3 Mar"
            return qsTr("Week of %1").arg(Utils.shortDate(d));
        }
        if (bucket === "month") {
            return d.toLocaleDateString(Qt.locale(), "MMMM yyyy");
        }
        return Utils.formatDate(d);
    }

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
     *
     * Bars start at zero, and reach to the end of the last period so the last bar is
     * whole; there is nothing to pad below them.
     */
    function bounds(seriesList, precision, asBars, bucketMs, goal, rangeStart, rangeEnd) {
        var b = { xMin: 0, xMax: 1, yMin: 0, yMax: 1, valid: false, single: false, onlyT: 0 };
        var first = true;

        for (var i = 0; i < seriesList.length; i++) {
            var points = seriesList[i] ? seriesList[i].points : null;
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

        var ranged = rangeStart !== null && rangeStart !== undefined && !isNaN(rangeStart)
                && rangeEnd !== null && rangeEnd !== undefined && !isNaN(rangeEnd);
        // Everything at one moment and no period to place it in: one date label, in the
        // middle. (It used to get one at each end, so a first day of water read
        // "10 Nov10 Nov".)
        b.single = b.xMax === b.xMin && !ranged;
        b.onlyT = b.xMin;
        // The line to reach is always on the plot, however far the readings are from it.
        if (goal !== null && goal !== undefined && !isNaN(goal)) {
            if (goal < b.yMin) b.yMin = goal;
            if (goal > b.yMax) b.yMax = goal;
        }

        if (asBars) {
            b.xMax += bucketMs;
            if (ranged) {
                b.xMin = Math.min(b.xMin, rangeStart);
                b.xMax = Math.max(b.xMax, rangeEnd);
            }
            b.yMin = Math.min(0, b.yMin);
            if (b.yMax <= b.yMin) {
                // Nothing but zeros: still an axis to draw them against.
                b.yMax = b.yMin + 10 * Math.pow(10, -precision);
            } else {
                // A little room only: rounding the axis up adds the rest.
                b.yMax += (b.yMax - b.yMin) * 0.05;
            }
            return roundAxis(b, precision);
        }

        if (ranged) {
            b.xMin = Math.min(b.xMin, rangeStart);
            b.xMax = Math.max(b.xMax, rangeEnd);
        }
        if (b.xMax === b.xMin) {
            // A single reading: give it a day of room so it lands mid-chart.
            b.xMin -= 43200000;
            b.xMax += 43200000;
        }
        if (b.yMax === b.yMin) {
            // The minimum room scales with the precision shown: 0.5 at one decimal,
            // 0.05 at two, so a flat ratio series (0.47) gets an axis of 0.42 to 0.52
            // rather than one running from below zero to nearly one.
            var minSpread = 5 * Math.pow(10, -precision);
            var spread = Math.abs(b.yMax) * 0.1;
            if (spread < minSpread) {
                spread = minSpread;
            }
            b.yMin -= spread;
            b.yMax += spread;
        } else {
            var margin = (b.yMax - b.yMin) * 0.1;
            b.yMin -= margin;
            b.yMax += margin;
        }
        return roundAxis(b, precision);
    }

    // At most this many gaps between the value axis's grid lines.
    readonly property int _maxGridIntervals: 5

    /*
     * Widens the value range to a round step (1, 2 or 5 times a power of ten, never
     * finer than the decimals shown) and records the grid lines: b.step, and b.firstTick
     * and b.ticks, the lines being (firstTick + i) * step for i from 0 to ticks.
     *
     * The grid used to divide the padded range in four whatever it was: lines at 80.3,
     * 82.3, 84.3, and on a narrow range two of them rounding to the same label
     * (waist-to-height 0.525 and 0.534 both "0.53").
     */
    function roundAxis(b, precision) {
        var minStep = Math.pow(10, -precision);
        var rough = (b.yMax - b.yMin) / _maxGridIntervals;
        var exponent = Math.floor(Math.log(Math.max(rough, minStep)) / Math.LN10);
        var multipliers = [1, 2, 5];
        // Each pass goes a power of ten up; a handful always finds a step that fits.
        for (var pass = 0; pass < 20; pass++, exponent++) {
            for (var m = 0; m < multipliers.length; m++) {
                var step = multipliers[m] * Math.pow(10, exponent);
                if (step < minStep * 0.999) {
                    continue;
                }
                // The small allowances keep a value that is already on a line from
                // being pushed out a step by floating point.
                var low = Math.floor(b.yMin / step + 1e-9);
                var high = Math.ceil(b.yMax / step - 1e-9);
                if (high - low <= _maxGridIntervals) {
                    b.step = step;
                    b.firstTick = low;
                    b.ticks = Math.max(1, high - low);
                    b.yMin = low * step;
                    b.yMax = (low + b.ticks) * step;
                    return b;
                }
            }
        }
        return b;
    }

    // Computed once per data change. The touch handler used to rescan every point for
    // the extent on each finger movement.
    readonly property var _bounds: bounds(series, decimals, bars, _bucketMs, goalValue, rangeStart, rangeEnd)

    function xAt(t) {
        return _plotX + ((t - _bounds.xMin) / (_bounds.xMax - _bounds.xMin)) * _plotWidth;
    }

    function yAt(v) {
        return _plotY + _plotHeight - ((v - _bounds.yMin) / (_bounds.yMax - _bounds.yMin)) * _plotHeight;
    }

    /*
     * The date labels under the plot, [{text, x, align}]: the first and last at the
     * plot's edges, evenly spaced between, as many as fit up to maxIntervals + 1.
     *
     * Over a year the full date ("11 Nov 2025") is too wide for three across a phone
     * and they ran into each other. Labels are measured first: the month and year
     * ("Nov 2025") are tried before a label is dropped. ctx must have the label font.
     */
    function dateLabels(ctx, start, span, maxIntervals, longSpan) {
        var formats = longSpan ? [Formatter.DateMedium, "MMM yyyy"] : [Formatter.DateMediumWithoutYear];
        var labels = [];
        for (var n = maxIntervals; n >= 1; n--) {
            for (var f = 0; f < formats.length; f++) {
                labels = [];
                for (var d = 0; d <= n; d++) {
                    var t = start + span * (d / n);
                    var date = new Date(t);
                    // Locale order rather than a fixed "d MMM", with the year once the
                    // window is long enough for "3 Jan" to be ambiguous.
                    var text = typeof formats[f] === "string" ? date.toLocaleDateString(Qt.locale(), formats[f])
                                                              : Format.formatDate(date, formats[f]);
                    var textWidth = ctx.measureText(text).width;
                    var x = xAt(_cx(t));
                    var align = d === 0 ? "left" : (d === n ? "right" : "center");
                    var left = align === "left" ? x : (align === "right" ? x - textWidth : x - textWidth / 2);
                    labels.push({ text: text, x: x, align: align, left: left, right: left + textWidth });
                }
                var fits = true;
                for (var i = 1; i < labels.length && fits; i++) {
                    fits = labels[i].left - labels[i - 1].right >= Theme.paddingLarge;
                }
                if (fits) {
                    return labels;
                }
            }
        }
        // Nothing fitted: the last try, the two ends in the shortest format.
        return labels;
    }

    onSeriesChanged: canvas.requestPaint()
    onBandsChanged: canvas.requestPaint()
    onBarsChanged: canvas.requestPaint()
    onBucketChanged: canvas.requestPaint()
    onAverageValueChanged: canvas.requestPaint()
    onGoalValueChanged: canvas.requestPaint()
    onGoalTextChanged: canvas.requestPaint()
    onRangeStartChanged: canvas.requestPaint()
    onRangeEndChanged: canvas.requestPaint()
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

            var b = root._bounds;
            if (!b.valid) {
                return;
            }

            var px = root._plotX;
            var py = root._plotY;
            var pw = root._plotWidth;
            var ph = root._plotHeight;
            var xAt = root.xAt;
            var yAt = root.yAt;

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
            // The system font: "sans-serif" was whatever the canvas fell back to.
            ctx.font = Math.round(Theme.fontSizeExtraSmall) + "px '" + Theme.fontFamily + "'";
            ctx.textAlign = "right";
            ctx.textBaseline = "middle";
            ctx.lineWidth = 1;
            ctx.strokeStyle = Theme.rgba(Theme.primaryColor, 0.15);
            ctx.fillStyle = Theme.secondaryColor;

            for (var g = 0; g <= b.ticks; g++) {
                var value = (b.firstTick + g) * b.step;
                var y = yAt(value);
                ctx.beginPath();
                ctx.moveTo(px, y);
                ctx.lineTo(px + pw, y);
                ctx.stroke();
                ctx.fillText(Utils.formatValue(value, root.decimals), px - Theme.paddingSmall, y);
            }

            // --- date labels -----------------------------------------------------
            ctx.textBaseline = "top";
            var longSpan = (b.xMax - b.xMin) > 300 * 86400000;
            // Under bars the labels name periods, from the first bar to the last: the
            // right edge of the plot is when the last period ends ("1 Dec" under November).
            var labelSpan = (b.xMax - b.xMin) - (root.bars ? root._bucketMs : 0);
            var labels = b.single || labelSpan <= 0
                    ? [{ text: Format.formatDate(new Date(b.onlyT), Formatter.DateMediumWithoutYear),
                         x: xAt(root._cx(b.onlyT)), align: "center" }]
                    : root.dateLabels(ctx, b.xMin, labelSpan, pw > Theme.itemSizeHuge * 3 ? 3 : 2, longSpan);
            for (var d = 0; d < labels.length; d++) {
                ctx.textAlign = labels[d].align;
                ctx.fillText(labels[d].text, labels[d].x, py + ph + Theme.paddingSmall);
            }

            // --- series ----------------------------------------------------------
            for (var s = 0; s < root.series.length; s++) {
                var set = root.series[s];
                if (!set || !set.points || set.points.length === 0) {
                    continue;
                }
                var lineColor = set.color ? set.color : Theme.highlightColor;

                if (root.bars) {
                    // 70% of the period's width, so neighbouring bars keep a gap; at
                    // least a device pixel, so a long range still shows every one.
                    var slot = (root._bucketMs / (b.xMax - b.xMin)) * pw;
                    var barWidth = Math.max(Theme.pixelRatio, slot * 0.7);
                    var baseY = yAt(0);
                    var lastBar = set.points.length - 1;
                    ctx.fillStyle = Theme.rgba(lineColor, 0.55);
                    for (var r = 0; r <= lastBar; r++) {
                        var barPoint = set.points[r];
                        var barTop = yAt(barPoint.v);
                        if (r === lastBar) {
                            // The latest period stands out, like the latest reading of a line.
                            ctx.fillStyle = lineColor;
                        }
                        ctx.fillRect(xAt(root._cx(barPoint.t)) - barWidth / 2, Math.min(barTop, baseY),
                                     barWidth, Math.abs(baseY - barTop));
                    }
                } else {
                    // The area under a lone line is shaded; several lines would overlap.
                    if (root.series.length === 1 && set.points.length > 1) {
                        ctx.beginPath();
                        ctx.moveTo(xAt(set.points[0].t), py + ph);
                        for (var f = 0; f < set.points.length; f++) {
                            ctx.lineTo(xAt(set.points[f].t), yAt(set.points[f].v));
                        }
                        ctx.lineTo(xAt(set.points[set.points.length - 1].t), py + ph);
                        ctx.closePath();
                        ctx.fillStyle = Theme.rgba(lineColor, 0.16);
                        ctx.fill();
                    }

                    ctx.strokeStyle = lineColor;
                    // Device pixels: a 2 px line is a hairline on a high-density screen.
                    ctx.lineWidth = 2 * Theme.pixelRatio;
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
                            ctx.arc(xAt(set.points[m].t), yAt(set.points[m].v), 3 * Theme.pixelRatio, 0, 2 * Math.PI);
                            ctx.fill();
                        }
                    }

                    // The latest reading stands out, so "where am I now" reads at a glance.
                    var last = set.points[set.points.length - 1];
                    ctx.fillStyle = Theme.rgba(lineColor, 0.35);
                    ctx.beginPath();
                    ctx.arc(xAt(last.t), yAt(last.v), 7 * Theme.pixelRatio, 0, 2 * Math.PI);
                    ctx.fill();
                    ctx.fillStyle = lineColor;
                    ctx.beginPath();
                    ctx.arc(xAt(last.t), yAt(last.v), 4 * Theme.pixelRatio, 0, 2 * Math.PI);
                    ctx.fill();
                }

                // --- average ------------------------------------------------------
                if (root.showAverage && set.points.length > 1) {
                    var average;
                    if (root.series.length === 1 && root.averageValue !== null
                            && root.averageValue !== undefined && !isNaN(root.averageValue)) {
                        average = root.averageValue;
                    } else {
                        var total = 0;
                        for (var a = 0; a < set.points.length; a++) {
                            total += set.points[a].v;
                        }
                        average = total / set.points.length;
                    }
                    var avgY = yAt(average);
                    // Drawn as explicit segments: setLineDash is not dependable here.
                    ctx.strokeStyle = Theme.rgba(lineColor, 0.5);
                    ctx.lineWidth = Theme.pixelRatio;
                    ctx.beginPath();
                    var dashStep = 12 * Theme.pixelRatio;
                    for (var dash = px; dash < px + pw; dash += dashStep) {
                        ctx.moveTo(dash, avgY);
                        ctx.lineTo(Math.min(dash + dashStep / 2, px + pw), avgY);
                    }
                    ctx.stroke();
                }
            }

            // --- the value to reach ---------------------------------------------------
            if (root.goalValue !== null && root.goalValue !== undefined && !isNaN(root.goalValue)) {
                var goalY = yAt(root.goalValue);
                // Longer dashes and the text colour, so it is not taken for the average.
                ctx.strokeStyle = Theme.rgba(Theme.primaryColor, 0.75);
                ctx.lineWidth = Math.max(1, Math.round(1.5 * Theme.pixelRatio));
                ctx.beginPath();
                var goalDash = 24 * Theme.pixelRatio;
                for (var gd = px; gd < px + pw; gd += goalDash) {
                    ctx.moveTo(gd, goalY);
                    ctx.lineTo(Math.min(gd + goalDash * 0.6, px + pw), goalY);
                }
                ctx.stroke();
                if (root.goalText !== "") {
                    // Above the line, or below it when the line is at the top of the plot.
                    var above = goalY - py > Theme.fontSizeExtraSmall * 1.5;
                    ctx.fillStyle = Theme.primaryColor;
                    ctx.textAlign = "right";
                    ctx.textBaseline = above ? "bottom" : "top";
                    ctx.fillText(root.goalText, px + pw - Theme.paddingSmall,
                                 goalY + (above ? -Theme.paddingSmall / 2 : Theme.paddingSmall / 2));
                }
            }
        }
    }

    /*
     * Touch marker, drawn over the canvas. Dragging a finger along the chart used to
     * repaint the whole chart -- bands, grid, labels and every point, on the CPU -- for
     * each touch event; now only these two items move.
     */
    Rectangle {
        visible: root.highlightedPoint !== null
        x: visible ? Math.round(root.xAt(root._cx(root.highlightedPoint.t)) - width / 2) : 0
        y: root._plotY
        width: Math.max(1, Math.round(Theme.pixelRatio))
        height: root._plotHeight
        color: Theme.rgba(Theme.highlightColor, 0.6)
    }

    Rectangle {
        visible: root.highlightedPoint !== null
        width: Math.round(10 * Theme.pixelRatio)
        height: width
        radius: width / 2
        x: visible ? root.xAt(root._cx(root.highlightedPoint.t)) - width / 2 : 0
        y: visible ? root.yAt(root.highlightedPoint.v) - height / 2 : 0
        color: Theme.highlightColor
    }

    // Drag anywhere across the plot to read individual values off the line.
    MouseArea {
        anchors.fill: parent
        enabled: root.pointCount() > 0

        // The nearest point in time; of several at the same time (systolic and diastolic
        // share theirs) the one nearest the finger, so both lines can be read. The first
        // series used to win every tie, and the diastolic value could not be read at all.
        function pick(mouseX, mouseY) {
            var b = root._bounds;
            if (!b.valid) {
                return;
            }
            var t = b.xMin + ((mouseX - root._plotX) / root._plotWidth) * (b.xMax - b.xMin);
            // A bar is drawn half a period after its start (_cx): shift the finger back
            // once rather than every point.
            var target = root.bars ? t - root._bucketMs / 2 : t;
            var best = null;
            var bestSeries = -1;
            var bestDistance = Number.MAX_VALUE;
            for (var s = 0; s < root.series.length; s++) {
                var points = root.series[s] ? root.series[s].points : null;
                if (!points) {
                    continue;
                }
                for (var i = 0; i < points.length; i++) {
                    var distance = Math.abs(points[i].t - target);
                    var nearer = distance < bestDistance;
                    if (!nearer && best !== null && distance === bestDistance) {
                        nearer = Math.abs(root.yAt(points[i].v) - mouseY) < Math.abs(root.yAt(best.v) - mouseY);
                    }
                    if (nearer) {
                        bestDistance = distance;
                        best = points[i];
                        bestSeries = s;
                    }
                }
            }
            root.highlightedPoint = best;
            root.highlightedSeries = bestSeries;
        }

        onPressed: pick(mouse.x, mouse.y)
        onPositionChanged: pick(mouse.x, mouse.y)
        onReleased: {
            root.highlightedPoint = null;
            root.highlightedSeries = -1;
        }
        onCanceled: {
            root.highlightedPoint = null;
            root.highlightedSeries = -1;
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
            // Same decimals as the axis, no stray space without a unit (BMI), and on a
            // chart with several lines the name of the one touched (systolic or diastolic).
            // A weekly or monthly bar is an average day, and says so.
            text: {
                if (root.highlightedPoint === null) {
                    return "";
                }
                var set = root.series.length > 1 && root.highlightedSeries >= 0
                        ? root.series[root.highlightedSeries] : null;
                var value = Utils.formatValue(root.highlightedPoint.v, root.decimals)
                        + (root.unit ? " " + root.unit : "");
                if (root.bars && root.bucket !== "day") {
                    //: Chart readout for a weekly or monthly bar: the average per day, e.g. "1.8 L a day"
                    value = qsTr("%1 a day").arg(value);
                }
                return (set && set.label ? set.label + " " : "") + value + "  ·  "
                        + root.periodText(root.highlightedPoint.t);
            }
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
