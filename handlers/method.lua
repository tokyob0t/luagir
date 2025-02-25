local helpers = require('helpers')

---@class Method
---@field name string
---@field doc string
---@field parameters {[1]: string, [2]: string, [3]?: string }[]
---@field is_async boolean
---@field return_value string
---@field return_value_doc string
local Method = {}
Method.__index = Method

Method.toString = function(self)
    local params = {}

    for _, value in ipairs(self.parameters) do
        local k, v = table.unpack(value)

        if k == 'self' then
            table.insert(params, 'self')
        else
            table.insert(params, string.format('%s: %s', k, v))
        end
    end

    return ('---@field %s fun(%s): %s %s'):format(
        self.name,
        table.concat(params, ', '),
        self.return_value,
        self.doc
    )
end

---@param class_name string
Method.toStringAsFunction = function(self, class_name)
    local lines, params = {}, {}
    local is_static = true

    if #self.doc > 0 and not DISABLE_COMMENTS then
        table.insert(lines, '')
        table.insert(lines, '---' .. self.doc)
    end

    if #self.doc == 0 and #self.parameters > 1 then
        table.insert(lines, '')
    end

    for _, value in ipairs(self.parameters) do
        local k, v, doc = table.unpack(value)

        if k == 'self' then
            is_static = false
        else
            table.insert(
                lines,
                string.format('---@param %s %s %s', k, v, DISABLE_COMMENTS and doc or '')
            )
            k = string.gsub(k, '%?', '')
            table.insert(params, k)
        end
    end

    table.insert(
        lines,
        string.format('---@return %s #%s', self.return_value, self.return_value_doc)
    )

    if self.is_async then
        table.insert(lines, '---@async')
    end

    local fmt = is_static and 'function %s.%s(%s) end' or 'function %s:%s(%s) end'

    table.insert(lines, string.format(fmt, class_name, self.name, table.concat(params, ', ')))

    return table.concat(lines, '\n')
end

Method.new = function(xml, namespace)
    local new_self = setmetatable({ namespace = namespace }, { __index = Method })
    new_self.name = xml._attr.name
    new_self.doc = helpers.get_docs(xml)
    new_self.parameters = helpers.get_method_params(xml, new_self.namespace)
    new_self.return_value = helpers.get_type(xml['return-value'], new_self.namespace)
    new_self.return_value_doc = helpers.get_docs(xml['return-value'])
    new_self.is_async = false

    if xml.parameters and xml.parameters.parameter then
        if xml.parameters.parameter._attr then
            xml.parameters.parameter = { xml.parameters.parameter }
        end

        for _, value in ipairs(xml.parameters.parameter) do
            if value._attr.scope == 'async' then
                new_self.is_async = true
                break
            end
        end
    end

    return new_self
end

return Method
