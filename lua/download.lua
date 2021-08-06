local url_base = "https://raw.githubusercontent.com/Commandcracker/CC-Images/master/lua/"
local urls = {
    "runSlideshow.lua",
    "runMon.lua",
    "runGIF.lua",
    "lib/multiMonitor.lua",
    "lib/json.lua",
    "bigMonitor2.json",
    "bigMonitor1.json",
    "lib/bigMonitor.lua",
    "lib/bbpack.lua",
    "lib/GIF.lua"
}

for _,url in pairs(urls) do
    shell.run("wget", url_base..url)
end
