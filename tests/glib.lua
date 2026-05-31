---@type GLib.List<Gdk.Monitor>
local monitors

for _, gdkmonitor in ipairs(monitors) do
    print(gdkmonitor.display)
end

---@type GLib.HashTable<string, Gdk.Monitor>
local hashtable

local mon = hashtable['dummy-key-oasdhbdsfjsbckfhbasjhdbfcgajsdbfjahscdf']

print(mon.model)

---@alias myEnum { [any]: "FIRST_VALUE"|"SECOND_VALUE"|"THIRD_VALUE", FIRST_VALUE: 1, SECOND_VALUE: 2, THIRD_VALUE: 3 }

---@param p myEnum
local function myFunction(p) end

myFunction {
    'FIRST_VALUE',
    'SECOND_VALUE',
}

---@type myEnum
local p

-- p.FIRST_VALUE
