# Luagir

Lua lib that allows you to build meta files from \*.gir.
Requires [xml2lua](https://github.com/manoelcampos/xml2lua)

### Installation:

```bash
$ luarocks install luagir
```

### Usage:

```bash
$ luagir -D @luagir GioUnix-2.0 Adw-1
GioUnix-2.0
├── GLib-2.0
├── GModule-2.0
├── GObject-2.0
└── Gio-2.0
Adw-1
└── Gtk-4.0
    ├── Gdk-4.0
    │   ├── GdkPixbuf-2.0
    │   ├── Pango-1.0
    │   │   ├── HarfBuzz-0.0
    │   │   │   └── freetype2-2.0
    │   │   └── cairo-1.0
    │   ├── PangoCairo-1.0
    └── Gsk-4.0
        └── Graphene-1.0
```

Then add the autocompletion files in your `.luarc.json` file.

```json
{
  "workspace": {
    "library": ["@luagir"]
  }
}
```

### Tip:

To autoassign the import type, you can use

```lua
---@generic T
---@type { require: fun(gir: `T`, version?: string): T }
local lgi = require('lgi')

local Gtk = lgi.require('Gtk', '3.0') --- Already a Gtk Class
local GObject lgi.require('GObject') --- GObject Class

local App = Gtk.Application.new('org.example.myApplication', 'DEFAULT_FLAGS')

---@type GLib.List<Gdk.Monitor>
local monitors

for _, gdkmonitor in ipairs(monitors) do
    print(gdkmonitor.display)
end
```
