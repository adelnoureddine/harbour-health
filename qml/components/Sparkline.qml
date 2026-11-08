import QtQuick 2.0
import Sailfish.Silica 1.0

/*
 * A small trend line without axes, for the dashboard. `points` are plain numbers,
 * oldest first. Painted once per change; nothing redraws while scrolling.
 */
Canvas {
    id: root

    property var points: []
    property color lineColor: Theme.highlightColor
    property bool filled: true

    renderTarget: Canvas.Image
    renderStrategy: Canvas.Immediate

    onPointsChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.clearRect(0, 0, width, height);
        if (!points || points.length < 2) {
            return;
        }

        var min = points[0];
        var max = points[0];
        for (var i = 1; i < points.length; i++) {
            min = Math.min(min, points[i]);
            max = Math.max(max, points[i]);
        }
        // A flat line sits in the middle rather than on the floor.
        var spread = max - min;
        if (spread === 0) {
            spread = 1;
            min -= 0.5;
        }

        var dot = 3 * Theme.pixelRatio;
        var top = dot;
        var usable = height - 2 * dot;
        var right = width - dot;
        function xAt(index) {
            return index * right / (points.length - 1);
        }
        function yAt(v) {
            return top + usable - ((v - min) / spread) * usable;
        }

        if (filled) {
            ctx.beginPath();
            ctx.moveTo(0, height);
            for (var f = 0; f < points.length; f++) {
                ctx.lineTo(xAt(f), yAt(points[f]));
            }
            ctx.lineTo(xAt(points.length - 1), height);
            ctx.closePath();
            ctx.fillStyle = Theme.rgba(lineColor, 0.16);
            ctx.fill();
        }

        ctx.beginPath();
        for (var k = 0; k < points.length; k++) {
            if (k === 0) {
                ctx.moveTo(xAt(k), yAt(points[k]));
            } else {
                ctx.lineTo(xAt(k), yAt(points[k]));
            }
        }
        ctx.strokeStyle = lineColor;
        ctx.lineWidth = 2 * Theme.pixelRatio;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.stroke();

        // The latest reading, where the line ends.
        ctx.beginPath();
        ctx.arc(xAt(points.length - 1), yAt(points[points.length - 1]), dot, 0, 2 * Math.PI);
        ctx.fillStyle = lineColor;
        ctx.fill();
    }
}

// vim:et:ts=4:sw=4
