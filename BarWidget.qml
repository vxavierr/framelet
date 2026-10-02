import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "vxavierr.framelet"
    implicitWidth: button.implicitWidth
    implicitHeight: barSize
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
        tooltipText: "Framelet — select and annotate"
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
                    {name:"Select and annotate",mode:"smart"},
                    {name:"Full screen",mode:"fullscreen"},
                    {name:"Scrolling capture",mode:"scroll"},
                    {name:"Code card",mode:"code"},
                    {name:"Record screen",mode:"record"}
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
