local fn = vim.fn

local M = {}

---@type Command[]
local commands = {}

---Initialize socket connection
local function init_socket()
	local socket_path = fn.tempname()
	vim.fn.serverstart(socket_path)
	return socket_path
end

local socket_path = init_socket()

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
	local dir = ""

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
		name = name,
	}
	return command
end

---Register NviRunInfo command to display socket and plugin information
local function setup_commands()
	vim.api.nvim_create_user_command("NviRunInfo", function()
		local info = string.format("Socket path: %s\n\nPlugins:", socket_path)
		for _, cmd in ipairs(commands) do
			info = info .. string.format("\n  %s:\n    dir: %s\n    cmd: %s", cmd.name, cmd.dir, cmd.cmd)
		end
		vim.api.nvim_echo({ { info, "Normal" } }, false, {})
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
		table.insert(commands, command)
	end
end

return M
