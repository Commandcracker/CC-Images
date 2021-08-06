-- © Commandcracker
-- TODO:
--[[
    ! Improve scroll, PaletteColour
    ! fix old CC Color and Colour
]]
-- the monitor
local bigMonitor = {}

local textScale = 1
local BackgroundColor = colors.black
local TextColour = colors.white
local posy = 1
local posx = 1
local setup
local _blink = false

function bigMonitor.init(_setup)
    setup = _setup
end

function bigMonitor.clearLine()
    local fullWidth, fullHeight = bigMonitor.getSize()
    local lineHeight = 0

    for _, line in pairs(setup) do
        local monitor = peripheral.wrap(line[1])
        local width, height = monitor.getSize()

        lineHeight = lineHeight + height

        if posy <= lineHeight then
            local lineWidth = 0

            for _, monitor_name in pairs(line) do
                local monitor = peripheral.wrap(monitor_name)
                local width, height = monitor.getSize()
                lineWidth = lineWidth + width

                local w = (posx - lineWidth) + width
                local h = (posy - lineHeight) + height

                monitor.setCursorPos(w, h)
                monitor.clearLine()
            end
            return
        end
    end
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
    textScale = scale
end

function bigMonitor.getTextScale()
    return textScale
end

function bigMonitor.setBackgroundColour(colour)
    for _, line in pairs(setup) do
        for _, monitor_name in pairs(line) do
            local monitor = peripheral.wrap(monitor_name)
            monitor.setBackgroundColour(colour)
        end
    end
    BackgroundColor = colour
end

bigMonitor.setBackgroundColor = bigMonitor.setBackgroundColour

function bigMonitor.getBackgroundColor()
    return BackgroundColor
end

bigMonitor.getBackgroundColour = bigMonitor.getBackgroundColor

function bigMonitor.setCursorPos(x, y)
    posy = y
    posx = x

    for _, line in pairs(setup) do
        for _, monitor_name in pairs(line) do
            local monitor = peripheral.wrap(monitor_name)
            monitor.setCursorBlink(false)
        end
    end

    if _blink == true then
        local fullWidth, fullHeight = bigMonitor.getSize()
        local lineHeight = 0
        local f = false

        for _, line in pairs(setup) do
            local monitor = peripheral.wrap(line[1])
            local width, height = monitor.getSize()
    
            lineHeight = lineHeight + height
    
            if posy <= lineHeight then
                local lineWidth = 0
    
                for _, monitor_name in pairs(line) do
                    local monitor = peripheral.wrap(monitor_name)
                    local width, height = monitor.getSize()
                    lineWidth = lineWidth + width
    
                    if posx <= lineWidth then
                        monitor.setCursorBlink(_blink)
                        return
                    end
                end
            end
        end
    end
end

-- Fix Too long without yielding
local function yield()
    os.queueEvent("randomEvent")
    os.pullEvent()
end

local function writeAt(text, x, y)
    local fullWidth, fullHeight = bigMonitor.getSize()
    local lineHeight = 0

    for _, line in pairs(setup) do
        local monitor = peripheral.wrap(line[1])
        local width, height = monitor.getSize()

        lineHeight = lineHeight + height

        if y <= lineHeight then
            local lineWidth = 0

            for _, monitor_name in pairs(line) do
                local monitor = peripheral.wrap(monitor_name)
                local width, height = monitor.getSize()
                lineWidth = lineWidth + width

                if x <= lineWidth then
                    local w = (x - lineWidth) + width
                    local h = (y - lineHeight) + height

                    if #text > width + 1 - w then
                        local textWarp = width + 1 - w
                        writeAt(string.sub(text, textWarp + 1), lineWidth + 1, y)
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

function bigMonitor.write(text)
    yield()
    writeAt(text, posx, posy)
    bigMonitor.setCursorPos(posx + #text, posy)
end

local function blitAt(text, textColour, backgroundColour, x, y)
    local fullWidth, fullHeight = bigMonitor.getSize()
    local lineHeight = 0

    for _, line in pairs(setup) do
        local monitor = peripheral.wrap(line[1])
        local width, height = monitor.getSize()

        lineHeight = lineHeight + height

        if y <= lineHeight then
            local lineWidth = 0

            for _, monitor_name in pairs(line) do
                local monitor = peripheral.wrap(monitor_name)
                local width, height = monitor.getSize()
                lineWidth = lineWidth + width

                if x <= lineWidth then
                    local w = (x - lineWidth) + width
                    local h = (y - lineHeight) + height

                    if #text > width + 1 - w then
                        local textWarp = width + 1 - w
                        blitAt(
                            string.sub(text, textWarp + 1),
                            string.sub(textColour, textWarp + 1),
                            string.sub(backgroundColour, textWarp + 1),
                            lineWidth + 1,
                            y
                        )
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

function bigMonitor.blit(text, textColour, backgroundColour)
    yield()
    blitAt(text, textColour, backgroundColour, posx, posy)
    bigMonitor.setCursorPos(posx + #text, posy)
end

function bigMonitor.isColour()
    for _, line in pairs(setup) do
        for _, monitor_name in pairs(line) do
            local monitor = peripheral.wrap(monitor_name)
            if not monitor.isColor() then
                return false
            end
        end
    end

    return true
end

bigMonitor.isColor = bigMonitor.isColour

function bigMonitor.setTextColour(colour)
    for _, line in pairs(setup) do
        for _, monitor_name in pairs(line) do
            local monitor = peripheral.wrap(monitor_name)
            monitor.setTextColour(colour)
        end
    end
    TextColour = colour
end

bigMonitor.setTextColor = bigMonitor.setTextColour

function bigMonitor.getTextColour()
    return TextColour
end

bigMonitor.getTextColor = bigMonitor.getTextColour

function bigMonitor.getCursorPos()
    return posx, posy
end

function bigMonitor.setPaletteColor(...)
    for _, line in pairs(setup) do
        for _, monitor_name in pairs(line) do
            local monitor = peripheral.wrap(monitor_name)
            monitor.setPaletteColour(...)
        end
    end
end

bigMonitor.setPaletteColour = bigMonitor.setPaletteColor

function bigMonitor.getPaletteColor(colour)
    local monitor = peripheral.wrap(setup[1][1])
    return monitor.getPaletteColor(colour)
end

bigMonitor.setPaletteColour = bigMonitor.getPaletteColor

function bigMonitor.setCursorBlink(blink)
    _blink = blink
    local fullWidth, fullHeight = bigMonitor.getSize()
    local lineHeight = 0

    for _, line in pairs(setup) do
        local monitor = peripheral.wrap(line[1])
        local width, height = monitor.getSize()
    
        lineHeight = lineHeight + height

        if posy <= lineHeight then
            local lineWidth = 0

            for _, monitor_name in pairs(line) do
                local monitor = peripheral.wrap(monitor_name)
                local width, height = monitor.getSize()
                lineWidth = lineWidth + width

                if posx <= lineWidth then
                    monitor.setCursorBlink(_blink)
                    return
                end
            end
        end
    end
end

function bigMonitor.getCursorBlink()
    return _blink
end

function bigMonitor.scroll(y)
    for _, line in pairs(setup) do
        for _, monitor_name in pairs(line) do
            local monitor = peripheral.wrap(monitor_name)
            monitor.scroll(y)
        end
    end
end

return bigMonitor
