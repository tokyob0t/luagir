local LGI_TO_LUA_TYPE = {
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
    filename = 'string',
    ['GObject.Callback'] = 'function',
}

local function getTypeOverride(fullname)
    local repo = SCOPE.repository

    if not repo then
        return
    end

    if not repo.override then
        return
    end

    if not repo.override.classes then
        return
    end

    return repo.override.classes[fullname]
end

local M = {}

function M.extractDoc(element)
    if not element or not element.doc then
        return
    end

    local doc = element.doc[1]

    local docs = {}

    for line in string.gmatch(doc, '[^\n]+') do
        line = string.gsub(line, '%s+', ' ')

        if string.sub(line, 1, 1) == ' ' then
            line = string.sub(line, 2)
        end

        table.insert(docs, string.format('--- %s', line))
    end

    if #docs == 1 then
        docs[1] = docs[1]:sub(5)
    else
        table.insert(docs, 1, '#')
    end

    return table.concat(docs, '\n')
end

---@param ctype string
---@return string?
function M.getType(ctype)
    if not ctype then
        return
    end

    if LGI_TO_LUA_TYPE[ctype] then
        return LGI_TO_LUA_TYPE[ctype]
    end

    if not string.find(ctype, '%.') then
        return string.format('%s.%s', SCOPE.namespace, ctype)
    end

    return ctype
end

function M.getXMLType(xml)
    if not xml then
        return
    end

    if xml.array then
        return string.format('%s[]', M.getXMLType(xml.array.type))
    end

    if not xml._attr or xml._attr.introspectable == '0' then
        return 'unknown'
    end

    local base_type = M.getType(xml._attr.name)

    local override = getTypeOverride(base_type)

    if override then
        base_type = type(override) == 'string' and override or base_type
    end

    -- Collect generic/container type parameters (e.g. GLib.List<Gtk.Widget>)
    local child_types = {}

    if xml.type then
        if xml.type._attr then
            table.insert(child_types, M.getXMLType(xml.type))
        else
            for _, child in ipairs(xml.type) do
                table.insert(child_types, M.getXMLType(child))
            end
        end
    end

    if xml._attr.name then
        ---@type luagir.Bitfield?
        local bitfield = SCOPE.bitfields[xml._attr.name]
            or SCOPE.bitfields[string.gsub(xml._attr.name, SCOPE.namespace .. '%.', '')]

        if bitfield then
            return string.format('%s.%s[]', SCOPE.namespace, bitfield.name)
        end
    end

    if #child_types > 0 then
        return string.format('%s<%s>', base_type, table.concat(child_types, ', '))
    end

    return base_type
end

function M.sanitizeName(name)
    return string.gsub(name, '%-', '_')
end

---@alias luagir.Parameter { name: string, type: string, doc: string? }

---@return luagir.Parameter[]
function M.getXMLParameters(xml)
    local args = {}

    if not (xml.parameters and xml.parameters[1]) then
        return args
    end

    local params = xml.parameters[1].parameter

    if not params then
        return args
    end

    for _, param in ipairs(params) do
        if param.type then
            local name = param._attr.name
            local _type

            if name == '...' then
                _type = 'any'
            else
                _type = M.getXMLType(param.type)
            end

            if param._attr.nullable == '1' then
                _type = _type .. '?'
            end

            table.insert(args, { name = name, type = _type, doc = M.extractDoc(param) })
        end
    end

    return args
end
return M
