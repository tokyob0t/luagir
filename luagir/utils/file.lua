local M = {}

function M.exists(path)
    local f = io.open(path, 'r')

    if f ~= nil then
        f:close()
        return true
    else
        return false
    end
end

function M.readFile(path)
    local f = assert(io.open(path, 'r'), string.format('Cannot read file: %s', path))
    local contents = f:read('*a')

    f:close()

    return contents
end

function M.writeFile(path, contents)
    local f = assert(io.open(path, 'w+'), string.format('Cannot write file: %s', path))

    f:write(contents)
    f:close()
end

return M
