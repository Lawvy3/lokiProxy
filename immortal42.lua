-- POINT2===============
-- UTILITY
-- CONFIG MANAGER
-- COMMAND MANAGER
-- DIALOG
-- CONTROLLER
-- NAME HANDLER
-- DIALOG HANDLER
-- PACKET HOOK
-- WORLDTOUCH
-- HOTKEY
-- RAW HOOK
-- VARIANTHOOK
-- INITIALIZE
-- =====================
local customWatermark = "`9[`4IMMORTAL`0by`2Loki``````] ``"

local ver = "4.2"

local is_windows = package.config:sub(1, 1) == "\\"

local CONFIG_FILE
if is_windows then
    CONFIG_FILE = "C:/Users/" .. os.getenv("USERNAME") .. "/AppData/local/Growtopia/scripts/immortalConfig.bin" -- Ganti sesuai path Windows
else
    CONFIG_FILE = "storage/emulated/0/Android/media/com.rtsoft.growtopia/scripts/immortalConfig.bin" -- Path untuk Android
end

local watermark = (customWatermark ~= "" and customWatermark or "`9[`4IMMORTAL``] ``")


local const = {
    itemId = {
        champagne = GetItemInfo("Champagne").id,
        wl = 242,
        dl = 1796,
        bgl = 7188,
        black = 11550,
        cc = GetItemInfo("Creative Coin").id
    }
}

local config = {
    autohost = {
        room1 = {
            x = 0,
            y = 0,
            direction = "left"
        },
        room2 = {
            x = 0,
            y = 0,
            direction = "left"
        },
        tax = 0,
        vertical = 0,
        gems1 = {
            x = 0,
            y = 0
        },
        gems2 = {
            x = 0,
            y = 0
        }
    },
    chat = {
        wm = "",
        color = ""
    },
    currency = {
        cvdl = 1,
        cvbgl = 1,
        cvblack = 1
    },

    autopull = {
        tile = {
            x = 0,
            y = 0
        },
        notify = 0,
        minimum = 0,
        status = 0,
        minDelay = 50,
        maxDelay = 250,
        blacklist = {}
    },
    wrench = {
        pText = "Pulled {name}",
        kText = "Kicked {name}",
        bText = "Banned {name}",
        wrp = 0,
        wrk = 0,
        wrb = 0,
        smodal = 0,
        pBody = 0
    },
    wheel = {
        reme = 0,
        leme = 0,
        qeme = 0,
        sspin = 0,
        lastspin = 1
    },
    telephone = {
        fastcv = 0
    },
    others = {
        bsdb = 0,
        imgui = 0,
        hidechamp = 0,
        findpath = 1,
        findpath2 = 1,
        dropMsg = 1,
        collectMsg = 1,
        calcMsg = 1,
        hideslave = 0,
        hideClothes = {},
        fastStorage = 0,
        gameMsg = 0,
        wmMsg = 0
    },
    pt = {
        x = 0,
        y = 0,
        hotkey = 0
    },
    lp = {
        hotkey = 0
    },
    andro = {
        tp = 0
    },
    spam = {
        delay = 5000,
        status = 0,
        text = "`c'/spam' `9For Set Spam Text"
    }
}

local cache = {
    autopull = {
        setap = false,
        dlPulled = 0
    },
    lp = {
        uid = 0
    },
    others = {
        pinging = false
    }
}
local storageItems = {}


local player_spin_titles = {}
local name_overrides = {}
local server_names = {}
local is_internal_send = false


local function clearCache()
    cache.autopull.setap = false
    player_spin_titles = {}
    name_overrides = {}
    server_names = {}
    is_internal_send = false
    cache.lp.uid = 0
    storageItems = {}
    startAutoPull = 0


    LogToConsole("`2Successfully `9Cleared Cache")
end


local commands = {}
local aliases = {}

local routes = {}
local controller = {}
local utils = {}
local service = {}

local logs = {
    spin = {},
    collect = {},
    commands = {}
}

local proxyUser = proxyUser or {}

-- UTILITY ============================================================================
function say(msg, public)
    if public then
        SendPacket(2, "action|input\n|text|" .. (config.others.wmMsg == 1 and (config.chat.wm) or "") .. msg)
    else
        SendVariantList({
            [0] = "OnTalkBubble",
            [1] = GetLocal().netid,
            [2] = msg
        })
    end
end

function log(msg)
    LogToConsole(msg)
end

function sendDialog(dialog)
    local result = {}

    for _, v in pairs(dialog) do
        table.insert(result, v)
    end

    table.insert(result, "set_border_color|110,60,150,255")
    table.insert(result, "set_bg_color|12,30,80,200")

    SendVariantList({
        [0] = "OnDialogRequest",
        [1] = table.concat(result, "\n")
    })
end

function sendOverlay(msg)
    SendVariantList({[0] = "OnTextOverlay", [1] = msg}, -1)
end

function drop(itemId, amount)
    if amount <= 0 then
        return
    end

    SendPacket(
        2,
        "action|dialog_return\n" ..
        "dialog_name|drop\n" ..
        "item_drop|" .. itemId .. "|\n" ..
        "item_count|" .. amount
    )
end

function wear(id)
    SendPacketRaw(false, {
        type = 10,
        value = id
    })
end

function utils.search(keyword)
    -- Validate empty input
    if not keyword or keyword == "" then
        log("`4Please enter a search keyword!``")
        return
    end

    -- Get matching items from game database
    local results = GetItemsByPartialName(keyword)
    local totalFound = #results

    if totalFound == 0 then
        log("`4No items found for: '`2" .. keyword .. "``'")
        return
    end

    -- Header log
    log("`9Search results for '`c" .. keyword .. "``' (`c" .. totalFound .. "`` found):")
    log("`#----------------------------------------``")

    -- Limit results to top 10
    local limit = math.min(totalFound, 10)

    -- Display list
    for i = 1, limit do
        local item = results[i]
        log(string.format(" `w%2d.`` `2%-30s`` `8|`9 ID: `c%d``", i, item.name, item.id))
    end

    -- Warning if results exceed 10
    if totalFound > 10 then
        log("`#----------------------------------------``")
        log(string.format("`4Too many results! `c%d`` additional items hidden. Please refine your query.", totalFound - 10))
    end
end

function utils.wrenchAction(type, netid)
    -- Ambil data player secara aman
    local player = GetPlayer(netid)
    local cleanName = (player and player.name) and player.name or "Unknown"
    cleanName = cleanName:gsub("^`%d%[`%dP`%d%]%s*", ""):gsub("%s*`*%#%[.-%#%]*%s*$", "")

    if type == "smodal" then
        SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netid .. "|\nbuttonClicked|viewinv")
    elseif type == "pull" then
        SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netid .. "|\nbuttonClicked|pull")

        local pText = config.wrench.pText:gsub("{name}", cleanName)
        cache.lp.uid = GetPlayer(netid).userid or 0 

        SendPacket(2, "action|input\n|text|" .. pText)
    elseif type == "kick" then
        SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netid .. "|\nbuttonClicked|kick")

        local kText = config.wrench.kText:gsub("{name}", cleanName)

        SendPacket(2, "action|input\n|text|" .. kText)
    elseif type == "ban" then
        SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netid .. "|\nbuttonClicked|world_ban")

        local bText = config.wrench.bText:gsub("{name}", cleanName)

        SendPacket(2, "action|input\n|text|" .. bText)
    else
        log("`4404 Action Wrench Not Found")
    end
end

function utils.convertLocksCount(amount)
    local WL = amount

    local black = math.floor(WL / 1000000)
    WL = WL % 1000000

    local bgl = math.floor(WL / 10000)
    WL = WL % 10000

    local dl = math.floor(WL / 100)
    WL = WL % 100

    local wl = WL

    return {
        wl = wl,
        dl = dl,
        bgl = bgl,
        black = black
    }
end

function utils.calculate(expr)
    local expr = tostring(expr)
        :gsub("%s+", "")
        :gsub("[xX]", "*")
        :gsub(":", "/")

    if not expr:match("^[%d%.%+%-%*/]+$") then
        return false
    end

    local numbers = {}
    local operators = {}

    for num, op in expr:gmatch("(%d+%.?%d*)([%+%-%*/]?)") do
        table.insert(numbers, tonumber(num))
        if op ~= "" then
            table.insert(operators, op)
        end
    end

    -- Kerjakan * dan /
    local i = 1
    while i <= #operators do
        local op = operators[i]

        if op == "*" or op == "/" then
            local a = numbers[i]
            local b = numbers[i + 1]

            numbers[i] = (op == "*") and (a * b) or (a / b)

            table.remove(numbers, i + 1)
            table.remove(operators, i)
        else
            i = i + 1
        end
    end

    -- Kerjakan + dan -
    local result = numbers[1]

    for i = 1, #operators do
        if operators[i] == "+" then
            result = result + numbers[i + 1]
        else
            result = result - numbers[i + 1]
        end
    end

    return result
end

function utils.lockEffect(x, y)
    local choordinat = y * 100 + x

    SendPacketRaw(true, {
        type = 38,
        netid = choordinat,
        snetid = -1,
        state = 8,
        extDataSize = 100
    })
end

function utils.lbotEffect(x, y)
    local x = x+16
    local y = y+16

    SendPacketRaw(true, {
        type = 17,
        netid = 88,
        snetid = -1,
        x = x,
        y = y,
        xspeed = 8,
        yspeed = 88,
        padding2 = 88,
    })
end

-- Daftar karakter alfanumerik (total 62 karakter)
local CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-=_+[]{};:"

-- Fungsi untuk mencari indeks karakter di dalam string CHARS
local function get_index(char)
    local i = string.find(CHARS, char, 1, true)
    return i
end

-- Fungsi Enkripsi
function utils.encrypt(text, shift)
    shift = shift or 3
    local len_chars = #CHARS
    local result = {}
    
    for i = 1, #text do
        local c = string.sub(text, i, i)
        local idx = get_index(c)
        
        if idx then
            -- Hitung posisi baru dengan pergeseran (1-based index di Lua)
            local new_idx = (idx - 1 + shift) % len_chars + 1
            table.insert(result, string.sub(CHARS, new_idx, new_idx))
        else
            -- Karakter selain alfanumerik (seperti spasi) tetap dipertahankan
            table.insert(result, c)
        end
    end
    
    return table.concat(result)
end

-- Fungsi Dekripsi (membalikkan arah pergeseran)
function utils.decrypt(text, shift)
    shift = shift or 3
    return utils.encrypt(text, -shift)
end

local function isProxyUser(uid)
    return proxyUser[tostring(uid)] ~= nil
end
-- ============================================================================
-- CONFIG MANAGER =============================================================

local function serialize(tbl, indent)

    indent = indent or 0

    local spacing = string.rep("    ", indent)

    local result = "{\n"

    for key, value in pairs(tbl) do

        local keyString =
            "[" ..
            string.format("%q", key) ..
            "]"

        if type(value) == "table" then

            result =
                result ..
                spacing ..
                "    " ..
                keyString ..
                " = " ..
                serialize(value, indent + 1) ..
                ",\n"

        elseif type(value) == "string" then

            result =
                result ..
                spacing ..
                "    " ..
                keyString ..
                " = " ..
                string.format("%q", value) ..
                ",\n"

        else

            result =
                result ..
                spacing ..
                "    " ..
                keyString ..
                " = " ..
                tostring(value) ..
                ",\n"

        end

    end

    result =
        result ..
        spacing ..
        "}"

    return result
end

local function mergeConfig(current, defaults)

    for key, value in pairs(defaults) do

        if current[key] == nil then

            if type(value) == "table" then

                current[key] = {}

                mergeConfig(
                    current[key],
                    value
                )

            else

                current[key] = value

            end

        elseif
            type(value) == "table"
            and
            type(current[key]) == "table"
        then

            mergeConfig(
                current[key],
                value
            )

        end

    end
end

local function saveConfig()

    local file =
        io.open(
            CONFIG_FILE,
            "w"
        )

    if not file then
        return false
    end

    file:write(
        "return " ..
        serialize(config)
    )

    file:close()

    return true
end

local function loadConfig()

    local success, data =
        pcall(
            dofile,
            CONFIG_FILE
        )

    if not success then

        saveConfig()

        return false

    end

    mergeConfig(
        data,
        config
    )

    config = data

    return true
end

local function toggle(tbl, key, bubble, text)

    tbl[key] =
        tbl[key] == 0
        and 1
        or 0

    local status =
        tbl[key] == 1
        and "`2On"
        or "`4Off"

    if text ~= nil then
        log(
            "`9" ..
            text:gsub("(%f[%a]%a)", string.upper) .. " Mode " ..
            status
        )
        if bubble then
            say(
                "`9" ..
                text:gsub("(%f[%a]%a)", string.upper) .. " Mode " ..
                status,
                true
            )
        end
    else
        log(
            "`9" ..
            key:gsub("(%f[%a]%a)", string.upper) .. " Mode " ..
            status
        )
        if bubble then
            say(
                "`9" ..
                key:gsub("(%f[%a]%a)", string.upper) .. " Mode " ..
                status,
                true
            )
        end
    end

    saveConfig()

    return tbl[key]
end

local function setExclusive(tbl, key, others, bubble, text)
    -- matikan semua dulu
    for _, k in ipairs(others) do
        tbl[k] = 0
    end

    -- toggle key utama
    tbl[key] = (tbl[key] == 1 and 0 or 1)



    local status =
        tbl[key] == 1
        and "`2On"
        or "`4Off"

    if text ~= nil then
        log(
            "`9" ..
            text:gsub("(%f[%a]%a)", string.upper) .. " Mode " ..
            status
        )
        if bubble then
            say(
                "`9" ..
                text:gsub("(%f[%a]%a)", string.upper) .. " Mode " ..
                status,
                true
            )
        end
    else
        log(
            "`9" ..
            key:gsub("(%f[%a]%a)", string.upper) .. " Mode " ..
            status
        )
        if bubble then
            say(
                "`9" ..
                key:gsub("(%f[%a]%a)", string.upper) .. " Mode " ..
                status,
                true
            )
        end
    end

    saveConfig()
    return tbl[key]
end
-- ============================================================================
-- COMMAND MANAGER ============================================================

local function registerCommand(data)

    local command = data.command
    local funcName = command:gsub("/", "")

    if type(controller[funcName]) ~= "function" then
        print(
            "`4" ..
            " Controller not found: " ..
            "`9" ..
            funcName
        )
        return false
    end

    routes[command] = controller[funcName]

    -- register aliases
    if data.aliases then
        for _, alias in ipairs(data.aliases) do
            aliases[alias] = command
        end
    end

    local commandData = {
        cmd = command,
        aliases = data.aliases or {},
        desc = data.desc or "",
        argType = data.argType or "none",
        usage = data.usage,
    }

    for _, categoryData in ipairs(commands) do
        if categoryData.category == data.category then

            table.insert(
                categoryData.items,
                commandData
            )

            print(
                "`9" ..
                "Registered command: " ..
                "`2" ..
                command
            )

            return true
        end
    end

    table.insert(commands, {
        category = data.category,
        icon = data.icon,
        items = {
            commandData
        }
    })

    print(
        "`9" ..
        "Registered command: " ..
        "`2" ..
        command
    )

    return true
end

local function getCommands()

    local result = {}

    for _, categoryData in ipairs(commands) do

        table.insert(
            result,
            "add_spacer|small"
        )

        table.insert(
            result,
            "add_label_with_icon|small|" ..
            "`c" ..
            categoryData.category ..
            ":|left|" ..
            categoryData.icon
        )

        for _, commandData in ipairs(categoryData.items) do

            local names = {
                commandData.cmd
            }

            for _, alias in ipairs(commandData.aliases) do
                table.insert(
                    names,
                    alias
                )
            end

            local cmdText =
                table.concat(
                    names,
                    " & "
                )

            if commandData.argType == "required" then

                cmdText =
                    cmdText ..
                    " " ..
                    (commandData.usage or "[arg]")

            elseif commandData.argType == "optional" then

                cmdText =
                    cmdText ..
                    (commandData.usage or "[arg]")

            end

            table.insert(
                result,
                "add_smalltext|" ..
                "`c" ..
                cmdText ..
                " " ..
                "`9" ..
                "(" ..
                commandData.desc ..
                ")|left"
            )
        end
    end

    return table.concat(
        result,
        "\n"
    )
end

local commandSearch = ""

local function drawCommands()

    -- SEARCH
    local changed
    changed, commandSearch = ImGui.InputTextWithHint(
        "##CommandSearch",
        "Search command...",
        commandSearch,
        100
    )

    ImGui.Spacing()

    -- SATU area scroll saja
    if ImGui.BeginChild(
        "CommandsScroll",
        ImVec2(0, 0),
        false
    ) then

        local query = commandSearch:lower()

        for categoryIndex, categoryData in ipairs(commands) do

            -- cek apakah category punya hasil
            local hasResult = false

            for commandIndex, commandData in ipairs(categoryData.items) do

                local names = {
                    commandData.cmd
                }

                -- aliases
                for _, alias in ipairs(commandData.aliases or {}) do
                    table.insert(names, alias)
                end

                -- gabungkan semua yang bisa dicari
                local searchText = table.concat(names, " ")

                searchText = searchText .. " " ..
                    (commandData.usage or "") .. " " ..
                    (commandData.desc or "")

                searchText = searchText:lower()

                if query == "" or searchText:find(query, 1, true) then
                    hasResult = true
                    break
                end
            end

            -- hanya tampilkan category yang punya hasil
            if hasResult then

                -- CATEGORY
                ImGui.Text(categoryData.category)
                ImGui.Separator()

                for commandIndex, commandData in ipairs(categoryData.items) do

                    local names = {
                        commandData.cmd
                    }

                    -- aliases
                    for _, alias in ipairs(commandData.aliases or {}) do
                        table.insert(names, alias)
                    end

                    local cmdText = table.concat(names, " & ")

                    -- usage
                    if commandData.argType == "required" then

                        cmdText = cmdText ..
                            " " ..
                            (commandData.usage or "[arg]")

                    elseif commandData.argType == "optional" then

                        cmdText = cmdText ..
                            " " ..
                            (commandData.usage or "[arg]")
                    end

                    -- text untuk pencarian
                    local searchText =
                        table.concat(names, " ") .. " " ..
                        (commandData.usage or "") .. " " ..
                        (commandData.desc or "")

                    -- tampilkan hanya yang cocok
                    if query == "" or
                        searchText:lower():find(query, 1, true) then

                        ImGui.Text(
                            cmdText ..
                            " (" ..
                            (commandData.desc or "") ..
                            ")"
                        )
                    end
                end

                -- jarak antar category
                ImGui.Spacing()
                ImGui.Spacing()
            end
        end

    end

    ImGui.EndChild()
end

local function commandHandler(type, packet)

    if type == 2 and packet:find("action|input\n|text|/", 1, true) then

        local fullText = packet:match("|text|([^\n]+)")
        local command, args = fullText:match("^(%S+)%s*(.*)$")

        -- alias redirect
        if aliases[command] then
            command = aliases[command]
        end

        for _, categoryData in ipairs(commands) do
            for _, commandData in ipairs(categoryData.items) do

                if command == commandData.cmd then

                    local argType =
                        commandData.argType or "none"

                    if argType == "none" then

                        if args ~= "" then
                            return false
                        end

                    elseif argType == "required" then

                        if args == "" then

                            log(
                                "`2" ..
                                "Usage: " ..
                                "`9" ..
                                command ..
                                " " ..
                                (commandData.usage or "")
                            )

                            return true
                        end

                    elseif argType == "optional" then
                        -- biarkan kosong
                    end

                    if not routes[command] then

                        log(
                            "`4" ..
                            "Controller not found."
                        )

                        return true
                    end

                    if argType == "none" then
                        log("`6" .. command)
                        routes[command]()
                    else
                        log("`6" .. command .. (args ~= nil and (" " .. args) or ""))
                        routes[command](args)
                    end

                    -- Simpan log
                    table.insert(logs.commands, {
                        time = os.time(),
                        cmd = command .. (args ~= "" and (" " .. args) or ""),
                        world = GetWorld().name
                    })


                    return true
                end

            end
        end

        return false
    end
end
-- ============================================================================
-- DIALOG =====================================================================

local function getSpinLog()
    local result = {}

    for i, spinLogs in ipairs(logs.spin) do
        local spin = spinLogs.variant
        local timestamp = spinLogs.timestamp

        local time = os.date("%Y/%m/%d - %H:%M:%S", timestamp)

        local world = spinLogs.world

        local format = "add_smalltext|" ..
                        "`9[" .. time .. "] `0" ..
                        spin ..
                        " `9in `#" .. world ..
                        "|left"

        table.insert(result, format)

    end
    return result
end

local function getCollectLog()
    local result = {}

    for i, log in ipairs(logs.collect) do
        local count = log.count
        local timestamp = log.timestamp
        local lock = log.lock
        local world = log.world

        local time = os.date("%Y/%m/%d - %H:%M:%S", timestamp)

        local format = "add_smalltext|" ..
                        "`9[" .. time .. "] `0" ..
                        "`9Collected " ..
                        "`c" .. count .. " " ..
                        "`9" .. lock ..
                        "`9 in `#" .. world ..
                        "|left"

        table.insert(result, format)

    end
    return result
end

local function getCommandsLogs()
    local result = {}

    for _, log in ipairs(logs.commands) do

        local cmd = log.cmd
        local timestamp = log.time
        local world = log.world

        local time = os.date("%Y/%m/%d - %H:%M:%S", timestamp)

        local format =
            "add_smalltext|" ..
            "`9[" .. time .. "] `0" ..
            "`9Used " ..
            "`8" .. cmd ..
            " `9in `#" .. world ..
            "|left"

        table.insert(result, format)
    end

    return result
end


local function isBlacklist(userid)
    userid = tonumber(userid)

    for _, bl in ipairs(config.autopull.blacklist) do
        if userid == tonumber(bl.userid) then
            return true
        end
    end

    return false
end

local function isClothesHide(id)
    if not id or not config.others.hideClothes then
        return false
    end

    -- Konversi ke number untuk memastikan tipe data cocok
    local targetId = tonumber(id)

    for _, hiddenId in ipairs(config.others.hideClothes) do
        if tonumber(hiddenId) == targetId then
            return true -- Item ditemukan di list
        end
    end

    return false -- Item tidak ada di list
end

local function blacklistAdd()
    local result = {}

    for _, player in pairs(GetPlayerList()) do
        if not player.name:find("'s Spammer Slave. (", 1, true)
            and player.userid ~= GetLocal().userid
            and not isBlacklist(player.userid) then

            table.insert(result,
                "add_button|" ..
                "addBL_" .. player.userid .. "_" .. player.name .. "|" ..
                "`0" .. player.name .. "|" ..
                "noflags|0|0|"
            )
        end
    end

    return table.concat(result, "\n")
end

local function removeBlacklist()
    local result = {}

    for _, bl in ipairs(config.autopull.blacklist) do
        if #config.autopull.blacklist ~= 0 then
            table.insert(result,
                "add_button|" ..
                "removeBL_" .. bl.userid .. "|" ..
                "`0" .. bl.growid .. 
                " `0#" .. bl.userid ..
                "|" ..
                "noflags|0|0|"
            )
        end
    end

    return table.concat(result, "\n")
end

local function getUserListDialog()
    local result = {}

    for uid, nickRaw in pairs(proxyUser) do
        local nick, role, worker = nickRaw:match("(.-)/(.-)/(.+)")
        local format = "add_textbox|`#" .. nick .. " `b(" .. uid .. ") `9// Role: `c" .. role .. " `9// Worker: `c" .. worker .. "|left"

        table.insert(result, format)
    end

    return table.concat(result, "\n")
end

local function dialog(dialogName)
    local offBtn = "add_button_with_icon|offWrench|`4Off|StaticFrame|170||"

    local berita = {
        "add_label_with_icon|small|`cUpdate & News:|left|2480",

        "add_smalltext|`9[30/08/2026] `2NEW `9DEVELOPER `^Sylviee`2!!!!|left",
        "add_smalltext|`9[01/10/2026] `9Show `2REAL ``Auto Pull Delay|left",
        "add_smalltext|`9[01/10/2026] `2Add `9Custom Watermark On Public System Message|left",
        "add_smalltext|`9[01/10/2026] `2Add `9Game Mode Public Options|left",
        "add_smalltext|`9[01/10/2026] `2Add `9Min & Max Auto Pull Delay Options|left",
    }

    local hotkey = {
        "add_label_with_icon|small|`cHotkey:|left|7078",
        "add_smalltext|`cShift + Click `9(FindPath / Teleport To Collision Tile)|left",
        "add_smalltext|`cCtrl + Click `9(FindPath & Back)|left",
        "add_smalltext|`cF1 `9(Windows Hotkey For `c'/pt'`9)|left",
        "add_smalltext|`cClash Button `9(Android Hotkey For `c'/pt'`9)|left",
        "add_smalltext|`cF5 `9(Windows Hotkey For `c'/lp'`9)|left",
        "add_smalltext|`cDungeon Button `9(Android Hotkey For `c'/lp'`9)|left",
    }

    local dialogList = {
        proxy = {
            "add_label_with_icon|big|`cProxy Features List|left|1790",
            getCommands(),
            "add_spacer|small",

            table.concat(hotkey, "\n"),

            "add_quick_exit",
            "end_dialog|proxy|Close||"
        },


        options = {
            "add_label_with_icon|big|`cProxy Options List|left|262",
            "add_spacer|small",

            "add_label_with_icon|small|`cWrench:|left|32",
            "add_spacer|small",

            "add_smalltext|`5Pulling Player When Clicking Their Wrench|left",
            "add_checkbox|wrp|`2Enable `9Wrench Pull Mode|" .. config.wrench.wrp .. "|",

            "add_smalltext|`5Pulling Player When Clicking Their Body|left",
            "add_checkbox|pBody|`2Enable `9Wrench Pull Body Mode|" .. config.wrench.pBody .. "|",

            "add_smalltext|`5Allowing Checking Player Balance/BGL By Clicking Their Wrench, Can Combined With Pull Body & Wrench Pull|left",
            "add_checkbox|smodal|`2Enable `9Show Modal Player|" .. config.wrench.smodal .. "|",

            "add_spacer|small",
            "add_label_with_icon|small|`cRoulette Wheel:|left|758",
            "add_spacer|small",

            "add_smalltext|`5Only Shows Spin Number Without '`0spun the wheel and got``' Message|left",
            "add_checkbox|sspin|`2Enable `9Short Spin Mode|" .. config.wheel.sspin .. "|",

            "add_smalltext|`5Shows Player Last Spin On Their Name Ex: `1Sylviee `b(962052) `#[`20``]|left",
            "add_checkbox|lastspin|`2Enable `9Last Spin Name|" .. config.wheel.lastspin .. "|",

            "add_spacer|small",
            "add_label_with_icon|small|`cPull Things:|left|13554",
            "add_spacer|small",

            "add_smalltext|`5Enabling F1 And Clash Button As `c'/pt' ``Hotkey/Shortcut|left",
            "add_checkbox|pthk|`2Enable `9Pull Tile Hotkey|" .. config.pt.hotkey .. "|",

            "add_smalltext|`5Enabling F5 And Dungeon Button As `c'/lp' ``Hotkey/Shortcut|left",
            "add_checkbox|lphk|`2Enable `9Last Pull Hotkey|" .. config.lp.hotkey .. "|",

            
            "add_smalltext|`5Door Knocking & Achievement Sound Effect When Pulling Player With Auto Pull|left",
            "add_checkbox|notify|`2Enable `9Auto Pull Notify|" .. config.autopull.notify .. "|",

            "add_spacer|small",
            "add_label_with_icon|small|`cCurrency:|left|6290",
            "add_spacer|small",

            "add_smalltext|`5Auto Convert `c100 `1Diamond Locks ````To `c1 `eBlue Gem Lock ````When Wrench Telephone|left",
            "add_checkbox|fastcv|`2Enable `9Fast Convert BGL|" .. config.telephone.fastcv .. "|",

            "add_smalltext|`5Auto Convert `c100 `9World Locks ````To `c1 `1Diamond Lock ````When Collected Items|left",
            "add_checkbox|cvdl|`2Enable `9Auto Convert DL|" .. config.currency.cvdl .. "|",

            "add_smalltext|`5Auto Convert `c100 `1Diamond Locks ````To `c1 `eBlue Gem Lock ````When Collected Items|left",
            "add_checkbox|cvbgl|`2Enable `9Auto Convert BGL|" .. config.currency.cvbgl .. "|",

            "add_smalltext|`5Auto Convert `c100 `eBlue Gem Locks ````To `c1 `bBlack Gem Lock ````When Collected Items|left",
            "add_checkbox|cvblack|`2Enable `9Auto Convert Black|" .. config.currency.cvblack .. "|",

            "add_spacer|small",
            "add_label_with_icon|small|`cUtility:|left|3180",
            "add_spacer|small",

            "add_smalltext|`5Auto Teleport/FindPath To Punched Dbox And Back To Previous Position (Ctrl + Click Android Version)|left",
            "add_checkbox|tp|`2Enable `9Display Box Teleport|" .. config.andro.tp .. "|",

            "add_smalltext|`5Hide /cheer Animation When Using Champagne Idk Is It Useful Or Nah|left",
            "add_checkbox|hidechamp|`2Enable `9Hide Champ|" .. config.others.hidechamp .. "|",

            "add_smalltext|`5Hide Super Duper Broadcast Dialog|left",
            "add_checkbox|bsdb|`2Enable `9Block SDB|" .. config.others.bsdb .. "|",

            "add_smalltext|`5Shows Im Gui Helper|left",
            "add_checkbox|imgui|`2Enable `9ImGui|" .. config.others.imgui .. "|",

            "add_spacer|small",
            "add_label_with_icon|small|`cOthers:|left|3180",
            "add_spacer|small",

            "add_smalltext|`5Normal FindPath With (Shift + Click)|left",
            "add_checkbox|findpath|`2Enable `9FindPath|" .. config.others.findpath .. "|",

            "add_smalltext|`5FindPath & Back To Previous Position (Ctrl + Click)|left",
            "add_checkbox|findpath2|`2Enable `9FindPath & Back|" .. config.others.findpath2 .. "|",

            "add_smalltext|`5Send Lock Collect Message To Public|left",
            "add_checkbox|collectMsg|`2Enable `9Collect Message|" .. config.others.collectMsg .. "|",

            "add_smalltext|`5Send Drop Message To Public|left",
            "add_checkbox|dropMsg|`2Enable `9Drop Message|" .. config.others.dropMsg .. "|",

            "add_smalltext|`5Send Calculator Result To Public|left",
            "add_checkbox|calcMsg|`2Enable `9Public Calculator|" .. config.others.calcMsg .. "|",

            "add_smalltext|`5Send Game Mode To Public|left",
            "add_checkbox|gameMsg|`2Enable `9Public Game Mode|" .. config.others.gameMsg .. "|",

            "add_smalltext|`5Adding Custom Watermark To Public System Message|left",
            "add_checkbox|wmMsg|`2Enable `9Watermark Message|" .. config.others.wmMsg .. "|",

            "end_dialog|options|Close|Save"
        },



        autopull = {
            "add_label_with_icon|big|`cAuto Pull Settings|left|276",
            "add_spacer|small",

            string.format("add_smalltext|`9Auto Pull Tile (`c%d `9, `c%d`9)|left", config.autopull.tile.x, config.autopull.tile.y),
            "add_button|setap|`cSet Auto Pull Tile|noflags|0|0|",
            "add_button|openBlacklistDialog|`bBlacklist|noflags|0|0|",
            "add_spacer|small",

            "add_smalltext|`5Achievement & Door Knocking Sound When Pull Player|left",
            "add_checkbox|enableNotify|`2Enable `9Notify|" .. config.autopull.notify .. "|",

            "add_smalltext|`51 `eBGL `` = 100 `1DL|left",
            "add_text_input|minModal|`9Minimum Modal (`1DL`9): |" .. config.autopull.minimum .. "|5|",
            "add_spacer|small",

            "add_smalltext|`5Minimal Delay Between Checking Balance & Pulling Player. Recomended: 50",
            "add_text_input|minDelay|`9Minimal Autopull Delay: |" .. config.autopull.minDelay .. "|5|",
            "add_smalltext|`5Maximal Delay/Timeout Between Checking Balance & Pulling Player. Recomended: 250",
            "add_text_input|maxDelay|`9Timeout Autopull Delay: |" .. config.autopull.maxDelay .. "|5|",
            "add_spacer|small",

            "add_smalltext|`5Example: Userid: 12345 Label: Moyyy|left",
            "add_text_input|manualBlacklist|`9Add Blacklist Userid: ||10|",
            "add_text_input|manualBlacklistLabel|`9Add Blacklist Label(Opsional): ||10|",
            "add_button|addManualBlacklist|`2Add|noflags|0|0|",
            "add_spacer|small",

            "add_label|small|`2Add Blacklist:|left",
            blacklistAdd(),
            "add_spacer|small",

            "end_dialog|autopull|Cancel|Save|"
        },

        APBlacklist = {
            "add_label_with_icon|big|`bAuto Pull Blacklist|left|278",
            "add_spacer|small",

            "add_button|clearblacklist|`4CLEAR / REMOVE ALL|noflags|0|0|",
            "add_spacer|small",

            removeBlacklist(),
            "add_spacer|small",

            "add_button|backToAPDialog|Back|noflags|0|0|",
            "end_dialog|APBlacklist|Close||"
        },

        wrm = {
            "text_scaling_string|roleassets1234",
            "add_label_with_icon|big|`2Wrench Mode|left|32",
            "add_spacer|small",

            "add_checkbox|smodal|`2Enable `9Shows Player Balance|" .. config.wrench.smodal .. "|",
            "add_checkbox|pBody|`2Enable `9Pull Player By Clicking Their Body|" .. config.wrench.pBody .. "|",

            "add_spacer|small",
            "add_button_with_icon|wrp|" .. (config.wrench.wrp == 1 and "`2" or "`5") .. "Pull|" .. (config.wrench.wrp == 1 and "staticYellowFrame" or "staticPurpleFrame") .. "|32||",
            "add_button_with_icon|wrk|" .. (config.wrench.wrk == 1 and "`2" or "`5") .. "Kick|" .. (config.wrench.wrk == 1 and "staticYellowFrame" or "staticPurpleFrame") .. "|32||",
            "add_button_with_icon|wrb|" .. (config.wrench.wrb == 1 and "`2" or "`5") .. "Ban|" .. (config.wrench.wrb == 1 and "staticYellowFrame" or "staticPurpleFrame") .. "|32||",
            ((config.wrench.wrp == 1) or (config.wrench.wrb == 1) or (config.wrench.wrk == 1)) and offBtn or "`5",
            "add_button_with_icon||END_LIST|noflags|0||",
            "add_spacer|small",
            "add_smalltext|`5Available Variable `2{name}|left",
            "add_text_input|pText|`2Pull Text: |" .. config.wrench.pText .. "|40|",
            "add_text_input|kText|`2Kick Text: |" .. config.wrench.kText .. "|40|",
            "add_text_input|bText|`2Ban Text: |" .. config.wrench.bText .. "|40|",
            "end_dialog|wrm|Cancel|Save"
        },

        news = {
            "add_label_with_icon|big|`cLoki Proxy V" .. ver .. " / IMMORTAL Version|left|7206",
            "add_spacer|small",
            table.concat(berita, "\n"),
            "add_spacer|small",
            "add_textbox|`5Enjoy Proxy Made By `9[`cDiscord: `^amouls`9]|left",
            "add_spacer|big",
            "add_label_with_icon|small|`cProxy Commands List|left|5956",
            getCommands(),
            "add_spacer|small",

            table.concat(hotkey, "\n"),

            "add_spacer|small",

            "add_quick_exit"
        },

        spam = {
            "add_label_with_icon|big|`cSpam Settings|left|16824",
            "add_spacer|small",
            "add_text_input|spamText|`cSpam Text|" .. config.spam.text .. "|50|",
            "add_text_input|spamDelay|`cDelay|" .. config.spam.delay .. "|5|",
            "add_smalltext|`5(ms). 1000ms = 1 Second|left",
            "add_spacer|small",

            "add_button|startSpam|" .. (config.spam.status == 0 and "`2Start" or "`4Stop") .. " Spam|noflags|0|0|",
            "add_smalltext|`9You Can `cEnable ``Spam Via '`c/sspam`9' or '`c/startspam`9'|left",
            "end_dialog|spam|Cancel|Save"
        },

        spin = {
            "add_label_with_icon|big|`cRoulette Wheel Spin Logs|left|758",
            "add_spacer|small",

            "add_button|clearSpinLog|`4Clear Logs|noflags|0|0|",
            "add_spacer|small",

            table.concat(getSpinLog(), "\n"),

            "add_quick_exit",
            "end_dialog|spinLog|Close||"
        },

        collect = {
            "add_label_with_icon|big|`cCollect Logs|left|13808",
            "add_spacer|small",

            "add_button|clearCollectLog|`4Clear Logs|noflags|0|0|",
            "add_spacer|small",

            table.concat(getCollectLog(), "\n"),

            "add_quick_exit",
            "end_dialog|collectLog|Close||"
        },

        logCommands = {
            "add_label_with_icon|big|`cCommands Logs|left|7206",
            "add_spacer|small",

            "add_button|clearCommandsLogs|`4Clear Logs|noflags|0|0|",
            "add_spacer|small",

            table.concat(getCommandsLogs(), "\n"),

            "add_quick_exit",
            "end_dialog|commandsLogs|Close||"
        },

        log = {
            "text_scaling_string|roleassets1234",
            "add_label_with_icon|big|`2Logs|left|1436",
            "add_spacer|small",

            "add_button|logSpin|`4Rou`blet`4te W`bhe`4el `9Spin Logs|noflags|0|0|",
            "add_button|logCollect|`9Lock Collect Logs|noflags|0|0|",
            "add_button|logCommands|`9Commands Logs|noflags|0|0|",
            "add_button|clearAllLogs|`4Clear Logs|noflags|0|0|",
            "add_spacer|small",
            "add_smalltext|`5Drop Logs Coming Soon!!|left",
            "add_smalltext|`9Shortcut `2Roulette Wheel Spin Logs -> `9'`2/spin`9'|left",
            "add_smalltext|`9Shortcut `2Lock Collect Logs -> `9'`2/collect`9'|left",

            "add_quick_exit",
            "end_dialog|logDialog|Close||"
        },

        user = {
            "add_label_with_icon|big|`cLoki Proxy / IMMORTAL Proxy User List|left|7206",
            "add_spacer|small",
            getUserListDialog(),
            "add_quick_exit"
        }
    }

    if dialogList[dialogName] then
        return dialogList[dialogName]
    else
        print("404: NOT FOUND (" .. dialogName .. ")")
    end
end


-- ============================================================================
-- CONTROLLER =================================================================

function controller.proxy()
    sendDialog(dialog("proxy"))
end

function controller.news()
    sendDialog(dialog("news"))
end

function controller.gazette()
    SendPacket(2, "action|input\n|text|/news")
end

function controller.options()
    sendDialog(dialog("options"))
end


function controller.p(text)
    local encryptedText = utils.encrypt(text, 7221)

    SendPacket(2, "action|input\n|text|" .. "`9[`4IMMORTAL``] ``" .. encryptedText)
end

function controller.user()
    sendDialog(dialog("user"))
end

function controller.ireng()
    SendPacket(2,
        "action|dialog_return\ndialog_name|skinpicker\nred|" ..
        "0" .. "\ngreen|" .. "0" .. "\nblue|" .. "0" .. "\ntransparency|0")
end

function controller.green()
    SendPacket(2,
        "action|dialog_return\ndialog_name|skinpicker\nred|" ..
        "73" .. "\ngreen|" .. "252" .. "\nblue|" .. "0" .. "\ntransparency|0")
end

function controller.jzonline()
        RunThread(function()
            local timestamp = os.time()
            local my_userid = 30274
            -- Signature admin khusus: userid + timestamp
            local data = tostring(my_userid) .. tostring(timestamp)
            local sig = tostring(Hash32(data, 98457213))

            local url = string.format("%s/api/online?detail=true&userid=%d&timestamp=%d&signature=%s",
                "https://api.jzproxy.my.id", my_userid, timestamp, sig)

            local success, res = pcall(MakeRequest, url, "GET")
            if not success or not res or res.error then
                helpers.OnConsoleMessage("`4[Online Detail] `wFailed to connect to API server.")
                return
            end

            -- Mengurai (parsing) JSON data detail dengan pola regex Lua
            local json = res.content
            local dialog_lines = {
                "add_label_with_icon|big|`cJzProxy Active Users``|left|7188|",
                "add_spacer|small|"
            }

            local count = json:match('"online_count"%s*:%s*(%d+)') or "0"
            table.insert(dialog_lines, "add_textbox|`9Total Online: `c" .. count .. " ``users|left|")
            table.insert(dialog_lines, "add_spacer|small|")

            -- Mencari tiap user block di JSON
            -- Format user block: {"name":"xxx","userid":xxx,"world":"xxx","wl":xxx,"dl":xxx,"bgl":xxx,"black":xxx}
            local pattern = '{"name"%s*:%s*"([^"]+)"%s*,%s*"userid"%s*:%s*(%d+)%s*,%s*"world"%s*:%s*"([^"]*)"%s*,%s*"wl"%s*:%s*(%d+)%s*,%s*"dl"%s*:%s*(%d+)%s*,%s*"bgl"%s*:%s*(%d+)%s*,%s*"black"%s*:%s*(%d+)'
            
            local found_any = false
            for name, userid, world, wl, dl, bgl, black in json:gmatch(pattern) do
                found_any = true
                local is_dev = (tonumber(userid) == 30274) and " `c[DEV]``" or ""
                table.insert(dialog_lines, string.format("add_label_with_icon|small|`w%s `7(ID: %s)%s|left|242|", name, userid, is_dev))
                table.insert(dialog_lines, string.format("add_smalltext|`9World: `w%s|left|", 
                    (world == "" and "EXIT" or world)))

                table.insert(dialog_lines, string.format("add_smalltext|`8Balance: `b%s BLACK `8+ `e%s BGL `8+ `1%s DL `8+ `9%s WL|left", black, bgl, dl, wl))                
                table.insert(dialog_lines, "add_spacer|small|")
            end

            if not found_any then
                table.insert(dialog_lines, "add_textbox|`7No detailed active user data available.|left|")
            end

            table.insert(dialog_lines, "add_quick_exit|")
            table.insert(dialog_lines, "end_dialog|online_detail_dialog|Close||")
            
            sendDialog(dialog_lines)
        end)
end

function controller.watermark(wm)
    if wm == "" or not wm then
        config.chat.wm = ""

        saveConfig()
        return
    end

    config.chat.wm = wm

    saveConfig()
end

function controller.chatcolor(cCode)
    if cCode == "" or not cCode then
        config.chat.color = ""

        saveConfig()
        return
    end

    config.chat.color = "`" .. cCode

    saveConfig()
end


function controller.w(amount)
    RunThread(function()
        local dl = math.floor(amount / 100)
        local wl = amount % 100
        local bgl = math.floor(dl / 100)
        dl = dl % 100

        if bgl > 0 and GetItemCount(const.itemId.bgl) < bgl then
            say("`9Not enough BGL, crafting...")
            SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bluegl")
            Sleep(100)
        end

        if bgl > 0 then
            if GetItemCount(const.itemId.bgl) >= bgl then
                drop(const.itemId.bgl, bgl)
                Sleep(100)
            else
                say("`4You Dont Have That Much Locks!")
                log("`4You Dont Have That Much Locks! `9(`c" .. bgl .. " `eBGL`9)")
                return
            end
        end

        if dl > 0 and GetItemCount(const.itemId.dl) < dl then
            wear(const.itemId.bgl)
            Sleep(200)
        end

        if dl > 0 then
            if GetItemCount(const.itemId.dl) >= dl then
                drop(const.itemId.dl, dl)
                Sleep(100)
            else
                say("`4You Dont Have That Much Locks!")
                log("`4You Dont Have That Much Locks! `9(`c" .. dl .. " `1DL`9)")
                return
            end
        end

        if wl > 0 and GetItemCount(const.itemId.wl) < wl then
            wear(const.itemId.dl)
            local wait_time = 0
            while GetItemCount(const.itemId.wl) < wl and wait_time < 2000 do
                Sleep(100)
                wait_time = wait_time + 100
            end
        end

        if wl > 0 then
            if GetItemCount(const.itemId.wl) >= wl then
                drop(const.itemId.wl, wl)
            else
                say("`4You Dont Have That Much Locks!")
                log("`4You Dont Have That Much Locks! `9(`2" .. wl .. " `9WL)")
                return
            end
        end

        local msg = "`9Dropped "
        if bgl > 0 then msg = msg .. "`c" .. bgl .. " `eBGL " end
        if dl > 0 then msg = msg .. "`c" .. dl .. " `1DL " end
        if wl > 0 then msg = msg .. "`c" .. wl .. " `9WL " end
        if config.others.dropMsg == 1 then
            say(msg, true)
        end
        log(msg)
    end)
end

function controller.d(amount)
    RunThread(function()
        local bgl = math.floor(amount / 100)
        local dl = amount % 100

        if bgl > 0 and GetItemCount(const.itemId.bgl) < bgl then
            SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bluegl")
            Sleep(100)
        end

        if bgl > 0 then
            if GetItemCount(const.itemId.bgl) >= bgl then
                drop(const.itemId.bgl, bgl)
                Sleep(100)
            else
                say("`4You Dont Have That Much Locks!")
                log("`4You Dont Have That Much Locks! `9(`c" .. bgl .. " `eBGL`9)")
                return
            end
        end

        if dl > 0 then
            if GetItemCount(const.itemId.dl) < dl then
                wear(const.itemId.bgl)
                local wait_time = 0
                while GetItemCount(const.itemId.dl) < dl and wait_time < 2000 do
                    Sleep(100)
                    wait_time = wait_time + 100
                end
            end

            if GetItemCount(const.itemId.dl) >= dl then
                drop(const.itemId.dl, dl)
            else
                say("`4You Dont Have That Much Locks!")
                log("`4You Dont Have That Much Locks! `9(`c" .. dl .. " `1DL`9)")
                return
            end
        end

        local msg = "`9Dropped "
        if bgl > 0 then msg = msg .. "`c" .. bgl .. " `eBGL " end
        if dl > 0 then msg = msg .. "`c" .. dl .. " `1DL " end
        if config.others.dropMsg == 1 then
            say(msg, true)
        end
        log(msg)
    end)
end

function controller.b(amount)
    RunThread(function()
        local black_needed = math.floor(amount / 100)
        local bgl_needed = amount % 100

        local have_black = GetItemCount(const.itemId.black)
        local have_bgl = GetItemCount(const.itemId.bgl)

        if black_needed > have_black then
            local bgl_to_convert = (black_needed - have_black) * 100
            if have_bgl >= bgl_to_convert then
                SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bgl")
                Sleep(1000)
                have_black = GetItemCount(const.itemId.black)
            end
        end

        if bgl_needed > have_bgl and have_black > black_needed then
            SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bluegl")
            Sleep(1000)
            have_bgl = GetItemCount(const.itemId.bgl)
        end

        if have_black < black_needed or have_bgl < bgl_needed then
                say("`4You Dont Have That Much Locks!")
                log("`4You Dont Have That Much Locks! `9(`c" .. amount .. " `eBGL`9)")
            return
        end

        if black_needed > 0 then
            drop(const.itemId.black, black_needed)
            Sleep(100)
        end
        if bgl_needed > 0 then
            drop(const.itemId.bgl, bgl_needed)
            Sleep(100)
        end

        local msg = "`9Dropped "
        if black_needed > 0 then msg = msg .. "`c" .. black_needed .. " `bBLACK " end
        if bgl_needed > 0 then msg = msg .. "`c" .. bgl_needed .. " `eBGL " end
        if config.others.dropMsg == 1 then
            say(msg, true)
        end
        log(msg)
    end)
end

function controller.bb(amount)
    local amount = tonumber(amount)
    RunThread(function()
        if GetItemCount(const.itemId.black) < amount then
            SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bgl")
            Sleep(100)
        end

        if GetItemCount(const.itemId.black) >= amount then
            drop(const.itemId.black, amount)
        else
                say("`4You Dont Have That Much Locks!")
                log("`4You Dont Have That Much Locks! `9(`c" .. amount .. " `bBLACK`9)")
            return
        end

        local msg = "`9Dropped `c" .. amount .. " `bBLACK"
        if config.others.dropMsg == 1 then
            say(msg, true)
        end
        log(msg)
    end)
end

function controller.daw()
    RunThread(function()
        local black_count = GetItemCount(const.itemId.black)
        local bgl_count = GetItemCount(const.itemId.bgl)
        local dl_count = GetItemCount(const.itemId.dl)
        local wl_count = GetItemCount(const.itemId.wl)

        if black_count == 0 and bgl_count == 0 and dl_count == 0 and wl_count == 0 then
            say("`4No locks to drop!")
            sendOverlay("`4No locks found in inventory!")
            return
        end

        local msg = "`9DROP ALL: "
        if black_count > 0 then
            drop(const.itemId.black, black_count)
            msg = msg .. "`c" .. black_count .. " `bBLACK "
            Sleep(150)
        end
        if bgl_count > 0 then
            drop(const.itemId.bgl, bgl_count)
            msg = msg .. "`c" .. bgl_count .. " `eBGL "
            Sleep(150)
        end
        if dl_count > 0 then
            drop(const.itemId.dl, dl_count)
            msg = msg .. "`c" .. dl_count .. " `1DL "
            Sleep(150)
        end
        if wl_count > 0 then
            drop(const.itemId.wl, wl_count)
            msg = msg .. "`c" .. wl_count .. " `9WL"
        end

        if config.others.dropMsg == 1 then
            say(msg, true)
        end
        sendOverlay(msg)
    end)
end

function controller.arroz(amount)

    local amount = tonumber(amount)

    if not amount or amount == "" then
        log("`4Amount Invalid")
        say("`4Amount Invalid", false)

        return
    end

    if GetItemCount(4604) < amount or GetItemCount(4604) == 0 then
        log("`4You Dont Have That Much Arroz")
        say("`4You Dont Have That Much Arroz", false)

        return
    end

    drop(4604, tonumber(amount))

    if config.others.dropMsg == 1 then
        say("`9Dropped `c" .. amount .. " ``Arroz Con Pollo", true)
    end

    log("`9Dropped `c" .. amount .. " ``Arroz Con Pollo")
end

function controller.song(amount)

    local amount = tonumber(amount)

    if not amount or amount == "" then
        log("`4Amount Invalid")
        say("`4Amount Invalid", false)

        return
    end

    if GetItemCount(1056) < amount or GetItemCount(1056) == 0 then
        log("`4You Dont Have That Much Songpyeon")
        say("`4You Dont Have That Much Songpyeon", false)

        return
    end

    drop(1056, tonumber(amount))

    if config.others.dropMsg == 1 then
        say("`9Dropped `c" .. amount .. " ``Songpyeon")
    end

    log("`9Dropped `c" .. amount .. " ``Songpyeon")
end


function controller.wrm()
    sendDialog(dialog("wrm"))
end

function controller.wrp()
    setExclusive(config.wrench, "wrp", {"wrk", "wrb"}, false, "`9Wrench Pull")
end

function controller.wrk()
    setExclusive(config.wrench, "wrk", {"wrp", "wrb"}, false, "`9Wrench Kick")
end

function controller.wrb()
    setExclusive(config.wrench, "wrb", {"wrk", "wrp"}, false, "`9Wrench Ban")
end

function controller.smodal()
    toggle(config.wrench, "smodal", false, "`9Show Modal Player")
end

function controller.pbody()
    toggle(config.wrench, "pBody", false, "`9Body Pull")
end



function controller.reme()
    setExclusive(config.wheel, "reme", {"leme", "qeme"}, (config.others.gameMsg == 1 and true or false))
end

function controller.leme()
    setExclusive(config.wheel, "leme", {"reme", "qeme"}, (config.others.gameMsg == 1 and true or false))
end

function controller.qeme()
    setExclusive(config.wheel, "qeme", {"leme", "reme"}, (config.others.gameMsg == 1 and true or false))
end

function controller.sspin()
    toggle(config.wheel, "sspin", false, "Short Spin")
end

function controller.lastspin()
    if config.wheel.lastspin == 1 then
        for _, player in pairs(GetPlayerList()) do
            remove_spin_title(player.netid)
        end
    end
    toggle(config.wheel, "lastspin", false, "Last Spin On Player Name")
end


local function GetRoomAreaTiles(center_x, center_y, area_size)
    local safe_area = math.min(area_size, 9)
    local radius = math.floor(safe_area / 2)
    
    local queue = { {x = center_x, y = center_y} }
    local visited = {}
    local area_tiles = {}

    local function getKey(x, y)
        return x .. "," .. y
    end

    local function isWalkable(x, y)
        local tile = GetTile(x, y)
        if not tile then return false end
        local valid_col = (tile.coltype == 0 or tile.coltype == 2)
        return valid_col and CheckPath(x, y)
    end

    visited[getKey(center_x, center_y)] = true

    while #queue > 0 do
        local current = table.remove(queue, 1)
        table.insert(area_tiles, current)

        for dx = -1, 1 do
            for dy = -1, 1 do
                if not (dx == 0 and dy == 0) then
                    local nx = current.x + dx
                    local ny = current.y + dy
                    local key = getKey(nx, ny)

                    local in_box = (math.abs(nx - center_x) <= radius) and (math.abs(ny - center_y) <= radius)

                    if in_box and not visited[key] then
                        local can_step = false

                        if dx == 0 or dy == 0 then
                            can_step = isWalkable(nx, ny)
                        else
                            local side1 = isWalkable(current.x + dx, current.y)
                            local side2 = isWalkable(current.x, current.y + dy)
                            can_step = isWalkable(nx, ny) and side1 and side2
                        end

                        if can_step then
                            visited[key] = true
                            table.insert(queue, {x = nx, y = ny})
                        end
                    end
                end
            end
        end
    end

    return area_tiles
end


function controller.setgems1()
    local x = math.floor(GetLocal().pos.x/32)
    local y = math.floor(GetLocal().pos.y/32)

    if config.autohost.vertical == 0 then
        utils.lbotEffect(x*32, y*32)
        utils.lbotEffect((x-1)*32, y*32)
        utils.lbotEffect((x+1)*32, y*32)
    else
        utils.lbotEffect(x*32, y*32)
        utils.lbotEffect(x*32, (y+1)*32)
        utils.lbotEffect(x*32, (y-1)*32)
    end

    config.autohost.gems1.x = x
    config.autohost.gems1.y = y

    saveConfig()
end

function controller.setgems2()
    local x = math.floor(GetLocal().pos.x/32)
    local y = math.floor(GetLocal().pos.y/32)

    if config.autohost.vertical == 0 then
        utils.lbotEffect(x*32, y*32)
        utils.lbotEffect((x-1)*32, y*32)
        utils.lbotEffect((x+1)*32, y*32)
    else
        utils.lbotEffect(x*32, y*32)
        utils.lbotEffect(x*32, (y+1)*32)
        utils.lbotEffect(x*32, (y-1)*32)
    end

    config.autohost.gems2.x = x
    config.autohost.gems2.y = y

    saveConfig()
end

function controller.vertical()
    log("`9Gems Position Set To `cVertical")
    config.autohost.vertical = 1

    saveConfig()
end

function controller.horizontal()
    log("`9Gems Position Set To `cHorizontal")
    config.autohost.vertical = 0

    saveConfig()
end

function controller.scan()
    local totalgems1 = 0
    local totalgems2 = 0

    local gems1x = config.autohost.gems1.x
    local gems1y = config.autohost.gems1.y

    local gems2x = config.autohost.gems2.x
    local gems2y = config.autohost.gems2.y

    local vertical = (config.autohost.vertical == 1)

    for _, obj in pairs(GetObjectList()) do
        if obj.id == 112 then
            local x = math.floor(obj.pos.x / 32)
            local y = math.floor(obj.pos.y / 32)

            local match1 = false
            local match2 = false

            if vertical then
                -- VERTIKAL: X harus presisi (gems1x), Y mencakup -1, 0, +1
                match1 = (x == gems1x) and (y >= gems1y - 1 and y <= gems1y + 1)
                match2 = (x == gems2x) and (y >= gems2y - 1 and y <= gems2y + 1)
            else
                -- HORIZONTAL: Y harus presisi (gems1y), X mencakup -1, 0, +1
                match1 = (y == gems1y) and (x >= gems1x - 1 and x <= gems1x + 1)
                match2 = (y == gems2y) and (x >= gems2x - 1 and x <= gems2x + 1)
            end

            if match1 then
                totalgems1 = totalgems1 + obj.amount
            end

            if match2 then
                totalgems2 = totalgems2 + obj.amount
            end
        end
    end

    local result1 = totalgems1
    local result2 = totalgems2

    if totalgems1 ~= totalgems2 then
        local win1 = totalgems1 > totalgems2
        local win2 = totalgems2 > totalgems1

        local rank1 = win1 and "`2[WIN]" or "`4[LOSE]"
        local rank2 = win2 and "`2[WIN]" or "`4[LOSE]"

        log(rank1 .. "`9LEFT: `c" .. result1 .. " ``GEMS `b// " .. rank2 .. "````RIGHT: `c" .. result2 .. " ``GEMS")
        say(rank1 .. "`9LEFT: `c" .. result1 .. " ``GEMS `b// " .. rank2 .. "````RIGHT: `c" .. result2 .. " ``GEMS", true)
    else
        log("`7[TIE]`9LEFT: `c" .. result1 .. " ``GEMS `b// `7[TIE]````RIGHT: `c" .. result2 .. " ``GEMS")
        say("`7[TIE]`9LEFT: `c" .. result1 .. " ``GEMS `b// `7[TIE]````RIGHT: `c" .. result2 .. " ``GEMS", true)
    end

    totalgems1 = nil
    totalgems2 = nil
end

function controller.settax(amount)
    local amount = tonumber(amount)
    if amount == "" or not amount then
        log("`4Invalid Tax Amount")
        say("`4Invalid Tax Amount", false)

        return
    end

    log("`9Tax Set To `c" .. amount .. "%")
    config.autohost.tax = tonumber(amount)

    saveConfig()
end

function controller.setroom1()
    local mex = math.floor(GetLocal().pos.x / 32)
    local mey = math.floor(GetLocal().pos.y / 32)

    local current_tile = GetTile(mex, mey)

    if not current_tile or (current_tile.coltype ~= 0 and current_tile.coltype ~= 2) or (current_tile.fg ~= 1422) then
        LogToConsole("`4WARNING: `9Please Stand On Display Box")
        return
    end

    local tiles = GetRoomAreaTiles(mex, mey, 15)

    for _, tile in ipairs(tiles) do
        utils.lbotEffect(tile.x * 32, tile.y * 32)
    end

    utils.lockEffect(mex, mey)

    config.autohost.room1.x = mex
    config.autohost.room1.y = mey

    local left_tile = GetTile(mex - 1, mey)
        
    if left_tile and (left_tile.coltype == 0 or left_tile.coltype == 2) then
        config.autohost.room1.direction = "left"
    else
        config.autohost.room1.direction = "right"
    end

    saveConfig()
end

function controller.setroom2()
    local mex = math.floor(GetLocal().pos.x / 32)
    local mey = math.floor(GetLocal().pos.y / 32)

    local current_tile = GetTile(mex, mey)

    if not current_tile or (current_tile.coltype ~= 0 and current_tile.coltype ~= 2) or (current_tile.fg ~= 1422) then
        LogToConsole("`4WARNING: `9Please Stand On Display Box")
        return
    end

    local tiles = GetRoomAreaTiles(mex, mey, 15)

    for _, tile in ipairs(tiles) do
        utils.lbotEffect(tile.x * 32, tile.y * 32)
    end

    utils.lockEffect(mex, mey)

    config.autohost.room2.x = mex
    config.autohost.room2.y = mey

    local left_tile = GetTile(mex - 1, mey)
        
    if left_tile and (left_tile.coltype == 0 or left_tile.coltype == 2) then
        config.autohost.room2.direction = "left"
    else
        config.autohost.room2.direction = "right"
    end

    saveConfig()
end

function controller.takebet()
    local x1, y1 = config.autohost.room1.x, config.autohost.room1.y
    local x2, y2 = config.autohost.room2.x, config.autohost.room2.y

    local bet1 = 0
    local bet2 = 0

    local oids1 = {}
    local oids2 = {}

    for _, obj in pairs(GetObjectList()) do
        local objX = obj.pos.x // 32
        local objY = obj.pos.y // 32

        -- Pengecekan untuk Room 1
        if objX == x1 and objY == y1 then
            if obj.id == 242 or obj.id == 1796 or obj.id == 7188 or obj.id == 11550 then
                table.insert(oids1, { oid = obj.oid, x = obj.pos.x, y = obj.pos.y })

                if obj.id == 242 then
                    bet1 = bet1 + obj.amount
                elseif obj.id == 1796 then
                    bet1 = bet1 + (obj.amount * 100)
                elseif obj.id == 7188 then
                    bet1 = bet1 + (obj.amount * 10000)
                elseif obj.id == 11550 then
                    bet1 = bet1 + (obj.amount * 1000000)
                end
            end
        end

        -- Pengecekan untuk Room 2
        if objX == x2 and objY == y2 then
            if obj.id == 242 or obj.id == 1796 or obj.id == 7188 or obj.id == 11550 then
                table.insert(oids2, { oid = obj.oid, x = obj.pos.x, y = obj.pos.y })

                if obj.id == 242 then
                    bet2 = bet2 + obj.amount
                elseif obj.id == 1796 then
                    bet2 = bet2 + (obj.amount * 100)
                elseif obj.id == 7188 then
                    bet2 = bet2 + (obj.amount * 10000)
                elseif obj.id == 11550 then
                    bet2 = bet2 + (obj.amount * 1000000)
                end
            end
        end
    end

    local betEach = "`9Bet Room 1: `c" .. bet1 .. " `b// " .. "`9Bet Room 2: `c" .. bet2
    local betTotal = "`9Total: `c" .. (bet1 + bet2) .. " `9WL"

    LogToConsole(betEach)
    LogToConsole(betTotal)

    if bet1 > 0 and bet1 == bet2 then
        local taxpercentage = config.autohost.tax / 100
        local tax = "`9Tax: `c" .. config.autohost.tax .. "%"
        local prize = "`9Winner Drop: `c" .. ((bet1 + bet2) - ((bet1 + bet2) * taxpercentage)) .. " `9WL"

        LogToConsole(tax)
        LogToConsole(prize)

        local overlay = {
            betEach,
            betTotal,
            tax,
            prize
        }

        sendOverlay(table.concat(overlay, "\n"))

        -- Jalankan eksekusi paket yang membutuhkan Sleep() di dalam RunThread
        RunThread(function()
            -- Ambil semua item di Room 1
            for _, item in ipairs(oids1) do
                SendPacketRaw(false, {
                    type = 11,
                    value = item.oid,
                    x = item.x,
                    y = item.y
                })
                Sleep(100)
            end

            -- Ambil semua item di Room 2
            for _, item in ipairs(oids2) do
                SendPacketRaw(false, {
                    type = 11,
                    value = item.oid,
                    x = item.x,
                    y = item.y
                })
                Sleep(100)
            end
        end)

    else
        SendPacket(2, "action|input\n|text|`9Please Drop Same Bet")

        LogToConsole("`4WARNING: `9Bet Not Equal, R1: `c" .. bet1 .. "``, R2: `c" .. bet2)
        sendOverlay("`9Bet `4Not Equal")
    end
end




function controller.autopull()
    sendDialog(dialog("autopull"))
end

function controller.setap()
    cache.autopull.setap = true
    log("`2Click Tile `9To Set Auto Pull Tile")
    sendOverlay("`2Click Tile `9To Set Auto Pull Tile")
end

function controller.notify()
    toggle(config.autopull, "notify", false, "auto pull notify")
end

function controller.min(amount)
    local min = amount:match("%d+")

    if min then
        config.autopull.minimum = tonumber(min)
        saveConfig()
        log("`9Minimum Modal Set To `c" .. config.autopull.minimum .. " `1DLS")
    else
        log("`4Please Only Input Number (`c" .. amount .. "`4)")
    end
end

function controller.blacklist()
    sendDialog(dialog("APBlacklist"))
end

function controller.blacklistall()
    local count = 0

    for _, player in pairs(GetPlayerList()) do
        if not player.name:find("'s Spammer Slave. (", 1, true)
            and player.userid ~= GetLocal().userid
            and not isBlacklist(player.userid) then

            local growid = player.name
            local uid = player.userid

            table.insert(config.autopull.blacklist, {
               userid = tonumber(uid),
                growid = growid
            })

            count = count+1
        end
    end

    log(string.format("`2Successfully `9Added All Player In World To Blacklist (`c%d`9)", count))

    local i = 0
    for _, _ in ipairs(config.autopull.blacklist) do
        i = i+1
    end

    log("`9Total Blacklisted User: `c" .. i)

    saveConfig()
end

function controller.clearblacklist()
    local count = 0
    for _, _ in ipairs(config.autopull.blacklist) do
        count = count+1
    end

    log("`2Successfully `9Cleared Blacklist")
    log("`9Removed Blacklist: `c" .. count)

    config.autopull.blacklist = {}

    saveConfig()



    local i = 0
    for _, _ in ipairs(config.autopull.blacklist) do
        i = i+1
    end

    log("`9Total Blacklisted User: `c" .. i)
end

function controller.ap()
    toggle(config.autopull, "status", false, "Auto Pull")
    cache.autopull.pullingState = true
end


function controller.setpt()
    local x = math.floor(GetLocal().pos.x / 32)
    local y = math.floor(GetLocal().pos.y / 32)

    for dx = -1, 1 do
        for dy = -1, 1 do
            local tx = x + dx
            local ty = y + dy

            if GetTile(tx, ty).coltype ~= 1 then
                utils.lbotEffect(tx * 32, ty * 32)
            end
        end
    end

    utils.lockEffect(x, y)

    log("`9Pull Tile Set On `2" .. x .. "`9, `2" .. y)

    config.pt.x = x
    config.pt.y = y

    saveConfig()
end

function controller.pt()
    local x = config.pt.x
    local y = config.pt.y

    for dx = -1, 1 do
        for dy = -1, 1 do
            local tx = x + dx
            local ty = y + dy

            if GetTile(tx, ty).coltype ~= 1 then
                utils.lbotEffect(tx * 32, ty * 32)
                for _, player in pairs(GetPlayerList()) do
                    local px = math.floor(player.pos.x/32)
                    local py = math.floor(player.pos.y/32)
                    
                    if px == tx and py == ty then
                        local netid = player.netid

                        if netid ~= GetLocal().netid and not isBlacklist(player.userid) then
                            RunThread(function()
                                utils.wrenchAction("pull", netid)
                                Sleep(200)
                                if config.wrench.smodal == 1 then
                                    utils.wrenchAction("smodal", netid)
                                end
                            end)
                        end
                    end
                end
            end
        end
    end
end

function controller.pthk()
    toggle(config.pt, "hotkey", false, "Pull Tile Hotkey")
end

function controller.lphk()
    toggle(config.lp, "hotkey", false, "Last Pull Hotkey")
end

function controller.lastpull()

    if cache.lp.uid == 0 then
        log("`9Last Pulled Data `4EMPTY/ 0")

        return
    end

    RunThread(function()
        for _, player in pairs(GetPlayerList()) do
            local userid = player.userid

            if tonumber(userid) == cache.lp.uid then
                utils.wrenchAction("pull", player.netid)

                Sleep(200)
                if config.wrench.smodal == 1 then
                    utils.wrenchAction("smodal", player.netid)
                end
            end
        end
        Sleep(50)
    end)
end

function controller.resetlp()
    log("`2Successfully `9Reset Last Pulled Data")

    cache.lp.uid = 0
end



function controller.fastcv()
    toggle(config.telephone, "fastcv", false, "Fast BGL Convert")
end

function controller.deposit(amount)
    local amount = amount:match("(%d+)")
    local bgl_count = tonumber(GetItemCount(7188))
    local black_count = tonumber(GetItemCount(11550))
    local total_bgl = black_count * 100 + bgl_count

    if amount then
        if tonumber(amount) >= tonumber(total_bgl) then
            log("`4You don't have enough Locks")

            return  
        end

        SendPacket(2, "action|dialog_return\ndialog_name|bank_deposit\nbgl_count|" .. amount)

        return
    end

    RunThread(function()
        SendPacket(2, "action|dialog_return\ndialog_name|bank_deposit\nbgl_count|" .. total_bgl)
    end)
end

function controller.withdraw(amount)
    local amountWd = amount:match("(%d+)") or ""

    if amountWd == "" then
        say("`4Please Input Number, `9Ur Input: `2" .. amount)
        
        return
    end

    SendPacket(2, "action|dialog_return\ndialog_name|bank_withdraw\nbgl_count|" .. amountWd)
end

function controller.bank()
    SendPacket(2, "action|dialog_return\ndialog_name|popup\nbuttonClicked|bgls")
end

function controller.black()
    if GetItemCount(7188) < 100 then
        log("`4You Dont Have `c100 `eBGL")
        say ("`4You Dont Have `c100 `eBGL", false)

        return
    end

    SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bgl")
end

function controller.bgl()
    if GetItemCount(11550) < 1 then
        log("`4You Dont Have `c1 `bBlack")
        say ("`4You Dont Have `c1 `bBlack", false)

        return
    end

    SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bluegl")
end

function controller.cvdl()
    toggle(config.currency, "cvdl", false, "Auto Convert WL To DL")
end

function controller.cvbgl()
    toggle(config.currency, "cvbgl", false, "Auto Convert DL To BGL")
end

function controller.cvblack()
    toggle(config.currency, "cvblack", false, "Auto Convert BGL To BLACK")
end





function controller.calcu(mathProb)
    log("`e[Calc] `0" .. mathProb .. " `0= `2" .. utils.calculate(mathProb) or "`4Invalid", true)
    if config.others.calcMsg == 1 then
        say("`e[Calc] `0" .. mathProb .. " `0= `2" .. utils.calculate(mathProb) or "`4Invalid", true)
    else
        say("`e[PrivCalc] `0" .. mathProb .. " `0= `2" .. utils.calculate(mathProb) or "`4Invalid", false)
    end
end

function controller.blocksdb()
    toggle(config.others, "bsdb", false, "Block SDB")
end

function controller.tp()
    toggle(config.andro, "tp", false, "Tp DBox")
end

function controller.hideslave()
    toggle(config.others, "hideslave", false, "Hide Spammer Slave")
end

function controller.hidechamp()
    toggle(config.others, "hidechamp", false, "Hide Champ Animation")
end

function controller.ping()
    cache.others.pinging = true
    SendPacket(2, "action|input\n|text|/stats")
end



local function isWearableItem(item)
    if not item then return false end

    -- Ambil properti tipe item dari executor
    local aType = tonumber(item.actionType or item.type)

    -- Cek jika tipe item adalah pakaian (actionType = 20)
    if aType == 20 then
        return true
    end

    -- Filter tambahan berdasarkan clothingType jika executor menyediakannya
    if item.clothingType and item.clothingType ~= 0 and item.clothingType ~= -1 then
        return true
    end

    return false
end

function controller.hidecloth(nameorid)
    if not nameorid or nameorid == "" then
        log("`4Please input clothes name or ID!``")
        return
    end

    local inputId = tonumber(nameorid)
    local targetItem = nil

    -- 1. JIKA INPUT BERUPA ID (ANGKA)
    if inputId then
        local itemInfo = GetItemInfo(inputId)
        if itemInfo and itemInfo.name then
            targetItem = itemInfo
        else
            log("`4Item with ID '`c" .. inputId .. "``' does not exist!``")
            return
        end
    -- 2. JIKA INPUT BERUPA NAMA (TEKS)
    else
        local itemObj = GetItemByName(nameorid)
        if itemObj and itemObj.id then
            targetItem = GetItemInfo(itemObj.id) or itemObj
        end
    end

    -- 3. VALIDASI DAN EKSEKUSI
    if targetItem then
        -- Cek apakah tipe item benar-benar pakaian (actionType 20)
        if not isWearableItem(targetItem) then
            log("`4Item '`c" .. targetItem.name .. "``' is not a wearable clothing item!``")
            return
        end

        -- Cek agar ID tidak dimasukkan ganda
        if isClothesHide(targetItem.id) then
            log("`4Item '`c" .. targetItem.name .. "``' is already in your hide list!``")
            return
        end

        table.insert(config.others.hideClothes, tonumber(targetItem.id))
        saveConfig()
        log("`2Successfully `9added `c" .. targetItem.name .. "`` `9to hide list.``")
    else
        -- Jika nama tidak pas (exact match), jalankan fitur search
        log("`4Item not found exact match. Searching for similar items...``")
        utils.search(nameorid)
    end
end

function controller.unhidecloth(nameorid)
    -- 1. JIKA INPUT KOSONG, TAMPILKAN SELURUH ISI TABLE
    if not nameorid or nameorid == "" then
        if not config.others.hideClothes or #config.others.hideClothes == 0 then
            log("`4Your hide list is currently empty!``")
            return
        end

        log("`9Current items in hide list (`c" .. #config.others.hideClothes .. "`` total):")
        log("`#----------------------------------------``")
        for i, id in ipairs(config.others.hideClothes) do
            local item = GetItemInfo(id)
            local itemName = item and item.name or "Unknown Item"
            log(string.format(" `w%2d.`` `2%-30s`` `8|`9 ID: `c%d``", i, itemName, id))
        end
        return
    end

    local inputId = tonumber(nameorid)

    -- 2. JIKA INPUT BERUPA ID (ANGKA)
    if inputId then
        for i, id in ipairs(config.others.hideClothes) do
            if tonumber(id) == inputId then
                local item = GetItemInfo(inputId)
                local itemName = item and item.name or tostring(inputId)

                table.remove(config.others.hideClothes, i)
                saveConfig()
                
                log("`2Successfully `9removed `c" .. itemName .. "`` `9from hide list.``")
                return
            end
        end
        log("`4ID '`c" .. inputId .. "``' is not in your hide list!``")
        return
    end

    -- 3. JIKA INPUT BERUPA NAMA (TEKS)
    local searchKey = string.lower(nameorid)
    local exactMatchIndex = nil
    local exactMatchItem = nil
    local matches = {}

    for i, id in ipairs(config.others.hideClothes) do
        local item = GetItemInfo(id)
        if item and item.name then
            local itemNameLower = string.lower(item.name)
            
            -- Exact Match
            if itemNameLower == searchKey then
                exactMatchIndex = i
                exactMatchItem = item
            end

            -- Partial Match
            if string.find(itemNameLower, searchKey, 1, true) then
                table.insert(matches, { index = i, id = id, name = item.name })
            end
        end
    end

    -- Hapus jika Exact Match ditemukan
    if exactMatchIndex then
        table.remove(config.others.hideClothes, exactMatchIndex)
        saveConfig()
        log("`2Successfully `9removed `c" .. exactMatchItem.name .. "`` `9from hide list.``")
        return
    end

    -- Tampilkan pilihan jika hanya Partial Match
    if #matches > 0 then
        log("`9Found `c" .. #matches .. "`` item(s) in hide list matching '`c" .. nameorid .. "``':")
        log("`#----------------------------------------``")
        for i, itemData in ipairs(matches) do
            log(string.format(" `w%2d.`` `2%-30s`` `8|`9 ID: `c%d``", i, itemData.name, itemData.id))
        end
        log("`#----------------------------------------``")
        log("`4Please specify the exact name or ID from the list above to remove.``")
    else
        log("`4No item matching '`c" .. nameorid .. "``' found in your hide list!``")
    end
end

function controller.faststorage()
    toggle(config.others, "fastStorage", false, "Fast Storage Box")
end



local spamRunning = false

local function startSpam()
    if spamRunning then return end

    spamRunning = true

    RunThread(function()
        while spamRunning do
            if config.spam.status ~= 1 then
                break
            end

            SendPacket(2, "action|input\n|text|" .. config.spam.text)

            local waited = 0
            while waited < config.spam.delay do
                if config.spam.status ~= 1 then
                    spamRunning = false
                    return
                end

                Sleep(100)
                waited = waited + 100
            end
        end

        spamRunning = false
    end)
end

function controller.spam()
    sendDialog(dialog("spam"))
end

function controller.startspam()
    local status = toggle(config.spam, "status", false, "Auto Spam")

    if status == 1 then
        startSpam()
    end
end



function controller.log()
    sendDialog(dialog("log"))
end

function controller.spin()
    sendDialog(dialog("spin"))
end

function controller.collect()
    sendDialog(dialog("collect"))
end

function controller.cmdlogs()
    sendDialog(dialog("logCommands"))
end





function controller.relog()
    local currentWorld = GetWorld().name

    say("Relog", true)
    SendPacket(3, "action|join_request\nname|" .. currentWorld .. "\ninvitedWorld|0")
end

function controller.res()
    SendPacket(2, "action|respawn")
end

function controller.mf()
    local status = GetValue("[C] Modfly")

    if status then
        log("`9Modfly `4OFF")
        sendOverlay("`9Modfly `4OFF")
        ChangeValue("[C] Modfly", false)
    else
        log("`9Modfly `2ON")
        sendOverlay("`9Modfly `2ON")
        ChangeValue("[C] Modfly", true)
    end
end

function controller.g()
    SendPacket(2, "action|input\n|text|/ghost")
end



-- ============================================================================
-- NAME HANDLER ===============================================================
-- Pembersih nama yang menghapus rank & spin tag tanpa merusak warna internal nama
local function extract_pure_name(raw_name)
    if not raw_name or raw_name == "" then return "`wPlayer" end
    local clean = tostring(raw_name)

    -- 1. Hapus Spin Tag di bagian BELAKANG secara berulang
    while true do
        local before = clean
        clean = clean:gsub("%s*`?.%b[]%s*$", "")
        clean = clean:gsub("%s*%b[]%s*$", "")
        if clean == before then break end
    end

    -- 2. Hapus Rank Tag di bagian DEPAN secara berulang
    while true do
        local before = clean
        clean = clean:gsub("^%s*`?.%b[]%s*", "")
        clean = clean:gsub("^%s*%b[]%s*", "")
        if clean == before then break end
    end

    -- 3. Trim spasi sisa di awal dan akhir
    clean = clean:gsub("^%s+", ""):gsub("%s+$", "")

    if clean == "" then return "`wPlayer" end

    -- 4. Berikan warna default `w hanya jika nama sama sekali tidak diawali kode warna
    if not clean:find("^`.", 1, true) then
        clean = "`w" .. clean
    end

    return clean
end

-- Fungsi mengambil base name secara DINAMIS (mempertahankan seluruh warna asli nama)
local function get_dynamic_base_name(netid)
    local raw_name = nil

    -- 1. Cek update nama terbaru dari system/server
    if server_names[netid] and server_names[netid] ~= "" then
        raw_name = server_names[netid]
    end

    -- 2. Jika tidak ada update system, fallback ke GetLocal() atau GetPlayer()
    if not raw_name or raw_name == "" then
        local local_avatar = GetLocal and GetLocal()
        if local_avatar and local_avatar.netid == netid then
            raw_name = local_avatar.name
        else
            local player_avatar = GetPlayer and GetPlayer(netid)
            if player_avatar and player_avatar.name then
                raw_name = player_avatar.name
            end
        end
    end

    -- 3. Ekstrak nama asli dengan seluruh kode warna internal yang utuh
    if raw_name and raw_name ~= "" then
        local base = extract_pure_name(raw_name)
        if base ~= "" and base ~= "`wPlayer" then
            return base
        end
    end

    return "`wPlayer"
end

-- Fungsi menyusun nama kustom: [RANK] BASE_NAME [SPIN]
function build_custom_name(netid)
    if not netid or netid < 0 then return nil, 0 end
    local spin = player_spin_titles[netid]
    local override = name_overrides[netid] or {}
    local rank = override.rank or ""
    local base_name = get_dynamic_base_name(netid)
    local world_id = override.world_id or 0

    if not spin and rank == "" then return nil, world_id end

    local custom_name = base_name

    -- Pasang Rank di DEPAN (Format 1 spasi pemisah tanpa spasi ganda)
    if rank ~= "" then
        local clean_rank = rank:gsub("^%s+", ""):gsub("%s+$", "")
        custom_name = clean_rank .. " " .. base_name
    end

    -- Pasang Spin Tag di BELAKANG (Format `%s `#[%s`#]`)
    if spin then
        local clean_spin = tostring(spin):gsub("^%s+", ""):gsub("%s+$", ""):gsub("`b", "`a")
        custom_name = string.format("%s `#[%s`#]", custom_name, clean_spin)
    end

    return custom_name, world_id
end

-- Fungsi mengirim pembaruan nama ke client
local function send_name_update(netid, customName, worldId)
    is_internal_send = true
    SendVariantList({
        [0] = "OnNameChanged",
        [1] = customName,
        [2] = string.format('{"PlayerWorldID":%d,"WrenchCustomization":{"WrenchForegroundID":-1,"WrenchIconID":32}}', worldId or 0)
    }, netid, 0)
    is_internal_send = false
end

-- Fungsi manual pasang Rank
function set_player_rank(netid, rank_prefix, world_id)
    if not netid or netid < 0 then return end

    local override = name_overrides[netid] or {}
    override.rank = rank_prefix
    if world_id then override.world_id = world_id end
    name_overrides[netid] = override

    local customName, wId = build_custom_name(netid)
    if customName then
        send_name_update(netid, customName, wId)
    end
end

-- Fungsi manual pasang Spin
function apply_spin_title(netid, spin_result, world_id)
    if not netid or netid < 0 then return end

    player_spin_titles[netid] = spin_result
    
    local override = name_overrides[netid] or {}
    if world_id then override.world_id = world_id end
    name_overrides[netid] = override

    local customName, wId = build_custom_name(netid)
    if customName then
        send_name_update(netid, customName, wId)
    end
end

-- 1. Fungsi menghapus Rank Tag saja
function remove_player_rank(netid)
    if not netid or netid < 0 then return end

    local override = name_overrides[netid]
    if override then
        override.rank = nil -- Hapus rank dari penyimpanan
        name_overrides[netid] = override
    end

    -- Susun ulang nama atau kirimkan pembaruan nama
    local customName, wId = build_custom_name(netid)
    if customName then
        send_name_update(netid, customName, wId)
    else
        -- Jika rank & spin sudah tidak ada, kembalikan ke nama dasar server
        local baseName = get_dynamic_base_name(netid)
        local worldId = (override and override.world_id) or 0
        send_name_update(netid, baseName, worldId)
    end
end

-- 2. Fungsi menghapus Spin Tag saja
function remove_spin_title(netid)
    if not netid or netid < 0 then return end

    player_spin_titles[netid] = nil -- Hapus spin dari penyimpanan

    local override = name_overrides[netid] or {}
    local customName, wId = build_custom_name(netid)
    if customName then
        send_name_update(netid, customName, wId)
    else
        -- Jika rank & spin sudah tidak ada, kembalikan ke nama dasar server
        local baseName = get_dynamic_base_name(netid)
        local worldId = override.world_id or 0
        send_name_update(netid, baseName, worldId)
    end
end

-- 3. Fungsi menghapus SELURUH Title (Rank & Spin sekaligus)
function reset_player_name(netid)
    if not netid or netid < 0 then return end

    -- Hapus data dari koleksi
    player_spin_titles[netid] = nil
    
    local worldId = 0
    if name_overrides[netid] then
        worldId = name_overrides[netid].world_id or 0
        name_overrides[netid].rank = nil
    end

    -- Kembalikan nama ke nama asli tanpa tag kustom
    local baseName = get_dynamic_base_name(netid)
    send_name_update(netid, baseName, worldId)
end

local function nameHandler(var , nid)
    if is_internal_send then return false end

    if var and var[0] == "OnNameChanged" then
        local netid = nid or (GetLocal and GetLocal() and GetLocal().netid)
        local numericNet = tonumber(netid or -1)

        if numericNet and numericNet >= 0 then
            local incomingName = tostring(var[1] or "")
            local incomingMeta = tostring(var[2] or "")
            local incomingWorldId = tonumber(incomingMeta:match('"PlayerWorldID":(%d+)') or "0") or 0

            local override = name_overrides[numericNet] or {}
            override.world_id = incomingWorldId > 0 and incomingWorldId or (override.world_id or 0)
            name_overrides[numericNet] = override

            if incomingName ~= "" then
                server_names[numericNet] = incomingName
            end

            local customName, worldId = build_custom_name(numericNet)
            if customName then
                if incomingName ~= customName then
                    send_name_update(numericNet, customName, worldId)
                    return true
                end
            end
        end
    end
end
-- ============================================================================
-- DIALOG HANDLER =============================================================
local function dialogHandler(type, packet)
    if packet:find("action|dialog_return", 1, true) then

        if packet:find("dialog_name|options", 1, true) then
            local wrp = tonumber(packet:match("wrp|(%d)"))
            local pBody = tonumber(packet:match("pBody|(%d)"))
            local smodal = tonumber(packet:match("smodal|(%d)"))

            config.wrench.wrp = wrp
            config.wrench.pBody = pBody
            config.wrench.smodal = smodal

            

            local sspin = tonumber(packet:match("sspin|(%d)"))
            local lastspin = tonumber(packet:match("lastspin|(%d)"))

            config.wheel.sspin = sspin
            config.wheel.lastspin = lastspin



            local pthk = tonumber(packet:match("pthk|(%d)"))
            local lphk = tonumber(packet:match("lphk|(%d)"))
            local notify = tonumber(packet:match("notify|(%d)"))

            config.pt.hotkey = pthk
            config.lp.hotkey = lphk
            config.autopull.notify = notify



            local fastcv = tonumber(packet:match("fastcv|(%d)"))
            local cvdl = tonumber(packet:match("cvdl|(%d)"))
            local cvbgl = tonumber(packet:match("cvbgl|(%d)"))
            local cvblack = tonumber(packet:match("cvblack|(%d)"))

            config.telephone.fastcv = fastcv
            config.currency.cvdl = cvdl
            config.currency.cvbgl = cvbgl
            config.currency.cvblack = cvblack



            local tp = tonumber(packet:match("tp|(%d)"))
            local hidechamp = tonumber(packet:match("hidechamp|(%d)"))
            local bsdb = tonumber(packet:match("bsdb|(%d)"))
            local imgui = tonumber(packet:match("imgui|(%d)"))

            config.andro.tp = tp
            config.others.hidechamp = hidechamp
            config.others.bsdb = bsdb
            config.others.imgui = imgui



            local findpath = tonumber(packet:match("findpath|(%d)"))
            local findpath2 = tonumber(packet:match("findpath2|(%d)"))
            local collectMsg = tonumber(packet:match("collectMsg|(%d)"))
            local dropMsg = tonumber(packet:match("dropMsg|(%d)"))
            local calcMsg = tonumber(packet:match("calcMsg|(%d)"))
            local gameMsg = tonumber(packet:match("gameMsg|(%d)"))
            local wmMsg = tonumber(packet:match("wmMsg|(%d)"))

            config.others.findpath = findpath
            config.others.findpath2 = findpath2
            config.others.collectMsg = collectMsg
            config.others.dropMsg = dropMsg
            config.others.calcMsg = calcMsg
            config.others.gameMsg = gameMsg
            config.others.wmMsg = wmMsg
            
            saveConfig()

            RunThread(function()
                Sleep(100)

                if config.others.imgui == 1 then
                    AddHook("OnDraw", "imgui", imgui)
                else
                    RemoveHook("imgui")
                end
            end)
        end

        if packet:find("dialog_name|logDialog", 1, true) then
            if packet:find("buttonClicked|logSpin", 1, true) then
                sendDialog(dialog("spin"))
            end

            if packet:find("buttonClicked|logCollect", 1, true) then
                sendDialog(dialog("collect"))
            end

            if packet:find("buttonClicked|logCommands", 1, true) then
                sendDialog(dialog("logCommands"))
            end

            if packet:find("buttonClicked|clearAllLogs", 1, true) then
                logs.spin = {}
                logs.collect = {}
                logs.commands = {}

                log("`2Successfully `9Removed All Spin & Collect Logs")
            end
        end


        if packet:find("dialog_name|spinLog", 1, true) then
            if packet:find("buttonClicked|clearSpinLog", 1, true) then
                logs.spin = {}
                sendDialog(dialog("spin"))
            end
        end

        if packet:find("dialog_name|collectLog", 1, true) then
            if packet:find("buttonClicked|clearCollectLog", 1, true) then
                logs.collect = {}
                sendDialog(dialog("collect"))
            end
        end

        if packet:find("dialog_name|commandsLogs", 1, true) then
            if packet:find("buttonClicked|clearCommandsLogs", 1, true) then
                logs.commands = {}
                sendDialog(dialog("logCommands"))
            end
        end




        if packet:find("dialog_name|spam", 1, true) then
            config.spam.text = packet:match("spamText|([^\n]+)")
            config.spam.delay = tonumber(packet:match("spamDelay|(%d+)"))

            if packet:find("buttonClicked|startSpam") then
                local status = toggle(config.spam, "status", false, "Auto Spam")

                if status == 1 then
                    startSpam()
                end
            end

            saveConfig()
        end

        if packet:find("dialog_name|autopull", 1, true) then
            local notify = tonumber(packet:match("enableNotify|(%d)"))
            local minimum = tonumber(packet:match("minModal|(%d+)"))
            local minDelay = tonumber(packet:match("minDelay|(%d+)"))
            local maxDelay = tonumber(packet:match("maxDelay|(%d+)"))

            config.autopull.notify = tonumber(notify)
            config.autopull.minimum = tonumber(minimum)
            config.autopull.minDelay = tonumber(minDelay)
            config.autopull.maxDelay = tonumber(maxDelay)

            log("`9Notify Set To " .. (config.autopull.notify == 1 and "`2True" or "`4False"))
            log("`9Minimum Modal Set To `c" .. config.autopull.minimum .. " `1DLS")
            log(string.format("`9Auto Pull Tile (`c%d `9, `c%d`9)", config.autopull.tile.x, config.autopull.tile.y))

            if packet:find("buttonClicked|setap", 1, true) then
                cache.autopull.setap = true
                log("`2Click Tile `9To Set Auto Pull Tile")
                sendOverlay("`2Click Tile `9To Set Auto Pull Tile")
            end

            if packet:find("buttonClicked|addBL_") then
                local uid, name = packet:match("buttonClicked|addBL_(%d-)_([^\n]+)")
                local name = name:gsub(" `b%((%d+)%)", "")

                table.insert(config.autopull.blacklist, {
                    userid = tonumber(uid),
                    growid = name
                })

                sendDialog(dialog("autopull"))

            end

            if packet:find("buttonClicked|addManualBlacklist", 1, true) then
                local uid = tonumber(packet:match("manualBlacklist|(%d+)"))
                local label = packet:match("manualBlacklistLabel|([^\n]+)")

                if uid and label then
                    table.insert(config.autopull.blacklist, {
                        userid = tonumber(uid),
                        growid = label
                    })

                    log("`2Successfully `9Added `c#" .. uid .. "``/`c'" .. label .. "' ``To Blacklist")
                end

                sendDialog(dialog("autopull"))
            end

            if packet:find("buttonClicked|openBlacklistDialog", 1, true) then
                sendDialog(dialog("APBlacklist"))
            end

            local i = 0
            for _, _ in ipairs(config.autopull.blacklist) do
                i = i+1
            end

            log("`9Total Blacklisted User: `c" .. i)

            saveConfig()
        end




        if packet:find("dialog_name|APBlacklist", 1, true) then
            if packet:find("buttonClicked|removeBL_", 1, true) then
                local uid = packet:match("buttonClicked|removeBL_(%d+)")
                uid = tonumber(uid)

                for i, bl in ipairs(config.autopull.blacklist) do
                    if bl.userid == uid then
                        table.remove(config.autopull.blacklist, i)
                    end
                end

                sendDialog(dialog("APBlacklist"))

                saveConfig()

                log(" ")
                log("`c" .. tostring(uid) .. " `9Removed From Blacklist")

                local i = 0
                for _, _ in ipairs(config.autopull.blacklist) do
                    i = i+1
                end

                log("`9Total Blacklisted User: `c" .. i)
            end


            if packet:find("buttonClicked|clearblacklist", 1, true) then
                local count = 0
                for _, _ in ipairs(config.autopull.blacklist) do
                    count = count+1
                end

                log("`2Successfully `9Cleared Blacklist")
                log("`9Removed Blacklist: `c" .. count)

                config.autopull.blacklist = {}

                saveConfig()



                local i = 0
                for _, _ in ipairs(config.autopull.blacklist) do
                    i = i+1
                end

                log("`9Total Blacklisted User: `c" .. i)
            end


            if packet:find("buttonClicked|backToAPDialog", 1, true) then
                sendDialog(dialog("autopull"))
            end
        end



        if packet:find("dialog_name|wrm", 1, true) then
            config.wrench.pText = packet:match("pText|([^\n]+)") or config.wrench.pText
            config.wrench.kText = packet:match("kText|([^\n]+)") or config.wrench.kText
            config.wrench.bText = packet:match("bText|([^\n]+)") or config.wrench.bText

            config.wrench.smodal = tonumber(packet:match("smodal|(%d+)")) or config.wrench.smodal
            config.wrench.pBody = tonumber(packet:match("pBody|(%d+)")) or config.wrench.pBody

            
            if packet:find("buttonClicked|wrp") then
                setExclusive(config.wrench, "wrp", {"wrk", "wrb"}, false, "`9Wrench Pull")
                sendDialog(dialog("wrm"))
            end
            
            if packet:find("buttonClicked|wrk") then
                setExclusive(config.wrench, "wrk", {"wrp", "wrb"}, false, "`9Wrench Kick")
                sendDialog(dialog("wrm"))
            end
            
            if packet:find("buttonClicked|wrb") then
                setExclusive(config.wrench, "wrb", {"wrk", "wrp"}, false, "`9Wrench Ban")
                sendDialog(dialog("wrm"))
            end

            if packet:find("buttonClicked|offWrench") then
                config.wrench.wrp = 0
                config.wrench.wrk = 0
                config.wrench.wrb = 0

                log("`4Disabled `9Wrench Action")
                say("`4Disabled `9Wrench Action", false)
                sendDialog(dialog("wrm"))
            end

            saveConfig()
        end

    end
end
-- ============================================================================
-- PACKETHOOK =================================================================
local function PacketHook(type, packet)

    if packet:find("action|dialog_return\ndialog_name|storage", 1, true) and config.others.fastStorage == 1 then
        local x = tonumber(packet:match("x|(%d+)|"))
        local y = tonumber(packet:match("y|(%d+)|"))
        if not packet:find("buttonClicked") then
            local itemId = tonumber(packet:match("item|(%d+)"))
            local itemBp = GetItemCount(itemId)

            if itemBp and itemId and x and y then
                local packet = {
                    "action|dialog_return",
                    "dialog_name|storage",
                    "item|" .. itemId .. "|",
                    "x|" .. x .. "|",
                    "y|" .. y .. "|",
                    "buttonClicked|store_confirm",
                    "item_count|" .. itemBp
                }
                SendPacket(2, table.concat(packet, "\n"))
            else
                log("`4Something Invalid")
                sendOverlay("`4Something Invalid")
            end

            return true
        elseif packet:find("buttonClicked|item_", 1, true) then
            -- Tangkap hash saat item diklik (buttonClicked|item_2328744195)
            local clickedHash = string.match(packet, "buttonClicked|item_(%d+)")
            local x = tonumber(packet:match("x|(%d+)|"))
            local y = tonumber(packet:match("y|(%d+)|"))
            
            if clickedHash then
                local itemData = storageItems[clickedHash]

                if itemData then
                    -- Berhasil mendapatkan total count dan detail item
                    local packet = {
                        "action|dialog_return",
                        "dialog_name|storage",
                        "x|" .. x .. "|",
                        "y|" .. y .. "|",
                        "hash|" .. clickedHash .. "|",
                        "buttonClicked|withdraw",
                        "item_count|" .. itemData.count
                    }

                    SendPacket(2, table.concat(packet, "\n"))

                    return true
                else
                    LogToConsole("`4Item data not found in cache for Hash: `c" .. clickedHash .. "``")

                    return true
                end
            end
        end
    end

    if packet:find("action|input\n|text|", 1, true) and not packet:find("/", 1, true) then
        local text = packet:match("action|input\n|text|(.+)")
        local coloredText = config.chat.color .. text
        local watermarkedText = config.chat.wm .. coloredText

        SendPacket(2, "action|input\n|text|" .. watermarkedText)

        return true
    end

    if packet:find("action|showdungeonsui", 1, true) and config.lp.hotkey == 1 then
        if cache.lp.uid == 0 then
            log("`9Last Pulled Data `4EMPTY/ 0")

            return true
        end

        RunThread(function()
            for _, player in pairs(GetPlayerList()) do
                local userid = player.userid

                if tonumber(userid) == cache.lp.uid then
                    utils.wrenchAction("pull", player.netid)

                    Sleep(200)
                    if config.wrench.smodal == 1 then
                        utils.wrenchAction("smodal", player.netid)
                    end
                end
            end
            Sleep(50)
        end)

        return true
    end


    if packet:find("action|eventmenu", 1, true) and config.pt.hotkey == 1 then

        controller.pt()

        return true
    end



    if packet:find("action|wrench\n|netid|", 1, true) then

        local netid =
            tonumber(
                packet:match("|netid|(%d+)")
            )

        if not netid or netid == GetLocal().netid then
            return false
        end

        local hasFastAction = false

        if config.wrench.wrp == 1 then

            hasFastAction = true

            utils.wrenchAction(
                "pull",
                netid
            )

        elseif config.wrench.wrk == 1 then

            hasFastAction = true

            utils.wrenchAction(
                "kick",
                netid
            )

        elseif config.wrench.wrb == 1 then

            hasFastAction = true

            utils.wrenchAction(
                "ban",
                netid
            )

        end

        if config.wrench.smodal == 1 and config.wrench.wrb == 0 and config.wrench.wrk == 0 then

            local targetNetid = netid

            if hasFastAction then

                RunThread(function()

                    Sleep(50)

                    utils.wrenchAction(
                        "smodal",
                        targetNetid
                    )

                end)

            else

                utils.wrenchAction(
                    "smodal",
                    targetNetid
                )

            end

        end

        if hasFastAction then
            return true
        end

    end
end


-- ============================================================================
-- HOTKEY =====================================================================

local function IsKeyDown(key)
    if type(GetAsyncKeyState) ~= "function" then
        return false
    end

    local ok, state = pcall(GetAsyncKeyState, key)

    if not ok then
        return false
    end

    state = tonumber(state) or 0

    return state < 0 or state >= 32768
end

local function Hotkey(key)
    if key == 112 and config.pt.hotkey == 1 then
        if config.pt.x == 0 and config.pt.y == 0 then
            log("`4Set Tile With `9'`2/setpt`9' `4First")

            return
        end

        controller.pt()
    end



    if key == 116 and config.lp.hotkey == 1 then
        if not IsKeyDown(116) then -- Shift
            return
        end

        if cache.lp.uid == 0 then
            log("`9Last Pulled Data `4EMPTY/ 0")

            return
        end

        controller.lastpull()
    end
end

-- ============================================================================
-- ============================================================================
-- WORLDTOUCH =================================================================

local function WorldTouchHook(pos, start)
    if not start then return end

    local x = math.floor(pos.x / 32)
    local y = math.floor(pos.y / 32)

    local isShiftDown = IsKeyDown(16) -- Shift Key
    local isCtrlDown  = IsKeyDown(17) -- Ctrl Key

    -- 1. Teleport Biasa (Shift + Touch)
    if isShiftDown and config.others.findpath == 1 then
        if CheckPath(x, y) then
            RunThread(function()
                FindPath(x, y)
                utils.lbotEffect(x * 32, y * 32)

                sendOverlay(
                    "`2Teleporting To `9" .. x .. "`2, `9" .. y
                )
            end)
        else
            log("`4Cannot Teleport To Chosen Tile")
        end
    end

    -- 2. Teleport Bolak-Balik / Ping-Pong (Ctrl + Touch)
    local player = GetLocal()
    if isCtrlDown and config.others.findpath2 == 1 then
        if CheckPath(x, y) then
            RunThread(function()
                local posAwal = {
                    x = math.floor(player.pos.x/32),
                    y = math.floor(player.pos.y/32)
                }

                local _,playerSkrg = pcall(GetLocal)
                local posSkrg = {
                    x = math.floor(playerSkrg.pos.x/32),
                    y = math.floor(playerSkrg.pos.y/32)
                }
                
                FindPath(x, y)
                utils.lbotEffect(x*32, y*32)

                if math.floor(GetLocal().pos.x/32) == posSkrg.x and math.floor(GetLocal().pos.y/32) == posSkrg.y then
                    FindPath(posAwal.x, posAwal.y)
                end
            end)
        else
            log("`4Cannot Teleport To Chosen Tile")
        end
    end

    -- 3. Wrench Player Body Action (Item 32 / Wrench)
    if GetPlayerInfo().backpack.selected == 32 and start and config.wrench.pBody == 1 then
        for _, player in pairs(GetPlayerList()) do
            local px = math.floor(player.pos.x / 32)
            local py = math.floor(player.pos.y / 32)
            local area = math.abs(px - x) <= 1 and math.abs(py - y) <= 1

            if area and player.netid ~= GetLocal().netid then
                RunThread(function()
                    utils.wrenchAction("pull", player.netid)
                    Sleep(200)
                    if config.wrench.smodal == 1 then
                        utils.wrenchAction("smodal", player.netid)
                    end
                end)
            end
        end
    end

    -- 4. Set Auto Pull Tile Target
    if cache.autopull.setap then
        RunThread(function()
            utils.lockEffect(x, y)

            config.autopull.tile.x = tonumber(x)
            config.autopull.tile.y = tonumber(y)

            Sleep(50)
            saveConfig()

            cache.autopull.setap = false
            log(string.format("`9Auto Pull Tile `2Successfully `9Set To (`c%d `9, `c%d`9)", config.autopull.tile.x, config.autopull.tile.y))
        end)
    end
end

-- ============================================================================
-- RAW HOOK ===================================================================
local function rawHook(packet)
    if IsKeyDown(16) or IsKeyDown(17) or packet and packet.type == 3 and cache.autopull.setap then
        if packet and packet.type == 3 then
            return true
        end
    end


    if packet and packet.type == 3 and config.andro.tp == 1 and GetTile(packet.px, packet.py).fg == 1422 then
        local x = packet.px
        local y = packet.py
        local player = GetLocal()

        if CheckPath(x, y) then
            RunThread(function()
                local posAwal = {
                    x = math.floor(player.pos.x/32),
                    y = math.floor(player.pos.y/32)
                }

                local _,playerSkrg = pcall(GetLocal)
                local posSkrg = { 
                    x = math.floor(playerSkrg.pos.x/32),
                    y = math.floor(playerSkrg.pos.y/32)
                }
                
                FindPath(x, y)
                utils.lbotEffect(x*32, y*32)

                if math.floor(GetLocal().pos.x/32) == posSkrg.x and math.floor(GetLocal().pos.y/32) == posSkrg.y then
                    FindPath(posAwal.x, posAwal.y)
                end
            end)

            return true
        end
    end
end

-- ============================================================================
-- VARIANTHOOK ================================================================
local firstOpen = true
local notesBP = (GetItemCount(242)/10000) + (GetItemCount(1796)/100) + GetItemCount(7188) + (GetItemCount(const.itemId.black)*100)
-- Letakkan di luar draw/UI function agar nilai search tidak reset setiap frame
local blacklistSearch = ""

-- Variabel penampung buffer (letakkan di luar hook)
local collectQueue = {
    totalValue = 0,
    lastTick = 0,
    active = false
}

local function imgui(dt)

    -- =========================================================
    -- WINDOW
    -- =========================================================

    if firstOpen then
        ImGui.SetNextWindowSize(ImVec2(680, 500))
        firstOpen = false
    end

    if not ImGui.Begin("IMMORTAL Proxy v" .. ver) then
        ImGui.End()
        return
    end


    -- =========================================================
    -- COLORS
    -- =========================================================

    local COLOR_GREEN = ImVec4(0.30, 0.90, 0.45, 1.00)
    local COLOR_RED = ImVec4(0.95, 0.35, 0.35, 1.00)
    local COLOR_YELLOW = ImVec4(1.00, 0.78, 0.25, 1.00)
    local COLOR_BLUE = ImVec4(0.35, 0.65, 1.00, 1.00)
    local COLOR_GRAY = ImVec4(0.65, 0.65, 0.65, 1.00)


    -- =========================================================
    -- HELPERS
    -- =========================================================

    local function bool(value)
        return value == 1
    end

    local function setBool(tbl, key, value)
        tbl[key] = value and 1 or 0
        saveConfig()
    end

    local function cleanName(name)
        return tostring(name or "Unknown"):gsub("`.", "")
    end

    local function drawSection(title)
        ImGui.TextColored(COLOR_BLUE, title)
        ImGui.Separator()
    end

    local function statusText(enabled)
        if enabled then
            ImGui.TextColored(COLOR_GREEN, "ON")
        else
            ImGui.TextColored(COLOR_RED, "OFF")
        end
    end

    local function getRouletteMode()

        if config.wheel.reme == 1 then
            return "REME"

        elseif config.wheel.leme == 1 then
            return "LEME"

        elseif config.wheel.qeme == 1 then
            return "QEME"
        end

        return "OFF"
    end

    local function getWrenchMode()

        if config.wrench.wrp == 1 then
            return "PULL"

        elseif config.wrench.wrk == 1 then
            return "KICK"

        elseif config.wrench.wrb == 1 then
            return "BAN"
        end

        return "OFF"
    end

    local function getCurrentBGL()

        return
            (GetItemCount(242) / 10000)
            + (GetItemCount(1796) / 100)
            + GetItemCount(7188)
            + (GetItemCount(const.itemId.black) * 100)
    end

    local function formatChange(value)

        if value > 0 then
            return "+" .. string.format("%.2f", value)

        elseif value < 0 then
            return string.format("%.2f", value)
        end

        return "0.00"
    end

    local function isPlayerBlacklisted(userid)

        for _, bl in ipairs(config.autopull.blacklist) do

            if tonumber(bl.userid) == tonumber(userid) then
                return true
            end
        end

        return false
    end

    local function addPlayerToBlacklist(player)

        if not player or not player.userid then
            return false
        end

        if isPlayerBlacklisted(player.userid) then
            return false
        end

        table.insert(
            config.autopull.blacklist,
            {
                userid = tonumber(player.userid),
                growid = player.name
                    or tostring(player.userid)
            }
        )

        saveConfig()

        return true
    end


    -- =========================================================
    -- HEADER
    -- =========================================================

    local currentBGL = getCurrentBGL()
    local bpChange = currentBGL - (notesBP or 0)

    ImGui.TextColored(
        COLOR_BLUE,
        "IMMORTAL PROXY"
    )

    ImGui.SameLine()

    ImGui.TextDisabled(
        "v" .. ver
    )

    ImGui.SameLine()

    if ImGui.Button(
        "Set Notes##header"
    ) then

        notesBP = currentBGL
    end

    ImGui.SameLine()

    if ImGui.Button(
        "Reset Size"
    ) then

        firstOpen = true
    end

    ImGui.SameLine()

    if ImGui.Button(
        "Clear Cache"
    ) then

        clearCache()

        log(
            "`2Successfully `9Cleared Cache"
        )
    end

    ImGui.Separator()


    -- =========================================================
    -- NOTES BGL
    -- =========================================================

    ImGui.Text("Notes BGL:")

    ImGui.SameLine()

    ImGui.TextColored(
        COLOR_YELLOW,
        string.format(
            "%.2f",
            notesBP or 0
        )
    )

    ImGui.SameLine()

    ImGui.Text("(")

    ImGui.SameLine()

    if bpChange > 0 then

        ImGui.TextColored(
            COLOR_GREEN,
            formatChange(bpChange)
        )

    elseif bpChange < 0 then

        ImGui.TextColored(
            COLOR_RED,
            formatChange(bpChange)
        )

    else

        ImGui.TextColored(
            COLOR_GRAY,
            formatChange(bpChange)
        )
    end

    ImGui.SameLine()

    ImGui.Text(")")

    ImGui.SameLine()

    ImGui.TextDisabled(
        "| Current: " ..
        string.format(
            "%.2f",
            currentBGL
        )
    )

    ImGui.Separator()


    -- =========================================================
    -- STATUS BAR
    -- =========================================================

    ImGui.Text("AP:")

    ImGui.SameLine()

    statusText(
        config.autopull.status == 1
    )

    ImGui.SameLine()

    ImGui.TextDisabled("|")

    ImGui.SameLine()

    ImGui.Text("Wheel:")

    ImGui.SameLine()

    local wheelMode = getRouletteMode()

    if wheelMode == "OFF" then

        ImGui.TextColored(
            COLOR_GRAY,
            wheelMode
        )

    else

        ImGui.TextColored(
            COLOR_YELLOW,
            wheelMode
        )
    end

    ImGui.SameLine()

    ImGui.TextDisabled("|")

    ImGui.SameLine()

    ImGui.Text("Wrench:")

    ImGui.SameLine()

    local wrenchMode = getWrenchMode()

    if wrenchMode == "OFF" then

        ImGui.TextColored(
            COLOR_GRAY,
            wrenchMode
        )

    else

        ImGui.TextColored(
            COLOR_BLUE,
            wrenchMode
        )
    end

    ImGui.SameLine()

    ImGui.TextDisabled("|")

    ImGui.SameLine()

    ImGui.Text("Spam:")

    ImGui.SameLine()

    statusText(
        config.spam.status == 1
    )

    ImGui.Separator()


    -- =========================================================
    -- MAIN TAB BAR
    -- =========================================================

    if ImGui.BeginTabBar(
        "ImmortalTabs"
    ) then


        -- =====================================================
        -- HOME
        -- =====================================================

        if ImGui.BeginTabItem(
            "Home"
        ) then

            drawSection("OVERVIEW")

            if ImGui.BeginTable(
                "HomeStatus",
                2,
                true
            ) then

                ImGui.TableNextRow()

                ImGui.TableSetColumnIndex(0)
                ImGui.Text("Current BGL")

                ImGui.TableSetColumnIndex(1)

                ImGui.TextColored(
                    COLOR_YELLOW,
                    string.format(
                        "%.2f",
                        currentBGL
                    )
                )


                ImGui.TableNextRow()

                ImGui.TableSetColumnIndex(0)
                ImGui.Text("Notes BGL")

                ImGui.TableSetColumnIndex(1)

                ImGui.Text(
                    string.format(
                        "%.2f (%s)",
                        notesBP or 0,
                        formatChange(bpChange)
                    )
                )


                ImGui.TableNextRow()

                ImGui.TableSetColumnIndex(0)
                ImGui.Text("Auto Pull")

                ImGui.TableSetColumnIndex(1)

                if config.autopull.status == 1 then

                    ImGui.TextColored(
                        COLOR_GREEN,
                        "Enabled"
                    )

                else

                    ImGui.TextColored(
                        COLOR_RED,
                        "Disabled"
                    )
                end


                ImGui.TableNextRow()

                ImGui.TableSetColumnIndex(0)
                ImGui.Text("Minimum")

                ImGui.TableSetColumnIndex(1)

                ImGui.Text(
                    tostring(
                        config.autopull.minimum
                    ) .. " DL"
                )


                ImGui.TableNextRow()

                ImGui.TableSetColumnIndex(0)
                ImGui.Text("Roulette")

                ImGui.TableSetColumnIndex(1)

                local mode =
                    getRouletteMode()

                if mode == "OFF" then

                    ImGui.TextColored(
                        COLOR_GRAY,
                        mode
                    )

                else

                    ImGui.TextColored(
                        COLOR_YELLOW,
                        mode
                    )
                end


                ImGui.TableNextRow()

                ImGui.TableSetColumnIndex(0)
                ImGui.Text("Wrench")

                ImGui.TableSetColumnIndex(1)

                local wrench =
                    getWrenchMode()

                if wrench == "OFF" then

                    ImGui.TextColored(
                        COLOR_GRAY,
                        wrench
                    )

                else

                    ImGui.TextColored(
                        COLOR_BLUE,
                        wrench
                    )
                end


                ImGui.TableNextRow()

                ImGui.TableSetColumnIndex(0)
                ImGui.Text("Spam")

                ImGui.TableSetColumnIndex(1)

                if config.spam.status == 1 then

                    ImGui.TextColored(
                        COLOR_GREEN,
                        "Running"
                    )

                else

                    ImGui.TextColored(
                        COLOR_RED,
                        "Stopped"
                    )
                end

                ImGui.EndTable()
            end

            ImGui.Spacing()

            drawSection("QUICK ACTIONS")

            if ImGui.Button(
                config.autopull.status == 1
                    and "Disable Auto Pull"
                    or "Enable Auto Pull",
                ImVec2(140, 0)
            ) then

                controller.ap()
            end

            ImGui.SameLine()

            if ImGui.Button(
                config.spam.status == 1
                    and "Stop Spam"
                    or "Start Spam",
                ImVec2(120, 0)
            ) then

                controller.startspam()
            end

            ImGui.SameLine()

            if ImGui.Button(
                "Pull Tile",
                ImVec2(100, 0)
            ) then

                controller.pt()
            end

            ImGui.SameLine()

            if ImGui.Button(
                "Last Pull",
                ImVec2(100, 0)
            ) then

                controller.lastpull()
            end

            ImGui.Spacing()

            if ImGui.Button(
                "Set Notes To Current BGL"
            ) then

                notesBP = currentBGL
            end

            ImGui.EndTabItem()
        end


        -- =====================================================
        -- AUTO PULL
        -- =====================================================

        if ImGui.BeginTabItem(
            "Auto Pull"
        ) then

            if ImGui.BeginTabBar(
                "AutoPullTabs"
            ) then


                -- =================================================
                -- SETTINGS + PLAYER ACTIONS
                -- =================================================

                if ImGui.BeginTabItem(
                    "Settings"
                ) then

                    -- =============================================
                    -- AUTO PULL SETTINGS
                    -- =============================================

                    drawSection(
                        "AUTO PULL SETTINGS"
                    )

                    local changed,
                    value =
                        ImGui.Checkbox(
                            "Enable Auto Pull",
                            bool(
                                config.autopull.status
                            )
                        )

                    if changed then

                        setBool(
                            config.autopull,
                            "status",
                            value
                        )
                    end


                    local notifyChanged,
                    notifyValue =
                        ImGui.Checkbox(
                            "Notify",
                            bool(
                                config.autopull.notify
                            )
                        )

                    if notifyChanged then

                        setBool(
                            config.autopull,
                            "notify",
                            notifyValue
                        )
                    end


                    ImGui.Spacing()

                    ImGui.TextDisabled(
                        string.format(
                            "Target Tile: (%d, %d)",
                            config.autopull.tile.x,
                            config.autopull.tile.y
                        )
                    )

                    ImGui.SameLine()

                    if ImGui.Button(
                        "Set Tile"
                    ) then

                        controller.setap()
                    end


                    local minChanged,
                    newMinimum =
                        ImGui.InputInt(
                            "Minimum DL",
                            config.autopull.minimum
                        )

                    if minChanged then

                        if newMinimum < 0 then
                            newMinimum = 0
                        end

                        config.autopull.minimum =
                            newMinimum

                        saveConfig()
                    end


                    -- =============================================
                    -- BLACKLIST ACTIONS
                    -- =============================================

                    ImGui.Spacing()
                    ImGui.Separator()
                    ImGui.Spacing()

                    ImGui.TextColored(
                        COLOR_BLUE,
                        "BLACKLIST ACTIONS"
                    )

                    ImGui.TextDisabled(
                        "Add all valid players currently in the world."
                    )

                    if ImGui.Button(
                        "Blacklist All Players",
                        ImVec2(180, 0)
                    ) then

                        controller.blacklistall()
                    end

                    ImGui.SameLine()

                    ImGui.TextDisabled(
                        tostring(
                            #config.autopull.blacklist
                        ) ..
                        " blacklisted"
                    )


                    -- =============================================
                    -- PLAYER ACTIONS
                    -- =============================================

                    ImGui.Spacing()
                    ImGui.Separator()
                    ImGui.Spacing()

                    ImGui.TextColored(
                        COLOR_BLUE,
                        "PLAYERS IN CURRENT WORLD"
                    )

                    ImGui.TextDisabled(
                        "Pull, kick, ban, inspect, or add players to blacklist."
                    )

                    ImGui.Separator()


                    -- =============================================
                    -- SEARCH
                    -- =============================================

                    ImGui.SetNextItemWidth(-1)

                    local searchChanged, newSearch =
                        ImGui.InputTextWithHint(
                            "##PlayerSearch",
                            "Search player or UserID...",
                            playerSearch,
                            100
                        )

                    if searchChanged then
                        playerSearch = newSearch
                    end


                    ImGui.Spacing()


                    -- =============================================
                    -- PLAYER LIST
                    -- =============================================

                    if ImGui.BeginChild(
                        "PlayerActionScroll",
                        ImVec2(0, 0),
                        true
                    ) then

                        local players =
                            GetPlayerList()

                        local localPlayer =
                            GetLocal()

                        local playerCount = 0
                        local search = tostring(
                            playerSearch or ""
                        ):lower()


                        if players
                            and localPlayer
                        then

                            if ImGui.BeginTable(
                                "PlayerActionTable",
                                2,
                                true
                            ) then

                                ImGui.TableSetupColumn(
                                    "Player",
                                    ImVec2(0, 0)
                                )

                                ImGui.TableSetupColumn(
                                    "Actions",
                                    ImVec2(280, 0)
                                )

                                ImGui.TableHeadersRow()


                                -- =============================================
                                -- PLAYERS
                                -- =============================================

                                for _, player
                                    in pairs(players)
                                do

                                    if
                                        player
                                        and player.netid
                                        and player.name
                                        and player.netid
                                            ~= localPlayer.netid
                                    then

                                        local name =
                                            cleanName(
                                                tostring(
                                                    player.name
                                                )
                                            )

                                        local userid =
                                            tostring(
                                                player.userid or ""
                                            )


                                        -- =============================================
                                        -- SEARCH FILTER
                                        -- =============================================

                                        local nameLower =
                                            name:lower()

                                        local useridLower =
                                            userid:lower()

                                        local matches =
                                            search == ""
                                            or nameLower:find(
                                                search,
                                                1,
                                                true
                                            ) ~= nil
                                            or useridLower:find(
                                                search,
                                                1,
                                                true
                                            ) ~= nil


                                        if matches then

                                            if not name:find(
                                                "Spammer Slave",
                                                1,
                                                true
                                            ) then

                                                playerCount =
                                                    playerCount + 1


                                                ImGui.TableNextRow()


                                                -- =============================================
                                                -- PLAYER
                                                -- =============================================

                                                ImGui.TableSetColumnIndex(
                                                    0
                                                )

                                                ImGui.Text(
                                                    name
                                                )

                                                if player.userid then

                                                    ImGui.SameLine()

                                                    ImGui.TextDisabled(
                                                        "#" ..
                                                        userid
                                                    )

                                                end


                                                -- =============================================
                                                -- ACTIONS
                                                -- =============================================

                                                ImGui.TableSetColumnIndex(
                                                    1
                                                )


                                                -- PULL
                                                if ImGui.Button(
                                                    "Pull##" ..
                                                    player.netid,
                                                    ImVec2(42, 0)
                                                ) then

                                                    utils.wrenchAction(
                                                        "pull",
                                                        player.netid
                                                    )

                                                end

                                                ImGui.SameLine()


                                                -- KICK
                                                if ImGui.Button(
                                                    "Kick##" ..
                                                    player.netid,
                                                    ImVec2(42, 0)
                                                ) then

                                                    utils.wrenchAction(
                                                        "kick",
                                                        player.netid
                                                    )

                                                end

                                                ImGui.SameLine()


                                                -- BAN
                                                if ImGui.Button(
                                                    "Ban##" ..
                                                    player.netid,
                                                    ImVec2(42, 0)
                                                ) then

                                                    utils.wrenchAction(
                                                        "ban",
                                                        player.netid
                                                    )

                                                end

                                                ImGui.SameLine()


                                                -- INFO
                                                if ImGui.Button(
                                                    "Info##" ..
                                                    player.netid,
                                                    ImVec2(42, 0)
                                                ) then

                                                    utils.wrenchAction(
                                                        "smodal",
                                                        player.netid
                                                    )

                                                end

                                                ImGui.SameLine()


                                                -- =============================================
                                                -- BLACKLIST
                                                -- =============================================

                                                if player.userid then

                                                    if isPlayerBlacklisted(
                                                        player.userid
                                                    ) then

                                                        ImGui.TextColored(
                                                            COLOR_GREEN,
                                                            "Added"
                                                        )

                                                    else

                                                        if ImGui.Button(
                                                            "Blacklist##" ..
                                                            player.netid,
                                                            ImVec2(75, 0)
                                                        ) then

                                                            if addPlayerToBlacklist(
                                                                player
                                                            ) then

                                                                log(
                                                                    "`2Successfully `9Added `c" ..
                                                                    name ..
                                                                    " `9to blacklist"
                                                                )

                                                            end
                                                        end
                                                    end
                                                end

                                            end
                                        end
                                    end
                                end


                                ImGui.EndTable()

                            end


                            -- =============================================
                            -- EMPTY / NO SEARCH RESULT
                            -- =============================================

                            if playerCount == 0 then

                                if search ~= "" then

                                    ImGui.TextDisabled(
                                        "No players found for \"" ..
                                        playerSearch ..
                                        "\""
                                    )

                                else

                                    ImGui.TextDisabled(
                                        "No valid players found in this world"
                                    )

                                end
                            end

                        else

                            ImGui.TextDisabled(
                                "Unable to detect players"
                            )

                        end

                        ImGui.EndChild()

                    end


                    ImGui.EndTabItem()
                end


                -- =================================================
                -- BLACKLIST
                -- =================================================

                if ImGui.BeginTabItem(
                    "Blacklist"
                ) then

                    drawSection("BLACKLIST")

                    if ImGui.Button(
                        "Clear All",
                        ImVec2(100, 0)
                    ) then

                        controller.clearblacklist()

                    end

                    ImGui.SameLine()

                    ImGui.TextDisabled(
                        tostring(
                            #config.autopull.blacklist
                        ) .. " users"
                    )

                    -- SEARCH
                    ImGui.SetNextItemWidth(-1)

                    local searchChanged, newSearch =
                        ImGui.InputTextWithHint(
                            "##BlacklistSearch",
                            "Search GrowID or UserID...",
                            blacklistSearch,
                            100
                        )

                    if searchChanged then
                        blacklistSearch = newSearch
                    end

                    ImGui.Separator()

                    if ImGui.BeginChild(
                        "BlacklistScroll",
                        ImVec2(0, 0),
                        true
                    ) then

                        local removeIndex = nil
                        local search = blacklistSearch:lower()
                        local visibleCount = 0

                        for i, bl in ipairs(
                            config.autopull.blacklist
                        ) do

                            local growid = tostring(
                                bl.growid or ""
                            )

                            local userid = tostring(
                                bl.userid or ""
                            )

                            local cleanGrowid = tostring(
                                cleanName(growid) or ""
                            )

                            -- Normalisasi search
                            local searchLower = search:lower()
                            local growidLower = growid:lower()
                            local cleanGrowidLower = cleanGrowid:lower()

                            -- Search GrowID asli, hasil cleanName, atau UserID
                            local matches =
                                searchLower == "" or
                                growidLower:find(
                                    searchLower,
                                    1,
                                    true
                                ) ~= nil or
                                cleanGrowidLower:find(
                                    searchLower,
                                    1,
                                    true
                                ) ~= nil or
                                userid:find(
                                    searchLower,
                                    1,
                                    true
                                ) ~= nil

                            if matches then

                                visibleCount = visibleCount + 1

                                ImGui.Text(
                                    cleanName(growid)
                                )

                                ImGui.SameLine()

                                ImGui.TextDisabled(
                                    "#" .. userid
                                )

                                ImGui.SameLine()

                                if ImGui.Button(
                                    "Remove##blacklist_" .. i
                                ) then

                                    removeIndex = i

                                end

                            end
                        end

                        -- Remove setelah loop selesai
                        if removeIndex then

                            local removed =
                                table.remove(
                                    config.autopull.blacklist,
                                    removeIndex
                                )

                            saveConfig()

                            if removed then

                                log(
                                    "`2Removed `9" ..
                                    cleanName(
                                        removed.growid
                                    ) ..
                                    " `9from blacklist"
                                )

                            end
                        end

                        -- Empty state
                        if #config.autopull.blacklist == 0 then

                            ImGui.TextDisabled(
                                "Blacklist is empty"
                            )

                        elseif visibleCount == 0 then

                            ImGui.TextDisabled(
                                "No users found"
                            )

                        end

                        ImGui.EndChild()

                    end

                    ImGui.EndTabItem()

                end


                -- =================================================
                -- MANUAL
                -- =================================================

                if ImGui.BeginTabItem(
                    "Manual"
                ) then

                    drawSection(
                        "ADD TO BLACKLIST MANUALLY"
                    )

                    local uidChanged,
                    newUid =
                        ImGui.InputInt(
                            "User ID",
                            tempManualUid
                        )

                    if uidChanged then
                        tempManualUid =
                            newUid
                    end


                    local nameChanged,
                    newName =
                        ImGui.InputText(
                            "Label",
                            tempManualLabel,
                            64
                        )

                    if nameChanged then
                        tempManualLabel =
                            newName
                    end


                    if ImGui.Button(
                        "Add To Blacklist",
                        ImVec2(140, 0)
                    ) then

                        if tempManualUid > 0 then

                            if isPlayerBlacklisted(
                                tempManualUid
                            ) then

                                log(
                                    "`6Player already exists in blacklist"
                                )

                            else

                                table.insert(
                                    config.autopull.blacklist,
                                    {
                                        userid =
                                            tempManualUid,

                                        growid =
                                            tempManualLabel ~= ""
                                            and tempManualLabel
                                            or tostring(
                                                tempManualUid
                                            )
                                    }
                                )

                                saveConfig()

                                log(
                                    "`2Successfully `9Added `c#" ..
                                    tostring(
                                        tempManualUid
                                    ) ..
                                    " `9to blacklist"
                                )

                                tempManualUid = 0
                                tempManualLabel = ""
                            end
                        end
                    end

                    ImGui.EndTabItem()
                end


                ImGui.EndTabBar()
            end

            ImGui.EndTabItem()
        end


        -- =====================================================
        -- FEATURES
        -- =====================================================

        if ImGui.BeginTabItem(
            "Features"
        ) then

            if ImGui.BeginTabBar(
                "FeatureTabs"
            ) then


                -- =================================================
                -- OPTIONS
                -- =================================================

                if ImGui.BeginTabItem(
                    "Options"
                ) then

                    drawSection(
                        "OPTIONS"
                    )


                    -- =============================================
                    -- SEARCH
                    -- =============================================

                    ImGui.SetNextItemWidth(-1)

                    local optionSearchChanged,
                    optionSearchValue =
                        ImGui.InputTextWithHint(
                            "##FeatureOptionsSearch",
                            "Search option...",
                            optionsSearch or "",
                            128
                        )

                    if optionSearchChanged then
                        optionsSearch = optionSearchValue
                    end


                    local search =
                        tostring(
                            optionsSearch or ""
                        ):lower()


                    ImGui.Spacing()


                    -- =============================================
                    -- HELPERS
                    -- =============================================

                    local function optionMatches(
                        label,
                        keywords
                    )

                        if search == "" then
                            return true
                        end

                        local text =
                            tostring(
                                label or ""
                            ):lower()

                        if text:find(
                            search,
                            1,
                            true
                        ) then
                            return true
                        end

                        if keywords then

                            for _, keyword
                                in ipairs(keywords)
                            do

                                if tostring(
                                    keyword
                                ):lower():find(
                                    search,
                                    1,
                                    true
                                ) then

                                    return true
                                end

                            end
                        end

                        return false
                    end


                    local function drawOption(
                        label,
                        tbl,
                        key,
                        keywords
                    )

                        if not optionMatches(
                            label,
                            keywords
                        ) then

                            return false
                        end

                        local changed,
                        value =
                            ImGui.Checkbox(
                                label,
                                bool(
                                    tbl[key]
                                )
                            )

                        if changed then

                            setBool(
                                tbl,
                                key,
                                value
                            )
                        end

                        return true
                    end


                    local function drawOptionSection(
                        title,
                        options
                    )

                        local visible = false

                        for _, option
                            in ipairs(options)
                        do

                            if optionMatches(
                                option.label,
                                option.keywords
                            ) then

                                visible = true
                                break

                            end
                        end

                        if not visible then
                            return
                        end

                        ImGui.TextColored(
                            COLOR_BLUE,
                            title
                        )

                        for _, option
                            in ipairs(options)
                        do

                            drawOption(
                                option.label,
                                option.tbl,
                                option.key,
                                option.keywords
                            )

                        end

                        ImGui.Spacing()

                    end


                    -- =============================================
                    -- OPTION DATA
                    -- =============================================

                    local optionGroups = {

                        {
                            title = "WRENCH",

                            options = {

                                {
                                    label = "Pull",
                                    tbl = config.wrench,
                                    key = "wrp",
                                    keywords = {
                                        "wrench",
                                        "pull",
                                        "wrp"
                                    }
                                },

                                {
                                    label = "Pull By Clicking Body",
                                    tbl = config.wrench,
                                    key = "pBody",
                                    keywords = {
                                        "wrench",
                                        "pull",
                                        "body",
                                        "click",
                                        "pbody"
                                    }
                                },

                                {
                                    label = "Show Player Balance",
                                    tbl = config.wrench,
                                    key = "smodal",
                                    keywords = {
                                        "wrench",
                                        "player",
                                        "balance",
                                        "info",
                                        "smodal"
                                    }
                                }

                            }
                        },


                        {
                            title = "ROULETTE",

                            options = {

                                {
                                    label = "Short Spin",
                                    tbl = config.wheel,
                                    key = "sspin",
                                    keywords = {
                                        "roulette",
                                        "spin",
                                        "short",
                                        "sspin"
                                    }
                                },

                                {
                                    label = "Show Last Spin On Player",
                                    tbl = config.wheel,
                                    key = "lastspin",
                                    keywords = {
                                        "roulette",
                                        "spin",
                                        "last",
                                        "player",
                                        "lastspin"
                                    }
                                }

                            }
                        },


                        {
                            title = "PLAYER / AUTO PULL",

                            options = {

                                {
                                    label = "Pull Tile Hotkey",
                                    tbl = config.pt,
                                    key = "hotkey",
                                    keywords = {
                                        "player",
                                        "pull",
                                        "tile",
                                        "hotkey",
                                        "pt",
                                        "pthk"
                                    }
                                },

                                {
                                    label = "Last Pull Hotkey",
                                    tbl = config.lp,
                                    key = "hotkey",
                                    keywords = {
                                        "player",
                                        "last",
                                        "pull",
                                        "hotkey",
                                        "lp",
                                        "lphk"
                                    }
                                },

                                {
                                    label = "Auto Pull Notification",
                                    tbl = config.autopull,
                                    key = "notify",
                                    keywords = {
                                        "auto",
                                        "pull",
                                        "notification",
                                        "notify"
                                    }
                                }

                            }
                        },


                        {
                            title = "TELEPHONE / CURRENCY",

                            options = {

                                {
                                    label = "Fast BGL Convert",
                                    tbl = config.telephone,
                                    key = "fastcv",
                                    keywords = {
                                        "telephone",
                                        "fast",
                                        "convert",
                                        "bgl",
                                        "fastcv"
                                    }
                                },

                                {
                                    label = "Convert Diamond Lock",
                                    tbl = config.currency,
                                    key = "cvdl",
                                    keywords = {
                                        "currency",
                                        "convert",
                                        "diamond",
                                        "dl",
                                        "cvdl"
                                    }
                                },

                                {
                                    label = "Convert Blue Gem Lock",
                                    tbl = config.currency,
                                    key = "cvbgl",
                                    keywords = {
                                        "currency",
                                        "convert",
                                        "blue",
                                        "gem",
                                        "bgl",
                                        "cvbgl"
                                    }
                                },

                                {
                                    label = "Convert Black Gem Lock",
                                    tbl = config.currency,
                                    key = "cvblack",
                                    keywords = {
                                        "currency",
                                        "convert",
                                        "black",
                                        "gem",
                                        "lock",
                                        "cvblack"
                                    }
                                }

                            }
                        },


                        {
                            title = "ANDROID / OTHER",

                            options = {

                                {
                                    label = "TP Display Box",
                                    tbl = config.andro,
                                    key = "tp",
                                    keywords = {
                                        "android",
                                        "teleport",
                                        "tp",
                                        "display",
                                        "box"
                                    }
                                },

                                {
                                    label = "Hide Champagne",
                                    tbl = config.others,
                                    key = "hidechamp",
                                    keywords = {
                                        "other",
                                        "champagne",
                                        "hide",
                                        "hidechamp"
                                    }
                                }

                            }
                        },


                        {
                            title = "PATH / MESSAGE",

                            options = {

                                {
                                    label = "Find Path",
                                    tbl = config.others,
                                    key = "findpath",
                                    keywords = {
                                        "path",
                                        "find",
                                        "findpath"
                                    }
                                },

                                {
                                    label = "Find Path 2",
                                    tbl = config.others,
                                    key = "findpath2",
                                    keywords = {
                                        "path",
                                        "find",
                                        "findpath2"
                                    }
                                },

                                {
                                    label = "Collect Message",
                                    tbl = config.others,
                                    key = "collectMsg",
                                    keywords = {
                                        "message",
                                        "collect",
                                        "collectmsg"
                                    }
                                },

                                {
                                    label = "Drop Message",
                                    tbl = config.others,
                                    key = "dropMsg",
                                    keywords = {
                                        "message",
                                        "drop",
                                        "dropmsg"
                                    }
                                },

                                {
                                    label = "Calculate Message",
                                    tbl = config.others,
                                    key = "calcMsg",
                                    keywords = {
                                        "message",
                                        "calculate",
                                        "calc",
                                        "calcmsg"
                                    }
                                }

                            }
                        }

                    }


                    -- =============================================
                    -- OPTIONS SCROLL
                    -- =============================================

                    if ImGui.BeginChild(
                        "FeatureOptionsScroll",
                        ImVec2(0, 0),
                        false
                    ) then

                        local anyResult = false

                        for _, group
                            in ipairs(optionGroups)
                        do

                            local groupVisible = false

                            for _, option
                                in ipairs(group.options)
                            do

                                if optionMatches(
                                    option.label,
                                    option.keywords
                                ) then

                                    groupVisible = true
                                    anyResult = true
                                    break

                                end
                            end


                            if groupVisible then

                                drawOptionSection(
                                    group.title,
                                    group.options
                                )

                            end

                        end


                        -- =============================================
                        -- NO SEARCH RESULT
                        -- =============================================

                        if search ~= ""
                            and not anyResult
                        then

                            ImGui.TextDisabled(
                                "No options found for \"" ..
                                tostring(
                                    optionsSearch
                                ) ..
                                "\""
                            )

                        end


                        ImGui.EndChild()

                    end

                    ImGui.EndTabItem()
                end


                -- =================================================
                -- WRENCH
                -- =================================================

                if ImGui.BeginTabItem(
                    "Wrench"
                ) then

                    drawSection(
                        "WRENCH SETTINGS"
                    )

                    local changed,
                    value =
                        ImGui.Checkbox(
                            "Show Player Balance",
                            bool(
                                config.wrench.smodal
                            )
                        )

                    if changed then

                        setBool(
                            config.wrench,
                            "smodal",
                            value
                        )
                    end


                    local bodyChanged,
                    bodyValue =
                        ImGui.Checkbox(
                            "Pull By Clicking Body",
                            bool(
                                config.wrench.pBody
                            )
                        )

                    if bodyChanged then

                        setBool(
                            config.wrench,
                            "pBody",
                            bodyValue
                        )
                    end


                    ImGui.Spacing()

                    ImGui.TextColored(
                        COLOR_BLUE,
                        "MODE"
                    )


                    if ImGui.RadioButton(
                        "Off",
                        getWrenchMode() == "OFF"
                    ) then

                        config.wrench.wrp = 0
                        config.wrench.wrk = 0
                        config.wrench.wrb = 0

                        saveConfig()
                    end

                    ImGui.SameLine()


                    if ImGui.RadioButton(
                        "Pull",
                        config.wrench.wrp == 1
                    ) then

                        config.wrench.wrp = 1
                        config.wrench.wrk = 0
                        config.wrench.wrb = 0

                        saveConfig()
                    end

                    ImGui.SameLine()


                    if ImGui.RadioButton(
                        "Kick",
                        config.wrench.wrk == 1
                    ) then

                        config.wrench.wrp = 0
                        config.wrench.wrk = 1
                        config.wrench.wrb = 0

                        saveConfig()
                    end

                    ImGui.SameLine()


                    if ImGui.RadioButton(
                        "Ban",
                        config.wrench.wrb == 1
                    ) then

                        config.wrench.wrp = 0
                        config.wrench.wrk = 0
                        config.wrench.wrb = 1

                        saveConfig()
                    end


                    ImGui.Separator()


                    local pChanged,
                    pText =
                        ImGui.InputText(
                            "Pull Text",
                            config.wrench.pText,
                            128
                        )

                    if pChanged then

                        config.wrench.pText =
                            pText

                        saveConfig()
                    end


                    local kChanged,
                    kText =
                        ImGui.InputText(
                            "Kick Text",
                            config.wrench.kText,
                            128
                        )

                    if kChanged then

                        config.wrench.kText =
                            kText

                        saveConfig()
                    end


                    local bChanged,
                    bText =
                        ImGui.InputText(
                            "Ban Text",
                            config.wrench.bText,
                            128
                        )

                    if bChanged then

                        config.wrench.bText =
                            bText

                        saveConfig()
                    end

                    ImGui.EndTabItem()
                end


                -- =================================================
                -- ROULETTE
                -- =================================================

                if ImGui.BeginTabItem(
                    "Roulette"
                ) then

                    drawSection(
                        "ROULETTE MODE"
                    )


                    if ImGui.RadioButton(
                        "Reme",
                        config.wheel.reme == 1
                    ) then

                        config.wheel.reme = 1
                        config.wheel.leme = 0
                        config.wheel.qeme = 0

                        saveConfig()
                    end

                    ImGui.SameLine()


                    if ImGui.RadioButton(
                        "Leme",
                        config.wheel.leme == 1
                    ) then

                        config.wheel.reme = 0
                        config.wheel.leme = 1
                        config.wheel.qeme = 0

                        saveConfig()
                    end

                    ImGui.SameLine()


                    if ImGui.RadioButton(
                        "Qeme",
                        config.wheel.qeme == 1
                    ) then

                        config.wheel.reme = 0
                        config.wheel.leme = 0
                        config.wheel.qeme = 1

                        saveConfig()
                    end


                    ImGui.Separator()


                    local shortChanged,
                    shortValue =
                        ImGui.Checkbox(
                            "Short Spin",
                            bool(
                                config.wheel.sspin
                            )
                        )

                    if shortChanged then

                        setBool(
                            config.wheel,
                            "sspin",
                            shortValue
                        )
                    end


                    local lastChanged,
                    lastValue =
                        ImGui.Checkbox(
                            "Show Last Spin On Player",
                            bool(
                                config.wheel.lastspin
                            )
                        )

                    if lastChanged then

                        if not lastValue then

                            for _, player
                                in pairs(
                                    GetPlayerList()
                                )
                            do

                                remove_spin_title(
                                    player.netid
                                )

                            end

                        end

                        setBool(
                            config.wheel,
                            "lastspin",
                            lastValue
                        )
                    end


                    ImGui.Spacing()

                    ImGui.Text(
                        "Current Mode:"
                    )

                    ImGui.SameLine()


                    local mode =
                        getRouletteMode()

                    if mode == "OFF" then

                        ImGui.TextColored(
                            COLOR_GRAY,
                            mode
                        )

                    else

                        ImGui.TextColored(
                            COLOR_YELLOW,
                            mode
                        )

                    end

                    ImGui.EndTabItem()
                end


                -- =================================================
                -- SPAM
                -- =================================================

                if ImGui.BeginTabItem(
                    "Spam"
                ) then

                    drawSection(
                        "SPAM SETTINGS"
                    )


                    local textChanged,
                    spamText =
                        ImGui.InputText(
                            "Spam Text",
                            config.spam.text,
                            256
                        )

                    if textChanged then

                        config.spam.text =
                            spamText

                        saveConfig()
                    end


                    local delayChanged,
                    delay =
                        ImGui.InputInt(
                            "Delay (ms)",
                            config.spam.delay
                        )

                    if delayChanged then

                        if delay < 100 then
                            delay = 100
                        end

                        config.spam.delay =
                            delay

                        saveConfig()
                    end


                    ImGui.TextDisabled(
                        "1000 ms = 1 second"
                    )

                    ImGui.Spacing()


                    if ImGui.Button(
                        config.spam.status == 1
                            and "Stop Spam"
                            or "Start Spam",
                        ImVec2(130, 0)
                    ) then

                        controller.startspam()
                    end

                    ImGui.SameLine()

                    statusText(
                        config.spam.status == 1
                    )

                    ImGui.EndTabItem()
                end


                ImGui.EndTabBar()
            end

            ImGui.EndTabItem()
        end

        -- =====================================================
        -- WORLD
        -- =====================================================

        if ImGui.BeginTabItem(
            "World"
        ) then

            if ImGui.BeginTabBar(
                "WorldTab"
            ) then

                -- =====================================================
                -- PLAYERS
                -- =====================================================

                if ImGui.BeginTabItem(
                    "Players"
                ) then

                    ImGui.TextColored(
                        COLOR_BLUE,
                        "PLAYERS IN CURRENT WORLD"
                    )

                    ImGui.TextDisabled(
                        "Pull, kick, ban, inspect, or add players to blacklist."
                    )

                    ImGui.Separator()


                    -- =============================================
                    -- SEARCH
                    -- =============================================

                    ImGui.SetNextItemWidth(-1)

                    local searchChanged, newSearch =
                        ImGui.InputTextWithHint(
                            "##PlayerSearch",
                            "Search player or UserID...",
                            playerSearch,
                            100
                        )

                    if searchChanged then
                        playerSearch = newSearch
                    end


                    ImGui.Spacing()


                    -- =============================================
                    -- PLAYER LIST
                    -- =============================================

                    if ImGui.BeginChild(
                        "PlayerActionScroll",
                        ImVec2(0, 0),
                        true
                    ) then

                        local players =
                            GetPlayerList()

                        local localPlayer =
                            GetLocal()

                        local playerCount = 0
                        local search = tostring(
                            playerSearch or ""
                        ):lower()


                        if players
                            and localPlayer
                        then

                            if ImGui.BeginTable(
                                "PlayerActionTable",
                                2,
                                true
                            ) then

                                ImGui.TableSetupColumn(
                                    "Player",
                                    ImVec2(0, 0)
                                )

                                ImGui.TableSetupColumn(
                                    "Actions",
                                    ImVec2(280, 0)
                                )

                                ImGui.TableHeadersRow()


                                -- =============================================
                                -- PLAYERS
                                -- =============================================

                                for _, player
                                    in pairs(players)
                                do

                                    if
                                        player
                                        and player.netid
                                        and player.name
                                        and player.netid
                                            ~= localPlayer.netid
                                    then

                                        local name =
                                            cleanName(
                                                tostring(
                                                    player.name
                                                )
                                            )

                                        local userid =
                                            tostring(
                                                player.userid or ""
                                            )


                                        -- =============================================
                                        -- SEARCH FILTER
                                        -- =============================================

                                        local nameLower =
                                            name:lower()

                                        local useridLower =
                                            userid:lower()

                                        local matches =
                                            search == ""
                                            or nameLower:find(
                                                search,
                                                1,
                                                true
                                            ) ~= nil
                                            or useridLower:find(
                                                search,
                                                1,
                                                true
                                            ) ~= nil


                                        if matches then

                                            if not name:find(
                                                "Spammer Slave",
                                                1,
                                                true
                                            ) then

                                                playerCount =
                                                    playerCount + 1


                                                ImGui.TableNextRow()


                                                -- =============================================
                                                -- PLAYER
                                                -- =============================================

                                                ImGui.TableSetColumnIndex(
                                                    0
                                                )

                                                ImGui.Text(
                                                    name
                                                )

                                                if player.userid then

                                                    ImGui.SameLine()

                                                    ImGui.TextDisabled(
                                                        "#" ..
                                                        userid
                                                    )

                                                end


                                                -- =============================================
                                                -- ACTIONS
                                                -- =============================================

                                                ImGui.TableSetColumnIndex(
                                                    1
                                                )


                                                -- PULL
                                                if ImGui.Button(
                                                    "Pull##" ..
                                                    player.netid,
                                                    ImVec2(42, 0)
                                                ) then

                                                    utils.wrenchAction(
                                                        "pull",
                                                        player.netid
                                                    )

                                                end

                                                ImGui.SameLine()


                                                -- KICK
                                                if ImGui.Button(
                                                    "Kick##" ..
                                                    player.netid,
                                                    ImVec2(42, 0)
                                                ) then

                                                    utils.wrenchAction(
                                                        "kick",
                                                        player.netid
                                                    )

                                                end

                                                ImGui.SameLine()


                                                -- BAN
                                                if ImGui.Button(
                                                    "Ban##" ..
                                                    player.netid,
                                                    ImVec2(42, 0)
                                                ) then

                                                    utils.wrenchAction(
                                                        "ban",
                                                        player.netid
                                                    )

                                                end

                                                ImGui.SameLine()


                                                -- INFO
                                                if ImGui.Button(
                                                    "Info##" ..
                                                    player.netid,
                                                    ImVec2(42, 0)
                                                ) then

                                                    utils.wrenchAction(
                                                        "smodal",
                                                        player.netid
                                                    )

                                                end

                                                ImGui.SameLine()


                                                -- =============================================
                                                -- BLACKLIST
                                                -- =============================================

                                                if player.userid then

                                                    if isPlayerBlacklisted(
                                                        player.userid
                                                    ) then

                                                        ImGui.TextColored(
                                                            COLOR_GREEN,
                                                            "Added"
                                                        )

                                                    else

                                                        if ImGui.Button(
                                                            "Blacklist##" ..
                                                            player.netid,
                                                            ImVec2(75, 0)
                                                        ) then

                                                            if addPlayerToBlacklist(
                                                                player
                                                            ) then

                                                                log(
                                                                    "`2Successfully `9Added `c" ..
                                                                    name ..
                                                                    " `9to blacklist"
                                                                )

                                                            end
                                                        end
                                                    end
                                                end

                                            end
                                        end
                                    end
                                end


                                ImGui.EndTable()

                            end


                            -- =============================================
                            -- EMPTY / NO SEARCH RESULT
                            -- =============================================

                            if playerCount == 0 then

                                if search ~= "" then

                                    ImGui.TextDisabled(
                                        "No players found for \"" ..
                                        playerSearch ..
                                        "\""
                                    )

                                else

                                    ImGui.TextDisabled(
                                        "No valid players found in this world"
                                    )

                                end
                            end

                        else

                            ImGui.TextDisabled(
                                "Unable to detect players"
                            )

                        end

                        ImGui.EndChild()

                    end

                    ImGui.EndTabItem()
                end


                

            ImGui.EndTabBar()
            end

            ImGui.EndTabItem()
        end

        -- =====================================================
        -- LOGS
        -- =====================================================

        if ImGui.BeginTabItem(
            "Logs"
        ) then

            if ImGui.BeginTabBar(
                "LogsTabs"
            ) then


                -- =================================================
                -- SPIN LOGS
                -- =================================================

                if ImGui.BeginTabItem(
                    "Spin Logs"
                ) then

                    if ImGui.Button(
                        "Clear Spin Logs"
                    ) then

                        logs.spin = {}

                        saveConfig()
                    end

                    ImGui.SameLine()

                    ImGui.TextDisabled(
                        tostring(
                            #logs.spin
                        ) ..
                        " entries"
                    )

                    ImGui.Separator()

                    if ImGui.BeginChild(
                        "MainSpinLog",
                        ImVec2(0, 0),
                        true
                    ) then

                        if #logs.spin == 0 then

                            ImGui.TextDisabled(
                                "No spin logs available"
                            )

                        else

                            for i =
                                #logs.spin,
                                1,
                                -1
                            do

                                local entry =
                                    logs.spin[i]

                                local time =
                                    os.date(
                                        "%Y/%m/%d %H:%M:%S",
                                        entry.timestamp
                                    )

                                ImGui.TextColored(
                                    COLOR_GRAY,
                                    "[" .. time .. "]"
                                )

                                ImGui.SameLine()

                                ImGui.Text(
                                    cleanName(
                                        entry.variant
                                    ) ..
                                    " in " ..
                                    tostring(
                                        entry.world
                                    )
                                )
                            end
                        end

                        ImGui.EndChild()
                    end

                    ImGui.EndTabItem()
                end


                -- =================================================
                -- COLLECT LOGS
                -- =================================================

                if ImGui.BeginTabItem(
                    "Collect Logs"
                ) then

                    if ImGui.Button(
                        "Clear Collect Logs"
                    ) then

                        logs.collect = {}
                    end

                    ImGui.SameLine()

                    ImGui.TextDisabled(
                        tostring(
                            #logs.collect
                        ) ..
                        " entries"
                    )

                    ImGui.Separator()

                    if ImGui.BeginChild(
                        "CollectLogScroll",
                        ImVec2(0, 0),
                        true
                    ) then

                        if #logs.collect == 0 then

                            ImGui.TextDisabled(
                                "No collect logs available"
                            )

                        else

                            for i =
                                #logs.collect,
                                1,
                                -1
                            do

                                local entry =
                                    logs.collect[i]

                                local time =
                                    os.date(
                                        "%Y/%m/%d %H:%M:%S",
                                        entry.timestamp
                                    )

                                ImGui.TextColored(
                                    COLOR_GRAY,
                                    "[" .. time .. "]"
                                )

                                ImGui.SameLine()

                                ImGui.Text(
                                    tostring(
                                        entry.count
                                    ) ..
                                    " " ..
                                    tostring(
                                        entry.lock
                                    ) ..
                                    " in " ..
                                    tostring(
                                        entry.world
                                    )
                                )
                            end
                        end

                        ImGui.EndChild()
                    end

                    ImGui.EndTabItem()
                end

                -- =================================================
                -- COMMANDS LOGS
                -- =================================================

                if ImGui.BeginTabItem(
                    "Commands Logs"
                ) then

                    if ImGui.Button(
                        "Clear Commands Logs"
                    ) then

                        logs.commands = {}
                    end

                    ImGui.SameLine()

                    ImGui.TextDisabled(
                        tostring(
                            #logs.commands
                        ) ..
                        " entries"
                    )

                    ImGui.Separator()

                    if ImGui.BeginChild(
                        "CommandsLogsScroll",
                        ImVec2(0, 0),
                        true
                    ) then

                        if #logs.commands == 0 then

                            ImGui.TextDisabled(
                                "No Commands logs available"
                            )

                        else

                            for i =
                                #logs.commands,
                                1,
                                -1
                            do

                                local entry =
                                    logs.commands[i]

                                local time =
                                    os.date(
                                        "%Y/%m/%d %H:%M:%S",
                                        entry.time
                                    )

                                ImGui.TextColored(
                                    COLOR_GRAY,
                                    "[" .. time .. "]"
                                )

                                ImGui.SameLine()

                                ImGui.Text(
                                    "Used " ..
                                    tostring(
                                        entry.cmd
                                    ) ..
                                    " in " ..
                                    tostring(
                                        entry.world
                                    )
                                )
                            end
                        end

                        ImGui.EndChild()
                    end

                    ImGui.EndTabItem()
                end


                -- =================================================
                -- MANAGE
                -- =================================================

                if ImGui.BeginTabItem(
                    "Manage"
                ) then

                    drawSection(
                        "LOG MANAGEMENT"
                    )

                    ImGui.Text(
                        "Spin Logs: " ..
                        tostring(
                            #logs.spin
                        )
                    )

                    ImGui.Text(
                        "Collect Logs: " ..
                        tostring(
                            #logs.collect
                        )
                    )

                    ImGui.Text(
                        "Commands Logs: " ..
                        tostring(
                            #logs.commands
                        )
                    )

                    ImGui.Spacing()

                    if ImGui.Button(
                        "Clear All Logs"
                    ) then

                        logs.spin = {}
                        logs.collect = {}
                        logs.commands = {}

                        log(
                            "`2Successfully `9Cleared All Logs"
                        )
                    end

                    ImGui.EndTabItem()
                end


                ImGui.EndTabBar()
            end

            ImGui.EndTabItem()
        end


        -- =====================================================
        -- MORE
        -- =====================================================

        if ImGui.BeginTabItem(
            "More"
        ) then

            if ImGui.BeginTabBar(
                "MoreTabs"
            ) then


                -- =================================================
                -- COMMANDS
                -- =================================================

                if ImGui.BeginTabItem(
                    "Commands"
                ) then

                    drawCommands()

                    ImGui.EndTabItem()
                end


                -- =================================================
                -- USERS
                -- =================================================

                if ImGui.BeginTabItem(
                    "Users"
                ) then

                    if ImGui.BeginChild(
                        "UsersScroll",
                        ImVec2(0, 0),
                        true
                    ) then

                        local count = 0

                        for uid, data
                            in pairs(proxyUser)
                        do

                            local nick,
                            role,
                            worker =
                                tostring(
                                    data
                                ):match(
                                    "(.-)/(.-)/(.+)"
                                )

                            ImGui.Text(
                                tostring(
                                    nick
                                    or "Unknown"
                                )
                            )

                            ImGui.SameLine()

                            ImGui.TextDisabled(
                                "#" ..
                                tostring(uid)
                            )

                            ImGui.SameLine()

                            ImGui.TextColored(
                                COLOR_BLUE,
                                tostring(
                                    role
                                    or "-"
                                )
                            )

                            count =
                                count + 1
                        end


                        if count == 0 then

                            ImGui.TextDisabled(
                                "No users available"
                            )
                        end

                        ImGui.EndChild()
                    end

                    ImGui.EndTabItem()
                end


                -- =================================================
                -- INFO
                -- =================================================

                if ImGui.BeginTabItem(
                    "Info"
                ) then

                    ImGui.TextColored(
                        COLOR_BLUE,
                        "IMMORTAL PROXY"
                    )

                    ImGui.TextDisabled(
                        "Version " .. ver
                    )

                    ImGui.Separator()

                    ImGui.TextColored(
                        COLOR_YELLOW,
                        "HOTKEYS"
                    )

                    ImGui.Text(
                        "F1 / Clash = Pull Tile"
                    )

                    ImGui.Text(
                        "F5 / Dungeon = Last Pull"
                    )

                    ImGui.Text(
                        "Shift + Click = FindPath / TP"
                    )

                    ImGui.Text(
                        "Ctrl + Click = FindPath + Back"
                    )

                    ImGui.Spacing()

                    ImGui.Separator()

                    ImGui.Text(
                        "Blacklist: " ..
                        tostring(
                            #config.autopull.blacklist
                        )
                    )

                    ImGui.Text(
                        "Spin Logs: " ..
                        tostring(
                            #logs.spin
                        )
                    )

                    ImGui.Text(
                        "Collect Logs: " ..
                        tostring(
                            #logs.collect
                        )
                    )

                    ImGui.EndTabItem()
                end


                ImGui.EndTabBar()
            end

            ImGui.EndTabItem()
        end


        ImGui.EndTabBar()
    end

    ImGui.End()
end

function controller.imgui()
    toggle(config.others, "imgui", false)

    RunThread(function()
        Sleep(100)

        if config.others.imgui == 1 then
            AddHook("OnDraw", "imgui", imgui)
        else
            RemoveHook("imgui")
        end
    end)
end

local function remeNumber(number)
    local number = tonumber(number)
    if not number then return "", "" end

    local num1 = math.floor(number / 10)
    local num2 = number % 10
    local sum = num1 + num2
    local result = tostring(sum):sub(-1)

    return tonumber(result)
end

local function qemeNumber(number)
    local number = tonumber(number)
    if number == 0 then
        number = 1
    end
    if not number then return "", "" end
    
    local result = (number >= 10) and tostring(number):sub(-1) or tostring(number)
    
    return tonumber(result)
end

local function rules(game, number)
    if not number or not game then
        return
    end

    local number = tonumber(number)

    if game == "reme" then

        local number = remeNumber(number)

        local color = {
            [0] = "`2",
            [1] = "`4",
            [2] = "`4",
            [3] = "`8",
            [4] = "`8",
            [5] = "`6",
            [6] = "`6",
            [7] = "`9",
            [8] = "`9",
            [9] = "`2",
        }

        if number == 0 then
            return "`^REME " .. color[number] .. number .. "`0[`2X3`0]"
        else
            return "`^REME " .. color[number] .. number
        end
    end

    if game == "leme" then

        local number = remeNumber(number)


        local color = {
            [0] = "`2",
            [1] = "`2",
            [2] = "`4",
            [3] = "`8",
            [4] = "`8",
            [5] = "`6",
            [6] = "`6",
            [7] = "`9",
            [8] = "`9",
            [9] = "`4",
        }

        if number == 0 then
            return "`5LEME " .. color[number] .. number .. "`0[`2X4`0]"
        elseif number == 1 then
            return "`5LEME " .. color[number] .. number .. "`0[`2X3`0]"
        elseif number == 9 then
            return "`5LEME " .. color[number] .. number .. "`0[`4Player Lose`0]"
        else
            return "`5LEME " .. color[number] .. number
        end
    end

    if game == "qeme" then

        local number = qemeNumber(number)

        local color = {
            [0] = "`2",
            [1] = "`4",
            [2] = "`4",
            [3] = "`8",
            [4] = "`8",
            [5] = "`6",
            [6] = "`6",
            [7] = "`9",
            [8] = "`9",
            [9] = "`2",
        }

        if number == 0 then
            return "`cQEME " .. color[number] .. number .. "`0[`2X3`0]"
        else
            return "`cQEME " .. color[number] .. number
        end
    end
end

local waitedPull
local sendingPull
local startAutoPull = 0

local function autopull(var)
    if var[0] == "OnSpawn" then
        -- 1. Micro-Optimization: Parsing regex sekaligus dalam 1 kali match
        local str = var[1]
        local netid_str, uid_str, px, py = str:match("netID|(%d+).+userID|(%d+).+posXY|(%d+)|(%d+)")
        
        if not netid_str then return end -- Guard clause jika packet tidak lengkap

        local netid = tonumber(netid_str)
        local uid = tonumber(uid_str)

        -- Bit shift >> 5 sama dengan math.floor(x / 32), jauh lebih cepat di Lua
        local x = tonumber(px) >> 5
        local y = tonumber(py) >> 5

        RunThread(function()
            if isProxyUser(uid) then
                set_player_rank(tonumber(netid), "`9[`4P`9]")
            end
        end)

        if var[1]:find("type|local", 1, true) then
            clearCache()
            RunThread(function()
                log("`9Getting Lock & Champagne Data...")
                Sleep(1000)
                local total = GetItemCount(242)/100 + GetItemCount(1796) + GetItemCount(7188)*100 + GetItemCount(11550)*10000
                log("`1Diamond Lock `9On Backpack: `c" .. (total or 0))
                log("`rChampagne `9On Backpack: `c" .. (GetItemCount(const.itemId.champagne) or 0))
            end)

            return
        end

        if config.autopull.status == 1 and x == config.autopull.tile.x and y == config.autopull.tile.y and not isBlacklist(uid) then
            RunThread(function()
                local currentConfig = config.wrench.smodal

                startAutoPull = os.clock()
                config.wrench.smodal = 1
                cache.autopull.dlPulled = nil -- Dynamic state indicator

                SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netid .. "|\nbuttonClicked|viewinv")

                -- Dynamic Delay Loop (Max 250ms with 10ms check intervals)
                waitedPull = 0

                while (waitedPull < config.autopull.minDelay) or (cache.autopull.dlPulled == nil and waitedPull < config.autopull.maxDelay) do
                    Sleep(5)
                    waitedPull = waitedPull + 5
                end

                config.wrench.smodal = currentConfig

                local dlAmount = cache.autopull.dlPulled or 0
                
                if dlAmount >= config.autopull.minimum then
                    -- Sleep(50)
                    log("`2[" .. math.floor((os.clock() - startAutoPull) * 1000) .. "ms] ``" .. (GetPlayer(netid).name or "Unknown") .. " `1DL: `c" .. dlAmount .. " `2[>=Minimum] `9Trying To `5Pull")
                    utils.wrenchAction("pull", netid)
                    -- Sleep(10)
                    sendingPull = true
                else
                    log("`2[" .. math.floor((os.clock() - startAutoPull) * 1000) .. "ms] ``" .. (GetPlayer(netid).name or "Unknown") .. " `1DL: `c" .. dlAmount .. " `4[<Mnimum]")
                end
                saveConfig()
            end)
        end
    end
end

local function VariantHook(var, nid, delay)

    if var[0] == "OnDialogRequest" and var[1]:find("end_dialog|storage|", 1, true) and config.others.fastStorage then
        local dialogText = var[1]

        -- Cek jika dialog berasal dari storage
        storageItems = {} -- Clear cache setiap kali dialog storage baru terbuka

            -- Pattern matching sesuai format: add_button_with_icon|item_hash|item name|frame|item id|item count|
        for hash, name, itemId, count in string.gmatch(dialogText, "add_button_with_icon|item_(%d+)|([^|]+)|.-|(%d+)|(%d+)|") do
            storageItems[hash] = {
                name = name,
                id = tonumber(itemId),
                count = tonumber(count)
            }
        end
    end

    if var[0] == "OnSetClothing" then
        local netid = nid

        local p1 = var[1]
        local p2 = var[2]
        local p3 = var[3]
        local p4 = var[4]
        local p5 = var[5]

        if isClothesHide(p1.x) then p1.x = 0 end
        if isClothesHide(p1.y) then p1.y = 0 end
        if isClothesHide(p1.z) then p1.z = 0 end

        if isClothesHide(p2.x) then p2.x = 0 end
        if isClothesHide(p2.y) then p2.y = 0 end
        if isClothesHide(p2.z) then p2.z = 0 end

        if isClothesHide(p3.x) then p3.x = 0 end
        if isClothesHide(p3.y) then p3.y = 0 end
        if isClothesHide(p3.z) then p3.z = 0 end

        if isClothesHide(p5.x) then p5.x = 0 end
        if isClothesHide(p5.y) then p5.y = 0 end
        if isClothesHide(p5.z) then p5.z = 0 end

        SendVariantList({
            [0] = "OnSetClothing",
            [1] = { x = p1.x, y = p1.y, z = p1.z },
            [2] = { x = p2.x, y = p2.y, z = p2.z },
            [3] = { x = p3.x, y = p3.y, z = p3.z },
            [4] = p4,
            [5] = { x = p5.x, y = p5.y, z = p5.z },
        }, netid)

        return true
    end

    if var[0] == "OnConsoleMessage" and var[1]:find("`4Spam detected!", 1, true) and nid == -1 then
        return true
    end

    if var[0] == "OnConsoleMessage" and cache.others.pinging then
        if var[1]:find("Ping: ", 1, true) then
            cache.others.pinging = false
            local current = var[1]:match("Ping:%s*(.-)%s*%(")
            local avg = var[1]:match("avg:%s*(.-)%)")
            local packetLoss = var[1]:match("%[Packet Loss:%s*(.-)%]")

            -- Menggunakan nilai default "N/A" jika match gagal/nil
            current = current or "`4N/A"
            avg = avg or "`4N/A"
            packetLoss = packetLoss or "`4N/A"

            log("`9PING: " .. current)
            log("`9AVG: " .. avg)
            log("`9PACKET LOSS: " .. packetLoss)

            return true
        end
        if var[1]:find("anomalizing", 1, true) then
            return true
        end

        if var[1]:find("`2CreativePS Time:", 1, true) then
            return true
        end

        if var[1]:find("Uptime: ", 1, true) then
            return true
        end

        if var[1]:find("`2The Carnival", 1, true) then
            return true
        end

        if var[1]:find("Today is", 1, true) then
            return true
        end
    end

    if var[0] == "OnConsoleMessage" and var[1]:find("'s Spammer Slave. (", 1, true) and config.others.hideslave == 1 then
    
        return true
    end


    if var[0] == "OnAction" and var[1] == "/cheer" and config.others.hidechamp == 1 and nid == GetLocal().netid then
        log("`2Successfully `9Blocked Using Champ Animation(/cheer)")

        return true
    end

    if var[0] == "OnConsoleMessage" and var[1]:find("`5pulls", 1, true) and config.autopull.status == 1 and sendingPull then
        local myName = GetLocal().name:gsub("`9%[`4P`9%]%s", ""):gsub("`.", ""):gsub("%s%((%d+)%)", ""):gsub("%s%[(.-)%]", ""):gsub("%s%[(.-)%]%s", "")
        local myNameInSystem = var[1]:gsub("`.", ""):gsub("`9%[`4P`9%]%s", ""):gsub("`.", ""):gsub("%s%((%d+)%)", ""):gsub("%s%[(.-)%]", ""):gsub("%s%[(.-)%]%s", ""):match(myName)

        if myName == myNameInSystem then
            RunThread(function()

                log("`2Successfully `9Pulled Player In `2" .. (waitedPull ~= nil and math.floor((os.clock() - startAutoPull) * 1000) or "0") .. "ms")

                config.autopull.status = 0
                sendingPull = false
                saveConfig()

                log("`9Auto Pull Set To " .. (config.autopull.status == "1" and "`2ON" or "`4OFF") .. " `8[Avoid Double Pull]")

                if config.autopull.notify == 1 then
                    SendVariantList({
                        [0] = "OnPlayPositioned",
                        [1] = "audio/knock.wav"
                    }, GetLocal().netid)

                    Sleep(50)

                    SendVariantList({
                        [0] = "OnPlayPositioned",
                        [1] = "audio/achievement.wav"
                    }, GetLocal().netid)
                end
            end)
        end
    end



    if var[0] == "OnSDBroadcast" and config.others.bsdb == 1 then
        log("`2Successfully `9Blocked Super Duper Broadcast")
        return true
    end


    if var[0] == "OnDialogRequest" and var[1]:find("end_dialog|telephone|Hang Up|Dial|") and config.telephone.fastcv == 1 then
        local x = var[1]:match("embed_data|x|(%d+)")
        local y = var[1]:match("embed_data|y|(%d+)")

        SendPacket(2, "action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|" .. x .. "|\ny|" .. y .. "|\nbuttonClicked|bglconvert")
        
        return true
    end

    if var[0] == "OnDialogRequest" and var[1]:find("embed_data|num|53785") and config.telephone.fastcv == 1 then
        return true
    end


    if var[0] == "OnDialogRequest" and var[1]:find("embed_data|netID|") then

        local targetNetid =
            tonumber(
                var[1]:match(
                    "embed_data|netID|(%d+)"
                )
            )

        if targetNetid == GetLocal().netid then
            return false
        end

        if
            config.wrench.wrp == 1
            or
            config.wrench.wrk == 1
            or
            config.wrench.wrb == 1
            or
            config.wrench.smodal == 1
        then
            return true
        end

    end

    if var[0] == "OnDialogRequest" and var[1]:find("embed_data|userID", 1, true) and config.wrench.smodal == 1 then

        local wl =
            tonumber(
                var[1]:match(
                    "staticframe|" ..
                    const.itemId.wl ..
                    "|(%d+)|"
                )
            ) or 0

        local dl =
            tonumber(
                var[1]:match(
                    "staticframe|" ..
                    const.itemId.dl ..
                    "|(%d+)|"
                )
            ) or 0

        local bglInven =
            tonumber(
                var[1]:match(
                    "staticframe|" ..
                    const.itemId.bgl ..
                    "|(%d+)|"
                )
            ) or 0

        local bglBank =
            tonumber(
                var[1]:match(
                    "Blue Gem Locks in the Bank: `$(%d+)``"
                )
            ) or 0

        local totalBgl =
            bglInven +
            bglBank

        local black =
            tonumber(
                var[1]:match(
                    "staticframe|" ..
                    const.itemId.black ..
                    "|(%d+)|"
                )
            ) or 0

        local champ =
            tonumber(
                var[1]:match(
                    "staticframe|" ..
                    const.itemId.champagne ..
                    "|(%d+)|"
                )
            ) or 0

        local cc =
            tonumber(
                var[1]:match(
                    "staticframe|" ..
                    const.itemId.cc ..
                    "|(%d+)|"
                )
            ) or 0

        local name =
            var[1]:match(
                "big|(.+)'s Inventory``"
            )
            or
            "Unknown"

        local total =
            wl +
            (dl * 100) +
            (totalBgl * 10000) +
            (black * 1000000)

        

        cache.autopull.dlPulled = total/100



        local locks =
            utils.convertLocksCount(total)


        if locks.wl == 0 and locks.dl == 0 and locks.bgl == 0 and locks.black == 0 then
            log(
                "`0MISKUY DIE (" .. name .. ") KGK ADA WL 1 PUN"
            )
            sendOverlay(
                "`0MISKUY DIE KGK ADA WL 1 PUN"
            )

        else

            log(
                "`0" .. name ..
                " `aBLACK: " ..
                locks.black ..
                " `eBGL: " ..
                locks.bgl ..
                " `1DL: " ..
                locks.dl ..
                " `9WL: " ..
                locks.wl ..
                " `rCHAMPAGNE: " ..
                champ ..
                (cc ~= 0 and ("`8 CC: " .. cc) or "")
            )

            sendOverlay(
                "`0" .. name ..
                " `aBLACK: " ..
                locks.black ..
                " `eBGL: " ..
                locks.bgl ..
                " `1DL: " ..
                locks.dl ..
                " `9WL: " ..
                locks.wl ..
                " `rCHAMPAGNE: " ..
                champ ..
                (cc ~= 0 and ("`8 CC: " .. cc) or "")
            )

        end

        return true

    end



    if var[0] == "OnTalkBubble" and var[2]:find("`9[`4IMMORTAL``] ``", 1, true) then
        local text = var[2]:gsub("`9%[`4IMMORTAL``%] ``", "")
        local decryptedText = utils.decrypt(text, 7221)

        SendVariantList({
            [0] = "OnTalkBubble",
            [1] = var[1],
            [2] = watermark .. decryptedText
        })

        return true
    end


    local fake = "`4[FAKE]"
    local real = "`2[REAL]"
    
    if var[0] == "OnTalkBubble" and var[2]:find("spun the wheel and got", 1, true) then
        local is_fake = var[2]:find("<", 1, true) and var[2]:find(">", 1, true)
        local prefix = is_fake and fake .. " " or real .. " "

        local bubble_netid = tonumber(var[1]) or -1

        if bubble_netid == -1 then
            return false
        end
        
        local num_str = var[2]:match("and got (.+)")
        
        if num_str then
            local num = string.gsub(string.gsub(num_str, "!%]", ""), "`", "")
            local onlynumber = string.sub(num, 2)
            local clearspace = string.gsub(onlynumber, " ", "")
            local h = string.gsub(string.gsub(clearspace, "!7", ""), "]", "")
            local num_parsed = tonumber(h)

            if not num_parsed then
                return false
            end

            local suffix = 
            (config.wheel.reme == 1 and rules("reme", num_parsed) or "") ..
            (config.wheel.leme == 1 and rules("leme", num_parsed) or "") ..
            (config.wheel.qeme == 1 and rules("qeme", num_parsed) or "")

            local mid = (config.wheel.sspin == 1 and num_str:gsub("``!]", "") or var[2])

            table.insert(logs.spin, {
                variant = var[2] .. " " .. suffix,
                timestamp = os.time(),
                world = GetWorld().name:upper()
            })

            if config.wheel.lastspin == 1 then
                apply_spin_title(tonumber(var[1]), num_str:gsub("``!]", ""))
            end
            


            if num_parsed then
                SendVariantList({
                    [0] = "OnTalkBubble",
                    [1] = var[1],
                    [2] = prefix .. mid .. " " .. suffix
                })
                return true
            end
        end

    end

    if var[0] == "OnConsoleMessage" and var[1]:find("spun the wheel and got", 1, true) then
        if var[1]:find("<", 1, true) or var[1]:find("<", 1, true) then
            return false
        end

        local num_str = var[1]:match("and got (.+)")
        
        if num_str then
            local num = string.gsub(string.gsub(num_str, "!%]", ""), "`", "")
            local onlynumber = string.sub(num, 2)
            local clearspace = string.gsub(onlynumber, " ", "")
            local h = string.gsub(string.gsub(clearspace, "!7", ""), "]", "")
            local num_parsed = tonumber(h)

            if not num_parsed then
                return false
            end

            local suffix = 
            (config.wheel.reme == 1 and rules("reme", num_parsed) or "") ..
            (config.wheel.leme == 1 and rules("leme", num_parsed) or "") ..
            (config.wheel.qeme == 1 and rules("qeme", num_parsed) or "")

            SendVariantList({
                [0] = "OnConsoleMessage",
                [1] = var[1] .. " " .. real .. " " .. suffix
            })
            return true
        end
    end



    -- Integrasi di dalam Hook Console Message
    if var[0] == "OnConsoleMessage" and var[1]:find("`oCollected", 1, true) and var[1]:find(" Lock", 1, true) then
        local count, lockName = var[1]:match("`w(%d+) (.-)``")
        count = tonumber(count) or 0

        -- 1. Hitung nilai WL dari lock yang diambil
        local itemValue = 0
        if lockName:find("World Lock", 1, true) then itemValue = count * 1
        elseif lockName:find("Diamond Lock", 1, true) then itemValue = count * 100
        elseif lockName:find("Blue Gem Lock", 1, true) then itemValue = count * 10000
        elseif lockName:find("Black Gem Lock", 1, true) then itemValue = count * 1000000
        end

        -- 2. Tambahkan ke Logs
        table.insert(logs.collect, {
            timestamp = os.time(),
            lock = lockName,
            count = count,
            world = GetWorld().name:upper()
        })

        -- 3. Akumulasi ke Buffer & Perbarui Timer
        collectQueue.totalValue = collectQueue.totalValue + itemValue
        collectQueue.lastTick = os.clock()

        -- 4. Thread Akumulasi & Chat System
        if not collectQueue.active then
            collectQueue.active = true

            RunThread(function()
                -- Menunggu seluruh item dari multi-tile selesai terambil (Debounce 120ms)
                while (os.clock() - collectQueue.lastTick) < 0.12 do
                    Sleep(20)
                end

                local totalGained = collectQueue.totalValue
                collectQueue.totalValue = 0
                collectQueue.active = false

                -- Kirim Pesan Akumulasi Chat
                if config.others.collectMsg == 1 and totalGained > 0 then
                    local c = utils.convertLocksCount(totalGained)
                    local parts = {}

                    if c.black > 0 then table.insert(parts, c.black .. " `bBLACK``") end
                    if c.bgl > 0 then table.insert(parts, c.bgl .. " `eBGL``") end
                    if c.dl > 0 then table.insert(parts, c.dl .. " `1DL``") end
                    if c.wl > 0 then table.insert(parts, c.wl .. " `9WL``") end

                    local text = #parts > 0 and table.concat(parts, " ") or "0 WL"
                    say("`9Collected `c" .. text, true)
                end
            end)
        end

        -- 5. Auto Convert System (WL -> DL, DL -> BGL, BGL -> Black)
        -- Convert WL -> DL
        local wlCount = const.itemId.wl or GetItemCount(242)
        if wlCount >= 100 and config.currency.cvdl == 1 then
            RunThread(function()
                wear(242)
                Sleep(100)
                wear(242)
            end)
        end

        -- Convert DL -> BGL (Menggunakan Telepon Terdekat)
        local dlCount = const.itemId.dl or GetItemCount(1796)
        if dlCount >= 100 and config.currency.cvbgl == 1 then
            RunThread(function()
                Sleep(100)
                local currentConfig = config.telephone.fastcv
                config.telephone.fastcv = 1
                Sleep(50)

                local px = math.floor(GetLocal().pos.x / 32)
                local py = math.floor(GetLocal().pos.y / 32)

                local closestTelephone = nil
                local minDist = math.huge

                for _, tile in pairs(GetTiles()) do
                    if tile.fg == 3898 then
                        local dist = math.abs(tile.x - px) + math.abs(tile.y - py)
                        if dist < minDist then
                            minDist = dist
                            closestTelephone = tile
                        end
                    end
                end

                if closestTelephone and minDist <= 5 then
                    local x = closestTelephone.x
                    local y = closestTelephone.y

                    Sleep(50)
                    SendPacket(2, "action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|" .. x .. "|\ny|" .. y .. "|\nbuttonClicked|bglconvert")
                    Sleep(100)
                    SendPacket(2, "action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|" .. x .. "|\ny|" .. y .. "|\nbuttonClicked|bglconvert")
                end

                config.telephone.fastcv = currentConfig
            end)
        end

        -- Convert BGL -> Black Gem Lock
        if GetItemCount(7188) >= 100 and config.currency.cvblack == 1 then
            RunThread(function()
                Sleep(100)
                SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bgl")
                Sleep(100)
                SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bgl")
            end)
        end
    end


    if var[0] == "OnConsoleMessage" and not var[1]:find("spun the wheel and got", 1, true) then
        log(watermark .. var[1])

        return true
    end
end
-- ============================================================================
-- INITIALIZE =================================================================

local function registerCommands()
    registerCommand({
        category = "Info",
        command = "/proxy",
        aliases = {},
        desc = "Shows Proxy Commands",
        icon = 660,
        argType = "none"
    })

    registerCommand({
        category = "Info",
        command = "/news",
        aliases = {},
        desc = "Shows News And Proxy Update",
        icon = 660,
        argType = "none"
    })

    registerCommand({
        category = "Info",
        command = "/gazette",
        aliases = {},
        desc = "Shows CreativePS News",
        icon = 660,
        argType = "none"
    })


    registerCommand({
        category = "Info",
        command = "/jzonline",
        aliases = {},
        desc = "See JzProxy Online User",
        icon = 660,
        argType = "none"
    })

    registerCommand({
        category = "Info",
        command = "/options",
        aliases = {
            "/opt",
            "/option"
        },
        desc = "Opens Big Feature Menu List",
        icon = 660,
        argType = "none"
    })



    registerCommand({
        category = "Customize",
        command = "/p",
        aliases = {},
        desc = "Send Decrypted Chat (Only Can See By Another Proxy User)",
        icon = 7206,
        argType = "required",
        usage = "[text]"
    })

    registerCommand({
        category = "Customize",
        command = "/watermark",
        aliases = {
            "/wm"
        },
        desc = "Set Chat Text Custom Watermark",
        icon = 7206,
        argType = "optional",
        usage = "[Watermark]"
    })

    registerCommand({
        category = "Customize",
        command = "/chatcolor",
        aliases = {
            "/cc"
        },
        desc = "Set Auto Colour Text",
        icon = 7206,
        argType = "optional",
        usage = "[Colour Code]"
    })

    registerCommand({
        category = "Customize",
        command = "/user",
        aliases = {},
        desc = "Show Registered IMMORTAL Proxy User",
        icon = 7206,
        argType = "none"
    })

    registerCommand({
        category = "Customize",
        command = "/ireng",
        aliases = {},
        desc = "Set Skin To Dark",
        icon = 7206,
        argType = "none"
    })

    registerCommand({
        category = "Customize",
        command = "/green",
        aliases = {},
        desc = "Set Skin To Green",
        icon = 7206,
        argType = "none"
    })



    registerCommand({
        category = "Drops",
        command = "/w",
        aliases = {},
        desc = "Drop Worlds Locks",
        icon = 1796,
        argType = "required",
        usage = "[amount]"
    })

    registerCommand({
        category = "Drops",
        command = "/d",
        aliases = {},
        desc = "Drop Diamond Locks",
        icon = 1796,
        argType = "required",
        usage = "[amount]"
    })

    registerCommand({
        category = "Drops",
        command = "/b",
        aliases = {},
        desc = "Drop Blue Gem Lock `4[Becareful Using This Commands]",
        icon = 1796,
        argType = "required",
        usage = "[amount]"
    })

    registerCommand({
        category = "Drops",
        command = "/bb",
        aliases = {},
        desc = "Drop Black Gem Lock `4[Becareful Using This Commands, I Suggest Use /b 100 Instead]",
        icon = 1796,
        argType = "required",
        usage = "[amount]"
    })

    registerCommand({
        category = "Drops",
        command = "/daw",
        aliases = {},
        desc = "Drops All Your Locks `4[Becareful Using This Commands]",
        icon = 1796,
        argType = "none"
    })

    registerCommand({
        category = "Drops",
        command = "/arroz",
        aliases = {
            "/adrop",
            "/ad"
        },
        desc = "Drop Arroz Con Pollo",
        icon = 1796,
        argType = "required",
        usage = "[amount]"
    })

    registerCommand({
        category = "Drops",
        command = "/song",
        aliases = {
            "/sdrop",
            "/sd"
        },
        desc = "Drop Songpyeon",
        icon = 1796,
        argType = "required",
        usage = "[amount]"
    })



    registerCommand({
        category = "Wrench",
        command = "/wrm",
        aliases = {},
        desc = "Opens Wrench Menu Dialog",
        icon = 32,
        argType = "none"
    })

    registerCommand({
        category = "Wrench",
        command = "/wrp",
        aliases = {},
        desc = "Enables Wrench Pull Mode",
        icon = 32,
        argType = "none"
    })

    registerCommand({
        category = "Wrench",
        command = "/wrk",
        aliases = {},
        desc = "Enables Wrench Kick Mode",
        icon = 32,
        argType = "none"
    })

    registerCommand({
        category = "Wrench",
        command = "/wrb",
        aliases = {},
        desc = "Enables Wrench Ban Mode",
        icon = 32,
        argType = "none"
    })

    registerCommand({
        category = "Wrench",
        command = "/smodal",
        aliases = {
            "/showbal"
        },
        desc = "Enables Shows Player Balance",
        icon = 32,
        argType = "none"
    })

    registerCommand({
        category = "Wrench",
        command = "/pbody",
        aliases = {},
        desc = "Enables Pulling Player By Clicking Their Body",
        icon = 32,
        argType = "none"
    })



    registerCommand({
        category = "Roulette Wheel",
        command = "/reme",
        aliases = {},
        desc = "Show REME Number On Bubble & System When Punch Roulette",
        icon = 758,
        argType = "none"
    })

    registerCommand({
        category = "Roulette Wheel",
        command = "/leme",
        aliases = {},
        desc = "Show LEME Number On Bubble & System When Punch Roulette",
        icon = 758,
        argType = "none"
    })

    registerCommand({
        category = "Roulette Wheel",
        command = "/qeme",
        aliases = {},
        desc = "Show QEME Number On Bubble & System When Punch Roulette",
        icon = 758,
        argType = "none"
    })

    registerCommand({
        category = "Roulette Wheel",
        command = "/sspin",
        aliases = {},
        desc = "Show Number Only Without 'spun the wheel and got' Text",
        icon = 758,
        argType = "none"
    })

    registerCommand({
        category = "Roulette Wheel",
        command = "/lastspin",
        aliases = {
            "/lspin"
        },
        desc = "Show Player Last Spin On Player Name"
    })



    registerCommand({
        category = "BJ & BTK",
        command = "/setgems1",
        aliases = {},
        desc = "Set First/Left Room Gems Tile",
        icon = 340,
        argType = "none"
    })

    registerCommand({
        category = "BJ & BTK",
        command = "/setgems2",
        aliases = {},
        desc = "Set Second/Right Room Gems Tile",
        icon = 340,
        argType = "none"
    })

    registerCommand({
        category = "BJ & BTK",
        command = "/vertical",
        aliases = {},
        desc = "Set Gems Position To Vertical",
        icon = 340,
        argType = "none"
    })

    registerCommand({
        category = "BJ & BTK",
        command = "/horizontal",
        aliases = {},
        desc = "Set Gems Position To Horizontal",
        icon = 340,
        argType = "none"
    })

    registerCommand({
        category = "BJ & BTK",
        command = "/scan",
        aliases = {},
        desc = "Scan Gems Total On Setted Tile",
        icon = 340,
        argType = "none"
    })

    registerCommand({
        category = "BJ & BTK",
        command = "/settax",
        aliases = {
            "/tax"
        },
        desc = "Set Tax Percentage",
        icon = 340,
        argType = "required",
        usage = "[tax, ex: /tax 2.5]"
    })

    registerCommand({
        category = "BJ & BTK",
        command = "/setroom1",
        aliases = {},
        desc = "Set Display Box For Room 1/Left",
        icon = 340,
        argType = "none"
    })

    registerCommand({
        category = "BJ & BTK",
        command = "/setroom2",
        aliases = {},
        desc = "Set Display Box For Room 2/Right",
        icon = 340,
        argType = "none"
    })

    registerCommand({
        category = "BJ & BTK",
        command = "/takebet",
        aliases = {},
        desc = "Take Bet",
        icon = 340,
        argType = "none"
    })




    registerCommand({
        category = "Auto Pull",
        command = "/autopull",
        aliases = {},
        desc = "Opens Auto Pull Settings Dialog",
        icon = 13554,
        argType = "none"
    })

    registerCommand({
        category = "Auto Pull",
        command = "/setap",
        aliases = {},
        desc = "Set Auto Pull Tile",
        icon = 13554,
        argType = "none"
    })

    registerCommand({
        category = "Auto Pull",
        command = "/notify",
        aliases = {},
        desc = "Toggle Notify When Pull Player",
        icon = 13554,
        argType = "none"
    })

    registerCommand({
        category = "Auto Pull",
        command = "/min",
        aliases = {},
        desc = "Set Minimum Modal Player To Pull",
        icon = 13554,
        argType = "required",
        usage = "[amount]"
    })

    registerCommand({
        category = "Auto Pull",
        command = "/blacklist",
        aliases = {},
        desc = "Opens Auto Pull Blacklist Dialog",
        icon = 13554,
        argType = "none"
    })

    registerCommand({
        category = "Auto Pull",
        command = "/blacklistall",
        aliases = {},
        desc = "Blacklist All Player In World",
        icon = 13554,
        argType = "none"
    })

    registerCommand({
        category = "Auto Pull",
        command = "/clearblacklist",
        aliases = {},
        desc = "Remove All Blacklisted Player From List",
        icon = 13554,
        argType = "none"
    })

    registerCommand({
        category = "Auto Pull",
        command = "/ap",
        aliases = {},
        desc = "Enable Auto Pull When Player Join World",
        icon = 13554,
        argType = "none"
    })

    registerCommand({
        category = "Pull Utility",
        command = "/setpt",
        aliases = {},
        desc = "Set Pull Tile In Current Position With 3x3 Area",
        icon = 13552,
        argType = "none"
    })

    registerCommand({
        category = "Pull Utility",
        command = "/pt",
        aliases = {},
        desc = "Pull Player In Tile",
        icon = 13552,
        argType = "none"
    })

    registerCommand({
        category = "Pull Utility",
        command = "/pthk",
        aliases = {},
        desc = "Enable Pull Tile Hotkey `c[F1 In Windows, Clash Event Button In Android]``",
        icon = 13552,
        argType = "none"
    })

    registerCommand({
        category = "Pull Utility",
        command = "/lastpull",
        aliases = {
            "/lp"
        },
        desc = "Pull The Last Person U Pulled `4[Last User You Pulled Data Will Be Deleted After 1 Minute]``",
        icon = 13552,
        argType = "none"
    })

    registerCommand({
        category = "Pull Utility",
        command = "/lphk",
        aliases = {},
        desc = "Enable Last Pull Hotkey `c[Dungeon Button For Android, F5]``",
        icon = 13552,
        argType = "none"
    })

    registerCommand({
        category = "Pull Utility",
        command = "/resetlp",
        aliases = {
            "/reslp",
            "/rlp"
        },
        desc = "Reset/Remove Last Pull Data",
        icon = 13552,
        argType = "none"
    })




    registerCommand({
        category = "Currency & Banking",
        command = "/deposit",
        aliases = {
            "/depo",
            "/dp"
        },
        desc = "Deposits BGl Into Bank",
        icon = 6290,
        argType = "optional",
        usage = "[amount]"
    })

    registerCommand({
        category = "Currency & Banking",
        command = "/withdraw",
        aliases = {
            "/wd"
        },
        desc = "Deposits BGl Into Bank",
        icon = 6290,
        argType = "required",
        usage = "[amount]"
    })

    registerCommand({
        category = "Currency & Banking",
        command = "/bank",
        aliases = {},
        desc = "Open CreativePS BGL Bank",
        icon = 6290,
        argType = "none"
    })

    registerCommand({
        category = "Currency & Banking",
        command = "/black",
        aliases = {},
        desc = "Convert `c100 `eBlue Gem Lock `9To `c1 `bBlack````",
        icon = 6290,
        argType = "none"
    })

    registerCommand({
        category = "Currency & Banking",
        command = "/bgl",
        aliases = {},
        desc = "Convert `c1 `bBlack Gem Lock `9To `c100 `eBlue Gem Lock````",
        icon = 6290,
        argType = "none"
    })

    registerCommand({
        category = "Currency & Banking",
        command = "/fastcv",
        aliases = {},
        desc = "Enable Fast Cv DL To BGL When Wrench Telephone",
        icon = 6290,
        argType = "none"
    })

    registerCommand({
        category = "Currency & Banking",
        command = "/cvdl",
        aliases = {},
        desc = "Auto Convert `c100 `9World Locks ````To `c1 `1Diamond Lock ````When Colleted Items",
        icon = 6290,
        argType = "none"
    })

    registerCommand({
        category = "Currency & Banking",
        command = "/cvbgl",
        aliases = {},
        desc = "Auto Convert `c100 `1Diamond Locks ````To `c1 `eBlue Gem Lock ````When Colleted Items",
        icon = 6290,
        argType = "none"
    })

    registerCommand({
        category = "Currency & Banking",
        command = "/cvblack",
        aliases = {},
        desc = "Auto Convert `c100 `eBlue Gem Lock ````To `c1 `bBlack Gem Lock ````When Colleted Items",
        icon = 6290,
        argType = "none"
    })





    registerCommand({
        category = "Utility",
        command = "/tp",
        aliases = {},
        desc = "Enable FindPath To Punched Display Box And Back `c[Useful For Android User. For Windows Use Ctrl + Click Instead]``",
        icon = 3180,
        argType = "none"
    })

    registerCommand({
        category = "Utility",
        command = "/hideslave",
        aliases = {},
        desc = "Hide Spammer Slave",
        icon = 3180,
        argType = "none"
    })

    registerCommand({
        category = "Utility",
        command = "/hidechamp",
        aliases = {
            "/hc"
        },
        desc = "Hide Using Champ Animation `8[/cheer Animation]``",
        icon = 3180,
        argType = "none"
    })

    registerCommand({
        category = "Utility",
        command = "/calcu",
        aliases = {
            "/calc"
        },
        desc = "Solve Simple Math Problem",
        icon = 3180,
        argType = "required",
        usage = "[Math Problem]"
    })

    registerCommand({
        category = "Utility",
        command = "/blocksdb",
        aliases = {
            "/bsdb"
        },
        desc = "Block Super Duper Broadcast",
        icon = 3180,
        argType = "none"
    })


    registerCommand({
        category = "Utility",
        command = "/imgui",
        aliases = {},
        desc = "Enable IMGUI",
        icon = 3180,
        argType = "none"
    })

    registerCommand({
        category = "Utility",
        command = "/ping",
        aliases = {},
        desc = "Show Your Current Ping Latency, Avg, And Packet Loss",
        icon = 3180,
        argType = "none"
    })

    registerCommand({
        category = "Utility",
        command = "/hidecloth",
        aliases = {
            "/ch",
            "/hidec"
        },
        desc = "Hide Clothes By Name `8[Dont Forget To Relog World]``",
        icon = 3180,
        argType = "required",
        usage = "[Cloth Full Name/Id]"

    })

    registerCommand({
        category = "Utility",
        command = "/unhidecloth",
        aliases = {
            "/unch",
            "/unhidec"
        },
        desc = "Unhide Clothes By Name Or Id `8[Dont Forget To Relog World]``",
        icon = 3180,
        argType = "optional",
        usage = "[Cloth Full Name/Id]"
    })

    registerCommand({
        category = "Utility",
        command = "/faststorage",
        aliases = {
            "/fastsbox"
        },
        desc = "Auto Put Or Take All Storage Box",
        icon = 3180,
        argType = "none"
    })





    registerCommand({
        category = "Spam",
        command = "/spam",
        aliases = {},
        desc = "Opens Spam Settings Dialog",
        icon = GetItemInfo("Spammer Slave").id,
        argType = "none"
    })

    registerCommand({
        category = "Spam",
        command = "/startspam",
        aliases = {
            "/sspam"
        },
        desc = "Toggle Auto Spam",
        icon = 16824,
        argType = "none"
    })



    registerCommand({
        category = "Logs",
        command = "/log",
        aliases = {
            "/logs"
        },
        desc = "Opens Logs Dialog",
        icon = 1436,
        argType = "none"
    })
    
    registerCommand({
        category = "Logs",
        command = "/spin",
        aliases = {},
        desc = "Opens Roulette Wheel Spin Logs Dialog",
        icon = 1436,
        argType = "none"
    })
    
    registerCommand({
        category = "Logs",
        command = "/collect",
        aliases = {},
        desc = "Opens Collect Logs Dialog",
        icon = 1436,
        argType = "none"
    })
    
    registerCommand({
        category = "Logs",
        command = "/cmdlogs",
        aliases = {},
        desc = "Opens Commands Logs Dialog",
        icon = 1436,
        argType = "none"
    })





    registerCommand({
        category = "Shortcuts",
        command = "/relog",
        aliases = {},
        desc = "Re Enter World Quickly",
        icon = 2322,
        argType = "none"
    })

    registerCommand({
        category = "Shortcuts",
        command = "/res",
        aliases = {},
        desc = "Respawn",
        icon = 2322,
        argType = "none"
    })

    registerCommand({
        category = "Shortcuts",
        command = "/mf",
        aliases = {},
        desc = "Toggle ModFly",
        icon = 2322,
        argType = "none"
    })

    registerCommand({
        category = "Shortcuts",
        command = "/g",
        aliases = {},
        desc = "/ghost Shortcuts",
        icon = 2322,
        argType = "none"
    })
end

local function registerHooks()
    AddHook("OnSendPacket", "commandHandler", commandHandler)

    AddHook("OnVariant", "VariantHook", VariantHook)
    AddHook("OnVariant", "autopull", autopull)

    AddHook("OnSendPacket", "dialogHandler", dialogHandler)

    AddHook("OnWorldTouch", "WorldTouchHook", WorldTouchHook)

    AddHook("OnVariant", "nameHandler", nameHandler)

    AddHook("OnSendPacket", "PacketHook", PacketHook)

    AddHook("OnInput", "Hotkey", Hotkey)

    AddHook("OnSendPacketRaw", "rawHook", rawHook)
end




local function getCommandsCount()
    local categoryCount = 0
    local commandCount = 0
    local aliasesCount = 0

    for _, categoryData in ipairs(commands or {}) do
        categoryCount = categoryCount + 1
        for _, commandData in ipairs(categoryData.items or {}) do
            commandCount = commandCount + 1
            if commandData.aliases then
                for _, alias in ipairs(commandData.aliases) do
                    aliasesCount = aliasesCount + 1
                end
            end
        end
    end

    return {
        category = categoryCount,
        aliases = aliasesCount,
        commands = commandCount
    }
end

local function gettingProxyUser()
    -- Menggunakan parameter cache-busting (?v=timestamp)
    local url = "https://cdn.jsdelivr.net/gh/Lawvy3/lokiProxy@main/allowIMMORTAL"
    local res = MakeRequest(url, "GET")
    
    if res and res.content and #res.content > 0 then
        local cleanContent = res.content:gsub("\r", "")
        for uid, nick in cleanContent:gmatch("(%d+)|([^\n]+)") do
            proxyUser[tostring(uid)] = nick:match("^%s*(.-)%s*$")
        end
        return true
    end
    
    return false
end

local function isProxyUser(uid)
    return proxyUser[tostring(uid)] ~= nil
end

local function initialize()
    loadConfig()
    registerCommands()
    registerHooks()

    local counts = getCommandsCount()

    log("`9Total Registered Commands Category: `2" .. counts.category)
    log("`9Total Registered Commands Aliases: `2" .. counts.aliases)
    log("`9Total Registered Commands: `2" .. counts.commands)

    -- SendPacket(2, "action|input\n|text|`9[`4IMMORTAL``] By amouls Proxy Injected")

    if controller and controller.news then
        controller.news()
    end

    ChangeValue("[M] Pathfinder", false)

    if config and config.spam and config.spam.status == 1 then
        startSpam()
    end

    if config and config.others and config.others.imgui == 1 then
        AddHook("OnDraw", "imgui", imgui)
    end

    RunThread(function()
        for _, player in pairs(GetPlayerList()) do
            if isProxyUser(player.userid) then
                set_player_rank(player.netid, "`9[`4P`9]")
            end
        end
    end)
end


if GetLocal() then
    log("`9Getting User Data...")
    
    local isSuccess = false
    local maxRetries = 10
    local baseDelay = 200      -- Jeda awal jika gagal (ms)
    local maxDelay = 2500      -- Jeda maksimal jika gagal berulang (ms)
    local factor = 1.5         -- Multiplier backoff
    local attempts = 0
    local currentDelay = baseDelay
    local actualRequestTime = 0

    while not isSuccess and attempts < maxRetries do
        attempts = attempts + 1
        
        -- Catat waktu awal request HTTP
        local reqStart = os.clock() * 1000
        local success = gettingProxyUser()
        local reqEnd = os.clock() * 1000
        
        -- Hitung latency asli dari request HTTP dalam milidetik
        actualRequestTime = math.floor(reqEnd - reqStart)
        
        if success then
            isSuccess = true
            break
        else
            if attempts < maxRetries then
                local sleepTime = math.floor(currentDelay)
                log("`9Retrying to get data (" .. attempts .. "/" .. maxRetries .. ") in " .. sleepTime .. "ms...")
                Sleep(sleepTime)
                
                -- Dynamic delay backoff untuk percobaan berikutnya
                currentDelay = math.min(currentDelay * factor, maxDelay)
            end
        end
    end

    if isSuccess then
        -- Menampilkan delay/latency asli secara dinamis berdasarkan respon HTTP
        log("`2Successfully `9Get User Data With `2" .. actualRequestTime .. "ms `c" .. attempts .. "`9x")
        
        if isProxyUser(GetLocal().userid) then
            initialize()
        else
            log("`4[ACCESS DENIED] `9UID kamu (" .. GetLocal().userid .. ") tidak terdaftar di whitelist!")
        end
    else
        log("`9Something `4ERROR `9When Getting Data (Timeout), Report To Dev")
    end
else
    log("`9Please Enter World Then Re-Execute The Proxy")
end
