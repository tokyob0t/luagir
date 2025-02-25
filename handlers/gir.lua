local handler = require('xmlhandler.tree')

local Bitfield = require('handlers.bitfields')
local Class = require('handlers.class')
local Const = require('handlers.const')
local Enum = require('handlers.enum')
local Method = require('handlers.method')

local print_start = function(message)
    io.write(message .. '... ')
    io.flush()
end

local print_done = function()
    io.write('\27[32mDone\27[0m\n')
    io.flush()
end

local print_error = function()
    io.write('\27[31mFailed\27[0m\n')
    io.flush()
end

---@class gir
---@field classes Class[]
---@field consts table<string, Const>
---@field bitfields table<string, Bitfield>
---@field enumerations table<string, Enumeration>
---@field functions table<string, Method>
---@field xml unknown
---@field name string
---@field version string
local gir = {}
gir.__index = gir

-- Modificaciones en las funciones del gir
gir.loadFile = function(self, filepath)
    print_start('Opening file')
    local file = io.open(filepath, 'r')
    if not file then
        print_error()
        return nil
    end

    local content = file:read('a')
    file:close()
    print_done()
    return content
end

gir.loadXML = function(self, str)
    print_start('Reading XML')
    local new_handler = handler:new()
    local xml2lua = require('xml2lua')
    local parser = xml2lua.parser(new_handler)
    parser:parse(str)
    print_done()
    return new_handler.root
end

gir.addClass = function(self, xml)
    local class = Class.new(xml, self)
    self.classes[class.name] = class
end

gir.addConst = function(self, xml)
    local const = Const.new(xml, self)
    self.consts[const.name] = const
end

gir.addBitfield = function(self, xml)
    local bfield = Bitfield.new(xml, self)
    self.bitfields[bfield.name] = bfield
end

gir.addEnum = function(self, xml)
    local enum = Enum.new(xml, self)
    self.enumerations[enum.name] = enum
end

gir.addFunc = function(self, xml)
    local fun = Method.new(xml, self)
    self.functions[fun.name] = fun
end

gir.saveToFile = function(self, path)
    print_start('Opening file')
    local file = io.open(path, 'w')
    if not file then
        print_error()
        return false
    end
    print_done()

    local content = self:toString()
    print_start('Saving content')
    file:write(content)
    file:close()
    print_done()
    return true
end

gir.toString = function(self)
    print_start('Generating types')
    local lines = { '---@meta _', '' }

    -- Define bitfields, enums, and classes
    for _, value in ipairs { self.consts, self.bitfields, self.enumerations, self.classes } do
        for _, v in pairs(value) do
            table.insert(lines, v:toString())
            table.insert(lines, '')
        end
    end
    table.insert(lines, '')

    -- Define namespace constants and static methods
    table.insert(lines, string.format('---@class %s', self.name))

    for _, value in pairs(self.classes) do
        table.insert(
            lines,
            string.format('---@field %s %s', string.gsub(value.name, '^[^.]+%.', ''), value.name)
        )
    end

    for _, value in pairs(self.functions) do
        table.insert(lines, value:toString())
    end

    -- Append enums, bitfields to namespace tbl
    table.insert(lines, string.format('local %s = {', self.name))

    for _, value in ipairs { self.enumerations, self.bitfields, self.consts } do
        for _, v in pairs(value) do
            local k, _v = string.gsub(v.name, '^[^.]+%.', ''), string.gsub(v.name, '%.', '')
            table.insert(lines, string.format('    %s = %s,', k, _v))
        end
    end

    table.insert(lines, '}')
    print_done()
    return table.concat(lines, '\n')
end

---@param tbl table
---@return number
local len = function(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

return function(libname)
    local new_gir = setmetatable({
        classes = {},
        consts = {},
        bitfields = {},
        enumerations = {},
        functions = {},
    }, { __index = gir })

    new_gir.name, new_gir.version = string.match(libname, '^(.-)%-(.+)$')

    local content = new_gir:loadFile(string.format('%s/%s.gir', GIR_PATH, libname))

    if not content then
        return
    end

    local xml = new_gir:loadXML(content)

    if not xml then
        return
    end

    new_gir.xml = xml

    io.write(string.format('Parsing %s...', libname))

    for _, element in ipairs {
        { key = 'bitfield', method = 'addBitfield' },
        { key = 'constant', method = 'addConst' },
        { key = 'enumeration', method = 'addEnum' },
        --
        { key = 'class', method = 'addClass' },
        { key = 'interface', method = 'addClass' },
        { key = 'record', method = 'addClass' },
        { key = 'function', method = 'addFunc' },
    } do
        local data = new_gir.xml.repository.namespace[element.key]

        if data and data._attr and data._attr.name then
            data = { data }
        end

        if data and #data > 0 then
            for _, value in ipairs(data) do
                new_gir[element.method](new_gir, value)
            end
        end
    end

    print_done()
    print(string.format('  | %d Classes', len(new_gir.classes)))
    print(string.format('  | %d Constants', len(new_gir.consts)))
    print(string.format('  | %d Bitfields', len(new_gir.bitfields)))
    print(string.format('  | %d Enumerations', len(new_gir.enumerations)))
    print(string.format('  | %d Functions', len(new_gir.functions)))

    return new_gir
end
