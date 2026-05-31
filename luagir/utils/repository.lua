local file = require('luagir.utils.file')

local handler = require('xmlhandler.tree')
local xml2lua = require('xml2lua')

---@alias luagir.XmlInclude { _attr: { name: string, version: string } }
---@alias luagir.Repository { _attr: table, include: XmlInclude[], namespace: table, override: luagir.Override  }

local M = {}

local DEFAULT_GIR_PATHS = {
    '/usr/share/gir-1.0',
}

local noreduce = {
    class = true,
    include = true,
    bitfield = true,
    constant = true,
    enumeration = true,
    interface = true,
    record = true,
    member = true,
    parameter = true,
    parameters = true,
    implements = true,
    prerequisite = true,
    method = true,
    constructor = true,
    property = true,
    ['function'] = true,
    ['glib:signal'] = true,
}

---@class luagir.RepositoryLoadOptions
---@field search_paths? string[]
local function findGir(gir, search_paths)
    if file.exists(gir) then
        return gir
    end

    if gir:match('%.gir$') then
        for _, dir in ipairs(search_paths) do
            local path = string.format('%s/%s', dir, gir)

            if file.exists(path) then
                return path
            end
        end
    else
        for _, dir in ipairs(search_paths) do
            local path = string.format('%s/%s.gir', dir, gir)

            if file.exists(path) then
                return path
            end
        end
    end
end

---@param opts luagir.RepositoryLoadOptions
---@return string[]
local function buildSearchPaths(opts)
    local paths = {}

    for _, path in ipairs(DEFAULT_GIR_PATHS) do
        table.insert(paths, path)
    end

    for _, path in ipairs(opts.include_paths or {}) do
        table.insert(paths, path)
    end

    return paths
end

---@param gir string
---@param opts? luagir.RepositoryLoadOptions
---@return luagir.Repository
function M.loadRepository(gir, opts)
    opts = opts or {}

    local gir_path = findGir(gir, buildSearchPaths(opts))

    if not gir_path then
        io.stderr:write(string.format('Could not find GIR: %s\n', gir))
        return
    end

    local h = handler:new()

    h.options.noreduce = noreduce

    local contents = file.readFile(gir_path)

    xml2lua.parser(h):parse(contents)

    return h.root.repository
end

return M
