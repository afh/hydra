hotkey.keycodes = hotkey._cachekeycodes()

--- hotkey.bind(mods, key, fn) -> hotkey
--- Shortcut for: return hotkey.new(mods, key, fn):enable()
function hotkey.bind(...)
  return hotkey.new(...):enable()
end

--- hotkey.disableall()
--- Disables all hotkeys; automatically called when user config reloads.
function hotkey.disableall()
  local function ishotkey(hk) return type(hk) == "userdata" end
  fnutils.each(fnutils.filter(hotkey._keys, ishotkey), hotkey.disable)
end
