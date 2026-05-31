local file = require('luagir.utils.file')
local print_utils = require('luagir.utils.print')
local repository = require('luagir.utils.repository')

local parseBitfields = require('luagir.handlers.parseBitfields')
local parseClasses = require('luagir.handlers.parseClasses')
local parseConstants = require('luagir.handlers.parseConstants')
local parseEnumerations = require('luagir.handlers.parseEnumerations')
local parseFunctions = require('luagir.handlers.parseFunctions')

local emit = require('luagir.emitters')

_G.SCOPE = {
    namespace = '',
    version = '',
    lines = {},
    bitfields = {},
    classes = {},
    functions = {},
    append_line = function(self, line)
        table.insert(self.lines, line or '')
    end,
    clear = function(self)
        self.lines = {}
        self.bitfields = {}
        self.classes = {}
        self.functions = {}
    end,
}

---@param repo luagir.Repository
local function generateAnnotations(repo, opts)
    local docs_enabled = opts.docs

    local modname = string.format(
        'luagir.overrides.%s-%s',
        repo.namespace._attr.name,
        repo.namespace._attr.version
    )

    local ok, overrides = pcall(require, modname)

    if not ok then
        overrides = require('luagir.overrides.default')
    end

    -- Wire up overrides for getTypeOverride in xml.lua
    repo.override = overrides

    for _, definition in ipairs(overrides.definitions) do
        SCOPE:append_line()
        SCOPE:append_line(definition)
    end

    -- Parse all sections
    local constants = parseConstants(repo.namespace.constant)
    local bitfields = parseBitfields(repo.namespace.bitfield)
    local enumerations = parseEnumerations(repo.namespace.enumeration)
    local functions = parseFunctions(repo.namespace['function'])
    local classes = parseClasses(repo.namespace.class)
    local interfaces = parseClasses(repo.namespace.interface)
    local records = parseClasses(repo.namespace.record)

    emit.emitConstants(constants)
    emit.emitBitfields(bitfields, docs_enabled)
    emit.emitEnumerations(enumerations, docs_enabled)
    emit.emitFunctions(functions, docs_enabled)

    -- Gather classes (including interfaces and records)
    local all_classes = {}

    for _, array in ipairs { records, classes, interfaces } do
        for _, item in ipairs(array) do
            table.insert(all_classes, item)
        end
    end

    -- Emit class sections
    for _, class in ipairs(all_classes) do
        local ns_name = SCOPE.namespace .. '.' .. class.name

        -- Build parent list
        local parent_classes = {}

        for _, v in ipairs(class.inherits) do
            if v:find('%.') then
                table.insert(parent_classes, v)
            else
                table.insert(parent_classes, string.format('%s.%s', SCOPE.namespace, v))
            end
        end

        local has_props = #class.properties > 0
        local has_signals = #class.signals > 0

        if has_props then
            emit.emitClassProperties(ns_name, class, parent_classes, docs_enabled)
            emit.emitClassNotifySignals(ns_name, class, parent_classes)
        end

        if has_signals or has_props then
            emit.emitClassSignals(ns_name, class, parent_classes, docs_enabled)
        end

        emit.emitClassConstructorParams(ns_name, class, parent_classes, docs_enabled)

        -- Build class inheritance chain
        local all_inherits = {}

        for _, parent in ipairs(parent_classes) do
            table.insert(all_inherits, 1, parent)
        end

        if has_props then
            table.insert(all_inherits, 1, string.format('%s.Properties', ns_name))
        end

        if has_signals or has_props then
            table.insert(all_inherits, 1, string.format('%s.Signals', ns_name))
        end

        local inherits_str = ''
        if #all_inherits > 0 then
            inherits_str = ' : ' .. table.concat(all_inherits, ', ')
        end

        if docs_enabled then
            emit.emitDoc(class.doc)
        end

        SCOPE:append_line()

        SCOPE:append_line(string.format('---@class %s%s', ns_name, inherits_str))

        -- Constructor overloads
        SCOPE:append_line(
            string.format('---@overload fun(args: %s.ConstructorParams): %s', ns_name, ns_name)
        )

        SCOPE:append_line(string.format('%s.%s = {}', SCOPE.namespace, class.name))

        -- Instance methods
        for _, method in ipairs(class.methods) do
            method.separator = ':'
        end

        emit.emitClassMethods(ns_name, class.methods, docs_enabled)

        -- Class (static) methods
        for _, fn in ipairs(class.class_methods) do
            fn.separator = '.'
        end

        emit.emitClassMethods(ns_name, class.class_methods, docs_enabled)
    end

    local all_lines = {
        '---@meta _',
        '',
        '-- Type Definitions for Lua-Lgi',
        '-- These type definitions are automatically generated, do not edit them by hand.',
        '-- If you found a bug create a bug report on https://github.com/tokyob0t/luagir',
        '-- made with <3',
        '',
        string.format('---@class %s', SCOPE.namespace),
        string.format('local %s = {}', SCOPE.namespace),
    }

    for _, line in ipairs(SCOPE.lines) do
        table.insert(all_lines, line)
    end

    return all_lines
end

-- File Output

---@param repo luagir.Repository
---@param opts luagir.Options
local function writeRepository(repo, opts)
    SCOPE.namespace = repo.namespace._attr.name
    SCOPE.version = repo.namespace._attr.version
    SCOPE.repository = repo
    SCOPE:clear()

    local lines = generateAnnotations(repo, opts)

    local path = string.format('%s/%s-%s.lua', opts.dest_directory, SCOPE.namespace, SCOPE.version)

    file.writeFile(path, table.concat(lines, '\n'))
end

-- Orchestration

---@param gir string
---@param opts luagir.Options
---@param generated table<string, boolean>
local function generateRepository(gir, opts, generated, branches)
    branches = branches or {}

    local repo = repository.loadRepository(gir, {
        include_paths = opts.include_paths,
    })

    if not repo then
        return
    end

    local namespace = repo.namespace._attr.name
    local version = repo.namespace._attr.version

    local key = string.format('%s-%s', namespace, version)

    if generated[key] then
        return
    end

    generated[key] = true

    print(string.format('%s%s', print_utils.treePrefix(branches), gir))

    if opts.dependencies ~= false then
        local includes = repo.include or {}

        for i, include in ipairs(includes) do
            local dep = string.format('%s-%s', include._attr.name, include._attr.version)

            local next_branches = {}

            for j, value in ipairs(branches) do
                next_branches[j] = value
            end

            next_branches[#next_branches + 1] = i < #includes

            generateRepository(dep, opts, generated, next_branches)
        end
    end

    writeRepository(repo, opts)
end

---@param girs string[]
---@param opts luagir.Options
return function(girs, opts)
    opts = opts or {}

    opts.docs = not not opts.docs
    opts.dependencies = opts.dependencies ~= false
    assert(opts.dest_directory, 'dest_directory is required')
    assert(
        os.execute(string.format('mkdir -p %q', opts.dest_directory)),
        string.format('Failed to create destination directory: %s', opts.dest_directory)
    )

    local generated = {}

    for _, gir in ipairs(girs) do
        generateRepository(gir, opts, generated)
    end
end
