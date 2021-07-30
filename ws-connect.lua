function connectToWs(host)
    local headers = {}
    headers['turtle-id'] = os.getComputerID()

    print(string.format("Connecting to %s", host))
    local ws, error = http.websocket(host, headers)

    if ws == nil or ws == false then
        print(string.format("Failed to connect: %s", error))
        return nil
    end

    print("Connection established.")
    return ws
end

function main (args)
    local ws = connectToWs(args[1])
    if ws == nil then
        -- Terminates turtle routine
        return
    end

    while true do
        local message = ws.receive()
        print(message)
    end
end


main({...})