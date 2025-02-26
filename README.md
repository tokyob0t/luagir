# Luagir

Lua script that allows you to build meta files from \*.gir.  
Requires [xml2lua](https://github.com/manoelcampos/xml2lua)

### Usage:

```bash
lua init.lua Gtk-3.0 GLib-2.0 GObject-2.0
```

Then add the autocompletion files in your `.luarc.json` file.

```json
{
  "workspace": {
    "library": ["~/.cache/luagir/"]
  }
}
```

### Tip:

To autoassign the import type, you can use

```lua
local lgi = require("lgi")

---@generic T
---@type fun(name: `T`, version?: string): T
lgi.require = lgi.require

local Gtk = lgi.require("Gtk", "3.0") --- Already a Gtk Class
local GObject lgi.require("GObject")
```
