function connectToWs(host, label, coords, bearing, fuel)
    local payload = {}
    payload.x = coords.x
    payload.y = coords.y
    payload.z = coords.z
    payload.label = label
    payload.bearing = bearing
    payload.fuelLevel = fuel

    local serialized = textutils.serializeJSON(payload)

    local headers = {}
    headers['turtle-data'] = serialized


    print(string.format("Connecting to %s", host))
    local ws, error = http.websocket(host, headers)

    if ws == nil or ws == false then
        print("Failed to connect")
        print(error)
        return nil
    end

    print(string.format("Connection established with %s", host))
    return ws
end

function main (args)
    local coords = {}
    coords.x = 0
    coords.y = 0
    coords.z = 0

    local ws = connectToWs(args[1], os.getComputerLabel(), coords, 1, 1)

    if ws == nil then
        return
    end

    while true do
        local message = ws.receive()
        print(message)
    end
end


main({...})