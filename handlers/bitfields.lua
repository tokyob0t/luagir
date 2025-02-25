local helpers = require('helpers')
---@class Bitfield
---@field name string
---@field members {[1]: string, [2]: number, [3]?: string}[]
local Bitfield = {}
Bitfield.__index = Bitfield

Bitfield.new = function(xml, namespace)
    local new_self = setmetatable({}, { __index = Bitfield })

    new_self.name = string.format('%s.%s', namespace.name, xml._attr.name)
    new_self.members = {}

    if xml.member and xml.member._attr and xml.member._attr.name then
        xml.member = { xml.member }
    end

    for _, member in pairs(xml.member) do
        table.insert(
            new_self.members,
            { string.upper(member._attr.name), member._attr.value, helpers.get_docs(member) }
        )
    end

    return new_self
end

Bitfield.toString = function(self)
    local lines = {}
    table.insert(lines, string.format('---@enum %s', self.name))
    table.insert(lines, string.format('local %s = {', string.gsub(self.name, '%.', '')))
    for _, value in ipairs(self.members) do
        if value[3] ~= '' then
            table.insert(lines, string.format('    ---%s', value[3]))
        end
        table.insert(lines, string.format('    %s = %s,', value[1], value[2]))
    end

    table.insert(lines, '}')

    return table.concat(lines, '\n')
end

return Bitfield
