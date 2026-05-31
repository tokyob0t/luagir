local M = {}

function M.treePrefix(branches)
    local parts = {}
    for i = 1, #branches - 1 do
        parts[#parts + 1] = branches[i] and '│   ' or '    '
    end
    if #branches > 0 then
        parts[#parts + 1] = branches[#branches] and '├── ' or '└── '
    end
    return table.concat(parts)
end

return M
