---@class Enumeration
---@field name string
---@field members {[1]: string, [2]: any}[]
local Enumeration = {}
Enumeration.__index = Enumeration

Enumeration.new = function(xml, namespace)
    local new_self = setmetatable(
        { name = string.format('%s.%s', namespace.name, xml._attr.name), members = {} },
        { __index = Enumeration }
    )

    for _, mmber in ipairs(xml.member) do
        table.insert(new_self.members, { string.upper(mmber._attr.name), mmber._attr.value })
    end

    return new_self
end

Enumeration.toString = function(self)
    local lines = {}
    table.insert(lines, string.format('---@enum (key) %s', self.name))
    table.insert(lines, string.format('local %s = {', string.gsub(self.name, '%.', '')))

    for _, member in ipairs(self.members) do
        local key, value = table.unpack(member)
        table.insert(lines, string.format('   %s = %s,', key, value))
    end
    table.insert(lines, '}')

    return table.concat(lines, '\n')
end

return Enumeration
