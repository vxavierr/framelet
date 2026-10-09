import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "vxavierr.framelet"
    implicitWidth: button.implicitWidth
    implicitHeight: barSize
    // Follows Framelet's language setting: language=pt_BR, en or system.
    property string language: ""
    readonly property bool portuguese: language.startsWith("pt")
        || ((language === "" || language === "system") && Qt.locale().name.startsWith("pt"))
    function label(english, portugueseText) { return portuguese ? portugueseText : english }
    FileView {
        path: Quickshell.env("HOME") + "/.config/Framelet/Framelet.conf"
        watchChanges: true
        printErrors: false
        onLoaded: {
            const match = /^language=(.*)$/m.exec(text());
            root.language = match ? match[1].trim() : "";
        }
        onFileChanged: reload()
    }
    function take(mode) {
        menu.open = false;
        root.bar.shell.summon(root.moduleName, JSON.stringify({capture:mode}));
    }
    BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: ""
        opticalSize: Style.bar.iconFont
        tooltipText: root.label("Framelet — select and annotate", "Framelet — selecionar e anotar")
        iconComponent: Item {
            Image {
                anchors.centerIn: parent
                width: Style.font.body
                height: width
                source: Qt.resolvedUrl("assets/framelet.svg")
                sourceSize.width: width
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit
            }
        }
        onPressed: mouseButton => {
            if (mouseButton === Qt.RightButton) menu.open = !menu.open;
            else if (mouseButton === Qt.MiddleButton) root.take("scroll");
            else root.take("smart");
        }
    }
    PopupCard {
        id: menu
        anchorItem: button; bar: root.bar
        contentWidth: menu.fittedContentWidth(Style.space(250))
        contentHeight: menu.fittedContentHeight(body.implicitHeight)
        Column {
            id: body
            width: parent.width; spacing: Style.space(4)
            Repeater {
                model: [
                    {name:root.label("Select and annotate","Selecionar e anotar"),mode:"smart"},
                    {name:root.label("Delayed capture","Captura com atraso"),mode:"delay"},
                    {name:root.label("Full screen","Tela inteira"),mode:"fullscreen"},
                    {name:root.label("Scrolling capture","Captura com rolagem"),mode:"scroll"},
                    {name:root.label("Code card","Cartão de código"),mode:"code"},
                    {name:root.label("Record screen","Gravar a tela"),mode:"record"},
                    {name:root.label("History","Histórico"),mode:"history"}
                ]
                Rectangle {
                    required property var modelData
                    width: body.width; height: Style.space(38); radius: Style.cornerRadius
                    color: hover.hovered ? Color.accent : "transparent"
                    Text { anchors.left:parent.left; anchors.leftMargin:Style.space(10); anchors.verticalCenter:parent.verticalCenter; text:parent.modelData.name; color:Color.popups.text; font.family:Style.font.family; font.pixelSize:Style.font.body }
                    HoverHandler {id:hover}
                    TapHandler {onTapped:root.take(parent.modelData.mode)}
                }
            }
        }
    }
}
