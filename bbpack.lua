-- +---------------------+------------+---------------------+
-- |                     |            |                     |
-- |                     |   BBPack   |                     |
-- |                     |            |                     |
-- +---------------------+------------+---------------------+

local version = "Version 1.6.1"
local bbpack = {}
-- Pastebin uploader/downloader for ComputerCraft, by Jeffrey Alexander (aka Bomb Bloke).
-- Handles multiple files in a single paste, as well as non-ASCII symbols within files.
-- Used to be called "package".
-- http://www.computercraft.info/forums2/index.php?/topic/21801-
-- pastebin get cUYTGbpb bbpack

---------------------------------------------
------------Variable Declarations------------
---------------------------------------------

local band, brshift, blshift = bit.band, bit.brshift, bit.blshift

local b64 = {}
for i = 1, 64 do
    b64[i - 1] = ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"):byte(i)
    b64[("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"):sub(i, i)] = i - 1
end

---------------------------------------------
------------Function Declarations------------
---------------------------------------------

local unpack = unpack or table.unpack

local function snooze()
    local myEvent = tostring({})
    os.queueEvent(myEvent)
    os.pullEvent(myEvent)
end

local function toBase64Internal(inputlist)
    if type(inputlist) ~= "table" then
        error("bbpack.toBase64: Expected: table or file handle", 2)
    end

    if inputlist.read then
        local templist, len = {}, 1

        for byte in inputlist.read do
            templist[len] = byte
            len = len + 1
        end

        inputlist.close()
        inputlist = templist
    elseif inputlist.readLine then
        inputlist.close()
        error("bbpack.toBase64: Use a binary-mode file handle", 2)
    end

    if #inputlist == 0 then
        return ""
    end

    local curbit, curbyte, outputlist, len = 32, 0, {}, 1

    for i = 1, #inputlist do
        local inByte, mask = inputlist[i], 128

        for j = 1, 8 do
            if band(inByte, mask) == mask then
                curbyte = curbyte + curbit
            end
            curbit, mask = curbit / 2, mask / 2

            if curbit < 1 then
                outputlist[len] = b64[curbyte]
                curbit, curbyte, len = 32, 0, len + 1
            end
        end
    end

    if curbit > 1 then
        outputlist[len] = b64[curbyte]
    end

    return string.char(unpack(outputlist))
end

local function fromBase64Internal(inData)
    if type(inData) ~= "string" and type(inData) ~= "table" then
        error("bbpack.fromBase64: Expected: string or file handle", 2)
    end

    if type(inData) == "table" then
        if inData.readLine then
            local temp = inData.readAll()
            inData.close()
            inData = temp
        else
            if inData.close then
                inData.close()
            end
            error("bbpack.fromBase64: Use text-mode file handles", 2)
        end
    end

    if #inData == 0 then
        return {}
    end

    local curbyte, curbit, outputlist, len = 0, 128, {}, 1

    for i = 1, #inData do
        local mask, curchar = 32, b64[inData:sub(i, i)]

        for j = 1, 6 do
            if band(curchar, mask) == mask then
                curbyte = curbyte + curbit
            end
            curbit, mask = curbit / 2, mask / 2

            if curbit < 1 then
                outputlist[len] = curbyte
                curbit, curbyte, len = 128, 0, len + 1
            end
        end
    end

    if curbit > 1 and curbyte > 0 then
        outputlist[len] = curbyte
    end

    return outputlist
end

local function compressIterator(ClearCode)
    local startCodeSize = 1
    while math.pow(2, startCodeSize) < ClearCode do
        startCodeSize = startCodeSize + 1
    end

    local EOI, ClearCode = math.pow(2, startCodeSize) + 1, math.pow(2, startCodeSize)
    startCodeSize = startCodeSize + 1

    local curstring, len, curbit, curbyte, outputlist, codes, CodeSize, MaxCode, nextcode, curcode =
        "",
        2,
        1,
        0,
        {0},
        {},
        startCodeSize,
        math.pow(2, startCodeSize) - 1,
        EOI + 1

    local function packByte(num)
        local mask = 1

        for i = 1, CodeSize do
            if band(num, mask) == mask then
                curbyte = curbyte + curbit
            end
            curbit, mask = curbit * 2, mask * 2

            if curbit > 128 or (i == CodeSize and num == EOI) then
                local counter = blshift(brshift(#outputlist - 1, 8), 8) + 1
                outputlist[counter] = outputlist[counter] + 1

                if outputlist[counter] > 255 then
                    outputlist[counter], outputlist[counter + 256], len = 255, 1, len + 1
                    snooze()
                end

                outputlist[len] = curbyte
                curbit, curbyte, len = 1, 0, len + 1
            end
        end
    end

    packByte(ClearCode)

    return function(incode)
        if not incode then
            if curcode then
                packByte(curcode)
            end
            packByte(EOI)
            outputlist[#outputlist + 1] = 0
            return outputlist
        end

        if not curcode then
            curcode = incode
            return
        end

        curstring = curstring .. string.char(incode)
        local thisCode = codes[curstring]

        if thisCode then
            curcode = thisCode
        else
            codes[curstring] = nextcode
            nextcode = nextcode + 1

            packByte(curcode)

            if nextcode == MaxCode + 2 then
                CodeSize = CodeSize + 1
                MaxCode = math.pow(2, CodeSize) - 1
            end

            if nextcode == 4095 then
                packByte(ClearCode)
                CodeSize, MaxCode, nextcode, codes = startCodeSize, math.pow(2, startCodeSize) - 1, EOI + 1, {}
            end

            curcode, curstring = incode, string.char(incode)
        end
    end
end

local function compressInternal(inputlist, valRange)
    if type(inputlist) ~= "table" and type(inputlist) ~= "string" then
        error("bbpack.compress: Expected: table, string or file handle", 2)
    end

    if not valRange then
        valRange = 256
    end
    if type(valRange) ~= "number" or valRange < 2 or valRange > 256 then
        error("bbpack.compress: Value range must be a number between 2 - 256.", 2)
    end

    if type(inputlist) == "table" and inputlist.close then
        local templist
        if inputlist.readAll then
            templist = inputlist.readAll()
        else
            local len = 1
            templist = {}
            for thisByte in inputlist.read do
                templist[len] = thisByte
                len = len + 1
            end
        end
        inputlist.close()
        inputlist = templist
    end

    if type(inputlist) == "string" then
        inputlist = {inputlist:byte(1, #inputlist)}
    end

    if #inputlist == 0 then
        return {}
    end

    local compressIt = compressIterator(valRange)

    local sleepCounter = 0
    for i = 1, #inputlist do
        compressIt(inputlist[i])

        sleepCounter = sleepCounter + 1
        if sleepCounter > 1023 then
            sleepCounter = 0
            snooze()
        end
    end

    return compressIt(false)
end

local function decompressIterator(ClearCode, codelist)
    local startCodeSize = 1
    while math.pow(2, startCodeSize) < ClearCode do
        startCodeSize = startCodeSize + 1
    end

    local EOI, ClearCode = math.pow(2, startCodeSize) + 1, math.pow(2, startCodeSize)
    startCodeSize = startCodeSize + 1

    local lastcounter, curbyte, spot, CodeSize, MaxCode, maskbit, nextcode, codes, gotbytes =
        codelist[1],
        codelist[2],
        3,
        startCodeSize,
        math.pow(2, startCodeSize) - 1,
        1,
        EOI + 1,
        {},
        1
    for i = 0, ClearCode - 1 do
        codes[i] = string.char(i)
    end

    return function()
        while true do
            local curcode, curbit = 0, 1

            for i = 1, CodeSize do
                if band(curbyte, maskbit) == maskbit then
                    curcode = curcode + curbit
                end
                curbit, maskbit = curbit * 2, maskbit * 2

                if maskbit > 128 and not (i == CodeSize and curcode == EOI) then
                    maskbit, curbyte, gotbytes = 1, codelist[spot], gotbytes + 1
                    spot = spot + 1

                    if gotbytes > lastcounter then
                        if curbyte == 0 then
                            break
                        end
                        lastcounter, gotbytes = curbyte, 1
                        curbyte = codelist[spot]
                        spot = spot + 1
                        snooze()
                    end
                end
            end

            if curcode == ClearCode then
                CodeSize, MaxCode, nextcode, codes = startCodeSize, math.pow(2, startCodeSize) - 1, EOI + 1, {}
                for i = 0, ClearCode - 1 do
                    codes[i] = string.char(i)
                end
            elseif curcode ~= EOI then
                if codes[nextcode - 1] then
                    codes[nextcode - 1] = codes[nextcode - 1] .. codes[curcode]:sub(1, 1)
                else
                    codes[nextcode - 1] = codes[curcode]:sub(1, 1)
                end

                if nextcode < 4096 then
                    codes[nextcode] = codes[curcode]
                    nextcode = nextcode + 1
                end

                if nextcode - 2 == MaxCode then
                    CodeSize = CodeSize + 1
                    MaxCode = math.pow(2, CodeSize) - 1
                end

                return codes[curcode]
            else
                return
            end
        end
    end
end

local function decompressInternal(codelist, outputText, valRange)
    if type(codelist) ~= "table" then
        error("bbpack.decompress: Expected: table or file handle", 2)
    end

    if not valRange then
        valRange = 256
    end
    if type(valRange) ~= "number" or valRange < 2 or valRange > 256 then
        error("bbpack.decompress: Value range must be a number between 2 - 256.", 2)
    end

    if codelist.readLine then
        codelist.close()
        error("bbpack.decompress: Use binary-mode file handles", 2)
    elseif codelist.readAll then
        codelist = codelist.readAll()
        codelist = {codelist:byte(1, #codelist)}
    elseif codelist.read then
        local data, len = {}, 1
        while true do
            local amount = codelist.read()
            data[len] = amount
            len = len + 1

            if amount == 0 then
                break
            end

            for i = 1, amount do
                data[len] = codelist.read()
                len = len + 1
            end

            snooze()
        end
        codelist = data
    elseif #codelist == 0 then
        return outputText and "" or {}
    end

    local outputlist, decompressIt, len = {}, decompressIterator(valRange, codelist), 1

    local sleepCounter = 0
    while true do
        local output = decompressIt()

        if output then
            outputlist[len] = output
            len = len + 1
        else
            break
        end
    end

    outputlist = table.concat(outputlist)

    return outputText and outputlist or {outputlist:byte(1, #outputlist)}
end

local function uploadPasteInternal(name, content)
    if type(name) ~= "string" or (type(content) ~= "string" and type(content) ~= "table") then
        error("bbpack.uploadPaste: Expected: (string) paste name, (string or file handle) paste content", 2)
    end

    if type(content) == "table" then
        if content.readLine then
            local temp = content.readAll()
            content.close()
            content = temp
        else
            if content.close then
                content.close()
            end
            error("bbpack.uploadPaste: Use text-mode file handles", 2)
        end
    end

    local webHandle =
        http.post(
        "https://pastebin.com/api/api_post.php",
        "api_option=paste&" ..
            "api_dev_key=147764e5c6ac900a3015d77811334df1&" ..
                "api_paste_format=lua&" ..
                    "api_paste_name=" ..
                        textutils.urlEncode(name) .. "&" .. "api_paste_code=" .. textutils.urlEncode(content)
    )

    if webHandle then
        local response = webHandle.readAll()
        webHandle.close()
        return string.match(response, "[^/]+$")
    else
        error(
            "Connection to pastebin failed. http API config in ComputerCraft.cfg is enabled, but may be set to block pastebin - or pastebin servers may be busy."
        )
    end
end

local function downloadPasteInternal(pasteID)
    if type(pasteID) ~= "string" then
        error("bbpack.downloadPaste: Expected: (string) paste ID", 2)
    end

    local webHandle = http.get("https://pastebin.com/raw/" .. textutils.urlEncode(pasteID))

    if webHandle then
        local incoming = webHandle.readAll()
        webHandle.close()
        return incoming
    else
        error(
            "Connection to pastebin failed. http API config in ComputerCraft.cfg is enabled, but may be set to block pastebin - or pastebin servers may be busy."
        )
    end
end

---------------------------------------------
------------     Load As API     ------------
---------------------------------------------

bbpack.compress = compressInternal
bbpack.decompress = decompressInternal

bbpack.toBase64 = toBase64Internal
bbpack.fromBase64 = fromBase64Internal

bbpack.uploadPaste = uploadPasteInternal
bbpack.downloadPaste = downloadPasteInternal

function bbpack.open(file, mode, valRange)
    if (type(file) ~= "table" and type(file) ~= "string") or type(mode) ~= "string" then
        error(
            "bbpack.open: Expected: file (string or handle), mode (string). Got: " ..
                type(file) .. ", " .. type(mode) .. ".",
            2
        )
    end

    mode = mode:lower()
    local binary, append, read, write, newhandle =
        mode:find("b") ~= nil,
        mode:find("a") ~= nil,
        mode:find("r") ~= nil,
        mode:find("w") ~= nil,
        {}

    if not valRange then
        valRange = 256
    end
    if type(valRange) ~= "number" or valRange < 2 or valRange > 256 then
        error("bbpack.decompress: Value range must be a number between 2 - 256.", 2)
    end

    if not (append or write or read) then
        error("bbpack.open: Invalid file mode: " .. mode, 2)
    end

    if type(file) == "string" then
        if append and fs.exists(file) then
            local oldfile = open(file, binary and "rb" or "r", valRange)
            if not oldfile then
                return nil
            end
            local olddata = oldfile.readAll()
            oldfile.close()

            newhandle = open(file, binary and "wb" or "w", valRange)
            newhandle.write(olddata)
            return newhandle
        end

        file = fs.open(file, (read and "r" or "w") .. "b")
        if not file then
            return nil
        end
    else
        if (write and (file.writeLine or not file.write)) or (read and not file.read) then
            error("bbpack.open: Handle / mode mismatch.", 2)
        end

        local tempfile, keys = {}, {}

        for key, _ in pairs(file) do
            keys[#keys + 1] = key
        end
        for i = 1, #keys do
            tempfile[keys[i]] = file[keys[i]]
            file[keys[i]] = nil
        end

        file = tempfile
    end

    if read then
        local data = {}
        if file.readAll then
            local len = 1

            while true do
                local amount = file.read()
                data[len] = string.char(amount)
                len = len + 1

                if amount == 0 then
                    break
                end

                data[len] = file.read(amount)
                len = len + 1
            end

            data = table.concat(data)
            data = {data:byte(1, #data)}
        else
            local len = 1

            while true do
                local amount = file.read()
                data[len] = amount
                len = len + 1

                if amount == 0 then
                    break
                end

                for i = 1, amount do
                    data[len] = file.read()
                    len = len + 1
                end

                snooze()
            end
        end

        local decompressIt, outputlist = decompressIterator(valRange, data), ""

        if binary then
            function newhandle.read(amount)
                if not outputlist then
                    return nil
                end

                if type(amount) ~= "number" then
                    if #outputlist == 0 then
                        outputlist = decompressIt()
                        if not outputlist then
                            return nil
                        end
                    end

                    local result = outputlist:byte(1)
                    outputlist = outputlist:sub(2)
                    return result
                else
                    while #outputlist < amount do
                        local new = decompressIt()

                        if not new then
                            new = outputlist
                            outputlist = nil
                            if #new > 0 then
                                return new
                            else
                                return
                            end
                        end

                        outputlist = outputlist .. new
                    end

                    local result = outputlist:sub(1, amount)
                    outputlist = outputlist:sub(amount + 1)
                    return result
                end
            end

            function newhandle.readAll()
                if not outputlist then
                    return nil
                end

                local result, len = {outputlist}, 2
                for data in decompressIt do
                    result[len] = data
                    len = len + 1
                end

                outputlist = nil

                return table.concat(result)
            end
        else
            function newhandle.readLine()
                if not outputlist then
                    return nil
                end

                while not outputlist:find("\n") do
                    local new = decompressIt()

                    if not new then
                        new = outputlist
                        outputlist = nil
                        if #new > 0 then
                            return new
                        else
                            return
                        end
                    end

                    outputlist = outputlist .. new
                end

                local result = outputlist:sub(1, outputlist:find("\n") - 1)
                outputlist = outputlist:sub(outputlist:find("\n") + 1)

                if outputlist:byte(1) == 13 then
                    outputlist = outputlist:sub(2)
                end

                return result
            end

            function newhandle.readAll()
                if not outputlist then
                    return nil
                end

                local result, len = {outputlist}, 2
                for data in decompressIt do
                    result[len] = data
                    len = len + 1
                end

                outputlist = nil

                return table.concat(result)
            end
        end

        function newhandle.extractHandle()
            local keys = {}
            for key, _ in pairs(newhandle) do
                keys[#keys + 1] = key
            end
            for i = 1, #keys do
                newhandle[keys[i]] = nil
            end
            return file
        end
    else
        local compressIt = compressIterator(valRange)

        if binary then
            function newhandle.write(data)
                if type(data) == "number" then
                    compressIt(data)
                elseif type(data) == "string" then
                    data = {data:byte(1, #data)}
                    for i = 1, #data do
                        compressIt(data[i])
                    end
                else
                    error(
                        "bbpackHandle.write: bad argument #1 (string or number expected, got " .. type(data) .. ")",
                        2
                    )
                end
            end
        else
            function newhandle.write(text)
                text = tostring(text)
                text = {text:byte(1, #text)}
                for i = 1, #text do
                    compressIt(text[i])
                end
            end

            function newhandle.writeLine(text)
                text = tostring(text)
                text = {text:byte(1, #text)}
                for i = 1, #text do
                    compressIt(text[i])
                end
                compressIt(10)
            end
        end

        newhandle.flush = file.flush

        function newhandle.extractHandle()
            local output, fWrite = compressIt(false), file.write
            for j = 1, #output do
                fWrite(output[j])
            end
            local keys = {}
            for key, _ in pairs(newhandle) do
                keys[#keys + 1] = key
            end
            for i = 1, #keys do
                newhandle[keys[i]] = nil
            end
            return file
        end
    end

    function newhandle.close()
        newhandle.extractHandle().close()
    end

    return newhandle
end

function bbpack.lines(file)
    if type(file) == "string" then
        file = open(file, "r")
    elseif type(file) ~= "table" or not file.readLine then
        error('bbpack.lines: Expected: file (string or "r"-mode handle).', 2)
    end

    return function()
        if not file.readLine then
            return nil
        end

        local line = file.readLine()
        if line then
            return line
        else
            file.close()
            return nil
        end
    end
end

local function dividePath(path)
    local result = {}
    for element in path:gmatch("[^/]+") do
        result[#result + 1] = element
    end
    return result
end

local function getGithubRepo(repo)
    local elements = dividePath(repo)
    for i = 1, #elements do
        if table.remove(elements, 1) == "github.com" then
            break
        end
    end
    if #elements < 2 or elements[3] == "raw" then
        return
    end
    repo = elements[1] .. "/" .. elements[2]
    local branch = (elements[3] == "tree") and elements[4] or "master"

    local webHandle = http.get("https://api.github.com/repos/" .. repo .. "/git/trees/" .. branch .. "?recursive=1")
    if not webHandle then
        return
    end
    local json =
        textutils.unserialize(
        webHandle.readAll():gsub("\10", ""):gsub(" ", ""):gsub("%[", "{"):gsub("]", "}"):gsub('{"', '{["'):gsub(
            ',"',
            ',["'
        ):gsub('":', '"]=')
    )
    webHandle.close()
    if json.message == "Not Found" then
        return
    end

    local tree, results = json.tree, {}

    for i = 1, #tree do
        if tree[i].type == "blob" then
            local path, cur = tree[i].path, results
            local elements = dividePath(path)

            for i = 1, #elements - 1 do
                local element = elements[i]
                if not cur[element] then
                    cur[element] = {}
                end
                cur = cur[element]
            end

            cur[elements[#elements]] = "https://raw.githubusercontent.com/" .. repo .. "/" .. branch .. "/" .. path
        end
    end

    if #elements > 4 then
        for i = 5, #elements do
            results = results[elements[i]]
        end
    end

    return (type(results) == "table") and results
end

local configTable = {["webMounts"] = {}, ["githubRepos"] = {}, ["clusters"] = {}, ["compressedFS"] = false}

if fs.exists(".bbpack.cfg") then
    local file = fs.open(".bbpack.cfg", "r") or fs.open(".bbpack.cfg", "r")
    local input = textutils.unserialize(file.readAll())
    file.close()

    if type(input) == "table" then
        if type(input.webMounts) == "table" then
            configTable.webMounts = input.webMounts
        end
        if type(input.githubRepos) == "table" then
            configTable.githubRepos = input.githubRepos
        end
        if type(input.clusters) == "table" then
            configTable.clusters = input.clusters
        end
        if type(input.compressedFS) == "boolean" then
            configTable.compressedFS = input.compressedFS
        end
    end
end

local webMountList, clusterList, repoList = configTable.webMounts, configTable.clusters, {}
for path, url in pairs(configTable.githubRepos) do
    repoList[path] = getGithubRepo(url)
end
if next(clusterList) then
    for _, side in pairs(rs.getSides()) do
        if peripheral.getType(side) == "modem" then
            rednet.open(side)
        end
    end
end
local blacklist = {"bbpack", "bbpack.lua", "startup", "startup.lua", ".settings", ".gif", ".zip", ".bbpack.cfg"}

bbpack.update = function()
    for cluster, ids in pairs(clusterList) do
        for i = 1, #ids do
            rednet.send(ids[i], {["cluster"] = cluster, "update"}, rednet.host and cluster)
        end
    end

    local file = fs.open("bbpack", "w")
    file.write(downloadPasteInternal("cUYTGbpb"))
    file.close()

    os.reboot()
end

bbpack.fileSys =
    bbpack and bbpack.fileSys or
    function(par1, par2)
        if type(par1) == "boolean" or (type(par1) == "string" and type(par2) == "boolean") then
            -- Compress / decompress hdd contents.
            local list
            if type(par1) == "boolean" then
                list = fs.list("")
                configTable.compressedFS = par1
            else
                list = {par1}
                par1 = par2
            end

            while #list > 0 do
                local entry = list[#list]
                list[#list] = nil

                if fs.getDrive(entry) == "hdd" and not webMountList[entry] then
                    if fs.isDir(entry) then
                        local newList, curLen = fs.list(entry), #list
                        for i = 1, #newList do
                            list[curLen + i] = fs.combine(entry, newList[i])
                        end
                    else
                        local blacklisted = false

                        for i = 1, #blacklist do
                            local check = blacklist[i]
                            if entry:sub(-(#check)):lower() == check then
                                blacklisted = true
                                break
                            end
                        end

                        if not blacklisted then
                            if par1 and entry:sub(-4) ~= ".bbp" then
                                -- Compress this file.
                                local file, content = fs.open(entry, "rb")
                                if file.readAll then
                                    content = file.readAll()
                                else
                                    content = {}
                                    local counter = 1
                                    for byte in file.read do
                                        content[counter] = byte
                                        counter = counter + 1
                                    end
                                    content = string.char(unpack(content))
                                end
                                file.close()

                                content = compressInternal(content)
                                if fs.getFreeSpace(entry) + fs.getSize(entry) < #content then
                                    return false
                                end
                                fs.delete(entry)
                                snooze()

                                file = fs.open(entry .. ".bbp", "wb")

                                if term.setPaletteColor then
                                    file.write(string.char(unpack(content)))
                                else
                                    for i = 1, #content do
                                        file.write(content[i])
                                    end
                                end

                                file.close()

                                snooze()
                            elseif not par1 and entry:sub(-4) == ".bbp" then
                                -- Decompress this file.
                                local file = open(entry, "rb")
                                local content = file.readAll()
                                file.close()

                                if fs.getFreeSpace(entry) + fs.getSize(entry) < #content then
                                    return false
                                end
                                fs.delete(entry)
                                snooze()

                                file = fs.open(entry:sub(1, -5), "wb")

                                if term.setPaletteColor then
                                    file.write(content)
                                else
                                    content = {content:byte(1, #content)}
                                    for i = 1, #content do
                                        file.write(content[i])
                                    end
                                end

                                file.close()

                                snooze()
                            end
                        end
                    end
                end
            end
        elseif type(par1) == "string" and type(par2) == "string" then
            -- New web mount.
            local url, path = par1, fs.combine(par2, "")
            local elements = dividePath(path)

            local repo = getGithubRepo(url)
            if repo then
                if #elements > 1 then
                    error("bbpack.mount: Github repos must be mounted at the root of your file system", 2)
                end
                repoList[path] = repo
                configTable.githubRepos[path] = url
            else
                if fs.getDrive(elements[1]) and fs.getDrive(elements[1]) ~= "hdd" then
                    error("bbpack.mount: web mounts must be located on the main hdd", 2)
                end

                local get = http.get(url)
                if not get then
                    error("bbpack.mount: Can't connect to URL: " .. url, 2)
                end
                get.close()

                webMountList[path] = url
            end
        elseif type(par1) == "string" then
            -- New cluster mount.
            local cluster, uuid = par1, math.random(1, 0x7FFFFFFF)
            for _, side in pairs(rs.getSides()) do
                if peripheral.getType(side) == "modem" then
                    rednet.open(side)
                end
            end
            rednet.broadcast({["cluster"] = cluster, ["uuid"] = uuid, "rollcall"}, rednet.host and cluster)
            clusterList[cluster] = nil
            local myTimer, map = os.startTimer(5), {}

            while true do
                local event, par1, par2 = os.pullEvent()

                if event == "timer" and par1 == myTimer then
                    break
                elseif
                    event == "rednet_message" and type(par2) == "table" and par2.cluster == cluster and
                        par2.uuid == uuid and
                        par2[1] == "rollcallResponse"
                 then
                    map[#map + 1] = par1
                end
            end

            if #map == 0 then
                error("bbpack.mount: Can't connect to cluster: " .. cluster, 2)
            end
            clusterList[cluster] = map
        end

        local file = fs.open(".bbpack.cfg", "w")
        file.write(textutils.serialize(configTable))
        file.close()

        return true
    end

return bbpack
