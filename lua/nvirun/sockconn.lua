local M = {}

---@param socket_path string
---@param plugin Plugin
function M.create_connection(socket_path, plugin)
    local connection = {}
    connection.restart_timer = nil
    connection.restart_interval = 1000 -- 1 second

    local function start_process(plugin, spath)
        local cmd = plugin.cmd .. " connect " .. spath
        local job_id = vim.fn.jobstart(cmd, {
            cwd = plugin.dir,
            on_exit = function(_, exit_code)
                if exit_code ~= 0 then
                    connection.log(string.format("Process exited with code %d, restarting...", exit_code))
                    -- Schedule restart
                    connection.restart_timer = vim.defer_fn(function()
                        connection.job_id = start_process(plugin, spath)
                    end, connection.restart_interval)
                else
                    connection.log("Process exited normally")
                end
            end,
        })

        if job_id <= 0 then
            error(string.format("Failed to start plugin %s", plugin.name))
        end
        return job_id
    end

    connection.job_id = start_process(plugin, socket_path)

    function connection.log(message)
        vim.schedule(function()
            print(string.format("[%s] %s", plugin.name, message))
        end)
    end

    function connection.stop()
        if connection.restart_timer then
            connection.restart_timer:close()
            connection.restart_timer = nil
        end
        if connection.job_id then
            vim.fn.jobstop(connection.job_id)
            connection.job_id = nil
        end
    end

    return connection
end

return M

