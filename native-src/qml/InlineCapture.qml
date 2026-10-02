import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: root
    visible: false
    flags: Qt.FramelessWindowHint
    color: theme.background
    palette.window: theme.background
    palette.windowText: theme.text
    palette.base: theme.well
    palette.text: theme.text
    palette.button: theme.controlFill
    palette.buttonText: theme.text
    palette.highlight: theme.accent
    palette.highlightedText: theme.onAccent
    palette.placeholderText: theme.faint
    title: "Framelet — capturar e criar"
    property string tool: "arrow"
    property bool finishing: false
    property bool codeStarted: false
    readonly property bool typing: canvas.typing || root.activeFocusItem instanceof TextInput || root.activeFocusItem instanceof TextEdit
    onToolChanged: if (tool !== "select") finishing = false
    Binding { target: studio; property: "editing"; value: root.visible && !root.finishing }
    readonly property bool ready: studio.hasImage && !studio.busy && !studio.rendering
    readonly property var tools: [
        {key:"select", label:"Mover", shortcut:"V"},
        {key:"arrow", label:"Seta", shortcut:"A"},
        {key:"box", label:"Caixa", shortcut:"B"},
        {key:"ellipse", label:"Elipse", shortcut:"O"},
        {key:"text", label:"Texto", shortcut:"T"},
        {key:"highlight", label:"Realçar", shortcut:"H"},
        {key:"blur", label:"Desfoque", shortcut:"G"},
        {key:"redact", label:"Ocultar", shortcut:"R"},
        {key:"pen", label:"Caneta", shortcut:"P"},
        {key:"brush", label:"Pincel", shortcut:"D"},
        {key:"step", label:"Número", shortcut:"N"},
        {key:"crop", label:"Recortar", shortcut:"X"}
    ]
    function deliver(save) {
        if (!studio.hasImage || studio.busy || pending) return;
        if (canvas.typing) canvas.commitText();
        // Committing text schedules a preview; deliver after that render finishes.
        pendingSave = save; pending = true;
        delivery.start();
    }
    property bool pending: false
    property bool pendingSave: false
    Timer {
        id: delivery; interval: 40; repeat: true
        onTriggered: if (root.pending && root.ready) {
            stop(); root.pending = false;
            studio.deliverInline(root.pendingSave);
        }
    }
    property bool previewReady: false
    onVisibleChanged: {
        if (visible) {
            tool = "arrow"; pending = false; previewReady = !studio.rendering; finishing = studio.style !== 8 || studio.framing.custom;
            if (codeAtStartup && !codeStarted) { codeStarted=true; Qt.callLater(() => codePanel.open()); }
        }
        else { delivery.stop(); pending = false; }
    }
    Connections {
        target: studio
        function onChanged() { if (!studio.rendering && studio.hasImage) root.previewReady = true; }
    }
    Shortcut { sequence: "Meta+C"; enabled: root.visible && !studio.busy; onActivated: root.deliver(false) }
    Shortcut { sequence: "Meta+S"; enabled: root.visible && !studio.busy; onActivated: root.deliver(true) }
    Shortcut { sequence: "Ctrl+C"; enabled: root.visible && !root.typing && !studio.busy; onActivated: root.deliver(false) }
    Shortcut { sequence: "Ctrl+S"; enabled: root.visible && !root.typing && !studio.busy; onActivated: root.deliver(true) }
    Shortcut { sequence: "E"; enabled: root.visible && !root.typing && !studio.busy && !style.opened && !framePanel.opened && !codePanel.opened; onActivated: framePanel.open() }
    Shortcut {
        sequence: "Escape"; enabled: root.visible && !studio.busy && !style.opened && !framePanel.opened && !codePanel.opened
        onActivated: {
            if (canvas.typing) canvas.commitText();
            else if (root.finishing) root.finishing = false;
            else if (canvas.dragging) canvas.cancelDrag();
            else studio.dismissQuick();
        }
    }
    Shortcut { sequence: "Ctrl+Z"; enabled: root.visible && !root.typing; onActivated: studio.marks.undo() }
    Shortcut { sequence: "Ctrl+Shift+Z"; enabled: root.visible && !root.typing; onActivated: studio.marks.redo() }
    Shortcut { sequence: "Delete"; enabled: root.visible && !root.typing; onActivated: studio.marks.deleteSelected() }
    Repeater {
        model: root.tools
        delegate: Item {
            required property var modelData
            Shortcut {
                sequence: modelData.shortcut
                enabled: root.visible && !root.typing && !studio.busy && !style.opened && !framePanel.opened && !codePanel.opened
                onActivated: root.tool = modelData.key
            }
        }
    }
    Image {
        anchors.fill: parent
        visible: !studio.inlineScroll
        source: root.visible && !studio.inlineScroll && studio.captureMonitor.length ? "image://frames/capture/" + studio.captureMonitor : ""
        cache: false; fillMode: Image.Stretch
    }
    Rectangle { anchors.fill: parent; color: "#88000000" }
    Flickable {
        id: viewport
        x: studio.inlineScroll || root.finishing || root.tool === "crop" ? 24 : studio.inlineArea.x * root.width
        y: studio.inlineScroll || root.finishing || root.tool === "crop" ? 80 : studio.inlineArea.y * root.height
        width: studio.inlineScroll || root.finishing || root.tool === "crop" ? root.width - 48 : studio.inlineArea.width * root.width
        height: studio.inlineScroll || root.finishing || root.tool === "crop" ? root.height - 145 : studio.inlineArea.height * root.height
        clip: true
        interactive: studio.inlineScroll && !canvas.dragging && !canvas.typing
        contentWidth: width
        contentHeight: studio.inlineScroll && preview.implicitWidth > 0 ? Math.max(height, Math.min(width, preview.implicitWidth) * preview.implicitHeight / preview.implicitWidth) : height
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: studio.inlineScroll ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
        Image {
            id: preview
            x: (viewport.width-width)/2
            width: Math.min(viewport.width, implicitWidth || viewport.width); height: viewport.contentHeight
            source: studio.hasImage && root.previewReady ? "image://frames/" + (root.finishing ? "preview" : root.tool === "crop" ? "uncropped" : "source") + "?" + studio.revision : ""
            cache: false; asynchronous: true; retainWhileLoading: true
            fillMode: Image.PreserveAspectFit
            MarkCanvas {
                id: canvas
                anchors.centerIn: parent
                width: preview.paintedWidth; height: preview.paintedHeight
                visible: !root.finishing
                doc: studio.marks; tool: root.tool; locked: studio.busy || root.pending
                workingSize: studio.workingSize; sourceSize: studio.sourceSize
                onToolRequested: key => root.tool = key
            }
        }
    }
    Rectangle {
        id: toolbar
        x: Math.max(12, Math.min(viewport.x + viewport.width / 2 - width / 2, root.width - width - 12))
        y: studio.inlineScroll || root.finishing || root.tool === "crop" ? 14 : viewport.y + viewport.height + height + 12 < root.height - 30 ? viewport.y + viewport.height + 12 : viewport.y > height + 24 ? viewport.y - height - 12 : 14
        width: Math.min(root.width - 24, buttons.implicitWidth + 20)
        height: 54
        color: theme.alpha(theme.background, 1); radius: 12
        border.width: 1; border.color: theme.controlBorder
        RowLayout {
            id: buttons; anchors.fill: parent; anchors.margins: 10
            spacing: 3
            Image { source:"FrameletIcon.svg";Layout.preferredWidth:24;Layout.preferredHeight:24;Layout.leftMargin:3;fillMode:Image.PreserveAspectFit }
            Text { text: "Framelet"; color:theme.text;font.family:theme.fontFamily;font.pixelSize:13;font.weight:Font.DemiBold;Layout.leftMargin:3;Layout.rightMargin:8 }
            Flickable {
                Layout.fillWidth: true; Layout.preferredWidth: toolsRow.implicitWidth
                Layout.preferredHeight: 34; clip:true
                contentWidth: toolsRow.implicitWidth;contentHeight:height
                boundsBehavior:Flickable.StopAtBounds
                RowLayout { id:toolsRow;spacing:3
            Repeater {
                model: root.tools
                StudioButton {
                    required property var modelData
                    text: ""; glyph: modelData.key
                    implicitWidth: 34; implicitHeight: 34
                    padding: 7; quiet: true
                    selected: root.tool === modelData.key
                    hint: modelData.label + " · " + modelData.shortcut
                    Accessible.name: modelData.label
                    onClicked: { root.finishing = false; root.tool = modelData.key; }
                }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 22; Layout.leftMargin: 6; Layout.rightMargin: 6; color: theme.separator }
            ToolStyleButton {
                id: style; atelierStudio: studio; doc: studio.marks; kind: studio.marks.selectedAnnotation.type || root.tool
                text: "Paleta"; hint: "Paletas, cor e espessura"; implicitHeight: 34
                contentItem: RowLayout {
                    spacing: 7
                    Rectangle { width: 10; height: 10; radius: 5; color: style.style.color || theme.accent; Layout.alignment: Qt.AlignVCenter }
                    Text { text: "Paleta"; color: style.ink; font.pixelSize: 12; font.family: theme.fontFamily }
                    Glyph { name: "chevron"; ink: style.ink; Layout.preferredWidth: 12; Layout.preferredHeight: 12 }
                }
            }
            StudioButton { text: ""; glyph: "undo"; quiet: true; implicitWidth: 34; implicitHeight: 34; hint: "Desfazer · Ctrl+Z"; enabled: studio.marks.canUndo; onClicked: studio.marks.undo() }
            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 22; Layout.leftMargin: 6; Layout.rightMargin: 6; color: theme.separator }
                }
            }
            StudioButton { text: "Copiar"; glyph: "copy"; primary: true; implicitHeight: 34; hint: "Super+C"; enabled: !studio.busy; onClicked: root.deliver(false) }
            StudioButton { text: "Salvar"; glyph: "folder"; quiet: true; implicitHeight: 34; hint: "Super+S"; enabled: !studio.busy; onClicked: root.deliver(true) }
            StudioButton { text: ""; glyph: "spark"; quiet: true; implicitWidth: 34; implicitHeight: 34; selected: root.finishing; hint: "Fundo e moldura · E"; enabled: !studio.busy; onClicked: framePanel.open() }
            StudioButton { text: ""; glyph: "image"; quiet: true; implicitWidth: 34; implicitHeight: 34; hint: "Adicionar uma imagem"; onClicked:{addDialog.vertical=false;addDialog.open();} }
            StudioButton { text: ""; glyph: "code"; quiet: true; implicitWidth: 34; implicitHeight: 34; hint: "Criar cartão de código"; onClicked:codePanel.open() }
            StudioButton { text: ""; glyph: "close"; quiet: true; implicitWidth: 34; implicitHeight: 34; hint: "Cancelar · Esc"; enabled: !studio.busy; onClicked: studio.dismissQuick() }
        }
    }
    Popup {
        id: framePanel
        parent: Overlay.overlay
        width: 348; height: Math.min(640, root.height - 110)
        x: Math.max(12, Math.min(parent.width-width-12, toolbar.x+toolbar.width-width))
        y: toolbar.y+toolbar.height+height+12 < root.height ? toolbar.y+toolbar.height+8 : Math.max(12,toolbar.y-height-8)
        padding: 18; focus: true; modal: true
        Overlay.modal: Rectangle { color: "transparent" }
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onAboutToShow: root.finishing = true
        background: Rectangle { color: theme.alpha(theme.background,1); radius: 12; border.width: 1; border.color: theme.controlBorder }
        contentItem: ScrollView {
            clip: true; contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ColumnLayout {
                width: parent.width
                spacing: 14
                Text { text: "Acabamento"; color: theme.text; font.pixelSize: 17; font.family: theme.fontFamily; font.weight: Font.DemiBold }
                Text { text: "Escolha o suporte para a sua captura."; color: theme.muted; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap }
                GridLayout {
                    columns: 2; Layout.fillWidth: true; rowSpacing: 8; columnSpacing: 8
                    Repeater {
                        model: [
                            {name:"Sketchbook",detail:"Papel e textura",color:"#ede5d6"},
                            {name:"Ink",detail:"Escuro e preciso",color:"#22272d"},
                            {name:"Gallery",detail:"Passe-partout claro",color:"#f3efe7"},
                            {name:"Original",detail:"Somente a captura",color:"transparent"}
                        ]
                        StudioButton {
                            required property var modelData
                            Layout.fillWidth: true; implicitHeight: 72; padding: 10
                            selected: studio.framing.finishName===modelData.name || (modelData.name==="Original" && studio.style===8 && !studio.framing.custom)
                            onClicked: { studio.applyFinish(modelData.name); root.finishing=modelData.name!=="Original"; }
                            contentItem: Column {
                                spacing: 4
                                Row { spacing: 7
                                    Rectangle { width:14;height:14;radius:3;color:modelData.color;border.width:1;border.color:theme.controlBorder }
                                    Text { text:modelData.name;color:theme.text;font.family:theme.fontFamily;font.pixelSize:12;font.weight:Font.DemiBold }
                                }
                                Text { text:modelData.detail;color:theme.muted;font.family:theme.fontFamily;font.pixelSize:10 }
                            }
                        }
                    }
                }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["Outros acabamentos", "Papel", "Ardósia", "Profundo", "Aurora", "Adaptativo", "Contorno", "Estúdio", "Ambiente"]
                    onActivated: if(currentIndex>0) { studio.configureFraming({custom:false});studio.style=currentIndex-1;root.finishing=true; }
                }
                CheckBox { text: "Personalizar aparência"; checked: studio.framing.custom; onToggled: { root.finishing=true; studio.configureFraming({custom:checked}); } }
                ColumnLayout {
                    Layout.fillWidth: true; visible: studio.framing.custom; spacing: 10
                    ComboBox {
                        Layout.fillWidth: true; model: ["Gradiente","Cor sólida","Transparente"]
                        currentIndex: ["gradient","solid","transparent"].indexOf(studio.framing.backgroundMode)
                        onActivated: studio.configureFraming({backgroundMode:["gradient","solid","transparent"][currentIndex]})
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; visible: studio.framing.backgroundMode!=="transparent"
                        ColorChoice { Layout.fillWidth: true; value: studio.framing.background; title: "Cor inicial"; onChosen: value => studio.configureFraming({background:String(value)}) }
                        ColorChoice { Layout.fillWidth: true; visible: studio.framing.backgroundMode==="gradient"; value: studio.framing.backgroundEnd; title: "Cor final"; onChosen: value => studio.configureFraming({backgroundEnd:String(value)}) }
                    }
                    Text { text: "Cantos"; color: theme.muted; font.pixelSize: 12 }
                    ThemedSlider { Layout.fillWidth: true; from:0; to:0.15; value:studio.framing.corners; onMoved: studio.configureFraming({corners:value}) }
                    Text { text: "Sombra"; color: theme.muted; font.pixelSize: 12 }
                    ThemedSlider { Layout.fillWidth: true; from:0; to:1; value:studio.framing.shadow; onMoved: studio.configureFraming({shadow:value}) }
                    Text { text: "Respiro dentro da imagem"; color: theme.muted; font.pixelSize: 12 }
                    ThemedSlider { Layout.fillWidth: true; from:0; to:0.15; value:studio.framing.inset; onMoved: studio.configureFraming({inset:value}) }
                    Text { text:"Textura do papel"; color:theme.muted; font.pixelSize:12 }
                    ThemedSlider { Layout.fillWidth:true; from:0;to:1;value:studio.framing.paper;enabled:studio.framing.backgroundMode!=="transparent";onMoved:studio.configureFraming({paper:value}) }
                    CheckBox { text:"Passe-partout"; checked:studio.framing.mat;onToggled:studio.configureFraming({mat:checked}) }
                    CheckBox { text:"Barra de título"; checked:studio.framing.titlebar; onToggled:studio.configureFraming({titlebar:checked}) }
                    TextField { Layout.fillWidth:true; visible:studio.framing.titlebar; text:studio.framing.title; placeholderText:"Título"; onEditingFinished:studio.configureFraming({title:text}) }
                }
                Text { text:"Margem"; color:theme.muted; font.pixelSize:12 }
                ThemedSlider { Layout.fillWidth:true; from:0.02; to:0.22; value:studio.padding; enabled:studio.style!==8 || studio.framing.custom; onMoved:studio.padding=value }
                ComboBox { Layout.fillWidth:true; model:["Proporção original","Quadrado · 1:1","Horizontal · 16:9","Clássico · 4:3","Vertical · 9:16"]; currentIndex:studio.aspect; onActivated:studio.aspect=currentIndex }
                Rectangle { Layout.fillWidth:true; height:1; color:theme.separator }
                Text { text:"Seus presets"; color:theme.text; font.pixelSize:13; font.weight:Font.DemiBold }
                ComboBox { Layout.fillWidth:true; visible:studio.lookNames.length>0; model:studio.lookNames; onActivated:studio.applyLook(currentText) }
                RowLayout {
                    Layout.fillWidth:true
                    TextField { id:lookName; Layout.fillWidth:true; placeholderText:"Nome do preset" }
                    StudioButton { text:"Guardar"; enabled:lookName.text.trim().length>0; onClicked:{studio.saveLook(lookName.text);lookName.text="";} }
                }
                Text { text:"Composição"; color:theme.text; font.pixelSize:13; font.weight:Font.DemiBold }
                RowLayout {
                    StudioButton { text:"Lado a lado"; glyph:"plus"; onClicked:{addDialog.vertical=false;addDialog.open();} }
                    StudioButton { text:"Empilhar"; onClicked:{addDialog.vertical=true;addDialog.open();} }
                }
                StudioButton { text:"Voltar às anotações"; Layout.fillWidth:true; onClicked:{framePanel.close();root.finishing=false;} }
                StudioButton { text:"Pasta das capturas"; glyph:"folder"; Layout.fillWidth:true; quiet:true; onClicked:saveFolder.open() }
            }
        }
    }
    FileDialog {
        id:addDialog
        property bool vertical:false
        title:"Adicionar imagem à composição"
        nameFilters:["Imagens (*.png *.jpg *.jpeg *.webp)"]
        onAccepted:{studio.addImage(selectedFile,vertical);root.finishing=true;}
    }
    FolderDialog {
        id:saveFolder
        title:"Pasta das capturas"
        currentFolder:"file://"+studio.outputDirectory
        onAccepted:studio.setOutputDirectory(selectedFolder)
    }
    Popup {
        id:codePanel; parent:Overlay.overlay
        width:Math.min(720,root.width-40);height:Math.min(510,root.height-80)
        x:(parent.width-width)/2;y:(parent.height-height)/2
        padding:24;modal:true;focus:true
        closePolicy:Popup.CloseOnEscape
        background:Rectangle{color:theme.alpha(theme.background,1);radius:12;border.width:1;border.color:theme.controlBorder}
        onOpened:codeEditor.forceActiveFocus()
        contentItem:ColumnLayout {
            spacing:16
            Text{text:"Cartão de código";color:theme.text;font.pixelSize:20;font.weight:Font.DemiBold}
            Text{text:"Cole o código e aplique o mesmo fundo e moldura da captura.";color:theme.muted;font.pixelSize:12;Layout.fillWidth:true;wrapMode:Text.Wrap}
            ScrollView {
                Layout.fillWidth:true;Layout.fillHeight:true
                TextArea{id:codeEditor;placeholderText:"Seu código aqui…";font.family:"monospace";font.pixelSize:14;wrapMode:TextEdit.NoWrap;selectByMouse:true;tabStopDistance:32}
            }
            RowLayout {
                Layout.fillWidth:true
                ComboBox{id:codeLanguage;model:["txt","javascript","typescript","python","json","bash","rust","go","css","html"];Layout.preferredWidth:150}
                CheckBox{id:codeNumbers;text:"Número das linhas";checked:true}
                Text{text:"Fonte";color:theme.muted;font.pixelSize:12}
                SpinBox{id:codeSize;from:12;to:32;value:16}
                Item{Layout.fillWidth:true}
            }
            RowLayout {
                Layout.fillWidth:true
                StudioButton{text:"Cancelar";quiet:true;onClicked:codePanel.close()}
                Item{Layout.fillWidth:true}
                StudioButton{text:"Criar cartão";primary:true;enabled:codeEditor.text.trim().length>0&&!studio.busy;onClicked:{studio.makeCodeCard(codeEditor.text,codeLanguage.currentText,codeSize.value,codeNumbers.checked);codePanel.close();root.finishing=true;}}
            }
        }
    }
    Rectangle {
        anchors.bottom: parent.bottom; anchors.bottomMargin: 12; anchors.horizontalCenter: parent.horizontalCenter
        width: statusLabel.implicitWidth + 24; height: 28; radius: 7
        color: theme.alpha(theme.background, 0.95)
        Text {
            id: statusLabel; anchors.centerIn: parent; color: theme.muted; font.pixelSize: 11; font.family: theme.fontFamily
            text: studio.busy || root.pending || studio.quickState === "failed" || studio.quickState === "capture-error" ? studio.status : "Super+C copiar    Super+S salvar    Esc cancelar" + (studio.inlineScroll ? "    Role para percorrer" : "")
        }
    }
}
