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
local customWatermark = ""

local ver = "4.2"

local is_windows = package.config:sub(1, 1) == "\\"

local CONFIG_FILE
if is_windows then
    CONFIG_FILE = "C:/Users/" .. os.getenv("USERNAME") .. "/AppData/local/Growtopia/scripts/sylConfig.bin" -- Ganti sesuai path Windows
else
    CONFIG_FILE = "storage/emulated/0/Android/media/com.rtsoft.growtopia/scripts/sylConfig.bin" -- Path untuk Android
end

local watermark = (customWatermark ~= "" and customWatermark or "`9[`^Syl`6Proxy````] ``")


local const = {
    itemId = {
        champagne = GetItemInfo("Champagne").id,
        wl = 242,
        dl = 1796,
        bgl = 7188,
        black = 11550,
        cc = GetItemInfo("Creative Coin").id,
        spamSlave = GetItemInfo("Spammer Slave").id
    }
}

local config = {
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
    autopull = {
        scantile = 0,
        onspawn = 0,
        tile = {
            x = 0,
            y = 0
        },
        notify = 1,
        minimum = 0,
        autooff = 1,
        blacklist = {}
    }
}

local cache = {
    setap = false,
    setapDialog = false,
    autopull = {
        dlPulled = 0
    },
    lp = {
        uid = 0
    }
}


local player_spin_titles = {}
local name_overrides = {}
local server_names = {}
local is_internal_send = false


local function clearCache()
    player_spin_titles = {}
    name_overrides = {}
    server_names = {}
    is_internal_send = false


    cache.setap = false
    cache.setapDialog = false
    cache.autopull.dlPulled = 0

    cache.lp.uid = 0


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
        SendPacket(2, "action|input\n|text|" .. msg)
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
        cache.lp.uid = (player and player.userid) or 0 

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

local function isBlacklist(userid)
    userid = tonumber(userid)

    for _, bl in ipairs(config.autopull.blacklist) do
        if userid == tonumber(bl.userid) then
            return true
        end
    end

    return false
end

local function addBlacklistLog()
    local result = {}

    for _, player in pairs(GetPlayerList()) do
        if not player.name:find("'s Spammer Slave. (", 1, true)
            and player.userid ~= GetLocal().userid
            and not isBlacklist(player.userid) then

            table.insert(result,
                "add_checkbox|" ..
                "addBL_" .. player.userid .. "_" .. player.name .. "|" ..
                "`0" .. player.name .. " `9// `w#" .. player.userid .. 
                "|0|"
            )
        end
    end

    return table.concat(result, "\n")
end

local function removeBlacklistLog()
    local result = {}

    for _, bl in ipairs(config.autopull.blacklist) do
        if #config.autopull.blacklist ~= 0 then
            table.insert(result,
                "add_checkbox|" ..
                "removeBL_" .. bl.userid .. "|" ..
                "`0" .. bl.growid .. 
                " `0#" .. bl.userid ..
                "|1|"
            )
        end
    end

    return table.concat(result, "\n")
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

    -- local hotkey = {
    --     "add_label_with_icon|small|`cHotkey:|left|7078",
    --     "add_smalltext|`cShift + Click `9(FindPath / Teleport To Collision Tile)|left",
    --     "add_smalltext|`cCtrl + Click `9(FindPath & Back)|left",
    --     "add_smalltext|`cF1 `9(Windows Hotkey For `c'/pt'`9)|left",
    --     "add_smalltext|`cClash Button `9(Android Hotkey For `c'/pt'`9)|left",
    --     "add_smalltext|`cF5 `9(Windows Hotkey For `c'/lp'`9)|left",
    --     "add_smalltext|`cDungeon Button `9(Android Hotkey For `c'/lp'`9)|left",
    -- }

    local dialogList = {
        proxy = {
            "add_label_with_icon|big|`cProxy Features List|left|1790",
            getCommands(),
            "add_spacer|small",

            -- table.concat(hotkey, "\n"),

            "add_quick_exit",
            "end_dialog|proxy|Close||"
        },

        autopull = {
            "add_label_with_icon|big|`cAutopull Settings|left|14824",
            "add_spacer|small",

            string.format("add_label_with_icon|small|`9OnSpawn: %s|left|%d", (config.autopull.onspawn == 1 and "`2ON" or "`4OFF"), (config.autopull.onspawn == 1 and 176 or 170)),
            string.format("add_label_with_icon|small|`9Scan Tile: %s|left|%d", (config.autopull.scantile == 1 and "`2ON" or "`4OFF"), (config.autopull.scantile == 1 and 176 or 170)),
            "add_spacer|small",

            "add_button|gotoBlacklist|`bBlacklist Settings|noflags|0|0|",
            "add_spacer|small",


            string.format("add_smalltext|`9Autopull Tile (`c%d``, `c%d``)|left", config.autopull.tile.x, config.autopull.tile.y),
            string.format("add_button|setap|`2Set `9Autopull Tile (`c%d``, `c%d``)|noflags|0|0|", config.autopull.tile.x, config.autopull.tile.y),
            "add_spacer|small",

            "add_smalltext|`5You Will Got Notify (Growtopia Knocking & Achievement Sounds) When Pulled Player|left",
            string.format("add_checkbox|notify|`2Enable `9Notify When Pulled Player|%d|", config.autopull.notify),
            "add_smalltext|`5Autopull Will Be Turned Off When Pulled Player(Avoid Double Pull)|left",
            string.format("add_checkbox|autooff|`2Enable `9Auto Off When Pulled Player|%d|", config.autopull.autooff),
            "add_spacer|small",

            string.format("add_text_input|minimum|`9Minimum Modal (`1DLS``): |%d|7|", config.autopull.minimum),
            "add_spacer|small",

            "add_label|small|`cAdd Blacklist: |left|",
            addBlacklistLog(),
            "add_spacer|small",

            "end_dialog|autopull|Cancel|Save"
        },

        blacklist = {
            "add_label_with_icon|big|`cAutopull `bBlacklist|left|278",
            "add_spacer|small",

            "add_button|clearBlacklist|`4Clear Blacklist|noflags|0|0|",
            "add_spacer|small",

            "add_label|small|`cUnchecklist To Remove Player From Blacklist:|left",
            "add_spacer|small",

            removeBlacklistLog(),
            "add_spacer|small",

            "add_button|back|Back|noflags|0|0|",

            "end_dialog|blacklist|Cancel|Save"
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

function controller.autopull()
    sendDialog(dialog("autopull"))
end

function controller.ap()
    toggle(config.autopull, "onspawn", false, "OnSpawn Autopull")
end



function controller.min(amount)
    amountDL = tonumber(amount)

    if not amountDL then
        log("`4Invalid Amount (`c" .. amount .. "``)")

        return
    end

    config.autopull.minimum = amountDL

    log("`9Autopull Minimum Set To `c" .. config.autopull.minimum .. " `1DLS")

    saveConfig()
end

function controller.blacklist()
    sendDialog(dialog("blacklist"))
end

function controller.setap()
    log("`9Click Tile To `2Set ``Autopull Tile")
    sendOverlay("`9Click Tile To `2Set ``Autopull Tile")

    cache.setap = true
end

function controller.blacklistall()
    for _, player in pairs(GetPlayerList()) do
        if not player.name:find("'s Spammer Slave. (", 1, true)
            and player.userid ~= GetLocal().userid
            and not isBlacklist(player.userid) then

            local uid = player.userid
            local growid = player.name

            log("`9Added `c" .. uid .. " `9To Autopull Blacklist")

            table.insert(config.autopull.blacklist, {
                userid = tonumber(uid),
                growid = growid
            })
            
        end
    end

    saveConfig()

    local i = 0

    for _, _ in pairs(config.autopull.blacklist) do
        i = i+1
    end

    log("`9Total Autopull Blacklist (`c" .. i .. "`9)")
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
        if packet:find("dialog_name|autopull", 1, true) then
            local notify = tonumber(packet:match("notify|(%d)"))
            local autooff = tonumber(packet:match("autooff|(%d)"))
            local minimum = tonumber(packet:match("minimum|(%d+)"))

            config.autopull.notify = notify
            config.autopull.autooff = autooff
            config.autopull.minimum = minimum

            for uid, growid, status in packet:gmatch("addBL_(%d+)_(.-)|(%d)") do
                                
                if tonumber(status) == 1 then

                    table.insert(config.autopull.blacklist, {
                        userid = tonumber(uid),
                        growid = growid
                    })

                    log("`9Added `c" .. uid .. " `9To Autopull Blacklist")
                end
            end

            if packet:find("buttonClicked|gotoBlacklist", 1, true) then
                sendDialog(dialog("blacklist"))
            end

            if packet:find("buttonClicked|setap", 1, true) then
                log("`9Click Tile To `2Set ``Autopull Tile")
                sendOverlay("`9Click Tile To `2Set ``Autopull Tile")

                cache.setap = true
                cache.setapDialog = true
            end

            saveConfig()

            local i = 0

            for _, _ in pairs(config.autopull.blacklist) do
                i = i+1
            end

            log("`9Total Autopull Blacklist (`c" .. i .. "`9)")
        end




        if packet:find("dialog_name|blacklist", 1, true) then

            for uid, status in packet:gmatch("removeBL_(%d+)|(%d)") do
                                
                if tonumber(status) == 0 then

                    for i = #config.autopull.blacklist, 1, -1 do
                        local blacklisted = config.autopull.blacklist[i]
                        
                        if tonumber(blacklisted.userid) == tonumber(uid) then
                            table.remove(config.autopull.blacklist, i)
                        end
                    end

                    log("`4Removed `c" .. uid .. " `9From Autopull Blacklist")
                end
            end

            if packet:find("buttonClicked|clearBlacklist", 1, true) then
                config.autopull.blacklist = {}
                log("`aBlacklist `4Cleared")
            end

            if packet:find("buttonClicked|back", 1, true) then
                sendDialog(dialog("autopull"))
            end

            saveConfig()

            local i = 0

            for _, _ in pairs(config.autopull.blacklist) do
                i = i+1
            end

            log("`9Total Autopull Blacklist (`c" .. i .. "`9)")
        end
    end
end
-- ============================================================================
-- PACKETHOOK =================================================================
local function PacketHook(type, packet)

end


-- ============================================================================
-- HOTKEY =====================================================================

local function IsKeyDown(key)

end

local function Hotkey(key)

end

-- ============================================================================
-- ============================================================================
-- WORLDTOUCH =================================================================

local function WorldTouchHook(pos, start)
    if start then
        if cache.setap then
            local x = tonumber(math.floor(pos.x/32))
            local y = tonumber(math.floor(pos.y/32))

            config.autopull.tile.x = x
            config.autopull.tile.y = y

            saveConfig()

            log(string.format("`2Successfully `9Autopull Tile Set To (`c%d``, `c%d``)", config.autopull.tile.x, config.autopull.tile.y))

            if cache.setapDialog then
                sendDialog(dialog("autopull"))
            end

            utils.lockEffect(x, y)

            cache.setap = false
        end
    end
end

-- ============================================================================
-- RAW HOOK ===================================================================
local function rawHook(packet)

end

-- ============================================================================
-- VARIANTHOOK ================================================================

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

local function cleanName(str)
    if not str then return "" end
    return str:gsub("`.", "")             -- Hapus semua kode warna
              :gsub("%(.-%)", "")         -- Hapus isi dalam kurung
              :gsub("%[.-%]", "")         -- Hapus isi dalam siku ([P], Guild, dll)
              :gsub("[%s%c%z]", "")       -- Hapus spasi dan control character
              :lower()                    -- Uniform ke lowercase
end


local function Filter(str)
    if not str then return "Unknown" end
    local cleaned = str:gsub("%s+", " ")
    cleaned = cleaned:match("^%s*(.-)%s*$") or "Unknown"
    return cleaned
end



local AptCooldown = {}
local PendingModalPull = {}
local activePulling = nil
local startPull = nil

-- Function untuk mengeksekusi Pull, diadaptasi dengan config milikmu
local function CheckAndExecutePull(playerObj)
    if not playerObj then return end
    local netID = playerObj.netid
    local userID = playerObj.userid
    local playerName = playerObj.name
    
    if not netID then return end

    -- Cek Blacklist dari config kamu
    if userID then
        for _, blacklisted in pairs(config.autopull.blacklist) do
            if tonumber(blacklisted.userid) == userID then return end -- Batal pull jika di blacklist
        end
    end

    local now = os.clock()
    if AptCooldown[netID] and (now - AptCooldown[netID] < 0.5) then return end

    local min_modal = tonumber(config.autopull.minimum) or 0
    if min_modal <= 0 then
        -- Jika tidak ada minimal modal, langsung tarik (Pull)
        AptCooldown[netID] = now

        activePulling = {
            name = playerName,
            cleanName = cleanName(playerName),
            netid = tonumber(netID),
            userid = tonumber(userID),
            isAutopull = true,
            direct = true
        }
        
        -- Double packet agar lebih cepat (Bypass lag)
        SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netID .. "|\nbuttonClicked|pull")
        RunThread(function()
            Sleep(50)
            SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netID .. "|\nbuttonClicked|pull")
        end)

        local text = config.wrench.pText:gsub("{name}", playerName)
        SendPacket(2, "action|input\n|text|" .. text)
        
        log(string.format("`9Trying To Pulling %s", Filter(playerName)))
    -- Di dalam CheckAndExecutePull (bagian else / min_modal > 0):
    else
        AptCooldown[netID] = now
        local uID = tonumber(userID) or tonumber(netID)
        if uID then
            PendingModalPull[uID] = {
                netid = tonumber(netID),
                userid = tonumber(userID),
                name = playerName
            }
        end
        SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netID .. "|\nbuttonClicked|viewinv")
    end
end


-- Inisialisasi variabel kontrol (sesuaikan atau letakkan di bagian atas script)
local AreaPullThreadRunning = false

function ManageAreaPullThread()
    if AreaPullThreadRunning then return end
    AreaPullThreadRunning = true

    RunThread(function()
        -- Loop berjalan selama fitur autopull scan tile diaktifkan (misal config.autopull.scantile == 1)
        while config.autopull and config.autopull.scantile == 1 do
            local pList = GetPlayerList()
            if pList then
                local lp = GetLocal()
                local lpNetID = lp and lp.netid or -1
                
                -- Target tile dari config kamu
                local targetX = config.autopull.tile.x
                local targetY = config.autopull.tile.y

                -- Hanya scan jika koordinat target valid (> 0)
                if targetX > 0 and targetY > 0 then
                    for _, p in pairs(pList) do
                        if p.pos and p.pos.x and p.pos.y and p.netid ~= lpNetID then
                            -- Konversi koordinat piksel pemain ke tile (Growtopia tile size = 32px)
                            local pxCenter = math.floor((p.pos.x + 16) / 32)
                            local pyCenter = math.floor((p.pos.y + 16) / 32)
                            local rawPx = math.floor(p.pos.x / 32)
                            local rawPy = math.floor(p.pos.y / 32)
                            
                            -- Pengecekan posisi pemain terhadap target tile
                            local xMatch = (pxCenter >= targetX - 1 and pxCenter <= targetX + 1) or 
                                           (rawPx >= targetX - 1 and rawPx <= targetX + 1)

                            local yMatch = (pyCenter == targetY or rawPy == targetY or pyCenter == targetY + 1 or rawPy == targetY + 1)
                            
                            if xMatch and yMatch then
                                startPull = os.clock()

                                CheckAndExecutePull(p)
                                break
                            end
                        end
                    end
                end
            end
            Sleep(20) -- Delay 20ms untuk mencegah spam/lag CPU
        end
        AreaPullThreadRunning = false
    end)
end
function controller.aps()
    toggle(config.autopull, "scantile", false, "Scan Tile Autopull")
    ManageAreaPullThread()
end

-- Function utama kamu yang sudah diperbaiki
local function autopull(var)
    if var[0] == "OnSpawn" then
        local data = var[1]

        local netID = tonumber(data:match("netID%s*|%s*(%d+)"))
        local userID = tonumber(data:match("userID%s*|%s*(%d+)"))
        local growid = data:match("name%s*|%s*([^|\n]+)")

        -- [DIPERBAIKI] Sebelumnya kamu pakai 'spawnData', padahal variabelnya 'data'
        local posX, posY = data:match("posXY%|(%d+)%|(%d+)")
        if not posX then
            posX = data:match("pos_x%|(%d+)")
            posY = data:match("pos_y%|(%d+)")
        end

        RunThread(function()
            if isProxyUser(tostring(userID)) then
                set_player_rank(netID, "`2[P]")
            end
        end)

        -- Abaikan jika itu adalah bot kita sendiri
        if data:find("type|local", 1, true) then
            -- clearCache() -- Pastikan function ini ada, atau hapus baris ini
            RunThread(function()
                log("`9Getting Lock & Champagne Data...")
                Sleep(1000)
                -- Pastikan GetItemCount sudah dedefinisikan di executor kamu
                local total = (GetItemCount(242)/100) + GetItemCount(1796) + (GetItemCount(7188)*100) + (GetItemCount(11550)*10000)
                log("`1Diamond Lock `9On Backpack: `c" .. (total or 0))
                log("`rChampagne `9On Backpack: `c" .. (GetItemCount(const.itemId.champagne) or 0)) 
            end)
            return
        end

        if config.autopull.onspawn == 1 then
            startPull = os.clock()
            if netID then
                local playerObj = {
                    netid = tonumber(netID),
                    userid = tonumber(userID),
                    name = growid and Filter(growid) or "Unknown",
                }

                -- LOGIKA POSISI YANG SUDAH DISESUAIKAN DENGAN CONFIG KAMU
                if posX and posY then
                    local spawnTileX = math.floor(tonumber(posX) / 32)
                    local spawnTileY = math.floor(tonumber(posY) / 32)
                    
                    local targetX = config.autopull.tile.x
                    local targetY = config.autopull.tile.y
                    
                    if targetX > 0 and targetY > 0 then
                        -- Jika target tile diset di config, cek apakah player spawn di dekat tile itu
                        if (spawnTileX == targetX) and (spawnTileY == targetY) then
                            CheckAndExecutePull(playerObj)
                        end
                    else
                        -- Jika targetX dan targetY 0 (belum diset), berarti AutoPull Anywhere (dimanapun)
                        log("`4Please Set Tile Autopull First")
                    end
                end
                
            end
        end
    end
end

local function VariantHook(var, nid, delay)
    if var[0] == "OnDialogRequest" and var[1]:find("embed_data|userID", 1, true) then
        local dialog = var[1]
        
        -- Tangkap userID atau netID dari dialog
        local dialogUserID = tonumber(dialog:match("embed_data|userID|(%d+)"))
        local dialogNetID = tonumber(dialog:match("embed_data|netID|(%d+)") or dialog:match("netID|(%d+)"))
        
        -- Cek antrean berdasarkan userID atau netID
        local pendingKey = (dialogUserID and PendingModalPull[dialogUserID] and dialogUserID) 
                        or (dialogNetID and PendingModalPull[dialogNetID] and dialogNetID)
        local pending = pendingKey and PendingModalPull[pendingKey]

        -- =========================================================
        -- 1. JIKA INI HASIL DARI AUTOPULL MODAL (Pending)
        -- =========================================================
        if pending then
            local name = dialog:match("big|(.+)'s Inventory``") or pending.name or "Unknown"

            local wl = tonumber(dialog:match("staticframe|" .. const.itemId.wl .. "|(%d+)|")) or 0
            local dl = tonumber(dialog:match("staticframe|" .. const.itemId.dl .. "|(%d+)|")) or 0
            local bglInven = tonumber(dialog:match("staticframe|" .. const.itemId.bgl .. "|(%d+)|")) or 0
            local bglBank = tonumber(dialog:match("Blue Gem Locks in the Bank: `$(%d+)``")) or 0
            local black = tonumber(dialog:match("staticframe|" .. const.itemId.black .. "|(%d+)|")) or 0

            local totalWL = wl + (dl * 100) + ((bglInven + bglBank) * 10000) + (black * 1000000)
            cache.autopull.dlPulled = totalWL / 100

            local minModalWL = (tonumber(config.autopull.minimum) or 0) * 100

            if totalWL >= minModalWL then
                utils.wrenchAction("pull", pending.netid)
                RunThread(function()
                    Sleep(50)
                    SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. pending.netid .. "|\nbuttonClicked|pull")
                end)

                -- AKTIFKAN ACTIVE PULLING KARENA LULUS CEK MODAL
                activePulling = {
                    name = pending.name,
                    cleanName = cleanName(pending.name),
                    netid = pending.netid,
                    userid = pending.userid,
                    isAutopull = true,
                    direct = false
                }
                log(string.format("`2Trying `9To Pulling `w%s `9(`c%.2f `1DL `2>= `c%.2f `1DL`9)", Filter(pending.name), totalWL / 100, minModalWL / 100))
            else
                activePulling = nil
                startPull = nil
                log(string.format("`4Skipped `w%s `9(`c%.2f `1DL `4< `c%.2f `1DL`9)", Filter(pending.name), totalWL / 100, minModalWL / 100))
            end

            -- Hapus antrean & BLOCK dialog agar tidak muncul di layar client
            PendingModalPull[pendingKey] = nil


            return true
        end

        -- =========================================================
        -- 2. JIKA BUKAN AUTOPULL, TAPI SMODAL AKTIF (Manual Wrench / ViewInv)
        -- =========================================================
        if config.wrench.smodal == 1 then
            local name = dialog:match("big|(.+)'s Inventory``") or "Unknown"

            local wl = tonumber(dialog:match("staticframe|" .. const.itemId.wl .. "|(%d+)|")) or 0
            local dl = tonumber(dialog:match("staticframe|" .. const.itemId.dl .. "|(%d+)|")) or 0
            local bglInven = tonumber(dialog:match("staticframe|" .. const.itemId.bgl .. "|(%d+)|")) or 0
            local bglBank = tonumber(dialog:match("Blue Gem Locks in the Bank: `$(%d+)``")) or 0
            local black = tonumber(dialog:match("staticframe|" .. const.itemId.black .. "|(%d+)|")) or 0
            local champ = tonumber(dialog:match("staticframe|" .. const.itemId.champagne .. "|(%d+)|")) or 0
            local cc = tonumber(dialog:match("staticframe|" .. const.itemId.cc .. "|(%d+)|")) or 0

            local totalWL = wl + (dl * 100) + ((bglInven + bglBank) * 10000) + (black * 1000000)
            cache.autopull.dlPulled = totalWL / 100

            local locks = utils.convertLocksCount(totalWL)
            local msg
            if locks.wl == 0 and locks.dl == 0 and locks.bgl == 0 and locks.black == 0 then
                msg = "`0MISKUY DIE (" .. Filter(name) .. ") KGK ADA WL 1 PUN"
            else
                local ccText = (cc > 0) and (" `8CC: " .. cc) or ""
                msg = string.format("`0%s `aBLACK: %d `eBGL: %d `1DL: %d `9WL: %d `rCHAMPAGNE: %d%s", 
                    Filter(name), locks.black, locks.bgl, locks.dl, locks.wl, champ, ccText)
            end

            log(msg)
            sendOverlay(msg)

            -- BLOCK dialog karena smodal aktif
            return true
        end

        -- Jika BUKAN pending dan smodal == 0, biarkan lolos tanpa return true (dialog biasa akan muncul)
    end






    -- =========================================================
    -- HANDLER LOGGING VIA CONSOLE MESSAGE (THREAD-SAFE & AUTOPULL ONLY)
    -- =========================================================
    if var[0] == "OnConsoleMessage" and var[1]:find("`5pulls", 1, true) then
        local rawData = var[1]
        local rawPuller, rawPulled = rawData:match("(.-)pulls(.-)!")

        if rawPulled then
            local cPulled = cleanName(rawPulled)

            -- HANYA PROSES JIKA ACTIVE PULLING ADA & VALID DIPICU OLEH AUTOPULL
            if activePulling and activePulling.isAutopull then
                local currentTarget = activePulling -- Simpan referensi lokal
                
                if currentTarget.cleanName == cPulled 
                   or cPulled:find(currentTarget.cleanName, 1, true) 
                   or currentTarget.cleanName:find(cPulled, 1, true) then

                    -- Reset state segera agar tidak terpanggil ganda
                    activePulling = nil

                    -- BUNGKUS KE RUNTHREAD AGAR AMAN DARI C CALL CRASH (KARENA SLEEP/VARIANT)
                    RunThread(function()
                        local pulledTargetName = currentTarget.name

                        local elapsedTime = startPull and math.floor((os.clock() - startPull) * 1000) or 0
                        -- 1. Auto OFF Handling
                        if config.autopull.autooff == 1 then
                            config.autopull.scantile = 0
                            config.autopull.onspawn = 0
                            if type(saveConfig) == "function" then
                                saveConfig()
                            end
                            log(string.format("`2Successfully `9Pulled %s in `2%dms `8[Autopull To `4OFF``]", pulledTargetName, elapsedTime))
                        else
                            log(string.format("`2Successfully `9Pulled %s in `2%dms `8[Autopull Still Turned `2On``]", pulledTargetName, elapsedTime))
                        end

                        -- 2. Audio Notification Handling (Safe Async)
                        if config.autopull.notify == 1 then
                            local localNetID = GetLocal() and GetLocal().netid
                            if localNetID then
                                SendVariantList({
                                    [0] = "OnPlayPositioned",
                                    [1] = "audio/knock.wav"
                                }, localNetID)

                                Sleep(50) -- Safe inside RunThread

                                SendVariantList({
                                    [0] = "OnPlayPositioned",
                                    [1] = "audio/achievement.wav"
                                }, localNetID)
                            end
                        end
                    end)
                else
                    log(string.format("`4[Autopull] Mismatch Target! Expected: '%s' | Console: '%s'", currentTarget.cleanName, cPulled))
                end
            end
            -- Jika dipull manual / activePulling nil, script akan diam (tidak spam log error)
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
        category = "Roulette Wheel",
        command = "/reme",
        aliases = {},
        desc = "Shows Reme Number On Spin",
        icon = 660,
        argType = "none"
    })

    registerCommand({
        category = "Roulette Wheel",
        command = "/leme",
        aliases = {},
        desc = "Shows Leme Number On Spin",
        icon = 660,
        argType = "none"
    })

    registerCommand({
        category = "Roulette Wheel",
        command = "/qeme",
        aliases = {},
        desc = "Shows Qeme Number On Spin",
        icon = 660,
        argType = "none"
    })

    registerCommand({
        category = "Roulette Wheel",
        command = "/sspin",
        aliases = {},
        desc = "Only Shows Spin Number Without 'spun the wheel and got'",
        icon = 660,
        argType = "none"
    })

    registerCommand({
        category = "Roulette Wheel",
        command = "/lastspin",
        aliases = {
            "/lspin"
        },
        desc = "Shows Last Player Number Spin On Their Names",
        icon = 660,
        argType = "none"
    })

    registerCommand({
        category = "Autopull",
        command = "/autopull",
        aliases = {},
        desc = "Open Autopull Settings Menu Dialog",
        icon = 14824,
        argType = "none"
    })

    registerCommand({
        category = "Autopull",
        command = "/ap",
        aliases = {},
        desc = "Toggle OnSpawn Autopull",
        icon = 14824,
        argType = "none"
    })

    registerCommand({
        category = "Autopull",
        command = "/aps",
        aliases = {},
        desc = "Toggle Scan Tile Autopull",
        icon = 14824,
        argType = "none"
    })

    registerCommand({
        category = "Autopull",
        command = "/setap",
        aliases = {},
        desc = "Set Autopull Center Pos",
        icon = 14824,
        argType = "none"
    })

    registerCommand({
        category = "Autopull",
        command = "/min",
        aliases = {},
        desc = "Set Minimum Modal With Diamond Locks Currency",
        icon = 14824,
        argType = "required",
        usage = "[Dls Amount]"
    })

    registerCommand({
        category = "Autopull",
        command = "/blacklistall",
        aliases = {},
        desc = "Add All People In World To Autopull Blacklist",
        icon = 14824,
        argType = "none"
    })

    registerCommand({
        category = "Autopull",
        command = "/blacklist",
        aliases = {},
        desc = "Opens Blacklist Dialog Settings",
        icon = 14824,
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
    local url = "https://cdn.jsdelivr.net/gh/Lawvy3/lokiProxy@main/allowSyl"
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

    if config.autopull.scantile == 1 then
        ManageAreaPullThread()
    end

    local counts = getCommandsCount()

    log("`9Total Registered Commands Category: `2" .. counts.category)
    log("`9Total Registered Commands Aliases: `2" .. counts.aliases)
    log("`9Total Registered Commands: `2" .. counts.commands)

    RunThread(function()
        for _, player in pairs(GetPlayerList()) do
            if isProxyUser(player.userid) then
                set_player_rank(player.netid, "`2[P]")
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
