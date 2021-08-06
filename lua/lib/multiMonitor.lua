-- © Commandcracker
-- TODO:
--[[
    ! fix old CC Color and Colour
]]
-- the monitor
local multiMonitor = {}

local textScale = 1
local BackgroundColor = colors.black
local TextColour = colors.white
local posy = 1
local posx = 1
local _monitors
local _blink = false

function multiMonitor.init(monitors)
    _monitors = monitors
end

function multiMonitor.clearLine()
    for _, monitor in pairs(_monitors) do
        monitor.clearLine()
    end
end

function multiMonitor.getSize()
    return _monitors[1].getSize()
end

function multiMonitor.clear()
    for _, monitor in pairs(_monitors) do
        monitor.clear()
    end
end

function multiMonitor.setTextScale(scale)
    for _, monitor in pairs(_monitors) do
        monitor.setTextScale(scale)
    end
    textScale = scale
end

function multiMonitor.getTextScale()
    return textScale
end

function multiMonitor.setBackgroundColour(colour)
    for _, monitor in pairs(_monitors) do
        monitor.setBackgroundColour(colour)
    end
    BackgroundColor = colour
end

multiMonitor.setBackgroundColor = multiMonitor.setBackgroundColour

function multiMonitor.getBackgroundColor()
    return BackgroundColor
end

multiMonitor.getBackgroundColour = multiMonitor.getBackgroundColor

function multiMonitor.setCursorPos(x, y)
    posy = y
    posx = x
    for _, monitor in pairs(_monitors) do
        monitor.setCursorPos(x, y)
    end
end

function multiMonitor.write(text)
    for _, monitor in pairs(_monitors) do
        monitor.write(text)
    end
end

function multiMonitor.blit(text, textColour, backgroundColour)
    for _, monitor in pairs(_monitors) do
        monitor.blit(text, textColour, backgroundColour)
    end
end

function multiMonitor.isColour()
    for _, monitor in pairs(_monitors) do
        if not monitor.isColor() then
            return false
        end
    end

    return true
end

multiMonitor.isColor = multiMonitor.isColour

function multiMonitor.setTextColour(colour)
    for _, monitor in pairs(_monitors) do
        monitor.setTextColour(colour)
    end
    TextColour = colour
end

multiMonitor.setTextColor = multiMonitor.setTextColour

function multiMonitor.getTextColour()
    return TextColour
end

multiMonitor.getTextColor = multiMonitor.getTextColour

function multiMonitor.getCursorPos()
    return posx, posy
end

function multiMonitor.setPaletteColor(...)
    for _, monitor in pairs(_monitors) do
        monitor.setPaletteColour(...)
    end
end

multiMonitor.setPaletteColour = multiMonitor.setPaletteColor

function multiMonitor.getPaletteColor(colour)
    return _monitors[1].getPaletteColor(colour)
end

multiMonitor.setPaletteColour = multiMonitor.getPaletteColor

function multiMonitor.setCursorBlink(blink)
    _blink = blink

    for _, monitor in pairs(_monitors) do
        monitor.setCursorBlink(blink)
    end
end

function multiMonitor.getCursorBlink()
    return _blink
end

function multiMonitor.scroll(y)
    for _, monitor in pairs(_monitors) do
        monitor.scroll(y)
    end
end

return multiMonitor
