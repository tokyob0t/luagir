local docSuffix = function(doc, enabled)
    if enabled and doc then
        return ' ' .. doc
    end
    return ''
end

local function buildInherits(parent_classes, suffix)
    local inherits = {}
    for _, parent in ipairs(parent_classes) do
        table.insert(inherits, parent .. '.' .. suffix)
    end
    return #inherits > 0 and ' : ' .. table.concat(inherits, ', ') or ''
end

local M = {}

M.emitDoc = function(doc, indent)
    if not doc then
        return
    end
    for line in doc:gmatch('[^\n]+') do
        SCOPE:append_line(string.format('%s---%s', indent or '', line))
    end
end

function M.emitConstants(constants)
    for _, const in ipairs(constants) do
        SCOPE:append_line()
        SCOPE:append_line(
            string.format('---@alias %s.%s %s', SCOPE.namespace, const.name, const.value)
        )
        SCOPE:append_line(string.format('%s.%s = %s', SCOPE.namespace, const.name, const.value))
    end
end

---@param bitfields luagir.Bitfield[]
function M.emitBitfields(bitfields, docs_enabled)
    for _, bitfield in ipairs(bitfields) do
        SCOPE:append_line()
        SCOPE:append_line(string.format('---@alias %s.%s', SCOPE.namespace, bitfield.name))

        for _, member in ipairs(bitfield.members) do
            if docs_enabled and member.doc then
                M.emitDoc(member.doc)
            end
            SCOPE:append_line(string.format('---| %q %s', member.name, member.value))
        end
    end
end

function M.emitEnumerations(enumerations, docs_enabled)
    for _, enum in ipairs(enumerations) do
        SCOPE:append_line()
        SCOPE:append_line(string.format('---@enum (key) %s.%s', SCOPE.namespace, enum.name))
        SCOPE:append_line(string.format('%s.%s = {', SCOPE.namespace, enum.name))

        for _, member in ipairs(enum.members) do
            if docs_enabled then
                M.emitDoc(member.doc, '   ')
            end
            SCOPE:append_line(string.format('   %s = %s,', member.name, member.value))
        end

        SCOPE:append_line('}')
    end
end

function M.emitFunctions(functions, docs_enabled)
    for _, fn in ipairs(functions) do
        SCOPE:append_line()

        if docs_enabled then
            M.emitDoc(fn.doc)
        end

        local parameters = {}

        for _, param in ipairs(fn.parameters) do
            SCOPE:append_line(
                string.format(
                    '---@param %s %s%s',
                    param.name,
                    param.type,
                    docSuffix(param.doc, docs_enabled)
                )
            )
            table.insert(parameters, param.name)
        end

        if fn['return'] then
            SCOPE:append_line(string.format('---@return %s', fn['return']))
        end

        local parameters_str = table.concat(parameters, ', ')

        SCOPE:append_line(
            string.format('function %s.%s(%s) end', SCOPE.namespace, fn.name, parameters_str)
        )
    end
end

function M.emitClassProperties(ns_name, class, parent_classes, docs_enabled)
    local suffix = buildInherits(parent_classes, 'Properties')

    SCOPE:append_line()
    SCOPE:append_line(string.format('---@class %s.Properties%s', ns_name, suffix))

    for _, prop in ipairs(class.properties) do
        SCOPE:append_line(
            string.format(
                '---@field %s %s%s',
                prop.name,
                prop.type or 'any',
                docSuffix(prop.doc, docs_enabled)
            )
        )
    end
end

function M.emitClassNotifySignals(ns_name, class, parent_classes)
    local suffix = buildInherits(parent_classes, 'NotifySignals')

    SCOPE:append_line()
    SCOPE:append_line(string.format('---@class %s.NotifySignals%s', ns_name, suffix))

    SCOPE:append_line(
        string.format(
            '---@field connect fun(self, callback: fun(self: %s, pspec: GObject.ParamSpec), property?: string, after?: boolean): integer',
            ns_name
        )
    )

    local pspec_sig = string.format('fun(self: %s, pspec: GObject.ParamSpec)', ns_name)

    local field_type =
        string.format('%s | { connect: fun(self, callback: %s): integer }', pspec_sig, pspec_sig)

    for _, prop in ipairs(class.properties) do
        if prop.doc then
            SCOPE:append_line(string.format('---@field %s %s %s', prop.name, field_type, prop.doc))
        else
            SCOPE:append_line(string.format('---@field %s %s', prop.name, field_type))
        end
    end
end

function M.emitClassSignals(ns_name, class, parent_classes, docs_enabled)
    local suffix = buildInherits(parent_classes, 'Signals')

    SCOPE:append_line()
    SCOPE:append_line(string.format('---@class %s.Signals%s', ns_name, suffix))

    for _, signal in ipairs(class.signals) do
        local signal_field = string.format('on_%s', signal.name)
        local cb_params = { string.format('self: %s', ns_name) }
        for _, param in ipairs(signal.parameters or {}) do
            table.insert(cb_params, string.format('%s: %s', param.name, param.type or 'any'))
        end
        local cb_sig = string.format('fun(%s)', table.concat(cb_params, ', '))
        local field_type =
            string.format('%s | { connect: fun(self, callback: %s): integer }', cb_sig, cb_sig)

        if docs_enabled and signal.doc then
            SCOPE:append_line(
                string.format('---@field %s %s %s', signal_field, field_type, signal.doc)
            )
        else
            SCOPE:append_line(string.format('---@field %s %s', signal_field, field_type))
        end
    end

    if #class.properties > 0 then
        SCOPE:append_line(string.format('---@field on_notify %s.NotifySignals', ns_name))
    end
end

function M.emitClassConstructorParams(ns_name, class, parent_classes, docs_enabled)
    local suffix = buildInherits(parent_classes, 'ConstructorParams')

    SCOPE:append_line()
    SCOPE:append_line(string.format('---@class %s.ConstructorParams%s', ns_name, suffix))

    for _, prop in ipairs(class.properties) do
        SCOPE:append_line(
            string.format(
                '---@field %s? %s%s',
                prop.name,
                prop.type or 'any',
                docSuffix(prop.doc, docs_enabled)
            )
        )
    end
end

function M.emitClassMethods(ns_name, methods, docs_enabled)
    for _, method in ipairs(methods) do
        SCOPE:append_line()

        if docs_enabled then
            M.emitDoc(method.doc)
        end

        for _, param in ipairs(method.parameters) do
            SCOPE:append_line(
                string.format(
                    '---@param %s %s%s',
                    param.name,
                    param.type or 'any',
                    docSuffix(param.doc, docs_enabled)
                )
            )
        end

        if method['return'] then
            SCOPE:append_line(string.format('---@return %s', method['return']))
        end

        local param_names = {}

        for _, param in ipairs(method.parameters) do
            table.insert(param_names, param.name)
        end

        local separator = method.separator or ':'

        SCOPE:append_line(
            string.format(
                'function %s%s%s(%s) end',
                ns_name,
                separator,
                method.name,
                table.concat(param_names, ', ')
            )
        )
    end
end

return M
