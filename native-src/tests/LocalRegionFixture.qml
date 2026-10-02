import QtQuick
import QtQuick.Window
Window {
    visible: true; width: 1000; height: 720
    title: "Captura — fixture de recorte"
    color: "#fafaf7"
    Rectangle { x: 320; y: 160; width: 760; height: 400; color: "transparent"; border.width: 5; border.color: "#3972aa" }
    Text { x: 450; y: 350; text: "Selecionar → anotar → salvar"; font.pixelSize: 24; color: "#17212b" }
}
