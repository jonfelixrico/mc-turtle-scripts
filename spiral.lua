-- modified spiral code from https://www.geeksforgeeks.org/print-a-given-matrix-in-spiral-form/ by karthiksrinivasprasad
function spiralPrint(width, length)
    local i
    local k = 0
    local l = 0
    --[[
        k - starting row index
        width - ending row index
        l - starting column index
        length - ending column index
        i - iterator 
    ]]--
 
    while k < width and l < length do
        -- print the first row from the remaining rows
        for i = l,  length - 1, 1 do
            print(string.format("%d %d", k, i))
        end

        k = k + 1
 
        -- print the last column from the remaining columns
        for i = k, width - 1, 1 do
            print(string.format("%d %d", i, length - 1))
        end
        length = length - 1
 
        -- print the last row from the remaining rows
        if k < width then
            for i = length - 1, l, -1 do
                print(string.format("%d %d", width - 1, i))
            end
            width = width - 1
        end
 
        -- // print the first column from the remaining columns
        if l < length then
            for i = width - 1, k, -1 do
                print(string.format("%d %d", i, l))
            end
            l = l + 1
        end
    end
end

spiralPrint(5, 1)