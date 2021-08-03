local GIF = require("GIF")
local json = require("json")
local mon = require("bigMonitor")
mon.init(json.decode(fs.open(shell.dir() .. "/monitors.json", "r").readAll()))

mon.setTextScale(0.5)
local x, y = mon.getSize()

print("loadGIF")
local image = GIF.loadGIF(fs.find("stuff/*.gif")[1])

--print("resizeGIF")
--image = GIF.resizeGIF(image,mon.getSize())

print("drawGIF/animateGIF")
--mon.setBackgroundColour(image[1].transparentCol or image.backgroundCol)
mon.setBackgroundColour(colours.white)

mon.clear()
--GIF.drawGIF(image[1], math.floor((x - image.width) / 2) + 1, math.floor((y - image.height) / 2) + 1, mon)
GIF.animateGIF(image, math.floor((x - image.width) / 2) + 1, math.floor((y - image.height) / 2) + 1, mon)
