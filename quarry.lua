-- Equivalent to the ternary operator to some languages
function ternary(condition, trueValue, falseValue)
	if condition then
  		return trueValue
	else
		return falseValue
	end
end

function Array ()
    local array = {}
    local indexCounter = 1
    array.length = 0
    
    function push(val)
        local pushedIndex = indexCounter
        indexCounter = indexCounter + 1 -- iterate the counter to the next

        array[pushedIndex] = val
        array.length = pushedIndex
    end

    function forEach(fn)
        for i = 1, array.length, 1 do
            fn(array[i], i, array)
        end
    end

    array.push = push
    array.forEach = forEach

    return array
end

function createCoords (x, y, z)
    local coords = {}

    coords.x = x
    coords.z = z
    coords.y = y

    return coords
end

-- Computes the path the turtle will take on the horizontal plane
-- `to` and `from` creates a 2d rectangle, and the path created will be something that "fills" this rectangle
-- @param from {table} Should have z and x properties, both of which have numeric value. This is the starting point of the turtle.
-- @param to {table} Same as above, but this is an ending point of the turtle
-- @returns {array} An array of the horizontal movements that the turtle will be making
function computeHorizontalPath(from, to)
	local path = Array()

	local zStart = from.z
	local zEnd = to.z

    -- for the usage of the ternary; basically we decrement if the value from `from` is larger than the value of `true` and vice versa
	for x = from.x, to.x, ternary(to.x >= from.x, 1, -1) do
		-- We're skipping the z-alternation in the first step of x because this will cause the turtle to start moving on the opposite side
        -- instead of its initial position
        if x ~= from.x then
            -- z-swapping produces the snake-like behavior where the turtle starts from end-to-end
			local oldZStart = zStart
            zStart = zEnd
			zEnd = oldZStart
		end
		
		for z = zStart, zEnd, ternary(zEnd >= zStart, 1, -1) do
			local coords = {}

            coords.x = x
            coords.z = z

            path.push(coords) 
		end
	end

	return path
end

local DIG_HEIGHT = 3

function VertSegment(y, skipped)
    local segment = {}
    segment.y = y
    segment.skipped = skipped == true

    return segment
end

-- Computes the path the turtle will take on the vertical plane
-- @param from {number} The y value the turtle will begin at
-- @param to {number} The y value the turtle will end up at
function computeVerticalPath(from, to)
	local path = Array()
    local moveUp = to >= from

	local distance = math.abs(from - to) + 1 -- inclusive distance, hence + 1
    local steps = distance / DIG_HEIGHT

	local fullSteps = math.floor(distance / DIG_HEIGHT)
    local hasPartialSteps = math.abs(steps - fullSteps) > 0

    local y = from

    if fullSteps > 0 then
        for i = 1, fullSteps, 1 do
            if i == 1 then
                y = y + ternary(moveUp, 1, -1)
            else
                y = y + ternary(moveUp, DIG_HEIGHT, -DIG_HEIGHT)
            end

            path.push(VertSegment(y, true))
        end

        y = from + fullSteps * ternary(moveUp, DIG_HEIGHT, -DIG_HEIGHT)
    end

    for partialY = y, to, ternary(moveUp, 1, -1) do
        path.push(VertSegment(partialY))
    end

    return path
end


function MovementManager (initialCoords, initialBearing)
    local NORTH = 1
    local EAST = 2
    local SOUTH = 3
    local WEST = 4

    local manager = {}

    manager.bearing = initialBearing
    manager.posX = initialCoords.x
    manager.posY = initialCoords.y
    manager.posZ = initialCoords.z

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

    manager.getCoords = function()
        return createCoords(manager.posX, manager.posY, manager.posZ)
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

function inventoryEjectRoutineFactory(movementManager, inventoryCoords)
    local manager = movementManager

    function tripFn (targetCoords) -- moves to the target coordinates
        local origCoords = manager.getCoords()
        manager.moveToY(targetCoords.y)
        manager.moveDiagonally(targetCoords.x, targetCoords.z)

        return function() -- returns back to the location the turtle was at before calling goto()
            manager.moveDiagonally(origCoords.x, origCoords.z)
            manager.moveToY(origCoords.y)
        end
    end
    
    function unloadAll()
        for i = 1, 16, 1 do
            turtle.select(i)
            turtle.dropDown()
        end
    end
    
    return function (shouldReturn)
        local returnFn = tripFn(inventoryCoords)
        unloadAll()
        if shouldReturn == true then
            returnFn()
        end
    end
end

local ARGS_COUNT = 10
function main(args)
    -- currently the args are number strings; this block parses them
    local numArgs = Array()
    for i = 1, ARGS_COUNT, 1 do
        numArgs.push(tonumber(args[i]))
    end

    local from = createCoords(numArgs[1], numArgs[2], numArgs[3])
    local bearing = numArgs[4]
    local to = createCoords(numArgs[5], numArgs[6], numArgs[7])

    local engine = MovementManager(from, bearing)
    local vPath = computeVerticalPath(from.y, to.y)

    local inventoryFn = inventoryEjectRoutineFactory(engine, createCoords(numArgs[8], numArgs[9], numArgs[10]))

    vPath.forEach(
        function(vSegment, index)
            local singleDig = not vSegment.skipped
            engine.moveToY(vSegment.y)

            function digAdjacent()
                if not singleDig then
                    turtle.digUp()
                    turtle.digDown()
                end
            end

            local isOdd = index % 2 ~= 0
            -- alternate between the corners so that the zigzag motion will be continouous
            local hPath = computeHorizontalPath(
                ternary(isOdd, from, to),
                ternary(isOdd, to, from)
            )

            hPath.forEach(
                function (hSegment)
                    digAdjacent()
                    engine.moveToX(hSegment.x)
                    engine.moveToZ(hSegment.z)
                end
            )

            digAdjacent()
            -- don't go back into the hole if quarrying is finished
            inventoryFn(index == vPath,.length)
        end
    )
end

main({ ... })