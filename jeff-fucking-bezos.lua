-- # CONSTANTS

-- These are bearings
local NORTH = 1
local EAST = 2
local SOUTH = 3
local WEST = 4

local args = {...}

-- Positioning variables
local posX = tonumber(args[1])
local posY = tonumber(args[2])
local posZ = tonumber(args[3])
local bearing = tonumber(args[4])
local recvChannel = tonumber(args[5])

function turn(dir)
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

    bearing = dir
end

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

function moveToX(destX)
    local moves = destX - posX
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
        posX = posX + posIncrement
    end

    return true
end

function moveToZ(destZ)
    local moves = destZ - posZ
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
        posZ = posZ + posIncrement
    end

    return true
end

function moveToY(destY)
    local moves = destY - posY
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
        posY = posY + posIncrement
    end

    return true
end

-- Returns a function that accepts a value `x` and returns the value `y`.
-- The function is actually an equation of a line which was obtained using the two-point form.
function twoPointFactory(xA, yA, xB, yB)
    local slopeY = yB - yA
    local slopeX = xB - xA

    return function (x)
        return (slopeY / slopeX) * (x - xA) + yA
    end
end

-- Moves the turtle on the horizontal plane. If the destination is not a straight line (with respect to z or x),
-- then the turtle moves diagonally.
function moveHorizontal(destX, destZ)
    local startX = math.min(destX, posX)
    local endX = math.max(destX, posX)

    -- As you can see here, we're finally making use of the math we learned in high school
    local lineFunction = twoPointFactory(posX, posZ, destX, destZ)

    for x = startX, endX, 1 do
        local z = lineFunction(x)
        moveToX(x)
        moveToZ(z)
    end
end

local modem = peripheral.wrap("right")
modem.open(recvChannel)

while true do
    -- os.pullEvent will "lock" the main process. The following code will not proceed until it receives a "modem_message"
    -- event from the OS (no idea how that works under the hood)
    local event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message")
    
    -- The payload (message) of the event is expected to be a JSON array containing 3 numbers, represeting X, Y, and Z coordinates
    local coords = textutils.unserializeJSON(message)
    
    local targetX = coords[1]
    local targetY = coords[2]
    local targetZ = coords[3]
    
    local origX = posX
    local origY = posY
    local origZ = posZ
    local origB = bearing
    
    moveToY(targetY + 15)
    moveHorizontal(targetX, targetZ)

    moveToY(targetY + 5)
    turtle.dropDown(1)

    moveToY(targetY + 15)
    moveHorizontal(origX, origZ)
    moveToY(origY)
    turn(origB)
end