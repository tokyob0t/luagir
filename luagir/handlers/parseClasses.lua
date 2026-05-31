local xml = require('luagir.utils.xml')

local parseFunctions = require('luagir.handlers.parseFunctions')

---@alias luagir.Method luagir.Function
---@alias luagir.Property { name: string, value: any, writable: '0'|'1', construct: '0'|'1', default_value: any | nil }
---@alias luagir.Signal { name: string, params: luagir.Parameter[] }
---@alias luagir.Class {
--- name: string,
--- inherits: string[],
--- methods: luagir.Method[],
--- constructors: luagir.Method[],
--- class_methods: luagir.Function[],
--- properties: luagir.Property[],
--- signals: luagir.Signal[] }

---@return string[]
local function getClassParents(class)
    local inherits = {}

    if class._attr.parent then
        table.insert(inherits, class._attr.parent)
    end

    if class.implements then
        for _, impl in ipairs(class.implements) do
            table.insert(inherits, impl._attr.name)
        end
    end

    if class.prerequisite then
        for _, prereq in ipairs(class.prerequisite) do
            table.insert(inherits, prereq._attr.name)
        end
    end

    return inherits
end

---@return luagir.Method[]
local function getClassMethods(class)
    return parseFunctions(class.method)
end

---@return luagir.Function[]
local function getClassFunctions(class)
    local functions = {}

    if class.constructor then
        for _, ctor in ipairs(class.constructor) do
            local name = ctor._attr.name
            local parameters = xml.getXMLParameters(ctor)
            local ret = ctor['return-value'] and xml.getXMLType(ctor['return-value'].type)

            table.insert(functions, {
                name = name,
                parameters = parameters,
                ['return'] = ret,
                doc = xml.extractDoc(ctor),
            })
        end
    end

    if class['function'] then
        for _, fn in ipairs(class['function']) do
            local name = fn._attr.name
            local parameters = xml.getXMLParameters(fn)
            local ret = fn['return-value'] and xml.getXMLType(fn['return-value'].type) or nil

            table.insert(functions, {
                name = name,
                parameters = parameters,
                ['return'] = ret,
                doc = xml.extractDoc(fn),
            })
        end
    end

    return functions
end

---@return luagir.Property[]
local function getClassProps(class)
    local properties = {}

    if class.field then
        for _, field in ipairs(class.field) do
            if field._attr.readable ~= '0' and not field.callback then
                table.insert(properties, {
                    name = xml.sanitizeName(field._attr.name),
                    type = xml.getXMLType(field.type),
                    doc = xml.extractDoc(field),
                })
            end
        end
    end

    if class.property then
        for _, prop in ipairs(class.property) do
            local name = xml.sanitizeName(prop._attr.name)
            local _type = xml.getXMLType(prop.type)

            table.insert(properties, {
                name = name,
                type = _type,
                doc = xml.extractDoc(prop),
            })
        end
    end

    return properties
end

---@return luagir.Signal[]
local function getClassSignals(class)
    local signals = {}

    if class['glib:signal'] then
        for _, signal in ipairs(class['glib:signal']) do
            local name = xml.sanitizeName(signal._attr.name)
            local params = xml.getXMLParameters(signal)

            table.insert(signals, {
                name = name,
                parameters = params,
                doc = xml.extractDoc(signal),
            })
        end
    end

    return signals
end

---@return luagir.Class[]
return function(classes)
    local klasses = {}

    if not classes then
        return klasses
    end

    for _, class in ipairs(classes) do
        local name = class._attr.name

        local inherits = getClassParents(class)
        local props = getClassProps(class)
        local methods = getClassMethods(class)
        local signals = getClassSignals(class)
        local class_methods = getClassFunctions(class)

        table.insert(klasses, {
            name = name,
            methods = methods,
            class_methods = class_methods,
            inherits = inherits,
            properties = props,
            signals = signals,
            doc = xml.extractDoc(class),
        })
    end

    return klasses
end
