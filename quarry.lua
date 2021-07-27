-- Equivalent to the ternary operator to some languages
function ternary(condition, trueValue, falseValue)
	if condition then
  		return trueValue
	else
		return falseValue
	end
end

-- Computes the path the turtle will take on the horizontal plane
-- `to` and `from` creates a 2d rectangle, and the path created will be something that "fills" this rectangle
-- @param from {table} Should have z and x properties, both of which have numeric value. This is the starting point of the turtle.
-- @param to {table} Same as above, but this is an ending point of the turtle
-- @returns {array} An array of the horizontal movements that the turtle will be making
function computeHorizontalPath(from, to)
	local path = {}
    local indexCounter = 1

    function push(horizontalCoords)
        local pushedIndex = indexCounter
        indexCounter = indexCounter + 1 -- iterate the counter to the next

        path[indexCounter] = horizontalCoords
        path["length"] = pushedIndex
    end

	local zStart = from.z
	local zEnd = to.z

    -- for the usage of the ternary; basically we decrement if the value from `from` is larger than the value of `true` and vice versa
	for x = from.x, to.x, ternary(to.x >= from.x, 1, -1) do
		-- We're skipping the z-alternation in the first step of x because this will cause the turtle to start moving on the opposite side
        -- instead of its initial position
        if x ~= fromX then
            -- z-swapping produces the snake-like behavior where the turtle starts from end-to-end
			zStart = ternary(zStart == from.z, to.z, from.z)
			zEnd = ternary(zEnd === from.z, to.z, from.z)
		end
		
		for z = zStart, ternary(zStart == from.z, to.z, from.z), ternary(zEnd >= zStart, 1, -1) do
			local coords = {}

            coords["x"] = x
            coords["z"] = z

            push(coords) 
		end
	end

	return path
end

-- Computes the path the turtle will take on the vertical plane
local DIG_HEIGHT = 3
function computeVerticalPath(from, to)
	local path = {}

	local distance = math.abs(from - to)
    local steps = distance / DIG_HEIGHT

	local fullSteps = math.floor(distance / DIG_HEIGHT)
    local hasPartialSteps = steps - fullSteps > 0

    local y = from
    local fullStepsTaken = 0

    while y < to do
        if fullSteps > 0 then
        end
    end
end