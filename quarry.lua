-- Equivalent to the ternary operator to some languages
function ternary(condition, trueValue, falseValue)
	if condition then
  		return trueValue
	else
		return falseValue
	end
end

function initArray ()
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
            fn(array[i])
        end
    end

    array.push = push
    array.forEach = forEach

    return array
end

function createCoords (x, z)
    local coords = {}

    coords.x = x
    coords.z = z

    return coords
end

-- Computes the path the turtle will take on the horizontal plane
-- `to` and `from` creates a 2d rectangle, and the path created will be something that "fills" this rectangle
-- @param from {table} Should have z and x properties, both of which have numeric value. This is the starting point of the turtle.
-- @param to {table} Same as above, but this is an ending point of the turtle
-- @returns {array} An array of the horizontal movements that the turtle will be making
function computeHorizontalPath(from, to)
	local path = initArray()

	local zStart = from.z
	local zEnd = to.z

    -- for the usage of the ternary; basically we decrement if the value from `from` is larger than the value of `true` and vice versa
	for x = from.x, to.x, ternary(to.x >= from.x, 1, -1) do
		-- We're skipping the z-alternation in the first step of x because this will cause the turtle to start moving on the opposite side
        -- instead of its initial position
        if x ~= fromX then
            -- z-swapping produces the snake-like behavior where the turtle starts from end-to-end
			zStart = ternary(zStart == from.z, to.z, from.z)
			zEnd = ternary(zEnd == from.z, to.z, from.z)
		end
		
		for z = zStart, ternary(zStart == from.z, to.z, from.z), ternary(zEnd >= zStart, 1, -1) do
			local coords = {}

            coords.x = x
            coords.z = z

            path.push(coords) 
		end
	end

	return path
end

local DIG_HEIGHT = 3

-- Computes the path the turtle will take on the vertical plane
-- @param from {number} The y value the turtle will begin at
-- @param to {number} The y value the turtle will end up at
function computeVerticalPath(from, to)
	local path = initArray()
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

            path.push(y)
        end

        y = from + fullSteps * ternary(moveUp, DIG_HEIGHT, -DIG_HEIGHT)
    end

    for partialY = y, to, ternary(moveUp, 1, -1) do
        path.push(partialY)
    end

    return path
end


-- The values used by initTurnManager
NORTH = 1
EAST = 2
SOUTH = 3
WEST = 4

function initTurnManager (initialBearing)
    local turnManager = {}
    turnManager.initialBearing = initialBearing

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
    
        turnManager.bearing = dir
    end

    turnManager.turn = turn
end