-- # CONSTANTS

-- These are bearings
local NORTH = 1
local EAST = 2
local SOUTH = 3
local WEST = 4

-- Positioning variables
local posX = 0
local posY = 0
local posZ = 0
local bearing = NORTH

local args = {...}

local origX = tonumber(args[1])
local origY = tonumber(args[2])
local origZ = tonumber(args[3])
local origBearing = tonumber(args[4])

posX = origX
posY = origY
posZ = origZ
bearing = origBearing

-- Required parameters
local trX = tonumber(args[5])
local trY = tonumber(args[6])
local trZ = tonumber(args[7])


-- The point where the quarry would start
local blX = posX
local blY = posY
local blZ = posZ

-- 4, 5, 6 are origin offset parameters
if args[8] ~= nil and args[9] ~= nil and args[10] ~= nil then
    blX = tonumber(args[8])
    blY = tonumber(args[9])
    blZ = tonumber(args[10])
end

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

function doXMovement()
    if posX == blX then
        moveToX(trX)
    else
        moveToX(blX)
    end
end


function doZMovement(a, b)
    local inc
    if b > a then
        inc = 1
    else
        inc = -1
    end

    for i = a, b, inc do
        moveToZ(i)
        doXMovement()
    end
end

function doYMovement(a, b)
    local inc
    if b > a then
        inc = 1
    else
        inc = -1
    end

    for i = a, b, inc do
        moveToY(i)
        if posZ == blZ then
            doZMovement(blZ, trZ)
        else
            doZMovement(trZ, blZ)
        end
    end

end

doYMovement(blY, trY)

moveToY(origY)
moveToX(origX)
moveToZ(origZ)
turn(origBearing)