# Luagir

Lua script that allows you to build meta files from \*.gir.

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
