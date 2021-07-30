-- Equivalent to the ternary operator to some languages
function ternary(condition, trueValue, falseValue)
	if condition then
  		return trueValue
	else
		return falseValue
	end
end


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
        local position = createCoords(manager.posX, manager.posY, manager.posZ)
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
    print(string.format("Obtained location -- %d %d %d", x, y, z))

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