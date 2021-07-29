function connectToWs(host, label, coords, bearing, fuel)
    local connString = string.format(
        "ws://%s?label=%sx=%dy=%dz=%dbearing=%dfuel=%d",
        host, label, coords.x, coords.y, coords.z, bearing, fuel
    )

    print(string.format("Connecting to %s", connString))
    return http.websocket(connString)
end

function main (args)
    local coords = {}
    coords.x = 0
    coords.y = 0
    coords.z = 0

    local ws = connectToWs(args[1], os.getComputerLabel(), coords, 1, 1)

    while true do
        local message = ws.receive()
        print(message)
    end
end


main({...})