---@type GLib.List<Gdk.Monitor>
local monitors

for _, gdkmonitor in ipairs(monitors) do
    print(gdkmonitor.display)
end

---@type GLib.HashTable<string, Gdk.Monitor>
local hashtable

local mon = hashtable['dummy-key-oasdhbdsfjsbckfhbasjhdbfcgajsdbfjahscdf']

print(mon.model)
