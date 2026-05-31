---@alias luagir.Override {
--- classes: table<string, luagir.Class>,
--- functions: table<string, luagir.Function>,
--- records: table<string, luagir.Class>,
--- constants: table<string, luagir.Const>,
--- bitfields: table<string, luagir.Bitfield>,
--- definitions: string[] }

return {
    classes = {},
    functions = {},
    records = {},
    aliases = {},
    bitfields = {},
    constants = {},
    definitions = {},
}
