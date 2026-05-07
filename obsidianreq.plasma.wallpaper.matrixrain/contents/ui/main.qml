import QtQuick 2.15
import QtQuick.Effects
import org.kde.plasma.plasmoid 2.0

WallpaperItem {
    id: main
    anchors.fill: parent

    property int fontSize:       main.configuration.fontSize       !== undefined ? main.configuration.fontSize       : 16
    property int speed:          main.configuration.speed          !== undefined ? main.configuration.speed          : 50
    property int colorMode:      main.configuration.colorMode      !== undefined ? main.configuration.colorMode      : 0
    property color singleColor:  main.configuration.singleColor    !== undefined ? main.configuration.singleColor    : "#00ff00"
    property int paletteIndex:   main.configuration.paletteIndex   !== undefined ? main.configuration.paletteIndex   : 0
    property real jitter:        main.configuration.jitter         !== undefined ? main.configuration.jitter         : 0
    property int glitchChance:   main.configuration.glitchChance   !== undefined ? main.configuration.glitchChance   : 1
    property string fontFamily:  main.configuration.fontFamily     !== undefined ? main.configuration.fontFamily     : "monospace"
    property int charSetMask:    main.configuration.charSetMask    !== undefined ? main.configuration.charSetMask    : 1
    property int trailLength:    main.configuration.trailLength    !== undefined ? main.configuration.trailLength    : 20
    property int trailLengthMin: main.configuration.trailLengthMin !== undefined ? main.configuration.trailLengthMin : 5
    property int density:        main.configuration.density        !== undefined ? main.configuration.density        : 100
    property bool leadHighlight: main.configuration.leadHighlight  !== undefined ? main.configuration.leadHighlight  : false
    property int glowSize:       main.configuration.glowSize       !== undefined ? main.configuration.glowSize       : 0
    property color bgColor:      main.configuration.bgColor        !== undefined ? main.configuration.bgColor        : "#000000"
    property int direction:      main.configuration.direction      !== undefined ? main.configuration.direction      : 0
    property bool varSpeed:      main.configuration.varSpeed       !== undefined ? main.configuration.varSpeed       : false
    property int dropsPerColumn: main.configuration.dropsPerColumn !== undefined ? main.configuration.dropsPerColumn : 1
    property int restartDelay:   main.configuration.restartDelay   !== undefined ? main.configuration.restartDelay   : 0

    property var palettes: [
        ["#00ff00","#ff00ff","#00ffff","#ff0000","#ffff00","#0000ff"],
        ["#ff0066","#33ff99","#ffcc00","#6600ff","#00ccff","#ff3300"],
        ["#ff00ff","#00ffcc","#cc00ff","#ffcc33","#33ccff","#ccff00"]
    ]

    property string currentChars: {
        var mask = main.charSetMask
        var s = ""
        if (mask & 1)  { for (var i = 0;    i < 96;   i++) s += String.fromCharCode(0x30A0 + i) }
        if (mask & 2)  { for (var i = 0x21; i <= 0x7E; i++) s += String.fromCharCode(i) }
        if (mask & 4)  { s += "01" }
        if (mask & 8)  { for (var i = 0;    i < 256;  i++) s += String.fromCharCode(0x2800 + i) }
        if (mask & 16) { for (var i = 0;    i < 256;  i++) s += String.fromCharCode(0x2600 + i) }
        if (mask & 32) { for (var i = 0;    i < 89;   i++) s += String.fromCharCode(0x16A0 + i) }
        return s || "?"
    }

    // Background is its own Rectangle so the Canvas can stay transparent.
    // A transparent Canvas is required for the MultiEffect glow below: the
    // shadow (halo) effect uses source alpha as a mask — if the Canvas were
    // opaque-filled the whole screen would glow.
    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: main.bgColor
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Threaded
        // Hidden because the MultiEffect below renders the canvas content
        // (and adds the glow halo). The Canvas still paints to its texture.
        visible: false

        // drops[col][dropIdx]              — float head position in rows
        // columnLastHeadRow[col][dropIdx]  — last integer row painted, -1 = not yet drawn
        // columnCooldowns[col][dropIdx]    — frames remaining before drop reappears
        // columnSpeeds[col]                — per-column speed multiplier
        // columnActive[col]                — whether column is alive (density)
        // columnTrailLengths[col]          — pre-randomised trail depth for this column
        property var drops: []
        property var columnLastHeadRow: []
        property var columnCooldowns: []
        property var columnSpeeds: []
        property var columnActive: []
        property var columnTrailLengths: []
        property bool needsClear: true

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
            var dpc  = Math.max(1, main.dropsPerColumn)
            var tMax = Math.max(2, main.trailLength)
            var tMin = Math.min(Math.max(2, main.trailLengthMin), tMax)

            drops              = []
            columnLastHeadRow  = []
            columnCooldowns    = []
            columnSpeeds       = []
            columnActive       = []
            columnTrailLengths = []

            for (var j = 0; j < cols; j++) {
                var colDrops = []
                var colLast  = []
                var colCool  = []
                for (var d = 0; d < dpc; d++) {
                    colDrops.push((rows / dpc) * d + Math.random() * (rows / dpc))
                    colLast.push(-1)
                    colCool.push(0)
                }
                drops.push(colDrops)
                columnLastHeadRow.push(colLast)
                columnCooldowns.push(colCool)
                columnSpeeds.push(main.varSpeed ? (0.5 + Math.random() * 1.5) : 1.0)
                columnActive.push(Math.random() * 100 < main.density)
                columnTrailLengths.push(tMin === tMax
                    ? tMin
                    : tMin + Math.floor(Math.random() * (tMax - tMin + 1)))
            }
            needsClear = true
        }

        Timer {
            id: timer
            interval: 1000 / main.speed
            running: true
            repeat: true
            onTriggered: canvas.requestPaint()
        }

        onPaint: {
            if (drops.length === 0) initDrops()

            // Hoist all property reads — with renderStrategy: Threaded these
            // cross thread boundaries, so we read them once per paint.
            var ctx    = getContext("2d")
            var w      = width,  h = height
            var sz     = main.fontSize
            var rows   = rowCount()
            var chars  = main.currentChars
            var clen   = chars.length
            var dir    = main.direction
            var glitch = main.glitchChance
            var lead   = main.leadHighlight
            var jitter = main.jitter
            var rd     = main.restartDelay
            var multi  = main.colorMode !== 0
            var palArr = main.palettes[main.paletteIndex]
            var palLen = palArr.length
            var single = main.singleColor
            var tMax   = Math.max(2, main.trailLength)

            // Fade alpha controls how long previously-painted glyphs persist on
            // the canvas. Tuned so trails reach near-invisibility around 1.5x
            // the configured max trail length; the per-column wipe truncates
            // any column whose colTrailLen is shorter than that.
            var fadeAlpha = 1.5 / tMax

            if (needsClear) {
                ctx.clearRect(0, 0, w, h)
                needsClear = false
            }

            // Fade by reducing destination alpha rather than painting opaque
            // bg: keeps the canvas transparent so the bg Rectangle shows
            // through and so the MultiEffect glow has glyph-shaped alpha to
            // work with.
            ctx.globalCompositeOperation = "destination-out"
            ctx.globalAlpha = fadeAlpha
            ctx.fillStyle = "#000"
            ctx.fillRect(0, 0, w, h)
            ctx.globalCompositeOperation = "source-over"
            ctx.globalAlpha = 1.0

            ctx.font = sz + "px " + main.fontFamily

            for (var i = 0; i < drops.length; i++) {
                if (!columnActive[i]) continue

                var colTrailLen = columnTrailLengths[i] || tMax
                var doWipe      = colTrailLen < rows
                var baseColor   = multi ? palArr[i % palLen] : single

                for (var d = 0; d < drops[i].length; d++) {
                    if (columnCooldowns[i][d] > 0) {
                        columnCooldowns[i][d]--
                        continue
                    }

                    var prevRow = columnLastHeadRow[i][d]
                    var headRow = drops[i][d] | 0

                    if (headRow !== prevRow) {
                        // Replace the old (white) head with a baseColor glyph so the
                        // white doesn't streak through the trail as it fades.
                        // fillText alone doesn't fully cover the previous glyph because
                        // of antialiasing, so clear the cell first.
                        if (lead && prevRow >= 0) {
                            var prevR = ((prevRow % rows) + rows) % rows
                            var ppx, ppy
                            switch (dir) {
                                case 0: ppx = i * sz;                   ppy = prevR * sz; break
                                case 1: ppx = i * sz;                   ppy = (rows - 1 - prevR) * sz; break
                                case 2: ppx = prevR * sz;               ppy = i * sz; break
                                case 3: ppx = (rows - 1 - prevR) * sz;  ppy = i * sz; break
                            }
                            ctx.clearRect(ppx, ppy, sz, sz)
                            ctx.globalAlpha = 1.0
                            ctx.fillStyle = baseColor
                            ctx.fillText(chars.charAt((Math.random() * clen) | 0), ppx, ppy + sz)
                        }

                        // Paint a head at every integer row crossed since last frame
                        // (covers fast columns where speed > 1 row/frame).
                        var startRow, endRow
                        if (prevRow < 0 || headRow < prevRow) {
                            startRow = headRow; endRow = headRow
                        } else {
                            startRow = prevRow + 1; endRow = headRow
                        }

                        for (var r = startRow; r <= endRow; r++) {
                            var actualRow = ((r % rows) + rows) % rows
                            var px, py
                            switch (dir) {
                                case 0: px = i * sz;                    py = actualRow * sz; break
                                case 1: px = i * sz;                    py = (rows - 1 - actualRow) * sz; break
                                case 2: px = actualRow * sz;            py = i * sz; break
                                case 3: px = (rows - 1 - actualRow) * sz; py = i * sz; break
                            }

                            var isHead = (r === endRow)
                            var charColor
                            if (isHead && lead) {
                                charColor = "#ffffff"
                            } else if (Math.random() * 100 < glitch) {
                                charColor = "#ffffff"
                            } else {
                                charColor = baseColor
                            }

                            ctx.globalAlpha = 1.0
                            ctx.fillStyle = charColor
                            ctx.fillText(chars.charAt((Math.random() * clen) | 0), px, py + sz)

                            // Wipe the cell that just left this column's per-column
                            // trail. Without this, columns whose colTrailLen < tMax
                            // would inherit the fade window of the longest column.
                            if (doWipe) {
                                var wipeR = (((r - colTrailLen) % rows) + rows) % rows
                                var wpx, wpy
                                switch (dir) {
                                    case 0: wpx = i * sz;                    wpy = wipeR * sz; break
                                    case 1: wpx = i * sz;                    wpy = (rows - 1 - wipeR) * sz; break
                                    case 2: wpx = wipeR * sz;                wpy = i * sz; break
                                    case 3: wpx = (rows - 1 - wipeR) * sz;   wpy = i * sz; break
                                }
                                ctx.clearRect(wpx, wpy, sz, sz)
                            }
                        }

                        columnLastHeadRow[i][d] = headRow
                    }

                    // Jitter: symmetric ±jitter rows added to per-frame advance,
                    // clamped to non-negative so the head never reverses (which
                    // would break the integer-row tracking) but can stutter/pause.
                    var jitDelta = jitter > 0 ? (Math.random() - 0.5) * 2 * jitter : 0
                    var advance  = columnSpeeds[i] + jitDelta
                    if (advance < 0) advance = 0
                    var newPos = drops[i][d] + advance
                    if (newPos >= rows) {
                        if (rd > 0) {
                            drops[i][d]                 = 0
                            columnLastHeadRow[i][d]     = -1
                            columnCooldowns[i][d]       = (Math.random() * (rd + 1)) | 0
                        } else {
                            drops[i][d]                 = newPos % rows
                            columnLastHeadRow[i][d]     = -1
                        }
                    } else {
                        drops[i][d] = newPos
                    }
                }
            }

            ctx.globalAlpha = 1.0
        }

        Component.onCompleted: initDrops()
        onWidthChanged:  initDrops()
        onHeightChanged: initDrops()
    }

    // GPU glow: renders the canvas plus a blurred halo behind sharp glyphs.
    // shadowEnabled is the right MultiEffect mode for this (blur replaces the
    // source with a blurred copy, which would smear the trails). With glow
    // off, source is rendered through the effect unchanged.
    MultiEffect {
        anchors.fill: canvas
        source: canvas
        blurMax: 32
        autoPaddingEnabled: true
        shadowEnabled: main.glowSize > 0
        shadowBlur: Math.min(1.0, main.glowSize / 30)
        shadowOpacity: 1.0
        shadowColor: main.colorMode === 0 ? main.singleColor : "#ffffff"
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        shadowScale: 1.0
    }

    onFontSizeChanged:       { canvas.initDrops(); canvas.requestPaint() }
    onSpeedChanged:          timer.interval = 1000 / main.speed
    onColorModeChanged:      canvas.requestPaint()
    onSingleColorChanged:    canvas.requestPaint()
    onPaletteIndexChanged:   canvas.requestPaint()
    onJitterChanged:         canvas.requestPaint()
    onGlitchChanceChanged:   canvas.requestPaint()
    onFontFamilyChanged:     canvas.requestPaint()
    onCurrentCharsChanged:   canvas.requestPaint()
    onTrailLengthChanged:    { canvas.initDrops(); canvas.requestPaint() }
    onTrailLengthMinChanged: { canvas.initDrops(); canvas.requestPaint() }
    onLeadHighlightChanged:  canvas.requestPaint()
    onGlowSizeChanged:       canvas.requestPaint()
    onBgColorChanged:        canvas.requestPaint()
    onDirectionChanged:      { canvas.initDrops(); canvas.requestPaint() }
    onDensityChanged:        { canvas.initDrops(); canvas.requestPaint() }
    onVarSpeedChanged:       { canvas.initDrops(); canvas.requestPaint() }
    onDropsPerColumnChanged: { canvas.initDrops(); canvas.requestPaint() }
    onRestartDelayChanged:   canvas.requestPaint()
}
