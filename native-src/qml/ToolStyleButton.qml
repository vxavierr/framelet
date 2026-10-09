import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

// The same contextual style editor on screenshots and video.
StudioButton {
    id: control
    property var doc
    property var atelierStudio: null
    property var paletteColors: ["#c87553","#e0b550","#556d83","#6f8872","#292f35"]
    property int paletteSlot: 0
    function pickPigment(color) {
        const colors = paletteColors.slice();
        const found = colors.findIndex(c => Qt.colorEqual(c, color));
        if (found < 0) { colors[paletteSlot] = String(color); paletteColors = colors; }
        else paletteSlot = found;
        apply({color:String(color)});
    }
    property string kind: "text"
    readonly property var names: ({text: "Text", arrow: "Arrow", line: "Line", box: "Box", ellipse: "Oval", pen: "Pen", brush: "Brush", highlight: "Highlight", step: "Step", blur: "Blur"})
    readonly property bool supported: names[kind] !== undefined
    readonly property string toolName: names[kind] || "Tool"
    readonly property var plurals: ({text: "labels", arrow: "arrows", line: "lines", box: "boxes", ellipse: "ovals", pen: "strokes", brush: "brush strokes", highlight: "highlights", step: "steps", blur: "blur areas"})
    readonly property bool opened: editor.opened
    readonly property bool label: kind === "text"
    readonly property bool shape: kind === "box" || kind === "ellipse"
    readonly property bool stroke: ["arrow", "line", "pen"].includes(kind)
    readonly property var selectedMark: doc ? doc.selectedAnnotation : ({})
    readonly property var style: !doc ? ({}) : label ? doc.labelStyle : selectedMark.type === kind ? selectedMark : doc.toolDefaults[kind] || ({})
    readonly property bool hasFill: label ? style.textStyle !== "shadow" : shape && !!style.filled
    signal beforeOpen()
    text: toolName + " style"
    implicitHeight: 34
    implicitWidth: buttonContent.implicitWidth + leftPadding + rightPadding
    leftPadding: 12; rightPadding: 10; topPadding: 7; bottomPadding: 7
    selected: opened
    tooltipEnabled: !opened
    hint: "Change " + toolName.toLowerCase() + " appearance"
    function close() { editor.close(); }
    function apply(fields) {
        if (label) doc.setLabelStyle(fields);
        else doc.setToolStyle(kind, fields);
    }
    onVisibleChanged: if (!visible) editor.close()
    onKindChanged: editor.close()
    onClicked: {
        if (editor.opened) editor.close();
        else { beforeOpen(); doc.refreshLabelStyle(); editor.open(); }
    }
    contentItem: Item {
        implicitWidth: buttonContent.implicitWidth
        implicitHeight: buttonContent.implicitHeight
        RowLayout {
            id: buttonContent
            anchors.centerIn: parent
            spacing: 8
            Text { textFormat: Text.PlainText; text: control.text; color: control.ink; font: control.font }
            Glyph { name: "chevron"; ink: control.ink; Layout.preferredWidth: 14; Layout.preferredHeight: 14 }
        }
    }
    Popup {
        id: editor
        parent: Overlay.overlay
        width: Math.min(320, parent ? parent.width - 24 : 320)
        height: Math.min(styleColumn.implicitHeight + 36, parent ? parent.height - 24 : 600)
        padding: 16
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        Overlay.modal: Rectangle { color: "transparent" }
        onAboutToShow: {
            inkChoice.custom = false; fillChoice.custom = false; numberChoice.custom = false;
            const point = control.mapToItem(parent, 0, control.height + 6);
            x = Math.max(12, Math.min(parent.width-width-12, point.x));
            y = Math.max(12, Math.min(parent.height-height-12, point.y + height <= parent.height-12 ? point.y : point.y-control.height-height-12));
            styleScroll.contentItem.contentY = 0;
        }
        onHeightChanged: if (opened && parent) y = Math.max(12, Math.min(parent.height-height-12, y))
        background: Rectangle {
            radius: theme.radius
            color: theme.alpha(theme.background, 1)
            border.width: theme.controlBorder.a > 0 ? (2) : 0
            border.color: theme.frame
        }
        contentItem: ScrollView {
            id: styleScroll
            clip: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            contentItem: Flickable {
                contentWidth: width
                contentHeight: styleColumn.implicitHeight + 4
                boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: styleColumn
                    x: 2; y: 2
                    width: parent.width - 12
                    spacing: 14
                    RowLayout {
                        Layout.fillWidth: true
                        Text { textFormat: Text.PlainText; Layout.fillWidth: true; text: control.text; color: theme.text; font.family: theme.fontFamily; font.pixelSize: 16; font.weight: Font.Medium }
                        StudioButton { Layout.preferredWidth: 28; glyph: "close"; quiet: true; implicitHeight: 28; hint: "Close style panel"; onClicked: editor.close() }
                    }
                    Text { textFormat: Text.PlainText; Layout.topMargin: -10; text: control.selectedMark.type === control.kind ? "Selected: " + control.toolName.toLowerCase() : "New " + (control.plurals[control.kind] || "marks"); color: theme.muted; font.family: theme.fontFamily; font.pixelSize: 11 }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72
                        radius: theme.radius
                        color: theme.well
                        clip: true
                        Repeater {
                            model: Math.max(0, Math.ceil(styleColumn.width / 12) * 6)
                            Rectangle {
                                required property int index
                                readonly property int columns: Math.ceil(styleColumn.width / 12)
                                x: index % columns * 12; y: Math.floor(index/columns) * 12
                                width: 12; height: 12
                                color: (index % columns + Math.floor(index/columns)) % 2 ? theme.well : theme.controlFill
                            }
                        }
                        Image {
                            anchors.fill: parent
                            anchors.margins: 4
                            fillMode: Image.PreserveAspectFit
                            cache: false
                            source: control.opened && control.doc ? control.doc.stylePreview(control.kind, Object.assign({}, control.style, {
                                color: inkChoice.preview.toString(), background: fillChoice.preview.toString(), numberColor: numberChoice.preview.toString(),
                                opacity: opacitySlider.value/100, backgroundOpacity: opacitySlider.value/100
                            })) : ""
                        }
                    }
                    ColumnLayout {
                        visible: control.atelierStudio !== null && control.kind !== "blur"
                        Layout.fillWidth: true; spacing: 8
                        Text { textFormat: Text.PlainText; text: "Palette"; color: theme.muted; font.family: theme.fontFamily; font.pixelSize: 12 }
                        ComboBox {
                            id: palettePicker; Layout.fillWidth: true
                            model: control.atelierStudio ? control.atelierStudio.palettes : []
                            textRole: "name"
                            onActivated: { control.paletteColors = model[currentIndex].colors; control.paletteSlot = 0; }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField { id: paletteName; Layout.fillWidth: true; placeholderText: "Save these five colors"; font.pixelSize: 11 }
                            StudioButton {
                                text: "Save"; font.pixelSize: 11; implicitHeight: 30
                                enabled: paletteName.text.trim().length > 0
                                onClicked: {
                                    if (control.atelierStudio.savePalette(paletteName.text, control.paletteColors)) paletteName.text = "";
                                    else paletteName.placeholderText = "Use a new name for the palette";
                                }
                            }
                        }
                    }
                    ColorChoice {
                        id: inkChoice
                        visible: control.kind !== "blur"
                        Layout.fillWidth: true
                        title: control.label ? "Text color" : control.shape ? "Outline color" : control.kind === "step" ? "Circle color" : "Color"
                        swatches: control.atelierStudio ? control.paletteColors.map(c => ({color:c,name:c})) : [{color:"#ffffff",name:"White"},{color:"#151a20",name:"Dark"},{color:"#e75439",name:"Red"},{color:"#eab841",name:"Gold"},{color:"#459ec7",name:"Blue"},{color:"#4ca782",name:"Green"}]
                        value: control.style.color || "#e75439"
                        onChosen: color => control.pickPigment(color)
                        onCustomChanged: if (custom) { fillChoice.custom = false; numberChoice.custom = false; }
                    }
                    ColumnLayout {
                        visible: control.kind === "arrow"
                        Layout.fillWidth: true
                        spacing: 6
                        Text { textFormat: Text.PlainText; text: "Arrowhead"; color: theme.text; font.family: theme.fontFamily; font.pixelSize: 12 }
                        Choice {
                            Layout.fillWidth: true
                            implicitHeight: 30
                            model: ["Open", "Filled"]
                            currentIndex: control.style.arrowHead === "filled" ? 1 : 0
                            onActivated: index => control.apply({arrowHead: index ? "filled" : "open"})
                        }
                    }
                    ColumnLayout {
                        visible: !control.label && control.kind !== "highlight"
                        Layout.fillWidth: true
                        spacing: 4
                        RowLayout {
                            Layout.fillWidth: true
                            Text { textFormat: Text.PlainText; Layout.fillWidth: true; text: control.kind === "blur" ? "Strength" : control.kind === "step" ? "Size" : "Thickness"; color: theme.text; font.family: theme.fontFamily; font.pixelSize: 12 }
                            Text { textFormat: Text.PlainText; text: Number(sizeSlider.value).toFixed(2).replace(/\.?0+$/, "") + "×"; color: theme.muted; font.family: theme.fontFamily; font.pixelSize: 12 }
                        }
                        ThemedSlider {
                            id: sizeSlider
                            Layout.fillWidth: true
                            Accessible.name: control.kind === "blur" ? "Blur strength" : control.kind === "step" ? "Step size" : "Thickness"
                            from: .5; to: 8; stepSize: .25
                            value: control.style.size || 1
                            onCommitted: value => control.apply({size: value})
                        }
                    }
                    RecordToggle {
                        visible: control.stroke
                        Layout.fillWidth: true
                        text: "Contrast outline"
                        checked: control.style.outline || false
                        onToggled: control.apply({outline: checked})
                    }
                    RecordToggle {
                        visible: control.label || control.shape
                        Layout.fillWidth: true
                        text: control.label ? "Text background" : "Fill"
                        checked: control.hasFill
                        onToggled: control.apply(control.label ? {textStyle: checked ? "box" : "shadow"} : {filled: checked})
                    }
                    ColorChoice {
                        id: fillChoice
                        visible: control.hasFill
                        Layout.fillWidth: true
                        title: control.label ? "Background color" : "Fill color"
                        value: control.style.background || "#151a20"
                        onChosen: color => control.apply({background: color.toString()})
                        onCustomChanged: if (custom) { inkChoice.custom = false; numberChoice.custom = false; }
                    }
                    ColorChoice {
                        id: numberChoice
                        visible: control.kind === "step"
                        Layout.fillWidth: true
                        title: "Number color"
                        value: control.style.numberColor || "#ffffff"
                        onChosen: color => control.apply({numberColor: color.toString()})
                        onCustomChanged: if (custom) { inkChoice.custom = false; fillChoice.custom = false; }
                    }
                    ColumnLayout {
                        visible: control.hasFill || control.kind === "highlight" || control.kind === "brush"
                        Layout.fillWidth: true
                        spacing: 4
                        RowLayout {
                            Layout.fillWidth: true
                            Text { textFormat: Text.PlainText; Layout.fillWidth: true; text: control.label ? "Background opacity" : control.shape ? "Fill opacity" : "Opacity"; color: theme.text; font.family: theme.fontFamily; font.pixelSize: 12 }
                            Text { textFormat: Text.PlainText; text: Math.round(opacitySlider.value) + "%"; color: theme.muted; font.family: theme.fontFamily; font.pixelSize: 12 }
                        }
                        ThemedSlider {
                            id: opacitySlider
                            Layout.fillWidth: true
                            Accessible.name: control.label ? "Background opacity" : "Opacity"
                            from: 0; to: 100; stepSize: 1
                            value: (control.label ? control.style.backgroundOpacity ?? 1 : control.style.opacity ?? .2) * 100
                            onCommitted: value => control.apply(control.label ? {backgroundOpacity: value/100} : {opacity: value/100})
                        }
                    }
                    RowLayout {
                        visible: control.label
                        Layout.fillWidth: true
                        spacing: 12
                        ColumnLayout {
                            spacing: 6
                            Text { textFormat: Text.PlainText; text: "Size"; color: theme.text; font.family: theme.fontFamily; font.pixelSize: 12 }
                            NumberField {
                                from: 8; to: 4096
                                value: control.style.fontPx || 32
                                suffix: "px"
                                step: Math.max(1, Math.round(value/12))
                                onCommitted: value => control.apply({fontPx: value})
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Text { textFormat: Text.PlainText; text: "Alignment"; color: theme.text; font.family: theme.fontFamily; font.pixelSize: 12 }
                            Choice {
                                Layout.fillWidth: true
                                implicitHeight: 30
                                model: ["Left", "Center", "Right"]
                                currentIndex: Math.max(0, ["left", "center", "right"].indexOf(control.style.textAlign || "center"))
                                onActivated: index => control.apply({textAlign: ["left", "center", "right"][index]})
                            }
                        }
                    }
                    Text { textFormat: Text.PlainText; Layout.fillWidth: true; text: "This look is remembered for your next marks."; color: theme.faint; font.family: theme.fontFamily; font.pixelSize: 11; wrapMode: Text.Wrap }
                    RowLayout {
                        Layout.fillWidth: true
                        StudioButton { text: "Reset"; quiet: true; implicitHeight: 32; font.pixelSize: 12; onClicked: control.label ? control.doc.resetLabelStyle() : control.doc.resetToolStyle(control.kind) }
                        Item { Layout.fillWidth: true }
                        StudioButton { text: "Done"; primary: true; implicitHeight: 32; font.pixelSize: 12; onClicked: editor.close() }
                    }
                }
            }
        }
    }
}
