local url_base = "https://raw.githubusercontent.com/Commandcracker/CC-Images/master/"
local urls = {
    "runMon.lua",
    "runGIF.lua",
    "multiMonitor.lua",
    "json.lua",
    "bigMonitor2.json",
    "bigMonitor1.json",
    "bigMonitor.lua",
    "bbpack.lua",
    "GIF.lua"
}

for _,url in pairs(urls) do
    shell.run("wget", url_base..url)
end
