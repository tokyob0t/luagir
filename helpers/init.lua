local h = {}

h.get_method_params = function(xml, namespace)
    local tbl = {}
    local param = xml.parameters

    if param and param['instance-parameter'] then
        table.insert(tbl, { 'self', '' })
    end

    if param and param.parameter then
        local params = param.parameter

        if params.type then
            params = { params }
        end

        for _, value in ipairs(params) do
            local name, type_name = value._attr.name, h.get_type(value, namespace)

            local nullable = value._attr.nullable == '1'
            local allow_none = value._attr['allow-none'] == '1'

            -- if nullable and allow_none then
            if nullable then
                name = ('%s?'):format(name)
            end

            if name == 'user_data' then
                table.insert(tbl, { '...', type_name })
            elseif type_name == 'Gio.AsyncReadyCallback' then
                table.insert(
                    tbl,
                    { name, 'fun(source_object: GObject.Object, task: Gio.AsyncResult): any' }
                )
            elseif type_name == 'Gio.DBusSignalCallback' then
                table.insert(tbl, {
                    name,
                    'fun(connection: Gio.DBusConnection, sender_name?:, object_path: string, interface_name: string, signal_name: string, parameters: GLib.Variant, ...: any)',
                })
            else
                table.insert(tbl, { name, type_name })
            end
        end
    end

    return tbl
end

h.get_docs = function(xml)
    if xml and xml.doc and not DISABLE_COMMENTS then
        return string.gsub(xml.doc[1], '%s+', ' ')
    else
        return ''
    end
end

---@param namespace gir
---@return "string" | "number" | "boolean" | "nil" | string
h.get_type = function(xml, namespace)
    if xml and xml.array then
        return ('%s[]'):format(h.get_type(xml.array, namespace))
    elseif xml and xml.type and xml.type.type then
        if #xml.type.type > 0 then -- HashTable
            return ('table<%s, %s>'):format(

                h.get_type({ type = xml.type.type[1] }, namespace),
                h.get_type({ type = xml.type.type[2] }, namespace)
            )
        else -- GList / GSList
            return ('%s[]'):format(h.get_type(xml.type, namespace))
        end
    elseif xml and xml.type then
        local bfield =
            namespace.bitfields[string.format('%s.%s', namespace.name, xml.type._attr.name)]

        if bfield then
            local possible_values = {}

            for _, value in ipairs(bfield.members) do
                table.insert(possible_values, string.format('"%s"', value[1]))
            end

            table.insert(
                possible_values,
                string.format('( %s )[]', table.concat(possible_values, ' | '))
            )

            table.insert(possible_values, 1, bfield.name)

            return table.concat(possible_values, ' | ')
        end

        local lua_type = LGI_TO_LUA_TYPE[xml.type._attr.name]

        if lua_type then
            return lua_type
        elseif string.find(xml.type._attr.name or '', '%.') then
            return xml.type._attr.name
        else
            return string.format('%s.%s', namespace.name, xml.type._attr.name)
        end
    else
        return 'nil'
    end
end

h.get_class_parents = function(xml, namespace)
    local parents = {}

    if xml._attr.parent then
        table.insert(parents, xml._attr.parent)
    end

    if xml.implements then
        for _, value in ipairs(xml.implements) do
            table.insert(parents, value._attr.name)
        end
    end

    for index, value in ipairs(parents) do
        if not string.find(value, '%.') then
            parents[index] = string.format('%s.%s', namespace.name, value)
        end
    end

    return parents
end

h.get_class_methods = function(xml, namespace)
    local Method = require('handlers.method')
    local m = {}

    if xml and xml.method and xml.method._attr then
        xml.method = { xml.method }
    end

    if xml and xml.method then
        for _, value in ipairs(xml.method) do
            table.insert(m, Method.new(value, namespace))
        end
    end

    if xml and xml.constructor and xml.constructor._attr then
        xml.constructor = { xml.constructor }
    end

    if xml and xml.constructor then
        for _, value in ipairs(xml.constructor) do
            table.insert(m, Method.new(value, namespace))
        end
    end

    if xml and xml['function'] and xml['function']._attr then
        xml['function'] = { xml['function'] }
    end

    if xml and xml['function'] then
        for _, value in ipairs(xml['function']) do
            table.insert(m, Method.new(value, namespace))
        end
    end

    return m
end

h.get_class_props = function(xml, namespace)
    local Property = require('handlers.prop')
    local p = {}

    if xml and xml.property and xml.property._attr then
        xml.property = { xml.property }
    end

    if xml and xml.property then
        for _, value in ipairs(xml.property) do
            table.insert(p, Property.new(value, namespace))
        end
    end
    if xml and xml.field and xml.field._attr then
        xml.field = { xml.field }
    end

    if xml and xml.field then
        for _, value in ipairs(xml.field) do
            table.insert(p, Property.new(value, namespace))
        end
    end

    return p
end

h.get_class_signals = function(xml, namespace)
    local Method = require('handlers.method')
    local m = {}

    if xml and xml['glib:signal'] and xml['glib:signal']._attr then
        xml['glib:signal'] = { xml['glib:signal'] }
    end

    if xml and xml['glib:signal'] then
        for _, value in ipairs(xml['glib:signal']) do
            local new_signal = Method.new(value, namespace)

            new_signal.name = ('on_%s'):format(new_signal.name:gsub('%-', '_'))

            table.insert(m, new_signal)
        end
    end

    return m
end

return h
