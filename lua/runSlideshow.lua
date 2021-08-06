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

while true do
    for _,file_path in pairs(fs.find(shell.dir() .. "/*.nfp")) do
        local file = fs.open(file_path, "r")
        local backgroundColour = true
        local text, textColour = "",""
        local y = 1

        while backgroundColour do
            backgroundColour = file.readLine()
            if backgroundColour then
                for i = 1, string.len(backgroundColour) do
                    text = text .. " "
                    textColour = textColour .. "0"
                end
                
                mon.setCursorPos(1,y)
                mon.blit(text, textColour, backgroundColour)
                y = y + 1
            end
        end

        file.close()
        sleep(10)
    end
end
