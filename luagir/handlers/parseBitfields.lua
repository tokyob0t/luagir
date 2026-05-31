local xml = require('luagir.utils.xml')

---@alias luagir.Bitfield { name: string, ctype: string, members: luagir.Member[] }

---@return luagir.Bitfield[]
return function(bitfields)
    local bfields = {}

    if not bitfields then
        return bfields
    end

    for _, bitfield in ipairs(bitfields) do
        local members = {}

        for _, member in pairs(bitfield.member) do
            table.insert(members, {
                name = member._attr.name:upper(),
                value = member._attr.value,
                doc = xml.extractDoc(member),
            })
        end

        local b = {
            name = bitfield._attr.name,
            ctype = bitfield._attr['c:type'],
            members = members,
        }

        table.insert(bfields, b)

        SCOPE.bitfields[string.format('%s.%s', SCOPE.namespace, bitfield._attr.name)] = b
    end

    return bfields
end
