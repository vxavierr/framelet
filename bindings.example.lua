-- Merge into ~/.config/hypr/bindings.lua after its existing hl/Omarchy imports.
-- Use the same bind helper as the rest of your personal configuration.
-- Example launch command for Print: omarchy-shell shell summon vxavierr.framelet '{"capture":"smart"}'
-- Keep one binding for Print; adapt this key if another screenshot binding already owns it.
hl.bind("PRINT", function()
  hl.dispatch(hl.dsp.exec_cmd([[omarchy-shell shell summon vxavierr.framelet '{"capture":"smart"}']]))
end, { description = "Framelet capture" })
-- Shift+Print waits 3, 5 or 10 seconds (the last choice) so menus and hover states stay open.
hl.bind("SHIFT + PRINT", function()
  hl.dispatch(hl.dsp.exec_cmd([[omarchy-shell shell summon vxavierr.framelet '{"capture":"delay"}']]))
end, { description = "Framelet delayed capture" })

hl.define_submap("framelet", function()
  local function chord(key)
    return function()
      hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = key, state = "down" }))
      hl.timer(function()
        hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = key, state = "up" }))
      end, { timeout = 50, type = "oneshot" })
    end
  end
  hl.bind("SUPER + C", chord("C"), { description = "Copy Framelet capture" })
  hl.bind("SUPER + S", chord("S"), { description = "Save Framelet capture" })
  hl.bind("SUPER + V", chord("V"), { description = "Paste text" })
end)
