local fn = vim.fn

local M = {}

---@class Command
---@field dir string
---@field cmd string
---@field opts table
---@field name string

---@param plugin table
---@return Command
local function start_plugin(plugin)
    local path = plugin[1]
    local opts = plugin.opts or {}

    local cmd
    local dir = ''

    if fn.isdirectory(path) == 1 then
        dir = path
        cmd = "cargo run --"
    else
        cmd = path
    end
    local name = fn.fnamemodify(path, ":t")

    local command = {
        dir = dir,
        cmd = cmd,
        opts = opts,
        name = name
    }
    print("Starting plugin: " .. vim.inspect(command))
    return command
end

function M.plugins(plugins)
    if type(plugins) ~= "table" then
        error("plugins must be a table")
    end

    for i, plugin in ipairs(plugins) do
        if type(plugin) ~= "table" or type(plugin[1]) ~= "string" then
            error(string.format("plugin #%d must be a table with a string path", i))
        end
        if plugin.opts ~= nil and type(plugin.opts) ~= "table" then
            error(string.format("plugin #%d opts must be a table", i))
        end
        start_plugin(plugin)
    end
end

return M
