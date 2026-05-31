---@generic T
---@type { require: fun(gir: `T`, version?: string): T }
local lgi = require('LuaGObject')

local Gtk = lgi.require('Gtk', '3.0')

local App = Gtk.Application.new('org.example.MyApplication', 'DEFAULT_FLAGS')

function App:on_activate()
    local window = self.active_window

    if not window then
        window = Gtk.ApplicationWindow {
            application = self,
        }
    end

    window:present()
end

App:run(arg)
