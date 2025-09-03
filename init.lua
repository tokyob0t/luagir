if not os.getenv('LUAGIR_PATH') then
    CACHE_PATH = os.getenv('HOME') .. '/.cache/luagir'
else
    CACHE_PATH = os.getenv('LUAGIR_PATH')
end

DISABLE_COMMENTS = false
GIR_PATH = '/usr/share/gir-1.0'
LGI_TO_LUA_TYPE = {
    gboolean = 'boolean',
    gint = 'number',
    guint = 'number',
    gint8 = 'number',
    guint8 = 'number',
    gint16 = 'number',
    guint16 = 'number',
    gint32 = 'number',
    guint32 = 'number',
    gint64 = 'number',
    guint64 = 'number',
    none = 'nil',
    gchar = 'string',
    guchar = 'string',
    ['gchar*'] = 'string',
    ['guchar*'] = 'string',
    glong = 'number',
    gulong = 'number',
    glong64 = 'number',
    gulong64 = 'number',
    gfloat = 'number',
    gdouble = 'number',
    gsize = 'number',

    string = 'string',
    GString = 'string',
    utf8 = 'string',
    gpointer = 'any',
    ---
    filename = 'string',
    ['GObject.Callback'] = 'function',
}

os.execute(string.format('mkdir -p %s', CACHE_PATH))

local load_gir = require('handlers.gir')

local is_valid_flag = function(arg)
    return arg == '-h' or arg == '--help' or arg == '--no-comments'
end

for i, arg_value in ipairs(arg) do
    if arg_value == '-h' or arg_value == '--help' then
        print(table.concat({
            'Usage: lua init.lua [options] <Library-1> <Library-2> ...',
            '',
            'Options:',
            '  -h, --help         Show this help message and exit.',
            '  --no-comments      Disable comments in the generated Lua files.',
            '',
            'Examples:',
            '  lua init.lua Gtk-3.0 GLib-2.0 GObject-2.0',
            '  lua init.lua --no-comments Gtk-3.0',
        }, '\n'))
        os.exit(0)
    end

    if arg_value == '--no-comments' then
        DISABLE_COMMENTS = true
        table.remove(arg, i)
    end
end

local filtered_args = {}

for _, arg_value in ipairs(arg) do
    if not is_valid_flag(arg_value) then
        table.insert(filtered_args, arg_value)
    end
end

if #filtered_args == 0 then
    print('Usage: lua init.lua <Library-1> <Library-2> ...')
    print('Example: lua init.lua Gtk-3.0 GLib-2.0 GObject-2.0')
    os.exit(1)
end

for _, lib in ipairs(filtered_args) do
    print('')
    local gir = load_gir(lib)

    if gir then
        gir:saveToFile(('%s/%s.lua'):format(CACHE_PATH, lib))
    else
        print(('\27[31m%s not found.\27[0m'):format(lib))
    end
    print('')
end
