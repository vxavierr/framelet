import QtQuick
import QtQuick.Controls.Basic

ToolTip {
    id: control
    contentItem: Text {
        textFormat: Text.PlainText
        objectName: "literalTooltipText"
        text: control.text
        font: control.font
        wrapMode: Text.Wrap
        color: control.palette.toolTipText
    }
}
