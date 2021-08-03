local setup = {
    {"monitor_20","monitor_21", "monitor_22","monitor_24", "monitor_23"},
    {"monitor_15","monitor_16","monitor_17","monitor_18","monitor_19"},
    {"monitor_6","monitor_7","monitor_8", "monitor_9", "monitor_12"},
    {"monitor_3","monitor_4","monitor_5", "monitor_10", "monitor_13"},
    {"monitor_0","monitor_1","monitor_2", "monitor_11", "monitor_14"}
}

local function reverseTable(mytable)
    local reversedTable = {}
    for i = #mytable, 1, -1 do
        table.insert(reversedTable, mytable[i])
    end
    return reversedTable
end

-- the monitor
local bigMonitor = {}

local posy = 1
local posx = 1

function bigMonitor.getSize()
    local fullWidth, fullHeight = 0,0

    -- height
    for _,line in ipairs(setup) do
        local monitor = peripheral.wrap(line[1])
        local width, height = monitor.getSize()
        fullHeight = fullHeight + height - 1
    end

    -- width
    for _,monitor_name in ipairs(setup[1]) do
        local monitor = peripheral.wrap(monitor_name)
        local width, height = monitor.getSize()
        fullWidth = fullWidth + width - 1
    end

    return fullWidth + 1,fullHeight + 1
end

function bigMonitor.clear()
    for k, v in pairs(setup) do
        for k, v in pairs(v) do
            local monitor = peripheral.wrap(v)
            monitor.clear()
        end
    end
end

function bigMonitor.setTextScale(scale)
    for k, v in pairs(setup) do
        for k, v in pairs(v) do
            local monitor = peripheral.wrap(v)
            monitor.setTextScale(scale)
        end
    end
end

function bigMonitor.setBackgroundColour(colour)
    for k, v in pairs(setup) do
        for k, v in pairs(v) do
            local monitor = peripheral.wrap(v)
            monitor.setBackgroundColour(colour)
        end
    end
end

function bigMonitor.setCursorPos(x, y)
    --print(x,y)
    posy = y
    posx = x
end

function bigMonitor.write(text)
    local fullWidth, fullHeight = bigMonitor.getSize()
    local lineHeight = 0

    for linekey, line in pairs(setup) do

        local monitor = peripheral.wrap(line[1])
        local width, height = monitor.getSize()

        lineHeight = lineHeight + height
        --print(text..": "..posy,lineHeight)
        if posy <= lineHeight then
            local lineWidth = 0

            for key, monitor_name in pairs(line) do
                local monitor = peripheral.wrap(monitor_name)
                local width, height = monitor.getSize()
                lineWidth = lineWidth + width

                if posx <= lineWidth then

                    local w = (posx-lineWidth)+width
                    local h = (posy-lineHeight)+height

                    if #text > width-w then
                        bigMonitor.setCursorPos(lineWidth+1,h)
                        bigMonitor.write(string.sub(text,width-w))
                        bigMonitor.setCursorPos(lineWidth,h)
                        text = string.sub(text,0,width-w)
                    end

                    --print(monitor_name.." : "..w.." : "..h)
                    monitor.setCursorPos(w,h)
                    monitor.write(text)
                    return
                end
            end

        end

    end

end

function bigMonitor.blit(text, textColour, backgroundColour)
    local fullWidth, fullHeight = bigMonitor.getSize()
    local lineHeight = 0

    for linekey, line in pairs(setup) do

        local monitor = peripheral.wrap(line[1])
        local width, height = monitor.getSize()

        lineHeight = lineHeight + height
        --print(text..": "..posy,lineHeight)
        if posy <= lineHeight then
            local lineWidth = 0

            for key, monitor_name in pairs(line) do
                local monitor = peripheral.wrap(monitor_name)
                local width, height = monitor.getSize()
                lineWidth = lineWidth + width

                if posx <= lineWidth then

                    local w = (posx-lineWidth)+width
                    local h = (posy-lineHeight)+height

                    if #text > width+1-w then
                        local textWarp = width+1-w
                        --print(lineHeight)
                        bigMonitor.setCursorPos(lineWidth+1,posy)
                        bigMonitor.blit(string.sub(text,textWarp),string.sub(textColour,textWarp) ,string.sub(backgroundColour,textWarp))
                        bigMonitor.setCursorPos(lineWidth,lineHeight)
                        text = string.sub(text,0,textWarp)
                        textColour = string.sub(textColour,0,textWarp)
                        backgroundColour = string.sub(backgroundColour,0,textWarp)
                    end

                    --print(monitor_name.." : "..w.." : "..h)
                    monitor.setCursorPos(w,h)
                    monitor.blit(text,textColour,backgroundColour)
                    return
                end
            end

        end

    end

end

function bigMonitor.idnt()
    for key, mon in pairs(monitors) do
        mon.write(key.." : "..peripheral.getName(mon))
    end
end

function bigMonitor.isColour()
    return true
end

function bigMonitor.getTextColour()
    return colours.white
end

function bigMonitor.setTextColour(colour)
    for k, v in pairs(setup) do
        for k, v in pairs(v) do
            local monitor = peripheral.wrap(v)
            monitor.setTextColour(colour)
        end
    end
end

function bigMonitor.getCursorPos()
    return posx,posy
end


--[[
bigMonitor.setBackgroundColour(colours.black)
bigMonitor.clear()

bigMonitor.setCursorPos(1,1)
bigMonitor.write("1")

bigMonitor.setCursorPos(165,1)
bigMonitor.write("2")

bigMonitor.setCursorPos(329,1)
bigMonitor.write("3")

bigMonitor.setCursorPos(1,82)
bigMonitor.write("4")

bigMonitor.setCursorPos(165,82)
bigMonitor.write("5")

bigMonitor.setCursorPos(329,82)
bigMonitor.write("6")
]]
print(bigMonitor.getSize())

--bigMonitor.getSize()

return bigMonitor
