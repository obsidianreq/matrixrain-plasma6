import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0

WallpaperItem {
    id: main
    anchors.fill: parent

    property int fontSize: main.configuration.fontSize !== undefined ? main.configuration.fontSize : 16
    property int speed: main.configuration.speed !== undefined ? main.configuration.speed : 50
    property int colorMode: main.configuration.colorMode !== undefined ? main.configuration.colorMode : 0
    property color singleColor: main.configuration.singleColor !== undefined ? main.configuration.singleColor : "#00ff00"
    property int paletteIndex: main.configuration.paletteIndex !== undefined ? main.configuration.paletteIndex : 0
    property real jitter: main.configuration.jitter !== undefined ? main.configuration.jitter : 0
    property int glitchChance: main.configuration.glitchChance !== undefined ? main.configuration.glitchChance : 1
    property string fontFamily: main.configuration.fontFamily !== undefined ? main.configuration.fontFamily : "monospace"
    property int charSetMask: main.configuration.charSetMask !== undefined ? main.configuration.charSetMask : 1
    property int trailLength: main.configuration.trailLength !== undefined ? main.configuration.trailLength : 20
    property int density: main.configuration.density !== undefined ? main.configuration.density : 100
    property bool leadHighlight: main.configuration.leadHighlight !== undefined ? main.configuration.leadHighlight : false
    property color bgColor: main.configuration.bgColor !== undefined ? main.configuration.bgColor : "#000000"
    property int direction: main.configuration.direction !== undefined ? main.configuration.direction : 0
    property bool varSpeed: main.configuration.varSpeed !== undefined ? main.configuration.varSpeed : false

    property var palettes: [
        ["#00ff00","#ff00ff","#00ffff","#ff0000","#ffff00","#0000ff"],
        ["#ff0066","#33ff99","#ffcc00","#6600ff","#00ccff","#ff3300"],
        ["#ff00ff","#00ffcc","#cc00ff","#ffcc33","#33ccff","#ccff00"]
    ]

    // Built from charSetMask bitmask; re-evaluates automatically when mask changes.
    property string currentChars: {
        var mask = main.charSetMask
        var s = ""
        if (mask & 1)  { for (var i = 0;      i < 96;   i++) s += String.fromCharCode(0x30A0 + i) }  // Katakana
        if (mask & 2)  { for (var i = 0x21;   i <= 0x7E; i++) s += String.fromCharCode(i) }           // ASCII
        if (mask & 4)  { s += "01" }                                                                   // Binary
        if (mask & 8)  { for (var i = 0;      i < 256;  i++) s += String.fromCharCode(0x2800 + i) }  // Braille
        if (mask & 16) { for (var i = 0;      i < 256;  i++) s += String.fromCharCode(0x2600 + i) }  // Picto
        if (mask & 32) { for (var i = 0;      i < 89;   i++) s += String.fromCharCode(0x16A0 + i) }  // Runic
        return s || "?"
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        property var drops: []
        property var columnSpeeds: []
        property var columnActive: []

        function columnCount() {
            return main.direction <= 1
                ? Math.floor(canvas.width  / main.fontSize)
                : Math.floor(canvas.height / main.fontSize)
        }
        function rowCount() {
            return main.direction <= 1
                ? Math.floor(canvas.height / main.fontSize)
                : Math.floor(canvas.width  / main.fontSize)
        }

        function initDrops() {
            if (canvas.width <= 0 || canvas.height <= 0) return
            var cols = columnCount()
            var rows = rowCount()
            drops = []
            columnSpeeds = []
            columnActive = []
            for (var j = 0; j < cols; j++) {
                drops.push(Math.random() * rows)
                columnSpeeds.push(main.varSpeed ? (0.5 + Math.random() * 1.5) : 1.0)
                columnActive.push(Math.random() * 100 < main.density)
            }
        }

        Timer {
            id: timer
            interval: 1000 / main.speed
            running: true
            repeat: true
            onTriggered: canvas.requestPaint()
        }

        onPaint: {
            // Guard: if initDrops hasn't run yet (e.g. size was 0 at Component.onCompleted)
            if (drops.length === 0) initDrops()

            var ctx = getContext("2d")
            var w = width, h = height
            var sz = main.fontSize
            var cols = columnCount()
            var rows = rowCount()
            var tLen = Math.max(2, main.trailLength)
            var chars = main.currentChars
            var clen = chars.length

            ctx.fillStyle = main.bgColor
            ctx.fillRect(0, 0, w, h)
            ctx.font = sz + "px " + main.fontFamily

            for (var i = 0; i < drops.length; i++) {
                if (!columnActive[i]) continue

                var headRow = Math.floor(drops[i])
                var baseColor = main.colorMode === 0
                    ? main.singleColor
                    : main.palettes[main.paletteIndex][i % main.palettes[main.paletteIndex].length]

                // Draw trail from tail (t = tLen-1) to head (t = 0)
                for (var t = tLen - 1; t >= 0; t--) {
                    var row = ((headRow - t) % rows + rows) % rows
                    var opacity = (tLen - t) / tLen

                    // Map logical (col, row) to screen (px, py) based on direction
                    var px, py
                    switch (main.direction) {
                        case 0: px = i   * sz; py = row                 * sz; break  // down
                        case 1: px = i   * sz; py = (rows - 1 - row)   * sz; break  // up
                        case 2: px = row * sz; py = i                   * sz; break  // right
                        case 3: px = (rows - 1 - row) * sz; py = i     * sz; break  // left
                    }

                    if (t === 0 && main.leadHighlight) {
                        ctx.globalAlpha = 1.0
                        ctx.fillStyle = "#ffffff"
                    } else if (Math.random() * 100 < main.glitchChance) {
                        ctx.globalAlpha = opacity
                        ctx.fillStyle = "#ffffff"
                    } else {
                        ctx.globalAlpha = opacity
                        ctx.fillStyle = baseColor
                    }

                    ctx.fillText(chars.charAt(Math.floor(Math.random() * clen)), px, py + sz)
                }

                drops[i] = (drops[i] + columnSpeeds[i] + Math.random() * main.jitter) % rows
            }

            ctx.globalAlpha = 1.0
        }

        Component.onCompleted: initDrops()
        onWidthChanged: initDrops()
        onHeightChanged: initDrops()
    }

    onFontSizeChanged:     { canvas.initDrops(); canvas.requestPaint() }
    onSpeedChanged:        timer.interval = 1000 / main.speed
    onColorModeChanged:    canvas.requestPaint()
    onSingleColorChanged:  canvas.requestPaint()
    onPaletteIndexChanged: canvas.requestPaint()
    onJitterChanged:       canvas.requestPaint()
    onGlitchChanceChanged: canvas.requestPaint()
    onFontFamilyChanged:   canvas.requestPaint()
    onCurrentCharsChanged: canvas.requestPaint()
    onTrailLengthChanged:  canvas.requestPaint()
    onLeadHighlightChanged: canvas.requestPaint()
    onBgColorChanged:      canvas.requestPaint()
    onDirectionChanged:    { canvas.initDrops(); canvas.requestPaint() }
    onDensityChanged:      { canvas.initDrops(); canvas.requestPaint() }
    onVarSpeedChanged:     { canvas.initDrops(); canvas.requestPaint() }
}
