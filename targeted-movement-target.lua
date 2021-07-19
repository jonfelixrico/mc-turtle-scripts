local args = {...}
local x, y, z = gps.locate(5, true)
local channel = tonumber(args[1])

if x == nil then return end

local modem = peripheral.wrap("back") -- Wraps the modem on the right side.
modem.transmit(channel, channel + 1, string.format("[%d, %d, %d]", math.floor(x), math.floor(y), math.floor(z))) 
