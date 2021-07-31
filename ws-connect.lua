-- Equivalent to the ternary operator to some languages
function ternary(condition, trueValue, falseValue)
	if condition then
  		return trueValue
	else
		return falseValue
	end
end

function connectToWs(host)
    local computerId = os.getComputerID()
    local url = string.format("%s/?id=%s", host, computerId)

    print(string.format("Attemptign to establish WS connection with %s", url))
    local ws, error = http.websocket(url)

    if ws == nil or ws == false then
        print(string.format("Failed to connect: %s", error))
        return nil
    end

    print("Connection established.")
    return ws
end

-- Movement utility
function MovementManager (initialCoords, initialBearing)
    initialCoords = ternary(initialCoords ~= nil, initialCoords, {})
    
    local manager = {}

    local NORTH = 1
    local EAST = 2
    local SOUTH = 3
    local WEST = 4

    manager.NORTH = NORTH
    manager.EAST = EAST
    manager.SOUTH = SOUTH
    manager.WEST = WEST

    manager.bearing = ternary(initalBearing ~= nil, initialBearing, NORTH)
    manager.posX = ternary(initialCoords.x ~= nil, initialCoords.x, 0)
    manager.posY = ternary(initialCoords.y ~= nil, initialCoords.y, 0)
    manager.posZ = ternary(initialCoords.z ~= nil, initialCoords.z, 0)

    function turn(dir)
        local bearing = manager.bearing
        if bearing == NORTH then
            -- facing NORTH
            if dir == EAST then
                turtle.turnRight()
            elseif dir == WEST then
                turtle.turnLeft()
            elseif dir == SOUTH then
                turtle.turnRight()
                turtle.turnRight()
            end
        elseif bearing == SOUTH then
            -- facing SOUTH
            if dir == NORTH then
                turtle.turnRight()
                turtle.turnRight()
            elseif dir == EAST then
                turtle.turnLeft()
            elseif dir == WEST then
                turtle.turnRight()
            end
        elseif bearing == EAST then
            -- facing EAST
            if dir == WEST then
                turtle.turnRight()
                turtle.turnRight()
            elseif dir == NORTH then
                turtle.turnLeft()
            elseif dir == SOUTH then
                turtle.turnRight()
            end
        else -- facing WEST
            if dir == EAST then
                turtle.turnRight()
                turtle.turnRight()
            elseif dir == NORTH  then
                turtle.turnRight()
            elseif dir == SOUTH then
                turtle.turnLeft()
            end
        end
    
        manager.bearing = dir
    end

    manager.turn = turn

    -- not exposed directly as an anonymous function for ease of calling from other methods
    -- if movement was successful, returns true; false if otherwise
    function moveForward()
        -- no obstructions detected
        if not turtle.detect() then
            turtle.forward()
            return true
        end

        -- obstruction detected

        -- turtle failed digging for some reason
        if not turtle.dig() then
            return false
        end

        return turtle.forward()
    end

    manager.moveForward = moveForward

    manager.moveToX = function(destX)
        local moves = destX - manager.posX
        if moves == 0 then return end
    
        local posIncrement = 1
    
        if moves > 0 then
            turn(EAST)
        else
            turn(WEST)
            posIncrement = -1
        end
    
        for i = 1, math.abs(moves), 1 do
            if not moveForward() then
                return false
            end
    
            -- will add +1 to pos if moving right, -1 if moving left
            manager.posX = manager.posX + posIncrement
        end
    
        return true
    end
    
    manager.moveToZ = function(destZ)
        local moves = destZ - manager.posZ
        if moves == 0 then return end
    
        local posIncrement = 1
    
        if moves > 0 then
            -- in MC, south is positive Z
            turn(SOUTH)
        else
            turn(NORTH)
            posIncrement = -1
        end
    
        for i = 1, math.abs(moves), 1 do
            if not moveForward() then
                return false
            end
    
            -- will add +1 to pos if moving right, -1 if moving left
            manager.posZ = manager.posZ + posIncrement
        end
    
        return true
    end
    
    manager.moveToY = function(destY)
        local moves = destY - manager.posY
        if moves == 0 then return end
    
        local posIncrement = 1
        local moveUp = moves > 0
    
        if not moveUp then
            posIncrement = -1
        end
    
        for i = 1, math.abs(moves), 1 do
            if moveUp then
                if turtle.detectUp() then
                    -- obstruction detected; going to clear
                    if not turtle.digUp() then
                        -- turtle wasnt able to dig up for some reason
                        return false
                    end
                end
    
                turtle.up()
            else
                -- same logic with the one above
                if turtle.detectDown() then
                    if not turtle.digDown() then
                        return false
                    end
                end
    
                turtle.down()
            end
    
            -- will add +1 to pos if moving right, -1 if moving left
            manager.posY = manager.posY + posIncrement
        end
    
        return true
    end

    manager.getPosition = function()
        local position = {}
        position.x = manager.posX
        position.y = manager.posY
        position.z = manager.posZ 
        position.bearing = manager.bearing

        return position
    end

    function twoPointFactory(xA, yA, xB, yB)
        local slopeY = yB - yA
        local slopeX = xB - xA
    
        return function (x)
            return (slopeY / slopeX) * (x - xA) + yA
        end
    end

    manager.moveDiagonally = function (destX, destZ)
        local startX = manager.posX
        local endX = destX
    
        if startX == endX then
            manager.moveToZ(destZ)
            return
        end
    
        -- As you can see here, we're finally making use of the math we learned in high school
        local lineFunction = twoPointFactory(manager.posX, manager.posZ, destX, destZ)
    
        for x = startX, endX, ternary(startX < endX, 1, -1) do
            local z = math.floor(lineFunction(x))
            manager.moveToX(x)
            manager.moveToZ(z)
        end
    end

    return manager
end

function getPosition()
    local x, y, z = gps.locate()
    if x == nil then
        return nil
    end

    local coords = {}
    coords.x = x
    coords.y = y
    coords.z = z

    return coords
end

function selfInitMovementManager()
    print("Starting movement manager self-init.")

    print("Retrieving location...")
    local origCoords = getPosition()

    if origCoords == nil then
        print("Cannot obtain location.")
        return false
    end
    print(string.format("Obtained location -- %d %d %d", origCoords.x, origCoords.y, origCoords.z))

    local manager = MovementManager(origCoords)
    
    print("Obtaining bearing... will move forward to check displacement.")
    manager.moveForward()

    local bearingCoords = getPosition()

    local xDiff = origCoords.x - bearingCoords.x
    local zDiff = origCoords.z - bearingCoords.z

    if xDiff ~= 0 then
        manager.bearing = ternary(xDiff > 0, manager.EAST, manager.WEST)
    else
        manager.bearing = ternary(zDiff > 0, manager.SOUTH, manager.NORTH)
    end

    print(string.format("Obtained bearing code %d", manager.bearing))

    print("Bearing obtained. Returning to original position...")
    turtle.back()

    print("Self-init complete.")

    return manager
end

function emitTurtleStatusRoutineFactory(manager, websocket, intervalInSeconds)
    intervalInSeconds = ternary(intervalInSeconds ~= nil, intervalInSeconds, 7)
    return function ()
        while true do
            local status = manager.getPosition()
            status.fuelLevel = turtle.getFuelLevel()
            status.fuelLimit = turtle.getFuelLimit()
            status.label = os.getComputerLabel()

            local message = {}
            message.type = "STATUS_UPDATE"
            message.payload = status
            websocket.send(textutils.serializeJSON(message))
            print("Sent STATUS_UPDATE to the server.")

            os.sleep(intervalInSeconds)
        end
    end
end

function listenForWebsocketMessagesRoutineFactory(manager, websocket)
    local typeTable = {}
    typeTable.moveToX = manager.moveToX
    typeTable.moveToY = manager.moveToY
    typeTable.moveToZ = manager.moveToZ

    function doIteration ()
        local message = websocket.receive()
        if message == nil then
            print("Something went wrong while waiting for a message...")
            return
        end

        local parsed = textutils.unserializeJSON(message)
        print(string.format("Received a message of type %s", parsed.type))
        typeTable[parsed.type](table.unpack(parsed.args))
    end

    return function ()
        while true do
            doIteration()
        end
    end
end

function main (args)
    local ws = connectToWs(args[1])
    if ws == nil then
        -- Terminates turtle routine
        return
    end

    local manager = selfInitMovementManager()
    if manager == nil then
        return
    end

    parallel.waitForAll(
        emitTurtleStatusRoutineFactory(manager, ws)
    )
end


main({...})