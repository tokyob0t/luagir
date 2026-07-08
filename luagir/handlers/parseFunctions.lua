local xml = require('luagir.utils.xml')

---@alias luagir.Function { name: string, parameters: luagir.Parameter[], return?: string, doc?: string }

---@return luagir.Function[]
return function(functions)
    local fns = {}

    if not functions then
        return fns
    end

    ---@type (luagir.Function | { finish_func: string })[]
    local functions_async = {}

    ---@type luagir.Function[]
    local functions_async_finish = {}

    for _, fn in ipairs(functions) do
        if fn._attr.introspectable ~= '0' then
            local name = fn._attr.name
            local params = xml.getXMLParameters(fn)
            local ret = fn['return-value']
                and xml.getXMLType(fn['return-value'].type or fn['return-value'])

            local f = {
                name = name,
                parameters = params,
                ['return'] = ret,
                doc = xml.extractDoc(fn),
            }

            table.insert(fns, f)
            SCOPE.functions[name] = f

            if name:sub(-6) == '_async' or fn._attr['glib:finish-func'] then
                f.finish_func = fn._attr['glib:finish-func']
                functions_async[name] = f
            end

            if name:sub(-7) == '_finish' then
                functions_async_finish[name] = f
            end
        end
    end

    for _, async_fn in pairs(functions_async) do
        local finish_fn = functions_async_finish[async_fn.finish_func]

        if finish_fn then
            if finish_fn['return'] then
                local cb_type = string.format(
                    'Gio.AsyncReadyCallback<Gio.AsyncResult<%s>>',
                    finish_fn['return']
                )

                for _, param in ipairs(async_fn.parameters) do
                    if param.name == 'callback' then
                        local nullable = param.type:sub(-1) == '?'
                        param.type = cb_type .. (nullable and '?' or '')
                        break
                    end
                end
            end

            local params = {}

            for _, param in ipairs(async_fn.parameters) do
                if param.name ~= 'callback' and param.name ~= 'user_data' then
                    params[#params + 1] = {
                        name = param.name,
                        type = param.type,
                        optional = param.optional,
                        nullable = param.nullable,
                        direction = param.direction,
                    }
                end
            end

            local sync_name = 'async_' .. async_fn.name:gsub('_async$', '')

            local wrapper = {
                name = sync_name,
                parameters = params,
                ['return'] = finish_fn['return'],
                doc = async_fn.doc,
            }

            table.insert(fns, wrapper)
            SCOPE.functions[sync_name] = wrapper
        end
    end

    return fns
end
