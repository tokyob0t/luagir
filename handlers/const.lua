local helpers = require('helpers')

---@class Const
---@field name string
---@field value string
---@field doc string[]
local Const = {}
Const.__index = Const

Const.new = function(xml, namespace)
    local new_self = setmetatable({
        name = string.format('%s.%s', namespace.name, xml._attr.name),
        value = xml._attr.value,
        doc = helpers.get_docs(xml),
        namespace = namespace,
    }, { __index = Const })

    if helpers.get_type(xml, namespace) == 'string' then
        new_self.value = string.format('"%s"', new_self.value)
    end

    return new_self
end

Const.toString = function(self)
    local name = string.gsub(self.name, '%.', '')

    if self.doc ~= '' then
        return string.format('local %s = %s --- %s', name, self.value, self.doc)
    else
        return string.format('local %s = %s', name, self.value)
    end
end

return Const
