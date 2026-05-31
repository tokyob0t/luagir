local xml = require('luagir.utils.xml')

return function(constants)
    local consts = {}

    if not constants then
        return consts
    end

    for _, const in ipairs(constants) do
        local value

        local _type = xml.getXMLType(const.type)

        if _type == 'string' then
            value = string.format('%q', const._attr.value)
        else
            value = const._attr.value
        end

        table.insert(consts, {
            name = const._attr.name,
            value = value,
        })
    end

    return consts
end
