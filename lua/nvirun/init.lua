local fn = vim.fn
local sockconn = require("nvirun.sockconn")

local M = {}

---@type table<string, table>
M.connections = {}

---@type string
M.socket_path = nil

---@type Plugin[]
M.running = {}

---Returns socket path and plugin information
---@return { socket: string, plugins: Plugin[] }
function M.info()
    return {
        socket = M.socket_path,
        plugins = M.running,
    }
end

---Initialize socket connection
local function init_socket()
    local socket_path = fn.tempname()
    vim.fn.serverstart(socket_path)
    return socket_path
end

M.socket_path = init_socket()

---@class Plugin
---@field dir string
---@field cmd string
---@field opts table
---@field name string

---@param plugin table
---@return Plugin
local function start_plugin(plugin)
    local path = plugin[1]
    local opts = plugin.opts or {}

    local cmd
    local dir = ""

    local expanded_path = fn.expand(path)
    if fn.isdirectory(expanded_path) ~= 0 then
        dir = expanded_path
        cmd = "cargo run --release --"
    else
        cmd = path
    end
    local name
    if fn.isdirectory(expanded_path) ~= 0 then
        name = fn.fnamemodify(expanded_path, ":t")
    else
        name = path
    end

    local command = {
        dir = dir,
        cmd = cmd,
        opts = opts,
        name = name,
    }
    return command
end

---Register NviRunInfo command to display socket and plugin information
local function setup_commands()
    vim.api.nvim_create_user_command("NviRunInfo", function()
        local info = M.info()
        local output = string.format("Socket path: %s\n\nPlugins:", info.socket)
        for _, cmd in ipairs(info.plugins) do
            output = output .. string.format("\n  %s:\n    dir: %s\n    cmd: %s", cmd.name, cmd.dir, cmd.cmd)
        end
        vim.api.nvim_echo({ { output, "Normal" } }, false, {})
    end, {})
end

setup_commands()

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
        local command = start_plugin(plugin)
        table.insert(M.running, command)

        -- Start the plugin process
        local conn = sockconn.create_connection(M.socket_path, command)
        M.connections[command.name] = conn
    end
end

return M