local M = {}

function M.create_connection(socket_path, service_name, ping_method)
    local connection = {}
    connection.channel_id = nil
    connection.reconnect_interval = 1000 -- 1 second
    connection.check_interval = 5000     -- 5 seconds
    connection.ping_method = ping_method or "__nvi_ping"

    function connection.log(message)
        vim.schedule(function()
            print(string.format("[%s] %s", service_name, message))
        end)
    end

    function connection.connect_to_socket()
        local success, result = pcall(function()
            return vim.fn.sockconnect("pipe", socket_path, { rpc = true })
        end)

        if success and type(result) == "number" and result > 0 then
            connection.channel_id = result
            connection.log("Connected successfully")
            connection.setup_disconnect_detection()
            return true
        else
            return false
        end
    end

    function connection.setup_disconnect_detection()
        -- Set up a timer to periodically check the connection
        connection.check_timer = vim.loop.new_timer()
        connection.check_timer:start(connection.check_interval, connection.check_interval, vim.schedule_wrap(function()
            if not connection.is_connected() then
                connection.log("Disconnected (detected during periodic check)")
                connection.disconnect()
                connection.try_reconnect()
            end
        end))
    end

    function connection.try_reconnect()
        if not connection.channel_id then
            if connection.connect_to_socket() then
                connection.log("Reconnected successfully")
            else
                vim.defer_fn(connection.try_reconnect, connection.reconnect_interval)
            end
        end
    end

    function connection.disconnect()
        if connection.channel_id then
            pcall(vim.fn.chanclose, connection.channel_id)
            connection.channel_id = nil
            if connection.check_timer then
                connection.check_timer:stop()
                connection.check_timer:close()
                connection.check_timer = nil
            end
            connection.log("Disconnected")
        end
    end

    function connection.is_connected()
        if not connection.channel_id then
            return false
        end

        local success, result = pcall(function()
            return vim.rpcrequest(connection.channel_id, connection.ping_method)
        end)

        return success and result == true
    end

    function connection.reconnect()
        connection.disconnect()
        connection.try_reconnect()
    end

    -- Initial connection attempt
    if not connection.connect_to_socket() then
        vim.defer_fn(connection.try_reconnect, connection.reconnect_interval)
    end

    return connection
end

return M
