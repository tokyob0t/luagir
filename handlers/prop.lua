local helpers = require('helpers')
---@class Property
---@field name string
---@field value_type string
---@field in_constructor boolean
---@field doc string
---@field writable boolean
local Property = {}
Property.__index = Property

Property.new = function(xml, namespace)
    local new_self = setmetatable({}, { __index = Property })

    new_self.name = string.gsub(xml._attr.name, '%-', '_')
    new_self.in_constructor = xml._attr.construct == '1'
    new_self.writable = xml._attr.writable == '1'
    new_self.value_type = helpers.get_type(xml, namespace)
    new_self.doc = helpers.get_docs(xml)

    return new_self
end

Property.toString = function(self)
    if self.writable then
        return string.format('---@field %s %s r/w %s', self.name, self.value_type, self.doc)
    else
        return string.format('---@field %s %s r %s', self.name, self.value_type, self.doc)
    end
end

return Property
