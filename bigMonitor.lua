-- © Commandcracker
-- TODO:
--[[
    * getCursorPos
    ? isColour
    ! getBackgroundColour
    ? getTextColour
    ! scroll
    ! getPaletteColor
    * setTextColor
    ! getCursorBlink
    ! getTextScale
    ! setPaletteColour
    * clear
    ! setBackgroundColor
    * write
    ! setPaletteColor
    * setCursorPos
    ! getBackgroundColor
    ? isColor
    * setTextColour
    * blit
    ? getTextColor
    * getSize
    ! getPaletteColour
    * setTextScale
    ! setCursorBlink
    * setBackgroundColour
    ! clearLine
]]
-- the monitor
local bigMonitor = {}

local posy = 1
local posx = 1
local setup

function bigMonitor.init(_setup)
    setup = _setup
end

function bigMonitor.getSize()
    local fullWidth, fullHeight = 0, 0

    -- height
    for _, line in ipairs(setup) do
        local monitor = peripheral.wrap(line[1])
        local width, height = monitor.getSize()
        fullHeight = fullHeight + height
    end

    -- width
    for _, monitor_name in ipairs(setup[1]) do
        local monitor = peripheral.wrap(monitor_name)
        local width, height = monitor.getSize()
        fullWidth = fullWidth + width
    end

    return fullWidth, fullHeight
end

function bigMonitor.clear()
    for _, line in pairs(setup) do
        for _, monitor_name in pairs(line) do
            local monitor = peripheral.wrap(monitor_name)
            monitor.clear()
        end
    end
end

function bigMonitor.setTextScale(scale)
    for _, line in pairs(setup) do
        for _, monitor_name in pairs(line) do
            local monitor = peripheral.wrap(monitor_name)
            monitor.setTextScale(scale)
        end
    end
end

function bigMonitor.setBackgroundColour(colour)
    for _, line in pairs(setup) do
        for _, monitor_name in pairs(line) do
            local monitor = peripheral.wrap(monitor_name)
            monitor.setBackgroundColour(colour)
        end
    end
end

function bigMonitor.setCursorPos(x, y)
    posy = y
    posx = x
end

function bigMonitor.write(text)
    -- Fix Too long without yielding
    os.queueEvent("randomEvent")
    os.pullEvent()
    --------------------------------

    local fullWidth, fullHeight = bigMonitor.getSize()
    local lineHeight = 0

    for linekey, line in pairs(setup) do
        local monitor = peripheral.wrap(line[1])
        local width, height = monitor.getSize()

        lineHeight = lineHeight + height

        if posy <= lineHeight then
            local lineWidth = 0

            for key, monitor_name in pairs(line) do
                local monitor = peripheral.wrap(monitor_name)
                local width, height = monitor.getSize()
                lineWidth = lineWidth + width

                if posx <= lineWidth then
                    local w = (posx - lineWidth) + width
                    local h = (posy - lineHeight) + height

                    if #text > width + 1 - w then
                        local textWarp = width + 1 - w
                        bigMonitor.setCursorPos(lineWidth + 1, posy)
                        bigMonitor.write(string.sub(text, textWarp))
                        bigMonitor.setCursorPos(lineWidth, lineHeight)
                        text = string.sub(text, 0, textWarp)
                    end

                    monitor.setCursorPos(w, h)
                    monitor.write(text)
                    return
                end
            end
        end
    end
end

function bigMonitor.blit(text, textColour, backgroundColour)
    -- Fix Too long without yielding
    os.queueEvent("randomEvent")
    os.pullEvent()
    --------------------------------

    local fullWidth, fullHeight = bigMonitor.getSize()
    local lineHeight = 0

    for linekey, line in pairs(setup) do
        local monitor = peripheral.wrap(line[1])
        local width, height = monitor.getSize()

        lineHeight = lineHeight + height

        if posy <= lineHeight then
            local lineWidth = 0

            for key, monitor_name in pairs(line) do
                local monitor = peripheral.wrap(monitor_name)
                local width, height = monitor.getSize()
                lineWidth = lineWidth + width

                if posx <= lineWidth then
                    local w = (posx - lineWidth) + width
                    local h = (posy - lineHeight) + height

                    if #text > width + 1 - w then
                        local textWarp = width + 1 - w
                        bigMonitor.setCursorPos(lineWidth + 1, posy)
                        bigMonitor.blit(
                            string.sub(text, textWarp),
                            string.sub(textColour, textWarp),
                            string.sub(backgroundColour, textWarp)
                        )
                        bigMonitor.setCursorPos(lineWidth, lineHeight)
                        text = string.sub(text, 0, textWarp)
                        textColour = string.sub(textColour, 0, textWarp)
                        backgroundColour = string.sub(backgroundColour, 0, textWarp)
                    end

                    monitor.setCursorPos(w, h)
                    monitor.blit(text, textColour, backgroundColour)
                    return
                end
            end
        end
    end
end

function bigMonitor.isColour()
    return true
end

function bigMonitor.isColor()
    return true
end

function bigMonitor.getTextColour()
    return colours.white
end

function bigMonitor.getTextColor()
    return colours.white
end

function bigMonitor.setTextColour(colour)
    for _, line in pairs(setup) do
        for _, monitor_name in pairs(line) do
            local monitor = peripheral.wrap(monitor_name)
            monitor.setTextColour(colour)
        end
    end
end

function bigMonitor.setTextColor(colour)
    bigMonitor.setTextColour(colour)
end

function bigMonitor.getCursorPos()
    return posx, posy
end

return bigMonitor
