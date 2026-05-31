local xml = require('luagir.utils.xml')

---@alias luagir.Member { name: string, value: number|string, doc: string? }

---@alias luagir.Enum { name: string, cname: string, members: luagir.Member[] }

---@return luagir.Enum[]
return function(enumerations)
    local enums = {}

    if not enumerations then
        return enums
    end

    for _, enum in ipairs(enumerations) do
        local members = {}

        for _, member in pairs(enum.member) do
            table.insert(members, {
                name = member._attr.name:upper(),
                value = member._attr.value,
                doc = xml.extractDoc(member),
            })
        end

        table.insert(enums, {
            name = enum._attr.name,
            cname = enum._attr['c:type'],
            members = members,
        })
    end

    return enums
end
