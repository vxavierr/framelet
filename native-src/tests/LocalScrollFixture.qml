import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
Window {
    visible: true; width: 1000; height: 720
    title: "Captura — fixture de rolagem"
    color: "#f5f5ef"
    Flickable {
        id: flick
        anchors.fill: parent; contentWidth: width; contentHeight: rows.height
        clip: true; boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOn }
        Column {
            id: rows; width: parent.width
            Repeater {
                model: 60
                Rectangle {
                    required property int index
                    width: rows.width; height: 72
                    color: Qt.hsla((index * 0.137) % 1, 0.23, 0.87, 1)
                    Repeater { model: 24; Rectangle { required property int index; x: 780 + index*34; y: 8; width: 24; height: 56; color: Qt.hsla(((parent.index*97 + index*13)%113)/113,0.5,0.5,1) } }
                    Rectangle { x: 40; y: 24; width: 400 + (parent.index % 5)*35; height: 24; color: Qt.hsla(parent.index / 60,0.7,0.5,1) }
                    Text { x: 620; y: 25; text: "Linha " + (parent.index+1); font.pixelSize: 20; color: "#17212b" }
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: wheel => {
                flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, flick.contentY - wheel.angleDelta.y));
                wheel.accepted = true;
            }
        }
    }
}
