local GIF = require("GIF")
local json = require("json")

local bigMonitor1 = dofile("root/bigMonitor.lua")
bigMonitor1.init(json.decode(fs.open(shell.dir() .. "/bigMonitor1.json", "r").readAll()))

local bigMonitor2 = dofile("root/bigMonitor.lua")
bigMonitor2.init(json.decode(fs.open(shell.dir() .. "/bigMonitor2.json", "r").readAll()))

local mon = require("multiMonitor")

mon.init(
    {
        bigMonitor1,
        bigMonitor2
    }
)

mon.setTextScale(0.5)
local x, y = mon.getSize()

print("loadGIF")
local image = GIF.loadGIF(fs.find(shell.dir() .. "/*.gif")[1])

--print("resizeGIF")
--image = GIF.resizeGIF(image,mon.getSize())

print("drawGIF/animateGIF")
--mon.setBackgroundColour(image[1].transparentCol or image.backgroundCol)
mon.setBackgroundColour(colours.white)

mon.clear()
--GIF.drawGIF(image[1], math.floor((x - image.width) / 2) + 1, math.floor((y - image.height) / 2) + 1, mon)
GIF.animateGIF(image, math.floor((x - image.width) / 2) + 1, math.floor((y - image.height) / 2) + 1, mon)
