pragma ComponentBehavior: Bound
import QtQuick 2.15
import QtQuick.Controls 2.15 as QC
import QtQuick.Layouts 1.15
import org.kde.kirigami.layouts 2.0 as KirigamiLayouts

KirigamiLayouts.FormLayout {
    anchors.fill: parent

    property alias cfg_fontSize:        fontSpin.value
    property alias cfg_speed:           speedSpin.value
    property alias cfg_colorMode:       modeCombo.currentIndex
    property alias cfg_singleColor:     colorField.text
    property alias cfg_paletteIndex:    paletteCombo.currentIndex
    property alias cfg_jitter:          jitterSpin.value
    property alias cfg_glitchChance:    glitchSpin.value
    property alias cfg_trailLength:     trailMaxSpin.value
    property alias cfg_trailLengthMin:  trailMinSpin.value
    property alias cfg_density:         densitySpin.value
    property alias cfg_leadHighlight:   leadCheck.checked
    property alias cfg_glowSize:        glowSpin.value
    property alias cfg_direction:       dirCombo.currentIndex
    property alias cfg_varSpeed:        varSpeedCheck.checked
    property alias cfg_dropsPerColumn:  dropsSpin.value
    property alias cfg_restartDelay:    restartSpin.value
    property alias cfg_bgColor:         bgColorField.text
    property string cfg_fontFamily:     configuration.fontFamily  !== undefined ? configuration.fontFamily  : "monospace"
    property int    cfg_charSetMask:    configuration.charSetMask !== undefined ? configuration.charSetMask : 1

    // --- Text / character appearance ---

    QC.SpinBox {
        id: fontSpin; from: 8; to: 48; stepSize: 1; value: configuration.fontSize
        onValueChanged: configuration.fontSize = value
        KirigamiLayouts.FormData.label: qsTr("Font Size")
    }
    QC.ComboBox {
        id: fontCombo
        // Cache as a JS array so indexOf is reliable — calling indexOf on the
        // ComboBox's wrapped model returned -1 even for present families.
        property var fontList: Qt.fontFamilies()
        model: fontList
        onActivated: function(idx) {
            cfg_fontFamily = fontList[idx]
            configuration.fontFamily = fontList[idx]
        }
        Component.onCompleted: Qt.callLater(function() {
            var fam = cfg_fontFamily || configuration.fontFamily || "monospace"
            var idx = fontList.indexOf(fam)
            currentIndex = idx >= 0 ? idx : 0
        })
        KirigamiLayouts.FormData.label: qsTr("Font")
    }
    ColumnLayout {
        spacing: 2
        KirigamiLayouts.FormData.label: qsTr("Character Sets")
        QC.CheckBox {
            text: qsTr("Katakana")
            checked: (cfg_charSetMask & 1) !== 0
            onToggled: { cfg_charSetMask = checked ? cfg_charSetMask | 1  : cfg_charSetMask & ~1;  configuration.charSetMask = cfg_charSetMask }
        }
        QC.CheckBox {
            text: qsTr("ASCII")
            checked: (cfg_charSetMask & 2) !== 0
            onToggled: { cfg_charSetMask = checked ? cfg_charSetMask | 2  : cfg_charSetMask & ~2;  configuration.charSetMask = cfg_charSetMask }
        }
        QC.CheckBox {
            text: qsTr("Binary")
            checked: (cfg_charSetMask & 4) !== 0
            onToggled: { cfg_charSetMask = checked ? cfg_charSetMask | 4  : cfg_charSetMask & ~4;  configuration.charSetMask = cfg_charSetMask }
        }
        QC.CheckBox {
            text: qsTr("Braille")
            checked: (cfg_charSetMask & 8) !== 0
            onToggled: { cfg_charSetMask = checked ? cfg_charSetMask | 8  : cfg_charSetMask & ~8;  configuration.charSetMask = cfg_charSetMask }
        }
        QC.CheckBox {
            text: qsTr("Picto")
            checked: (cfg_charSetMask & 16) !== 0
            onToggled: { cfg_charSetMask = checked ? cfg_charSetMask | 16 : cfg_charSetMask & ~16; configuration.charSetMask = cfg_charSetMask }
        }
        QC.CheckBox {
            text: qsTr("Runic")
            checked: (cfg_charSetMask & 32) !== 0
            onToggled: { cfg_charSetMask = checked ? cfg_charSetMask | 32 : cfg_charSetMask & ~32; configuration.charSetMask = cfg_charSetMask }
        }
    }
    QC.SpinBox {
        id: trailMaxSpin; from: 2; to: 60; stepSize: 1
        value: configuration.trailLength !== undefined ? configuration.trailLength : 20
        onValueChanged: configuration.trailLength = value
        KirigamiLayouts.FormData.label: qsTr("Trail Max")
    }
    QC.SpinBox {
        id: trailMinSpin; from: 2; to: 60; stepSize: 1
        value: configuration.trailLengthMin !== undefined ? configuration.trailLengthMin : 5
        onValueChanged: configuration.trailLengthMin = value
        KirigamiLayouts.FormData.label: qsTr("Trail Min")
    }
    QC.CheckBox {
        id: leadCheck
        text: qsTr("Enabled")
        checked: configuration.leadHighlight !== undefined ? configuration.leadHighlight : false
        onCheckedChanged: configuration.leadHighlight = checked
        KirigamiLayouts.FormData.label: qsTr("Lead Highlight")
    }
    QC.SpinBox {
        id: glowSpin; from: 0; to: 30; stepSize: 1
        value: configuration.glowSize !== undefined ? configuration.glowSize : 0
        onValueChanged: configuration.glowSize = value
        KirigamiLayouts.FormData.label: qsTr("Glow")
    }

    // --- Motion ---

    QC.SpinBox {
        id: speedSpin; from: 1; to: 100; stepSize: 1; value: configuration.speed
        onValueChanged: configuration.speed = value
        KirigamiLayouts.FormData.label: qsTr("Speed")
    }
    QC.ComboBox {
        id: dirCombo
        model: [qsTr("Down"), qsTr("Up"), qsTr("Right"), qsTr("Left")]
        currentIndex: configuration.direction !== undefined ? configuration.direction : 0
        onCurrentIndexChanged: configuration.direction = currentIndex
        KirigamiLayouts.FormData.label: qsTr("Direction")
    }
    QC.SpinBox {
        id: densitySpin; from: 1; to: 100; stepSize: 1
        value: configuration.density !== undefined ? configuration.density : 100
        onValueChanged: configuration.density = value
        KirigamiLayouts.FormData.label: qsTr("Density (%)")
    }
    QC.SpinBox {
        id: dropsSpin; from: 1; to: 4; stepSize: 1
        value: configuration.dropsPerColumn !== undefined ? configuration.dropsPerColumn : 1
        onValueChanged: configuration.dropsPerColumn = value
        KirigamiLayouts.FormData.label: qsTr("Drops / Column")
    }
    QC.SpinBox {
        id: restartSpin; from: 0; to: 100; stepSize: 1
        value: configuration.restartDelay !== undefined ? configuration.restartDelay : 0
        onValueChanged: configuration.restartDelay = value
        KirigamiLayouts.FormData.label: qsTr("Restart Delay")
    }
    QC.CheckBox {
        id: varSpeedCheck
        text: qsTr("Enabled")
        checked: configuration.varSpeed !== undefined ? configuration.varSpeed : false
        onCheckedChanged: configuration.varSpeed = checked
        KirigamiLayouts.FormData.label: qsTr("Variable Speed")
    }
    QC.SpinBox {
        id: jitterSpin; from: 0; to: 100; stepSize: 1; value: configuration.jitter * 100
        onValueChanged: configuration.jitter = value / 100
        KirigamiLayouts.FormData.label: qsTr("Jitter (%)")
    }

    // --- Color ---

    QC.ComboBox {
        id: modeCombo; model: [qsTr("Single Color"), qsTr("Multi Color")]
        currentIndex: configuration.colorMode
        onCurrentIndexChanged: configuration.colorMode = currentIndex
        KirigamiLayouts.FormData.label: qsTr("Color Mode")
    }
    QC.TextField {
        id: colorField; text: configuration.singleColor
        onTextChanged: configuration.singleColor = text
        visible: modeCombo.currentIndex === 0
        KirigamiLayouts.FormData.label: qsTr("Single Color")
    }
    QC.Button {
        text: qsTr("Default"); visible: modeCombo.currentIndex === 0
        onClicked: colorField.text = "#00ff00"
    }
    QC.ComboBox {
        id: paletteCombo; model: [qsTr("Neon"), qsTr("Cyberpunk"), qsTr("Synthwave")]
        currentIndex: configuration.paletteIndex
        onCurrentIndexChanged: configuration.paletteIndex = currentIndex
        visible: modeCombo.currentIndex === 1
        KirigamiLayouts.FormData.label: qsTr("Palette")
    }
    QC.SpinBox {
        id: glitchSpin; from: 0; to: 100; stepSize: 1; value: configuration.glitchChance
        onValueChanged: configuration.glitchChance = value
        KirigamiLayouts.FormData.label: qsTr("Glitch Chance (%)")
    }
    QC.TextField {
        id: bgColorField
        text: configuration.bgColor !== undefined ? configuration.bgColor : "#000000"
        onTextChanged: configuration.bgColor = text
        KirigamiLayouts.FormData.label: qsTr("Background Color")
    }
    QC.Button {
        text: qsTr("Default")
        onClicked: bgColorField.text = "#000000"
    }
}
