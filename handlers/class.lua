local helpers = require('helpers')

---@class Class
---@field name string
---@field parent string[]
---@field methods Method[]
---@field properties Property[]
---@field signals Method[]
---@field ctor_args {[1]: string, [2]: string}[]
---@field doc string
local Class = {}
Class.__index = Class

Class.new = function(xml, namespace)
    local new_self = setmetatable({}, { __index = Class })

    new_self.namespace = namespace
    new_self.name = string.format('%s.%s', namespace.name, xml._attr.name)
    new_self.doc = helpers.get_docs(xml)
    new_self.parent = helpers.get_class_parents(xml, namespace)
    new_self.methods = helpers.get_class_methods(xml, namespace)
    new_self.properties = helpers.get_class_props(xml, namespace)
    new_self.signals = helpers.get_class_signals(xml, namespace)
    new_self.ctor_args = {}

    for _, value in pairs(new_self.properties) do
        if value.in_constructor or value.writable then
            table.insert(new_self.ctor_args, { value.name, value.value_type })
        end
    end

    return new_self
end

Class.toString = function(self)
    local lines = {}
    local class_name = string.gsub(self.name, '%.', '')
    local ctor_name = string.format('%sConstructor', class_name)

    local formatted = {}

    for _, value in ipairs(self.ctor_args) do
        local k, v = table.unpack(value)
        table.insert(formatted, string.format('%s: (%s)', k, v))
    end

    local ctors = {}

    if #self.parent > 0 then
        for _, value in ipairs(self.parent) do
            table.insert(ctors, string.format('%sConstructor', string.gsub(value, '%.', '')))
        end
    end

    local fmt = '---@alias %s { %s }' .. (#ctors > 0 and ' | %s' or '')

    table.insert(
        lines,
        string.format(fmt, ctor_name, table.concat(formatted, ', '), table.concat(ctors, ' | '))
    )

    table.insert(lines, '')

    if #self.doc > 0 and not DISABLE_COMMENTS then
        table.insert(lines, string.format('---%s', self.doc))
    end

    if #self.parent > 0 then
        table.insert(
            lines,
            string.format('---@class %s: %s', self.name, table.concat(self.parent, ', '))
        )
    else
        table.insert(lines, string.format('---@class %s', self.name))
    end

    for _, v in ipairs(self.properties) do
        table.insert(lines, v:toString())
    end

    for _, v in ipairs(self.signals) do
        table.insert(v.parameters, 1, { 'self', self.name })
        table.insert(lines, v:toString())
    end

    table.insert(lines, string.format('---@overload fun(args: %s ): %s', ctor_name, self.name))
    table.insert(lines, string.format('local %s = {}', class_name))

    for _, v in ipairs(self.methods) do
        table.insert(lines, v:toStringAsFunction(class_name))
    end

    return table.concat(lines, '\n')
end

return Class
