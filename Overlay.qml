import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property var shell: null
    property var manifest: null
    property string omarchyPath: ""
    property bool opened: false
    readonly property string launcher: Quickshell.env("HOME") + "/.config/omarchy/plugins/vxavierr.framelet/bin/framelet"
    Process { id: capture; command: [root.launcher] }
    function open(payloadJson) {
        let p = {};
        try { p = JSON.parse(payloadJson || "{}"); } catch(e) {}
        let command = [root.launcher];
        if (p.path) command.push("--inline", String(p.path));
        else if (p.capture === "code") command.push("--code");
        else if (p.capture === "scroll") command.push("--scroll");
        else if (p.capture === "fullscreen") command.push("--screen");
        else if (p.capture === "record") command.push("--record");
        if (capture.running) return "busy";
        capture.command = command;
        capture.running = true;
        return "ok";
    }
    function close() { opened = false; }
    function toggle(payloadJson) { return open(payloadJson); }
}
