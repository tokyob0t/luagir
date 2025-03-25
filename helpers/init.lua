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

            if value._attr.nullable == '1' then
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
    if not xml then
        return 'nil'
    end

    if xml.array then
        return ('%s[]'):format(h.get_type(xml.array, namespace))
    elseif xml.type then
        if xml.type.type then
            return #xml.type.type > 0
                    and ('table<%s, %s>'):format(
                        h.get_type({ type = xml.type.type[1] }, namespace),
                        h.get_type({ type = xml.type.type[2] }, namespace)
                    )
                or ('%s[]'):format(h.get_type(xml.type, namespace))
        end

        local bfield =
            namespace.bitfields[string.format('%s.%s', namespace.name, xml.type._attr.name)]
        if bfield then
            local possible_values = { bfield.name }
            for _, value in ipairs(bfield.members) do
                table.insert(possible_values, string.format('"%s"', value[1]))
            end
            table.insert(
                possible_values,
                string.format('table<integer, %s>', table.concat(possible_values, ' | '))
            )
            return table.concat(possible_values, ' | ')
        end

        local lua_type = LGI_TO_LUA_TYPE[xml.type._attr.name]
        return lua_type
            or (string.find(xml.type._attr.name or '', '%.') and xml.type._attr.name)
            or string.format('%s.%s', namespace.name, xml.type._attr.name)
    end

    return 'nil'
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
    local method_return_value = {}

    for _, key in ipairs { 'method', 'constructor', 'function' } do
        if xml and xml[key] then
            if xml[key]._attr then
                xml[key] = { xml[key] }
            end

            for _, value in ipairs(xml[key]) do
                local method = Method.new(value, namespace)
                table.insert(m, method)

                if string.find(method.name, '_async$') then
                    local meth = h.transform_method_async(Method.new(value, namespace))

                    local method_name = string.gsub(method.name, '_async', '')

                    if method_return_value[method_name] then
                        meth.return_value = method_return_value[method_name]
                    end

                    table.insert(m, meth)
                else
                    method_return_value[method.name] = method.return_value
                end
            end
        end
    end

    return m
end

---@param method Method
h.transform_method_async = function(method)
    method.name = string.format('async_%s', string.sub(method.name, 1, -7)) -- remove '_async'

    local new_params = {}

    for _, value in ipairs(method.parameters) do
        if
            not (value[1] == 'io_priority' or value[1] == 'cancellable?' or value[1] == 'callback?')
        then
            table.insert(new_params, value)
        end
    end

    method.parameters = new_params

    return method
end

h.get_class_props = function(xml, namespace)
    local Property = require('handlers.prop')
    local p = {}

    for _, key in ipairs { 'property', 'field' } do
        if xml and xml[key] then
            if xml[key]._attr then
                xml[key] = { xml[key] }
            end
            for _, value in ipairs(xml[key]) do
                table.insert(p, Property.new(value, namespace))
            end
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
