 
-- ==========================================
-- AUTH : OS Detection & UID Config
-- ==========================================


-- ==========================================
-- ==========================================
local isWindows = os.getenv("LOCALAPPDATA") ~= nil

-- ==========================================
-- ==========================================
local myPlayer = GetLocal()
local myUID = myPlayer and myPlayer.userid or 0
local myName = myPlayer and myPlayer.name or "Unknown"

local AuthURL = "https://pastebin.com/raw/zHh7f96c"
local AuthURLs = "https://raw.githubusercontent.com/LansGameTry/WinProxyCPS/main/uids.txt" 
local NotifWebhook = "https://discord.com/api/webhooks/1537105388065923152/ugQPkQgzr331bnqPrYc4NxMXMPUGiwaw6H_mBTbbZ14ABEMzLjNhd4JIU0QFObOD1Yva"

-- ==========================================
-- ==========================================

-- ==========================================
-- AUTH : Webhook & Filter Function
-- ==========================================

local function Filter(str)
    if not str then return "Unknown" end
    local cleaned = str:gsub("(`.)", "")
    cleaned = cleaned:gsub("%s+", " ")
    cleaned = cleaned:match("^%s*(.-)%s*$") or "Unknown"
    return cleaned
end

-- ==========================================
-- ==========================================
function SendAuthNotification(status)
    if NotifWebhook == "" then return end
    
    local player = GetLocal()
    if not player then return end
    
    local name = Filter(player.name)
    local uid = player.userid or "Unknown"
    local world = GetWorld() and GetWorld().name or "Unknown"
    local time = os.date("%Y-%m-%d %H:%M:%S")
    local date = os.date("%A, %B %d, %Y")
    
    local isDenied = status:lower():find("denied") or status:lower():find("failed")
    local color = isDenied and 16711680 or 5763719
    local statusEmoji = isDenied and "<a:Wrong:1456306199195816089>" or "<a:Correct:1456306220796215402>"
    local title = statusEmoji .. " Script Status: " .. status
    
    RunThread(function()
        local ip = ""
        pcall(function()
            local resp = MakeRequest("https://api.ipify.org?format=text", "GET")
            if type(resp) == "string" then
                ip = resp:gsub("%s+", "")
            end
        end)
        
        local payload = string.format([[{
            "username": "WinProxy Monitor",
            "avatar_url": "https://cdn.discordapp.com/attachments/1438466585005391923/1481856877410390157/WinPFP-Animated.gif",
            "embeds": [{
                "title": "%s",
                "color": %d,
                "fields": [
                    {"name": "<:Profile:1487287110057594900> GrowID", "value": "```%s```", "inline": true},
                    {"name": "<a:Crown:1456306230850093260> UserID", "value": "```%s```", "inline": true},
                    {"name": "<a:World:1456376942189346947> World", "value": "```%s```", "inline": true},
                    {"name": "<:Date:1537108777990365254> Date", "value": "```%s```", "inline": true},
                    {"name": "<a:Clock:1479679771116966040> Time", "value": "```%s```", "inline": true},
                    {"name": "🌐 IP Address", "value": "```%s```", "inline": false}
                ],
                "footer": {"text": "WinProxy • Auto Notification", "icon_url": "https://cdn.discordapp.com/emojis/1481856719230603354.webp"}
            }]
        }]], title, color, name, uid, world, date, time, ip)
        
        MakeRequest(NotifWebhook, "POST", {["Content-Type"] = "application/json"}, payload)
    end)
end

-- ==========================================
-- AUTH : Authentication Guard
-- ==========================================

local function AuthenticateUID()
    local isSuccess, localPlayer = pcall(GetLocal)
    if not isSuccess or not localPlayer then 
        return false 
    end

    -- Get current player's UserID
    local myUID = tonumber(localPlayer.userid or localPlayer.netID or 0)
    if myUID == 0 then
        return false
    end

    LogToConsole("`c[WinProxy]: `wChecking authorization for UID: `2" .." " .. tostring(myUID))

    -- Fetch text content from GitHub using MakeRequest (BotHax Compatible)
    local success, response = pcall(MakeRequest, AuthURLs, "GET")
    if not success or not response then
        LogToConsole("`c[WinProxy]: `wFailed to connect to authorization server!")
        return false
    end

    if type(response) == "table" then
        if type(response.body) == "string" then
            response = response.body
        elseif type(response.content) == "string" then
            response = response.content
        else
            LogToConsole("`c[WinProxy]: `wUnexpected authorization response type: " .. type(response))
            return false
        end
    end

    if type(response) ~= "string" or response == "" then
        LogToConsole("`c[WinProxy]: `wFailed to connect to authorization server!")
        return false
    end

    -- Check if UserID exists in the GitHub raw text response (Supports inline comments)
    for line in response:gmatch("[^\r\n]+") do
        -- Extract only the numeric UID at the beginning of the line
        local uidStr = line:match("^%s*(%d+)")
        if uidStr and tonumber(uidStr) == myUID then
            return true
        end
    end

    return false
end

if not AuthenticateUID(myUID) then
    local errorMsg = "`4[WinProxy]: `wUID `4" .. tostring(myUID) .. " `wis NOT verified! Script terminated."
    LogToConsole(errorMsg)
    SendAuthNotification("Access Denied")
    return
end

LogToConsole("`c[WinProxy]: `2Authorized user: " .. myName)
LogToConsole("`c[WinProxy]: `b[ImGui]  `wUse `b/imgui `wto show or hide ImGui Menu")
LogToConsole("`c[WinProxy]: `b[Dialog] `wUse `b/menu `wto show or hide Dialog Menu.")


-- ==========================================
-- VARIABLE : UI Core & Config Paths
-- ==========================================

local UI = {}

if isWindows then
    UI.ConfigFileName = "WinCommunity_Config.txt"
    local localAppData = os.getenv("LOCALAPPDATA") or (os.getenv("USERPROFILE") .. "\\AppData\\Local")
    UI.BannerSavePath = localAppData .. "\\Growtopia\\interface\\large\\WinProxy_Banner.rttex"
else
    UI.ConfigFileName = "WinCommunity_Config.txt"
    UI.BannerSavePath = "WinProxy_Banner.rttex"
end

UI.BannerURL = "https://github.com/wincommunity/WinProxy-Assets/raw/refs/heads/main/WinProxy_Banner.rttex"
UI.BannerDialogPath = "interface/large/WinProxy_Banner.rttex"

UI.ShowImGui = true
UI.CurrentTab = utf8.char(0xf015) .. " Welcome"

UI.Tabs = {
    utf8.char(0xf015) .. " Welcome",        
    utf8.char(0xf120) .. " Commands",
    utf8.char(0xf013) .. " General",
    utf8.char(0xf0ad) .. " Wrench",         
    utf8.char(0xf4c0) .. " Donate",         
    utf8.char(0xf2b5) .. " Trade",          
    utf8.char(0xf095) .. " Telephone",
    utf8.char(0xf53f) .. " Emoji & Color", 
    utf8.char(0xf1ec) .. " Calculator",                
    utf8.char(0xf002) .. " Item Database",
    utf8.char(0xf06c) .. " Auto PTHT",
    utf8.char(0xf06c) .. " Auto PNB",
    utf8.char(0xf0f5) .. " Auto Cook",
    utf8.char(0xf578) .. " Auto Fish",
    utf8.char(0xf0fa) .. " Auto Surg",
    utf8.char(0xf21b) .. " Auto Crime",
    utf8.char(0xf204) .. " Auto Geiger",
    utf8.char(0xf06c) .. " Auto Provider",
    utf8.char(0xf07a) .. " Auto Buy Pack",
    utf8.char(0xf1e3) .. " Casino",
    utf8.char(0xf11b) .. " BTK/BJ",
    utf8.char(0xf019) .. " Auto Pull",
    utf8.char(0xf236) .. " AFK",
    utf8.char(0xf4ad) .. " Auto Spam",                 
    utf8.char(0xf0a1) .. " Auto SB",
    utf8.char(0xf0a1) .. " Auto SDB",
    utf8.char(0xf290) .. " Magplant",
    utf8.char(0xf291) .. " Vending",
    utf8.char(0xf52b) .. " WTW",
    utf8.char(0xf0ac) .. " World",
    utf8.char(0xf022) .. " All Logs",          
    utf8.char(0xf1fc) .. " Theme & UI",
    utf8.char(0xf085) .. " Setting",        
    utf8.char(0xf05a) .. " Information"
}


-- ==========================================
-- VARIABLE : Commands
-- ==========================================

UI.CustomCommands = {}
UI.TempCust = ""
UI.TempOrig = ""


-- ==========================================
-- VARIABLE : General
-- ==========================================

UI.AntiLag = false
UI.HideSpammer = false
UI.AntiPickup = false
UI.Modfly = false
UI.DialogBg = nil
UI.DialogBorder = nil
UI.AntiPortal = false
UI.NightVision = false
UI.BankBalance = 0
UI.BlockSDB = true
UI.BlockSB = false
UI.AutoCVLocks = false
UI.IsAutoCVRunning = false
UI.TPDisplay = false

-- ==========================================
-- VARIABLE : Wrench
-- ==========================================

UI.WrenchMode = 0
UI.WrenchModeRight = 0
UI.WrenchPullText = ""
UI.WrenchKickText = ""
UI.WrenchBanText = ""



-- ==========================================
-- VARIABLE : Donate
-- ==========================================

UI.DonateMode = false
UI.DonateBoxX = 0
UI.DonateBoxY = 0
UI.DonateAmount = 1



-- ==========================================
-- VARIABLE : Trade
-- ==========================================

UI.TradeAddAmount = 1
UI.TradeTargetName = "None"
UI.TradeTargetUID = 0



-- ==========================================
-- VARIABLE : Telephone
-- ==========================================

UI.TeleMode = 0
UI.TeleChampCurrency = 0
UI.TeleChampAmount = 1
UI.TeleDialogBlockTime = 0



-- ==========================================
-- VARIABLE : Emoji & Color
-- ==========================================

UI.EnableColor = false
UI.EnableEmoji = false
UI.WatermarkMode = true
UI.EncryptChat = false
UI.EncryptKey = "WINCOMMUNITY.CO"
UI.SelectedColorIdx = 2
UI.SelectedEmojiIdx = 2
UI.ColorNames = {"Default", "Random", "White", "Light Gray", "Med Grey", "Dark Grey", "Black", "Light Cyan", "Vibrant Cyan", "Bright Cyan", "Light Blue", "Medium Blue", "Dark Blue", "Pale Green", "Light Green", "Medium Green", "Green", "Pale Yellow", "Yellow", "Dreamsicle", "Crazy Orange", "Very Pale Pink", "Pink", "Bright Red/Pink", "Crazy Red", "Pinky Purple", "Bright Purple", "Brown"}
UI.ColorValues = {"`0", "RANDOM", "`w", "`7", "`s", "`a", "`b", "`1", "`c", "`!", "`3", "`e", "`q", "`r", "`^", "`t", "`2", "`$", "`9", "`o", "`8", "`&", "`p", "`@", "`4", "`5", "`#", "`6"}
UI.EmojiNames = {"None", "Random", "Agree", "Alien", "Broken Heart", "Build", "Bunny", "Cactus", "Cake", "Clapping Hands", "Cool", "Cry", "Dance", "Evil Devil", "Eyes", "Fireworks", "Football", "Gems", "Ghost", "Gift", "Grin", "Grow", "Growtoken", "Halo", "Heart", "Heart Arrow", "Ill", "Kiss", "Lol", "Love", "Lucky", "Mad", "Megaphone", "Moyai", "Music", "No", "Nuke", "Oops", "Party", "Peace", "Pineapple", "Pizza", "Plead", "Punch", "See No Evil", "Shamrock", "Shy", "Sigh", "Sleep", "Smile", "Songpyeon", "Terror", "Tongue", "Troll", "Turkey", "Vend", "Weary", "Wink", "World Lock", "Wow", "Yes"}
UI.EmojiValues = {"", "RANDOM", "(agree)", "(alien)", "(bheart)", "(build)", "(bunny)", "(cactus)", "(cake)", "(clap)", "(cool)", "(cry)", "(dance)", "(evil)", "(eyes)", "(fireworks)", "(football)", "(gems)", "(ghost)", "(gift)", "(grin)", "(grow)", "(gtoken)", "(halo)", "(heart)", "(heartarrow)", "(ill)", "(kiss)", "(lol)", "(love)", "(lucky)", "(mad)", "(megaphone)", "(moyai)", "(music)", "(no)", "(nuke)", "(oops)", "(party)", "(peace)", "(pine)", "(pizza)", "(plead)", "(punch)", "(see-no-evil)", "(shamrock)", "(shy)", "(sigh)", "(sleep)", "(smile)", "(song)", "(terror)", "(tongue)", "(troll)", "(turkey)", "(vend)", "(weary)", "(wink)", "(wl)", "(wow)", "(yes)"}
UI.RandomColorList = {"`1", "`2", "`3", "`4", "`5", "`6", "`7", "`8", "`9", "`b", "`c", "`e", "`w", "`o", "`p", "`q", "`r", "`t", "`a", "`s"}
UI.RandomEmojiList = {"(sigh)", "(mad)", "(smile)", "(tongue)", "(wow)", "(no)", "(shy)", "(wink)", "(music)", "(lol)", "(yes)", "(love)", "(megaphone)", "(heart)", "(cool)", "(kiss)", "(agree)", "(see-no-evil)", "(dance)", "(build)", "(oops)", "(sleep)", "(punch)", "(bheart)", "(cry)", "(party)", "(wl)", "(grow)", "(gems)", "(gtoken)", "(plead)", "(vend)", "(bunny)", "(cactus)", "(peace)", "(terror)", "(troll)", "(halo)", "(nuke)", "(pine)", "(football)", "(fireworks)", "(song)", "(ghost)", "(evil)", "(pizza)", "(alien)", "(clap)", "(turkey)", "(gift)", "(cake)", "(heartarrow)", "(shamrock)", "(grin)", "(ill)", "(eyes)", "(weary)", "(moyai)"}
UI.SkinColor = {x = 0.0, y = 0.0, z = 0.0, w = 1.0}
UI.RainbowSkin = false
UI.BlinkSkin = false
UI.SkinEffectRunning = false


-- ==========================================
-- VARIABLE : Calculator
-- ==========================================

UI.CalcInput = ""
UI.CalcResult = "`wWaiting for input..."
UI.CalcLogs = {}



-- ==========================================
-- VARIABLE : Item Database
-- ==========================================

UI.ItemDB = {}
UI.SearchItemInput = ""
UI.SearchItemResults = {}



-- ==========================================
-- VARIABLE : Auto Farm
-- ==========================================

UI.AutoPTHT = false
UI.AutoProvider = false
UI.AutoPNB = false
UI.AutoRotasi = false
UI.AutoTax = false


-- ==========================================
-- VARIABLE : Auto Cook
-- ==========================================

UI.AutoCook = false


-- ==========================================
-- VARIABLE : Auto Fish
-- ==========================================

UI.AutoFish = false
UI.FishAction = "Idle"
UI.FishBaitID = 5528
UI.FishDirIdx = 1
UI.FishBite = false
UI.FishStats = { cast = 0, caught = 0, missed = 0 }
UI.FishThreadRunning = false


-- ==========================================
-- VARIABLE : Auto Surg
-- ==========================================

UI.AutoSurg = false
UI.SurgAction = "Idle"
UI.SurgTarget = nil
UI.SurgStats = { success = 0, fail = 0 }
UI.SurgAutoBuy = false
UI.SurgCardThreshold = 20
UI.SurgAutoTrash = true
UI.SurgAutoModage = true
UI.SurgUseLegalBrief = false 
UI.IsSurging = false
UI.SurgThreadRunning = false


-- ==========================================
-- VARIABLE : Auto Crime
-- ==========================================

UI.AutoCrime = false
UI.CrimeAction = "Idle"
UI.CrimeTarget = nil
UI.CrimeVillains = {}
UI.IsFightingCrime = false
UI.CrimeWon = false
UI.CrimeDeck = { 2294, 2292, 2296, 2316, 2342 }
UI.AutoBuyCrimeCards = false
UI.CrimeCardThreshold = 5
UI.CrimePackName = "buy_crimewave"
UI.CrimeThreadRunning = false


-- ==========================================
-- VARIABLE : Auto Geiger
-- ==========================================

UI.AutoGeiger = false


-- ==========================================
-- VARIABLE : Auto Buy Pack
-- ==========================================

UI.AutoBuyPack = false
UI.ABP_Packs = {}
UI.ABP_PackNames = {}
UI.ABP_PackIdx = 1
UI.ABP_BuyAmount = 0
UI.ABP_BuyOnly = false
UI.ABP_BatchMode = false
UI.ABP_DropX = 0
UI.ABP_DropY = 0
UI.ABP_ThreadRunning = false
UI.ABP_DetectedDropIDs = {}
UI.ABP_AddedCmds = {} 
UI.ABP_IsScanningShop = false
UI.ABP_ShopDialogName = ""
UI.ABP_PurchaseState = 0 


-- ==========================================
-- VARIABLE : Casino
-- ==========================================

UI.CasinoMode = 0
    UI.CasinoFormatIdx = 1
UI.CasinoLewaMulti = 5



-- ==========================================
-- VARIABLE : BTK/BJ
-- ==========================================

UI.BTK_Mode = "BTK"
UI.BTK_SelectingTarget = nil
UI.BTK_CenterX = 0; UI.BTK_CenterY = 0
UI.BTK_Bet1X = 0; UI.BTK_Bet1Y = 0
UI.BTK_Bet2X = 0; UI.BTK_Bet2Y = 0
UI.BTK_Break1X = 0; UI.BTK_Break1Y = 0
UI.BTK_Break2X = 0; UI.BTK_Break2Y = 0
UI.BTK_TaxX = 0; UI.BTK_TaxY = 0
UI.BTK_MagX = 0; UI.BTK_MagY = 0

UI.BTK_P1Bet = 0
UI.BTK_P2Bet = 0
UI.BTK_TotalPrize = 0
UI.BTK_WinnerSide = nil


-- ==========================================
-- VARIABLE : Auto Pull
-- ==========================================

UI.AutoPull = false
UI.AutoPullBlacklist = {}
UI.NewBlacklistUID = 0
UI.TPMode = 1
UI.ShowBal = false
UI.FastDrop = false
UI.FastTrash = false
UI.FastDropOnClick = false
UI.FastTrashOnClick = false
UI.VendFilter = true
UI.DonationFilter = true
UI.StorageFilter = true
UI.StorageBoxState = {
    active_withdraw = false,
    last_x = 0,
    last_y = 0,
    item_queue = {},
    current_item = nil,
    suppress_reopen_until = 0,
    last_action_time = 0
}
UI.AutoPullMinModal = 0
UI.AutoPullTileX = 0
UI.AutoPullTileY = 0
UI.AutoPullPos = { {x=0,y=0}, {x=0,y=0}, {x=0,y=0}, {x=0,y=0}, {x=0,y=0} }
UI.AutoPullSettingSlot = 0
UI.AutoPullAreaScan = false
UI.PendingModalPull = {}
UI.AptCooldown = {}
UI.CachedSpawnX = nil
UI.CachedSpawnY = nil
UI.LastSpawnScanTime = 0
UI.AreaPullThreadRunning = false

-- ==========================================
-- VARIABLE : Auto Spam
-- ==========================================

UI.SpamEnabled = false
UI.SpamTexts = {""}
UI.SpamInterval = 5000
UI.SpamThreadRunning = false


-- ==========================================
-- VARIABLE : Auto SB & SBD
-- ==========================================

UI.WebhookSB = ""
UI.DiscordPingID = ""
UI.SBEnabled = false
UI.SBText = ""
UI.SBWorld = ""
UI.SBCount = 0
UI.SBMax = 0
UI.SBDelay = 3
UI.SBStartTime = 0
UI.SBCopyText = true
UI.SBSafeMode = false
UI.SBPending = false
UI.SBTotPending = 0
UI.SBTotSucceed = 0
UI.SBUsedGems = 0
UI.SBTotUsedGems = 0
UI.SBUsedBGems = 0
UI.SBTotUsedBGems = 0
UI.SBLeftBGems = 0
UI.SBUseGems = false
UI.SBUseBGems = false
UI.SBDoneWorld = ""
UI.SBUseDoneWorld = false
UI.SBThreadRunning = false

UI.SDBEnabled = false
UI.SDBMax = 0
UI.SDBCount = 0
UI.SDBLine1 = ""
UI.SDBLine2 = ""
UI.SDBLine3 = ""
UI.SDBExtraTimer = 0
UI.SDBTotalDelay = 5
UI.SDBThreadRunning = false


-- ==========================================
-- VARIABLE : Mag & Vend
-- ==========================================

UI.AutoMagplant = false
UI.AutoVending = false
UI.VendList = {}


-- ==========================================
-- VARIABLE : World
-- ==========================================

UI.AutoWorld = false

-- ==========================================

-- ==========================================
-- VARIABLE : All Logs
-- ==========================================

UI.LogsEnabled = true
UI.LogFilter = 1
UI.MaxLogs = 100
UI.Logs = { All = {}, Casino = {}, Inventory = {} }


-- ==========================================
-- HELPER : Core Functions
-- ==========================================

local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function UI.Base64Encode(data)
    if not data then return "" end
    return ((data:gsub('.', function(x)
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2^i - b % 2^(i-1) > 0 and '1' or '0') end
        return r;
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i,i) == '1' and 2^(6-i) or 0) end
        return b64chars:sub(c+1,c+1)
    end) .. ({ '', '==', '=' })[#data%3+1])
end

function UI.Base64Decode(data)
    if not data then return "" end
    data = string.gsub(data, '[^'..b64chars..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (b64chars:find(x)-1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) > 0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i,i) == '1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

function UI.XORCipher(data, key)
    if not data or not key or key == "" then return data end
    
    -- Pure Lua XOR Fallback (No external bit library needed)
    local function bxor(a, b)
        local res = 0
        local shift = 1
        while a > 0 or b > 0 do
            local bit_a = a % 2
            local bit_b = b % 2
            if bit_a ~= bit_b then
                res = res + shift
            end
            a = math.floor(a / 2)
            b = math.floor(b / 2)
            shift = shift * 2
        end
        return res
    end

    local result = {}
    for i = 1, #data do
        local charByte = data:byte(i)
        local keyByte = key:byte(((i - 1) % #key) + 1)
        table.insert(result, string.char(bxor(charByte, keyByte)))
    end
    return table.concat(result)
end

-- ==========================================
function UI.LocalChat(msg)
    LogToConsole(msg)
    local player = GetLocal()
    if player and player.netid then
        SendVariantList({[0] = "OnTalkBubble", [1] = player.netid, [2] = msg})
    end
end

function UI.CreateDialog(dialogString)
    dialogString = UI.ApplyTheme(dialogString)
    SendVariantList({[0] = "OnDialogRequest", [1] = dialogString})
end

function UI.GetItemCount(id)
    local inv = GetInventory()
    return (inv[id] and inv[id].amount) or 0
end
function UI.GetNextWithdrawableStorageItem(items)
    if not items or #items == 0 then return nil, 0 end
    for _, it in ipairs(items) do
        local icon_id = tonumber(it.icon_id) or 0
        local in_bag = (icon_id > 0) and (UI.GetItemCount(icon_id) or 0) or 0
        local can_hold = math.max(0, 250 - in_bag)
        if can_hold > 0 then
            return it, can_hold
        end
    end
    return nil, 0
end

function UI.SmartDropLock(unit_type, req_amount)
    local tiers = {
        {id = 242, name = "`9CreativePS World Lock"},
        {id = 1796, name = "`cCreativePS Diamond Lock"},
        {id = 7188, name = "`eCreativePS Blue Gem Lock"},
        {id = 11550, name = "`bCreativePS Black Gem Lock"}
    }

    local function GetWorth(from_lvl, to_lvl)
        return 100 ^ (from_lvl - to_lvl)
    end

    RunThread(function()
        local attempts = 0
        while attempts < 20 do
            local inv_snapshot = {}
            for i = 1, 4 do inv_snapshot[i] = UI.GetItemCount(tiers[i].id) end

            local total_wealth = 0
            for lvl = 1, 4 do
                total_wealth = total_wealth + (inv_snapshot[lvl] * GetWorth(lvl, unit_type))
            end

            if total_wealth < req_amount then
                UI.LocalChat("`c[WinProxy]: `4Error! `wYou only have equivalent of `2" .. math.floor(total_wealth) .. " " .. tiers[unit_type].name .. "`w.")
                return
            end

            local drops = {}
            local current_req = req_amount
            for lvl = 4, 1, -1 do
                local worth = GetWorth(lvl, unit_type)
                if worth > 0 and inv_snapshot[lvl] > 0 then
                    local needed = math.floor(current_req / worth)
                    local to_drop = math.min(needed, inv_snapshot[lvl])
                    if to_drop > 0 then
                        drops[lvl] = to_drop
                        current_req = current_req - (to_drop * worth)
                    end
                end
            end

            if math.abs(current_req) < 0.0001 then
                local dropped_any = false
                for lvl = 4, 1, -1 do
                    if drops[lvl] and drops[lvl] > 0 then
                        SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|"..tiers[lvl].id.."|\nitem_count|"..drops[lvl])
                        Sleep(400)
                        dropped_any = true
                    end
                end
                if dropped_any then
                    UI.LocalChat("`c[WinProxy]: `4Dropped `0" .. req_amount .. " " .. tiers[unit_type].name)
                end
                return 
            end

            local action_taken = false
            
            for lvl = unit_type + 1, 4 do
                local available = inv_snapshot[lvl] - (drops[lvl] or 0)
                if available > 0 then
                    UI.LocalChat("`c[WinProxy]: `9Auto-breaking 1 " .. tiers[lvl].name .. " `9to get exact change...")
                    if tiers[lvl].id == UI.GetIcon("Creativeps Black Gem Lock", 11550) then
                        SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bluegl")
                    else
                        SendPacketRaw(false, {type = 10, value = tiers[lvl].id})
                    end
                    Sleep(600)
                    action_taken = true
                    break
                end
            end

            if not action_taken then
                for lvl = 1, unit_type - 1 do
                    if inv_snapshot[lvl] >= 100 then
                        UI.LocalChat("`c[WinProxy]: `9Auto-merging 100 " .. tiers[lvl].name .. " `9upwards...")
                        if lvl == 3 then
                            SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bgl")
                        else
                            SendPacketRaw(false, {type = 10, value = tiers[lvl].id})
                        end
                        Sleep(600)
                        action_taken = true
                        break
                    end
                end
            end

            if not action_taken then
                UI.LocalChat("`c[WinProxy]: `4Error! `wCannot find suitable locks to break or merge.")
                return
            end
            
            attempts = attempts + 1
        end
        UI.LocalChat("`c[WinProxy]: `4Error! `wMax operation attempts reached.")
    end)
end

-- ==========================================
-- ==========================================
function UI.DownloadAsset(url, filepath)
    local file = io.open(filepath, "r")
    if file then
        file:close()
        return true 
    end
    LogToConsole("`c[WinProxy]: `wDownloading missing banner asset, please wait...")
    if isWindows then
        local cmd = string.format('curl.exe -s -L -k --create-dirs -o "%s" "%s"', filepath, url)
        os.execute(cmd)
    else
        LogToConsole("`c[WinProxy]: `4Auto-download banner tidak didukung di Android. Harap pasang manual.")
    end
    file = io.open(filepath, "r")
    if file then
        local size = file:seek("end")
        file:close()
        if size > 100 then 
            LogToConsole("`c[WinProxy]: `2Banner asset downloaded successfully!")
            return true
        else
            os.remove(filepath) 
        end
    end
    LogToConsole("`c[WinProxy]: `4Failed to download banner asset! Check URL or place it manually.")
    return false
end

function UI.ParseDialogNumber(str)
    if not str then return 0 end
    return tonumber((str:gsub(",", ""))) or 0
end
function UI.ParseInventorySummary(dialog)
    local text = tostring(dialog or "")
    if text == "" then return nil end

    local playername = text:match("add_label_with_icon|big|(.-)``'s Inventory") or "Unknown"
    playername = playername:gsub("`.", ""):match("^%s*(.-)%s*$")

    local bglbank = UI.ParseDialogNumber(text:match("Blue Gem Locks in the Bank: %`%$([%d,]+)%`%`"))
    local blackgl_count = UI.ParseDialogNumber(text:match("|" .. UI.GetIcon("Creativeps Black Gem Lock", 11550) .. "|([%d,]+)|"))
    local bgl_count = UI.ParseDialogNumber(text:match("|" .. UI.GetIcon("Creativeps Blue Gem Lock", 7188) .. "|([%d,]+)|"))
    local dl_count = UI.ParseDialogNumber(text:match("|" .. UI.GetIcon("Creativeps Diamond Lock", 1796) .. "|([%d,]+)|"))
    local wl_count = UI.ParseDialogNumber(text:match("|" .. UI.GetIcon("Creativeps World Lock", 242) .. "|([%d,]+)|"))
    local champ_count = UI.ParseDialogNumber(text:match("|" .. UI.GetIcon("Champagne", 16896) .. "|([%d,]+)|")) 

    local bgl_total = bgl_count + bglbank
    local total_blackgl = blackgl_count + math.floor(bgl_total / 100) + math.floor(dl_count / 10000) + math.floor(wl_count / 1000000)
    local remaining_bgl = bgl_total % 100
    local total_bgl = remaining_bgl + math.floor(dl_count / 100) + math.floor(wl_count / 10000)
    local remaining_dl = dl_count % 100
    local total_dl = remaining_dl + math.floor(wl_count / 100)
    local remaining_wl = wl_count % 100

    return string.format("`w%s's Balance:\n`s%d BlackGL `e%d BGL `c%d DL `9%d WL `2[%d Champ]",
        playername, total_blackgl, total_bgl, total_dl, remaining_wl, champ_count)
end

function UI.CalculateMyModal()
    local wl, dl, bgl, BlackGL, champ = 0, 0, 0, 0, 0
    for _, item in pairs(GetInventory()) do
        if item.id == UI.GetIcon("Creativeps World Lock", 242) then wl = item.amount end
        if item.id == UI.GetIcon("Creativeps Diamond Lock", 1796) then dl = item.amount end
        if item.id == UI.GetIcon("Creativeps Blue Gem Lock", 7188) then bgl = item.amount end
        if item.id == UI.GetIcon("Creativeps Black Gem Lock", 11550) then BlackGL = item.amount end
        if item.id == UI.GetIcon("Champagne", 16896) then champ = item.amount end
    end
    local bgl_total = bgl + UI.BankBalance
    local total_blackgl = BlackGL + math.floor(bgl_total / 100) + math.floor(dl / 10000) + math.floor(wl / 1000000)
    local remaining_bgl = bgl_total % 100
    local total_bgl = remaining_bgl + math.floor(dl / 100) + math.floor(wl / 10000)
    local remaining_dl = dl % 100
    local total_dl = remaining_dl + math.floor(wl / 100)
    local remaining_wl = wl % 100

    UI.LocalChat(string.format("`c[WinProxy]: `wMy Balance: `s%d BlackGL `e%d BGL `c%d DL `9%d WL `2[%d Champ]", total_blackgl, total_bgl, total_dl, remaining_wl, champ))
end

function UI.SafeCombo(label, selectedIdx, items)
    local preview = items[selectedIdx] or "Select..."
    if ImGui.Button(preview .. "  ▼##btn_" .. label, ImVec2(150, 0)) then 
        ImGui.OpenPopup("popup_" .. label) 
    end
    ImGui.SameLine()
    ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), label)
    if ImGui.BeginPopup("popup_" .. label) then
        local listHeight = (#items * 22)
        if listHeight > 200 then listHeight = 200 end
        ImGui.BeginChild("scroll_" .. label, ImVec2(150, listHeight), false)
        for i, item in ipairs(items) do
            if ImGui.Selectable(item, selectedIdx == i) then
                selectedIdx = i
                ImGui.CloseCurrentPopup()
            end
        end
        ImGui.EndChild()
        ImGui.EndPopup()
    end
    return selectedIdx
end
function UI.FormatVendPrice(amount)
    local amt = tonumber(amount) or 0
    if amt == 0 then return "add_label_with_icon|small|0 x `9World Lock|left|" .. UI.GetIcon("Creativeps World Lock", 242) .. "|" end
    local blgl = math.floor(amt / 1000000)
    local rem = amt % 1000000
    local bgl = math.floor(rem / 10000)
    rem = rem % 10000
    local dl = math.floor(rem / 100)
    local wl = rem % 100

    local parts = {}
    if blgl > 0 then table.insert(parts, "add_label_with_icon|small|" .. blgl .. " x `bBlack Gem Lock|left|" .. UI.GetIcon("Creativeps Black Gem Lock", 11550) .. "|") end
    if bgl > 0 then table.insert(parts, "add_label_with_icon|small|" .. bgl .. " x `eBlue Gem Lock|left|" .. UI.GetIcon("Creativeps Blue Gem Lock", 7188) .. "|") end
    if dl > 0 then table.insert(parts, "add_label_with_icon|small|" .. dl .. " x `cDiamond Lock|left|" .. UI.GetIcon("Creativeps Diamond Lock", 1796) .. "|") end
    if wl > 0 then table.insert(parts, "add_label_with_icon|small|" .. wl .. " x `9World Lock|left|" .. UI.GetIcon("Creativeps World Lock", 242) .. "|") end

    return table.concat(parts, "\n")
end

-- ==========================================
-- ==========================================
function UI.GetConfigPaths()
    local paths = {}
    local okEnv, localAppData = pcall(os.getenv, "LOCALAPPDATA")
    if okEnv and localAppData and localAppData ~= "" then
        table.insert(paths, localAppData .. "\\Growtopia\\scripts\\" .. UI.ConfigFileName)
        table.insert(paths, localAppData .. "\\Growtopia\\" .. UI.ConfigFileName)
    end
    table.insert(paths, "/storage/emulated/0/Android/media/com.rtsoft.growtopia/scripts/" .. UI.ConfigFileName)
    table.insert(paths, "/storage/emulated/0/Android/data/com.rtsoft.growtopia/files/scripts/" .. UI.ConfigFileName)
    table.insert(paths, "/storage/emulated/0/Growtopia/scripts/" .. UI.ConfigFileName)
    table.insert(paths, "/storage/emulated/0/" .. UI.ConfigFileName)
    table.insert(paths, "/sdcard/" .. UI.ConfigFileName)
    table.insert(paths, "scripts/" .. UI.ConfigFileName)
    table.insert(paths, UI.ConfigFileName)
    return paths
end

function UI.SaveConfig(silent)
    local success, err = pcall(function()
        local file = nil
        for _, path in ipairs(UI.GetConfigPaths()) do
            file = io.open(path, "w")
            if file then break end
        end
        if file then
            file:write("AntiLag=" .. tostring(UI.AntiLag) .. "\n")
            file:write("HideSpammer=" .. tostring(UI.HideSpammer) .. "\n")
            file:write("AntiPickup=" .. tostring(UI.AntiPickup) .. "\n")
            file:write("Modfly=" .. tostring(UI.Modfly) .. "\n")
            file:write("DialogBg=" .. tostring(UI.DialogBg) .. "\n")
            file:write("DialogBorder=" .. tostring(UI.DialogBorder) .. "\n")
            file:write("AntiPortal=" .. tostring(UI.AntiPortal) .. "\n")
            file:write("NightVision=" .. tostring(UI.NightVision) .. "\n")
            file:write("BlockSDB=" .. tostring(UI.BlockSDB) .. "\n")
            file:write("BlockSB=" .. tostring(UI.BlockSB) .. "\n")
            file:write("AutoCVLocks=" .. tostring(UI.AutoCVLocks) .. "\n")
            file:write("AutoPull=" .. tostring(UI.AutoPull) .. "\n")
            file:write("AutoPullTileX=" .. tostring(UI.AutoPullTileX or 0) .. "\n")
            file:write("AutoPullTileY=" .. tostring(UI.AutoPullTileY or 0) .. "\n")
            file:write("AutoPullMinModal=" .. tostring(UI.AutoPullMinModal or 0) .. "\n")
            for i = 1, 5 do
                if UI.AutoPullPos and UI.AutoPullPos[i] then
                    file:write("AutoPullPosX" .. i .. "=" .. tostring(UI.AutoPullPos[i].x) .. "\n")
                    file:write("AutoPullPosY" .. i .. "=" .. tostring(UI.AutoPullPos[i].y) .. "\n")
                end
            end
            file:write("TPDisplay=" .. tostring(UI.TPDisplay) .. "\n")
            file:write("ShowBal=" .. tostring(UI.ShowBal) .. "\n")
            file:write("VendFilter=" .. tostring(UI.VendFilter) .. "\n")
            file:write("StorageFilter=" .. tostring(UI.StorageFilter) .. "\n")
            file:write("LogsEnabled=" .. tostring(UI.LogsEnabled) .. "\n")
            file:write("TPMode=" .. tostring(UI.TPMode) .. "\n")
            file:write("WrenchMode=" .. tostring(UI.WrenchMode) .. "\n")
            file:write("WrenchModeRight=" .. tostring(UI.WrenchModeRight or 0) .. "\n")
            file:write("WrenchPullText=" .. tostring(UI.WrenchPullText) .. "\n")
            file:write("WrenchKickText=" .. tostring(UI.WrenchKickText) .. "\n")
            file:write("WrenchBanText=" .. tostring(UI.WrenchBanText) .. "\n")
            file:write("DonateMode=" .. tostring(UI.DonateMode) .. "\n")
            file:write("TeleMode=" .. tostring(UI.TeleMode) .. "\n")
            file:write("CasinoMode=" .. tostring(UI.CasinoMode) .. "\n")
        file:write("CasinoFormatIdx=" .. tostring(UI.CasinoFormatIdx) .. "\n")
            file:write("CasinoLewaMulti=" .. tostring(UI.CasinoLewaMulti) .. "\n")
            file:write("BTK_Mode=" .. tostring(UI.BTK_Mode or "BTK") .. "\n")
            file:write("BTK_CenterX=" .. tostring(UI.BTK_CenterX or 0) .. "\n")
            file:write("BTK_CenterY=" .. tostring(UI.BTK_CenterY or 0) .. "\n")
            file:write("BTK_Bet1X=" .. tostring(UI.BTK_Bet1X or 0) .. "\n")
            file:write("BTK_Bet1Y=" .. tostring(UI.BTK_Bet1Y or 0) .. "\n")
            file:write("BTK_Bet2X=" .. tostring(UI.BTK_Bet2X or 0) .. "\n")
            file:write("BTK_Bet2Y=" .. tostring(UI.BTK_Bet2Y or 0) .. "\n")
            file:write("BTK_Break1X=" .. tostring(UI.BTK_Break1X or 0) .. "\n")
            file:write("BTK_Break1Y=" .. tostring(UI.BTK_Break1Y or 0) .. "\n")
            file:write("BTK_Break2X=" .. tostring(UI.BTK_Break2X or 0) .. "\n")
            file:write("BTK_Break2Y=" .. tostring(UI.BTK_Break2Y or 0) .. "\n")
            file:write("BTK_TaxX=" .. tostring(UI.BTK_TaxX or 0) .. "\n")
            file:write("BTK_TaxY=" .. tostring(UI.BTK_TaxY or 0) .. "\n")
            file:write("BTK_MagX=" .. tostring(UI.BTK_MagX or 0) .. "\n")
            file:write("BTK_MagY=" .. tostring(UI.BTK_MagY or 0) .. "\n")
            file:write("FishDirIdx=" .. tostring(UI.FishDirIdx) .. "\n")
            file:write("FishBaitID=" .. tostring(UI.FishBaitID) .. "\n")
            file:write("SurgAutoBuy=" .. tostring(UI.SurgAutoBuy) .. "\n")
            file:write("SurgCardThreshold=" .. tostring(UI.SurgCardThreshold) .. "\n")
            file:write("SurgAutoTrash=" .. tostring(UI.SurgAutoTrash) .. "\n")
            file:write("SurgAutoModage=" .. tostring(UI.SurgAutoModage) .. "\n")
            file:write("SurgUseLegalBrief=" .. tostring(UI.SurgUseLegalBrief) .. "\n")
            file:write("AutoBuyCrimeCards=" .. tostring(UI.AutoBuyCrimeCards) .. "\n")
            file:write("CrimeCardThreshold=" .. tostring(UI.CrimeCardThreshold) .. "\n")
            file:write("ABP_BuyAmount=" .. tostring(UI.ABP_BuyAmount) .. "\n")
            file:write("ABP_BuyOnly=" .. tostring(UI.ABP_BuyOnly) .. "\n")
            file:write("ABP_BatchMode=" .. tostring(UI.ABP_BatchMode) .. "\n")
            file:write("ABP_DropX=" .. tostring(UI.ABP_DropX) .. "\n")
            file:write("ABP_DropY=" .. tostring(UI.ABP_DropY) .. "\n")
            file:write("WatermarkMode=" .. tostring(UI.WatermarkMode) .. "\n")
            file:write("EnableColor=" .. tostring(UI.EnableColor) .. "\n")
            file:write("EnableEmoji=" .. tostring(UI.EnableEmoji) .. "\n")
            file:write("EncryptChat=" .. tostring(UI.EncryptChat) .. "\n")
            file:write("SelectedColorIdx=" .. tostring(UI.SelectedColorIdx) .. "\n")
            file:write("SelectedEmojiIdx=" .. tostring(UI.SelectedEmojiIdx) .. "\n")
            file:write("RainbowSkin=" .. tostring(UI.RainbowSkin) .. "\n")
            file:write("BlinkSkin=" .. tostring(UI.BlinkSkin) .. "\n")
            file:write("WebhookSB=" .. tostring(UI.WebhookSB) .. "\n")
            file:write("DiscordPingID=" .. tostring(UI.DiscordPingID) .. "\n")
            file:write("TradeAddAmount=" .. tostring(UI.TradeAddAmount) .. "\n")
            file:write("SpamInterval=" .. tostring(UI.SpamInterval) .. "\n")
            file:write("SBText=" .. tostring(UI.SBText) .. "\n")
            file:write("SBMax=" .. tostring(UI.SBMax) .. "\n")
            file:write("SBCopyText=" .. tostring(UI.SBCopyText) .. "\n")
            file:write("SBSafeMode=" .. tostring(UI.SBSafeMode) .. "\n")
            file:write("SBDoneWorld=" .. tostring(UI.SBDoneWorld) .. "\n")
            file:write("SBUseDoneWorld=" .. tostring(UI.SBUseDoneWorld) .. "\n")
            file:write("SDBLine1=" .. tostring(UI.SDBLine1) .. "\n")
            file:write("SDBLine2=" .. tostring(UI.SDBLine2) .. "\n")
            file:write("SDBLine3=" .. tostring(UI.SDBLine3) .. "\n")
            file:write("SDBMax=" .. tostring(UI.SDBMax) .. "\n")
            file:write("SDBExtraTimer=" .. tostring(UI.SDBExtraTimer) .. "\n")
            
            for k, v in pairs(UI.CustomCommands) do 
                file:write("CmdAlias|" .. k .. "=" .. v.orig .. "|" .. tostring(v.disableOrig) .. "\n") 
            end
            for i, text in ipairs(UI.SpamTexts) do
                if text ~= "" then 
                    file:write("SpamText|" .. tostring(i) .. "=" .. text .. "\n") 
                end
            end

            if #UI.AutoPullBlacklist > 0 then
                file:write("AutoPullBlacklist=" .. table.concat(UI.AutoPullBlacklist, ",") .. "\n")
            end
            file:close()
        end
    end)
    
    if success then 
        if not silent then UI.LocalChat("`c[WinProxy]: `9Configuration successfully saved!") end
    else
        if not silent then UI.LocalChat("`c[WinProxy]: `4Failed to save configuration.") end
    end
end

function UI.LoadConfig()
    local success, err = pcall(function()
        local file = nil
        for _, path in ipairs(UI.GetConfigPaths()) do
            file = io.open(path, "r")
            if file then break end
        end
        if file then
            UI.SpamTexts = {}
            UI.AutoPullBlacklist = {}
            for line in file:lines() do
                local key, value = line:match("([^=]+)=(.+)")
                if key and value then
                    if key == "AntiLag" then UI.AntiLag = (value == "true")
                    elseif key == "HideSpammer" then UI.HideSpammer = (value == "true")
                    elseif key == "AntiPickup" then UI.AntiPickup = (value == "true")
                    elseif key == "Modfly" then UI.Modfly = (value == "true"); pcall(function() ChangeValue("[C] Modfly", UI.Modfly) end)
                    elseif key == "DialogBg" and value ~= "nil" then UI.DialogBg = tostring(value)
                    elseif key == "DialogBorder" and value ~= "nil" then UI.DialogBorder = tostring(value)
                    elseif key == "AntiPortal" then UI.AntiPortal = (value == "true"); pcall(function() ChangeValue("[C] Anti portal", UI.AntiPortal) end)
                    elseif key == "NightVision" then UI.NightVision = (value == "true"); pcall(function() ChangeValue("[C] Night vision", UI.NightVision) end)
                    elseif key == "BlockSDB" then UI.BlockSDB = (value == "true")
                    elseif key == "BlockSB" then UI.BlockSB = (value == "true")
                    elseif key == "AutoCVLocks" then UI.AutoCVLocks = (value == "true")
                    elseif key == "AutoPull" then UI.AutoPull = (value == "true")
                    elseif key == "AutoPullTileX" then UI.AutoPullTileX = tonumber(value) or 0
                    elseif key == "AutoPullTileY" then UI.AutoPullTileY = tonumber(value) or 0
                    elseif key == "AutoPullMinModal" then UI.AutoPullMinModal = tonumber(value) or 0
                    elseif key:find("AutoPullBlacklist|") then
                        local uid = tonumber(key:match("AutoPullBlacklist|(%d+)"))
                        if uid then
                            table.insert(UI.AutoPullBlacklist, uid)
                        end
                    elseif key == "AutoPullBlacklist" then
                        for uid in value:gmatch("%d+") do
                            table.insert(UI.AutoPullBlacklist, tonumber(uid))
                        end
                    elseif key:match("AutoPullPosX(%d+)") then
                        local idx = tonumber(key:match("AutoPullPosX(%d+)"))
                        if idx and idx >= 1 and idx <= 5 then UI.AutoPullPos[idx].x = tonumber(value) or 0 end
                    elseif key:match("AutoPullPosY(%d+)") then
                        local idx = tonumber(key:match("AutoPullPosY(%d+)"))
                        if idx and idx >= 1 and idx <= 5 then UI.AutoPullPos[idx].y = tonumber(value) or 0 end
                    elseif key == "TPDisplay" then UI.TPDisplay = (value == "true")
                    elseif key == "ShowBal" then UI.ShowBal = (value == "true")
                    elseif key == "VendFilter" then UI.VendFilter = (value == "true")
                    elseif key == "DonationFilter" then UI.DonationFilter = (value == "true")
                    elseif key == "StorageFilter" then UI.StorageFilter = (value == "true")
                    elseif key == "LogsEnabled" then UI.LogsEnabled = (value == "true")
                    elseif key == "TPMode" then UI.TPMode = tonumber(value) or 1
                    elseif key == "WrenchMode" then UI.WrenchMode = tonumber(value) or 0
                    elseif key == "WrenchModeRight" then UI.WrenchModeRight = tonumber(value) or 0
                    elseif key == "WrenchPullText" then UI.WrenchPullText = (value == "nil") and "" or value
                    elseif key == "WrenchKickText" then UI.WrenchKickText = (value == "nil") and "" or value
                    elseif key == "WrenchBanText" then UI.WrenchBanText = (value == "nil") and "" or value
                    elseif key == "DonateMode" then UI.DonateMode = (value == "true")
                    elseif key == "TeleMode" then UI.TeleMode = tonumber(value) or 0
                    elseif key == "CasinoMode" then UI.CasinoMode = tonumber(value) or 0
        elseif key == "CasinoFormatIdx" then UI.CasinoFormatIdx = tonumber(value) or 1
                    elseif key == "CasinoLewaMulti" then UI.CasinoLewaMulti = tonumber(value) or 5
                    elseif key == "BTK_Mode" then UI.BTK_Mode = (value == "BJ") and "BJ" or "BTK"
                    elseif key == "BTK_CenterX" then UI.BTK_CenterX = tonumber(value) or 0
                    elseif key == "BTK_CenterY" then UI.BTK_CenterY = tonumber(value) or 0
                    elseif key == "BTK_Bet1X" then UI.BTK_Bet1X = tonumber(value) or 0
                    elseif key == "BTK_Bet1Y" then UI.BTK_Bet1Y = tonumber(value) or 0
                    elseif key == "BTK_Bet2X" then UI.BTK_Bet2X = tonumber(value) or 0
                    elseif key == "BTK_Bet2Y" then UI.BTK_Bet2Y = tonumber(value) or 0
                    elseif key == "BTK_Break1X" then UI.BTK_Break1X = tonumber(value) or 0
                    elseif key == "BTK_Break1Y" then UI.BTK_Break1Y = tonumber(value) or 0
                    elseif key == "BTK_Break2X" then UI.BTK_Break2X = tonumber(value) or 0
                    elseif key == "BTK_Break2Y" then UI.BTK_Break2Y = tonumber(value) or 0
                    elseif key == "BTK_TaxX" then UI.BTK_TaxX = tonumber(value) or 0
                    elseif key == "BTK_TaxY" then UI.BTK_TaxY = tonumber(value) or 0
                    elseif key == "BTK_MagX" then UI.BTK_MagX = tonumber(value) or 0
                    elseif key == "BTK_MagY" then UI.BTK_MagY = tonumber(value) or 0
                    elseif key == "FishDirIdx" then UI.FishDirIdx = tonumber(value) or 1
                    elseif key == "FishBaitID" then UI.FishBaitID = tonumber(value) or 5528
                    elseif key == "SurgAutoBuy" then UI.SurgAutoBuy = (value == "true")
                    elseif key == "SurgCardThreshold" then UI.SurgCardThreshold = tonumber(value) or 20
                    elseif key == "SurgAutoTrash" then UI.SurgAutoTrash = (value == "true")
                    elseif key == "SurgAutoModage" then UI.SurgAutoModage = (value == "true")
                    elseif key == "SurgUseLegalBrief" then UI.SurgUseLegalBrief = (value == "true")
                    elseif key == "AutoBuyCrimeCards" then UI.AutoBuyCrimeCards = (value == "true")
                    elseif key == "CrimeCardThreshold" then UI.CrimeCardThreshold = tonumber(value) or 10
                    elseif key == "ABP_BuyAmount" then UI.ABP_BuyAmount = tonumber(value) or 0
                    elseif key == "ABP_BuyOnly" then UI.ABP_BuyOnly = (value == "true")
                    elseif key == "ABP_BatchMode" then UI.ABP_BatchMode = (value == "true")
                    elseif key == "ABP_DropX" then UI.ABP_DropX = tonumber(value) or 0
                    elseif key == "ABP_DropY" then UI.ABP_DropY = tonumber(value) or 0
                    elseif key == "WatermarkMode" then UI.WatermarkMode = (value == "true")
                    elseif key == "EnableColor" then UI.EnableColor = (value == "true")
                    elseif key == "EnableEmoji" then UI.EnableEmoji = (value == "true")
                    elseif key == "EncryptChat" then UI.EncryptChat = (value == "true")
                    elseif key == "SelectedColorIdx" then UI.SelectedColorIdx = tonumber(value) or 2
                    elseif key == "SelectedEmojiIdx" then UI.SelectedEmojiIdx = tonumber(value) or 2
                    elseif key == "RainbowSkin" then UI.RainbowSkin = (value == "true")
                    elseif key == "BlinkSkin" then UI.BlinkSkin = (value == "true")
                    elseif key == "WebhookSB" then UI.WebhookSB = (value == "nil") and "" or value
                    elseif key == "DiscordPingID" then UI.DiscordPingID = (value == "nil") and "" or value
                    elseif key == "TradeAddAmount" then UI.TradeAddAmount = tonumber(value) or 1
                    elseif key == "SpamInterval" then UI.SpamInterval = tonumber(value) or 5000
                    elseif key == "SBText" then UI.SBText = (value == "nil") and "" or value
                    elseif key == "SBMax" then UI.SBMax = tonumber(value) or 0
                    elseif key == "SBCopyText" then UI.SBCopyText = (value == "true")
                    elseif key == "SBSafeMode" then UI.SBSafeMode = (value == "true")
                    elseif key == "SBDoneWorld" then UI.SBDoneWorld = (value == "nil") and "" or value
                    elseif key == "SBUseDoneWorld" then UI.SBUseDoneWorld = (value == "true")
                    elseif key == "SDBLine1" then UI.SDBLine1 = (value == "nil") and "" or value
                    elseif key == "SDBLine2" then UI.SDBLine2 = (value == "nil") and "" or value
                    elseif key == "SDBLine3" then UI.SDBLine3 = (value == "nil") and "" or value
                    elseif key == "SDBMax" then UI.SDBMax = tonumber(value) or 0
                    elseif key == "SDBExtraTimer" then UI.SDBExtraTimer = tonumber(value) or 0
                    elseif key:find("CmdAlias|") then 
                        local origCmd, disableStr = value:match("([^|]+)|(.*)")
                        if origCmd and disableStr then
                            UI.CustomCommands[key:sub(10)] = { orig = origCmd, disableOrig = (disableStr == "true") }
                        else
                            UI.CustomCommands[key:sub(10)] = { orig = value, disableOrig = false }
                        end
                    elseif key:find("SpamText|") then 
                        table.insert(UI.SpamTexts, value)
                    end
                end
            end
            if #UI.SpamTexts == 0 then table.insert(UI.SpamTexts, "") end
            file:close()
            return true
        end
        return false
    end)
end

function UI.ResetConfig()
    UI.AntiLag = false
    UI.HideSpammer = false
    UI.AntiPickup = false
UI.Modfly = false
UI.AntiPortal = false
UI.NightVision = false
    UI.BlockSDB = true
    UI.BTK_Mode = "BTK"
    UI.AutoPull = false
    for i = 1, 5 do UI.AutoPullPos[i] = {x=0, y=0} end
    UI.AutoPullSettingSlot = 0
    UI.AutoPullTileX = 0
    UI.AutoPullTileY = 0
    UI.AutoPullMinModal = 0
    AutoCVLocks = false
    UI.TPDisplay = false
    UI.ShowBal = false
    UI.FastDrop = false
    UI.FastTrash = false
    UI.VendFilter = false
    UI.DonationFilter = false
    UI.StorageFilter = false
    UI.LogsEnabled = true
    UI.TPMode = 1
    UI.WrenchMode = 0
    UI.WrenchModeRight = 0
    UI.WrenchPullText = ""
    UI.WrenchKickText = ""
    UI.WrenchBanText = ""
    UI.DonateMode = false
    UI.DonateBoxX = 0
    UI.DonateBoxY = 0
    UI.DonateAmount = 1
    UI.TeleMode = 0
    UI.CasinoMode = 0
    UI.CasinoLewaMulti = 5
    UI.WatermarkMode = true
    UI.EncryptChat = false
    UI.EnableColor = false
    UI.EnableEmoji = false
    UI.SelectedColorIdx = 2
    UI.SelectedEmojiIdx = 2
    UI.RainbowSkin = false
    UI.BlinkSkin = false
    UI.WebhookSB = ""
    UI.DiscordPingID = ""
    UI.TradeAddAmount = 1
    UI.SpamInterval = 5000
    UI.CustomCommands = {}
    UI.SpamTexts = {""}
    UI.SBText = ""
    UI.SBMax = 0
    UI.SBCopyText = false
    UI.SBSafeMode = false
    UI.SBDoneWorld = ""
    UI.SBUseDoneWorld = false
    UI.SDBLine1 = ""
    UI.SDBLine2 = ""
    UI.SDBLine3 = ""
    UI.SDBMax = 0
    UI.SDBExtraTimer = 0
    UI.LocalChat("`c[WinProxy]: `9Configuration reset to default. Click 'Save' to apply.")
end


-- ==========================================
-- HELPER : Get Soon Dialog
-- ==========================================

local function GetSoonDialog(title, iconID)
    return "add_label_with_icon|big|`9" .. title .. "|left|" .. iconID .. "|\n" ..
           "add_spacer|small|\n" ..
           "add_textbox|`wThis feature will be available soon.|\n" ..
           "add_spacer|small|\n" ..
           "text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|\n" ..
           "add_button|menuu|Back|noflags|0|0|\n" ..
           "end_dialog|close_ui|Close||\n"
end


-- ==========================================
-- HELPER : General
-- ==========================================

function UI.ToggleAntiLag(state)
    if state ~= nil then UI.AntiLag = state else UI.AntiLag = not UI.AntiLag end
    
    pcall(function()
        ChangeValue("[C] No render particle", UI.AntiLag)
        ChangeValue("[C] No render shadow", UI.AntiLag)
    end)
    
    UI.SaveConfig(true)
    UI.LocalChat("`c[WinProxy]: `9Anti-Lag is now " .. (UI.AntiLag and "`2ON" or "`4OFF"))
end

function UI.ToggleHideSpammer(state)
    if state ~= nil then UI.HideSpammer = state else UI.HideSpammer = not UI.HideSpammer end
    UI.SaveConfig(true)
    UI.LocalChat("`c[WinProxy]: `9Hide Spammer Slave is now " .. (UI.HideSpammer and "`2ON" or "`4OFF"))
end

function UI.GetNearestTelephone()
    local lp = GetLocal()
    if not lp or not lp.pos then return nil, nil end
    local px = math.floor(lp.pos.x / 32)
    local py = math.floor(lp.pos.y / 32)
    
    local bestX, bestY = nil, nil
    local minDist = 9999
    
    local ok, tiles = pcall(GetTiles)
    if ok and tiles then
        for _, tile in pairs(tiles) do
            if tile.fg == 3898 then
                local dist = math.max(math.abs(tile.x - px), math.abs(tile.y - py))
                if dist < minDist then
                    minDist = dist
                    bestX = tile.x
                    bestY = tile.y
                end
            end
        end
    end
    
    if minDist <= 3 then return bestX, bestY end
    return nil, nil
end

UI.WarningThreadRunning = false
function UI.ManageWarningThread()
    if UI.WarningThreadRunning then return end
    UI.WarningThreadRunning = true
    RunThread(function()
        while UI.FastDropOnClick or UI.FastTrashOnClick do
            local mode = UI.FastDropOnClick and "`4FAST DROP" or "`4FAST TRASH"
            local actionStr = UI.FastDropOnClick and "DROP" or "TRASH"
            local warningMsg = "`wWarning: " .. mode .. " ON-CLICK `wis `2ACTIVE`w!\n`4Touch an item in your inventory to instantly " .. actionStr .. " it!"
            SendVariantList({[0] = "OnTextOverlay", [1] = warningMsg})
            Sleep(2000)
        end
        UI.WarningThreadRunning = false
    end)
end

UI.OnClickThreadRunning = false
UI.LastSelectedItemID = 0

function UI.ManageOnClickItemThread()
    if UI.OnClickThreadRunning then return end
    UI.OnClickThreadRunning = true
    RunThread(function()
        while UI.FastDropOnClick or UI.FastTrashOnClick do
            local success, player_items = pcall(GetPlayerItems)
            if success and player_items and player_items.backpack then
                local cur_sel = tonumber(player_items.backpack.selected) or 0
                
                if cur_sel > 0 and cur_sel ~= UI.LastSelectedItemID then
                    UI.LastSelectedItemID = cur_sel
                    
                    if cur_sel ~= 18 and cur_sel ~= 32 and cur_sel ~= UI.GetIcon("Creativeps World Lock", 242) and cur_sel ~= UI.GetIcon("Creativeps Diamond Lock", 1796) and cur_sel ~= UI.GetIcon("Creativeps Blue Gem Lock", 7188) and cur_sel ~= UI.GetIcon("Creativeps Black Gem Lock", 11550) then
                        if UI.FastDropOnClick then
                            SendPacket(2, "action|drop\n|itemID|" .. cur_sel)
                        elseif UI.FastTrashOnClick then
                            SendPacket(2, "action|trash\n|itemID|" .. cur_sel)
                        end
                    end
                elseif cur_sel == 0 then
                    UI.LastSelectedItemID = 0
                end
            end
            Sleep(50)
        end
        UI.OnClickThreadRunning = false
        UI.LastSelectedItemID = 0
    end)
end


-- ==========================================
-- HELPER : Wrench
-- ==========================================

function UI.GetPlayerNameByNetID(netid)
    local pName = "Player"
    local success, players = pcall(GetPlayerList)
    if success and type(players) == "table" then
        for _, p in pairs(players) do
            if p.netid == tonumber(netid) then
                local cleanName = p.name
                cleanName = cleanName:gsub("%[.-%]", "")
                cleanName = cleanName:gsub("%(.-%)", "")
                cleanName = cleanName:gsub("%s+", " ")
                cleanName = cleanName:gsub("%s+`", "`")
                pName = cleanName:match("^%s*(.-)%s*$")
                break
            end
        end
    end
    return pName
end

function UI.ToggleWrench(mode, isRight)
    local modeNames = {"Pull", "Kick", "Ban", "Trade"}
    local sideLabel = isRight and "Right Click" or "Left Click"
    
    if isRight then
        if UI.WrenchModeRight ~= 0 then 
            UI.LocalChat("`c[WinProxy]: `4Disabled " .. sideLabel .. " Wrench " .. (modeNames[UI.WrenchModeRight] or "Unknown")) 
        end
        if UI.WrenchModeRight == mode then 
            UI.WrenchModeRight = 0 
        else
            UI.WrenchModeRight = mode
            UI.LocalChat("`c[WinProxy]: `2Enabled " .. sideLabel .. " Wrench " .. (modeNames[mode] or "Unknown"))
        end
    else
        if UI.WrenchMode ~= 0 then 
            UI.LocalChat("`c[WinProxy]: `4Disabled " .. sideLabel .. " Wrench " .. (modeNames[UI.WrenchMode] or "Unknown")) 
        end
        if UI.WrenchMode == mode then 
            UI.WrenchMode = 0 
        else
            UI.WrenchMode = mode
            UI.LocalChat("`c[WinProxy]: `2Enabled " .. sideLabel .. " Wrench " .. (modeNames[mode] or "Unknown"))
        end
    end
    UI.SaveConfig(true)
end


-- ==========================================
-- HELPER : Donate
-- ==========================================

function UI.DoDonate(itemID, amount)
    if not UI.DonateMode or UI.DonateBoxX == 0 then 
        return UI.LocalChat("`c[WinProxy]: `4Enable /dmode and set a box position first!") 
    end
    local itemName = ""
    if itemID == 242 then itemName = "`9World Locks" 
    elseif itemID == 1796 then itemName = "`cDiamond Locks" 
    elseif itemID == 7188 then itemName = "`eBlue Gem Locks" 
    else itemName = "`bBlack Gem Locks" end
    
    if amount > 0 then
        if UI.GetItemCount(itemID) >= amount then
            SendPacket(2, "action|dialog_return\ndialog_name|donate_item|\nx|"..UI.DonateBoxX.."|\ny|"..UI.DonateBoxY.."|\nitem|"..itemID.."|\ndoncount|"..amount.."|\noptNote|")
            UI.LocalChat("`c[WinProxy]: `9Donating `4"..amount.." " .. itemName .. "`9...")
        else 
            UI.LocalChat("`c[WinProxy]: `4You don't have enough " .. itemName .. "!") 
        end
    end
end

function UI.DonateAllLocks()
    if not UI.DonateMode or UI.DonateBoxX == 0 then 
        return UI.LocalChat("`c[WinProxy]: `4Enable /dmode and set a box position first!") 
    end
    RunThread(function()
        local locks = {UI.GetIcon("Creativeps Black Gem Lock", 11550), UI.GetIcon("Creativeps Blue Gem Lock", 7188), UI.GetIcon("Creativeps Diamond Lock", 1796), UI.GetIcon("Creativeps World Lock", 242)}
        local totalDonated = 0
        for _, id in ipairs(locks) do
            local count = UI.GetItemCount(id)
            if count > 0 then
                SendPacket(2, "action|dialog_return\ndialog_name|donate_item|\nx|"..UI.DonateBoxX.."|\ny|"..UI.DonateBoxY.."|\nitem|"..id.."|\ndoncount|"..count.."|\noptNote|")
                totalDonated = totalDonated + 1
                Sleep(750)
            end
        end
        if totalDonated > 0 then
            UI.LocalChat("`c[WinProxy]: `9Successfully put all locks into the Donation Box!")
        else
            UI.LocalChat("`c[WinProxy]: `4You don't have any locks to donate!")
        end
    end)
end


-- ==========================================
-- HELPER : Trade
-- ==========================================

function UI.FastTradeAdd(itemID, amount)
    local itemName = ""
    if itemID == 242 then itemName = "`9World Locks" 
    elseif itemID == 1796 then itemName = "`cDiamond Locks" 
    elseif itemID == 7188 then itemName = "`eBlue Gem Locks" 
    else itemName = "`bBlack Gem Locks" end
    
    if amount > 0 then
        if UI.GetItemCount(itemID) >= amount then
            SendPacket(2, "action|dialog_return\ndialog_name|trade\nitem_trade|" .. itemID .. "|\nitem_count|" .. amount)
            UI.LocalChat("`c[WinProxy]: `9You've Put `4" .. amount .. " " .. itemName .. " `9to the Trade`4!")
        else 
            UI.LocalChat("`c[WinProxy]: `4You don't have enough " .. itemName .. "`4!") 
        end
    end
end

function UI.TradeAllLocks()
    RunThread(function()
        local locks = {UI.GetIcon("Creativeps Black Gem Lock", 11550), UI.GetIcon("Creativeps Blue Gem Lock", 7188), UI.GetIcon("Creativeps Diamond Lock", 1796), UI.GetIcon("Creativeps World Lock", 242)}
        local totalAdded = 0
        for _, id in ipairs(locks) do
            local count = UI.GetItemCount(id)
            if count > 0 then
                SendPacket(2, "action|dialog_return\ndialog_name|trade\nitem_trade|" .. id .. "|\nitem_count|" .. count)
                totalAdded = totalAdded + 1
                Sleep(750)
            end
        end
        if totalAdded > 0 then
            UI.LocalChat("`c[WinProxy]: `9Successfully added all locks to Trade!")
        else
            UI.LocalChat("`c[WinProxy]: `4You don't have any locks to trade!")
        end
    end)
end

function UI.TradeClearLocks()
    RunThread(function()
        local locks = {UI.GetIcon("Creativeps Black Gem Lock", 11550), UI.GetIcon("Creativeps Blue Gem Lock", 7188), UI.GetIcon("Creativeps Diamond Lock", 1796), UI.GetIcon("Creativeps World Lock", 242)}
        for _, id in ipairs(locks) do
            SendPacket(2, "action|rem_trade\nitemID|" .. id .. "\n")
            Sleep(750)
        end
        UI.LocalChat("`c[WinProxy]: `9Cleared all locks from Trade window!")
    end)
end


-- ==========================================
-- HELPER : Emoji & Color
-- ==========================================

function UI.SetSkinColor(r, g, b, a)
    local red = math.max(0, math.min(255, math.floor((r or 1.0) * 255)))
    local green = math.max(0, math.min(255, math.floor((g or 1.0) * 255)))
    local blue = math.max(0, math.min(255, math.floor((b or 1.0) * 255)))
    local transparency = math.max(0, math.min(255, math.floor((1.0 - (a or 1.0)) * 255)))
    local packet = string.format("action|dialog_return\ndialog_name|skinpicker\nred|%d\ngreen|%d\nblue|%d\ntransparency|%d", red, green, blue, transparency)
    SendPacket(2, packet)
end

local function HSVtoRGB(h, s, v)
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c
    local r, g, b = 0, 0, 0
    if h < 60 then r, g, b = c, x, 0
    elseif h < 120 then r, g, b = x, c, 0
    elseif h < 180 then r, g, b = 0, c, x
    elseif h < 240 then r, g, b = 0, x, c
    elseif h < 300 then r, g, b = x, 0, c
    else r, g, b = c, 0, x end
    return math.floor((r + m) * 255), math.floor((g + m) * 255), math.floor((b + m) * 255)
end

local FadeColors = {
    3370516479, 3033464831, 2864971775, 2527912447,
    2190853119, 2022356223, 1685231359, 1348231359,
    1348231359, 1685231359, 2022356223, 2190853119,
    2527912447, 2864971775, 3033464831, 3370516479
}

function UI.ManageSkinEffects()
    if UI.SkinEffectRunning then return end
    UI.SkinEffectRunning = true
    RunThread(function()
        local hue = 0
        while UI.RainbowSkin or UI.BlinkSkin do
            if UI.RainbowSkin then
                hue = (hue + 12) % 360
                local r, g, b = HSVtoRGB(hue, 1.0, 1.0)
                SendPacket(2, "action|dialog_return\ndialog_name|skinpicker\nred|" .. r .. "\ngreen|" .. g .. "\nblue|" .. b .. "\ntransparency|0\n")
                Sleep(100)
            elseif UI.BlinkSkin then
                for _, color in ipairs(FadeColors) do
                    if not UI.BlinkSkin then break end
                    SendPacket(2, "action|setSkin\ncolor|" .. color)
                    Sleep(150)
                end
            end
        end
        UI.SkinEffectRunning = false
    end)
end


-- ==========================================
-- HELPER : Calculator
-- ==========================================

function UI.CalculateMath(formula)
    local clean = formula:gsub("[^%d%+%-%*%/%.%(%)%%]", "")
    if clean == "" then 
        UI.CalcResult = "`4Error: Invalid input!"
        return false, clean, nil 
    end
    local evalString = clean:gsub("([%d%.]+)([%+%-])([%d%.]+)%%", "%1%2(%1*%3/100)"):gsub("([%d%.]+)%%", "(%1/100)")
    local func = load("return " .. evalString)
    
    if func then
        local success, result = pcall(func)
        if success and type(result) == "number" then
            local formattedResult = ""
            if result % 1 == 0 then formattedResult = string.format("%d", result)
            else formattedResult = string.format("%g", result) end
            
            local finalString = "`w" .. clean .. " = `2" .. formattedResult
            UI.CalcResult = finalString
            table.insert(UI.CalcLogs, 1, finalString)
            if #UI.CalcLogs > 5 then table.remove(UI.CalcLogs, 6) end
            
            return true, clean, formattedResult
        end
    end
    UI.CalcResult = "`4Error: Math calculation failed!"
    return false, clean, nil
end


-- ==========================================
-- HELPER : Item Database
-- ==========================================

function UI.SearchItem(query)
    UI.SearchItemResults = {}
    if not query or query == "" then return end
    
    local qLower = query:lower()
    local isNum = tonumber(query)
    local count = 0
    
    for name, id in pairs(UI.ItemDB) do
        if isNum and id == isNum then
            table.insert(UI.SearchItemResults, {name = name, id = id})
            count = count + 1
        elseif not isNum and name:find(qLower) then
            table.insert(UI.SearchItemResults, {name = name, id = id})
            count = count + 1
        end
        if count >= 100 then break end 
    end
    table.sort(UI.SearchItemResults, function(a, b) return a.id < b.id end)
end


-- ==========================================
-- HELPER : Auto Fish
-- ==========================================

function UI.ManageAutoFishThread()
    if UI.FishThreadRunning then return end
    UI.FishThreadRunning = true
    RunThread(function()
        UI.LocalChat("`c[WinProxy]: `9Auto Fish Started! `wMake sure you are standing near water.")
        while UI.AutoFish do
            local lp = GetLocal()
            if not lp then Sleep(500) goto continue end
            if UI.GetItemCount(UI.FishBaitID) <= 0 then
                UI.LocalChat("`c[WinProxy]: `4[WARNING] `wOut of Bait (ID: " .. UI.FishBaitID .. ")! Stopping Auto Fish.")
                UI.AutoFish = false
                break
            end
            UI.FishAction = "Casting Bait..."
            UI.FishStats.cast = UI.FishStats.cast + 1
            
            local castX = math.floor(lp.pos.x / 32) + (UI.FishDirIdx == 1 and 1 or -1)
            local castY = math.floor(lp.pos.y / 32) + 1
            
            SendPacketRaw(false, {type = 3, value = UI.FishBaitID, px = castX, py = castY, x = lp.pos.x, y = lp.pos.y})
            
            UI.FishAction = "Waiting for fish..."
            UI.FishBite = false
            
            local waitTime = 0
            while UI.AutoFish and not UI.FishBite and waitTime < 450 do
                Sleep(100)
                waitTime = waitTime + 1
            end
            
            if UI.FishBite and UI.AutoFish then
                UI.FishAction = "Reeling in!"
                SendPacketRaw(false, {type = 3, value = UI.FishBaitID, px = castX, py = castY, x = lp.pos.x, y = lp.pos.y})
                Sleep(400) 
            end
            ::continue::
        end
        UI.FishThreadRunning = false
        UI.FishAction = "Stopped."
        UI.FishBite = false
    end)
end


-- ==========================================
-- HELPER : Auto Surg
-- ==========================================

function UI.OnSurgerySuccess()
    if not UI.IsSurging then return end
    UI.IsSurging = false
    UI.SurgStats.success = UI.SurgStats.success + 1
    UI.SurgAction = "Surgery Successful!"
    SendPacket(2, "action|input\n|text|`#" .. UI.SurgStats.success .. " Surg Done `2#WinProxy")
end

UI.LastBypassTime = 0
UI.IsBypassing = false

function UI.BypassMalpractice()
    local now = os.time()
    if (now - (UI.LastBypassTime or 0)) < 2 or UI.IsBypassing then
        return
    end
    UI.LastBypassTime = now
    UI.IsBypassing = true
    UI.IsSurging = true
    UI.SurgStats.fail = UI.SurgStats.fail + 1
    UI.SurgAction = "Bypassing Malpractice..."
    
    RunThread(function()
        Sleep(150)
        if UI.SurgAutoModage then
            UI.LocalChat("`c[WinProxy]: `4[Malpractice] `9Bypassing with /modage 999...")
            SendPacket(2, "action|input\n|text|/modage 999")
            Sleep(200)
            SendPacket(2, "action|input\n|text|/modage 60")
        end
        if UI.SurgUseLegalBrief then
            UI.LocalChat("`c[WinProxy]: `4[Malpractice] `9Using Legal Brief (3172)...")
            local lp = GetLocal()
            local px = lp and math.floor(lp.pos.x / 32) or 0
            local py = lp and math.floor(lp.pos.y / 32) or 0
            SendPacketRaw(false, { type = 10, value = 3172, px = px, py = py, x = px * 32, y = py * 32 })
            Sleep(200)
            SendPacketRaw(false, { type = 10, value = 3172 })
        end
        if not UI.SurgAutoModage and not UI.SurgUseLegalBrief then
            UI.LocalChat("`c[WinProxy]: `4[Malpractice] `9Bypassing with /modage 999...")
            SendPacket(2, "action|input\n|text|/modage 999")
            Sleep(200)
            SendPacket(2, "action|input\n|text|/modage 60")
        end
        Sleep(800)
        UI.IsBypassing = false
        UI.IsSurging = false
    end)
end

function UI.TrashExcessTools()
    local trashIDs = { 1240, 1256, 1266, 1262, 1264, 4314, 1260, 1268, 1258, 1270 }
    for _, id in ipairs(trashIDs) do
        local count = UI.GetItemCount(id)
        if count >= 240 then
            local trashAmount = count - 200
            UI.LocalChat("`c[WinProxy]: `9[Auto Trash] `wTrashing `e" .. trashAmount .. " `wof item `2#" .. id .. " `wto free space.")
            SendPacket(2, "action|dialog_return\ndialog_name|trash\nitem_trash|" .. id .. "|\nitem_count|" .. trashAmount .. "\n")
            Sleep(250)
        end
    end
end

function UI.PerformSurgAntiStuck(reason)
    if UI.IsRecoveringAntiStuck then return end
    UI.IsRecoveringAntiStuck = true
    UI.IsSurging = false
    UI.SurgStartTime = 0
    UI.SurgAction = "Anti-Stuck: Rejoining World..."
    UI.LocalChat("`c[WinProxy]: `4[" .. (reason or "Timeout 20s") .. "] `9Re-warping world & returning to spot...")
    
    local w = ""
    local ok, worldObj = pcall(GetWorld)
    if ok and worldObj and worldObj.name and worldObj.name ~= "" then
        w = worldObj.name
    end
    
    RunThread(function()
        if w ~= "" then
            SendPacket(3, "action|join_request\nname|" .. w .. "\ninvitedWorld|0")
            Sleep(250)
            SendPacket(2, "action|input\n|text|/warp " .. w)
            Sleep(3000)
            
            if UI.SurgPos and UI.SurgPos.x and UI.SurgPos.y then
                UI.LocalChat("`c[WinProxy]: `9Pathfinding back to surgery tile (" .. UI.SurgPos.x .. ", " .. UI.SurgPos.y .. ")...")
                pcall(FindPath, UI.SurgPos.x, UI.SurgPos.y)
                Sleep(2000)
            end

            if UI.SurgAutoModage then
                UI.LocalChat("`c[WinProxy]: `9[Anti-Stuck] Applying /modage 999 & /modage 60...")
                SendPacket(2, "action|input\n|text|/modage 999")
                Sleep(200)
                SendPacket(2, "action|input\n|text|/modage 60")
                Sleep(500)
            end
            if UI.SurgUseLegalBrief then
                UI.LocalChat("`c[WinProxy]: `9[Anti-Stuck] Using Legal Brief (3172)...")
                local lp = GetLocal()
                local px = lp and math.floor(lp.pos.x / 32) or 0
                local py = lp and math.floor(lp.pos.y / 32) or 0
                SendPacketRaw(false, { type = 10, value = 3172, px = px, py = py, x = px * 32, y = py * 32 })
                Sleep(200)
                SendPacketRaw(false, { type = 10, value = 3172 })
                Sleep(500)
            end
            if not UI.SurgAutoModage and not UI.SurgUseLegalBrief then
                SendPacket(2, "action|input\n|text|/modage 999")
                Sleep(200)
                SendPacket(2, "action|input\n|text|/modage 60")
                Sleep(500)
            end
        end
        UI.IsRecoveringAntiStuck = false
        UI.IsSurging = false
        UI.SurgStartTime = 0
        if UI.SurgTarget then
            UI.SurgAction = "Waiting for target..."
        end
    end)
end

function UI.ManageAutoSurgThread()
    if UI.SurgThreadRunning then return end
    UI.SurgThreadRunning = true
    RunThread(function()
        UI.LocalChat("`c[WinProxy]: `9Auto Surg Started! `wWrench a player or surgical bed to begin.")
        UI.SurgAction = "Waiting for target..."
        UI.SurgStartTime = os.time()
        
        local lp = GetLocal()
        if lp and lp.pos then
            UI.SurgPos = { x = math.floor(lp.pos.x / 32), y = math.floor(lp.pos.y / 32) }
        end
        
        local surgTools = {1240, 1258, 1260, 1262, 1264, 1266, 1268, 1270}
        
        while UI.AutoSurg do
            if UI.SurgAutoTrash then
                UI.TrashExcessTools()
            end

            if UI.SurgAutoBuy then
                local needBuy = false
                for _, tid in ipairs(surgTools) do
                    local count = UI.GetItemCount(tid)
                    if count < UI.SurgCardThreshold then 
                        needBuy = true
                        break 
                    end
                end
                
                if needBuy then
                    UI.SurgAction = "Buying Surg Kits..."
                    UI.LocalChat("`c[WinProxy]: `wTools dropped below " .. UI.SurgCardThreshold .. "! Restocking...")
                    local buyAttempts = 0
                    while needBuy and buyAttempts < 15 and UI.AutoSurg do
                        if UI.SurgAutoTrash then UI.TrashExcessTools() end
                        SendPacket(2, "action|buy\nitem|buy_surgkit")
                        Sleep(1200)
                        needBuy = false
                        for _, tid in ipairs(surgTools) do
                            if UI.GetItemCount(tid) < UI.SurgCardThreshold then needBuy = true break end
                        end
                        buyAttempts = buyAttempts + 1
                    end
                    if needBuy then
                        UI.LocalChat("`c[WinProxy]: `4[WARNING] `wFailed to restock! Stopping Auto Surg.")
                        UI.AutoSurg = false
                        break
                    else
                        if not UI.SurgTarget then UI.SurgAction = "Waiting for target..." end
                    end
                end
            end
            
            if UI.SurgTarget and not UI.IsSurging and not UI.IsBypassing and not UI.IsRecoveringAntiStuck then
                SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. UI.SurgTarget .. "|\nbuttonClicked|surgery\n\n")
            end
            
            if UI.IsSurging and UI.SurgStartTime > 0 and (os.time() - UI.SurgStartTime > 20) then
                UI.PerformSurgAntiStuck("Surgery Timeout 20s")
            end
            Sleep(800)
        end
        UI.SurgThreadRunning = false
        UI.SurgAction = "Stopped."
        UI.SurgTarget = nil
        UI.IsSurging = false
    end)
end


-- ==========================================
-- HELPER : Auto Crime
-- ==========================================

function UI.ScanVillains()
    UI.CrimeVillains = {}
    local world = GetWorld()
    if not world then return end

    for y = 0, world.height - 1 do
        for x = 0, world.width - 1 do
            local tile = GetTile(x, y)
            if tile and tile.fg == 2302 then
                local vName = "Unknown Villain"
                if tile.extra and tile.extra.label2 and tile.extra.label2 ~= "" then
                    vName = tile.extra.label2:gsub("`.", ""):gsub("!", ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
                end
                table.insert(UI.CrimeVillains, { name = vName, x = x, y = y })
            end
        end
    end
    UI.LocalChat("`c[WinProxy]: `9Crime Scan complete! Found `2" .. #UI.CrimeVillains .. " `9villains.")
end

function UI.ManageAutoCrimeThread()
    if UI.CrimeThreadRunning then return end
    UI.CrimeThreadRunning = true
    RunThread(function()
        UI.ScanVillains()
        if #UI.CrimeVillains == 0 then
            UI.CrimeAction = "No villains found. Stopped."
            UI.AutoCrime = false
            UI.CrimeThreadRunning = false
            return
        end

        local function SafeMoveTo(tx, ty)
            for attempt = 1, 100 do 
                local lp = GetLocal()
                if not lp then return false end
                local cx = math.floor(lp.pos.x / 32)
                local cy = math.floor(lp.pos.y / 32)
                if cx == tx and cy == ty then return true end
                local dx, dy = tx - cx, ty - cy
                local dist = math.sqrt(dx*dx + dy*dy)
                if dist > 3 then
                    FindPath(cx + math.floor((dx / dist) * 3), cy + math.floor((dy / dist) * 3))
                else
                    FindPath(tx, ty)
                end
                Sleep(150)
            end
            return false
        end

        for i, inst in ipairs(UI.CrimeVillains) do
            if not UI.AutoCrime then break end

            if UI.AutoBuyCrimeCards then
                local needToBuy = false
                for _, cardId in ipairs(UI.CrimeDeck) do
                    if UI.GetItemCount(cardId) < UI.CrimeCardThreshold then
                        needToBuy = true
                        break
                    end
                end

                if needToBuy then
                    UI.CrimeAction = "Buying Crime Cards..."
                    local buyAttempts = 0
                    while needToBuy and buyAttempts < 15 and UI.AutoCrime do
                        SendPacket(2, "action|buy\nitem|" .. UI.CrimePackName)
                        Sleep(1000) 
                        needToBuy = false
                        for _, cardId in ipairs(UI.CrimeDeck) do
                            if UI.GetItemCount(cardId) < UI.CrimeCardThreshold then
                                needToBuy = true
                                break
                            end
                        end
                        buyAttempts = buyAttempts + 1
                    end
                    if needToBuy then
                        UI.LocalChat("`c[WinProxy]: `4[WARNING] `wFailed to buy enough Crime Cards!")
                        UI.AutoCrime = false
                        break
                    end
                end
            else
                local missingCard = false
                for _, cardId in ipairs(UI.CrimeDeck) do
                    if UI.GetItemCount(cardId) < 1 then
                        missingCard = true
                        break
                    end
                end
                if missingCard then
                    UI.LocalChat("`c[WinProxy]: `4[WARNING] `wYou ran out of Crime Cards! Stopping.")
                    UI.AutoCrime = false
                    break
                end
            end

            UI.CrimeAction = "Moving to " .. inst.name .. " (" .. i .. "/" .. #UI.CrimeVillains .. ")"
            UI.CrimeTarget = { name = inst.name, x = inst.x, y = inst.y }
            SafeMoveTo(inst.x, inst.y)
            Sleep(500)
            
            local packetString = "action|dialog_return\ndialog_name|crimewave\nx|" .. inst.x .. "|\ny|" .. inst.y .. "|\n"
            for _, cardId in ipairs(UI.CrimeDeck) do packetString = packetString .. cardId .. "|1\n" end
            SendPacket(2, packetString)
            Sleep(1000) 
            
            local cardToSpam = 2294
            if inst.name:find("The Harvester") or inst.name:find("Professor Pummel") or inst.name:find("Devil Ham") or inst.name:find("Ban Hammer") then
                cardToSpam = 2316
            end
            
            UI.IsFightingCrime = true
            UI.CrimeWon = false
            UI.CrimeAction = "Fighting " .. inst.name .. "!"
            
            while UI.IsFightingCrime and UI.AutoCrime do
                SendPacket(2, "action|dialog_return\ndialog_name|crimewave\nx|" .. inst.x .. "|\ny|" .. inst.y .. "|\nbuttonClicked|" .. cardToSpam)
                Sleep(150)
                local curtile = GetTile(inst.x, inst.y)
                if curtile and curtile.fg ~= 2302 then
                    UI.IsFightingCrime = false
                    UI.CrimeAction = "Done fighting " .. inst.name
                end
            end
            UI.CrimeTarget = nil
            Sleep(500)
        end
        UI.AutoCrime = false
        UI.CrimeAction = "Finished clearing villains!"
        UI.CrimeThreadRunning = false
    end)
end


-- ==========================================
-- HELPER : Auto Spam
-- ==========================================

function UI.ManageSpamThread()
    if UI.SpamThreadRunning then return end
    UI.SpamThreadRunning = true
    RunThread(function()
        local currentIndex = 1
        while UI.SpamEnabled do
            local textToSend = ""
            local maxIndex = #UI.SpamTexts
            if maxIndex > 0 then
                local attempts = 0
                while attempts < maxIndex do
                    if UI.SpamTexts[currentIndex] and UI.SpamTexts[currentIndex] ~= "" then
                        textToSend = UI.SpamTexts[currentIndex]
                        currentIndex = (currentIndex % maxIndex) + 1
                        break
                    end
                    currentIndex = (currentIndex % maxIndex) + 1
                    attempts = attempts + 1
                end
            end
            if textToSend ~= "" then SendPacket(2, "action|input\n|text|" .. textToSend) end
            Sleep(UI.SpamInterval)
        end
        UI.SpamThreadRunning = false
    end)
end

function UI.ToggleSpam(state)
    UI.SpamEnabled = state
    if UI.SpamEnabled then
        UI.LocalChat("`c[WinProxy]: `9Auto-Spam is now `2ON")
        UI.ManageSpamThread()
    else 
        UI.LocalChat("`c[WinProxy]: `9Auto-Spam is now `4OFF") 
    end
end


-- ==========================================
-- HELPER : Auto SB & SBD
-- ==========================================

function UI.FormatNum(num)
    num = math.floor(num + 0.5)
    local formatted = tostring(num)
    local k = 3
    while k < #formatted do
        formatted = formatted:sub(1, #formatted - k) .. "," .. formatted:sub(#formatted - k + 1)
        k = k + 4
    end
    return formatted
end

function UI.CleanStr(str)
    local cleanedStr = string.gsub(str, "`(%S)", '')
    cleanedStr = string.gsub(cleanedStr, "`{2}|(~{2})", '')
    cleanedStr = string.gsub(cleanedStr, "\\", "\\\\")
    cleanedStr = string.gsub(cleanedStr, '"', '\\"')
    return cleanedStr
end

function UI.GetSBEndTime()
    if UI.SBCount == 0 then return UI.SBStartTime + (UI.SBMax * UI.SBDelay * 60)
    else return UI.SBStartTime + ((UI.SBMax - UI.SBCount) * UI.SBDelay * 60) end
end

function UI.ManageSBThread()
    if UI.SBThreadRunning then return end
    UI.SBThreadRunning = true
    RunThread(function()
        UI.SBWorld = GetWorld() and GetWorld().name or "UNKNOWN"
        UI.LocalChat("`c[WinProxy]: `eSuper Broadcast `2Activated")
        Sleep(1000)
        UI.LocalChat("`c[WinProxy]: `9World `0= " .. UI.SBWorld)
        Sleep(1000)
        UI.LocalChat("`c[WinProxy]: `9Duration `0= " .. math.floor(UI.SBMax * 3) .. " Minutes!")
        Sleep(1000)
        
        while UI.SBEnabled and UI.SBCount < UI.SBMax do
            SendPacket(2, "action|input\n|text|/sb " .. UI.SBText .. " `c#WinProxy")
            UI.SBCount = UI.SBCount + 1
            
            local sbRemain = UI.SBMax - UI.SBCount
            local minRemain = (UI.SBMax * 3) - (UI.SBCount * 3)
            local endTime = UI.GetSBEndTime()
            
            Sleep(1000)
            
            if not UI.SBPending then
                if UI.SBUseGems and not UI.SBUseBGems then
                    UI.SBTotSucceed = UI.SBTotSucceed + 1
                    UI.LocalChat("`c[WinProxy]: `eSB `2Succeed`4!")
                    Sleep(1000)
                    UI.LocalChat("`c[WinProxy]: `9Last Used `0= `6" .. UI.FormatNum(UI.SBUsedGems) .. " `2Gems")
                    Sleep(1000)
                    UI.LocalChat("`c[WinProxy]: `9Total Used `0= `6" .. UI.FormatNum(UI.SBTotUsedGems) .. " `2Gems")
                elseif UI.SBUseBGems and not UI.SBUseGems then
                    UI.SBTotSucceed = UI.SBTotSucceed + 1
                    UI.LocalChat("`c[WinProxy]: `eSB `2Succeed`4!")
                    Sleep(1000)
                    UI.LocalChat("`c[WinProxy]: `9Last Used `0= `6" .. UI.SBUsedBGems .. " `bBGems")
                    Sleep(1000)
                    UI.LocalChat("`c[WinProxy]: `9Total Used `0= `6" .. UI.FormatNum(UI.SBTotUsedBGems) .. " `bBGems")
                end
                Sleep(1000)
                UI.LocalChat("`c[WinProxy]: `9Total `0: `2" .. UI.SBCount .. "`0/`4" .. UI.SBMax .. "`0, `4Remain `0: `4" .. sbRemain)
                Sleep(1000)
                UI.LocalChat("`c[WinProxy]: `2Start `0: `6" .. os.date(" %I:%M %p", UI.SBStartTime) .. "`0, `4End `0: `6" .. os.date(" %I:%M %p", endTime))
            else
                UI.SBTotPending = UI.SBTotPending + 1
                UI.LocalChat("`c[WinProxy]: `eSB `4Pending `9Please Wait`4!")
                Sleep(5000)
                UI.SBPending = false
            end
            
            Sleep(1000)
            UI.LocalChat("`c[WinProxy]: `9Time Left `0: `6" .. minRemain .. " `9Minutes!")
            
            if UI.WebhookSB ~= "" then
                Sleep(1000)
                UI.LocalChat("`c[WinProxy]: `9Sending Discord Webhook...")
                local myGems = (GetPlayerInfo() and GetPlayerInfo().gems) or 0
                local myName = (GetLocal() and GetLocal().name and GetLocal().name:gsub("`.", "")) or "Unknown"
                local startGems = myGems + UI.SBTotUsedGems
                local startBGems = UI.SBLeftBGems + UI.SBTotUsedBGems
                local sbAvatar = "https://media.discordapp.net/attachments/1438466585005391923/1481856877410390157/WinPFP-Animated.gif"
                local sbFooterIcon = "https://cdn.discordapp.com/emojis/1481856719230603354.webp"
                local payload = [[{"username": "WinProxy SB", "avatar_url": "]]..sbAvatar..[[", "embeds": [{"title": "<a:Megaphone:1456376952251351131> Super Broadcast Status", "color": 5763719, "fields": [{"name": "Account Information", "value": "<:Profile:1487287110057594900> **Name : ]]..myName..[[**\n<:Gems:1369733901278511124> **Gems : ]]..UI.FormatNum(startGems)..[[**\n<:BlackGems:1487276323809530107> **Black Gems : ]]..UI.FormatNum(startBGems)..[[**", "inline": false}, {"name": "Location", "value": "<a:World:1456376942189346947> **World : ]] .. UI.SBWorld .. [[**\n<:Textflip:1261276491023646892> **Text : ]].. UI.CleanStr(UI.SBText) ..[[**", "inline": false}, {"name": "SB Information", "value": "🎯 **Target : ]] .. UI.SBMax .. [[**\n<a:Correct:1456306220796215402> **Sent : ]] .. UI.SBCount .. [[**\n<a:Loading:1456634326450966599> **Remain : ]].. sbRemain ..[[**", "inline": false}, {"name": "<:Gems:1369733901278511124> Gems Usage", "value": "**Used : ]].. UI.FormatNum(UI.SBUsedGems) .. [[**\n**Remain : ]].. UI.FormatNum(myGems) .. [[**\n**Total Used : ]].. UI.FormatNum(UI.SBTotUsedGems) .. [[**", "inline": true}, {"name": "<:BlackGems:1487276323809530107> Black Gems Usage", "value": "**Used : ]].. UI.FormatNum(UI.SBUsedBGems) .. [[**\n**Remain : ]].. UI.FormatNum(UI.SBLeftBGems) .. [[**\n**Total Used : ]].. UI.FormatNum(UI.SBTotUsedBGems) .. [[**", "inline": true}], "thumbnail": {"url": "]]..sbAvatar..[["}, "footer": {"text": "Time : ]] .. os.date("%Y-%m-%d %H:%M:%S") .. [[", "icon_url": "]]..sbFooterIcon..[["}}] }]]
                MakeRequest(UI.WebhookSB, "POST", {["Content-Type"] = "application/json"}, payload)
            end
            Sleep(140000)
            
            if UI.SBCount >= UI.SBMax then
                UI.SBEnabled = false
                UI.LocalChat("`c[WinProxy]: `2DONE `eSuper Broadcast `9Completed`4!")
                if UI.WebhookSB ~= "" and UI.DiscordPingID ~= "" then
                    local myGems = (GetPlayerInfo() and GetPlayerInfo().gems) or 0
                    local myName = (GetLocal() and GetLocal().name and GetLocal().name:gsub("`.", "")) or "Unknown"
                    local startGems = myGems + UI.SBTotUsedGems
                    local startBGems = UI.SBLeftBGems + UI.SBTotUsedBGems
                    local sbAvatar = "https://media.discordapp.net/attachments/1438466585005391923/1481856877410390157/WinPFP-Animated.gif"
                    local sbFooterIcon = "https://cdn.discordapp.com/emojis/1481856719230603354.webp"
                    local donePayload = [[{"username": "WinProxy SB", "avatar_url": "]]..sbAvatar..[[", "content": " <@]]..UI.DiscordPingID..[[>", "allowed_mentions": { "parse": ["users"]}, "embeds": [{"title": "<a:Megaphone:1456376952251351131> Super Broadcast Finished!", "color": 5763719, "fields": [{"name": "Account Information", "value": "<:Profile:1487287110057594900> **Name : ]]..myName..[[**\n<:Gems:1369733901278511124> **Gems : ]]..UI.FormatNum(startGems)..[[**\n<:BlackGems:1487276323809530107> **Black Gems : ]]..UI.FormatNum(startBGems)..[[**", "inline": false}, {"name": "Location", "value": "<a:World:1456376942189346947> **World : ]] .. UI.SBWorld .. [[**\n<:Textflip:1261276491023646892> **Text : ]].. UI.CleanStr(UI.SBText) ..[[**", "inline": false}, {"name": "SB Information", "value": "🎯 **Target : ]] .. UI.SBMax .. [[**\n<a:Correct:1456306220796215402> **Total Sent : ]] .. UI.SBCount .. [[**\n<a:Loading:1456634326450966599> **Remain : 0**", "inline": false}, {"name": "<:Gems:1369733901278511124> Gems Usage", "value": "**Used : ]].. UI.FormatNum(UI.SBUsedGems) .. [[**\n**Remain : ]].. UI.FormatNum(myGems) .. [[**\n**Total Used : ]].. UI.FormatNum(UI.SBTotUsedGems) .. [[**", "inline": true}, {"name": "<:BlackGems:1487276323809530107> Black Gems Usage", "value": "**Used : ]].. UI.FormatNum(UI.SBUsedBGems) .. [[**\n**Remain : ]].. UI.FormatNum(UI.SBLeftBGems) .. [[**\n**Total Used : ]].. UI.FormatNum(UI.SBTotUsedBGems) .. [[**", "inline": true}], "thumbnail": { "url": "]]..sbAvatar..[[" }, "footer": { "text": "Time : ]] .. os.date("%Y-%m-%d %H:%M:%S") .. [[", "icon_url": "]]..sbFooterIcon..[[" }}] }]]
                    MakeRequest(UI.WebhookSB, "POST", {["Content-Type"] = "application/json"}, donePayload)
                end
                if UI.SBUseDoneWorld and UI.SBDoneWorld ~= "" then SendPacket(2, "action|input\n|text|/warp " .. UI.SBDoneWorld) end
            end
        end
        UI.SBThreadRunning = false
    end)
end

function UI.ManageSDBThread()
    if UI.SDBThreadRunning then return end
    UI.SDBThreadRunning = true
    RunThread(function()
        UI.LocalChat("`c[WinProxy]: `9Starting `#" .. UI.SDBMax .. " `2SDB `9with delay of `#" .. UI.SDBTotalDelay .. " `bMinutes`0.")
        Sleep(2000)
        while UI.SDBEnabled and UI.SDBCount < UI.SDBMax do
            local hasMegaphone = false
            for _, item in pairs(GetInventory()) do
                if item.id == 2480 and item.amount > 0 then 
                    hasMegaphone = true
                    break 
                end
            end
            if not hasMegaphone then
                UI.LocalChat("`c[WinProxy]: `4You don't have any Megaphone in your inventory. SDB Stopped.")
                UI.SDBEnabled = false
                break
            end
            UI.LocalChat("`c[WinProxy]: `9Executing SDB...")
            Sleep(1000)
            SendPacket(2, "action|dialog_return\ndialog_name|megaphone\nline|"..UI.SDBLine1.."\nline2|"..UI.SDBLine2.."\nline3|"..UI.SDBLine3)
            UI.SDBCount = UI.SDBCount + 1
            Sleep(1000)
            UI.LocalChat("`c[WinProxy]: `2SDB `9Count `0= `0[`2"..UI.SDBCount.."`0/`4"..UI.SDBMax.."`0]")
            if UI.SDBCount >= UI.SDBMax then
                UI.SDBEnabled = false
                UI.LocalChat("`c[WinProxy]: `2DONE `eSuper Duper Broadcast `9Completed`4!")
                break
            end
            if UI.SDBExtraTimer == 0 then
                Sleep(144000)
                UI.LocalChat("`c[WinProxy]: `#3 `bMinutes `9Before Sending `2SDB `9Again`0!")
                Sleep(150000)
            else
                Sleep(294000)
                UI.LocalChat("`c[WinProxy]: `#"..UI.SDBExtraTimer.." `bMinutes `9Before Sending `2SDB `9Again`0!")
                Sleep(UI.SDBExtraTimer * 60000)
            end
        end
        UI.SDBThreadRunning = false
    end)
end


-- ==========================================
-- HELPER : Casino
-- ==========================================

local function remefunc(number)
    if number == 19 or number == 28 or number == 0 then return 0 end
    return tonumber(string.sub(tostring(math.floor(number / 10) + (number % 10)), -1))
end
local function qemefunc(number)
    if number >= 10 then return tonumber(string.sub(tostring(number), -1))
    elseif number == 0 then return 1 else return number end
end
local function lemefunc(number)
    if number == 1 or number == 10 or number == 29 then return 1
    elseif number == 0 or number == 19 or number == 28 then return 0
    else return tonumber(string.sub(tostring(math.floor(number / 10) + (number % 10)), -1)) end
end
local function cemefunc(number)
    if number == 0 or number == 19 or number == 28 then return 0
    elseif number == 1 or number == 10 or number == 29 then return 1
    elseif number == 2 or number == 11 or number == 20 then return 2
    elseif number == 3 or number == 12 or number == 21 or number == 30 then return 3
    else return tonumber(string.sub(tostring(math.floor(number / 10) + (number % 10)), -1)) end
end
local function lewafunc(number)
    local hasil = number
    if number >= 10 then hasil = tonumber(string.sub(tostring(number), -1)) end
    if number == 10 or number == 20 or number == 30 then hasil = 0
    elseif number == 19 or number == 29 or number == 9 then hasil = 9
    elseif number == 1 or number == 11 or number == 21 or number == 31 or number == 0 then hasil = 1 end
    return hasil
end

function UI.GetCasinoText(num, isReal)
    local modeName = ""
    local result = 0
    local statusText = ""
    local prefix = isReal and "`2[REAL] " or "`4[FAKE] "
    
    if UI.CasinoMode == 7 then
        local r_res = remefunc(num)
        local l_res = lemefunc(num)
        local q_res = qemefunc(num)
        local calc_res = "`b[`cReme : `b" .. r_res .. "`b] [`cLeme : `b" .. l_res .. "`b] [`cQeme : `b" .. q_res .. "`b]"
        if UI.CasinoFormatIdx == 2 then
            return prefix .. "`9(" .. num .. ") " .. calc_res
        else
            return prefix .. calc_res .. " `9(" .. num .. ")"
        end
    end

    if UI.CasinoMode == 1 then
        modeName = "Reme"
        result = remefunc(num)
        if result == 0 then statusText = "`2[WIN x3]" elseif result == 1 then statusText = "`4[Lose]" end
    elseif UI.CasinoMode == 2 then
        modeName = "Qeme"
        result = qemefunc(num)
        if result == 0 then statusText = "`2[WIN x3]" elseif result == 1 or num == 0 then statusText = "`4[Lose]" end
    elseif UI.CasinoMode == 3 then
        modeName = "Leme"
        result = lemefunc(num)
        if result == 1 then statusText = "`2[WIN x3]" elseif result == 0 then statusText = "`2[WIN x4]" elseif result == 2 or result == 9 then statusText = "`4[Lose]" end
    elseif UI.CasinoMode == 4 then
        modeName = "Leme S"
        result = lemefunc(num)
        if num == 0 then statusText = "`4[Lose]" elseif result == 0 then statusText = "`2[WIN x5]" elseif result == 1 then statusText = "`2[WIN x3]" elseif result == 2 or result == 9 then statusText = "`4[Lose]" end
    elseif UI.CasinoMode == 5 then
        modeName = "Ceme"
        result = cemefunc(num)
        if result == 0 then statusText = "`2[WIN x4]" elseif result == 1 then statusText = "`4[Lose]" elseif result == 2 then statusText = "`2[WIN x3]" elseif result == 3 then statusText = "`b[HOSTER WIN]" end
    elseif UI.CasinoMode == 6 then
        modeName = "Lewa"
        result = lewafunc(num)
        if result == 9 then statusText = "`2[WIN x3]" elseif result == 0 then statusText = "`2[WIN x" .. UI.CasinoLewaMulti .. "]" end
        if UI.CasinoLewaMulti == 5 and result == 1 then statusText = "`4[Lose]"
        elseif UI.CasinoLewaMulti == 6 and (result == 1 or result == 2) then statusText = "`4[Lose]"
        elseif UI.CasinoLewaMulti == 7 and (result == 1 or result == 2 or result == 3) then statusText = "`4[Lose]" end
    end
    local prefix = isReal and "`2[REAL] " or "`4[FAKE] "
    local final_text = "`b[`c" .. modeName .. " `0: `b" .. result .. "`b]"
    if statusText ~= "" then final_text = final_text .. " " .. statusText end
    
    if UI.CasinoFormatIdx == 2 then
        return prefix .. "`9(" .. num .. ") " .. final_text
    else
        return prefix .. final_text .. " `9(" .. num .. ")"
    end
end

function UI.ToggleCasino(mode)
    if UI.CasinoMode == mode then
        UI.CasinoMode = 0
        UI.LocalChat("`c[WinProxy]: `4Disabled Casino Mode")
    else
        UI.CasinoMode = mode
        local modeNames = {"Reme", "Qeme", "Leme", "Leme S", "Ceme", "Lewa", "All"}
        UI.LocalChat("`c[WinProxy]: `2Enabled " .. modeNames[mode] .. " Mode")
    end
    UI.SaveConfig(true)
end


-- ==========================================
-- HELPER : BTK/BJ
-- ==========================================

function UI.SetBTKCoordByTouch(target, x, y)
    if target == "Host Center" then
        UI.BTK_CenterX = x; UI.BTK_CenterY = y
    elseif target == "Bet P1" then
        UI.BTK_Bet1X = x; UI.BTK_Bet1Y = y
    elseif target == "Bet P2" then
        UI.BTK_Bet2X = x; UI.BTK_Bet2Y = y
    elseif target == "Break P1 (Mid)" then
        UI.BTK_Break1X = x; UI.BTK_Break1Y = y
    elseif target == "Break P2 (Mid)" then
        UI.BTK_Break2X = x; UI.BTK_Break2Y = y
    elseif target == "Tax Drop (Mid)" then
        UI.BTK_TaxX = x; UI.BTK_TaxY = y
    elseif target == "Magplant (Top)" then
        UI.BTK_MagX = x; UI.BTK_MagY = y
    end
    UI.LocalChat("`c[WinProxy]: `2" .. target .. " `9set to `2(" .. x .. ", " .. y .. ")")
    UI.BTK_SelectingTarget = nil
    UI.SaveConfig(true)
end

function UI.BTK_GetPositions()
    local cx, cy = UI.BTK_CenterX, UI.BTK_CenterY
    return {
        b1 = { x = UI.BTK_Bet1X, y = UI.BTK_Bet1Y },
        b2 = { x = UI.BTK_Bet2X, y = UI.BTK_Bet2Y },
        p1 = { { x = UI.BTK_Break1X - 1, y = UI.BTK_Break1Y }, { x = UI.BTK_Break1X, y = UI.BTK_Break1Y }, { x = UI.BTK_Break1X + 1, y = UI.BTK_Break1Y } },
        p2 = { { x = UI.BTK_Break2X - 1, y = UI.BTK_Break2Y }, { x = UI.BTK_Break2X, y = UI.BTK_Break2Y }, { x = UI.BTK_Break2X + 1, y = UI.BTK_Break2Y } },
        tax = { { x = UI.BTK_TaxX - 1, y = UI.BTK_TaxY }, { x = UI.BTK_TaxX, y = UI.BTK_TaxY }, { x = UI.BTK_TaxX + 1, y = UI.BTK_TaxY } },
        drop1 = { x = UI.BTK_Bet1X - 1, y = UI.BTK_Bet1Y },
        drop2 = { x = UI.BTK_Bet2X + 1, y = UI.BTK_Bet2Y },
        center = { x = cx, y = cy }
    }
end

function UI.ParseBetAt(tile)
    if tile.x == 0 and tile.y == 0 then return 0 end
    local total = 0
    for _, o in pairs(GetObjectList()) do
        if math.floor(o.pos.x / 32) == tile.x and math.floor(o.pos.y / 32) == tile.y then
            if o.id == UI.GetIcon("Creativeps Black Gem Lock", 11550) then total = total + (o.amount * 10000)
            elseif o.id == UI.GetIcon("Creativeps Blue Gem Lock", 7188) then total = total + (o.amount * 100)
            elseif o.id == UI.GetIcon("Creativeps Diamond Lock", 1796) then total = total + o.amount end
        end
    end
    return total
end

function UI.CountGemsAt(posList)
    local total = 0
    for _, o in pairs(GetObjectList()) do
        if o.id == 112 then
            local ox, oy = math.floor(o.pos.x / 32), math.floor(o.pos.y / 32)
            for _, p in ipairs(posList) do
                if ox == p.x and oy == p.y then total = total + o.amount break end
            end
        end
    end
    return total
end

function UI.PickupTile(tile)
    if tile.x == 0 and tile.y == 0 then return end
    for _, o in pairs(GetObjectList()) do
        if math.floor(o.pos.x / 32) == tile.x and math.floor(o.pos.y / 32) == tile.y then
            SendPacketRaw(false, {type = 11, value = o.oid, x = o.pos.x, y = o.pos.y})
        end
    end
end

function UI.BTK_PlaceChands(posList)
    for _, tile in ipairs(posList) do
        SendPacketRaw(false, {
            type = 3,
            value = 5640,
            px = tile.x,
            py = tile.y,
            x = tile.x * 32,
            y = tile.y * 32
        })
        Sleep(150)
    end
end

function UI.BTK_ActionTakeRemote()
    if UI.BTK_MagX > 0 then
        RunThread(function()
            local magRealX = UI.BTK_MagX
            local magRealY = UI.BTK_MagY + 1
            FindPath(UI.BTK_MagX, UI.BTK_MagY)
            Sleep(850)
            SendPacketRaw(false, { type = 3, value = 32, x = magRealX * 32, y = magRealY * 32, px = magRealX, py = magRealY, state = 0 })
            Sleep(500)
            SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|"..magRealX.."|\ny|"..magRealY.."|\nbuttonClicked|getRemote")
            UI.LocalChat("`c[WinProxy]: `9Remote collected from Magplant!")
            Sleep(500)
            local pos = UI.BTK_GetPositions()
            FindPath(pos.center.x, pos.center.y)
            Sleep(850)
        end)
    else
        UI.LocalChat("`c[WinProxy]: `4Set Magplant coordinates first!")
    end
end

function UI.BTK_ActionTakeBets()
    local pos = UI.BTK_GetPositions()
    UI.BTK_P1Bet = UI.ParseBetAt(pos.b1)
    UI.BTK_P2Bet = UI.ParseBetAt(pos.b2)
    
    if UI.BTK_P1Bet > 0 and UI.BTK_P1Bet == UI.BTK_P2Bet then
        UI.BTK_TotalPrize = (UI.BTK_P1Bet + UI.BTK_P2Bet) * 0.95
        UI.PickupTile(pos.b1); UI.PickupTile(pos.b2)
        UI.LocalChat("`c[WinProxy]: `9Bets taken! Prize (after 5% tax): `2" .. UI.BTK_TotalPrize .. " DLs")
    else
        UI.LocalChat("`c[WinProxy]: `4Bets un-equal or empty! (P1: " .. UI.BTK_P1Bet .. ", P2: " .. UI.BTK_P2Bet .. ")")
    end
end

function UI.BTK_ActionCheckGems()
    local pos = UI.BTK_GetPositions()
    local g1 = UI.CountGemsAt(pos.p1)
    local g2 = UI.CountGemsAt(pos.p2)
    
    if UI.BTK_Mode == "BJ" then
        if g1 <= 21 and g2 <= 21 then
            if g1 > g2 then 
                UI.BTK_WinnerSide = "Left"
                UI.LocalChat("`c[WinProxy] `b[BJ]: `2[WIN] `0Left `2"..g1.." `0- `4"..g2.." `0Right `4[LOSE]")
            elseif g2 > g1 then 
                UI.BTK_WinnerSide = "Right"
                UI.LocalChat("`c[WinProxy] `b[BJ]: `4[LOSE] `0Left `4"..g1.." `0- `2"..g2.." `0Right `2[WIN]")
            else 
                UI.BTK_WinnerSide = "Draw"
                UI.LocalChat("`c[WinProxy] `b[BJ]: `9[DRAW] `0Left `9"..g1.." `0- `9"..g2.." `0Right `9[DRAW]") 
            end
        elseif g1 <= 21 and g2 > 21 then
            UI.BTK_WinnerSide = "Left"
            UI.LocalChat("`c[WinProxy] `b[BJ]: `2[WIN] `0Left `2"..g1.." `0- `4"..g2.." `0Right `4(Bust) `4[LOSE]")
        elseif g2 <= 21 and g1 > 21 then
            UI.BTK_WinnerSide = "Right"
            UI.LocalChat("`c[WinProxy] `b[BJ]: `4[LOSE] `4(Bust) `0Left `4"..g1.." `0- `2"..g2.." `0Right `2[WIN]")
        else
            local dist1 = math.abs(g1 - 21)
            local dist2 = math.abs(g2 - 21)
            if dist1 < dist2 then
                UI.BTK_WinnerSide = "Left"
                UI.LocalChat("`c[WinProxy] `b[BJ]: `2[WIN] `0Left `2"..g1.." `s(Closest) `0- `4"..g2.." `0Right `4[LOSE]")
            elseif dist2 < dist1 then
                UI.BTK_WinnerSide = "Right"
                UI.LocalChat("`c[WinProxy] `b[BJ]: `4[LOSE] `0Left `4"..g1.." `0- `2"..g2.." `0Right `s(Closest) `2[WIN]")
            else
                UI.BTK_WinnerSide = "Draw"
                UI.LocalChat("`c[WinProxy] `b[BJ]: `9[DRAW] `0Left `9"..g1.." `0- `9"..g2.." `0Right `9[DRAW] `s(Both Over 21)")
            end
        end
    else
        if g1 > g2 then 
            UI.BTK_WinnerSide = "Left"
            UI.LocalChat("`c[WinProxy] `b[BTK]: `2[WIN] `0Left `2"..g1.." `0- `4"..g2.." `0Right `4[LOSE]")
        elseif g2 > g1 then 
            UI.BTK_WinnerSide = "Right"
            UI.LocalChat("`c[WinProxy] `b[BTK]: `4[LOSE] `0Left `4"..g1.." `0- `2"..g2.." `0Right `2[WIN]")
        else 
            UI.BTK_WinnerSide = "Draw"
            UI.LocalChat("`c[WinProxy] `b[BTK]: `9[DRAW] `0Left `9"..g1.." `0- `9"..g2.." `0Right `9[DRAW]") 
        end
    end
end

function UI.BTK_ActionDropReset()
    local pos = UI.BTK_GetPositions()
    local standX, standY = 0, 0
    
    if UI.BTK_WinnerSide == "Left" then 
        standX = UI.BTK_Bet1X - 2
        standY = UI.BTK_Bet1Y
    elseif UI.BTK_WinnerSide == "Right" then 
        standX = UI.BTK_Bet2X + 2
        standY = UI.BTK_Bet2Y
    end
    
    if standX > 0 and standY > 0 then
        RunThread(function()
            local function executeSmartDrop(amountDL)
                local drop_black = math.floor(amountDL / 10000)
                local rem1 = amountDL % 10000
                local drop_bgl = math.floor(rem1 / 100)
                local rem2 = rem1 % 100
                local drop_dl = math.floor(rem2)
                local drop_wl = math.floor((rem2 - drop_dl) * 100 + 0.5)
                
                if drop_black > 0 and UI.GetItemCount(UI.GetIcon("Creativeps Black Gem Lock", 11550)) >= drop_black then
                    SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. UI.GetIcon("Creativeps Black Gem Lock", 11550) .. "|\nitem_count|" .. drop_black)
                    Sleep(600)
                end
                if drop_bgl > 0 then
                    while UI.GetItemCount(UI.GetIcon("Creativeps Blue Gem Lock", 7188)) < drop_bgl do
                        if UI.GetItemCount(UI.GetIcon("Creativeps Black Gem Lock", 11550)) > 0 then
                            SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bluegl")
                            Sleep(1000)
                        else
                            break
                        end
                    end
                    if UI.GetItemCount(UI.GetIcon("Creativeps Blue Gem Lock", 7188)) >= drop_bgl then
                        SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. UI.GetIcon("Creativeps Blue Gem Lock", 7188) .. "|\nitem_count|" .. drop_bgl)
                        Sleep(600)
                    end
                end
                if drop_dl > 0 then
                    while UI.GetItemCount(UI.GetIcon("Creativeps Diamond Lock", 1796)) < drop_dl do
                        if UI.GetItemCount(UI.GetIcon("Creativeps Blue Gem Lock", 7188)) > 0 then
                            SendPacketRaw(false, {type = 10, value = 7188})
                            Sleep(1000)
                        elseif UI.GetItemCount(UI.GetIcon("Creativeps Black Gem Lock", 11550)) > 0 then
                            SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bluegl")
                            Sleep(1000)
                        else
                            break
                        end
                    end
                    if UI.GetItemCount(UI.GetIcon("Creativeps Diamond Lock", 1796)) >= drop_dl then
                        SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. UI.GetIcon("Creativeps Diamond Lock", 1796) .. "|\nitem_count|" .. drop_dl)
                        Sleep(600)
                    end
                end
                if drop_wl > 0 then
                    while UI.GetItemCount(UI.GetIcon("Creativeps World Lock", 242)) < drop_wl do
                        if UI.GetItemCount(UI.GetIcon("Creativeps Diamond Lock", 1796)) > 0 then
                            SendPacketRaw(false, {type = 10, value = 1796})
                            Sleep(1000)
                        elseif UI.GetItemCount(UI.GetIcon("Creativeps Blue Gem Lock", 7188)) > 0 then
                            SendPacketRaw(false, {type = 10, value = 7188})
                            Sleep(1000)
                        elseif UI.GetItemCount(UI.GetIcon("Creativeps Black Gem Lock", 11550)) > 0 then
                            SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bluegl")
                            Sleep(1000)
                        else
                            break
                        end
                    end
                    if UI.GetItemCount(UI.GetIcon("Creativeps World Lock", 242)) >= drop_wl then
                        SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. UI.GetIcon("Creativeps World Lock", 242) .. "|\nitem_count|" .. drop_wl)
                        Sleep(600)
                    end
                end
            end

            FindPath(standX, standY)
            Sleep(850)
            executeSmartDrop(UI.BTK_TotalPrize)
            UI.LocalChat("`c[WinProxy]: `9Dropped Prize: `2" .. UI.BTK_TotalPrize .. " DLs")
            Sleep(500)
                        
            FindPath(pos.center.x, pos.center.y)
            Sleep(800)
                        
            local totalPool = UI.BTK_P1Bet + UI.BTK_P2Bet
            local totalPool = UI.BTK_P1Bet + UI.BTK_P2Bet
            local taxToDrop = (totalPool * 0.05) / 2
            local taxMidX = pos.tax[2].x
            local taxMidY = pos.tax[2].y
            
            if taxToDrop > 0 and taxMidX > 0 then
                pcall(function() ChangeValue("[C] Modfly", true) end)
                FindPath(taxMidX, taxMidY)
                Sleep(850)
                executeSmartDrop(taxToDrop)
                UI.LocalChat("`c[WinProxy]: `9Dropped Tax (50%%): `2" .. taxToDrop .. " DLs")
                Sleep(500)
                pcall(function() ChangeValue("[C] Modfly", false) end)
            end
            
            for _, tile in ipairs(pos.p1) do 
                FindPath(tile.x, tile.y)
                Sleep(400)
                SendPacketRaw(false, { type = 3, value = 5640, px = tile.x, py = tile.y, x = tile.x * 32, y = tile.y * 32 })
                Sleep(150)
            end
            
            for _, tile in ipairs(pos.p2) do 
                FindPath(tile.x, tile.y)
                Sleep(400)
                SendPacketRaw(false, { type = 3, value = 5640, px = tile.x, py = tile.y, x = tile.x * 32, y = tile.y * 32 })
                Sleep(150)
            end
            
            UI.BTK_TotalPrize = 0; UI.BTK_P1Bet = 0; UI.BTK_P2Bet = 0; UI.BTK_WinnerSide = nil
            
            FindPath(pos.center.x, pos.center.y)
            Sleep(850)
        end)
    else
        UI.LocalChat("`c[WinProxy]: `4Draw/Target Drop invalid! Drop manually.")
    end
end


-- ==========================================
-- HELPER : Auto Pull
-- ==========================================

function UI.GetSpawnTile()
    local now = os.clock()
    if UI.CachedSpawnX and UI.CachedSpawnY and (now - UI.LastSpawnScanTime < 5.0) then
        return UI.CachedSpawnX, UI.CachedSpawnY
    end
    local isTilesSuccess, worldTiles = pcall(GetTiles)
    if isTilesSuccess and worldTiles then
        for _, tile in pairs(worldTiles) do
            if tile and (tile.fg == 6 or tile.id == 6 or tile.foreground == 6) then
                UI.CachedSpawnX, UI.CachedSpawnY = tile.x, tile.y
                UI.LastSpawnScanTime = now
                return tile.x, tile.y
            end
        end
    end
    return nil, nil
end

function UI.GetTargetPullTile()
    local customX = tonumber(UI.AutoPullTileX) or 0
    local customY = tonumber(UI.AutoPullTileY) or 0
    if customX > 0 and customY > 0 then
        return customX, customY, true
    end
    local dx, dy = UI.GetSpawnTile()
    return dx, dy, false
end

function UI.CheckAndExecutePull(playerObj, reason)
    if not playerObj then return end
    local netID = tonumber(playerObj.netID or playerObj.netid)
    local userID = tonumber(playerObj.userid or playerObj.userID)
    local playerName = playerObj.name or "Unknown"
    if not netID then return end

    if Filter(playerName):lower():find("spammer slave") then return end

    if userID then
        for _, blockedUID in ipairs(UI.AutoPullBlacklist) do
            if tonumber(blockedUID) == userID then return end
        end
    end

    local now = os.clock()
    local cooldownLimit = reason:find("Area Scan") and 0.05 or 0.5
    if UI.AptCooldown[netID] and (now - UI.AptCooldown[netID] < cooldownLimit) then return end

    local min_modal = tonumber(UI.AutoPullMinModal) or 0
    if min_modal <= 0 then
        UI.AptCooldown[netID] = now
        
        SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netID .. "|\nbuttonClicked|pull")
        RunThread(function()
            Sleep(50)
            SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netID .. "|\nbuttonClicked|pull")
        end)
        
        local cleanName = Filter(playerName)
        if UI.WrenchPullText ~= "" then
            local msg = UI.WrenchPullText:gsub("{GrowID}", cleanName)
            SendPacket(2, "action|input\n|text|" .. msg)
        end
        UI.LocalChat("`c[WinProxy]: `w[`2APT`w] Auto Pulled `2" .. cleanName .. " `w(" .. reason .. ")")
        
        if UI.ShowBal then
            RunThread(function() Sleep(250); SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netID .. "|\nbuttonClicked|viewinv") end)
        end
    else
        UI.AptCooldown[netID] = now
        UI.PendingModalPull[netID] = {
            netid = netID,
            userid = userID,
            name = Filter(playerName),
            reason = reason,
            timestamp = now
        }
        SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netID .. "|\nbuttonClicked|viewinv")
    end
end

function UI.ManageAreaPullThread()
    if UI.AreaPullThreadRunning then return end
    UI.AreaPullThreadRunning = true
    RunThread(function()
        while UI.AutoPullAreaScan do
            local pList = GetPlayerList()
            if pList then
                local lp = GetLocal()
                local lpNetID = lp and lp.netid or -1
                
                for _, p in pairs(pList) do
                    if p.pos and p.pos.x and p.pos.y and p.netid ~= lpNetID then
                        local pxCenter = math.floor((p.pos.x + 16) / 32)
                        local pyCenter = math.floor((p.pos.y + 16) / 32)
                        local rawPx = math.floor(p.pos.x / 32)
                        local rawPy = math.floor(p.pos.y / 32)
                        
                        for i = 1, 5 do
                            local targetX = UI.AutoPullPos[i].x
                            local targetY = UI.AutoPullPos[i].y
                            if targetX > 0 and targetY > 0 then
                                local xMatch = (pxCenter == targetX or rawPx == targetX)
                                local yMatch = (pyCenter == targetY or rawPy == targetY or pyCenter == targetY + 1 or rawPy == targetY + 1)
                                
                                if xMatch and yMatch then
                                    UI.CheckAndExecutePull(p, "Area Scan (Pos " .. i .. ")")
                                    break
                                end
                            end
                        end
                    end
                end
            end
            Sleep(20) 
        end
        UI.AreaPullThreadRunning = false
    end)
end

function UI.FindClosestPlayer(pos)
    local isLocalSuccess, localPlayer = pcall(GetLocal)
    local localNetID = isLocalSuccess and localPlayer and tonumber(localPlayer.netID or localPlayer.netid) or nil
    local isListSuccess, playerList = pcall(GetPlayerList)
    if not isListSuccess or not playerList then return nil end

    local targetX = tonumber(pos.x)
    local targetY = tonumber(pos.y)
    local closestPlayer = nil
    local minDistanceSq = nil
    local maxSearchRadiusSq = 1280

    for _, player in pairs(playerList) do
        local playerNetID = tonumber(player.netID or player.netid)
        local playerPos = player and player.pos
        if playerNetID and playerPos and playerPos.x and playerPos.y and playerNetID ~= localNetID then
            local dx = tonumber(playerPos.x) - targetX
            local dy = tonumber(playerPos.y) - targetY
            local distSq = (dx * dx) + (dy * dy)
            if distSq <= maxSearchRadiusSq and (not minDistanceSq or distSq < minDistanceSq) then
                closestPlayer = player
                minDistanceSq = distSq
            end
        end
    end
    return closestPlayer
end


-- ==========================================
-- HELPER : Auto Buy Pack
-- ==========================================

function UI.ManageABPThread()
    if UI.ABP_ThreadRunning then return end
    UI.ABP_ThreadRunning = true
    RunThread(function()
        local DropPosY = {}
        local currentPack = UI.ABP_Packs[UI.ABP_PackIdx]
        UI.ABP_DetectedDropIDs = {} 
        local OrderedDropIDs = {}
        UI.ABP_ForceDrop = false 
        
        if currentPack.items then
            for _, itm in ipairs(currentPack.items) do
                UI.ABP_DetectedDropIDs[itm.id] = true
                table.insert(OrderedDropIDs, itm.id)
            end
        end
        
        local function SafeMoveTo(tx, ty)
            for attempt = 1, 100 do 
                local lp = GetLocal()
                if not lp then return false end
                local cx = math.floor(lp.pos.x / 32)
                local cy = math.floor(lp.pos.y / 32)
                if cx == tx and cy == ty then return true end
                local dx = tx - cx
                local dy = ty - cy
                local dist = math.sqrt(dx*dx + dy*dy)
                if dist > 3 then
                    local stepX = cx + math.floor((dx / dist) * 3)
                    local stepY = cy + math.floor((dy / dist) * 3)
                    FindPath(stepX, stepY)
                else
                    FindPath(tx, ty)
                end
                Sleep(150)
            end
            return false
        end
        
        UI.LocalChat("`c[WinProxy]: `9Auto Buy Pack Started. Target: `2" .. currentPack.name)
        if UI.ABP_BatchMode then UI.LocalChat("`c[WinProxy]: `e[BATCH MODE ON] `wBuying multiple times until full, then dropping!") end
        
        local packsBought = 0
        while UI.AutoBuyPack do
            if UI.ABP_BuyAmount > 0 and packsBought >= UI.ABP_BuyAmount then
                UI.AutoBuyPack = false
                UI.LocalChat("`c[WinProxy]: `2Finished buying " .. UI.ABP_BuyAmount .. " packs!")
                break
            end
            
            local preInv = {}
            for _, itm in pairs(GetInventory()) do
                preInv[itm.id] = (preInv[itm.id] or 0) + itm.amount
            end
            
            SendPacket(2, "action|buy\nitem|" .. currentPack.cmd)
            Sleep(800) 
            
            local purchaseSuccess = false
            local invFullWarning = false
            
            for _, itm in pairs(GetInventory()) do
                local oldAmt = preInv[itm.id] or 0
                if itm.amount > oldAmt then
                    purchaseSuccess = true
                    if not UI.ABP_DetectedDropIDs[itm.id] then
                        UI.ABP_DetectedDropIDs[itm.id] = true
                        table.insert(OrderedDropIDs, itm.id)
                        UI.LocalChat("`c[WinProxy]: `9Smart Detect learned ID: `2" .. itm.id)
                    end
                end
                if UI.ABP_DetectedDropIDs[itm.id] and itm.amount >= 180 then
                    invFullWarning = true
                end
            end
            
            if UI.ABP_ForceDrop then
                invFullWarning = true
                UI.ABP_ForceDrop = false
            end
            
            if not purchaseSuccess and not invFullWarning then
                UI.LocalChat("`c[WinProxy]: `4[WARNING] `wPurchase failed! (Out of Gems/Balance).")
                UI.LocalChat("`c[WinProxy]: `wAuto Buy Pack is now `4STOPPED`w.")
                UI.AutoBuyPack = false
                break
            end
            
            if purchaseSuccess then packsBought = packsBought + 1 end
            
            local shouldDrop = false
            if UI.ABP_BuyOnly then shouldDrop = false
            elseif not UI.ABP_BatchMode then shouldDrop = true 
            elseif invFullWarning or (UI.ABP_BuyAmount > 0 and packsBought >= UI.ABP_BuyAmount) then shouldDrop = true end
            
            if shouldDrop then
                table.sort(OrderedDropIDs)
                
                local originalAntiPickupStatus = UI.AntiPickup
                UI.AntiPickup = true
                pcall(function() ChangeValue("[C] Modfly", true) end)
                
                local lastPosX, lastPosY = nil, nil
                local maxPerRow = 10 
                
                for dropIndex, id in ipairs(OrderedDropIDs) do
                    local invCount = UI.GetItemCount(id)
                    if invCount > 0 then
                        local offsetX = (dropIndex - 1) % maxPerRow
                        local offsetY = math.floor((dropIndex - 1) / maxPerRow)
                        if not DropPosY[dropIndex] then DropPosY[dropIndex] = UI.ABP_DropY - offsetY end
                        
                        local posx = UI.ABP_DropX + offsetX
                        local posy = DropPosY[dropIndex]
                        lastPosX = posx
                        lastPosY = posy
                        
                        SafeMoveTo(posx - 1, posy)
                        Sleep(250)
                        
                        for attempt = 1, 24 do
                            local currentCount = UI.GetItemCount(id)
                            if currentCount > 0 then
                                SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. id .. "|\nitem_count|" .. currentCount)
                                Sleep(400)
                            else break end
                        end
                        if UI.GetItemCount(id) > 0 then DropPosY[dropIndex] = DropPosY[dropIndex] - 1 end
                    end
                end
                
                SafeMoveTo(UI.ABP_DropX - 1, UI.ABP_DropY)
                Sleep(300)
                pcall(function() ChangeValue("[C] Modfly", false) end)
                UI.AntiPickup = originalAntiPickupStatus
            end
            Sleep(200)
        end
        UI.ABP_ThreadRunning = false
    end)
end


-- ==========================================
-- HELPER : All Logs
-- ==========================================

function UI.AddLog(category, text)
    if not UI.LogsEnabled then return end
    local timeStr = os.date("%H:%M:%S")
    local logEntry = string.format("[%s] %s", timeStr, text)
    if UI.Logs[category] then
        table.insert(UI.Logs[category], 1, logEntry)
        if #UI.Logs[category] > UI.MaxLogs then table.remove(UI.Logs[category], UI.MaxLogs + 1) end
    end
    table.insert(UI.Logs.All, 1, logEntry)
    if #UI.Logs.All > UI.MaxLogs then table.remove(UI.Logs.All, UI.MaxLogs + 1) end
end


-- ==========================================
-- UI : Render ImGui
-- ==========================================

function UI.RenderImGui()
    if not UI.ShowImGui then return end
    
    if ImGui.SetNextWindowPos then
        pcall(ImGui.SetNextWindowPos, ImVec2(0, 25))
    end
    
    ImGui.SetNextWindowSize(ImVec2(600, 450), ImGui.Cond.FirstUseEver)

    if ImGui.SetNextWindowSizeConstraints then
        ImGui.SetNextWindowSizeConstraints(ImVec2(600, 490), ImVec2(2000, 2000))
    end

    local isExpanded, isOpen = ImGui.Begin("CreativePS Proxy: Win Community", true)

    if isOpen == false then
        UI.ShowImGui = false
        UI.SaveConfig(true)
        UI.LocalChat("`c[WinProxy]: `9ImGui Menu is now `4CLOSED `9(Use /imgui to reopen)")
    end

    if isExpanded then
        ImGui.Columns(2, "MenuColumns", true)
        ImGui.SetColumnWidth(0, 185)

        ImGui.Text(utf8.char(0xf015) .. " Win Community Script")
        ImGui.Separator()
        ImGui.Spacing()

        ImGui.BeginChild("TabArea", ImVec2(0, 0), false)
        for _, tab in ipairs(UI.Tabs) do
            local displayTab = tab:gsub(" ", " | ", 1) 
            if ImGui.Selectable(displayTab, UI.CurrentTab == tab) then 
                UI.CurrentTab = tab 
            end
        end
        ImGui.EndChild()

        ImGui.NextColumn()
        
        ImGui.BeginChild("ContentArea", ImVec2(0, 0), false)
        local headerColor = ImVec4(0.2, 0.8, 1.0, 1.0)
        
        if UI.CurrentTab == utf8.char(0xf015) .. " Welcome" then
            ImGui.Spacing()
            ImGui.TextColored(ImVec4(0.2, 0.8, 1.0, 1.0), "========================================")
            ImGui.Spacing()
            ImGui.TextColored(ImVec4(1.0, 1.0, 1.0, 1.0), "                 W I N - C O M M U N I T Y   P R O X Y")
            ImGui.TextColored(ImVec4(0.4, 0.8, 0.4, 1.0), "                    The Best CreativePS Proxy Script")
            ImGui.Spacing()
            ImGui.TextColored(ImVec4(0.2, 0.8, 1.0, 1.0), "========================================")
            ImGui.Spacing()
            ImGui.Separator()

            local currentTime = os.date("%Y-%m-%d %H:%M:%S")
            ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), utf8.char(0xf017) .. " Current Time: " .. currentTime)
            ImGui.Separator()
            ImGui.Spacing()

            ImGui.TextColored(ImVec4(0.8, 0.6, 1.0, 1.0), utf8.char(0xf007) .. " Player Information")
            local growid, uid, worldName = "Unknown", "Unknown", "Unknown"
            local posX, posY = 0, 0 
            
            local okLocal, player = pcall(function() return GetLocal() end)
            local okWorld, world = pcall(function() return GetWorld() end)
            
            if okLocal and player then
                growid = player.name and player.name:gsub("`(%S)", ""):match("%S+") or "Unknown"
                uid = player.userid or "Unknown"
                if player.pos then
                    posX = math.floor(player.pos.x / 32)
                    posY = math.floor(player.pos.y / 32)
                end
            end
            
            if okWorld and world then worldName = world.name or "Unknown" end

            ImGui.Indent(20)
            ImGui.TextColored(ImVec4(0.7, 0.7, 1.0, 1.0), "GrowID: " .. growid)
            ImGui.TextColored(ImVec4(0.7, 0.7, 1.0, 1.0), "UID: " .. uid)
            ImGui.TextColored(ImVec4(0.7, 0.7, 1.0, 1.0), "Current World: " .. worldName)
            ImGui.TextColored(ImVec4(0.4, 1.0, 0.4, 1.0), string.format("Position: X: %d | Y: %d", posX, posY))
            ImGui.Unindent(20)
            ImGui.Spacing()
            ImGui.Separator()
            ImGui.Spacing()

            ImGui.TextColored(ImVec4(0.6, 1.0, 0.6, 1.0), utf8.char(0xf06b) .. " Thank you for using our proxy script!")
            ImGui.TextWrapped("This panel provides advanced tools for Growtopia automation and enhancement. Navigate using the menu on the left.")
            ImGui.Spacing()
            ImGui.Separator()
            
            ImGui.TextColored(ImVec4(1.0, 0.7, 0.3, 1.0), utf8.char(0xf0e7) .. " Quick Actions")
            if ImGui.Button(utf8.char(0xf085) .. " Open Settings", ImVec2(ImGui.GetWindowWidth()/2 - 15, 30)) then 
                UI.CurrentTab = utf8.char(0xf085) .. " Setting" 
            end
            ImGui.SameLine()
            if ImGui.Button(utf8.char(0xf05a) .. " Information", ImVec2(ImGui.GetWindowWidth()/2 - 15, 30)) then 
                UI.CurrentTab = utf8.char(0xf05a) .. " Information" 
            end
            if ImGui.Button(utf8.char(0xf0c9) .. " Show Menu Dialog (/menu)", ImVec2(ImGui.GetWindowWidth() - 20, 30)) then 
                UI.ShowMainDialog() 
            end
            ImGui.Spacing()

        elseif UI.CurrentTab == utf8.char(0xf120) .. " Commands" then
            ImGui.TextColored(headerColor, utf8.char(0xf120) .. " Command Center")
            ImGui.Separator()
            ImGui.Spacing()

            if ImGui.CollapsingHeader(utf8.char(0xf021) .. " Custom Commands (Alias)", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.Spacing()
                ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Map your own shortcut commands (e.g., /di -> /dbl)")
                
                ImGui.PushItemWidth(130)
                local custChanged, newCust = ImGui.InputTextWithHint("##newCust", "Your Alias (e.g. /di)", UI.TempCust, 32)
                if custChanged then UI.TempCust = newCust end
                ImGui.SameLine()
                local origChanged, newOrig = ImGui.InputTextWithHint("##newOrig", "Original (e.g. /dbl)", UI.TempOrig, 32)
                if origChanged then UI.TempOrig = newOrig end
                ImGui.PopItemWidth()
                
                ImGui.SameLine()
                if UI.TempDisableOrig == nil then UI.TempDisableOrig = true end
                local disChanged, newDis = ImGui.Checkbox("Disable Orig", UI.TempDisableOrig)
                if disChanged then UI.TempDisableOrig = newDis end
                
                if ImGui.Button(utf8.char(0xf067) .. " Add Alias") and UI.TempCust ~= "" and UI.TempOrig ~= "" then
                    if UI.TempCust:sub(1,1) ~= "/" then UI.TempCust = "/" .. UI.TempCust end
                    if UI.TempOrig:sub(1,1) ~= "/" then UI.TempOrig = "/" .. UI.TempOrig end
                    UI.CustomCommands[UI.TempCust] = { orig = UI.TempOrig, disableOrig = UI.TempDisableOrig }
                    UI.TempCust = ""
                    UI.TempOrig = ""
                    UI.SaveConfig(true)
                end
                
                ImGui.Spacing()
                ImGui.Columns(4, "AliasTable", true)
                ImGui.SetColumnWidth(0, 110)
                ImGui.SetColumnWidth(1, 130)
                ImGui.SetColumnWidth(2, 90)
                ImGui.SetColumnWidth(3, 60)
                
                ImGui.TextColored(ImVec4(1.0, 0.8, 0.2, 1.0), "Alias") ImGui.NextColumn()
                ImGui.TextColored(ImVec4(1.0, 0.8, 0.2, 1.0), "Original") ImGui.NextColumn()
                ImGui.TextColored(ImVec4(1.0, 0.8, 0.2, 1.0), "Disabled Ori") ImGui.NextColumn()
                ImGui.TextColored(ImVec4(1.0, 0.8, 0.2, 1.0), "Act") ImGui.NextColumn()
                ImGui.Separator()
                
                for cust, data in pairs(UI.CustomCommands) do
                    ImGui.TextColored(ImVec4(0.4, 1.0, 0.4, 1.0), cust) ImGui.NextColumn()
                    ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), data.orig) ImGui.NextColumn()
                    local disColor = data.disableOrig and ImVec4(1.0, 0.4, 0.4, 1.0) or ImVec4(0.8, 0.8, 0.8, 1.0)
                    ImGui.TextColored(disColor, tostring(data.disableOrig)) ImGui.NextColumn()
                    if ImGui.Button("Del##"..cust) then
                        UI.CustomCommands[cust] = nil
                        UI.SaveConfig(true)
                    end
                    ImGui.NextColumn()
                    ImGui.Separator()
                end
                ImGui.Columns(1)
                ImGui.Spacing()
            end

            if ImGui.CollapsingHeader(utf8.char(0xf02d) .. " Command Manual Book", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.Spacing()
                ImGui.BeginChild("CommandsListArea", ImVec2(0, 0), false)
                local cmdHeaderColor = ImVec4(1.0, 0.8, 0.2, 1.0)
                local cmdColor = ImVec4(0.6, 1.0, 0.6, 1.0)
                local colWidth = 240

                local function DrawCmdRow(cmd, desc)
                    ImGui.TextColored(cmdColor, utf8.char(0xf105) .. " " .. cmd)
                    ImGui.NextColumn()
                    ImGui.TextColored(ImVec4(0.8, 0.9, 1.0, 1.0), desc)
                    ImGui.NextColumn()
                    ImGui.Separator()
                end
                local function BeginCmdTable(id, icon, title)
                    ImGui.TextColored(cmdHeaderColor, icon .. " " .. title)
                    ImGui.Spacing()
                    ImGui.Columns(2, id, true)
                    ImGui.SetColumnWidth(0, colWidth)
                    ImGui.TextColored(ImVec4(1.0, 0.4, 0.4, 1.0), utf8.char(0xf120) .. " Commands")
                    ImGui.NextColumn()
                    ImGui.TextColored(ImVec4(0.4, 1.0, 0.4, 1.0), utf8.char(0xf05a) .. " Description")
                    ImGui.NextColumn()
                    ImGui.Separator()
                end
                local function EndCmdTable()
                    ImGui.Columns(1)
                    ImGui.Spacing()
                    ImGui.Spacing()
                end

                BeginCmdTable("Tbl_Casino", utf8.char(0xf522), "Casino Modes")
                DrawCmdRow("/casinomenu", "Open Casino Menu directly.")
                DrawCmdRow("/allmode", "Toggle All (Reme, Leme, Qeme) mode.")
                DrawCmdRow("/reme", "Toggle Reme calculator mode.")
                DrawCmdRow("/qeme", "Toggle Qeme calculator mode.")
                DrawCmdRow("/leme", "Toggle Leme calculator mode.")
                DrawCmdRow("/lemes", "Toggle Leme S calculator mode.")
                DrawCmdRow("/ceme", "Toggle Ceme calculator mode.")
                DrawCmdRow("/lewa <num>", "Set Lewa multiplier and Enable.")
                EndCmdTable()

                BeginCmdTable("Tbl_AutoPull", utf8.char(0xf019), "Auto Pull & Settings")
                DrawCmdRow("/autopullmenu", "Open Auto Pull Menu directly.")
                DrawCmdRow("/autopull", "Toggle Auto Pull Master.")
                DrawCmdRow("/posautopull", "Set Auto Pull target to your tile.")
                DrawCmdRow("/clearposautopull", "Reset target back to White Door.")
                DrawCmdRow("/apblacklist add <uid>", "Add UID to Auto Pull blacklist.")
                DrawCmdRow("/apblacklist remove <uid>", "Remove UID from blacklist.")
                DrawCmdRow("/apblacklist list", "Show current blacklist in chat.")
                EndCmdTable()

                BeginCmdTable("Tbl_Wrench", utf8.char(0xf0ad), "Wrench Controls")
                DrawCmdRow("/wrenchmenu", "Open Wrench Menu directly.")
                DrawCmdRow("/wrp, /wrps", "Auto Pull (Left Click / Right Click).")
                DrawCmdRow("/wrk, /wrks", "Auto Kick (Left Click / Right Click).")
                DrawCmdRow("/wrb, /wrbs", "Auto World Ban (Left Click / Right Click).")
                DrawCmdRow("/wrt, /wrts", "Auto Trade (Left Click / Right Click).")
                DrawCmdRow("/showbal", "Toggle fast balance on inspect.")
                EndCmdTable()

                BeginCmdTable("Tbl_Donate", utf8.char(0xf4c0), "Smart Donation")
                DrawCmdRow("/donatemenu", "Open Donate Menu directly.")
                DrawCmdRow("/dmode", "Toggle Smart Donation Mode.")
                DrawCmdRow("/pw <qty>", "Remote Donate World Lock.")
                DrawCmdRow("/pd <qty>", "Remote Donate Diamond Lock.")
                DrawCmdRow("/pb <qty>", "Remote Donate Blue Gem Lock.")
                DrawCmdRow("/pbl <qty>", "Remote Donate Black Gem Lock.")
                DrawCmdRow("/pall", "Remote Donate All Locks in inventory.")
                DrawCmdRow("/takeall", "Retrieve all items from Donation Box.")
                EndCmdTable()

                BeginCmdTable("Tbl_Trade", utf8.char(0xf2b5), "Advanced Trading")
                DrawCmdRow("/trademenu", "Open Trade Menu directly.")
                DrawCmdRow("/tmode", "Toggle Trade Wrench Mode.")
                DrawCmdRow("/tw <qty>", "Fast add World Lock to trade.")
                DrawCmdRow("/td <qty>", "Fast add Diamond Lock to trade.")
                DrawCmdRow("/tb <qty>", "Fast add Blue Gem Lock to trade.")
                DrawCmdRow("/tbl <qty>", "Fast add Black GL to trade.")
                DrawCmdRow("/tall", "Fast add All Locks to trade.")
                DrawCmdRow("/tclear", "Clear all locks from Trade window.")
                EndCmdTable()

                BeginCmdTable("Tbl_Tele", utf8.char(0xf095), "Telephone Commands")
                DrawCmdRow("/telemenu", "Open Telephone Menu directly.")
                DrawCmdRow("/cvdl", "Auto Convert DL to BGL.")
                DrawCmdRow("/buybgl", "Auto Buy Blue Gem Lock.")
                DrawCmdRow("/buydl", "Auto Buy Diamond Lock.")
                DrawCmdRow("/buychamp", "Auto Buy Champagne (Normal).")
                DrawCmdRow("/buychampbg", "Auto Buy Champagne (Black Gems).")
                DrawCmdRow("/buychampbulk", "Auto Buy Bulk Champagne.")
                EndCmdTable()

                BeginCmdTable("Tbl_Calc", utf8.char(0xf1ec), "Smart Calculator")
                DrawCmdRow("/calcmenu", "Open Calculator Menu directly.")
                DrawCmdRow("/calc <form>", "Calculate math instantly.")
                EndCmdTable()

                BeginCmdTable("Tbl_Spam", utf8.char(0xf4ad), "Auto-Spam Settings")
                DrawCmdRow("/spammenu", "Open Spam UI Menu directly.")
                DrawCmdRow("/spam", "Toggle Auto-Spam on/off.")
                DrawCmdRow("/addspam <txt>", "Add a new spam message.")
                DrawCmdRow("/removespam", "Remove last spam message.")
                DrawCmdRow("/spamtext <#> <txt>", "Edit specific spam line.")
                EndCmdTable()

                BeginCmdTable("Tbl_SB", utf8.char(0xf0a1), "Super Broadcast")
                DrawCmdRow("/sbmenu", "Open SB & SDB Menu directly.")
                DrawCmdRow("/sbstart", "Start Super Broadcast.")
                DrawCmdRow("/sbstop", "Stop Super Broadcast.")
                DrawCmdRow("/sdbstart", "Start Super Duper Broadcast.")
                DrawCmdRow("/sdbstop", "Stop Super Duper Broadcast.")
                EndCmdTable()

                BeginCmdTable("Tbl_Emoji", utf8.char(0xf53f), "Emoji & Color Customization")
                DrawCmdRow("/emojimenu", "Open Emoji Menu directly.")
                DrawCmdRow("/emoji", "Toggles Random Chat Emojis.")
                DrawCmdRow("/watermark", "Toggles Custom Chat Watermark.")
                EndCmdTable()

                BeginCmdTable("Tbl_Logs", utf8.char(0xf022), "Logs & History")
                DrawCmdRow("/logsmenu", "Open main Logs Menu Dialog.")
                DrawCmdRow("/logs", "Toggle activity logging on/off.")
                DrawCmdRow("/clogs", "Open Collect Logs directly.")
                DrawCmdRow("/dlogs", "Open Drop Logs directly.")
                DrawCmdRow("/invlogs", "Open Inventory Logs directly.")
                DrawCmdRow("/slogs", "Open Casino/Spin Logs directly.")
                EndCmdTable()

                BeginCmdTable("Tbl_Economy", utf8.char(0xf2b5), "Economy & Drop")
                DrawCmdRow("/dw <qty>", "Auto drop World Lock.")
                DrawCmdRow("/dd <qty>", "Auto drop Diamond Lock.")
                DrawCmdRow("/db <qty>", "Auto drop Blue Gem Lock.")
                DrawCmdRow("/dbl <qty>", "Auto drop Black Gem Lock.")
                DrawCmdRow("/daw", "Drop all locks in backpack.")
                DrawCmdRow("/depo <qty>", "Deposit BGL to bank.")
                DrawCmdRow("/with <qty>", "Withdraw BGL from bank.")
                DrawCmdRow("/blue", "Convert Black GL to Blue GL.")
                DrawCmdRow("/black", "Convert Blue GL to Black GL.")
                EndCmdTable()

                BeginCmdTable("Tbl_General", utf8.char(0xf013), "General Proxy Features")
                DrawCmdRow("/antilag", "Toggle Anti-Lag (Particle/Shadow).")
                DrawCmdRow("/hidespammer", "Toggle Hide Spammer Slave.")
                DrawCmdRow("/antipickup", "Toggle Anti-Pickup items.")
            DrawCmdRow("/modfly", "Toggle Modfly.")
            DrawCmdRow("/antiportal", "Toggle Anti-Portal.")
            DrawCmdRow("/nightvision", "Toggle Night Vision.")
                DrawCmdRow("/blocksdb", "Toggle Block SDB Dialogs.")
                DrawCmdRow("/autocv", "Toggle Auto CV All Locks on collect.")
                DrawCmdRow("/tp", "Toggle Teleport Punch (Display/Vend).")
                DrawCmdRow("/modal", "Calculate & show your own total balance.")
                DrawCmdRow("/fastdrop", "Toggle fast drop without confirmation.")
                DrawCmdRow("/fasttrash", "Toggle fast trash without confirmation.")
                DrawCmdRow("/vendfilter", "Formats huge World Lock prices to BGL/DL.")
                DrawCmdRow("/donfilter", "Shows actual item icons in Donation Box.")
                DrawCmdRow("/sboxfilter", "Enable Storage Box Xtreme Take-All mode.")
                EndCmdTable()

                BeginCmdTable("Tbl_BTK", utf8.char(0xf11b), "BTK & BJ Commands")
                DrawCmdRow("/btkmenu, /bjmenu", "Open Host Dialog Panel.")
                DrawCmdRow("/btkcmd, /bjcmd", "Open BTK/BJ Command List.")
                DrawCmdRow("/btk, /bj", "Switch Game Mode (BTK / BJ).")
                DrawCmdRow("/btkremote, /bjremote", "Collect Remote from Magplant.")
                DrawCmdRow("/btkbet, /bjbet", "Take Bets & Calculate Tax.")
                DrawCmdRow("/btkgems, /bjgems", "Check Gems & Announce Winner.")
                DrawCmdRow("/btkdrop, /bjdrop", "Drop Prize, Tax & Reset Round.")
                DrawCmdRow("/btkcenter, /bjcenter", "Touch/Punch to set Host Center tile.")
                DrawCmdRow("/btkposbet1, /bjposbet1", "Touch/Punch to set Bet Player 1 tile.")
                DrawCmdRow("/btkposbet2, /bjposbet2", "Touch/Punch to set Bet Player 2 tile.")
                DrawCmdRow("/btkposbreak1, /bjposbreak1", "Touch/Punch to set Break Player 1 tile.")
                DrawCmdRow("/btkposbreak2, /bjposbreak2", "Touch/Punch to set Break Player 2 tile.")
                DrawCmdRow("/btktax, /bjtax", "Touch/Punch to set Tax Drop tile.")
                DrawCmdRow("/btkmag, /bjmag", "Touch/Punch to set Magplant tile.")
                EndCmdTable()

                BeginCmdTable("Tbl_Sys", utf8.char(0xf013), "System & Tools")
                DrawCmdRow("/menu, /help", "Open Main Menu Dialog in-game.")
                DrawCmdRow("/cmd", "Open this Commands Dialog directly.")
                DrawCmdRow("/settingmenu", "Open Setting Menu directly.")
                DrawCmdRow("/imgui, /proxy", "Open/Close ImGui Panel.")
                DrawCmdRow("/g, /ghost", "Shortcut for /ghost.")
                DrawCmdRow("/res", "Shortcut for Respawn.")
                DrawCmdRow("/re", "Shortcut for Rejoin World.")
                DrawCmdRow("/relog", "Shortcut to Reconnect server.")
                EndCmdTable()
                ImGui.EndChild()
            end

        elseif UI.CurrentTab == utf8.char(0xf013) .. " General" then
            ImGui.TextColored(headerColor, utf8.char(0xf013) .. " General Proxy Features")
            ImGui.Separator()
            ImGui.Spacing()
            if ImGui.CollapsingHeader(utf8.char(0xf085) .. " Utility Toggles", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.Spacing()

                local alChanged, newAl = ImGui.Checkbox("Anti-Lag (No Particle/Shadow)", UI.AntiLag)
                if alChanged then UI.ToggleAntiLag(newAl) end
                ImGui.SameLine(); ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "- (/antilag)")

                local hsChanged, newHs = ImGui.Checkbox("Hide Spammer Slave", UI.HideSpammer)
                if hsChanged then UI.ToggleHideSpammer(newHs) end
                ImGui.SameLine(); ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "- (/hidespammer)")
                
                local apChanged, newAp = ImGui.Checkbox("Anti-Pickup Items (/antipickup)", UI.AntiPickup)
                if apChanged then UI.AntiPickup = newAp; UI.SaveConfig(true) end
                
                local mfChanged, newMf = ImGui.Checkbox("Modfly (/modfly)", UI.Modfly)
                if mfChanged then UI.Modfly = newMf; pcall(function() ChangeValue("[C] Modfly", UI.Modfly) end); UI.SaveConfig(true) end
                
                local pChanged, newP = ImGui.Checkbox("Anti Portal (/antiportal)", UI.AntiPortal)
                if pChanged then UI.AntiPortal = newP; pcall(function() ChangeValue("[C] Anti portal", UI.AntiPortal) end); UI.SaveConfig(true) end
                
                local nvChanged, newNv = ImGui.Checkbox("Night Vision (/nightvision)", UI.NightVision)
                if nvChanged then UI.NightVision = newNv; pcall(function() ChangeValue("[C] Night vision", UI.NightVision) end); UI.SaveConfig(true) end
                ImGui.SameLine(); ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "- Prevents auto-collecting dropped items")

                local bsdbChanged, newBsdb = ImGui.Checkbox("Block SDB Dialogs (/blocksdb)", UI.BlockSDB)
                if bsdbChanged then UI.BlockSDB = newBsdb; UI.SaveConfig(true) end
                ImGui.SameLine(); ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "- Hides annoying Super Duper Broadcast popups")

                local bsbChanged, newBsb = ImGui.Checkbox("Block SB Chat (/blocksb)", UI.BlockSB)
                if bsbChanged then UI.BlockSB = newBsb; UI.SaveConfig(true) end
                ImGui.SameLine(); ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "- Hides Super Broadcasts in console")

                local cvChanged, newCv = ImGui.Checkbox("Auto CV All Locks (/autocv)", UI.AutoCVLocks)
                if cvChanged then UI.AutoCVLocks = newCv; UI.SaveConfig(true) end
                ImGui.SameLine(); ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "- Converts strictly on collect")

                local tpChanged, newTp = ImGui.Checkbox("Teleport Punch (/tp)", UI.TPDisplay)
                if tpChanged then UI.TPDisplay = newTp; UI.SaveConfig(true) end
                ImGui.SameLine(); ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "- Auto FindPath when punching Display/Vend")

                local fdChanged, newFd = ImGui.Checkbox("Fast Drop (/fastdrop)", UI.FastDrop)
                if fdChanged then 
                    UI.FastDrop = newFd
                    if not newFd then UI.FastDropOnClick = false end
                    UI.SaveConfig(true) 
                end
                ImGui.SameLine(); ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "- Skips drop amount dialog (drops all)")

                if UI.FastDrop then
                    ImGui.Indent(20)
                    local fdOC, newFDOC = ImGui.Checkbox("Fast Drop OnClick Item", UI.FastDropOnClick)
                    if fdOC then 
                        UI.FastDropOnClick = newFDOC
                        if newFDOC then 
                            UI.FastTrashOnClick = false 
                            UI.ManageWarningThread()
                            UI.ManageOnClickItemThread()
                        end
                    end
                    ImGui.SameLine(); ImGui.TextColored(ImVec4(1.0, 0.4, 0.4, 1.0), " [WARNING: 1-Tap Drop All]")
                    ImGui.Unindent(20)
                end

                local ftChanged, newFt = ImGui.Checkbox("Fast Trash (/fasttrash)", UI.FastTrash)
                if ftChanged then 
                    UI.FastTrash = newFt
                    if not newFt then UI.FastTrashOnClick = false end
                    UI.SaveConfig(true) 
                end
                ImGui.SameLine(); ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "- Skips trash warning dialog (trashes all)")
                
                if UI.FastTrash then
                    ImGui.Indent(20)
                    local ftOC, newFTOC = ImGui.Checkbox("Fast Trash OnClick Item", UI.FastTrashOnClick)
                    if ftOC then 
                        UI.FastTrashOnClick = newFTOC
                        if newFTOC then 
                            UI.FastDropOnClick = false 
                            UI.ManageWarningThread()
                            UI.ManageOnClickItemThread()
                        end
                    end
                    ImGui.SameLine(); ImGui.TextColored(ImVec4(1.0, 0.4, 0.4, 1.0), " [WARNING: 1-Tap Trash All]")
                    ImGui.Unindent(20)
                end
                
                local vfChanged, newVf = ImGui.Checkbox("Vend Filter (/vendfilter)", UI.VendFilter)
                if vfChanged then UI.VendFilter = newVf; UI.SaveConfig(true) end
                ImGui.SameLine(); ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "- Formats huge World Lock prices to BGL/DL")

                local dfChanged, newDf = ImGui.Checkbox("Donation Box Filter (/donfilter)", UI.DonationFilter)
                if dfChanged then UI.DonationFilter = newDf; UI.SaveConfig(true) end
                ImGui.SameLine(); ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "- Shows actual item icons in Donation Box list")

                local sfChanged, newSf = ImGui.Checkbox("Storage Box Filter (/sboxfilter)", UI.StorageFilter)
                if sfChanged then UI.StorageFilter = newSf; UI.SaveConfig(true) end
                ImGui.SameLine(); ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "- Converts Storage Box to list with Take All")
            end

        elseif UI.CurrentTab == utf8.char(0xf0ad) .. " Wrench" then
            ImGui.TextColored(headerColor, utf8.char(0xf0ad) .. " Wrench Mode Options")
            ImGui.Separator()
            ImGui.Spacing()
            if ImGui.CollapsingHeader(utf8.char(0xf013) .. " Features & Toggles", ImGuiTreeNodeFlags_DefaultOpen) then
                    ImGui.Spacing()
                    local smChanged, newSm = ImGui.Checkbox("Show Balance on Wrench (/showbal)", UI.ShowBal)
                    if smChanged then UI.ShowBal = newSm; UI.SaveConfig(true) end
                    ImGui.SameLine(); ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "- Hides inventory dialog & shows balance")
                    ImGui.Spacing(); ImGui.Separator(); ImGui.Spacing()

                    ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Left Click Action (Main): [/wr_ example : /wrp]")
                    if select(2, ImGui.Checkbox("Off##L", UI.WrenchMode == 0)) and UI.WrenchMode ~= 0 then UI.WrenchMode = 0; UI.SaveConfig(true) end
                    ImGui.SameLine()
                    if select(2, ImGui.Checkbox("Pull##L", UI.WrenchMode == 1)) and UI.WrenchMode ~= 1 then UI.WrenchMode = 1; UI.SaveConfig(true) end
                    ImGui.SameLine()
                    if select(2, ImGui.Checkbox("Kick##L", UI.WrenchMode == 2)) and UI.WrenchMode ~= 2 then UI.WrenchMode = 2; UI.SaveConfig(true) end
                    ImGui.SameLine()
                    if select(2, ImGui.Checkbox("Ban##L", UI.WrenchMode == 3)) and UI.WrenchMode ~= 3 then UI.WrenchMode = 3; UI.SaveConfig(true) end
                    ImGui.SameLine()
                    if select(2, ImGui.Checkbox("Trade##L", UI.WrenchMode == 4)) and UI.WrenchMode ~= 4 then UI.WrenchMode = 4; UI.SaveConfig(true) end
                    ImGui.Spacing()

                    ImGui.TextColored(ImVec4(0.8, 0.8, 1.0, 1.0), "Right Click Action (Secondary): [/wr_s example : /wrks]")
                    if select(2, ImGui.Checkbox("Off##R", UI.WrenchModeRight == 0)) and UI.WrenchModeRight ~= 0 then UI.WrenchModeRight = 0; UI.SaveConfig(true) end
                    ImGui.SameLine()
                    if select(2, ImGui.Checkbox("Pull##R", UI.WrenchModeRight == 1)) and UI.WrenchModeRight ~= 1 then UI.WrenchModeRight = 1; UI.SaveConfig(true) end
                    ImGui.SameLine()
                    if select(2, ImGui.Checkbox("Kick##R", UI.WrenchModeRight == 2)) and UI.WrenchModeRight ~= 2 then UI.WrenchModeRight = 2; UI.SaveConfig(true) end
                    ImGui.SameLine()
                    if select(2, ImGui.Checkbox("Ban##R", UI.WrenchModeRight == 3)) and UI.WrenchModeRight ~= 3 then UI.WrenchModeRight = 3; UI.SaveConfig(true) end
                    ImGui.SameLine()
                    if select(2, ImGui.Checkbox("Trade##R", UI.WrenchModeRight == 4)) and UI.WrenchModeRight ~= 4 then UI.WrenchModeRight = 4; UI.SaveConfig(true) end
                    ImGui.Spacing()
                end
            if ImGui.CollapsingHeader(utf8.char(0xf040) .. " Custom Chat Actions", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.Spacing()
                ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Use {GrowID} to tag the player's name.")
                ImGui.PushItemWidth(-1)
                local pChanged, newP = ImGui.InputTextWithHint("##pulltxt", "Auto Pull Text (e.g. Get over here {GrowID}!)", UI.WrenchPullText, 64)
                if pChanged then UI.WrenchPullText = newP; UI.SaveConfig(true) end
                local kChanged, newK = ImGui.InputTextWithHint("##kicktxt", "Auto Kick Text (e.g. Bye {GrowID}!)", UI.WrenchKickText, 64)
                if kChanged then UI.WrenchKickText = newK; UI.SaveConfig(true) end
                local bChanged, newB = ImGui.InputTextWithHint("##bantxt", "Auto Ban Text (e.g. {GrowID} is banned!)", UI.WrenchBanText, 64)
                if bChanged then UI.WrenchBanText = newB; UI.SaveConfig(true) end
                ImGui.PopItemWidth()
                ImGui.Spacing()
            end

        elseif UI.CurrentTab == utf8.char(0xf4c0) .. " Donate" then
            ImGui.TextColored(headerColor, utf8.char(0xf4c0) .. " Smart Donation Mode")
            ImGui.Separator()
            ImGui.Spacing()
            if ImGui.CollapsingHeader(utf8.char(0xf013) .. " Features & Toggles", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.Spacing()
                local dChanged, newDMode = ImGui.Checkbox("Enable Donate Mode (/dmode)", UI.DonateMode)
                if dChanged then 
                    UI.DonateMode = newDMode 
                    if not UI.DonateMode then UI.DonateBoxX = 0; UI.DonateBoxY = 0 end
                    UI.SaveConfig(true)
                end
                ImGui.Spacing()
                ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Status: ")
                ImGui.SameLine()
                if UI.DonateBoxX == 0 and UI.DonateBoxY == 0 then
                    ImGui.TextColored(ImVec4(1.0, 0.4, 0.4, 1.0), "Box Not Set! Wrench a Donation Box.")
                else
                    ImGui.TextColored(ImVec4(0.4, 1.0, 0.4, 1.0), "Box Set at X: " .. UI.DonateBoxX .. ", Y: " .. UI.DonateBoxY)
                end
                ImGui.Spacing(); ImGui.Separator(); ImGui.Spacing()
                
                ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Quick Donate Action:")
                ImGui.PushItemWidth(150)
                local aChanged, newAmt = ImGui.InputInt("Amount", UI.DonateAmount)
                if aChanged then UI.DonateAmount = newAmt end
                if UI.DonateAmount < 1 then UI.DonateAmount = 1 end
                ImGui.PopItemWidth()
                ImGui.Spacing()
                
                if ImGui.Button("Donate WL (/pw)", ImVec2(150, 30)) then UI.DoDonate(UI.GetIcon("Creativeps World Lock", 242), UI.DonateAmount) end
                ImGui.SameLine()
                if ImGui.Button("Donate DL (/pd)", ImVec2(150, 30)) then UI.DoDonate(UI.GetIcon("Creativeps Diamond Lock", 1796), UI.DonateAmount) end
                ImGui.Spacing()
                if ImGui.Button("Donate BlueGL (/pb)", ImVec2(150, 30)) then UI.DoDonate(UI.GetIcon("Creativeps Blue Gem Lock", 7188), UI.DonateAmount) end
                ImGui.SameLine()
                if ImGui.Button("Donate BlackGL (/pbl)", ImVec2(150, 30)) then UI.DoDonate(UI.GetIcon("Creativeps Black Gem Lock", 11550), UI.DonateAmount) end
                ImGui.Spacing()
                if ImGui.Button("Put All Locks (/pall)", ImVec2(310, 30)) then UI.DonateAllLocks() end
                ImGui.Spacing()
                if ImGui.Button("Take All Items (/takeall)", ImVec2(310, 30)) then
                    if UI.DonateMode and UI.DonateBoxX ~= 0 then
                        SendPacket(2, "action|dialog_return\ndialog_name|donate_edit|\nx|"..UI.DonateBoxX.."|\ny|"..UI.DonateBoxY.."|\nbuttonClicked|withdrawall")
                        UI.LocalChat("`c[WinProxy]: `9Retrieving all items from Donation Box...")
                    else
                        UI.LocalChat("`c[WinProxy]: `4Please enable /dmode and set a box position first!")
                    end
                end
                ImGui.Spacing()
            end

        elseif UI.CurrentTab == utf8.char(0xf2b5) .. " Trade" then
            ImGui.TextColored(headerColor, utf8.char(0xf2b5) .. " Advanced Trading Mode")
            ImGui.Separator()
            ImGui.Spacing()
            if ImGui.CollapsingHeader(utf8.char(0xf013) .. " Features & Toggles", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.Spacing()
                
                local isTradeWrench = (UI.WrenchMode == 4)
                local tmChanged, newTm = ImGui.Checkbox("Enable Trade Mode (/tmode)", isTradeWrench)
                if tmChanged then 
                    UI.ToggleWrench(4) 
                end
                
                ImGui.Spacing()
                ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Status: ")
                ImGui.SameLine()
                if UI.TradeTargetUID == 0 then
                    ImGui.TextColored(ImVec4(1.0, 0.4, 0.4, 1.0), "Not Trading! Wrench a Player.")
                else
                    local cleanImGuiName = UI.TradeTargetName:gsub("`.", "")
                    
                    ImGui.TextColored(ImVec4(0.4, 1.0, 0.4, 1.0), "Trading with " .. cleanImGuiName .. " (UID: " .. UI.TradeTargetUID .. ")")
                end
                ImGui.Spacing(); ImGui.Separator(); ImGui.Spacing()

                ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Fast Add Items to Trade:")
                ImGui.PushItemWidth(150)
                local tChanged, newTAmt = ImGui.InputInt("Amount##tradeamt", UI.TradeAddAmount)
                if tChanged then UI.TradeAddAmount = newTAmt end
                if UI.TradeAddAmount < 1 then UI.TradeAddAmount = 1 end
                ImGui.PopItemWidth()
                ImGui.Spacing()
                
                if ImGui.Button("Add WL (/tw)", ImVec2(150, 30)) then UI.FastTradeAdd(UI.GetIcon("Creativeps World Lock", 242), UI.TradeAddAmount) end
                ImGui.SameLine()
                if ImGui.Button("Add DL (/td)", ImVec2(150, 30)) then UI.FastTradeAdd(UI.GetIcon("Creativeps Diamond Lock", 1796), UI.TradeAddAmount) end
                ImGui.Spacing()
                if ImGui.Button("Add BlueGL (/tb)", ImVec2(150, 30)) then UI.FastTradeAdd(UI.GetIcon("Creativeps Blue Gem Lock", 7188), UI.TradeAddAmount) end
                ImGui.SameLine()
                if ImGui.Button("Add BlackGL (/tbl)", ImVec2(150, 30)) then UI.FastTradeAdd(UI.GetIcon("Creativeps Black Gem Lock", 11550), UI.TradeAddAmount) end
                ImGui.Spacing()
                if ImGui.Button("Put All Locks (/tall)", ImVec2(310, 30)) then UI.TradeAllLocks() end
                ImGui.Spacing()
                if ImGui.Button("Clear Locks (/tclear)", ImVec2(310, 30)) then UI.TradeClearLocks() end
                ImGui.Spacing()
            end

        elseif UI.CurrentTab == utf8.char(0xf095) .. " Telephone" then
            ImGui.TextColored(ImVec4(0.2, 1.0, 0.2, 1.0), utf8.char(0xf095) .. " Telephone Auto-Buy")
            ImGui.Separator()
            ImGui.Spacing()
            if ImGui.CollapsingHeader(utf8.char(0xf013) .. " Features & Toggles", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.Spacing()
                ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Select Action:")
                if select(2, ImGui.Checkbox("Off (Disabled)", UI.TeleMode == 0)) and UI.TeleMode ~= 0 then UI.TeleMode = 0 end
                if select(2, ImGui.Checkbox("Buy Diamond Lock (/buydl)", UI.TeleMode == 1)) and UI.TeleMode ~= 1 then 
                    UI.TeleMode = 1; UI.LocalChat("`c[WinProxy]: `9Wrench Telephone to Buy `cDL `9is now `2Enabled") 
                end
                if select(2, ImGui.Checkbox("Buy Blue Gem Lock (/buybgl)", UI.TeleMode == 2)) and UI.TeleMode ~= 2 then 
                    UI.TeleMode = 2; UI.LocalChat("`c[WinProxy]: `9Wrench Telephone to Buy `eBGL `9is now `2Enabled") 
                end
                if select(2, ImGui.Checkbox("Convert DL to BGL (/cvdl)", UI.TeleMode == 3)) and UI.TeleMode ~= 3 then 
                    UI.TeleMode = 3; UI.LocalChat("`c[WinProxy]: `9Wrench Telephone to Change `cDL `9to `eBGL `9is now `2Enabled") 
                end
                if select(2, ImGui.Checkbox("Buy Champagne (Normal) (/buychamp)", UI.TeleMode == 4)) and UI.TeleMode ~= 4 then 
                    UI.TeleMode = 4; UI.LocalChat("`c[WinProxy]: `9Wrench Telephone to Buy `2Champagne `9is now `2Enabled") 
                end
                if select(2, ImGui.Checkbox("Buy Champagne (BGems) (/buychampbg)", UI.TeleMode == 5)) and UI.TeleMode ~= 5 then 
                    UI.TeleMode = 6; UI.LocalChat("`c[WinProxy]: `9Wrench Telephone to Buy `2Champ (Black Gems) `9is now `2Enabled") 
                end
                if select(2, ImGui.Checkbox("Buy Champagne (BULK) (/buychampbulk)", UI.TeleMode == 6)) and UI.TeleMode ~= 6 then 
                    UI.TeleMode = 5; UI.LocalChat("`c[WinProxy]: `9Wrench Telephone to Buy `2Bulk Champagne `9is now `2Enabled") 
                end
                ImGui.Spacing(); ImGui.Separator(); ImGui.Spacing()
                ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "Instruction: Select an option and wrench a Telephone.\nThe script will automatically bypass dialogs and buy the item.")
                ImGui.Spacing()
            end

        elseif UI.CurrentTab == utf8.char(0xf53f) .. " Emoji & Color" then
            ImGui.TextColored(ImVec4(1.0, 0.4, 0.7, 1.0), utf8.char(0xf53f) .. " Emoji & Skin Customization")
            ImGui.Separator()
            ImGui.Spacing()
            if ImGui.CollapsingHeader("Input Text Stuff (Colors, Emojis)", ImGuiTreeNodeFlags_DefaultOpen) then
                local colChanged, newCol = ImGui.Checkbox("Enable Color", UI.EnableColor)
                if colChanged then UI.EnableColor = newCol; UI.SaveConfig(true) end
                
                local oldColIdx = UI.SelectedColorIdx
                UI.SelectedColorIdx = UI.SafeCombo("Text Color", UI.SelectedColorIdx, UI.ColorNames)
                if oldColIdx ~= UI.SelectedColorIdx then UI.SaveConfig(true) end
                
                local emChanged, newEm = ImGui.Checkbox("Enable Emoji", UI.EnableEmoji)
                if emChanged then UI.EnableEmoji = newEm; UI.SaveConfig(true) end
                
                local oldEmIdx = UI.SelectedEmojiIdx
                UI.SelectedEmojiIdx = UI.SafeCombo("Emoji", UI.SelectedEmojiIdx, UI.EmojiNames)
                if oldEmIdx ~= UI.SelectedEmojiIdx then UI.SaveConfig(true) end
                
                local wmChanged, newWm = ImGui.Checkbox("Enable Chat Watermark", UI.WatermarkMode)
                if wmChanged then UI.WatermarkMode = newWm; UI.SaveConfig(true) end
                
                local encChanged, newEnc = ImGui.Checkbox("Enable Encrypt Chat (/encrypt)", UI.EncryptChat)
                if encChanged then UI.EncryptChat = newEnc; UI.SaveConfig(true) end
            end
            if ImGui.CollapsingHeader("Skin Changer", ImGuiTreeNodeFlags_DefaultOpen) then
                local cChanged, newSkinColor = ImGui.ColorEdit4("Custom Player Color", UI.SkinColor)
                if cChanged then 
                    UI.SkinColor.x = newSkinColor.x; UI.SkinColor.y = newSkinColor.y; UI.SkinColor.z = newSkinColor.z; UI.SkinColor.w = newSkinColor.w
                end
                local rbChanged, newRb = ImGui.Checkbox("Rainbow Skin", UI.RainbowSkin)
                if rbChanged then 
                    UI.RainbowSkin = newRb
                    if UI.RainbowSkin then UI.ManageSkinEffects() end
                    UI.SaveConfig(true)
                end
                local blChanged, newBl = ImGui.Checkbox("Blink", UI.BlinkSkin)
                if blChanged then 
                    UI.BlinkSkin = newBl
                    if UI.BlinkSkin then UI.ManageSkinEffects() end
                    UI.SaveConfig(true)
                end
                ImGui.Spacing()
                if ImGui.Button("Apply In-Game", ImVec2(150, 30)) then
                    UI.SetSkinColor(UI.SkinColor.x, UI.SkinColor.y, UI.SkinColor.z, UI.SkinColor.w)
                    UI.LocalChat("`c[WinProxy]: `9Custom skin applied!")
                end
                ImGui.Spacing()
                ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Quick Presets:")
                if ImGui.Button("Black", ImVec2(60, 25)) then UI.RainbowSkin = false; UI.BlinkSkin = false; UI.SetSkinColor(0.0, 0.0, 0.0, 1.0) end
                ImGui.SameLine()
                if ImGui.Button("White", ImVec2(60, 25)) then UI.RainbowSkin = false; UI.BlinkSkin = false; UI.SetSkinColor(1.0, 1.0, 1.0, 1.0) end
                ImGui.SameLine()
                if ImGui.Button("Red", ImVec2(60, 25)) then UI.RainbowSkin = false; UI.BlinkSkin = false; UI.SetSkinColor(1.0, 0.0, 0.0, 1.0) end
                ImGui.SameLine()
                if ImGui.Button("Yellow", ImVec2(60, 25)) then UI.RainbowSkin = false; UI.BlinkSkin = false; UI.SetSkinColor(1.0, 1.0, 0.0, 1.0) end

                if ImGui.Button("Green", ImVec2(60, 25)) then UI.RainbowSkin = false; UI.BlinkSkin = false; UI.SetSkinColor(0.0, 1.0, 0.0, 1.0) end
                ImGui.SameLine()
                if ImGui.Button("Blue", ImVec2(60, 25)) then UI.RainbowSkin = false; UI.BlinkSkin = false; UI.SetSkinColor(0.0, 0.4, 1.0, 1.0) end
                ImGui.SameLine()
                if ImGui.Button("Purple", ImVec2(60, 25)) then UI.RainbowSkin = false; UI.BlinkSkin = false; UI.SetSkinColor(0.6, 0.1, 0.9, 1.0) end
                ImGui.SameLine()
                if ImGui.Button("Pink", ImVec2(60, 25)) then UI.RainbowSkin = false; UI.BlinkSkin = false; UI.SetSkinColor(1.0, 0.4, 0.8, 1.0) end
                ImGui.Spacing()
            end

        elseif UI.CurrentTab == utf8.char(0xf1ec) .. " Calculator" then
            ImGui.TextColored(headerColor, utf8.char(0xf1ec) .. " Smart Calculator")
            ImGui.Separator()
            ImGui.Spacing()
            ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Display:")
            ImGui.PushItemWidth(-1)
            local calcChanged, newCalcIn = ImGui.InputText("##hidden_calc_input", UI.CalcInput, 256)
            if calcChanged then UI.CalcInput = newCalcIn end
            ImGui.PopItemWidth()
            local plainResult = UI.CalcResult:gsub("`.", "")
            ImGui.TextColored(ImVec4(0.4, 1.0, 0.4, 1.0), "= " .. plainResult)
            ImGui.Spacing()
            
            local btnSize = ImVec2(50, 40)
            local btnZeroSize = ImVec2(108, 40)
            
            if ImGui.Button("C", btnSize) then UI.CalcInput = "" end ImGui.SameLine()
            if ImGui.Button(utf8.char(0xf55a), btnSize) then UI.CalcInput = string.sub(UI.CalcInput, 1, -2) end ImGui.SameLine()
            if ImGui.Button("%", btnSize) then UI.CalcInput = UI.CalcInput .. "%" end ImGui.SameLine()
            if ImGui.Button("/", btnSize) then UI.CalcInput = UI.CalcInput .. "/" end
            
            if ImGui.Button("7", btnSize) then UI.CalcInput = UI.CalcInput .. "7" end ImGui.SameLine()
            if ImGui.Button("8", btnSize) then UI.CalcInput = UI.CalcInput .. "8" end ImGui.SameLine()
            if ImGui.Button("9", btnSize) then UI.CalcInput = UI.CalcInput .. "9" end ImGui.SameLine()
            if ImGui.Button("x", btnSize) then UI.CalcInput = UI.CalcInput .. "*" end
            
            if ImGui.Button("4", btnSize) then UI.CalcInput = UI.CalcInput .. "4" end ImGui.SameLine()
            if ImGui.Button("5", btnSize) then UI.CalcInput = UI.CalcInput .. "5" end ImGui.SameLine()
            if ImGui.Button("6", btnSize) then UI.CalcInput = UI.CalcInput .. "6" end ImGui.SameLine()
            if ImGui.Button("-", btnSize) then UI.CalcInput = UI.CalcInput .. "-" end
            
            if ImGui.Button("1", btnSize) then UI.CalcInput = UI.CalcInput .. "1" end ImGui.SameLine()
            if ImGui.Button("2", btnSize) then UI.CalcInput = UI.CalcInput .. "2" end ImGui.SameLine()
            if ImGui.Button("3", btnSize) then UI.CalcInput = UI.CalcInput .. "3" end ImGui.SameLine()
            if ImGui.Button("+", btnSize) then UI.CalcInput = UI.CalcInput .. "+" end
            
            if ImGui.Button("0", btnZeroSize) then UI.CalcInput = UI.CalcInput .. "0" end ImGui.SameLine()
            if ImGui.Button(".", btnSize) then UI.CalcInput = UI.CalcInput .. "." end ImGui.SameLine()
            if ImGui.Button("=", btnSize) then UI.CalculateMath(UI.CalcInput) end

            ImGui.Spacing(); ImGui.Separator(); ImGui.Spacing()
            ImGui.TextColored(ImVec4(0.6, 0.8, 1.0, 1.0), "Calculation History:")
            ImGui.BeginChild("CalcLogsChild", ImVec2(0, 120), true)
            if #UI.CalcLogs == 0 then
                ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "No history available.")
            else
                for i, log in ipairs(UI.CalcLogs) do ImGui.Text(i .. ". " .. log:gsub("`.", "")) end
            end
            ImGui.EndChild()
            ImGui.Spacing()

        elseif UI.CurrentTab == utf8.char(0xf002) .. " Item Database" then
            ImGui.TextColored(headerColor, utf8.char(0xf002) .. " Item Database Search")
            ImGui.Separator()
            ImGui.Spacing()
            ImGui.PushItemWidth(-1)
            local sChanged, newSearch = ImGui.InputTextWithHint("##itemsearch", "Search by Item Name or ID...", UI.SearchItemInput, 64)
            if sChanged then
                UI.SearchItemInput = newSearch
                UI.SearchItem(UI.SearchItemInput)
            end
            ImGui.PopItemWidth()
            ImGui.Spacing()
            
            ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Results Found: " .. #UI.SearchItemResults)
            ImGui.BeginChild("ItemDBSearchResults", ImVec2(0, 0), true)
            if #UI.SearchItemResults == 0 then
                ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "No items found. Type above to start searching.")
            else
                ImGui.Columns(2, "ItemDBCols", true)
                ImGui.SetColumnWidth(0, 80)
                ImGui.TextColored(ImVec4(1.0, 0.8, 0.2, 1.0), "Item ID")
                ImGui.NextColumn()
                ImGui.TextColored(ImVec4(1.0, 0.8, 0.2, 1.0), "Item Name")
                ImGui.NextColumn()
                ImGui.Separator()
                for _, item in ipairs(UI.SearchItemResults) do
                    ImGui.TextColored(ImVec4(0.4, 1.0, 0.4, 1.0), tostring(item.id))
                    ImGui.NextColumn()
                    local properName = item.name:gsub("(%a)([%w_']*)", function(first, rest) return first:upper() .. rest:lower() end)
                    ImGui.TextColored(ImVec4(0.9, 0.9, 0.9, 1.0), properName)
                    ImGui.NextColumn()
                end
                ImGui.Columns(1)
            end
            ImGui.EndChild()

        elseif UI.CurrentTab == utf8.char(0xf06c) .. " Auto PTHT" then
            ImGui.TextColored(headerColor, utf8.char(0xf06c) .. " Auto PTHT")
            ImGui.Separator()
            ImGui.TextColored(ImVec4(0.6, 0.6, 0.6, 1.0), "This feature will be available soon.")

        elseif UI.CurrentTab == utf8.char(0xf06c) .. " Auto PNB" then
            ImGui.TextColored(headerColor, utf8.char(0xf06c) .. " Auto PNB")
            ImGui.Separator()
            ImGui.TextColored(ImVec4(0.6, 0.6, 0.6, 1.0), "This feature will be available soon.")

        elseif UI.CurrentTab == utf8.char(0xf236) .. " AFK" then
            ImGui.TextColored(headerColor, utf8.char(0xf236) .. " AFK")
            ImGui.Separator()
            ImGui.TextColored(ImVec4(0.6, 0.6, 0.6, 1.0), "This feature will be available soon.")

        elseif UI.CurrentTab == utf8.char(0xf52b) .. " WTW" then
            ImGui.TextColored(headerColor, utf8.char(0xf52b) .. " WTW")
            ImGui.Separator()
            ImGui.TextColored(ImVec4(0.6, 0.6, 0.6, 1.0), "This feature will be available soon.")
            
        elseif UI.CurrentTab == utf8.char(0xf0f5) .. " Auto Cook" then
            ImGui.TextColored(headerColor, utf8.char(0xf0f5) .. " Auto Cook")
            ImGui.Separator()
            ImGui.TextColored(ImVec4(0.6, 0.6, 0.6, 1.0), "This feature will be available soon.")
            
        elseif UI.CurrentTab == utf8.char(0xf578) .. " Auto Fish" then
            ImGui.TextColored(headerColor, utf8.char(0xf578) .. " Auto Fishing")
            ImGui.Separator()
            ImGui.Spacing()
            if ImGui.CollapsingHeader("Controls & Info", ImGuiTreeNodeFlags_DefaultOpen) then
                local statusColor = UI.AutoFish and ImVec4(0.4, 1.0, 0.4, 1.0) or ImVec4(1.0, 1.0, 0.4, 1.0)
                if UI.FishAction:find("Out of") then statusColor = ImVec4(1.0, 0.4, 0.4, 1.0) end
                ImGui.Text("Status: "); ImGui.SameLine(); ImGui.TextColored(statusColor, UI.FishAction)
                ImGui.Spacing()
                
                if UI.AutoFish then
                    if ImGui.Button("STOP AUTO FISH", ImVec2(-1, 35)) then
                        UI.AutoFish = false; UI.FishAction = "Stopping..."
                    end
                else
                    if ImGui.Button("START AUTO FISH", ImVec2(-1, 35)) then
                        UI.AutoFish = true; UI.ManageAutoFishThread()
                    end
                end
                ImGui.Spacing()
                ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "How to use: Equip your Fishing Rod, face the water,\nselect your direction below, and click Start!")
                ImGui.Spacing()
            end
            if ImGui.CollapsingHeader("Settings", ImGuiTreeNodeFlags_DefaultOpen) then
                UI.FishDirIdx = UI.SafeCombo("Facing Direction", UI.FishDirIdx, {"Facing Right", "Facing Left"})
                ImGui.Spacing()
                ImGui.PushItemWidth(150)
                local bChg, newBait = ImGui.InputInt("Bait Item ID", UI.FishBaitID)
                if bChg then UI.FishBaitID = newBait end
                ImGui.PopItemWidth()
                ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "(Common Baits: 2504 = Worm, 5528 = Mega Pelet, 2904 = Salmon)")
                ImGui.Spacing()
            end
            if ImGui.CollapsingHeader("Live Statistics", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Total Casts : " .. UI.FishStats.cast)
                ImGui.TextColored(ImVec4(0.4, 1.0, 0.4, 1.0), "Fish Caught : " .. UI.FishStats.caught)
                ImGui.TextColored(ImVec4(1.0, 0.4, 0.4, 1.0), "Fish Missed : " .. UI.FishStats.missed)
                ImGui.Spacing()
                if ImGui.Button("Reset Stats##fish") then UI.FishStats = { cast = 0, caught = 0, missed = 0 } end
                ImGui.Spacing()
            end
            
        elseif UI.CurrentTab == utf8.char(0xf0fa) .. " Auto Surg" then
            ImGui.TextColored(headerColor, utf8.char(0xf0fa) .. " Auto Surgery (Smart AI)")
            ImGui.Separator()
            ImGui.Spacing()
            if ImGui.CollapsingHeader("Controls & Info", ImGuiTreeNodeFlags_DefaultOpen) then
                local statusColor = UI.AutoSurg and ImVec4(0.4, 1.0, 0.4, 1.0) or ImVec4(1.0, 1.0, 0.4, 1.0)
                if UI.SurgAction:find("Malpractice") or UI.SurgAction:find("low!") then statusColor = ImVec4(1.0, 0.4, 0.4, 1.0) end
                ImGui.Text("Status: "); ImGui.SameLine(); ImGui.TextColored(statusColor, UI.SurgAction)
                if UI.SurgTarget then
                    ImGui.Text("Target: "); ImGui.SameLine(); ImGui.TextColored(ImVec4(0.4, 0.8, 1.0, 1.0), "Player ID: " .. tostring(UI.SurgTarget))
                end
                ImGui.Spacing()
                
                if UI.AutoSurg then
                    if ImGui.Button("STOP AUTO SURG", ImVec2(-1, 35)) then
                        UI.AutoSurg = false; UI.IsSurging = false; UI.SurgTarget = nil; UI.SurgAction = "Stopping..."
                    end
                else
                    if ImGui.Button("START AUTO SURG", ImVec2(-1, 35)) then
                        UI.AutoSurg = true; UI.ManageAutoSurgThread()
                    end
                end
                ImGui.Spacing()
                ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "How to use: Click Start, then Wrench a player to begin.")
                ImGui.Spacing()
            end
            if ImGui.CollapsingHeader("Settings & Toggles", ImGuiTreeNodeFlags_DefaultOpen) then
                local abChg, newAb = ImGui.Checkbox("Enable Auto Buy Surg Kit", UI.SurgAutoBuy)
                if abChg then UI.SurgAutoBuy = newAb end
                
                ImGui.PushItemWidth(120)
                local thrChg, newThr = ImGui.InputInt("Min. Threshold", UI.SurgCardThreshold)
                if thrChg then 
                    UI.SurgCardThreshold = newThr 
                    if UI.SurgCardThreshold < 1 then UI.SurgCardThreshold = 1 end
                end
                ImGui.PopItemWidth()
                ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "Bot will automatically buy 'Surgical Kit' if any tool drops below " .. UI.SurgCardThreshold .. ".")
                ImGui.Spacing()
                
                local atChg, newAt = ImGui.Checkbox("Auto Trash Excess Tools (>= 240 items)", UI.SurgAutoTrash)
                if atChg then UI.SurgAutoTrash = newAt end
                ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "Prevents inventory full errors by trashing excess tools down to 200.")
                ImGui.Spacing()
                
                local amChg, newAm = ImGui.Checkbox("Auto Bypass Malpractice (/modage 999)", UI.SurgAutoModage)
                if amChg then 
                    UI.SurgAutoModage = newAm 
                    if newAm then UI.SurgUseLegalBrief = false end
                end
                local lbChg, newLb = ImGui.Checkbox("Use Legal Brief (For Non-MVP+)", UI.SurgUseLegalBrief)
                if lbChg then 
                    UI.SurgUseLegalBrief = newLb 
                    if newLb then UI.SurgAutoModage = false end
                end
                ImGui.Spacing()
            end
            if ImGui.CollapsingHeader("Live Statistics", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.TextColored(ImVec4(0.4, 1.0, 0.4, 1.0), "Successful Surgeries : " .. UI.SurgStats.success)
                ImGui.TextColored(ImVec4(1.0, 0.4, 0.4, 1.0), "Failed (Malpractice) : " .. UI.SurgStats.fail)
                local total = UI.SurgStats.success + UI.SurgStats.fail
                local winRate = total > 0 and math.floor((UI.SurgStats.success / total) * 100) or 0
                ImGui.TextColored(ImVec4(0.4, 0.8, 1.0, 1.0), "Win Rate Accuracy    : " .. winRate .. "%")
                ImGui.Spacing()
                if ImGui.Button("Reset Stats") then UI.SurgStats = { success = 0, fail = 0 } end
                ImGui.Spacing()
            end
            
        elseif UI.CurrentTab == utf8.char(0xf204) .. " Auto Geiger" then
            ImGui.TextColored(headerColor, utf8.char(0xf204) .. " Auto Geiger")
            ImGui.Separator()
            ImGui.TextColored(ImVec4(0.6, 0.6, 0.6, 1.0), "This feature will be available soon.")

        elseif UI.CurrentTab == utf8.char(0xf06c) .. " Auto Provider" then
            ImGui.TextColored(headerColor, utf8.char(0xf06c) .. " Auto Provider")
            ImGui.Separator()
            ImGui.TextColored(ImVec4(0.6, 0.6, 0.6, 1.0), "This feature will be available soon.")
            
        elseif UI.CurrentTab == utf8.char(0xf21b) .. " Auto Crime" then
            ImGui.TextColored(headerColor, utf8.char(0xf21b) .. " Auto Crime (CPS Optimized)")
            ImGui.Separator()
            ImGui.Spacing()
            if ImGui.CollapsingHeader("Controls & Status", ImGuiTreeNodeFlags_DefaultOpen) then
                local statusColor = UI.AutoCrime and ImVec4(0.4, 1.0, 0.4, 1.0) or ImVec4(1.0, 1.0, 0.4, 1.0)
                if UI.CrimeAction:find("Error") or UI.CrimeAction:find("Lost") then statusColor = ImVec4(1.0, 0.4, 0.4, 1.0) end
                ImGui.Text("Status: "); ImGui.SameLine(); ImGui.TextColored(statusColor, UI.CrimeAction)
                if UI.CrimeTarget then
                    ImGui.Text("Target: "); ImGui.SameLine(); ImGui.TextColored(ImVec4(0.4, 0.8, 1.0, 1.0), string.format("%s @ (%d, %d)", UI.CrimeTarget.name, UI.CrimeTarget.x, UI.CrimeTarget.y))
                end
                ImGui.Spacing()
                if UI.AutoCrime then
                    if ImGui.Button("STOP AUTO CRIME", ImVec2(150, 35)) then
                        UI.AutoCrime = false; UI.IsFightingCrime = false; UI.CrimeAction = "Stopping..."
                    end
                else
                    if ImGui.Button("START AUTO CRIME", ImVec2(150, 35)) then
                        UI.AutoCrime = true; UI.ManageAutoCrimeThread()
                    end
                    ImGui.SameLine()
                    if ImGui.Button("SCAN VILLAINS", ImVec2(150, 35)) then UI.ScanVillains() end
                end
                ImGui.Spacing()
            end
            if ImGui.CollapsingHeader("Auto Buy Cards Settings", ImGuiTreeNodeFlags_DefaultOpen) then
                local abcChg, newAbc = ImGui.Checkbox("Enable Auto Buy Crime Cards", UI.AutoBuyCrimeCards)
                if abcChg then UI.AutoBuyCrimeCards = newAbc end
                ImGui.PushItemWidth(120)
                local thrChg, newThr = ImGui.InputInt("Min. Threshold", UI.CrimeCardThreshold)
                if thrChg then 
                    UI.CrimeCardThreshold = newThr 
                    if UI.CrimeCardThreshold < 1 then UI.CrimeCardThreshold = 1 end
                end
                ImGui.PopItemWidth()
                ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "Bot will automatically buy Crime Cards if any card drops below " .. UI.CrimeCardThreshold .. ".")
                ImGui.Spacing()
            end
            if ImGui.CollapsingHeader("Villains Found in World", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.Text("Total Instances: " .. #UI.CrimeVillains)
                ImGui.Separator()
                if ImGui.BeginTable("VillainListTable", 3) then
                    ImGui.TableSetupColumn("No.", 0, 0.1)
                    ImGui.TableSetupColumn("Name", 0, 0.6)
                    ImGui.TableSetupColumn("Position", 0, 0.3)
                    ImGui.TableHeadersRow()
                    for i, inst in ipairs(UI.CrimeVillains) do
                        ImGui.TableNextRow()
                        ImGui.TableSetColumnIndex(0); ImGui.Text(tostring(i))
                        ImGui.TableSetColumnIndex(1); ImGui.Text(inst.name)
                        ImGui.TableSetColumnIndex(2); ImGui.TextColored(ImVec4(0.4, 0.8, 1.0, 1.0), string.format("(%d, %d)", inst.x, inst.y))
                    end
                    ImGui.EndTable()
                end
            end

        elseif UI.CurrentTab == utf8.char(0xf4ad) .. " Auto Spam" then
            ImGui.TextColored(headerColor, utf8.char(0xf4ad) .. " Auto-Spam Settings")
            ImGui.Separator()
            ImGui.Spacing()
            if ImGui.CollapsingHeader(utf8.char(0xf013) .. " Features & Toggles", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.Spacing()
                local sChanged, newSpam = ImGui.Checkbox("Enable Auto-Spam", UI.SpamEnabled)
                if sChanged then UI.ToggleSpam(newSpam) end
                ImGui.Spacing()
                ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Spam Configuration:")
                ImGui.PushItemWidth(-1)
                for i = 1, #UI.SpamTexts do
                    local txtChanged, newTxt = ImGui.InputText("Typer Text " .. i, UI.SpamTexts[i], 128)
                    if txtChanged then UI.SpamTexts[i] = newTxt end
                end
                ImGui.PopItemWidth()
                ImGui.Spacing()
                if ImGui.Button(utf8.char(0xf067) .. " Add New Field", ImVec2(140, 30)) then table.insert(UI.SpamTexts, "") end
                ImGui.SameLine()
                if #UI.SpamTexts > 1 then
                    if ImGui.Button(utf8.char(0xf068) .. " Remove Last Field", ImVec2(140, 30)) then table.remove(UI.SpamTexts) end
                end
                ImGui.Spacing(); ImGui.Separator(); ImGui.Spacing()
                ImGui.PushItemWidth(150)
                local intChanged, newInt = ImGui.InputInt("Typer Delay (ms)", UI.SpamInterval, 100, 1000)
                if intChanged then 
                    if newInt < 500 then newInt = 500 end 
                    UI.SpamInterval = newInt 
                end
                ImGui.PopItemWidth()
                ImGui.Spacing()
                ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "Warning: Setting delay too low may cause a temporary server ban.")
                ImGui.Spacing()
            end

        elseif UI.CurrentTab == utf8.char(0xf0a1) .. " Auto SB" then
            ImGui.TextColored(headerColor, utf8.char(0xf0a1) .. " Super Broadcast (SB)")
            ImGui.Separator()
            ImGui.Spacing()
            if ImGui.CollapsingHeader(utf8.char(0xf013) .. " Webhook & Ping Settings", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.Spacing()
                ImGui.PushItemWidth(-1)
                local wChanged, newW = ImGui.InputTextWithHint("##wbhook", "Discord Webhook URL", UI.WebhookSB, 256)
                if wChanged then UI.WebhookSB = newW; UI.SaveConfig(true) end
                local pChanged, newP = ImGui.InputTextWithHint("##dping", "Discord User ID to Ping", UI.DiscordPingID, 64)
                if pChanged then UI.DiscordPingID = newP; UI.SaveConfig(true) end
                ImGui.PopItemWidth()
                ImGui.Spacing()
            end
            if ImGui.CollapsingHeader(utf8.char(0xf0a1) .. " Super Broadcast (SB)", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.Spacing()
                local sbState = UI.SBEnabled and "`2RUNNING" or "`4STOPPED"
                ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Status: ")
                ImGui.SameLine()
                if UI.SBEnabled then ImGui.TextColored(ImVec4(0.4, 1.0, 0.4, 1.0), "RUNNING") else ImGui.TextColored(ImVec4(1.0, 0.4, 0.4, 1.0), "STOPPED") end
                ImGui.SameLine(); ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), " | Sent: " .. UI.SBCount .. " / " .. UI.SBMax)
                ImGui.Spacing()
                ImGui.PushItemWidth(-1)
                local tChanged, newT = ImGui.InputTextWithHint("##sbtext", "SB Text", UI.SBText, 128)
                if tChanged then UI.SBText = newT end
                ImGui.PopItemWidth()
                ImGui.Spacing()
                ImGui.PushItemWidth(100)
                local cChanged, newC = ImGui.InputInt("Amount", UI.SBMax)
                if cChanged then UI.SBMax = newC end
                ImGui.PopItemWidth()
                ImGui.SameLine(); if ImGui.Button("+ 1H") then UI.SBMax = UI.SBMax + 20 end
                ImGui.SameLine(); if ImGui.Button("+ 2H") then UI.SBMax = UI.SBMax + 40 end
                ImGui.SameLine(); if ImGui.Button("+ 3H") then UI.SBMax = UI.SBMax + 60 end
                ImGui.Spacing()
                local cpChanged, newCp = ImGui.Checkbox("Auto-Copy Sign Text", UI.SBCopyText)
                if cpChanged then UI.SBCopyText = newCp end
                ImGui.SameLine()
                local sfChanged, newSf = ImGui.Checkbox("Safe Mode (Auto Warp Back)", UI.SBSafeMode)
                if sfChanged then UI.SBSafeMode = newSf end
                ImGui.Spacing()
                ImGui.PushItemWidth(150)
                local dwChanged, newDw = ImGui.InputTextWithHint("##sbdoneworld", "Done World", UI.SBDoneWorld, 64)
                if dwChanged then UI.SBDoneWorld = newDw end
                ImGui.PopItemWidth()
                ImGui.SameLine()
                local uwChanged, newUw = ImGui.Checkbox("Warp When Done", UI.SBUseDoneWorld)
                if uwChanged then UI.SBUseDoneWorld = newUw end
                ImGui.Spacing(); ImGui.Separator(); ImGui.Spacing()
                if ImGui.Button("START SB", ImVec2(120, 30)) then 
                    UI.SBEnabled = true; UI.SBStartTime = os.time(); UI.ManageSBThread() 
                end
                ImGui.SameLine()
                if ImGui.Button("STOP SB", ImVec2(120, 30)) then 
                    UI.SBEnabled = false; UI.LocalChat("`c[WinProxy]: `4STOPPING `0SUPER BROADCAST")
                end
                ImGui.Spacing()
            end
        elseif UI.CurrentTab == utf8.char(0xf0a1) .. " Auto SDB" then
            ImGui.TextColored(headerColor, utf8.char(0xf0a1) .. " Super Duper Broadcast (SDB)")
            ImGui.Separator()
            ImGui.Spacing()
            if ImGui.CollapsingHeader(utf8.char(0xf0a1) .. " Super Duper Broadcast (SDB)", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.Spacing()
                ImGui.PushItemWidth(-1)
                local l1Changed, newL1 = ImGui.InputTextWithHint("##sdbl1", "Line 1", UI.SDBLine1, 64)
                if l1Changed then UI.SDBLine1 = newL1 end
                local l2Changed, newL2 = ImGui.InputTextWithHint("##sdbl2", "Line 2", UI.SDBLine2, 64)
                if l2Changed then UI.SDBLine2 = newL2 end
                local l3Changed, newL3 = ImGui.InputTextWithHint("##sdbl3", "Line 3", UI.SDBLine3, 64)
                if l3Changed then UI.SDBLine3 = newL3 end
                ImGui.PopItemWidth()
                ImGui.Spacing()
                ImGui.PushItemWidth(100)
                local scChanged, newSc = ImGui.InputInt("SDB Amount", UI.SDBMax)
                if scChanged then UI.SDBMax = newSc end
                local stChanged, newSt = ImGui.InputInt("Extra Delay (Mins)", UI.SDBExtraTimer)
                if stChanged then UI.SDBExtraTimer = newSt; UI.SDBTotalDelay = 5 + UI.SDBExtraTimer end
                ImGui.PopItemWidth()
                ImGui.Spacing(); ImGui.Separator(); ImGui.Spacing()
                if ImGui.Button("START SDB", ImVec2(120, 30)) then 
                    UI.SDBEnabled = true; UI.ManageSDBThread() 
                end
                ImGui.SameLine()
                if ImGui.Button("STOP SDB", ImVec2(120, 30)) then 
                    UI.SDBEnabled = false; UI.LocalChat("`c[WinProxy]: `4STOPPING `0SUPER DUPER BROADCAST")
                end
                ImGui.Spacing()
            end

        elseif UI.CurrentTab == utf8.char(0xf1e3) .. " Casino" then
            ImGui.TextColored(headerColor, utf8.char(0xf1e3) .. " Casino & Gambling Settings")
            ImGui.Separator()
            ImGui.Spacing()
            if ImGui.CollapsingHeader(utf8.char(0xf013) .. " Features & Toggles", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.Spacing()
                if select(2, ImGui.Checkbox("Off", UI.CasinoMode == 0)) and UI.CasinoMode ~= 0 then UI.ToggleCasino(UI.CasinoMode) end
                if select(2, ImGui.Checkbox("All (Reme/Leme/Qeme)", UI.CasinoMode == 7)) and UI.CasinoMode ~= 7 then UI.ToggleCasino(7) end
                if select(2, ImGui.Checkbox("Reme", UI.CasinoMode == 1)) and UI.CasinoMode ~= 1 then UI.ToggleCasino(1) end
                if select(2, ImGui.Checkbox("Qeme", UI.CasinoMode == 2)) and UI.CasinoMode ~= 2 then UI.ToggleCasino(2) end
                if select(2, ImGui.Checkbox("Leme", UI.CasinoMode == 3)) and UI.CasinoMode ~= 3 then UI.ToggleCasino(3) end
                if select(2, ImGui.Checkbox("Leme S", UI.CasinoMode == 4)) and UI.CasinoMode ~= 4 then UI.ToggleCasino(4) end
                if select(2, ImGui.Checkbox("Ceme", UI.CasinoMode == 5)) and UI.CasinoMode ~= 5 then UI.ToggleCasino(5) end
                
                ImGui.BeginGroup()
                ImGui.BeginGroup()
                if select(2, ImGui.Checkbox("Lewa", UI.CasinoMode == 6)) and UI.CasinoMode ~= 6 then UI.ToggleCasino(6) end
                if UI.CasinoMode == 6 then
                    ImGui.SameLine()
                    ImGui.PushItemWidth(120)
                    local changed, newVal = ImGui.InputInt("Multiplier", UI.CasinoLewaMulti)
                    if changed then 
                        UI.CasinoLewaMulti = newVal 
                        if UI.CasinoLewaMulti < 5 then UI.CasinoLewaMulti = 5 end
                        if UI.CasinoLewaMulti > 7 then UI.CasinoLewaMulti = 7 end
                        UI.SaveConfig(true)
                    end
                    ImGui.PopItemWidth()
                end
                ImGui.EndGroup()
                
                ImGui.Spacing()
                ImGui.Text("Result Format:")
                if ImGui.RadioButton("[Result] (Original)", UI.CasinoFormatIdx == 1) then UI.CasinoFormatIdx = 1; UI.SaveConfig(true) end
                if ImGui.RadioButton("(Original) [Result]", UI.CasinoFormatIdx == 2) then UI.CasinoFormatIdx = 2; UI.SaveConfig(true) end
                ImGui.EndGroup()
                ImGui.Spacing()
            end

        elseif UI.CurrentTab == utf8.char(0xf11b) .. " BTK/BJ" then
            ImGui.TextColored(headerColor, utf8.char(0xf11b) .. " BTK/BJ (Custom Tile Setup)")
            ImGui.Separator()
            ImGui.Spacing()
            
            ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Game Mode:")
            if ImGui.RadioButton("BTK (Most Gems)", UI.BTK_Mode == "BTK") then
                UI.BTK_Mode = "BTK"
                UI.SaveConfig(true)
            end
            ImGui.SameLine()
            if ImGui.RadioButton("BJ (Blackjack 21)", UI.BTK_Mode == "BJ") then
                UI.BTK_Mode = "BJ"
                UI.SaveConfig(true)
            end
            ImGui.Spacing()
            ImGui.Separator()
            ImGui.Spacing()

            ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "1. Set Coordinates (Click Touch and tap tile, or Stand)")
            if UI.BTK_SelectingTarget then
                ImGui.TextColored(ImVec4(1.0, 0.8, 0.2, 1.0), ">> Touch/Punch tile for: " .. UI.BTK_SelectingTarget)
            end
            ImGui.BeginChild("BTK_Coords", ImVec2(0, 202), true)
            
            local lp = GetLocal()
            local curX = lp and lp.pos and math.floor(lp.pos.x / 32) or 0
            local curY = lp and lp.pos and math.floor(lp.pos.y / 32) or 0

            local function SetRow(label, xVal, yVal)
                ImGui.TextColored(ImVec4(0.4, 0.8, 1.0, 1.0), string.format("%-15s : (%d, %d)", label, xVal, yVal))
                ImGui.SameLine(175)
                
                local isSelecting = (UI.BTK_SelectingTarget == label)
                local touchBtnLabel = isSelecting and ("Touching...##" .. label) or ("Touch##" .. label)
                
                if ImGui.Button(touchBtnLabel) then
                    if isSelecting then
                        UI.BTK_SelectingTarget = nil
                        UI.LocalChat("`c[WinProxy]: `4Touch selection cancelled.")
                    else
                        UI.BTK_SelectingTarget = label
                        UI.LocalChat("`c[WinProxy]: `9Touch or Punch any tile to set `2" .. label)
                    end
                end
                
                ImGui.SameLine()
                if ImGui.Button("Stand##" .. label) then
                    UI.SetBTKCoordByTouch(label, curX, curY)
                end
            end

            SetRow("Host Center", UI.BTK_CenterX, UI.BTK_CenterY)
            SetRow("Bet P1", UI.BTK_Bet1X, UI.BTK_Bet1Y)
            SetRow("Bet P2", UI.BTK_Bet2X, UI.BTK_Bet2Y)
            SetRow("Break P1 (Mid)", UI.BTK_Break1X, UI.BTK_Break1Y)
            SetRow("Break P2 (Mid)", UI.BTK_Break2X, UI.BTK_Break2Y)
            SetRow("Tax Drop (Mid)", UI.BTK_TaxX, UI.BTK_TaxY)
            SetRow("Magplant (Top)", UI.BTK_MagX, UI.BTK_MagY)

            ImGui.EndChild()
            ImGui.Spacing()
            
            if ImGui.Button("Take Remote Magplant", ImVec2(398, 30)) then
                if UI.BTK_MagX > 0 then
                    RunThread(function()
                        local magRealX = UI.BTK_MagX
                        local magRealY = UI.BTK_MagY + 1
                        
                        FindPath(UI.BTK_MagX, UI.BTK_MagY)
                        Sleep(850)
                        
                        SendPacketRaw(false, { type = 3, value = 32, x = magRealX * 32, y = magRealY * 32, px = magRealX, py = magRealY, state = 0 })
                        Sleep(500)
                        
                        SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|"..magRealX.."|\ny|"..magRealY.."|\nbuttonClicked|getRemote")
                        UI.LocalChat("`c[WinProxy]: `9Remote collected from Magplant!")
                        Sleep(500)
                        
                        local pos = UI.BTK_GetPositions()
                        FindPath(pos.center.x, pos.center.y)
                        Sleep(850)
                    end)
                else
                    UI.LocalChat("`c[WinProxy]: `4Set Magplant coordinates first!")
                end
            end
            ImGui.Spacing()
            
            if ImGui.Button("2. Take Bets & Calc", ImVec2(195, 30)) then
                local pos = UI.BTK_GetPositions()
                UI.BTK_P1Bet = UI.ParseBetAt(pos.b1)
                UI.BTK_P2Bet = UI.ParseBetAt(pos.b2)
                
                if UI.BTK_P1Bet > 0 and UI.BTK_P1Bet == UI.BTK_P2Bet then
                    UI.BTK_TotalPrize = (UI.BTK_P1Bet + UI.BTK_P2Bet) * 0.95
                    UI.PickupTile(pos.b1); UI.PickupTile(pos.b2)
                    UI.LocalChat("`c[WinProxy]: `9Bets taken! Prize (after 5% tax): `2" .. UI.BTK_TotalPrize .. " DLs")
                else
                    UI.LocalChat("`c[WinProxy]: `4Bets un-equal or empty! (P1: " .. UI.BTK_P1Bet .. ", P2: " .. UI.BTK_P2Bet .. ")")
                end
            end
            ImGui.SameLine()
            if ImGui.Button("3. Check Gems", ImVec2(195, 30)) then
                UI.BTK_ActionCheckGems()
            end
            
            ImGui.Spacing()
            if ImGui.Button("4. Drop Prize, Tax & Reset Round", ImVec2(398, 30)) then
                local pos = UI.BTK_GetPositions()
                local standX, standY = 0, 0
                
                if UI.BTK_WinnerSide == "Left" then 
                    standX = UI.BTK_Bet1X - 2
                    standY = UI.BTK_Bet1Y
                elseif UI.BTK_WinnerSide == "Right" then 
                    standX = UI.BTK_Bet2X + 2
                    standY = UI.BTK_Bet2Y
                end
                
                if standX > 0 and standY > 0 then
                    RunThread(function()
                        local function executeSmartDrop(amountDL)
                            local drop_black = math.floor(amountDL / 10000)
                            local rem1 = amountDL % 10000
                            local drop_bgl = math.floor(rem1 / 100)
                            local rem2 = rem1 % 100
                            local drop_dl = math.floor(rem2)
                            local drop_wl = math.floor((rem2 - drop_dl) * 100 + 0.5)
                            
                            if drop_black > 0 then
                                while UI.GetItemCount(UI.GetIcon("Creativeps Black Gem Lock", 11550)) < drop_black do
                                    break
                                end
                                if UI.GetItemCount(UI.GetIcon("Creativeps Black Gem Lock", 11550)) >= drop_black then
                                    SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. UI.GetIcon("Creativeps Black Gem Lock", 11550) .. "|\nitem_count|" .. drop_black)
                                    Sleep(600)
                                end
                            end
                            
                            if drop_bgl > 0 then
                                while UI.GetItemCount(UI.GetIcon("Creativeps Blue Gem Lock", 7188)) < drop_bgl do
                                    if UI.GetItemCount(UI.GetIcon("Creativeps Black Gem Lock", 11550)) > 0 then
                                        SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bluegl")
                                        Sleep(1000)
                                    else
                                        break
                                    end
                                end
                                if UI.GetItemCount(UI.GetIcon("Creativeps Blue Gem Lock", 7188)) >= drop_bgl then
                                    SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. UI.GetIcon("Creativeps Blue Gem Lock", 7188) .. "|\nitem_count|" .. drop_bgl)
                                    Sleep(600)
                                end
                            end
                            
                            if drop_dl > 0 then
                                while UI.GetItemCount(UI.GetIcon("Creativeps Diamond Lock", 1796)) < drop_dl do
                                    if UI.GetItemCount(UI.GetIcon("Creativeps Blue Gem Lock", 7188)) > 0 then
                                        SendPacketRaw(false, {type = 10, value = 7188})
                                        Sleep(1000)
                                    elseif UI.GetItemCount(UI.GetIcon("Creativeps Black Gem Lock", 11550)) > 0 then
                                        SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bluegl")
                                        Sleep(1000)
                                    else
                                        break
                                    end
                                end
                                if UI.GetItemCount(UI.GetIcon("Creativeps Diamond Lock", 1796)) >= drop_dl then
                                    SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. UI.GetIcon("Creativeps Diamond Lock", 1796) .. "|\nitem_count|" .. drop_dl)
                                    Sleep(600)
                                end
                            end
                            
                            if drop_wl > 0 then
                                while UI.GetItemCount(UI.GetIcon("Creativeps World Lock", 242)) < drop_wl do
                                    if UI.GetItemCount(UI.GetIcon("Creativeps Diamond Lock", 1796)) > 0 then
                                        SendPacketRaw(false, {type = 10, value = 1796})
                                        Sleep(1000)
                                    elseif UI.GetItemCount(UI.GetIcon("Creativeps Blue Gem Lock", 7188)) > 0 then
                                        SendPacketRaw(false, {type = 10, value = 7188})
                                        Sleep(1000)
                                    elseif UI.GetItemCount(UI.GetIcon("Creativeps Black Gem Lock", 11550)) > 0 then
                                        SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bluegl")
                                        Sleep(1000)
                                    else
                                        break
                                    end
                                end
                                if UI.GetItemCount(UI.GetIcon("Creativeps World Lock", 242)) >= drop_wl then
                                    SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. UI.GetIcon("Creativeps World Lock", 242) .. "|\nitem_count|" .. drop_wl)
                                    Sleep(600)
                                end
                            end
                        end

                        FindPath(standX, standY)
                        Sleep(850)
                        executeSmartDrop(UI.BTK_TotalPrize)
                        UI.LocalChat("`c[WinProxy]: `9Dropped Prize: `2" .. UI.BTK_TotalPrize .. " DLs")
                        Sleep(500)
                        
                        local totalPool = UI.BTK_P1Bet + UI.BTK_P2Bet
                        local taxToDrop = (totalPool * 0.05) / 2
                        local taxMidX = pos.tax[2].x
                        local taxMidY = pos.tax[2].y
                        
                        if taxToDrop > 0 and taxMidX > 0 then
                            pcall(function() ChangeValue("[C] Modfly", true) end)
                            FindPath(taxMidX, taxMidY)
                            Sleep(850)
                            executeSmartDrop(taxToDrop)
                            UI.LocalChat("`c[WinProxy]: `9Dropped Tax (50%): `2" .. taxToDrop .. " DLs")
                            Sleep(500)
                            pcall(function() ChangeValue("[C] Modfly", false) end)
                        end
                        
                        for _, tile in ipairs(pos.p1) do 
                            FindPath(tile.x, tile.y)
                            Sleep(400)
                            SendPacketRaw(false, { type = 3, value = 5640, px = tile.x, py = tile.y, x = tile.x * 32, y = tile.y * 32 })
                            Sleep(150)
                        end
                        
                        for _, tile in ipairs(pos.p2) do 
                            FindPath(tile.x, tile.y)
                            Sleep(400)
                            SendPacketRaw(false, { type = 3, value = 5640, px = tile.x, py = tile.y, x = tile.x * 32, y = tile.y * 32 })
                            Sleep(150)
                        end
                        
                        UI.BTK_TotalPrize = 0; UI.BTK_P1Bet = 0; UI.BTK_P2Bet = 0; UI.BTK_WinnerSide = nil
                        
                        FindPath(pos.center.x, pos.center.y)
                        Sleep(850)
                    end)
                else
                    UI.LocalChat("`c[WinProxy]: `4Draw/Target Drop invalid! Drop manually.")
                end
            end
        
        elseif UI.CurrentTab == utf8.char(0xf019) .. " Auto Pull" then
            ImGui.TextColored(headerColor, utf8.char(0xf019) .. " Auto Pull & Modal Settings")
            ImGui.Separator()
            ImGui.Spacing()

            if ImGui.CollapsingHeader("Master Control", ImGuiTreeNodeFlags_DefaultOpen) then
                local apChanged, newAp = ImGui.Checkbox("Master Enable Auto Pull (OnSpawn)", UI.AutoPull)
                if apChanged then UI.AutoPull = newAp; UI.SaveConfig(true) end

                local areaChanged, newArea = ImGui.Checkbox("Area Scan Mode (Scan Pos)", UI.AutoPullAreaScan)
                if areaChanged then
                    if newArea and not UI.AutoPullAreaScan then
                        UI.AutoPullAreaScan = true; UI.ManageAreaPullThread()
                    else
                        UI.AutoPullAreaScan = newArea
                    end
                    UI.SaveConfig(true)
                end
                ImGui.Spacing()
            end

            if ImGui.CollapsingHeader("Target Coordinates (5 Positions)", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Setup multiple target positions for pulling:")
                ImGui.Spacing()
                
                for i = 1, 5 do
                    local pos = UI.AutoPullPos[i]
                    local statusColor = (pos.x > 0 or pos.y > 0) and ImVec4(0.2, 1.0, 0.3, 1.0) or ImVec4(0.6, 0.6, 0.6, 1.0)
                    local statusText = (pos.x > 0 or pos.y > 0) and string.format("Slot %d: (%d, %d)", i, pos.x, pos.y) or string.format("Slot %d: Not Set", i)
                    
                    ImGui.TextColored(statusColor, statusText)
                    ImGui.SameLine(180)
                    if ImGui.Button("My Pos##" .. i) then
                        local lp = GetLocal()
                        if lp and lp.pos then
                            UI.AutoPullPos[i].x = math.floor(lp.pos.x / 32)
                            UI.AutoPullPos[i].y = math.floor(lp.pos.y / 32)
                            UI.SaveConfig(true)
                            UI.LocalChat("`c[WinProxy]: `2Target tile " .. i .. " set to your position: (" .. UI.AutoPullPos[i].x .. ", " .. UI.AutoPullPos[i].y .. ")")
                        end
                    end
                    ImGui.SameLine()
                    local touchLabel = (UI.AutoPullSettingSlot == i) and "Touching...##" .. i or "Touch##" .. i
                    if ImGui.Button(touchLabel) then
                        UI.AutoPullSettingSlot = i
                        UI.LocalChat("`c[WinProxy]: `9Touch any tile on screen to set `2Pos " .. i)
                    end
                    ImGui.SameLine()
                    if ImGui.Button("Clear##" .. i) then
                        UI.AutoPullPos[i].x = 0
                        UI.AutoPullPos[i].y = 0
                        UI.SaveConfig(true)
                    end
                end
                
                ImGui.Spacing()
                if ImGui.Button("Reset All 5 Positions") then
                    for i = 1, 5 do UI.AutoPullPos[i] = {x=0, y=0} end
                    UI.SaveConfig(true)
                    UI.LocalChat("`c[WinProxy]: `4All 5 Auto Pull positions have been reset!")
                end
                ImGui.Spacing()
            end

            if ImGui.CollapsingHeader("Minimal Modal Settings", ImGuiTreeNodeFlags_DefaultOpen) then
                local cur_min = tonumber(UI.AutoPullMinModal) or 0
                local displayLabel = (cur_min > 0) and (cur_min .. " BGL (Active)") or "No Limit (Pull All)"
                ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Status: " .. displayLabel)

                ImGui.PushItemWidth(150)
                local mChanged, nMod = ImGui.InputInt("Min Modal (BGL)", UI.AutoPullMinModal)
                if mChanged then
                    UI.AutoPullMinModal = nMod
                    if UI.AutoPullMinModal < 0 then UI.AutoPullMinModal = 0 end
                    UI.SaveConfig(true)
                end
                ImGui.PopItemWidth()
                ImGui.Spacing()
            end

            if ImGui.CollapsingHeader("Live Player Blacklist", ImGuiTreeNodeFlags_DefaultOpen) then
                local sortedUIDs = {}
                if type(UI.AutoPullBlacklist) == "table" then
                    for _, v in ipairs(UI.AutoPullBlacklist) do
                        table.insert(sortedUIDs, tonumber(v) or 0)
                    end
                    table.sort(sortedUIDs)
                end
                
                if #sortedUIDs == 0 then
                    ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "No UIDs currently blacklisted.")
                else
                    ImGui.TextColored(ImVec4(0.4, 1.0, 0.4, 1.0), "Total Blacklisted: " .. #sortedUIDs .. " UID(s)")
                    ImGui.TextWrapped(table.concat(sortedUIDs, ", "))
                end
                ImGui.Spacing()

                ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Select players in world to block:")
                
                if not UI.LastPlayerCacheTime or (os.clock() - UI.LastPlayerCacheTime > 1.0) then
                    UI.CachedPlayerList = GetPlayerList()
                    UI.LastPlayerCacheTime = os.clock()
                end
                
                local pList = UI.CachedPlayerList
                local lpUID = GetLocal() and GetLocal().userid or 0
                local playerCount = 0

                if pList then
                    for _, p in pairs(pList) do
                        local uid = p.userid or p.netid or 0
                        local name = p.name or "Unknown"
                        
                        local cleanName = name:gsub("%[.-%]", "")
                        cleanName = cleanName:gsub("%(.-%)", "")
                        cleanName = cleanName:gsub("%s+", " "):match("^%s*(.-)%s*$") or "Unknown"
                        local plainName = cleanName:gsub("`.", "")
                        
                        if uid ~= 0 and uid ~= lpUID and not plainName:lower():find("spammer slave") then
                            playerCount = playerCount + 1
                            
                            local isBlacklisted = false
                            local blacklistIndex = -1
                            for i, bUid in ipairs(UI.AutoPullBlacklist) do
                                if tonumber(bUid) == uid then
                                    isBlacklisted = true
                                    blacklistIndex = i
                                    break
                                end
                            end
                            
                            local changed, newVal = ImGui.Checkbox(plainName .. " (UID: " .. uid .. ")##cb_"..uid, isBlacklisted)
                            if changed then
                                if newVal then
                                    table.insert(UI.AutoPullBlacklist, uid)
                                else
                                    if blacklistIndex > 0 then table.remove(UI.AutoPullBlacklist, blacklistIndex) end
                                end
                                UI.SaveConfig(true)
                            end
                        end
                    end
                end
                
                if playerCount == 0 then
                    ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "No other players in this world.")
                end
                
                ImGui.Spacing()
                
                ImGui.PushItemWidth(100)
                local changedInput, newUID = ImGui.InputInt("##newuidapt", UI.NewBlacklistUID)
                if changedInput then UI.NewBlacklistUID = newUID end
                ImGui.PopItemWidth()
                ImGui.SameLine()
                
                if ImGui.Button("Add UID") and UI.NewBlacklistUID > 0 then
                    local uid = tonumber(UI.NewBlacklistUID)
                    local found = false
                    for _, v in ipairs(UI.AutoPullBlacklist) do
                        if tonumber(v) == uid then found = true; break end
                    end
                    if not found then
                        table.insert(UI.AutoPullBlacklist, uid)
                        UI.SaveConfig(true)
                    end
                    UI.NewBlacklistUID = 0
                end
                
                ImGui.SameLine()
                
                if ImGui.Button("Remove UID") and UI.NewBlacklistUID > 0 then
                    local uid = tonumber(UI.NewBlacklistUID)
                    local newList = {}
                    for _, v in ipairs(UI.AutoPullBlacklist) do
                        if tonumber(v) ~= uid then table.insert(newList, v) end
                    end
                    UI.AutoPullBlacklist = newList
                    UI.SaveConfig(true)
                    UI.NewBlacklistUID = 0
                end
                ImGui.Spacing()
            end

        
        elseif UI.CurrentTab == utf8.char(0xf290) .. " Magplant" then
            ImGui.TextColored(headerColor, utf8.char(0xf290) .. " Magplant")
            ImGui.Separator()
            ImGui.TextColored(ImVec4(0.6, 0.6, 0.6, 1.0), "This feature will be available soon.")

        elseif UI.CurrentTab == utf8.char(0xf291) .. " Vending" then
            ImGui.TextColored(headerColor, utf8.char(0xf291) .. " Vending")
            ImGui.Separator()
            ImGui.TextColored(ImVec4(0.6, 0.6, 0.6, 1.0), "This feature will be available soon.")

        elseif UI.CurrentTab == utf8.char(0xf022) .. " All Logs" then
            ImGui.TextColored(headerColor, utf8.char(0xf022) .. " Global Activity Logs")
            ImGui.Separator()
            ImGui.Spacing()
            if ImGui.CollapsingHeader(utf8.char(0xf013) .. " Features & Toggles", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.Spacing()
                local logChanged, newLog = ImGui.Checkbox("Enable Auto-Logging (/logs)", UI.LogsEnabled)
                if logChanged then UI.LogsEnabled = newLog; UI.SaveConfig(true) end
                ImGui.SameLine(0, 20)
                if ImGui.Button("Clear All Logs") then
                    UI.Logs = { All = {}, Casino = {}, Inventory = {} }
                    UI.LocalChat("`c[WinProxy]: `9All logs have been cleared.")
                end
                ImGui.Spacing(); ImGui.Separator(); ImGui.Spacing()
                ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Filter Category:")
                if ImGui.Button("All Logs", ImVec2(80, 25)) then UI.LogFilter = 1 end ImGui.SameLine()
                if ImGui.Button("Casino", ImVec2(80, 25)) then UI.LogFilter = 2 end ImGui.SameLine()
                if ImGui.Button("Inventory", ImVec2(80, 25)) then UI.LogFilter = 3 end
                ImGui.Spacing(); ImGui.Separator()
                
                local activeLogArray = UI.Logs.All
                local defaultCatColor = ImVec4(1.0, 1.0, 1.0, 1.0)
                if UI.LogFilter == 2 then 
                    activeLogArray = UI.Logs.Casino; defaultCatColor = ImVec4(0.4, 1.0, 0.4, 1.0)
                elseif UI.LogFilter == 3 then 
                    activeLogArray = UI.Logs.Inventory; defaultCatColor = ImVec4(1.0, 0.8, 0.2, 1.0)
                end

                ImGui.BeginChild("LogDisplayArea", ImVec2(0, 0), true)
                if #activeLogArray == 0 then
                    ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "No logs recorded in this category yet...")
                else
                    for i, logStr in ipairs(activeLogArray) do
                        ImGui.PushTextWrapPos(0.0)
                        local displayStr = logStr:gsub("`.", "")
                        if i % 2 == 0 then 
                            ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), displayStr)
                        else
                            local rowColor = defaultCatColor
                            if UI.LogFilter == 1 then
                                if displayStr:find("spun the wheel") then rowColor = ImVec4(0.4, 1.0, 0.4, 1.0)
                                elseif displayStr:find("Collected") or displayStr:find("Dropped") then rowColor = ImVec4(1.0, 0.8, 0.2, 1.0) end
                            end
                            ImGui.TextColored(rowColor, displayStr)
                        end
                        ImGui.PopTextWrapPos()
                    end
                end
                ImGui.EndChild()
                ImGui.Spacing()
            end

        elseif UI.CurrentTab == utf8.char(0xf07a) .. " Auto Buy Pack" then
            ImGui.TextColored(headerColor, utf8.char(0xf07a) .. " Auto Buy Pack (Smart Detect)")
            ImGui.Separator()
            ImGui.Spacing()
            if ImGui.CollapsingHeader(utf8.char(0xf013) .. " Configuration", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.Spacing()
                local scanBtnText = UI.ABP_IsScanningShop and "SCANNING IN PROGRESS..." or (utf8.char(0xf021) .. " AUTO-SCAN SHOP PACKS")
                if ImGui.Button(scanBtnText, ImVec2(-1, 30)) then
                    if not UI.ABP_IsScanningShop then
                        UI.ABP_IsScanningShop = true
                        UI.ABP_Packs = {}; UI.ABP_PackNames = {}; UI.ABP_AddedCmds = {}
                        RunThread(function()
                            UI.LocalChat("`c[WinProxy]: `9[1/3] Auto-Scanning 'Featured' tab...")
                            SendPacket(2, "action|store\nlocation|gem"); Sleep(1200)
                            UI.LocalChat("`c[WinProxy]: `9[2/3] Auto-Scanning 'Locks & Stuff' tab...")
                            SendPacket(2, "action|buy\nitem|locks"); Sleep(1200)
                            UI.LocalChat("`c[WinProxy]: `9[3/3] Auto-Scanning 'Item Packs' tab...")
                            SendPacket(2, "action|buy\nitem|itempack"); Sleep(1200)
                            table.sort(UI.ABP_Packs, function(a, b) return a.name:lower() < b.name:lower() end)
                            UI.ABP_PackNames = {}
                            for _, p in ipairs(UI.ABP_Packs) do table.insert(UI.ABP_PackNames, p.name) end
                            UI.ABP_PackIdx = 1
                            UI.ABP_IsScanningShop = false
                            UI.LocalChat("`c[WinProxy]: `2[+] Auto-Scan Complete! Absorbed `w" .. #UI.ABP_Packs .. "`2 items (Sorted A-Z).")
                        end)
                    end
                end
                ImGui.Spacing(); ImGui.Separator(); ImGui.Spacing()
                
                if #UI.ABP_Packs == 0 then
                    ImGui.TextColored(ImVec4(1.0, 0.4, 0.4, 1.0), "Click 'Auto-Scan' to silently load packs from the server!")
                else
                    UI.ABP_PackIdx = UI.SafeCombo("Select Pack", UI.ABP_PackIdx, UI.ABP_PackNames)
                    ImGui.Spacing()
                    ImGui.PushItemWidth(150)
                    local amtChg, newAmt = ImGui.InputInt("Amount to Buy", UI.ABP_BuyAmount)
                    if amtChg then 
                        UI.ABP_BuyAmount = newAmt 
                        if UI.ABP_BuyAmount < 0 then UI.ABP_BuyAmount = 0 end 
                    end
                    ImGui.SameLine(); ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "(0 = Infinite)")
                    ImGui.PopItemWidth()
                    
                    local onlyChg, newOnly = ImGui.Checkbox("Buy Only (Do Not Drop)", UI.ABP_BuyOnly)
                    if onlyChg then UI.ABP_BuyOnly = newOnly end

                    local batchChg, newBatch = ImGui.Checkbox("Batch Mode (Buy until full, then Drop)", UI.ABP_BatchMode)
                    if batchChg then UI.ABP_BatchMode = newBatch end
                    
                    if not UI.ABP_BuyOnly then
                        ImGui.Spacing(); ImGui.Separator(); ImGui.Spacing()
                        ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "The script will automatically detect items from the pack")
                        ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "and drop them side-by-side immediately after buying.")
                        ImGui.Spacing()
                        ImGui.PushItemWidth(100)
                        local xChg, nX = ImGui.InputInt("Drop Base X", UI.ABP_DropX)
                        if xChg then UI.ABP_DropX = nX end
                        ImGui.SameLine()
                        local yChg, nY = ImGui.InputInt("Drop Base Y", UI.ABP_DropY)
                        if yChg then UI.ABP_DropY = nY end
                        ImGui.PopItemWidth()
                    end
                end
                ImGui.Spacing()
            end
            ImGui.Spacing(); ImGui.Separator(); ImGui.Spacing()
            if #UI.ABP_Packs > 0 then
                local btnText = UI.AutoBuyPack and "STOP AUTO BUY PACK" or "START AUTO BUY PACK"
                if ImGui.Button(btnText, ImVec2(-1, 35)) then
                    UI.AutoBuyPack = not UI.AutoBuyPack
                    if UI.AutoBuyPack then UI.ManageABPThread() end
                end
            else
                if ImGui.Button("START AUTO BUY PACK (LOCKED)", ImVec2(-1, 35)) then
                    UI.LocalChat("`c[WinProxy]: `4Please Auto-Scan the shop first!")
                end
            end
            ImGui.Spacing()

        elseif UI.CurrentTab == utf8.char(0xf0ac) .. " World" then
            ImGui.TextColored(headerColor, utf8.char(0xf0ac) .. " World Settings")
            ImGui.Separator()
            ImGui.TextColored(ImVec4(0.6, 0.6, 0.6, 1.0), "This feature will be available soon.")
        
        elseif UI.CurrentTab == utf8.char(0xf1fc) .. " Theme & UI" then
    ImGui.TextColored(headerColor, utf8.char(0xf1fc) .. " Dialog Theming")
    ImGui.Separator()
    ImGui.Spacing()

    ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Select a theme for your in-game proxy dialogs.")
    ImGui.Spacing()

    if ImGui.Button("Reset to Default Theme", ImVec2(-1, 30)) then
        UI.DialogBg = nil; UI.DialogBorder = nil; UI.SaveConfig(true)
        UI.LocalChat("`c[WinProxy]: `9Theme reset to `wDefault")
    end
    ImGui.Spacing()

    -- Pastel Mode
    if ImGui.CollapsingHeader("Pastel Mode", ImGuiTreeNodeFlags_DefaultOpen) then
        local pastel_themes = {
            {"Pastel Purple", "225,190,231,255", "156,39,176,255"}, {"Pastel Blue", "187,222,251,255", "33,150,243,255"}, {"Pastel Aqua", "178,235,242,255", "0,188,212,255"},
            {"Pastel Green", "200,230,201,255", "76,175,80,255"}, {"Pastel Yellow", "255,249,196,255", "255,235,59,255"}, {"Pastel Orange", "255,224,178,255", "255,152,0,255"},
            {"Pastel Pink", "248,187,208,255", "233,30,99,255"}
        }
        for i, theme in ipairs(pastel_themes) do
            if ImGui.Button(theme[1] .. "##P" .. i, ImVec2(125, 25)) then
                UI.DialogBg = theme[2]; UI.DialogBorder = theme[3]; UI.SaveConfig(true)
                UI.LocalChat("`c[WinProxy]: `9Theme set to `w" .. theme[1])
            end
            if i % 3 ~= 0 and i ~= #pastel_themes then ImGui.SameLine() end
        end
        ImGui.Spacing()
    end

    -- Dark Mode
    if ImGui.CollapsingHeader("Dark Mode", ImGuiTreeNodeFlags_DefaultOpen) then
        local dark_themes = {
            {"Dark Purple", "49,27,146,255", "81,45,168,255"}, {"Dark Blue", "13,71,161,255", "21,101,192,255"}, {"Dark Aqua", "0,96,100,255", "0,131,143,255"},
            {"Dark Green", "27,94,32,255", "46,125,50,255"}, {"Dark Yellow", "245,127,23,255", "249,168,37,255"}, {"Dark Orange", "230,81,0,255", "239,108,0,255"},
            {"Dark Red", "183,28,28,255", "198,40,40,255"}, {"Dark Brown", "62,39,35,255", "78,52,46,255"}, {"Dark Grey", "33,33,33,255", "66,66,66,255"}
        }
        for i, theme in ipairs(dark_themes) do
            if ImGui.Button(theme[1] .. "##D" .. i, ImVec2(125, 25)) then
                UI.DialogBg = theme[2]; UI.DialogBorder = theme[3]; UI.SaveConfig(true)
                UI.LocalChat("`c[WinProxy]: `9Theme set to `w" .. theme[1])
            end
            if i % 3 ~= 0 and i ~= #dark_themes then ImGui.SameLine() end
        end
        ImGui.Spacing()
    end

    -- Normal Mode
    if ImGui.CollapsingHeader("Normal Mode", ImGuiTreeNodeFlags_DefaultOpen) then
        local normal_themes = {
            {"Purple", "156,39,176,255", "106,27,154,255"}, {"Blue", "33,150,243,255", "21,101,192,255"}, {"Aqua", "0,188,212,255", "0,131,143,255"},
            {"Green", "76,175,80,255", "46,125,50,255"}, {"Yellow", "255,235,59,255", "249,168,37,255"}, {"Orange", "255,152,0,255", "239,108,0,255"},
            {"Red", "244,67,54,255", "198,40,40,255"}, {"Brown", "121,85,72,255", "93,64,55,255"}, {"Black", "0,0,0,255", "33,33,33,255"},
            {"Grey", "158,158,158,255", "117,117,117,255"}, {"White", "255,255,255,255", "224,224,224,255"}
        }
        for i, theme in ipairs(normal_themes) do
            if ImGui.Button(theme[1] .. "##N" .. i, ImVec2(125, 25)) then
                UI.DialogBg = theme[2]; UI.DialogBorder = theme[3]; UI.SaveConfig(true)
                UI.LocalChat("`c[WinProxy]: `9Theme set to `w" .. theme[1])
            end
            if i % 3 ~= 0 and i ~= #normal_themes then ImGui.SameLine() end
        end
        ImGui.Spacing()
    end

elseif UI.CurrentTab == utf8.char(0xf085) .. " Setting" then
            ImGui.TextColored(headerColor, utf8.char(0xf085) .. " Core Proxy Settings")
            ImGui.Separator()
            ImGui.Spacing()
            if ImGui.CollapsingHeader(utf8.char(0xf0c7) .. " Configuration Management", ImGuiTreeNodeFlags_DefaultOpen) then
                ImGui.Spacing()
                ImGui.TextColored(ImVec4(0.8, 0.8, 0.8, 1.0), "Save your current toggles and modes to your local device.")
                ImGui.TextColored(ImVec4(0.5, 0.5, 0.5, 1.0), "File will be saved as: " .. UI.ConfigFileName)
                ImGui.Spacing()
                if ImGui.Button(utf8.char(0xf0c7) .. " Save Current Config", ImVec2(190, 35)) then UI.SaveConfig() end
                ImGui.SameLine()
                if ImGui.Button(utf8.char(0xf021) .. " Reload Config", ImVec2(190, 35)) then UI.LoadConfig() end
                ImGui.Spacing()
                if ImGui.Button(utf8.char(0xf0e2) .. " Reset to Default", ImVec2(390, 35)) then UI.ResetConfig() end
                ImGui.Spacing()
            end

        elseif UI.CurrentTab == utf8.char(0xf05a) .. " Information" then
            ImGui.TextColored(headerColor, utf8.char(0xf05a) .. " Information & Support Center")
            ImGui.Spacing()
            ImGui.Separator()
            ImGui.Spacing()

            ImGui.TextColored(ImVec4(0.8, 0.6, 1.0, 1.0), utf8.char(0xf007) .. " Developer Information")
            ImGui.Indent(20)
            ImGui.TextColored(ImVec4(0.7, 0.7, 1.0, 1.0), "Creator: Win")
            ImGui.TextColored(ImVec4(0.7, 0.7, 1.0, 1.0), "Discord: win.store")
            ImGui.Unindent(20)
            ImGui.Spacing()
            ImGui.Separator()
            ImGui.Spacing()

            ImGui.TextColored(ImVec4(0.8, 0.9, 0.4, 1.0), utf8.char(0xf0c0) .. " Community & Support")
            ImGui.Indent(20)
            ImGui.TextColored(ImVec4(0.9, 0.9, 0.9, 1.0), "WhatsApp Group:")
            if ImGui.Button(utf8.char(0xf095) .. " Join WhatsApp Group", ImVec2(220, 30)) then 
                if isWindows then
                    os.execute('start "" "https://chat.whatsapp.com/IuQ3YdLm2lf4EnnCF1GcXr?mode=gi_t"') 
                else
                    LogToConsole("`2[WinProxy]: `9Link WA: https://chat.whatsapp.com/IuQ3YdLm2lf4EnnCF1GcXr?mode=gi_t")
                end
            end
            ImGui.SameLine()
            if ImGui.Button(utf8.char(0xf0c5) .. " Copy Link##copywa", ImVec2(120, 30)) then
                local pipe = io.popen('echo https://chat.whatsapp.com/IuQ3YdLm2lf4EnnCF1GcXr?mode=gi_t | clip', 'w')
                if pipe then pipe:close() end
                LogToConsole("`2[UI] `9WhatsApp link copied to clipboard!")
            end
            ImGui.Spacing()
            
            ImGui.TextColored(ImVec4(0.9, 0.9, 0.9, 1.0), "Discord Community:")
            if ImGui.Button(utf8.char(0xf086) .. " Join Discord Community", ImVec2(220, 30)) then 
                if isWindows then
                    os.execute('start "" "https://discord.gg/kUuE2f98FK"') 
                else
                    LogToConsole("`2[WinProxy]: `9Link Discord: https://discord.gg/kUuE2f98FK")
                end
            end
            ImGui.SameLine()
            if ImGui.Button(utf8.char(0xf0c5) .. " Copy Link##copydc", ImVec2(120, 30)) then
                if isWindows then
                    local pipe = io.popen('echo https://discord.gg/kUuE2f98FK | clip', 'w')
                    if pipe then pipe:close() end
                    LogToConsole("`2[UI] `9Discord link copied to clipboard!")
                else
                    LogToConsole("`2[UI] `9Link Discord: https://discord.gg/kUuE2f98FK")
                end
            end
            ImGui.Unindent(20)
            ImGui.Spacing()
            ImGui.Separator()
            ImGui.Spacing()

            ImGui.TextColored(ImVec4(0.6, 1.0, 0.6, 1.0), utf8.char(0xf06b) .. " Version Information")
            ImGui.Indent(20)
            ImGui.TextColored(ImVec4(0.9, 0.9, 0.9, 1.0), "Proxy Version: 1.0")
            ImGui.TextColored(ImVec4(0.9, 0.9, 0.9, 1.0), "Status: Active Development")
            ImGui.TextColored(ImVec4(1.0, 0.7, 0.3, 1.0), "Support: Available via Discord or WhatsApp")
            ImGui.Unindent(20)
            ImGui.Spacing()
        
        end
        
        ImGui.EndChild()
        ImGui.Columns(1)
    end

    ImGui.End()
end



-- ==========================================
-- DIALOG : Main Menu & Core
-- ==========================================

function UI.GetIcon(name, fallbackID)
    if UI.ItemDB and UI.ItemDB[name:lower()] then
        return UI.ItemDB[name:lower()]
    end
    return fallbackID
end


function UI.GetDialogColorPalette()
    return {
        { id = "pinkpastel",    category = "Pastel Themes",        label = "`pPink Pastel",   icon = 510,  border = "255,192,203,255", bg = "255,192,203,200" },
        { id = "orangepastel",  category = "Pastel Themes",        label = "`6Orange Pastel", icon = 512,  border = "255,218,185,255", bg = "255,218,185,200" },
        { id = "yellowpastel",  category = "Pastel Themes",        label = "`9Yellow Pastel", icon = 514,  border = "255,255,224,255", bg = "255,255,224,200" },
        { id = "greenpastel",   category = "Pastel Themes",        label = "`2Green Pastel",  icon = 516,  border = "144,238,144,255", bg = "144,238,144,200" },
        { id = "aquapastel",    category = "Cool Pastel Themes",   label = "`cAqua Pastel",   icon = 518,  border = "175,238,238,255", bg = "175,238,238,200" },
        { id = "bluepastel",    category = "Cool Pastel Themes",   label = "`3Blue Pastel",   icon = 520,  border = "173,216,230,255", bg = "173,216,230,200" },
        { id = "purplepastel",  category = "Cool Pastel Themes",   label = "`#Purple Pastel", icon = 522,  border = "221,160,221,255", bg = "221,160,221,200" },
        { id = "darkred",       category = "Dark Themes",          label = "`4Dark Red",      icon = 2014, border = "139,0,0,255",     bg = "70,0,0,200" },
        { id = "darkgrey",      category = "Dark Themes",          label = "`7Dark Grey",     icon = 2012, border = "100,100,100,255", bg = "45,45,45,200" },
        { id = "darkorange",    category = "Dark Themes",          label = "`6Dark Orange",   icon = 2016, border = "180,90,0,255",    bg = "80,40,0,200" },
        { id = "darkyellow",    category = "Dark Themes",          label = "`9Dark Yellow",   icon = 2018, border = "165,140,0,255",   bg = "75,60,0,200" },
        { id = "darkgreen",     category = "Dark Themes",          label = "`2Dark Green",    icon = 2020, border = "0,120,70,255",    bg = "0,50,28,200" },
        { id = "darkaqua",      category = "Dark Themes",          label = "`cDark Aqua",     icon = 2022, border = "0,120,120,255",   bg = "0,50,50,200" },
        { id = "darkblue",      category = "Dark Themes",          label = "`3Dark Blue",     icon = 2024, border = "35,75,150,255",   bg = "12,30,80,200" },
        { id = "darkpurple",    category = "Dark Themes",          label = "`#Dark Purple",   icon = 2026, border = "110,60,150,255",  bg = "45,20,80,200" },
        { id = "darkbrown",     category = "Dark Themes",          label = "`oDark Brown",    icon = 2028, border = "110,75,45,255",   bg = "55,35,18,200" },
        { id = "classicgrey",   category = "Classic Block Themes", label = "`7Grey",          icon = 164,  border = "160,160,160,255", bg = "120,120,120,200" },
        { id = "classicblack",  category = "Classic Block Themes", label = "`0Black",         icon = 166,  border = "70,70,70,255",    bg = "20,20,20,200" },
        { id = "classicwhite",  category = "Classic Block Themes", label = "`wWhite",         icon = 168,  border = "255,255,255,255", bg = "230,230,230,210" },
        { id = "classicred",    category = "Classic Block Themes", label = "`4Red",           icon = 170,  border = "220,70,70,255",   bg = "170,35,35,200" },
        { id = "classicorange", category = "Classic Block Themes", label = "`6Orange",        icon = 172,  border = "235,145,45,255",  bg = "185,95,20,200" },
        { id = "classicyellow", category = "Classic Block Themes", label = "`9Yellow",        icon = 174,  border = "245,220,70,255",  bg = "195,170,25,200" },
        { id = "classicgreen",  category = "Classic Block Themes", label = "`2Green",         icon = 176,  border = "90,200,90,255",   bg = "45,145,45,200" },
        { id = "classicaqua",   category = "Classic Block Themes", label = "`cAqua",          icon = 178,  border = "75,210,210,255",  bg = "30,150,150,200" },
        { id = "classicblue",   category = "Classic Block Themes", label = "`3Blue",          icon = 180,  border = "85,140,230,255",  bg = "40,85,180,200" },
        { id = "classicpurple", category = "Classic Block Themes", label = "`#Purple",        icon = 182,  border = "165,105,220,255", bg = "110,55,170,200" },
        { id = "classicbrown",  category = "Classic Block Themes", label = "`oBrown",         icon = 184,  border = "165,115,70,255",  bg = "110,70,35,200" }
    }
end

function UI.ApplyTheme(content)
    if UI.DialogBg and UI.DialogBorder and type(content) == "string" then
        if not content:find("set_bg_color") and not content:find("set_border_color") then
            local replacement = "set_default_color|`o\nset_border_color|"..UI.DialogBorder.."|\nset_bg_color|"..UI.DialogBg.."|\n"
            if content:find("set_default_color|`o") then
                content = content:gsub("set_default_color|`o\n?", replacement, 1)
            else
                content = replacement .. content
            end
        end
    end
    return content
end

function UI.ChangeDialogColor()
    local dialog = [[
set_default_color|`o
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjjjj|

add_label_with_icon|big|`cWinProxy Themes|left|]] .. UI.GetIcon("Painting Easel", 1000) .. [[|
add_spacer|small|
add_smalltext|`7Personalize your WinProxy experience. Changes apply globally!|left|
add_spacer|small|

add_button_with_icon|resetdefault|`cReset Theme|staticYellowFrame|]] .. UI.GetIcon("Frost Dragon of Legend - 104", 17508) .. [[||
add_button_with_icon||END_LIST|noflags|0||
add_spacer|small|

add_label|medium|`cPastel Mode `0:|
add_button_with_icon|purplepastel|`#Pastel Purple|staticYellowFrame|]] .. UI.GetIcon("Pastel Purple Block", 522) .. [[||
add_button_with_icon|bluepastel|`3Pastel Blue|staticYellowFrame|]] .. UI.GetIcon("Pastel Blue Block", 520) .. [[||
add_button_with_icon|aquapastel|`cPastel Aqua|staticYellowFrame|]] .. UI.GetIcon("Pastel Aqua Block", 518) .. [[||
add_button_with_icon|greenpastel|`2Pastel Green|staticYellowFrame|]] .. UI.GetIcon("Pastel Green Block", 516) .. [[||
add_button_with_icon|yellowpastel|`9Pastel Yellow|staticYellowFrame|]] .. UI.GetIcon("Pastel Yellow Block", 514) .. [[||
add_button_with_icon|orangepastel|`6Pastel Orange|staticYellowFrame|]] .. UI.GetIcon("Pastel Orange Block", 512) .. [[||
add_button_with_icon|pinkpastel|`pPastel Pink|staticYellowFrame|]] .. UI.GetIcon("Pastel Pink Block", 510) .. [[||
add_button_with_icon||END_LIST|noflags|0||
add_spacer|small|

add_label|medium|`cDark Mode `0:|
add_button_with_icon|darkpurple|`#Dark Purple|staticYellowFrame|]] .. UI.GetIcon("Dark Purple Block", 2026) .. [[||
add_button_with_icon|darkblue|`3Dark Blue|staticYellowFrame|]] .. UI.GetIcon("Dark Blue Block", 2024) .. [[||
add_button_with_icon|darkaqua|`cDark Aqua|staticYellowFrame|]] .. UI.GetIcon("Dark Aqua Block", 2022) .. [[||
add_button_with_icon|darkgreen|`2Dark Green|staticYellowFrame|]] .. UI.GetIcon("Dark Green Block", 2020) .. [[||
add_button_with_icon|darkyellow|`9Dark Yellow|staticYellowFrame|]] .. UI.GetIcon("Dark Yellow Block", 2018) .. [[||
add_button_with_icon|darkorange|`6Dark Orange|staticYellowFrame|]] .. UI.GetIcon("Dark Orange Block", 2016) .. [[||
add_button_with_icon|darkred|`4Dark Red|staticYellowFrame|]] .. UI.GetIcon("Dark Red Block", 2014) .. [[||
add_button_with_icon|darkbrown|`oDark Brown|staticYellowFrame|]] .. UI.GetIcon("Dark Brown Block", 2028) .. [[||
add_button_with_icon|darkgrey|`7Dark Grey|staticYellowFrame|]] .. UI.GetIcon("Dark Grey Block", 2012) .. [[||
add_button_with_icon||END_LIST|noflags|0||
add_spacer|small|

add_label|medium|`cNormal Mode `0:|
add_button_with_icon|classicpurple|`#Purple|staticYellowFrame|]] .. UI.GetIcon("Purple Block", 182) .. [[||
add_button_with_icon|classicblue|`3Blue|staticYellowFrame|]] .. UI.GetIcon("Blue Block", 180) .. [[||
add_button_with_icon|classicaqua|`cAqua|staticYellowFrame|]] .. UI.GetIcon("Aqua Block", 178) .. [[||
add_button_with_icon|classicgreen|`2Green|staticYellowFrame|]] .. UI.GetIcon("Green Block", 176) .. [[||
add_button_with_icon|classicyellow|`9Yellow|staticYellowFrame|]] .. UI.GetIcon("Yellow Block", 174) .. [[||
add_button_with_icon|classicorange|`6Orange|staticYellowFrame|]] .. UI.GetIcon("Orange Block", 172) .. [[||
add_button_with_icon|classicred|`4Red|staticYellowFrame|]] .. UI.GetIcon("Red Block", 170) .. [[||
add_button_with_icon|classicbrown|`oBrown|staticYellowFrame|]] .. UI.GetIcon("Brown Block", 184) .. [[||
add_button_with_icon|classicblack|`0Black|staticYellowFrame|]] .. UI.GetIcon("Black Block", 166) .. [[||
add_button_with_icon|classicgrey|`7Grey|staticYellowFrame|]] .. UI.GetIcon("Grey Block", 164) .. [[||
add_button_with_icon|classicwhite|`wWhite|staticYellowFrame|]] .. UI.GetIcon("White Block", 168) .. [[||
add_button_with_icon||END_LIST|noflags|0||
add_spacer|small|

add_quick_exit||
end_dialog|changedialogcolor|Close||
]]
    SendVariantList({ [0] = "OnDialogRequest", [1] = UI.ApplyTheme(dialog) })
end
function UI.ShowMainDialog()

    local myPlayer = GetLocal()
    local playerName = (myPlayer and myPlayer.name) or "Unknown"
    local dateStr = os.date("!%a, %b/%d/%Y")
    local timeStr = os.date("%I:%M %p")
    
    local dialog = [[
add_label_with_icon|big|`cWin-Community Script|left|]] .. UI.GetIcon("Megaphone", 2480) .. [[|
add_image_button|banner_img|]] .. UI.BannerDialogPath .. [[|banner_img|400|200|
add_textbox|`9GrowID `0: ]] .. playerName .. [[|
add_textbox|`9Date `0: `2]] .. dateStr .. [[|
add_textbox|`9Time `0: `2]] .. timeStr .. [[|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|

add_button_with_icon|btn_commands|`cCommands|staticYellowFrame|]] .. UI.GetIcon("Dumb Question 3", 6128) .. [[||
add_button_with_icon||END_LIST|noflags|0||

add_label|medium|`cAll Feature `0:|
add_button_with_icon|btn_general|`cGeneral|staticYellowFrame|]] .. UI.GetIcon("Mini-Mod", 4758) .. [[||
add_button_with_icon|btn_wrench|`cWrench|staticYellowFrame|]] .. UI.GetIcon("Wrench", 15418) .. [[||
add_button_with_icon|btn_donate|`cDonate|staticYellowFrame|]] .. UI.GetIcon("Donation Box", 1452) .. [[||
add_button_with_icon|btn_trade|`cTrade|staticYellowFrame|]] .. UI.GetIcon("Creativeps World Lock", 242) .. [[||
add_button_with_icon|btn_telephone|`cTelephone|staticYellowFrame|]] .. UI.GetIcon("Telephone", 3898) .. [[||
add_button_with_icon|btn_toggle_emoji|`cEmoji & Color|staticYellowFrame|]] .. UI.GetIcon("Happy Block", 5776) .. [[||
add_button_with_icon|btn_calc|`cCalculator|staticYellowFrame|]] .. UI.GetIcon("Compu Panel", 1164) .. [[||
add_button_with_icon|btn_itemdb|`cItem Database|staticYellowFrame|]] .. UI.GetIcon("Growscan 9000", 6016) .. [[||
add_button_with_icon|btn_ptht|`4Auto PTHT|staticYellowFrame|]] .. UI.GetIcon("Dumb Farmer", 7064) .. [[||
add_button_with_icon|btn_pnb|`4Auto PNB|staticYellowFrame|]] .. UI.GetIcon("Dumb Builder", 7070) .. [[||
add_button_with_icon|btn_auto_cook|`4Auto Cook|staticYellowFrame|]] .. UI.GetIcon("Dumb Cook", 7076) .. [[||
add_button_with_icon|btn_auto_fish|`cAuto Fish|staticYellowFrame|]] .. UI.GetIcon("Dumb Fisher", 7072) .. [[||
add_button_with_icon|btn_auto_surg|`cAuto Surg|staticYellowFrame|]] .. UI.GetIcon("Dumb Surgeon", 7068) .. [[||
add_button_with_icon|btn_auto_crime|`cAuto Crime|staticYellowFrame|]] .. UI.GetIcon("Crime Wave", 2382) .. [[||
add_button_with_icon|btn_auto_geiger|`4Auto Geiger|staticYellowFrame|]] .. UI.GetIcon("Geiger Counter", 2204) .. [[||
add_button_with_icon|btn_auto_provider|`4Auto Provider|staticYellowFrame|]] .. UI.GetIcon("Black Atm Machine", 17024) .. [[||
add_button_with_icon|btn_auto_buypack|`cAuto Buy Pack|staticYellowFrame|]] .. UI.GetIcon("Dumb G4g Crate Pack", 10868) .. [[||
add_button_with_icon|btn_gambling|`cCasino|staticYellowFrame|]] .. UI.GetIcon("Roulette Wheel", 758) .. [[||
add_button_with_icon|btn_btkbj|`cBTK & BJ|staticYellowFrame|]] .. UI.GetIcon("Chandelier", 340) .. [[||
add_button_with_icon|btn_autopull_settings|`cAuto Pull|staticYellowFrame|]] .. UI.GetIcon("Shocking Wrench Decoration", 14822) .. [[||
add_button_with_icon|btn_afk|`4AFK|staticYellowFrame|]] .. UI.GetIcon("Dumb Worker", 1000) .. [[||
add_button_with_icon|btn_spam|`cAuto Spam|staticYellowFrame|]] .. UI.GetIcon("Spammer Slave", 16990) .. [[||
add_button_with_icon|btn_sb|`cAuto SB|staticYellowFrame|]] .. UI.GetIcon("Locke's Megaphone", 1000) .. [[||
add_button_with_icon|btn_sbd|`cAuto SDB|staticYellowFrame|]] .. UI.GetIcon("Megaphone", 2480) .. [[||
add_button_with_icon|btn_mag|`4Magplant|staticYellowFrame|]] .. UI.GetIcon("MAGPLANT 5000", 5638) .. [[||
add_button_with_icon|btn_vend|`4Vending|staticYellowFrame|]] .. UI.GetIcon("Digivend Machine", 1000) .. [[||
add_button_with_icon|btn_wtw|`4WTW|staticYellowFrame|]] .. UI.GetIcon("Door", 10) .. [[||
add_button_with_icon|btn_world|`4World|staticYellowFrame|]] .. UI.GetIcon("Main Door", 6) .. [[||
add_button_with_icon|btn_logs|`cAll Logs|staticYellowFrame|]] .. UI.GetIcon("Security Camera", 1436) .. [[||
add_button_with_icon|btn_theme|`cTheme & UI|staticYellowFrame|]] .. UI.GetIcon("Painting Easel", 1000) .. [[||
add_button_with_icon|btn_setting|`cSetting|staticYellowFrame|]] .. UI.GetIcon("Steampunk Sprocket", 3310) .. [[||
add_button_with_icon|btn_info|`cInformation|staticYellowFrame|]] .. UI.GetIcon("Digital Sign", 11186) .. [[||
add_button_with_icon||END_LIST|noflags|0||

text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_quick_exit|
end_dialog|cmdend|Close|
]]
    UI.CreateDialog(dialog)
end
function UI.ShowCommandsDialog()
    local dialog = [[
add_label_with_icon|big|`9Command Center|left|]] .. UI.GetIcon("Dumb Question 3", 6128) .. [[|
add_spacer|small|
add_label_with_icon|small|`9Casino Modes|left|]] .. UI.GetIcon("Roulette Wheel", 758) .. [[|
add_smalltext|`b/casinomenu `w: Open Casino Menu directly.|
add_smalltext|`b/allmode `w: Toggle All (Reme, Leme, Qeme) mode.|
add_smalltext|`b/reme `w: Toggle Reme calculator mode.|
add_smalltext|`b/qeme `w: Toggle Qeme calculator mode.|
add_smalltext|`b/leme `w: Toggle Leme calculator mode.|
add_smalltext|`b/lemes `w: Toggle Leme S calculator mode.|
add_smalltext|`b/ceme `w: Toggle Ceme calculator mode.|
add_smalltext|`b/lewa <num> `w: Set Lewa multiplier & Enable.|
add_spacer|small|
add_label_with_icon|small|`9Auto Pull & Min Modal|left|]] .. UI.GetIcon("Shocking Wrench Decoration", 14822) .. [[|
add_smalltext|`b/autopullmenu `w: Open Auto Pull Menu directly.|
add_smalltext|`b/autopull `w: Toggle Auto Pull Master.|
add_smalltext|`b/posautopull `w: Set Auto Pull target to your tile.|
add_smalltext|`b/clearposautopull `w: Reset target back to White Door.|
add_smalltext|`b/apblacklist add <uid> `w: Add UID to blacklist.|
add_smalltext|`b/apblacklist remove <uid> `w: Remove UID from blacklist.|
add_smalltext|`b/apblacklist list `w: Show current blacklist in chat.|
add_spacer|small|
add_label_with_icon|small|`9Wrench Controls|left|]] .. UI.GetIcon("Wrench", 15418) .. [[|
add_smalltext|`b/wrenchmenu `w: Open Wrench Menu directly.|
add_smalltext|`b/wrp, /wrps `w: Auto Pull (Left Click / Right Click).|
add_smalltext|`b/wrk, /wrks `w: Auto Kick (Left Click / Right Click).|
add_smalltext|`b/wrb, /wrbs `w: Auto World Ban (Left Click / Right Click).|
add_smalltext|`b/wrt, /wrts `w: Auto Trade (Left Click / Right Click).|
add_smalltext|`b/showbal `w: Toggle fast balance on inspect.|
add_spacer|small|
add_label_with_icon|small|`9Smart Donation|left|]] .. UI.GetIcon("Donation Box", 1452) .. [[|
add_smalltext|`b/donatemenu `w: Open Donate Menu directly.|
add_smalltext|`b/dmode `w: Toggle Smart Donation Mode.|
add_smalltext|`b/pw <qty> `w: Remote Donate World Lock.|
add_smalltext|`b/pd <qty> `w: Remote Donate Diamond Lock.|
add_smalltext|`b/pb <qty> `w: Remote Donate Blue Gem Lock.|
add_smalltext|`b/pbl <qty> `w: Remote Donate Black GL.|
add_smalltext|`b/pall `w: Remote Donate All Locks in inventory.|
add_smalltext|`b/takeall `w: Retrieve all items from Box.|
add_spacer|small|
add_label_with_icon|small|`9Advanced Trading|left|]] .. UI.GetIcon("Creativeps World Lock", 242) .. [[|
add_smalltext|`b/trademenu `w: Open Trade Menu directly.|
add_smalltext|`b/tmode `w: Toggle Trade Wrench Mode.|
add_smalltext|`b/tw <qty> `w: Fast add World Lock to trade.|
add_smalltext|`b/td <qty> `w: Fast add Diamond Lock to trade.|
add_smalltext|`b/tb <qty> `w: Fast add Blue Gem Lock to trade.|
add_smalltext|`b/tbl <qty> `w: Fast add Black GL to trade.|
add_smalltext|`b/tall `w: Fast add All Locks to trade.|
add_smalltext|`b/tclear `w: Clear all locks from Trade window.|
add_spacer|small|
add_label_with_icon|small|`9Telephone Commands|left|]] .. UI.GetIcon("Telephone", 3898) .. [[|
add_smalltext|`b/telemenu `w: Open Telephone Menu directly.|
add_smalltext|`b/cvdl `w: Auto Convert DL to BGL.|
add_smalltext|`b/buybgl `w: Auto Buy Blue Gem Lock.|
add_smalltext|`b/buydl `w: Auto Buy Diamond Lock.|
add_smalltext|`b/buychamp `w: Auto Buy Champagne (Normal).|
add_smalltext|`b/buychampbg `w: Auto Buy Champagne (Black Gems).|
add_smalltext|`b/buychampbulk `w: Auto Buy Bulk Champagne.|
add_spacer|small|
add_label_with_icon|small|`9Smart Calculator|left|]] .. UI.GetIcon("Compu Panel", 1164) .. [[|
add_smalltext|`b/calcmenu `w: Open Calculator Menu directly.|
add_smalltext|`b/calc <form> `w: Calculate math instantly.|
add_spacer|small|
add_label_with_icon|small|`9Auto-Spam Settings|left|]] .. UI.GetIcon("Spammer Slave", 16990) .. [[|
add_smalltext|`b/spammenu `w: Open the Spam UI Menu directly.|
add_smalltext|`b/spam `w: Toggle Auto-Spam on/off.|
add_smalltext|`b/addspam <txt> `w: Add a new spam message.|
add_smalltext|`b/removespam `w: Remove the last spam message.|
add_smalltext|`b/spamtext <num> <txt> `w: Edit specific spam line.|
add_spacer|small|
add_label_with_icon|small|`9Super Broadcast|left|]] .. UI.GetIcon("Megaphone", 2480) .. [[|
add_smalltext|`b/sbmenu `w: Open SB & SDB Menu directly.|
add_smalltext|`b/sbstart `w: Start Super Broadcast.|
add_smalltext|`b/sbstop `w: Stop Super Broadcast.|
add_smalltext|`b/sdbstart `w: Start Super Duper Broadcast.|
add_smalltext|`b/sdbstop `w: Stop Super Duper Broadcast.|
add_spacer|small|
add_label_with_icon|small|`9Emoji & Color Customization|left|]] .. UI.GetIcon("Happy Block", 5776) .. [[|
add_smalltext|`b/emojimenu `w: Open Emoji Menu directly.|
add_smalltext|`b/emoji `w: Toggle Random Chat Emojis.|
add_smalltext|`b/watermark `w: Toggle Chat Watermark.|
add_spacer|small|
add_label_with_icon|small|`9Logs & History|left|]] .. UI.GetIcon("Security Camera", 1436) .. [[|
add_smalltext|`b/logsmenu `w: Open main Logs Menu Dialog.|
add_smalltext|`b/logs `w: Toggle activity logging on/off.|
add_smalltext|`b/clogs `w: Open Collect Logs directly.|
add_smalltext|`b/dlogs `w: Open Drop Logs directly.|
add_smalltext|`b/invlogs `w: Open Inventory Logs directly.|
add_smalltext|`b/slogs `w: Open Casino/Spin Logs directly.|
add_spacer|small|
add_label_with_icon|small|`9Economy & Drop|left|]] .. UI.GetIcon("Creativeps Blue Gem Lock", 7188) .. [[|
add_smalltext|`b/dw <qty> `w: Auto drop World Lock.|
add_smalltext|`b/dd <qty> `w: Auto drop Diamond Lock.|
add_smalltext|`b/db <qty> `w: Auto drop Blue Gem Lock.|
add_smalltext|`b/dbl <qty> `w: Auto drop Black Gem Lock.|
add_smalltext|`b/daw `w: Drop all locks in backpack.|
add_smalltext|`b/depo <qty> `w: Deposit BGL to bank.|
add_smalltext|`b/with <qty> `w: Withdraw BGL from bank.|
add_smalltext|`b/blue `w: Convert Black GL to Blue GL.|
add_smalltext|`b/black `w: Convert Blue GL to Black GL.|
add_spacer|small|
add_label_with_icon|small|`9General Proxy Features|left|]] .. UI.GetIcon("Mini-Mod", 4758) .. [[|
add_smalltext|`b/antilag `w: Toggle Anti-Lag (Particle/Shadow).|
add_smalltext|`b/hidespammer `w: Toggle Hide Spammer Slave.|
add_smalltext|`b/antipickup `w: Toggle Anti-Pickup items.|
add_smalltext|`b/modfly `w: Toggle Modfly.|
add_smalltext|`b/antiportal `w: Toggle Anti Portal.|
add_smalltext|`b/nightvision `w: Toggle Night Vision.|
add_smalltext|`b/blocksdb `w: Toggle Block SDB Dialogs.|
add_smalltext|`b/autocv `w: Toggle Auto CV All Locks on collect.|
add_smalltext|`b/tp `w: Toggle Teleport Punch (Display/Vend).|
add_smalltext|`b/modal `w: Show your own total balance.|
add_smalltext|`b/fastdrop `w: Toggle fast drop without confirmation.|
add_smalltext|`b/fasttrash `w: Toggle fast trash without confirmation.|
add_smalltext|`b/vendfilter `w: Formats huge World Lock prices.|
add_smalltext|`b/donfilter `w: Shows actual item icons in Dono Box.|
add_smalltext|`b/sboxfilter `w: Enable Storage Box Xtreme Take-All mode.|
add_spacer|small|
add_label_with_icon|small|`9BTK & BJ Commands|left|]] .. UI.GetIcon("Chandelier", 340) .. [[|
add_smalltext|`b/btkmenu, /bjmenu `w: Open Host Dialog Panel.|
add_smalltext|`b/btkcmd, /bjcmd `w: Open BTK/BJ Command List.|
add_smalltext|`b/btk, /bj `w: Switch Game Mode (BTK / BJ).|
add_smalltext|`b/btkremote, /bjremote `w: Collect Remote from Magplant.|
add_smalltext|`b/btkbet, /bjbet `w: Take Bets & Calculate Tax.|
add_smalltext|`b/btkgems, /bjgems `w: Check Gems & Announce Winner.|
add_smalltext|`b/btkdrop, /bjdrop `w: Drop Prize, Tax & Reset.|
add_smalltext|`b/btkcenter, /bjcenter `w: Touch/Punch to set Host Center tile.|
add_smalltext|`b/btkposbet1, /bjposbet1 `w: Touch/Punch to set Bet Player 1 tile.|
add_smalltext|`b/btkposbet2, /bjposbet2 `w: Touch/Punch to set Bet Player 2 tile.|
add_smalltext|`b/btkposbreak1, /bjposbreak1 `w: Touch/Punch to set Break P1 tile.|
add_smalltext|`b/btkposbreak2, /bjposbreak2 `w: Touch/Punch to set Break P2 tile.|
add_smalltext|`b/btktax, /bjtax `w: Touch/Punch to set Tax Drop tile.|
add_smalltext|`b/btkmag, /bjmag `w: Touch/Punch to set Magplant tile.|
add_spacer|small|
add_label_with_icon|small|`9System & Tools|left|]] .. UI.GetIcon("Dummy Puzzle Icon", 11986) .. [[|
add_smalltext|`b/menu, /help `w: Open Main Menu Dialog in-game.|
add_smalltext|`b/cmd `w: Open this Commands Dialog directly.|
add_smalltext|`b/settingmenu `w: Open Setting Menu directly.|
add_smalltext|`b/imgui, /proxy `w: Open/Close ImGui Panel.|
add_smalltext|`b/g, /ghost `w: Shortcut for /ghost.|
add_smalltext|`b/res `w: Shortcut for Respawn.|
add_smalltext|`b/re `w: Shortcut for Rejoin World.|
add_smalltext|`b/relog `w: Shortcut to Reconnect server.|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : Sub-Menu Specific Command Lists
-- ==========================================

function UI.ShowGeneralCommandsDialog()
    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9General Commands List|left|]] .. UI.GetIcon("Mini-Mod", 4758) .. [[|
add_spacer|small|
add_textbox|`wFast in-game commands for General Proxy Features:|left|
add_spacer|small|
add_smalltext|`b/antilag `w: Toggle Anti-Lag (Particle/Shadow).|left|
add_smalltext|`b/hidespammer `w: Toggle Hide Spammer Slave.|left|
add_smalltext|`b/antipickup `w: Toggle Anti-Pickup items.|
add_smalltext|`b/modfly `w: Toggle Modfly.|
add_smalltext|`b/antiportal `w: Toggle Anti Portal.|
add_smalltext|`b/nightvision `w: Toggle Night Vision.|left|
add_smalltext|`b/blocksdb `w: Toggle Block SDB Dialogs.|left|
add_smalltext|`b/autocv `w: Toggle Auto CV All Locks on collect.|left|
add_smalltext|`b/tp `w: Toggle Teleport Punch (Display/Vend).|left|
add_smalltext|`b/modal `w: Calculate & show your own total balance.|left|
add_smalltext|`b/fastdrop `w: Toggle fast drop without confirmation.|left|
add_smalltext|`b/fasttrash `w: Toggle fast trash without confirmation.|left|
add_smalltext|`b/vendfilter `w: Formats huge World Lock prices.|left|
add_smalltext|`b/donfilter `w: Shows actual item icons in Dono Box.|left|
add_smalltext|`b/sboxfilter `w: Enable Storage Box Xtreme Take-All mode.|left|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|btn_general|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

function UI.ShowWrenchCommandsDialog()
    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9Wrench Commands List|left|]] .. UI.GetIcon("Wrench", 15418) .. [[|
add_spacer|small|
add_textbox|`wFast in-game commands for Wrench Controls:|left|
add_spacer|small|
add_smalltext|`b/wrenchmenu `w: Open Wrench Menu directly.|left|
add_smalltext|`b/wrp, /wrps `w: Auto Pull (Left Click / Right Click).|left|
add_smalltext|`b/wrk, /wrks `w: Auto Kick (Left Click / Right Click).|left|
add_smalltext|`b/wrb, /wrbs `w: Auto World Ban (Left Click / Right Click).|left|
add_smalltext|`b/wrt, /wrts `w: Auto Trade (Left Click / Right Click).|left|
add_smalltext|`b/showbal `w: Toggle fast balance on inspect.|left|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|btn_wrench|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

function UI.ShowDonateCommandsDialog()
    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9Donate Commands List|left|]] .. UI.GetIcon("Donation Box", 1452) .. [[|
add_spacer|small|
add_textbox|`wFast in-game commands for Smart Donation:|left|
add_spacer|small|
add_smalltext|`b/donatemenu `w: Open Donate Menu directly.|left|
add_smalltext|`b/dmode `w: Toggle Smart Donation Mode.|left|
add_smalltext|`b/pw <qty> `w: Remote Donate World Lock.|left|
add_smalltext|`b/pd <qty> `w: Remote Donate Diamond Lock.|left|
add_smalltext|`b/pb <qty> `w: Remote Donate Blue Gem Lock.|left|
add_smalltext|`b/pbl <qty> `w: Remote Donate Black GL.|left|
add_smalltext|`b/pall `w: Remote Donate All Locks in inventory.|left|
add_smalltext|`b/takeall `w: Retrieve all items from Box.|left|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|btn_donate|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

function UI.ShowTradeCommandsDialog()
    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9Trade Commands List|left|]] .. UI.GetIcon("Creativeps World Lock", 242) .. [[|
add_spacer|small|
add_textbox|`wFast in-game commands for Advanced Trading:|left|
add_spacer|small|
add_smalltext|`b/trademenu `w: Open Trade Menu directly.|left|
add_smalltext|`b/tmode `w: Toggle Trade Wrench Mode.|left|
add_smalltext|`b/tw <qty> `w: Fast add World Lock to trade.|left|
add_smalltext|`b/td <qty> `w: Fast add Diamond Lock to trade.|left|
add_smalltext|`b/tb <qty> `w: Fast add Blue Gem Lock to trade.|left|
add_smalltext|`b/tbl <qty> `w: Fast add Black GL to trade.|left|
add_smalltext|`b/tall `w: Fast add All Locks to trade.|left|
add_smalltext|`b/tclear `w: Clear all locks from Trade window.|left|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|btn_trade|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

function UI.ShowTelephoneCommandsDialog()
    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9Telephone Commands List|left|]] .. UI.GetIcon("Telephone", 3898) .. [[|
add_spacer|small|
add_textbox|`wFast in-game commands for Telephone Auto-Buy:|left|
add_spacer|small|
add_smalltext|`b/telemenu `w: Open Telephone Menu directly.|left|
add_smalltext|`b/cvdl `w: Auto Convert DL to BGL.|left|
add_smalltext|`b/buybgl `w: Auto Buy Blue Gem Lock.|left|
add_smalltext|`b/buydl `w: Auto Buy Diamond Lock.|left|
add_smalltext|`b/buychamp `w: Auto Buy Champagne (Normal).|left|
add_smalltext|`b/buychampbg `w: Auto Buy Champagne (Black Gems).|left|
add_smalltext|`b/buychampbulk `w: Auto Buy Bulk Champagne.|left|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|btn_telephone|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

function UI.ShowEmojiCommandsDialog()
    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9Emoji & Color Commands List|left|]] .. UI.GetIcon("Happy Block", 5776) .. [[|
add_spacer|small|
add_textbox|`wFast in-game commands for Customization:|left|
add_spacer|small|
add_smalltext|`b/emojimenu `w: Open Emoji Menu directly.|left|
add_smalltext|`b/emoji `w: Toggle Random Chat Emojis.|left|
add_smalltext|`b/watermark `w: Toggle Chat Watermark.|left|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|btn_toggle_emoji|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

function UI.ShowCalculatorCommandsDialog()
    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9Calculator Commands List|left|]] .. UI.GetIcon("Compu Panel", 1164) .. [[|
add_spacer|small|
add_textbox|`wFast in-game commands for Smart Calculator:|left|
add_spacer|small|
add_smalltext|`b/calcmenu `w: Open Calculator Menu directly.|left|
add_smalltext|`b/calc <form> `w: Calculate math instantly.|left|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|btn_calc|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

function UI.ShowSpamCommandsDialog()
    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9Auto-Spam Commands List|left|]] .. UI.GetIcon("Spammer Slave", 16990) .. [[|
add_spacer|small|
add_textbox|`wFast in-game commands for Auto-Spam:|left|
add_spacer|small|
add_smalltext|`b/spammenu `w: Open the Spam UI Menu directly.|left|
add_smalltext|`b/spam `w: Toggle Auto-Spam on/off.|left|
add_smalltext|`b/addspam <txt> `w: Add a new spam message.|left|
add_smalltext|`b/removespam `w: Remove the last spam message.|left|
add_smalltext|`b/spamtext <num> <txt> `w: Edit specific spam line.|left|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|btn_spam|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

function UI.ShowSBCommandsDialog()
    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9SB & SDB Commands List|left|]] .. UI.GetIcon("Megaphone", 2480) .. [[|
add_spacer|small|
add_textbox|`wFast in-game commands for Super Broadcast:|left|
add_spacer|small|
add_smalltext|`b/sbmenu `w: Open SB & SDB Menu directly.|left|
add_smalltext|`b/sbstart `w: Start Super Broadcast.|left|
add_smalltext|`b/sbstop `w: Stop Super Broadcast.|left|
add_smalltext|`b/sdbstart `w: Start Super Duper Broadcast.|left|
add_smalltext|`b/sdbstop `w: Stop Super Duper Broadcast.|left|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|btn_sbsbd|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

function UI.ShowCasinoCommandsDialog()
    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9Casino Commands List|left|]] .. UI.GetIcon("Roulette Wheel", 758) .. [[|
add_spacer|small|
add_textbox|`wFast in-game commands for Casino Modes:|left|
add_spacer|small|
add_smalltext|`b/casinomenu `w: Open Casino Menu directly.|left|
add_smalltext|`b/allmode `w: Toggle All (Reme, Leme, Qeme) mode.|left|
add_smalltext|`b/reme `w: Toggle Reme calculator mode.|left|
add_smalltext|`b/qeme `w: Toggle Qeme calculator mode.|left|
add_smalltext|`b/leme `w: Toggle Leme calculator mode.|left|
add_smalltext|`b/lemes `w: Toggle Leme S calculator mode.|left|
add_smalltext|`b/ceme `w: Toggle Ceme calculator mode.|left|
add_smalltext|`b/lewa <num> `w: Set Lewa multiplier & Enable.|left|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|btn_gambling|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

function UI.ShowAutoPullCommandsDialog()
    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9Auto Pull Commands List|left|]] .. UI.GetIcon("Shocking Wrench Decoration", 14822) .. [[|
add_spacer|small|
add_textbox|`wFast in-game commands for Auto Pull:|left|
add_spacer|small|
add_smalltext|`b/autopullmenu `w: Open Auto Pull Menu directly.|left|
add_smalltext|`b/autopull `w: Toggle Auto Pull Master.|left|
add_smalltext|`b/posautopull `w: Set Auto Pull target to your tile.|left|
add_smalltext|`b/clearposautopull `w: Reset target back to White Door.|left|
add_smalltext|`b/apblacklist add <uid> `w: Add UID to blacklist.|left|
add_smalltext|`b/apblacklist remove <uid> `w: Remove UID from blacklist.|left|
add_smalltext|`b/apblacklist list `w: Show current blacklist in chat.|left|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|btn_autopull_settings|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

function UI.ShowLogsCommandsDialog()
    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9Logs Commands List|left|]] .. UI.GetIcon("Security Camera", 1436) .. [[|
add_spacer|small|
add_textbox|`wFast in-game commands for Logs & History:|left|
add_spacer|small|
add_smalltext|`b/logsmenu `w: Open main Logs Menu Dialog.|left|
add_smalltext|`b/logs `w: Toggle activity logging on/off.|left|
add_smalltext|`b/clogs `w: Open Collect Logs directly.|left|
add_smalltext|`b/dlogs `w: Open Drop Logs directly.|left|
add_smalltext|`b/invlogs `w: Open Inventory Logs directly.|left|
add_smalltext|`b/slogs `w: Open Casino/Spin Logs directly.|left|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|btn_logs|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

-- ==========================================
-- DIALOG : General
-- ==========================================

function UI.ShowGeneralDialog()
    local apTxt   = UI.AntiPickup and "`2ON" or "`4OFF"
    local mfTxt   = UI.Modfly and "`2ON" or "`4OFF"
    local pTxt    = UI.AntiPortal and "`2ON" or "`4OFF"
    local nvTxt   = UI.NightVision and "`2ON" or "`4OFF"
    local bsdbTxt = UI.BlockSDB   and "`2ON" or "`4OFF"
    local cvTxt   = UI.AutoCVLocks and "`2ON" or "`4OFF"
    local tpTxt   = UI.TPDisplay  and "`2ON" or "`4OFF"
    local fdTxt   = UI.FastDrop   and "`2ON" or "`4OFF"
    local ftTxt   = UI.FastTrash  and "`2ON" or "`4OFF"
    local vfTxt   = UI.VendFilter and "`2ON" or "`4OFF"
    local dfTxt   = UI.DonationFilter and "`2ON" or "`4OFF"
    local sfTxt   = UI.StorageFilter and "`2ON" or "`4OFF"
    local alTxt   = UI.AntiLag and "`2ON" or "`4OFF"
    local hsTxt   = UI.HideSpammer and "`2ON" or "`4OFF"
    
    local fdOCTxt = UI.FastDropOnClick and "`2ON" or "`4OFF"
    local ftOCTxt = UI.FastTrashOnClick and "`2ON" or "`4OFF"

    local dialog = [[
add_label_with_icon|big|`9General Proxy Features|left|]] .. UI.GetIcon("Mini-Mod", 4758) .. [[|
add_spacer|small|
add_small_font_button|btn_cmd_general|`9List Command|noflags|0|0|
add_small_font_button|gen_toggle_antilag|Anti-Lag (Particle/Shadow): ]] .. alTxt .. [[|noflags|0|0|
add_small_font_button|gen_toggle_hidespam|Hide Spammer Slave: ]] .. hsTxt .. [[|noflags|0|0|
add_small_font_button|gen_toggle_ap|Anti-Pickup: ]] .. apTxt .. [[|noflags|0|0|
add_small_font_button|gen_toggle_mf|Modfly: ]] .. mfTxt .. [[|noflags|0|0|
add_small_font_button|gen_toggle_p|Anti Portal: ]] .. pTxt .. [[|noflags|0|0|
add_small_font_button|gen_toggle_nv|Night Vision: ]] .. nvTxt .. [[|noflags|0|0|
add_small_font_button|gen_toggle_bsdb|Block SDB Dialogs: ]] .. bsdbTxt .. [[|noflags|0|0|
add_small_font_button|gen_toggle_autocv|Auto CV Locks: ]] .. cvTxt .. [[|noflags|0|0|
add_small_font_button|gen_toggle_tp|Teleport Punch: ]] .. tpTxt .. [[|noflags|0|0|
add_small_font_button|gen_toggle_fd|Fast Drop: ]] .. fdTxt .. [[|noflags|0|0|
]]
    if UI.FastDrop or UI.FastTrash then
        if UI.FastDrop then
            dialog = dialog .. "add_small_font_button|gen_toggle_fdoc| `2> `0Fast Drop OnClick: " .. fdOCTxt .. "|noflags|0|0|\n"
        end
    end

    dialog = dialog .. [[
add_small_font_button|gen_toggle_ft|Fast Trash: ]] .. ftTxt .. [[|noflags|0|0|
]]
    if UI.FastDrop or UI.FastTrash then
        if UI.FastTrash then
            dialog = dialog .. "add_small_font_button|gen_toggle_ftoc| `2> `0Fast Trash OnClick: " .. ftOCTxt .. "|noflags|0|0|\n"
        end
    end

    dialog = dialog .. [[
add_small_font_button|gen_toggle_vf|Vend Filter: ]] .. vfTxt .. [[|noflags|0|0|
add_small_font_button|gen_toggle_df|Donation Box Filter: ]] .. dfTxt .. [[|noflags|0|0|
add_small_font_button|gen_toggle_sf|Storage Box Filter: ]] .. sfTxt .. [[|noflags|0|0|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : Wrench
-- ==========================================

function UI.ShowWrenchDialog()
    local l_off   = (UI.WrenchMode == 0) and "Off `2[ON]"   or "Off `4[OFF]"
    local l_pull  = (UI.WrenchMode == 1) and "Pull `2[ON]"  or "Pull `4[OFF]"
    local l_kick  = (UI.WrenchMode == 2) and "Kick `2[ON]"  or "Kick `4[OFF]"
    local l_ban   = (UI.WrenchMode == 3) and "Ban `2[ON]"   or "Ban `4[OFF]"
    local l_trade = (UI.WrenchMode == 4) and "Trade `2[ON]" or "Trade `4[OFF]"

    local lf_off   = (UI.WrenchMode == 0) and "staticYellowFrame" or "staticGreyFrame"
    local lf_pull  = (UI.WrenchMode == 1) and "staticYellowFrame" or "staticGreyFrame"
    local lf_kick  = (UI.WrenchMode == 2) and "staticYellowFrame" or "staticGreyFrame"
    local lf_ban   = (UI.WrenchMode == 3) and "staticYellowFrame" or "staticGreyFrame"
    local lf_trade = (UI.WrenchMode == 4) and "staticYellowFrame" or "staticGreyFrame"

    local r_off   = (UI.WrenchModeRight == 0) and "Off `2[ON]"   or "Off `4[OFF]"
    local r_pull  = (UI.WrenchModeRight == 1) and "Pull `2[ON]"  or "Pull `4[OFF]"
    local r_kick  = (UI.WrenchModeRight == 2) and "Kick `2[ON]"  or "Kick `4[OFF]"
    local r_ban   = (UI.WrenchModeRight == 3) and "Ban `2[ON]"   or "Ban `4[OFF]"
    local r_trade = (UI.WrenchModeRight == 4) and "Trade `2[ON]" or "Trade `4[OFF]"

    local rf_off   = (UI.WrenchModeRight == 0) and "staticYellowFrame" or "staticGreyFrame"
    local rf_pull  = (UI.WrenchModeRight == 1) and "staticYellowFrame" or "staticGreyFrame"
    local rf_kick  = (UI.WrenchModeRight == 2) and "staticYellowFrame" or "staticGreyFrame"
    local rf_ban   = (UI.WrenchModeRight == 3) and "staticYellowFrame" or "staticGreyFrame"
    local rf_trade = (UI.WrenchModeRight == 4) and "staticYellowFrame" or "staticGreyFrame"

    local sbTxt   = UI.ShowBal and "Show Balance `2[ON]" or "Show Balance `4[OFF]"
    local sbFrame = UI.ShowBal and "staticYellowFrame" or "staticGreyFrame"

    local dialog = [[
add_label_with_icon|big|`9Wrench Mode Settings|left|]] .. UI.GetIcon("Wrench", 15418) .. [[|
add_spacer|small|
add_small_font_button|btn_cmd_wrench|`9List Command|noflags|0|0|
add_button_with_icon|wrench_showbal|]] .. sbTxt .. [[|]] .. sbFrame .. [[|]] .. UI.GetIcon("Creativeps World Lock", 242) .. [[|
add_button_with_icon||END_LIST|noflags|0||
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|

add_smalltext|`wLeft Click Action (Main):|
add_button_with_icon|wrench_l_off|]] .. l_off .. [[|]] .. lf_off .. [[|]] .. UI.GetIcon("Constellation Wrench Style", 15678) .. [[|
add_button_with_icon|wrench_l_pull|]] .. l_pull .. [[|]] .. lf_pull .. [[|]] .. UI.GetIcon("Constellation Wrench Style", 15678) .. [[|
add_button_with_icon|wrench_l_kick|]] .. l_kick .. [[|]] .. lf_kick .. [[|]] .. UI.GetIcon("Constellation Wrench Style", 15678) .. [[|
add_button_with_icon|wrench_l_ban|]] .. l_ban .. [[|]] .. lf_ban .. [[|]] .. UI.GetIcon("Constellation Wrench Style", 15678) .. [[|
add_button_with_icon|wrench_l_trade|]] .. l_trade .. [[|]] .. lf_trade .. [[|]] .. UI.GetIcon("Constellation Wrench Style", 15678) .. [[|
add_button_with_icon||END_LIST|noflags|0||

add_smalltext|`wRight Click Action (Secondary):|
add_button_with_icon|wrench_r_off|]] .. r_off .. [[|]] .. rf_off .. [[|]] .. UI.GetIcon("Constellation Wrench Style", 15678) .. [[|
add_button_with_icon|wrench_r_pull|]] .. r_pull .. [[|]] .. rf_pull .. [[|]] .. UI.GetIcon("Constellation Wrench Style", 15678) .. [[|
add_button_with_icon|wrench_r_kick|]] .. r_kick .. [[|]] .. rf_kick .. [[|]] .. UI.GetIcon("Constellation Wrench Style", 15678) .. [[|
add_button_with_icon|wrench_r_ban|]] .. r_ban .. [[|]] .. rf_ban .. [[|]] .. UI.GetIcon("Constellation Wrench Style", 15678) .. [[|
add_button_with_icon|wrench_r_trade|]] .. r_trade .. [[|]] .. rf_trade .. [[|]] .. UI.GetIcon("Constellation Wrench Style", 15678) .. [[|
add_button_with_icon||END_LIST|noflags|0||
add_spacer|small|

add_smalltext|`wCustom Action Chat (Use {GrowID} for name):|
add_text_input|wrench_pull_txt|Pull:|]] .. UI.WrenchPullText .. [[|64|
add_text_input|wrench_kick_txt|Kick:|]] .. UI.WrenchKickText .. [[|64|
add_text_input|wrench_ban_txt|Ban:|]] .. UI.WrenchBanText .. [[|64|
add_spacer|small|
add_small_font_button|wrench_save_txt|`2Save Text|noflags|0|0|
add_spacer|small|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : Donate
-- ==========================================

function UI.ShowDonateDialog()
    local dModeTxt = UI.DonateMode and "`2ON" or "`4OFF"
    local statusTxt = "`4Not Set! Wrench a Box."
    if UI.DonateBoxX ~= 0 or UI.DonateBoxY ~= 0 then statusTxt = "`2X: " .. UI.DonateBoxX .. "  Y: " .. UI.DonateBoxY end
    local dialog = [[
add_label_with_icon|big|`9Smart Donation Mode|left|]] .. UI.GetIcon("Donation Box", 1452) .. [[|
add_spacer|small|
add_small_font_button|btn_cmd_donate|`9List Command|noflags|0|0|
add_button|btn_toggle_dmode|Donate Mode: ]] .. dModeTxt .. [[|noflags|0|0|
add_textbox|Box Status: ]] .. statusTxt .. [[|
add_text_input|don_amount|Amount:|1|5|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button_with_icon|btn_do_don_wl|Donate WL|noflags|]] .. UI.GetIcon("Creativeps World Lock", 242) .. [[|
add_button_with_icon|btn_do_don_dl|Donate DL|noflags|]] .. UI.GetIcon("Creativeps Diamond Lock", 1796) .. [[|
add_button_with_icon|btn_do_don_bgl|Donate BGL|noflags|]] .. UI.GetIcon("Creativeps Blue Gem Lock", 7188) .. [[|
add_button_with_icon|btn_do_don_blgl|Donate BlackGL|noflags|]] .. UI.GetIcon("Creativeps Black Gem Lock", 11550) .. [[|
add_button_with_icon||END_LIST|noflags|0|
add_small_font_button|btn_do_don_all|`2Put All Locks|noflags|0|0|
add_small_font_button|btn_do_don_takeall|`4Take All Items|noflags|0|0|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : Trade
-- ==========================================

function UI.ShowTradeDialog()
    local tModeTxt = (UI.WrenchMode == 4) and "`2ON" or "`4OFF"
    local statusTxt = "`4Not Trading! Wrench a Player."
    if UI.TradeTargetUID and UI.TradeTargetUID ~= 0 then
        statusTxt = "`2" .. UI.TradeTargetName .. " `0(UID: `2" .. UI.TradeTargetUID .. "`0)"
    end

    local dialog = [[
add_label_with_icon|big|`9Advanced Trading Mode|left|]] .. UI.GetIcon("Creativeps World Lock", 242) .. [[|
add_spacer|small|
add_small_font_button|btn_cmd_trade|`9List Command|noflags|0|0|
add_button|btn_toggle_tmode|Trade Mode: ]] .. tModeTxt .. [[|noflags|0|0|
add_textbox|Trade Status: ]] .. statusTxt .. [[|
add_textbox|`wFast Add Currency:|
add_text_input|trade_amount|Amount:|1|5|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button_with_icon|btn_trade_add_wl|Add WL|noflags|]] .. UI.GetIcon("Creativeps World Lock", 242) .. [[|
add_button_with_icon|btn_trade_add_dl|Add DL|noflags|]] .. UI.GetIcon("Creativeps Diamond Lock", 1796) .. [[|
add_button_with_icon|btn_trade_add_bgl|Add BGL|noflags|]] .. UI.GetIcon("Creativeps Blue Gem Lock", 7188) .. [[|
add_button_with_icon|btn_trade_add_blgl|Add BlackGL|noflags|]] .. UI.GetIcon("Creativeps Black Gem Lock", 11550) .. [[|
add_button_with_icon||END_LIST|noflags|0|
add_small_font_button|btn_trade_add_all|`2Put All Locks|noflags|0|0|
add_small_font_button|btn_trade_clear|`4Clear Locks|noflags|0|0|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : Telephone
-- ==========================================

function UI.ShowTelephoneDialog()
    local mode1 = (UI.TeleMode == 1) and "`2[ON]" or "`4[OFF]"
    local mode2 = (UI.TeleMode == 2) and "`2[ON]" or "`4[OFF]"
    local mode3 = (UI.TeleMode == 3) and "`2[ON]" or "`4[OFF]"
    local mode4 = (UI.TeleMode == 4) and "`2[ON]" or "`4[OFF]"
    local mode5 = (UI.TeleMode == 5) and "`2[ON]" or "`4[OFF]"
    local mode6 = (UI.TeleMode == 6) and "`2[ON]" or "`4[OFF]"

    local frame1 = (UI.TeleMode == 1) and "staticYellowFrame" or "staticGreyFrame"
    local frame2 = (UI.TeleMode == 2) and "staticYellowFrame" or "staticGreyFrame"
    local frame3 = (UI.TeleMode == 3) and "staticYellowFrame" or "staticGreyFrame"
    local frame4 = (UI.TeleMode == 4) and "staticYellowFrame" or "staticGreyFrame"
    local frame5 = (UI.TeleMode == 5) and "staticYellowFrame" or "staticGreyFrame"
    local frame6 = (UI.TeleMode == 6) and "staticYellowFrame" or "staticGreyFrame"

    local dialog = [[
add_label_with_icon|big|`9Telephone Auto-Buy|left|]] .. UI.GetIcon("Telephone", 3898) .. [[|
add_spacer|small|
add_small_font_button|btn_cmd_tele|`9List Command|noflags|0|0|
add_textbox|`wSelect an action below and punch a Telephone!|

add_smalltext|`wLocks & Conversion:|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button_with_icon|tele_set_buydl|Buy DL ]] .. mode1 .. [[|]] .. frame1 .. [[|]] .. UI.GetIcon("Creativeps Diamond Lock", 1796) .. [[|
add_button_with_icon|tele_set_buybgl|Buy BGL ]] .. mode2 .. [[|]] .. frame2 .. [[|]] .. UI.GetIcon("Creativeps Blue Gem Lock", 7188) .. [[|
add_button_with_icon|tele_set_cv|CV BGL ]] .. mode3 .. [[|]] .. frame3 .. [[|]] .. UI.GetIcon("Creativeps Blue Gem Lock", 7188) .. [[|
add_button_with_icon||END_LIST|noflags|0||
add_smalltext|`wChampagne Auto-Buy:|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button_with_icon|tele_set_buychamp|Normal ]] .. mode4 .. [[|]] .. frame4 .. [[|]] .. UI.GetIcon("Champagne", 16896) .. [[|
add_button_with_icon|tele_set_buychampbg|BGem ]] .. mode5 .. [[|]] .. frame5 .. [[|]] .. UI.GetIcon("Champagne", 16896) .. [[|
add_button_with_icon|tele_set_buychampbulk|Bulk ]] .. mode6 .. [[|]] .. frame6 .. [[|]] .. UI.GetIcon("`$`2Infinity Champagne", 16904) .. [[|
add_button_with_icon||END_LIST|noflags|0||

add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : Emoji & Color
-- ==========================================

function UI.ShowEmojiColorDialog()
    local colTxt = (UI.EnableColor and UI.ColorValues[UI.SelectedColorIdx] == "RANDOM") and "`2ON" or "`4OFF"
    local emTxt = (UI.EnableEmoji and UI.EmojiValues[UI.SelectedEmojiIdx] == "RANDOM") and "`2ON" or "`4OFF"
    local wmTxt = UI.WatermarkMode and "`2ON" or "`4OFF"
    local encTxt = UI.EncryptChat and "`2ON" or "`4OFF"
    local rbTxt = UI.RainbowSkin and "`2ON" or "`4OFF"
    local blTxt = UI.BlinkSkin and "`2ON" or "`4OFF"
    local rbFrame = UI.RainbowSkin and "staticYellowFrame" or "staticGreyFrame"
    local blFrame = UI.BlinkSkin and "staticYellowFrame" or "staticGreyFrame"

    local dialog = [[
add_label_with_icon|big|`9Emoji & Color Settings|left|]] .. UI.GetIcon("Happy Block", 1444) .. [[|
add_spacer|small|
add_small_font_button|btn_cmd_emoji|`9List Command|noflags|0|0|
add_textbox|`wInput Text Stuff (Colors, Emojis):|
add_small_font_button|btn_toggle_rcol|Random Text Color: ]] .. colTxt .. [[|noflags|0|0|
add_small_font_button|btn_toggle_remo|Random Chat Emojis: ]] .. emTxt .. [[|noflags|0|0|
add_small_font_button|btn_toggle_wm|Chat Watermark: ]] .. wmTxt .. [[|noflags|0|0|
add_small_font_button|btn_toggle_encrypt|Encrypt Chat: ]] .. encTxt .. [[|noflags|0|0|
add_spacer|small|
add_textbox|`wSkin Effects:|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button_with_icon|btn_toggle_rb|Rainbow: ]] .. rbTxt .. [[|]] .. rbFrame .. [[|]] .. UI.GetIcon("Kaleidoscopic Wallpaper", 5272) .. [[|
add_button_with_icon|btn_toggle_bl|Blink: ]] .. blTxt .. [[|]] .. blFrame .. [[|]] .. UI.GetIcon("Checker Wallpaper", 284) .. [[|
add_button_with_icon||END_LIST|noflags|0||
add_spacer|small|
add_textbox|`wSkin Color Presets:|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button_with_icon|skin_black|Black|staticGreyFrame|]] .. UI.GetIcon("Black Wallpaper", 1158) .. [[|
add_button_with_icon|skin_white|White|staticGreyFrame|]] .. UI.GetIcon("White Wallpaper", 1156) .. [[|
add_button_with_icon|skin_red|Red|staticGreyFrame|]] .. UI.GetIcon("Red Wallpaper", 558) .. [[|
add_button_with_icon|skin_yellow|Yellow|staticGreyFrame|]] .. UI.GetIcon("Yellow Wallpaper", 562) .. [[|
add_button_with_icon||END_LIST|noflags|0||
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button_with_icon|skin_green|Green|staticGreyFrame|]] .. UI.GetIcon("Green Wallpaper", 564) .. [[|
add_button_with_icon|skin_blue|Blue|staticGreyFrame|]] .. UI.GetIcon("Blue Wallpaper", 568) .. [[|
add_button_with_icon|skin_purple|Purple|staticGreyFrame|]] .. UI.GetIcon("Purple Wallpaper", 570) .. [[|
add_button_with_icon|skin_pink|Pink|staticGreyFrame|]] .. UI.GetIcon("Pastel Pink Wallpaper", 2496) .. [[|
add_button_with_icon||END_LIST|noflags|0||
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : Calculator
-- ==========================================

function UI.ShowCalculatorDialog()
    local historyStr = ""
    if #UI.CalcLogs > 0 then
        for i, log in ipairs(UI.CalcLogs) do historyStr = historyStr .. "add_smalltext|`8" .. i .. ". " .. log .. "|\n" end
    else 
        historyStr = "add_smalltext|`8No history available.|\n" 
    end
    local dialog = [[
add_label_with_icon|big|`9Smart Calculator|left|]] .. UI.GetIcon("Compu Panel", 1164) .. [[|
add_spacer|small|
add_small_font_button|btn_cmd_calc|`9List Command|noflags|0|0|
add_smalltext|`wEnter your math formula below: (/calc)|
add_smalltext|`oOperators: (+) Add, (-) Sub, (*) Mul, (/) Div, (%) Modulo|
add_text_input|calc_input|Formula:|]] .. UI.CalcInput .. [[|64|
add_small_font_button|btn_do_calc|`2Calculate|noflags|0|0|
add_smalltext|`wLatest Result: ]] .. UI.CalcResult .. [[|
add_spacer|small|
add_smalltext|`9Calculation History:|
]] .. historyStr .. [[
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : Item Database
-- ==========================================

function UI.ShowItemDBDialog()
    local resStr = ""
    if #UI.SearchItemResults > 0 then
        for i, item in ipairs(UI.SearchItemResults) do
            if i > 30 then
                resStr = resStr .. "add_smalltext|`8... and " .. (#UI.SearchItemResults - 30) .. " more.|\n"
                break
            end
            local properName = item.name:gsub("(%a)([%w_']*)", function(first, rest) return first:upper() .. rest:lower() end)
            resStr = resStr .. "add_label_with_icon|small|`w" .. properName .. " `0(ID: `2" .. item.id .. "`0)|left|" .. item.id .. "|\n"
        end
    else resStr = "add_smalltext|`4No items found or query empty.|\n" end
    local dialog = [[
add_label_with_icon|big|`9Item Database|left|]] .. UI.GetIcon("Growscan 9000", 6016) .. [[|
add_spacer|small|
add_text_input|input_search_item|Search:|]] .. UI.SearchItemInput .. [[|32|
add_spacer|small|
add_button|btn_do_search_item|`2Search Item|noflags|0|0|
add_textbox|`9Search Results:|
]] .. resStr .. [[
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : Auto Farm
-- ==========================================

function UI.ShowAutoFarmDialog()
    local dialog = [[
add_label_with_icon|big|`9Auto Farm Features|left|]] .. UI.GetIcon("Dumb Farmer", 7064) .. [[|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button_with_icon|btn_auto_ptht|`wAuto PTHT|staticYellowFrame|]] .. UI.GetIcon("Dumb Farmer", 7064) .. [[||
add_button_with_icon|btn_auto_provider|`wAuto Provider|staticYellowFrame|]] .. UI.GetIcon("Black Atm Machine", 17024) .. [[||
add_button_with_icon|btn_auto_pnb|`wAuto PNB|staticYellowFrame|]] .. UI.GetIcon("Dumb Builder", 7070) .. [[||
add_button_with_icon|btn_auto_rotasi|`wAuto Rotasi|staticYellowFrame|]] .. UI.GetIcon("Stack Of Gems Icon", 3524) .. [[||
add_button_with_icon|btn_auto_tax|`wAuto Tax|staticYellowFrame|]] .. UI.GetIcon("Creativeps Diamond Lock", 1796) .. [[||
add_button_with_icon||END_LIST|noflags|0||
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

function UI.ShowAutoPTHTDialog() UI.CreateDialog(GetSoonDialog("Auto PTHT Settings", 7064)) end
function UI.ShowAutoProviderDialog() UI.CreateDialog(GetSoonDialog("Auto Provider Settings", 17024)) end
function UI.ShowAutoPNBDialog() UI.CreateDialog(GetSoonDialog("Auto PNB Settings", 7070)) end
function UI.ShowAutoRotasiDialog() UI.CreateDialog(GetSoonDialog("Auto Rotasi Settings", 3524)) end
function UI.ShowAutoTaxDialog() UI.CreateDialog(GetSoonDialog("Auto Tax Settings", 1796)) end

-- ==========================================
-- DIALOG : Auto Cook
-- ==========================================

function UI.ShowAutoCookDialog() UI.CreateDialog(GetSoonDialog("Auto Cook Settings", 7076)) end


-- ==========================================
-- DIALOG : Auto Fish
-- ==========================================

function UI.ShowAutoFishDialog()
    local stateBtn = UI.AutoFish and "add_small_font_button|btn_toggle_fish|`4STOP AUTO FISH|noflags|0|0|\n" or "add_button|btn_toggle_fish|`2START AUTO FISH|noflags|0|0|\n"
    local statusColor = UI.AutoFish and "`2" or "`e"
    if UI.FishAction:find("Out of") or UI.FishAction:find("Stopping") then statusColor = "`4" end
    local dirTxt = (UI.FishDirIdx == 1) and "`2Facing Right" or "`2Facing Left"
    
    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9Auto Fishing|left|]] .. UI.GetIcon("Dumb Fisher", 7072) .. [[|
add_spacer|small|
add_textbox|`wStatus: ]] .. statusColor .. UI.FishAction .. [[|left|
]] .. stateBtn .. [[
add_smalltext|`wHow to use: Equip your Fishing Rod, face the water, select your direction below, and click Start!|
add_small_font_button|btn_toggle_fish_dir|Facing Direction: ]] .. dirTxt .. [[|noflags|0|0|
add_text_input|input_fish_bait|Bait Item ID:|]] .. UI.FishBaitID .. [[|6|
add_smalltext|`o(Common Baits: 2504 = Worm, 5528 = Mega Pelet, 2904 = Salmon)|
add_small_font_button|btn_save_fish|`2Save Settings|noflags|0|0|
add_spacer|small|
add_smalltext|`2Statistics:|
add_smalltext|`wTotal Casts : `0]] .. UI.FishStats.cast .. [[|left|
add_smalltext|`wFish Caught : `2]] .. UI.FishStats.caught .. [[|left|
add_smalltext|`wFish Missed : `4]] .. UI.FishStats.missed .. [[|left|
add_small_font_button|btn_reset_fish_stats|Reset Stats|noflags|0|0|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : Auto Surg
-- ==========================================

function UI.ShowAutoSurgDialog()
    local stateBtn = UI.AutoSurg and "add_button|btn_toggle_surg|`4STOP AUTO SURG|noflags|0|0|\n" or "add_button|btn_toggle_surg|`2START AUTO SURG|noflags|0|0|\n"
    local statusColor = UI.AutoSurg and "`2" or "`e"
    if UI.SurgAction:find("Malpractice") or UI.SurgAction:find("low!") or UI.SurgAction:find("Stopping") then statusColor = "`4" end
    
    local targetLine = ""
    if UI.SurgTarget then
        targetLine = "add_textbox|`wTarget: `2Player ID: `0" .. tostring(UI.SurgTarget) .. "|left|\n"
    end
    
    local abTxt = UI.SurgAutoBuy and "`2[ON]" or "`4[OFF]"
    local atTxt = UI.SurgAutoTrash and "`2[ON]" or "`4[OFF]"
    local amTxt = UI.SurgAutoModage and "`2[ON]" or "`4[OFF]"
    local lbTxt = UI.SurgUseLegalBrief and "`2[ON]" or "`4[OFF]"
    
    local totalSurg = UI.SurgStats.success + UI.SurgStats.fail
    local winRate = (totalSurg > 0) and math.floor((UI.SurgStats.success / totalSurg) * 100) or 0
    
    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9Auto Surgery (Smart AI)|left|]] .. UI.GetIcon("Dumb Surgeon", 7068) .. [[|
add_spacer|small|
add_textbox|`wStatus: ]] .. statusColor .. UI.SurgAction .. [[|left|
]] .. targetLine .. [[
]] .. stateBtn .. [[
add_smalltext|`wHow to use: Click Start, then Wrench a player to begin.|
add_small_font_button|btn_toggle_surg_autobuy|Enable Auto Buy Surg Kit: ]] .. abTxt .. [[|noflags|0|0|
add_text_input|input_surg_threshold|Min. Threshold:|]] .. UI.SurgCardThreshold .. [[|3|
add_smalltext|`oBot will automatically buy 'Surgical Kit' if any tool drops below ]] .. UI.SurgCardThreshold .. [[.|
add_small_font_button|btn_toggle_surg_autotrash|Auto Trash Excess Tools (>= 240): ]] .. atTxt .. [[|noflags|0|0|
add_small_font_button|btn_toggle_surg_modage|Auto Bypass Malpractice (For MVP+): ]] .. amTxt .. [[|noflags|0|0|
add_small_font_button|btn_toggle_surg_legalbrief|Use Legal Brief (For Non-MVP+): ]] .. lbTxt .. [[|noflags|0|0|
add_small_font_button|btn_save_surg|`2Save Settings|noflags|0|0|
add_spacer|small|
add_smalltext|`2Statistics:|
add_smalltext|`wSuccessful Surgeries : `2]] .. UI.SurgStats.success .. [[|left|
add_smalltext|`wFailed (Malpractice) : `4]] .. UI.SurgStats.fail .. [[|left|
add_smalltext|`wWin Rate Accuracy    : `b]] .. winRate .. [[%|left|
add_small_font_button|btn_reset_surg_stats|Reset Stats|noflags|0|0|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : Auto Crime
-- ==========================================

function UI.ShowAutoCrimeDialog()
    local stateBtn = UI.AutoCrime and "add_small_font_button|btn_toggle_crime|`4STOP AUTO CRIME|noflags|0|0|\n" or "add_button|btn_toggle_crime|`2START AUTO CRIME|noflags|0|0|\n"
    local statusColor = UI.AutoCrime and "`2" or "`e"
    if UI.CrimeAction:find("Error") or UI.CrimeAction:find("Lost") or UI.CrimeAction:find("Stopping") then statusColor = "`4" end
    
    local targetLine = ""
    if UI.CrimeTarget then
        targetLine = "add_textbox|`wTarget: `2" .. UI.CrimeTarget.name .. " `0@ (" .. UI.CrimeTarget.x .. ", " .. UI.CrimeTarget.y .. ")|left|\n"
    end
    
    local abcTxt = UI.AutoBuyCrimeCards and "`2[ON]" or "`4[OFF]"
    
    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9Auto Crime (CPS Optimized)|left|]] .. UI.GetIcon("Crime Wave", 2382) .. [[|
add_spacer|small|
add_textbox|`wStatus: ]] .. statusColor .. UI.CrimeAction .. [[|left|
]] .. targetLine .. [[
]] .. stateBtn .. [[
add_smalltext|`wHow to use: Click Scan Villains, then Start to auto-fight villains in world.|
add_small_font_button|btn_scan_crime|`eScan Villains|noflags|0|0|
add_small_font_button|btn_toggle_crime_autobuy|Enable Auto Buy Crime Cards: ]] .. abcTxt .. [[|noflags|0|0|
add_text_input|input_crime_threshold|Min. Threshold:|]] .. UI.CrimeCardThreshold .. [[|3|
add_smalltext|`oBot will automatically buy Crime Cards if any card drops below ]] .. UI.CrimeCardThreshold .. [[.|
add_small_font_button|btn_save_crime|`2Save Settings|noflags|0|0|
add_spacer|small|
add_smalltext|`2Statistics:|
add_smalltext|`wVillains Found in World : `2]] .. #UI.CrimeVillains .. [[ `wVillains|left|
add_small_font_button|btn_view_crime_villains|View Villains List|noflags|0|0|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : Auto Geiger
-- ==========================================

function UI.ShowAutoGeigerDialog() UI.CreateDialog(GetSoonDialog("Auto Geiger Settings", 2204)) end


-- ==========================================
-- DIALOG : Auto Buy Pack
-- ==========================================

function UI.ShowAutoBuyPackDialog()
    local statusText = UI.AutoBuyPack and "Running" or "Idle"
    local statusColor = UI.AutoBuyPack and "`2" or "`e"
    
    local currentPack = UI.ABP_Packs[UI.ABP_PackIdx]
    local packName = currentPack and currentPack.name or "`4None (Click Auto-Scan!)"
    local packPrice = (currentPack and currentPack.cost) and (" `o(" .. currentPack.cost .. " Gems)") or ""
    
    local scanBtnTxt = UI.ABP_IsScanningShop and "`4Scanning Shop..." or "`eAuto-Scan Shop Packs"
    local stateBtn = ""
    if #UI.ABP_Packs > 0 then
        stateBtn = UI.AutoBuyPack and "add_small_font_button|btn_toggle_abp|`4STOP AUTO BUY PACK|noflags|0|0|\n" or "add_button|btn_toggle_abp|`2START AUTO BUY PACK|noflags|0|0|\n"
    else
        stateBtn = "add_small_font_button|btn_scan_abp|`4START LOCKED (Please Auto-Scan first)|noflags|0|0|\n"
    end
    
    local boTxt = UI.ABP_BuyOnly and "`2[ON]" or "`4[OFF]"
    local bmTxt = UI.ABP_BatchMode and "`2[ON]" or "`4[OFF]"
    
    local dropCoordsBlock = ""
    if not UI.ABP_BuyOnly then
        dropCoordsBlock = [[
add_text_input|input_abp_dropx|Drop Base X:|]] .. UI.ABP_DropX .. [[|4|
add_text_input|input_abp_dropy|Drop Base Y:|]] .. UI.ABP_DropY .. [[|4|
add_smalltext|`oPack items will be automatically dropped side-by-side.|
]]
    end
    
    local packSelectBlock = ""
    if #UI.ABP_Packs > 0 then
        packSelectBlock = "add_small_font_button|btn_abp_select_menu|Select Pack From List|noflags|0|0|\n"
    end

    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9Auto Buy Pack (Smart Detect)|left|]] .. UI.GetIcon("Dumb G4g Crate Pack", 10868) .. [[|
add_spacer|small|
add_textbox|`wStatus: ]] .. statusColor .. statusText .. [[|left|
add_textbox|`wSelected Pack: `2]] .. packName .. packPrice .. [[|left|
]] .. stateBtn .. [[
add_small_font_button|btn_scan_abp|]] .. scanBtnTxt .. [[|noflags|0|0|
]] .. packSelectBlock .. [[
add_text_input|input_abp_amount|Amount to Buy (0=Inf):|]] .. UI.ABP_BuyAmount .. [[|5|
add_small_font_button|btn_toggle_abp_only|Buy Only (Do Not Drop): ]] .. boTxt .. [[|noflags|0|0|
add_small_font_button|btn_toggle_abp_batch|Batch Mode (Buy till full, then Drop): ]] .. bmTxt .. [[|noflags|0|0|
]] .. dropCoordsBlock .. [[
add_small_font_button|btn_save_abp|`2Save Settings|noflags|0|0|
add_spacer|small|
add_smalltext|`2Statistics:|
add_smalltext|`wTotal Packs Loaded : `2]] .. #UI.ABP_Packs .. [[ `wItems|left|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

function UI.ShowABPPackListDialog()
    local listStr = ""
    for i, p in ipairs(UI.ABP_Packs) do
        local isSel = (i == UI.ABP_PackIdx) and "`2[Selected] " or ""
        local costStr = p.cost and (" `o(" .. p.cost .. " Gems)") or ""
        listStr = listStr .. "add_small_font_button|abp_sel_" .. i .. "|" .. isSel .. p.name .. costStr .. "|noflags|0|0|\n"
    end
    
    if #UI.ABP_Packs == 0 then
        listStr = "add_smalltext|`4No packs found. Please click 'Auto-Scan Shop Packs' first!|\n"
    end
    
    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9Select Pack (Total: ]] .. #UI.ABP_Packs .. [[)|left|]] .. UI.GetIcon("Dumb G4g Crate Pack", 10868) .. [[|
add_spacer|small|
add_smalltext|`wClick any pack below to select it:|
add_spacer|small|
]] .. listStr .. [[
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|btn_abp_back|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : Casino
-- ==========================================

function UI.ShowCasinoDialog()
    local rTxt  = (UI.CasinoMode == 1) and "`2Reme: ON"   or "`4Reme: OFF"
    local qTxt  = (UI.CasinoMode == 2) and "`2Qeme: ON"   or "`4Qeme: OFF"
    local lTxt  = (UI.CasinoMode == 3) and "`2Leme: ON"   or "`4Leme: OFF"
    local lsTxt = (UI.CasinoMode == 4) and "`2Leme S: ON" or "`4Leme S: OFF"
    local cTxt  = (UI.CasinoMode == 5) and "`2Ceme: ON"   or "`4Ceme: OFF"
    local allTxt= (UI.CasinoMode == 7) and "`2All (R/L/Q): ON" or "`4All (R/L/Q): OFF"
    local lwTxt = (UI.CasinoMode == 6) and "`2Lewa: ON"   or "`4Lewa: OFF"
    local dialog = [[
add_label_with_icon|big|`9Casino Modes|left|]] .. UI.GetIcon("Roulette Wheel", 758) .. [[|
add_spacer|small|
add_small_font_button|btn_cmd_casino|`9List Command|noflags|0|0|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button_with_icon|cas_all|]] .. allTxt .. [[|staticYellowFrame|]] .. UI.GetIcon("Roulette Wheel", 758) .. [[|
add_button_with_icon|cas_reme|]] .. rTxt .. [[|staticYellowFrame|]] .. UI.GetIcon("Roulette Wheel", 758) .. [[|
add_button_with_icon|cas_qeme|]] .. qTxt .. [[|staticYellowFrame|]] .. UI.GetIcon("Roulette Wheel", 758) .. [[|
add_button_with_icon|cas_leme|]] .. lTxt .. [[|staticYellowFrame|]] .. UI.GetIcon("Roulette Wheel", 758) .. [[|
add_button_with_icon|cas_lemes|]] .. lsTxt .. [[|staticYellowFrame|]] .. UI.GetIcon("Roulette Wheel", 758) .. [[|
add_button_with_icon|cas_ceme|]] .. cTxt .. [[|staticYellowFrame|]] .. UI.GetIcon("Roulette Wheel", 758) .. [[|
add_button_with_icon|cas_lewa|]] .. lwTxt .. [[|staticYellowFrame|]] .. UI.GetIcon("Roulette Wheel", 758) .. [[|
add_button_with_icon||END_LIST|noflags|0||
add_text_input|input_lewa|Lewa Multiplier:|]] .. UI.CasinoLewaMulti .. [[|3|
add_small_font_button|btn_save_lewa|`2Save Lewa|
add_spacer|small|
add_label_with_icon|small|`9Result Format:|left|]] .. UI.GetIcon("Compu Panel", 1164) .. [[|
add_button_with_icon|cas_fmt_1|]] .. ((UI.CasinoFormatIdx == 1) and "`2[Result] (Ori)" or "`4[Result] (Ori)") .. [[|staticYellowFrame|]] .. UI.GetIcon("Compu Panel", 1164) .. [[|
add_button_with_icon|cas_fmt_2|]] .. ((UI.CasinoFormatIdx == 2) and "`2(Ori) [Result]" or "`4(Ori) [Result]") .. [[|staticYellowFrame|]] .. UI.GetIcon("Compu Panel", 1164) .. [[|
add_button_with_icon||END_LIST|noflags|0||
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : BTK/BJ
-- ==========================================

function UI.ShowBTKBJDialog()
    local modeColor = (UI.BTK_Mode == "BJ") and "`eBlackjack 21" or "`2BTK (Most Gems)"
    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9BTK / BJ Control Panel|left|]] .. UI.GetIcon("Chandelier", 340) .. [[|
add_spacer|small|
add_small_font_button|btn_btk_cmd_list|`9List Command|noflags|0|0|
add_textbox|`wDue to the setup complexity, we recommend using the `2ImGui Panel (/imgui) `wor fast `9In-Game Chat Commands `wfor the best experience.|left|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_spacer|small|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

function UI.ShowBTKCommandsDialog()
    local dialog = [[
set_default_color|`o
add_label_with_icon|big|`9BTK & BJ Commands List|left|]] .. UI.GetIcon("Chandelier", 340) .. [[|
add_spacer|small|
add_textbox|`wFast in-game commands for BTK & BJ host gameplay:|left|
add_spacer|small|
add_smalltext|`2Menu & Mode Switching:|
add_smalltext|`b/btkmenu `4or `b/bjmenu `w: Open Host Dialog Panel|left|
add_smalltext|`b/btkcmd `4or `b/bjcmd `w: Show this Command List|left|
add_smalltext|`b/btk `w: Switch to BTK Mode (Most Gems)|left|
add_smalltext|`b/bj `w: Switch to BJ Mode (Blackjack 21)|left|
add_spacer|small|
add_smalltext|`2Game Round Actions:|
add_smalltext|`b/btkremote `4or `b/bjremote `w: Collect Remote from Magplant|left|
add_smalltext|`b/btkbet `4or `b/bjbet `w: Take Bets & Calculate 5% Tax|left|
add_smalltext|`b/btkgems `4or `b/bjgems `w: Check Gems & Announce Winner|left|
add_smalltext|`b/btkdrop `4or `b/bjdrop `w: Drop Prize, Tax & Reset Round|left|
add_spacer|small|
add_smalltext|`2Coordinate Setup (Touch / Punch tile to set):|
add_smalltext|`b/btkcenter `4or `b/bjcenter `w: Set Host Center tile|left|
add_smalltext|`b/btkposbet1 `4or `b/bjposbet1 `w: Set Bet Player 1 tile|left|
add_smalltext|`b/btkposbet2 `4or `b/bjposbet2 `w: Set Bet Player 2 tile|left|
add_smalltext|`b/btkposbreak1 `4or `b/bjposbreak1 `w: Set Break Player 1 tile|left|
add_smalltext|`b/btkposbreak2 `4or `b/bjposbreak2 `w: Set Break Player 2 tile|left|
add_smalltext|`b/btktax `4or `b/bjtax `w: Set Tax Drop tile|left|
add_smalltext|`b/btkmag `4or `b/bjmag `w: Set Magplant tile|left|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|btn_btkbj|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : Auto Pull
-- ==========================================

function UI.ShowAutoPullDialog()
    local apState = UI.AutoPull and "`2[ON]" or "`4[OFF]"
    local areaState = UI.AutoPullAreaScan and "`2[ON]" or "`4[OFF]"
    
    local cur_min = tonumber(UI.AutoPullMinModal) or 0
    local min_modal = (cur_min > 0) and tostring(cur_min) or ""
    local displayLabel = (cur_min > 0) and ("`2" .. min_modal .. " BGL `w(Active)") or "`4No Limit"

    local dialog = [[
add_label_with_icon|big|`9Auto Pull Settings|left|]] .. UI.GetIcon("Shocking Wrench Decoration", 14822) .. [[|
add_spacer|small|
add_small_font_button|btn_cmd_autopull|`9List Command|noflags|0|0|
add_button|apt_master_toggle|Auto Pull (OnSpawn): ]] .. apState .. [[|noflags|0|0|
add_button|apt_area_toggle|Area Scan Mode: ]] .. areaState .. [[|noflags|0|0|
add_spacer|small|
add_textbox|`wCurrent Min Modal: ]] .. displayLabel .. [[|left|
add_text_input|apt_min_modal_input|Min Modal (BGL):|]] .. min_modal .. [[|5|
add_spacer|small|
add_small_font_button|btn_apt_pos_menu|`2Manage Pos Autopull|noflags|0|0|
add_small_font_button|btn_apt_blacklist_menu|`4Manage Blacklist|noflags|0|0|
add_spacer|small|
add_small_font_button|btn_apt_save_all|`2Save Configuration|noflags|0|0|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

function UI.ShowAPTPositionsDialog()
    local positionsListStr = ""
    for i = 1, 5 do
        local pos = UI.AutoPullPos[i]
        local statusStr = "`4Not Set"
        if type(pos) == "table" and (pos.x > 0 or pos.y > 0) then
            statusStr = "`2(" .. pos.x .. ", " .. pos.y .. ")"
        end
        positionsListStr = positionsListStr .. "add_textbox|`9Pos " .. i .. " : " .. statusStr .. "|left|\n"
        positionsListStr = positionsListStr .. "add_small_font_button|btn_apt_mypos_" .. i .. "|`2Set My Pos " .. i .. "|noflags|0|0|\n"
        positionsListStr = positionsListStr .. "add_small_font_button|btn_apt_touch_" .. i .. "|`cTouch to Set " .. i .. "|noflags|0|0|\n"
        positionsListStr = positionsListStr .. "add_small_font_button|btn_apt_clear_" .. i .. "|`4Clear " .. i .. "|noflags|0|0|\n"
        positionsListStr = positionsListStr .. "add_spacer|small|\n"
    end

    local dialog = [[
add_label_with_icon|big|`9Manage Pos Autopull|left|]] .. UI.GetIcon("Shocking Wrench Decoration", 14822) .. [[|
add_spacer|small|
add_textbox|`wTarget Positions (Pos 1 - 5):|left|
add_spacer|small|
]] .. positionsListStr .. [[
add_button|btn_apt_reset_all_positions|`4RESET ALL 5 POSITIONS|noflags|0|0|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|btn_apt_back_main|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

function UI.ShowAPTBlacklistDialog()
    local playerList = GetPlayerList() or {}
    local lp = GetLocal()
    local lpUID = lp and lp.userid or 0
    local listStr = ""
    local playerCount = 0

    local sortedUIDs = {}
    for _, v in ipairs(UI.AutoPullBlacklist) do
        table.insert(sortedUIDs, v)
    end
    table.sort(sortedUIDs)
    
    local activeListStr = ""
    if #sortedUIDs == 0 then
        activeListStr = "add_textbox|`7No UIDs currently blacklisted.|left|\n"
    else
        activeListStr = "add_textbox|`2Total Blacklisted: `9" .. #sortedUIDs .. " UID(s)|left|\n"
        activeListStr = activeListStr .. "add_textbox|`eUIDs: `w" .. table.concat(sortedUIDs, "`7, `w") .. "|left|\n"
    end

    for _, player in pairs(playerList) do
        local uid = player.userid or player.netid or 0
        local name = player.name or "Unknown"
        
        local displayName = name:gsub("%[.-%]", "")
        displayName = displayName:gsub("%(.-%)", "")
        displayName = displayName:gsub("%s+", " "):match("^%s*(.-)%s*$") or "Unknown"
        local plainName = displayName:gsub("`.", "")
        
        if uid ~= 0 and uid ~= lpUID and not plainName:lower():find("spammer slave") then
            local checked = 0
            for _, blocked in ipairs(UI.AutoPullBlacklist) do
                if blocked == uid then checked = 1; break end
            end
            listStr = listStr .. "add_checkbox|apt_cb_" .. uid .. "|" .. displayName .. " `0(UID: `2" .. uid .. "`0)|" .. checked .. "|\n"
            playerCount = playerCount + 1
        end
    end

    if playerCount == 0 then listStr = "add_textbox|`9No other players in this world.|left|\n" end
    
    local dialog = [[
add_label_with_icon|big|`9Auto Pull Blacklist|left|]] .. UI.GetIcon("Black Wallpaper", 1158) .. [[|
add_spacer|small|
add_label_with_icon|small|`2Active Blacklist Status|left|]] .. UI.GetIcon("Black Wallpaper", 3210) .. [[|
]] .. activeListStr .. [[
add_spacer|small|
add_textbox|`wSelect players in world to block:|left|
]] .. listStr .. [[
add_spacer|small|
add_small_font_button|btn_apt_save|`2Save Checkbox|noflags|0|0|
add_small_font_button|btn_apt_select_all|Select All|noflags|0|0|
add_small_font_button|btn_apt_deselect_all|Deselect All|noflags|0|0|
add_spacer|small|
add_textbox|`wManual UID Input:|left|
add_text_input|apt_uid_input|UID:|0|8|
add_small_font_button|btn_apt_add|`2+ Add UID|noflags|0|0|
add_small_font_button|btn_apt_remove|`4- Remove UID|noflags|0|0|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|btn_apt_back_main|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : Auto Spam
-- ==========================================

function UI.ShowSpamDialog()
    local spamTxt = UI.SpamEnabled and "`2ON" or "`4OFF"
    local dialog = [[
add_label_with_icon|big|`9Auto-Spam Settings|left|]] .. UI.GetIcon("Spammer Slave", 16990) .. [[|
add_spacer|small|
add_small_font_button|btn_cmd_spam|`9List Command|noflags|0|0|
add_button|btn_toggle_spam|Auto-Spam: ]] .. spamTxt .. [[|noflags|0|0|
add_textbox|`wSpam Messages:|
]]
    for i = 1, #UI.SpamTexts do
        dialog = dialog .. "add_text_input|input_spam_" .. i .. "|Typer Text " .. i .. ":|" .. UI.SpamTexts[i] .. "|64|\n"
    end
    dialog = dialog .. [[
add_small_font_button|btn_add_spam_field|`2[+] Add Field|noflags|0|0|
]]
    if #UI.SpamTexts > 1 then 
        dialog = dialog .. "add_small_font_button|btn_rem_spam_field|`4[-] Remove Last|noflags|0|0|\n" 
    end
    dialog = dialog .. [[
add_text_input|input_spam_delay|Typer Delay (ms):|]] .. UI.SpamInterval .. [[|5|
add_small_font_button|btn_save_spam|`2Save Configuration|noflags|0|0|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : Auto SB & SBD
-- ==========================================

function UI.ShowSBDialog()
    local dialog = [[
add_label_with_icon|big|`9SB Settings|left|]] .. UI.GetIcon("Megaphone", 2480) .. [[|
add_spacer|small|
add_small_font_button|btn_cmd_sb|`9List Command|noflags|0|0|
add_label_with_icon|small|`9Super Broadcast (SB)|left|]] .. UI.GetIcon("Megaphone", 11230) .. [[|
add_text_input|input_sb_text|Text:|]] .. UI.SBText .. [[|64|
add_text_input|input_sb_amount|Amount:|]] .. UI.SBMax .. [[|5|
add_text_input|input_sb_done|Done World:|]] .. UI.SBDoneWorld .. [[|32|
add_button_with_icon|btn_start_sb|`2Start SB|staticYellowFrame|]] .. UI.GetIcon("Megaphone", 2480) .. [[|
add_button_with_icon|btn_stop_sb|`4Stop SB|staticYellowFrame|]] .. UI.GetIcon("Megaphone", 2480) .. [[|
add_button_with_icon||END_LIST|noflags|0|
add_spacer|small|
add_button|btn_save_sb_config|`2Save Configuration|noflags|0|0|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

function UI.ShowSDBDialog()
    local dialog = [[
add_label_with_icon|big|`9SDB Settings|left|]] .. UI.GetIcon("Megaphone", 2480) .. [[|
add_spacer|small|
add_label_with_icon|small|`9Super Duper Broadcast (SDB)|left|]] .. UI.GetIcon("Megaphone", 11230) .. [[|
add_text_input|input_sdb_l1|Line 1:|]] .. UI.SDBLine1 .. [[|64|
add_text_input|input_sdb_l2|Line 2:|]] .. UI.SDBLine2 .. [[|64|
add_text_input|input_sdb_l3|Line 3:|]] .. UI.SDBLine3 .. [[|64|
add_text_input|input_sdb_amount|Amount:|]] .. UI.SDBMax .. [[|5|
add_text_input|input_sdb_delay|Extra Delay (Mins):|]] .. UI.SDBExtraTimer .. [[|5|
add_button_with_icon|btn_start_sdb|`2Start SDB|staticYellowFrame|]] .. UI.GetIcon("Megaphone", 2480) .. [[|
add_button_with_icon|btn_stop_sdb|`4Stop SDB|staticYellowFrame|]] .. UI.GetIcon("Megaphone", 2480) .. [[|
add_button_with_icon||END_LIST|noflags|0|
add_spacer|small|
add_button|btn_save_sdb_config|`2Save Configuration|noflags|0|0|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : Mag & Vend
-- ==========================================

function UI.ShowMagplantDialog() UI.CreateDialog(GetSoonDialog("Magplant Settings", 5638)) end
function UI.ShowVendingDialog() UI.CreateDialog(GetSoonDialog("Vending Settings", 9268)) end


-- ==========================================
-- DIALOG : World
-- ==========================================

function UI.ShowWorldDialog() UI.CreateDialog(GetSoonDialog("World Settings", 6)) end


-- ==========================================
-- DIALOG : All Logs
-- ==========================================

function UI.ShowLogsMenuDialog()
    local logState = UI.LogsEnabled and "`2[ON]" or "`4[OFF]"
    local dialog = [[
add_label_with_icon|big|`9Activity Logs Menu|left|]] .. UI.GetIcon("Security Camera", 1436) .. [[|
add_spacer|small|
add_small_font_button|btn_cmd_logs|`9List Command|noflags|0|0|
add_button|btn_toggle_logs|Auto-Logging: ]] .. logState .. [[|noflags|0|0|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button_with_icon|btn_show_all_logs|`wAll Logs|staticYellowFrame|]] .. UI.GetIcon("Security Camera", 1436) .. [[||
add_button_with_icon|btn_show_casino_logs|`2Casino Logs|staticYellowFrame|]] .. UI.GetIcon("Roulette Wheel", 758) .. [[||
add_button_with_icon|btn_show_inv_logs|`eInventory Logs|staticYellowFrame|]] .. UI.GetIcon("Creativeps World Lock", 242) .. [[||
add_button_with_icon|btn_show_collect_logs|`^Collect Logs|staticYellowFrame|]] .. UI.GetIcon("CreativePS Black Gem Lock", 274) .. [[||
add_button_with_icon|btn_show_drop_logs|`4Drop Logs|staticYellowFrame|]] .. UI.GetIcon("CreativePS Black Gem Lock", 276) .. [[||
add_button_with_icon||END_LIST|noflags|0||
add_small_font_button|btn_clear_logs|`4Clear All Logs|noflags|0|0|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

function UI.ShowLogDetailDialog(title, logCategory, filterWord)
    local dialog = [[
add_label_with_icon|big|`9]] .. title .. [[|left|]] .. UI.GetIcon("Security Camera", 1436) .. [[|
add_spacer|small|
]]
    local logsFound = 0
    local sourceTable = UI.Logs[logCategory] or {}
    for i, logStr in ipairs(sourceTable) do
        if not filterWord or logStr:find(filterWord) then
            dialog = dialog .. "add_smalltext|" .. logStr .. "|\n"
            logsFound = logsFound + 1
        end
        if logsFound >= 45 then break end
    end
    if logsFound == 0 then dialog = dialog .. "add_textbox|`4No logs found in this category yet.|\n" end
    dialog = dialog .. [[
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|btn_logs_menu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end


-- ==========================================
-- DIALOG : Setting
-- ==========================================

function UI.ShowSettingDialog()
    local dialog = [[
add_label_with_icon|big|`9Core Proxy Settings|left|]] .. UI.GetIcon("Steampunk Sprocket", 3310) .. [[|
add_spacer|small|
add_label_with_icon|small|`9Configuration Management|left|]] .. UI.GetIcon("Steampunk Sprocket", 14418) .. [[|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_smalltext|`wSave your current toggles and modes to your local device.|
add_button_with_icon|btn_save_config|`2Save Config|staticYellowFrame|]] .. UI.GetIcon("Command - Move Down", 16076) .. [[|
add_button_with_icon|btn_load_config|`eReload Config|staticYellowFrame|]] .. UI.GetIcon("Command - Move Up", 16078) .. [[|
add_button_with_icon|btn_reset_config|`4Reset Config|staticYellowFrame|]] .. UI.GetIcon("Command - Pause", 16074) .. [[|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button_with_icon||END_LIST|noflags|0|
add_spacer|small|
text_scaling_string|jjjjjjjjjjjjjjjjjjjjjjjjjj|
add_button|menuu|Back|noflags|0|0|
end_dialog|close_ui|Close||
]]
    UI.CreateDialog(dialog)
end

-- ==========================================
-- DIALOG : Information
-- ==========================================

function UI.ShowInformationDialog()
    local dialog = [[
add_label_with_icon|big|`cInformation & Support Center|left|]] .. UI.GetIcon("Digital Sign", 11186) .. [[|
add_spacer|small|
add_smalltext|`5Developer Information|
add_textbox|`9Creator: `wWin|
add_textbox|`9Discord: `wwin.store|
add_spacer|small|
add_smalltext|`^Community & Support|
add_button|info_copy_wa|`2Copy WhatsApp Group Link|noflags|0|
add_button|info_copy_dc|`5Copy Discord Community Link|noflags|0|
add_spacer|small|
add_smalltext|`2Version Information|
add_textbox|`9Proxy Version: `w1.0|
add_textbox|`9Status: `wActive Development|
add_textbox|`8Support: Available via Discord or WhatsApp|
add_spacer|small|
add_button|menuu|Back|noflags|0|
end_dialog|info_dialog|Close|
]]
    UI.CreateDialog(dialog)
end

-- ==========================================
-- ROUTER : Dialog Actions
-- ==========================================

local DialogActions = {
    ["resetdefault"] = function(str) UI.DialogBg = nil; UI.DialogBorder = nil; UI.SaveConfig(true); UI.ChangeDialogColor() end,

    ["menuu"] = function(str) UI.ShowMainDialog() end,
    ["close_ui"] = function(str) UI.ShowMainDialog() end,
    ["cmdend"] = function(str) LogToConsole("`4[WinProxy]: `wMenu closed.") end,
    
    ["btn_cmd_general"] = function(str) UI.ShowGeneralCommandsDialog() end,
    ["btn_cmd_wrench"] = function(str) UI.ShowWrenchCommandsDialog() end,
    ["btn_cmd_donate"] = function(str) UI.ShowDonateCommandsDialog() end,
    ["btn_cmd_trade"] = function(str) UI.ShowTradeCommandsDialog() end,
    ["btn_cmd_tele"] = function(str) UI.ShowTelephoneCommandsDialog() end,
    ["btn_cmd_emoji"] = function(str) UI.ShowEmojiCommandsDialog() end,
    ["btn_cmd_calc"] = function(str) UI.ShowCalculatorCommandsDialog() end,
    ["btn_cmd_spam"] = function(str) UI.ShowSpamCommandsDialog() end,
    ["btn_cmd_sb"] = function(str) UI.ShowSBCommandsDialog() end,
    ["btn_cmd_casino"] = function(str) UI.ShowCasinoCommandsDialog() end,
    ["btn_cmd_autopull"] = function(str) UI.ShowAutoPullCommandsDialog() end,
    ["btn_cmd_logs"] = function(str) UI.ShowLogsCommandsDialog() end,
    ["btn_commands"] = function(str) UI.ShowCommandsDialog() end,
    ["btn_general"] = function(str) UI.ShowGeneralDialog() end,
    ["btn_autopull_settings"] = function(str) UI.ShowAutoPullDialog() end,
    ["btn_apt_pos_menu"] = function(str) UI.ShowAPTPositionsDialog() end,
    ["btn_apt_blacklist_menu"] = function(str) UI.ShowAPTBlacklistDialog() end,
    ["btn_apt_back_main"] = function(str) UI.ShowAutoPullDialog() end,
    ["apt_master_toggle"] = function(str) 
        UI.AutoPull = not UI.AutoPull; UI.SaveConfig(true); UI.ShowAutoPullDialog() 
    end,
    ["apt_area_toggle"] = function(str) 
        UI.AutoPullAreaScan = not UI.AutoPullAreaScan; 
        if UI.AutoPullAreaScan then UI.ManageAreaPullThread() end
        UI.SaveConfig(true); UI.ShowAutoPullDialog() 
    end,
    ["btn_apt_save_all"] = function(str)
        local target = "\n" .. str
        UI.AutoPull = target:match("\napt_master_active|1") and true or false
        local newAreaScan = target:match("\napt_area_scan|1") and true or false
        
        if newAreaScan and not UI.AutoPullAreaScan then
            UI.AutoPullAreaScan = true; UI.ManageAreaPullThread()
        else
            UI.AutoPullAreaScan = newAreaScan
        end

        local minValStr = target:match("\napt_min_modal_input|([^|\n\r]*)")
        if minValStr then UI.AutoPullMinModal = tonumber(minValStr:match("([%d%.]+)")) or 0 end
        
        UI.SaveConfig(true)
        UI.LocalChat("`c[WinProxy]: `2[APT] Settings saved successfully!")
        UI.ShowAutoPullDialog()
    end,
    
    ["btn_apt_reset_all_positions"] = function(str)
        for i = 1, 5 do UI.AutoPullPos[i] = {x=0, y=0} end
        UI.SaveConfig(true)
        UI.LocalChat("`c[WinProxy]: `4All 5 Auto Pull positions have been reset!")
        UI.ShowAPTPositionsDialog()
    end,
    
    ["btn_apt_set_my_pos"] = function(str)
        local lp = GetLocal()
        if lp and lp.pos and lp.pos.x and lp.pos.y then
            UI.AutoPullTileX = math.floor(lp.pos.x / 32)
            UI.AutoPullTileY = math.floor(lp.pos.y / 32)
            UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `2Target tile set to your position: (" .. UI.AutoPullTileX .. ", " .. UI.AutoPullTileY .. ")")
        end
        UI.ShowAutoPullDialog()
    end,
    
    ["btn_apt_set_door_pos"] = function(str)
        local dx, dy = UI.GetSpawnTile()
        if dx and dy then
            UI.AutoPullTileX, UI.AutoPullTileY = dx, dy
            UI.LocalChat("`c[WinProxy]: `2Target tile set to White Door: (" .. dx .. ", " .. dy .. ")")
        else
            UI.AutoPullTileX, UI.AutoPullTileY = 0, 0
            UI.LocalChat("`c[WinProxy]: `4White Door not found, set to Auto (0, 0)")
        end
        UI.SaveConfig(true); UI.ShowAutoPullDialog()
    end,

    ["btn_apt_save"] = function(str)
        local onlineUIDs = {}
        local pList = GetPlayerList() or {}
        for _, p in pairs(pList) do
            local u = p.userid or p.netid or 0
            if u ~= 0 then onlineUIDs[u] = true end
        end

        local newBlacklist = {}
        for _, existingUID in ipairs(UI.AutoPullBlacklist) do
            if not onlineUIDs[existingUID] then
                table.insert(newBlacklist, existingUID)
            end
        end
        for uidStr in str:gmatch("apt_cb_(%d+)%|1") do
            local uid = tonumber(uidStr)
            if uid then table.insert(newBlacklist, uid) end
        end

        UI.AutoPullBlacklist = newBlacklist
        UI.SaveConfig(true)
        UI.LocalChat("`c[WinProxy]: `9Blacklist updated (" .. #newBlacklist .. " UIDs).")
        UI.ShowAPTBlacklistDialog()
    end,

    ["btn_apt_select_all"] = function(str)
        local pList = GetPlayerList() or {}
        local lpUID = GetLocal() and GetLocal().userid or 0
        local newBlacklist = {}
        local onlineUIDs = {}
        for _, p in pairs(pList) do
            local u = p.userid or p.netid or 0
            if u ~= 0 then onlineUIDs[u] = true end
        end
        for _, existingUID in ipairs(UI.AutoPullBlacklist) do
            if not onlineUIDs[existingUID] then table.insert(newBlacklist, existingUID) end
        end
        for _, player in pairs(pList) do
            local uid = player.userid or player.netid or 0
            if uid ~= 0 and uid ~= lpUID then table.insert(newBlacklist, uid) end
        end

        UI.AutoPullBlacklist = newBlacklist; UI.SaveConfig(true)
        UI.LocalChat("`c[WinProxy]: `9All online players blacklisted.")
        UI.ShowAPTBlacklistDialog()
    end,

    ["btn_apt_deselect_all"] = function(str)
        local pList = GetPlayerList() or {}
        local onlineUIDs = {}
        for _, p in pairs(pList) do
            local u = p.userid or p.netid or 0
            if u ~= 0 then onlineUIDs[u] = true end
        end
        local newBlacklist = {}
        for _, existingUID in ipairs(UI.AutoPullBlacklist) do
            if not onlineUIDs[existingUID] then table.insert(newBlacklist, existingUID) end
        end

        UI.AutoPullBlacklist = newBlacklist; UI.SaveConfig(true)
        UI.ShowAPTBlacklistDialog()
    end,

    ["btn_apt_add"] = function(str)
        local uid = tonumber(str:match("apt_uid_input|([^|\n]*)"))
        if uid and uid > 0 then
            local found = false
            for _, v in ipairs(UI.AutoPullBlacklist) do if v == uid then found = true; break end end
            if not found then table.insert(UI.AutoPullBlacklist, uid); UI.SaveConfig(true) end
        end
        UI.ShowAPTBlacklistDialog()
    end,

    ["btn_apt_remove"] = function(str)
        local uid = tonumber(str:match("apt_uid_input|([^|\n]*)"))
        if uid and uid > 0 then
            local newList = {}
            for _, v in ipairs(UI.AutoPullBlacklist) do if v ~= uid then table.insert(newList, v) end end
            UI.AutoPullBlacklist = newList; UI.SaveConfig(true)
        end
        UI.ShowAPTBlacklistDialog()
    end,
    ["btn_wrench"] = function(str) UI.ShowWrenchDialog() end,
    ["btn_donate"] = function(str) UI.ShowDonateDialog() end,
    ["btn_trade"] = function(str) UI.ShowTradeDialog() end,
    ["btn_telephone"] = function(str) UI.ShowTelephoneDialog() end,
    ["btn_toggle_emoji"] = function(str) UI.ShowEmojiColorDialog() end,
    ["btn_calc"] = function(str) UI.ShowCalculatorDialog() end,
    ["btn_itemdb"] = function(str) UI.ShowItemDBDialog() end,
    
    ["btn_ptht"] = function(str) UI.CreateDialog(GetSoonDialog("Auto PTHT", 7064)) end,
    ["btn_pnb"] = function(str) UI.CreateDialog(GetSoonDialog("Auto PNB", 7070)) end,
    ["btn_auto_cook"] = function(str) UI.ShowAutoCookDialog() end,
    ["btn_auto_fish"] = function(str) UI.ShowAutoFishDialog() end,
    ["btn_auto_surg"] = function(str) UI.ShowAutoSurgDialog() end,
    ["btn_auto_geiger"] = function(str) UI.ShowAutoGeigerDialog() end,
    ["btn_auto_crime"] = function(str) UI.ShowAutoCrimeDialog() end,
    ["btn_afk"] = function(str) UI.CreateDialog(GetSoonDialog("AFK", 1000)) end,
    ["btn_spam"] = function(str) UI.ShowSpamDialog() end,
    ["btn_sb"] = function(str) UI.ShowSBDialog() end,
    ["btn_sbd"] = function(str) UI.ShowSDBDialog() end,
    
    ["btn_gambling"] = function(str) UI.ShowCasinoDialog() end,
    ["btn_btkbj"] = function(str) UI.ShowBTKBJDialog() end,
    ["btn_logs"] = function(str) UI.ShowLogsMenuDialog() end,
    ["btn_theme"] = function(str) UI.ChangeDialogColor() end,
    ["btn_auto_buypack"] = function(str) UI.ShowAutoBuyPackDialog() end,
    ["btn_mag"] = function(str) UI.CreateDialog(GetSoonDialog("Magplant Settings", 5638)) end,
    ["btn_vend"] = function(str) UI.CreateDialog(GetSoonDialog("Vending Settings", 2978)) end,
    ["btn_wtw"] = function(str) UI.CreateDialog(GetSoonDialog("WTW Settings", 10)) end,
    ["btn_world"] = function(str) UI.ShowWorldDialog() end,
    
    ["btn_setting"] = function(str) UI.ShowSettingDialog() end,
    ["btn_info"] = function(str) UI.ShowInformationDialog() end,

    ["gen_toggle_antilag"] = function(str) UI.ToggleAntiLag(); UI.ShowGeneralDialog() end,
    ["gen_toggle_hidespam"] = function(str) UI.ToggleHideSpammer(); UI.ShowGeneralDialog() end,
    ["gen_toggle_ap"] = function(str) UI.AntiPickup = not UI.AntiPickup; UI.SaveConfig(true); UI.ShowGeneralDialog() end,
        ["gen_toggle_mf"] = function(str) UI.Modfly = not UI.Modfly; pcall(function() ChangeValue("[C] Modfly", UI.Modfly) end); UI.SaveConfig(true); UI.ShowGeneralDialog() end,
        ["gen_toggle_p"] = function(str) UI.AntiPortal = not UI.AntiPortal; pcall(function() ChangeValue("[C] Anti portal", UI.AntiPortal) end); UI.SaveConfig(true); UI.ShowGeneralDialog() end,
        ["gen_toggle_nv"] = function(str) UI.NightVision = not UI.NightVision; pcall(function() ChangeValue("[C] Night vision", UI.NightVision) end); UI.SaveConfig(true); UI.ShowGeneralDialog() end,
    ["gen_toggle_bsdb"] = function(str) UI.BlockSDB = not UI.BlockSDB; UI.SaveConfig(true); UI.ShowGeneralDialog() end,
    ["gen_toggle_autocv"] = function(str) UI.AutoCVLocks = not UI.AutoCVLocks; UI.SaveConfig(true); UI.ShowGeneralDialog() end,
    ["gen_toggle_tp"] = function(str) UI.TPDisplay = not UI.TPDisplay; UI.SaveConfig(true); UI.ShowGeneralDialog() end,
    ["gen_toggle_fd"] = function(str) 
        UI.FastDrop = not UI.FastDrop
        if not UI.FastDrop then UI.FastDropOnClick = false end
        UI.ShowGeneralDialog() 
    end,
    ["gen_toggle_ft"] = function(str) 
        UI.FastTrash = not UI.FastTrash
        if not UI.FastTrash then UI.FastTrashOnClick = false end
        UI.ShowGeneralDialog() 
    end,
    ["gen_toggle_vf"] = function(str) UI.VendFilter = not UI.VendFilter; UI.SaveConfig(true); UI.ShowGeneralDialog() end,
    ["gen_toggle_df"] = function(str) UI.DonationFilter = not UI.DonationFilter; UI.SaveConfig(true); UI.ShowGeneralDialog() end,
    ["gen_toggle_sf"] = function(str) UI.StorageFilter = not UI.StorageFilter; UI.SaveConfig(true); UI.ShowGeneralDialog() end,
    ["gen_toggle_fdoc"] = function(str) 
        UI.FastDropOnClick = not UI.FastDropOnClick
        if UI.FastDropOnClick then 
            UI.FastTrashOnClick = false
            UI.ManageWarningThread()
            UI.ManageOnClickItemThread()
        end
        UI.SaveConfig(true)
        UI.ShowGeneralDialog() 
    end,
    ["gen_toggle_ftoc"] = function(str) 
        UI.FastTrashOnClick = not UI.FastTrashOnClick
        if UI.FastTrashOnClick then 
            UI.FastDropOnClick = false
            UI.ManageWarningThread()
            UI.ManageOnClickItemThread()
        end
        UI.SaveConfig(true)
        UI.ShowGeneralDialog() 
    end,

    ["btn_auto_ptht"] = function(str) UI.ShowAutoPTHTDialog() end,
    ["btn_auto_splice"] = function(str) UI.ShowAutoSpliceDialog() end,
    ["btn_auto_pnb"] = function(str) UI.ShowAutoPNBDialog() end,
    ["btn_auto_rotasi"] = function(str) UI.ShowAutoRotasiDialog() end,
    ["btn_auto_tax"] = function(str) UI.ShowAutoTaxDialog() end,

    ["wrench_save_txt"] = function(str)
        UI.WrenchPullText = str:match("wrench_pull_txt|([^|\n]*)") or ""
        UI.WrenchKickText = str:match("wrench_kick_txt|([^|\n]*)") or ""
        UI.WrenchBanText = str:match("wrench_ban_txt|([^|\n]*)") or ""
        UI.SaveConfig(true)
        UI.LocalChat("`c[WinProxy]: `9Wrench Custom Texts saved!")
        UI.ShowWrenchDialog()
    end,
    
    ["wrench_l_off"] = function(str) UI.ToggleWrench(0, false); UI.ShowWrenchDialog() end,
    ["wrench_l_pull"] = function(str) UI.ToggleWrench(1, false); UI.ShowWrenchDialog() end,
    ["wrench_l_kick"] = function(str) UI.ToggleWrench(2, false); UI.ShowWrenchDialog() end,
    ["wrench_l_ban"] = function(str) UI.ToggleWrench(3, false); UI.ShowWrenchDialog() end,
    ["wrench_l_trade"] = function(str) UI.ToggleWrench(4, false); UI.ShowWrenchDialog() end,

    ["wrench_r_off"] = function(str) UI.ToggleWrench(0, true); UI.ShowWrenchDialog() end,
    ["wrench_r_pull"] = function(str) UI.ToggleWrench(1, true); UI.ShowWrenchDialog() end,
    ["wrench_r_kick"] = function(str) UI.ToggleWrench(2, true); UI.ShowWrenchDialog() end,
    ["wrench_r_ban"] = function(str) UI.ToggleWrench(3, true); UI.ShowWrenchDialog() end,
    ["wrench_r_trade"] = function(str) UI.ToggleWrench(4, true); UI.ShowWrenchDialog() end,

    ["wrench_showbal"] = function(str) 
        UI.ShowBal = not UI.ShowBal
        UI.SaveConfig(true)
        UI.ShowWrenchDialog() 
    end,

    ["btn_toggle_dmode"] = function(str) 
        UI.DonateMode = not UI.DonateMode
        if not UI.DonateMode then UI.DonateBoxX = 0; UI.DonateBoxY = 0 end
        UI.SaveConfig(true); UI.ShowDonateDialog()
    end,
    ["btn_do_don_wl"] = function(str) local amt = tonumber(str:match("don_amount|(%d+)")) or 1; UI.DoDonate(UI.GetIcon("Creativeps World Lock", 242), amt); UI.ShowDonateDialog() end,
    ["btn_do_don_dl"] = function(str) local amt = tonumber(str:match("don_amount|(%d+)")) or 1; UI.DoDonate(UI.GetIcon("Creativeps Diamond Lock", 1796), amt); UI.ShowDonateDialog() end,
    ["btn_do_don_bgl"] = function(str) local amt = tonumber(str:match("don_amount|(%d+)")) or 1; UI.DoDonate(UI.GetIcon("Creativeps Blue Gem Lock", 7188), amt); UI.ShowDonateDialog() end,
    ["btn_do_don_blgl"] = function(str) local amt = tonumber(str:match("don_amount|(%d+)")) or 1; UI.DoDonate(UI.GetIcon("Creativeps Black Gem Lock", 11550), amt); UI.ShowDonateDialog() end,
    ["btn_do_don_all"] = function(str) UI.DonateAllLocks(); UI.ShowDonateDialog() end,
    ["btn_do_don_takeall"] = function(str)
        if UI.DonateMode and UI.DonateBoxX ~= 0 then
            SendPacket(2, "action|dialog_return\ndialog_name|donate_edit|\nx|"..UI.DonateBoxX.."|\ny|"..UI.DonateBoxY.."|\nbuttonClicked|withdrawall")
            UI.LocalChat("`c[WinProxy]: `9Retrieving all items from Donation Box...")
        else 
            UI.LocalChat("`c[WinProxy]: `4Please enable /dmode and set a box position first!") 
        end
        UI.ShowDonateDialog()
    end,

    ["btn_toggle_tmode"] = function(str)
        local amt = tonumber(str:match("trade_amount|(%d+)"))
        if amt then UI.TradeAddAmount = amt end
        UI.ToggleWrench(4)
        UI.ShowTradeDialog()
    end,
    ["btn_trade_add_wl"] = function(str) local amt = tonumber(str:match("trade_amount|(%d+)")) or 1; UI.FastTradeAdd(UI.GetIcon("Creativeps World Lock", 242), amt); UI.ShowTradeDialog() end,
    ["btn_trade_add_dl"] = function(str) local amt = tonumber(str:match("trade_amount|(%d+)")) or 1; UI.FastTradeAdd(UI.GetIcon("Creativeps Diamond Lock", 1796), amt); UI.ShowTradeDialog() end,
    ["btn_trade_add_bgl"] = function(str) local amt = tonumber(str:match("trade_amount|(%d+)")) or 1; UI.FastTradeAdd(UI.GetIcon("Creativeps Blue Gem Lock", 7188), amt); UI.ShowTradeDialog() end,
    ["btn_trade_add_blgl"] = function(str) local amt = tonumber(str:match("trade_amount|(%d+)")) or 1; UI.FastTradeAdd(UI.GetIcon("Creativeps Black Gem Lock", 11550), amt); UI.ShowTradeDialog() end,
    ["btn_trade_add_all"] = function(str) UI.TradeAllLocks(); UI.ShowTradeDialog() end,
    ["btn_trade_clear"] = function(str) UI.TradeClearLocks(); UI.ShowTradeDialog() end,

    ["tele_set_buydl"] = function(str)
        UI.TeleMode = (UI.TeleMode == 1) and 0 or 1
        UI.LocalChat(UI.TeleMode == 1 and "`c[WinProxy]: `9Wrench Telephone to Buy `cDL `9is now `2Enabled" or "`c[WinProxy]: `9Telephone Auto-Buy is now `4Disabled")
        UI.ShowTelephoneDialog()
    end,
    ["tele_set_buybgl"] = function(str)
        UI.TeleMode = (UI.TeleMode == 2) and 0 or 2
        UI.LocalChat(UI.TeleMode == 2 and "`c[WinProxy]: `9Wrench Telephone to Buy `eBGL `9is now `2Enabled" or "`c[WinProxy]: `9Telephone Auto-Buy is now `4Disabled")
        UI.ShowTelephoneDialog()
    end,
    ["tele_set_cv"] = function(str)
        UI.TeleMode = (UI.TeleMode == 3) and 0 or 3
        UI.LocalChat(UI.TeleMode == 3 and "`c[WinProxy]: `9Wrench Telephone to Change `cDL `9to `eBGL `9is now `2Enabled" or "`c[WinProxy]: `9Telephone Auto-Buy is now `4Disabled")
        UI.ShowTelephoneDialog()
    end,
    ["tele_set_buychamp"] = function(str)
        UI.TeleMode = (UI.TeleMode == 4) and 0 or 4
        UI.LocalChat(UI.TeleMode == 4 and "`c[WinProxy]: `9Wrench Telephone to Buy `2Champagne `9is now `2Enabled" or "`c[WinProxy]: `9Telephone Auto-Buy is now `4Disabled")
        UI.ShowTelephoneDialog()
    end,
    ["tele_set_buychampbg"] = function(str)
        UI.TeleMode = (UI.TeleMode == 5) and 0 or 5
        UI.LocalChat(UI.TeleMode == 5 and "`c[WinProxy]: `9Wrench Telephone to Buy `2Champ (Black Gems) `9is now `2Enabled" or "`c[WinProxy]: `9Telephone Auto-Buy is now `4Disabled")
        UI.ShowTelephoneDialog()
    end,
    ["tele_set_buychampbulk"] = function(str)
        UI.TeleMode = (UI.TeleMode == 6) and 0 or 6
        UI.LocalChat(UI.TeleMode == 6 and "`c[WinProxy]: `9Wrench Telephone to Buy `2Bulk Champagne `9is now `2Enabled" or "`c[WinProxy]: `9Telephone Auto-Buy is now `4Disabled")
        UI.ShowTelephoneDialog()
    end,

    ["cas_reme"] = function(str) UI.ToggleCasino(1); UI.ShowCasinoDialog() end,
    ["cas_qeme"] = function(str) UI.ToggleCasino(2); UI.ShowCasinoDialog() end,
    ["cas_leme"] = function(str) UI.ToggleCasino(3); UI.ShowCasinoDialog() end,
    ["cas_lemes"] = function(str) UI.ToggleCasino(4); UI.ShowCasinoDialog() end,
    ["cas_ceme"] = function(str) UI.ToggleCasino(5); UI.ShowCasinoDialog() end,
    ["cas_all"] = function(str) UI.ToggleCasino(7); UI.ShowCasinoDialog() end,
    ["cas_lewa"] = function(str) UI.ToggleCasino(6); UI.ShowCasinoDialog() end,
    ["cas_fmt_1"] = function(str) UI.CasinoFormatIdx = 1; UI.SaveConfig(true); UI.ShowCasinoDialog() end,
        ["cas_fmt_2"] = function(str) UI.CasinoFormatIdx = 2; UI.SaveConfig(true); UI.ShowCasinoDialog() end,
        ["btn_save_lewa"] = function(str)
        local val = str:match("input_lewa|(%d+)")
        if val then
            local num = tonumber(val)
            if num < 5 then num = 5 end
            if num > 7 then num = 7 end
            UI.CasinoLewaMulti = num; UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `9Lewa Multiplier saved to `2" .. num)
        end
        UI.ShowCasinoDialog()
    end,

    -- ==========================================
    -- ==========================================
    ["btn_btk_cmd_list"] = function(str) UI.ShowBTKCommandsDialog() end,
    ["btk_open_imgui"] = function(str)
        UI.ShowImGui = true
        UI.SaveConfig(true)
        UI.LocalChat("`c[WinProxy]: `9ImGui Menu is now `2OPEN")
    end,
    

    ["btn_do_calc"] = function(str)
        local val = str:match("calc_input|([^|\n]+)")
        if val then 
            UI.CalcInput = val
            UI.CalculateMath(val) 
        end
        UI.ShowCalculatorDialog()
    end,

    ["btn_toggle_fish"] = function(str)
        UI.AutoFish = not UI.AutoFish
        if UI.AutoFish then 
            UI.ManageAutoFishThread() 
        else 
            UI.FishAction = "Stopping..." 
        end
        UI.ShowAutoFishDialog()
    end,
    ["btn_toggle_fish_dir"] = function(str)
        UI.FishDirIdx = (UI.FishDirIdx == 1) and 2 or 1
        UI.SaveConfig(true)
        UI.ShowAutoFishDialog()
    end,
    ["btn_save_fish"] = function(str)
        local bait = tonumber(str:match("input_fish_bait|(%d+)"))
        if bait then 
            UI.FishBaitID = bait
            UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `9Bait Item ID saved to `2" .. bait) 
        end
        UI.ShowAutoFishDialog()
    end,
    ["btn_reset_fish_stats"] = function(str)
        UI.FishStats = { cast = 0, caught = 0, missed = 0 }
        UI.LocalChat("`c[WinProxy]: `9Fishing statistics reset.")
        UI.ShowAutoFishDialog()
    end,
    ["btn_toggle_surg"] = function(str)
        UI.AutoSurg = not UI.AutoSurg
        if UI.AutoSurg then 
            UI.ManageAutoSurgThread() 
        else 
            UI.IsSurging = false
            UI.SurgTarget = nil
            UI.SurgAction = "Stopping..." 
        end
        UI.ShowAutoSurgDialog()
    end,
    ["btn_toggle_surg_autobuy"] = function(str)
        UI.SurgAutoBuy = not UI.SurgAutoBuy
        UI.SaveConfig(true)
        UI.ShowAutoSurgDialog()
    end,
    ["btn_toggle_surg_autotrash"] = function(str)
        UI.SurgAutoTrash = not UI.SurgAutoTrash
        UI.SaveConfig(true)
        UI.ShowAutoSurgDialog()
    end,
    ["btn_toggle_surg_modage"] = function(str)
        UI.SurgAutoModage = not UI.SurgAutoModage
        if UI.SurgAutoModage then UI.SurgUseLegalBrief = false end
        UI.SaveConfig(true)
        UI.ShowAutoSurgDialog()
    end,
    ["btn_toggle_surg_legalbrief"] = function(str)
        UI.SurgUseLegalBrief = not UI.SurgUseLegalBrief
        if UI.SurgUseLegalBrief then UI.SurgAutoModage = false end
        UI.SaveConfig(true)
        UI.ShowAutoSurgDialog()
    end,
    ["btn_save_surg"] = function(str)
        local thr = tonumber(str:match("input_surg_threshold|(%d+)"))
        if thr then
            if thr < 1 then thr = 1 end
            UI.SurgCardThreshold = thr
            UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `9Surg Card Threshold saved to `2" .. thr)
        end
        UI.ShowAutoSurgDialog()
    end,
    ["btn_reset_surg_stats"] = function(str)
        UI.SurgStats = { success = 0, fail = 0 }
        UI.LocalChat("`c[WinProxy]: `9Surgery statistics reset.")
        UI.ShowAutoSurgDialog()
    end,
    ["btn_toggle_crime"] = function(str)
        UI.AutoCrime = not UI.AutoCrime
        if UI.AutoCrime then 
            UI.ManageAutoCrimeThread() 
        else 
            UI.IsFightingCrime = false
            UI.CrimeAction = "Stopping..." 
        end
        UI.ShowAutoCrimeDialog()
    end,
    ["btn_scan_crime"] = function(str) UI.ScanVillains(); UI.ShowAutoCrimeDialog() end,
    ["btn_toggle_crime_autobuy"] = function(str)
        UI.AutoBuyCrimeCards = not UI.AutoBuyCrimeCards
        UI.SaveConfig(true)
        UI.ShowAutoCrimeDialog()
    end,
    ["btn_save_crime"] = function(str)
        local thr = tonumber(str:match("input_crime_threshold|(%d+)"))
        if thr then
            if thr < 1 then thr = 1 end
            UI.CrimeCardThreshold = thr
            UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `9Crime Card Threshold saved to `2" .. thr)
        end
        UI.ShowAutoCrimeDialog()
    end,
    ["btn_view_crime_villains"] = function(str) UI.ShowCrimeVillainsDialog() end,
    ["btn_crime_back"] = function(str) UI.ShowAutoCrimeDialog() end,

    ["btn_auto_provider"] = function(str) UI.ShowAutoProviderDialog() end,

    ["btn_toggle_spam"] = function(str) UI.ToggleSpam(not UI.SpamEnabled); UI.ShowSpamDialog() end,
    ["btn_add_spam_field"] = function(str) 
        for i = 1, #UI.SpamTexts do
            local val = str:match("input_spam_" .. i .. "|([^|\n]*)")
            if val then UI.SpamTexts[i] = val end
        end
        table.insert(UI.SpamTexts, "")
        UI.ShowSpamDialog() 
    end,
    ["btn_rem_spam_field"] = function(str) 
        if #UI.SpamTexts > 1 then table.remove(UI.SpamTexts) end
        UI.ShowSpamDialog() 
    end,
    ["btn_save_spam"] = function(str)
        for i = 1, #UI.SpamTexts do
            local val = str:match("input_spam_" .. i .. "|([^|\n]*)")
            if val then UI.SpamTexts[i] = val end
        end
        local newInt = tonumber(str:match("input_spam_delay|(%d+)")) or 3000
        if newInt < 500 then newInt = 500 end
        UI.SpamInterval = newInt
        UI.LocalChat("`c[WinProxy]: `9Spam configuration saved!")
        UI.ShowSpamDialog()
    end,

    ["btn_start_sb"] = function(str) UI.SBEnabled = true; UI.SBStartTime = os.time(); UI.ManageSBThread(); UI.ShowSBDialog() end,
    ["btn_stop_sb"] = function(str) UI.SBEnabled = false; UI.LocalChat("`c[WinProxy]: `4STOPPING `0SUPER BROADCAST"); UI.ShowSBDialog() end,
    ["btn_start_sdb"] = function(str) UI.SDBEnabled = true; UI.ManageSDBThread(); UI.ShowSDBDialog() end,
    ["btn_stop_sdb"] = function(str) UI.SDBEnabled = false; UI.LocalChat("`c[WinProxy]: `4STOPPING `0SUPER DUPER BROADCAST"); UI.ShowSDBDialog() end,
    ["btn_save_sb_config"] = function(str)
        UI.SBText = str:match("input_sb_text|([^|\n]*)") or ""
        UI.SBMax = tonumber(str:match("input_sb_amount|(%d+)")) or 0
        UI.SBDoneWorld = str:match("input_sb_done|([^|\n]*)") or ""
        UI.SaveConfig(true)
        UI.LocalChat("`c[WinProxy]: `9SB Configuration saved!")
        UI.ShowSBDialog()
    end,
    ["btn_save_sdb_config"] = function(str)
        UI.SDBLine1 = str:match("input_sdb_l1|([^|\n]*)") or ""
        UI.SDBLine2 = str:match("input_sdb_l2|([^|\n]*)") or ""
        UI.SDBLine3 = str:match("input_sdb_l3|([^|\n]*)") or ""
        UI.SDBMax = tonumber(str:match("input_sdb_amount|(%d+)")) or 0
        UI.SDBExtraTimer = tonumber(str:match("input_sdb_delay|(%d+)")) or 0
        UI.SDBTotalDelay = 5 + UI.SDBExtraTimer
        UI.SaveConfig(true)
        UI.LocalChat("`c[WinProxy]: `9SDB Configuration saved!")
        UI.ShowSDBDialog()
    end,


    ["btn_toggle_rcol"] = function() 
        if UI.EnableColor and UI.ColorValues[UI.SelectedColorIdx] == "RANDOM" then UI.EnableColor = false else UI.EnableColor = true; UI.SelectedColorIdx = 2 end
        UI.SaveConfig(true); UI.ShowEmojiColorDialog() 
    end,
    ["btn_toggle_remo"] = function() 
        if UI.EnableEmoji and UI.EmojiValues[UI.SelectedEmojiIdx] == "RANDOM" then UI.EnableEmoji = false else UI.EnableEmoji = true; UI.SelectedEmojiIdx = 2 end
        UI.SaveConfig(true); UI.ShowEmojiColorDialog() 
    end,
    ["btn_toggle_wm"] = function() UI.WatermarkMode = not UI.WatermarkMode; UI.SaveConfig(true); UI.ShowEmojiColorDialog() end,
    ["btn_toggle_encrypt"] = function() UI.EncryptChat = not UI.EncryptChat; UI.SaveConfig(true); UI.ShowEmojiColorDialog() end,
    ["btn_toggle_rb"] = function() UI.RainbowSkin = not UI.RainbowSkin; if UI.RainbowSkin then UI.ManageSkinEffects() end; UI.SaveConfig(true); UI.ShowEmojiColorDialog() end,
    ["btn_toggle_bl"] = function() UI.BlinkSkin = not UI.BlinkSkin; if UI.BlinkSkin then UI.ManageSkinEffects() end; UI.SaveConfig(true); UI.ShowEmojiColorDialog() end,
    ["skin_black"] = function() UI.RainbowSkin = false; UI.BlinkSkin = false; UI.SetSkinColor(0.0, 0.0, 0.0, 1.0); UI.LocalChat("`c[WinProxy]: `9Skin changed to `bBlack"); UI.ShowEmojiColorDialog() end,
    ["skin_white"] = function() UI.RainbowSkin = false; UI.BlinkSkin = false; UI.SetSkinColor(1.0, 1.0, 1.0, 1.0); UI.LocalChat("`c[WinProxy]: `9Skin changed to `wWhite"); UI.ShowEmojiColorDialog() end,
    ["skin_red"] = function() UI.RainbowSkin = false; UI.BlinkSkin = false; UI.SetSkinColor(1.0, 0.0, 0.0, 1.0); UI.LocalChat("`c[WinProxy]: `9Skin changed to `4Red"); UI.ShowEmojiColorDialog() end,
    ["skin_yellow"] = function() UI.RainbowSkin = false; UI.BlinkSkin = false; UI.SetSkinColor(1.0, 1.0, 0.0, 1.0); UI.LocalChat("`c[WinProxy]: `9Skin changed to `6Yellow"); UI.ShowEmojiColorDialog() end,
    ["skin_green"] = function() UI.RainbowSkin = false; UI.BlinkSkin = false; UI.SetSkinColor(0.0, 1.0, 0.0, 1.0); UI.LocalChat("`c[WinProxy]: `9Skin changed to `2Green"); UI.ShowEmojiColorDialog() end,
    ["skin_blue"] = function() UI.RainbowSkin = false; UI.BlinkSkin = false; UI.SetSkinColor(0.0, 0.4, 1.0, 1.0); UI.LocalChat("`c[WinProxy]: `9Skin changed to `9Blue"); UI.ShowEmojiColorDialog() end,
    ["skin_purple"] = function() UI.RainbowSkin = false; UI.BlinkSkin = false; UI.SetSkinColor(0.6, 0.1, 0.9, 1.0); UI.LocalChat("`c[WinProxy]: `9Skin changed to `pPurple"); UI.ShowEmojiColorDialog() end,
    ["skin_pink"] = function() UI.RainbowSkin = false; UI.BlinkSkin = false; UI.SetSkinColor(1.0, 0.4, 0.8, 1.0); UI.LocalChat("`c[WinProxy]: `9Skin changed to `5Pink"); UI.ShowEmojiColorDialog() end,

    ["btn_logs_menu"] = function(str) UI.ShowLogsMenuDialog() end,
    ["btn_toggle_logs"] = function(str) 
        UI.LogsEnabled = not UI.LogsEnabled; UI.SaveConfig(true)
        UI.LocalChat("`c[WinProxy]: `9Activity Logging is now " .. (UI.LogsEnabled and "`2ON" or "`4OFF"))
        UI.ShowLogsMenuDialog() 
    end,
    ["btn_clear_logs"] = function(str) 
        UI.Logs = { All = {}, Casino = {}, Inventory = {} }
        UI.LocalChat("`c[WinProxy]: `9All logs have been cleared.")
        UI.ShowLogsMenuDialog() 
    end,
    ["btn_show_all_logs"] = function(str) UI.ShowLogDetailDialog("Global Activity Logs", "All", nil) end,
    ["btn_show_casino_logs"] = function(str) UI.ShowLogDetailDialog("Casino & Spin Logs", "Casino", nil) end,
    ["btn_show_inv_logs"] = function(str) UI.ShowLogDetailDialog("Inventory Logs", "Inventory", nil) end,
    ["btn_show_collect_logs"] = function(str) UI.ShowLogDetailDialog("Collect Logs", "Inventory", "Collected") end,
    ["btn_show_drop_logs"] = function(str) UI.ShowLogDetailDialog("Drop Logs", "Inventory", "Dropped") end,

    ["btn_toggle_abp"] = function(str)
        if #UI.ABP_Packs == 0 then
            UI.LocalChat("`c[WinProxy]: `4Please Auto-Scan the shop first!")
        else
            UI.AutoBuyPack = not UI.AutoBuyPack
            if UI.AutoBuyPack then UI.ManageABPThread() end
        end
        UI.ShowAutoBuyPackDialog()
    end,
    ["btn_scan_abp"] = function(str)
        if not UI.ABP_IsScanningShop then
            UI.ABP_IsScanningShop = true
            UI.ABP_Packs = {}; UI.ABP_PackNames = {}; UI.ABP_AddedCmds = {}
            RunThread(function()
                UI.LocalChat("`c[WinProxy]: `9[1/3] Auto-Scanning 'Featured' tab...")
                SendPacket(2, "action|store\nlocation|gem"); Sleep(1200)
                UI.LocalChat("`c[WinProxy]: `9[2/3] Auto-Scanning 'Locks & Stuff' tab...")
                SendPacket(2, "action|buy\nitem|locks"); Sleep(1200)
                UI.LocalChat("`c[WinProxy]: `9[3/3] Auto-Scanning 'Item Packs' tab...")
                SendPacket(2, "action|buy\nitem|itempack"); Sleep(1200)
                table.sort(UI.ABP_Packs, function(a, b) return a.name:lower() < b.name:lower() end)
                UI.ABP_PackNames = {}
                for _, p in ipairs(UI.ABP_Packs) do table.insert(UI.ABP_PackNames, p.name) end
                UI.ABP_PackIdx = 1
                UI.ABP_IsScanningShop = false
                UI.LocalChat("`c[WinProxy]: `2[+] Auto-Scan Complete! Absorbed `w" .. #UI.ABP_Packs .. "`2 items (Sorted A-Z).")
                Sleep(300)
                UI.ShowAutoBuyPackDialog()
            end)
        end
    end,
    ["btn_abp_select_menu"] = function(str) UI.ShowABPPackListDialog() end,
    ["btn_abp_back"] = function(str) UI.ShowAutoBuyPackDialog() end,
    ["btn_toggle_abp_only"] = function(str)
        UI.ABP_BuyOnly = not UI.ABP_BuyOnly
        UI.SaveConfig(true)
        UI.ShowAutoBuyPackDialog()
    end,
    ["btn_toggle_abp_batch"] = function(str)
        UI.ABP_BatchMode = not UI.ABP_BatchMode
        UI.SaveConfig(true)
        UI.ShowAutoBuyPackDialog()
    end,
    ["btn_save_abp"] = function(str)
        local amt = tonumber(str:match("input_abp_amount|(%d+)"))
        local dx = tonumber(str:match("input_abp_dropx|(%d+)"))
        local dy = tonumber(str:match("input_abp_dropy|(%d+)"))
        if amt then UI.ABP_BuyAmount = amt end
        if dx then UI.ABP_DropX = dx end
        if dy then UI.ABP_DropY = dy end
        UI.SaveConfig(true)
        UI.LocalChat("`c[WinProxy]: `9Auto Buy Pack settings saved!")
        UI.ShowAutoBuyPackDialog()
    end,

    ["btn_do_search_item"] = function(str)
        UI.SearchItemInput = str:match("input_search_item|([^|\n]*)") or ""
        UI.SearchItem(UI.SearchItemInput)
        UI.ShowItemDBDialog()
    end,

    ["btn_save_config"] = function(str) UI.SaveConfig(); UI.ShowSettingDialog() end,
    ["btn_load_config"] = function(str) UI.LoadConfig(); UI.ShowSettingDialog() end,
    ["btn_reset_config"] = function(str) UI.ResetConfig(); UI.ShowSettingDialog() end,

    ["info_copy_wa"] = function(str)
        if isWindows then
            local pipe = io.popen('echo https://chat.whatsapp.com/IuQ3YdLm2lf4EnnCF1GcXr?mode=gi_t | clip', 'w')
            if pipe then pipe:close() end
            LogToConsole("`2[WinProxy]: `9WhatsApp link copied to clipboard!")
        else
            LogToConsole("`2[WinProxy]: `9Link WA: https://chat.whatsapp.com/IuQ3YdLm2lf4EnnCF1GcXr?mode=gi_t")
        end
    end,
    ["info_copy_dc"] = function(str)
        local pipe = io.popen('echo https://discord.gg/kUuE2f98FK | clip', 'w')
        if pipe then pipe:close() end
        LogToConsole("`2[WinProxy]: `9Discord link copied to clipboard!")
    end
}

for i = 1, 5 do
    DialogActions["btn_apt_mypos_" .. i] = function(str)
        local lp = GetLocal()
        if lp and lp.pos then
            UI.AutoPullPos[i].x = math.floor(lp.pos.x / 32)
            UI.AutoPullPos[i].y = math.floor(lp.pos.y / 32)
            UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `2Pos " .. i .. " set to your position: (" .. UI.AutoPullPos[i].x .. ", " .. UI.AutoPullPos[i].y .. ")")
        end
        UI.ShowAPTPositionsDialog()
    end

    DialogActions["btn_apt_touch_" .. i] = function(str)
        UI.AutoPullSettingSlot = i
        UI.LocalChat("`c[WinProxy]: `9Touch any tile on screen to set `2Pos " .. i)
    end

    DialogActions["btn_apt_clear_" .. i] = function(str)
        UI.AutoPullPos[i].x = 0
        UI.AutoPullPos[i].y = 0
        UI.SaveConfig(true)
        UI.LocalChat("`c[WinProxy]: `4Pos " .. i .. " cleared!")
        UI.ShowAPTPositionsDialog()
    end
end


-- ==========================================
-- HOOK : Outgoing Packet
-- ==========================================

function UI.OnOutgoingPacket(type, str)

    -- ==========================================
    -- ==========================================
    if type == 2 and str:find("buttonClicked|win_profile") then
        local fakeProfile = "set_default_color|\n"
        fakeProfile = fakeProfile .. "add_player_info|`2@Win `c[Win Community]|2737|0|49800300|\n"
        fakeProfile = fakeProfile .. "add_spacer|small|\n"
        fakeProfile = fakeProfile .. "add_label|small|Account Net. Worth: Unlimited|left|\n"
        fakeProfile = fakeProfile .. "add_spacer|small|\n"
        fakeProfile = fakeProfile .. "add_label_with_icon|small|Kit Level: Unlimited|left|" .. UI.GetIcon("Golden Sword", 604) .. "|\n"
        fakeProfile = fakeProfile .. "add_spacer|small|\n"
        fakeProfile = fakeProfile .. "add_label_with_icon|small|Total Gems: Unlimited|left|" .. UI.GetIcon("Gems", 112) .. "|\n"
        fakeProfile = fakeProfile .. "add_spacer|small|\n"
        fakeProfile = fakeProfile .. "add_label_with_icon|small|Total World Locks: Unlimited|left|" .. UI.GetIcon("Creativeps Diamond Lock", 1796) .. "|\n"
        fakeProfile = fakeProfile .. "add_label_with_icon|small|Total BGLs in the Bank: Unlimited|left|" .. UI.GetIcon("Creativeps Blue Gem Lock", 7188) .. "|\n"
        fakeProfile = fakeProfile .. "add_label_with_icon|small|Total Black Gem Locks: Unlimited|left|" .. UI.GetIcon("Creativeps Black Gem Lock", 11550) .. "|\n"
        fakeProfile = fakeProfile .. "add_spacer|small|\n"
        fakeProfile = fakeProfile .. "add_label_with_icon|small|Total Growtokens: Unlimited|left|" .. UI.GetIcon("Growtoken", 1486) .. "|\n"
        fakeProfile = fakeProfile .. "add_spacer|small|\n"
        fakeProfile = fakeProfile .. "add_label_with_icon|small|Total Tax Credits: Unlimited|left|" .. UI.GetIcon("Telephone", 3898) .. "|\n"
        fakeProfile = fakeProfile .. "add_spacer|small|\n"
        fakeProfile = fakeProfile .. "add_label_with_icon|small|Total Worlds Owned: All worlds belong to Win|left|" .. UI.GetIcon("Creativeps World Lock", 242) .. "|\n"
        fakeProfile = fakeProfile .. "add_spacer|small|\n"
        fakeProfile = fakeProfile .. "add_label|small|Total Backpack Space: Unlimited|left|\n"
        fakeProfile = fakeProfile .. "add_spacer|small|\n"
        
        fakeProfile = fakeProfile .. "add_button|leaderboard|Back|noflags|0|0|\n"
        fakeProfile = fakeProfile .. "end_dialog|social||\n"
        
        SendVariantList({[0] = "OnDialogRequest", [1] = fakeProfile})
        return true
    end

    if type == 3 and str:find("action|join_request") and str:find("name|WIN COMMUNITY") then
        local modifiedJoin = str:gsub("name|WIN COMMUNITY", "name|WIN")
        SendPacket(3, modifiedJoin)
        UI.LocalChat("`c[WinProxy]: `9Warping to `2WIN `9(via WIN COMMUNITY button)...")
        return true
    end
    
    if str:find("text|/apblacklist add ") then
        local uid = str:match("text|/apblacklist add (%d+)")
        if uid then
            uid = tonumber(uid)
            local found = false
            for _, v in ipairs(UI.AutoPullBlacklist) do
                if v == uid then found = true; break end
            end
            if not found then
                table.insert(UI.AutoPullBlacklist, uid)
                UI.SaveConfig(true)
                UI.LocalChat("`c[WinProxy]: `9Added UID " .. uid .. " to Auto Pull blacklist.")
            else
                UI.LocalChat("`c[WinProxy]: `4UID " .. uid .. " is already in blacklist.")
            end
        else
            UI.LocalChat("`c[WinProxy]: `4Usage: /apblacklist add <UserID>")
        end
        return true

    elseif str:find("text|/apblacklist remove ") then
        local uid = str:match("text|/apblacklist remove (%d+)")
        if uid then
            uid = tonumber(uid)
            local newList = {}
            local removed = false
            for _, v in ipairs(UI.AutoPullBlacklist) do
                if v ~= uid then
                    table.insert(newList, v)
                else
                    removed = true
                end
            end
            UI.AutoPullBlacklist = newList
            if removed then
                UI.SaveConfig(true)
                UI.LocalChat("`c[WinProxy]: `9Removed UID " .. uid .. " from blacklist.")
            else
                UI.LocalChat("`c[WinProxy]: `4UID " .. uid .. " not found in blacklist.")
            end
        else
            UI.LocalChat("`c[WinProxy]: `4Usage: /apblacklist remove <UserID>")
        end
        return true

    elseif str:find("text|/apblacklist list") then
        if #UI.AutoPullBlacklist == 0 then
            UI.LocalChat("`c[WinProxy]: `9Blacklist is empty.")
        else
            local msg = "`c[WinProxy]: `9Blacklist: "
            for i, uid in ipairs(UI.AutoPullBlacklist) do
                msg = msg .. uid .. (i < #UI.AutoPullBlacklist and ", " or "")
                if #msg > 80 then
                    UI.LocalChat(msg)
                    msg = "`c[WinProxy]: "
                end
            end
            if msg ~= "" then UI.LocalChat(msg) end
        end
        return true

    elseif str:find("text|/autocv$") then
            UI.AutoCVLocks = not UI.AutoCVLocks; UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `9Auto CV All Locks is now " .. (UI.AutoCVLocks and "`2ON" or "`4OFF")); return true
    end

    if type == 2 and str:find("dialog_name|drop") then
        local idStr = str:match("item_drop|(%d+)")
        local countStr = str:match("item_count|(%d+)")
        if idStr and countStr then
            local itemID = tonumber(idStr)
            local itemName = "Item ID " .. idStr
            local success, itemData = pcall(function() return GetItemInfo(itemID) end)
            if success and itemData and itemData.name then itemName = itemData.name end
            UI.AddLog("Inventory", "Dropped " .. countStr .. " " .. itemName)
        end
    end

    if type == 2 and str:find("action|dialog_return") then
        local buttonClicked = str:match("buttonClicked|([^|\n]+)")
        if buttonClicked then
            if buttonClicked == "take_all_sbox" then
                if not UI.StorageBoxState.item_queue or #UI.StorageBoxState.item_queue == 0 then
                    UI.LocalChat("`c[WinProxy]: `4[Storage] Storage Box is already empty!")
                    return true
                end

                local first_item, can_hold = UI.GetNextWithdrawableStorageItem(UI.StorageBoxState.item_queue)
                if not first_item or can_hold <= 0 then
                    first_item = UI.StorageBoxState.item_queue[1]
                end

                if not first_item then
                    UI.LocalChat("`c[WinProxy]: `4[Storage] Storage Box is already empty!")
                    return true
                end

                UI.StorageBoxState.active_withdraw = true
                UI.StorageBoxState.current_item = first_item
                UI.StorageBoxState.last_action_time = os.time()

                local use_x = UI.StorageBoxState.last_x or 0
                local use_y = UI.StorageBoxState.last_y or 0
                local btn_name = first_item.raw_btn or ("item_" .. first_item.hash)
                
                RunThread(function()
                    Sleep(20)
                    SendPacket(2, "action|dialog_return\ndialog_name|storage\nx|" .. use_x .. "|\ny|" .. use_y .. "|\nbuttonClicked|" .. btn_name .. "\n")
                end)
                return true
            end

            if buttonClicked:find("^item_") and UI.StorageFilter then
                UI.StorageBoxState.active_withdraw = false
                for _, it in ipairs(UI.StorageBoxState.item_queue) do
                    if it.raw_btn == buttonClicked then
                        UI.StorageBoxState.current_item = it
                        break
                    end
                end
            end

            if buttonClicked:find("^ap_remove_") then
                local idx = buttonClicked:match("ap_remove_(%d+)")
                if idx then
                    local i = tonumber(idx)
                    if i and i <= #UI.AutoPullBlacklist then
                        table.remove(UI.AutoPullBlacklist, i)
                        UI.SaveConfig(true)
                        UI.LocalChat("`c[WinProxy]: `9Removed UID from blacklist.")
                        UI.ShowAutoPullDialog()
                        return true
                    end
                end
            end
            
            if buttonClicked:find("^abp_sel_") then
                local idx = tonumber(buttonClicked:match("abp_sel_(%d+)"))
                if idx and idx <= #UI.ABP_Packs then
                    UI.ABP_PackIdx = idx
                    UI.SaveConfig(true)
                    UI.LocalChat("`c[WinProxy]: `9Selected Pack: `2" .. UI.ABP_Packs[idx].name)
                    UI.ShowAutoBuyPackDialog()
                    return true
                end
            end
            
            if DialogActions[buttonClicked] then
                DialogActions[buttonClicked](str)
                return true
            end
        end
    end

    if type == 2 and str:find("text|/proxy") then 
        UI.ShowImGui = not UI.ShowImGui; UI.SaveConfig(true)
        UI.LocalChat("`c[WinProxy]: `9ImGui Menu is now " .. (UI.ShowImGui and "`2OPEN" or "`4CLOSED"))
        return true 
    end
    if type == 2 and (str:find("text|/menu") or str:find("text|/help")) then UI.ShowMainDialog(); return true end
    if type == 2 and (str:find("text|/cmd")) then UI.ShowCommandsDialog(); return true end

    if type == 2 and str:find("action|input\n|text|") then
        local text = str:match("text|(.+)")
        if text then
            
            local rawTypedCmd = text:match("^(/%S+)")
            
            if rawTypedCmd then
                for alias, data in pairs(UI.CustomCommands) do
                    if data.orig == rawTypedCmd and data.disableOrig then
                        UI.LocalChat("`c[WinProxy]: `4Command " .. rawTypedCmd .. " is disabled! `wUse your alias: `2" .. alias)
                        return true
                    end
                end
            end
            
            if rawTypedCmd and UI.CustomCommands[rawTypedCmd] then
                local aliasData = UI.CustomCommands[rawTypedCmd]
                local safeCmd = rawTypedCmd:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
                text = text:gsub("^" .. safeCmd, aliasData.orig, 1)
                str = str:gsub("text|" .. safeCmd, "text|" .. aliasData.orig, 1)
            end
            
            if text == "/logsmenu" then UI.ShowLogsMenuDialog(); return true
            elseif text == "/clogs" then UI.ShowLogDetailDialog("Collect Logs", "Inventory", "Collected"); return true
            elseif text == "/dlogs" then UI.ShowLogDetailDialog("Drop Logs", "Inventory", "Dropped"); return true
            elseif text == "/invlogs" then UI.ShowLogDetailDialog("Inventory Logs", "Inventory", nil); return true
            elseif text == "/slogs" then UI.ShowLogDetailDialog("Casino & Spin Logs", "Casino", nil); return true
            elseif text == "/logs" then
                UI.LogsEnabled = not UI.LogsEnabled; UI.SaveConfig(true)
                UI.LocalChat("`c[WinProxy]: `9Activity Logging is now " .. (UI.LogsEnabled and "`2ON" or "`4OFF"))
                return true
            elseif text == "/emojimenu" then UI.ShowEmojiColorDialog(); return true
            elseif text == "/emoji" then
                UI.EnableEmoji = not UI.EnableEmoji; UI.SaveConfig(true)
                UI.LocalChat("`c[WinProxy]: `9Random Emoji Mode is now " .. (UI.EnableEmoji and "`2ON" or "`4OFF"))
                return true
            elseif text == "/watermark" then
                UI.WatermarkMode = not UI.WatermarkMode; UI.SaveConfig(true)
                UI.LocalChat("`c[@Win]: `9Chat Watermark is now " .. (UI.WatermarkMode and "`2ON" or "`4OFF"))
                return true
            elseif text == "/encrypt" then
                UI.EncryptChat = not UI.EncryptChat; UI.SaveConfig(true)
                UI.LocalChat("`c[WinProxy]: `9Encrypt Chat is now " .. (UI.EncryptChat and "`2ON" or "`4OFF"))
                return true
            elseif text == "/settingmenu" then UI.ShowSettingDialog(); return true
            end

            if text:sub(1, 1) ~= "/" then
                local prefix = ""
                local hasPrefixElement = false
                
                if UI.EncryptChat then
                    text = UI.Base64Encode(UI.XORCipher(text, UI.EncryptKey))
                end
                
                if UI.WatermarkMode then prefix = prefix .. "`c[@Win]`0 "; hasPrefixElement = true end
                
                if UI.EnableEmoji then
                    local emVal = UI.EmojiValues[UI.SelectedEmojiIdx]
                    if emVal == "RANDOM" then 
                        prefix = prefix .. UI.RandomEmojiList[math.random(1, #UI.RandomEmojiList)] .. " "
                        hasPrefixElement = true
                    elseif emVal ~= "" then 
                        prefix = prefix .. emVal .. " "
                        hasPrefixElement = true 
                    end
                end
                
                if hasPrefixElement then prefix = prefix:sub(1, -2) .. " : " end
                
                if UI.EnableColor then
                    local colVal = UI.ColorValues[UI.SelectedColorIdx]
                    if colVal == "RANDOM" then prefix = prefix .. UI.RandomColorList[math.random(1, #UI.RandomColorList)]
                    else prefix = prefix .. colVal end
                end
                
                if prefix ~= "" or UI.EncryptChat then 
                    SendPacket(2, "action|input\n|text|" .. prefix .. text)
                    return true 
                end
            end
        end
    end
    
    if type == 2 then
        if str:find("text|/wrenchmenu") then UI.ShowWrenchDialog(); return true
        elseif str:find("text|/autopullmenu") then UI.ShowAutoPullDialog(); return true
        elseif str:find("text|/wrp$") then UI.ToggleWrench(1, false); return true
        elseif str:find("text|/wrk$") then UI.ToggleWrench(2, false); return true
        elseif str:find("text|/wrb$") then UI.ToggleWrench(3, false); return true
        elseif str:find("text|/wrt$") then UI.ToggleWrench(4, false); return true
        elseif str:find("text|/wrps$") then UI.ToggleWrench(1, true); return true
        elseif str:find("text|/wrks$") then UI.ToggleWrench(2, true); return true
        elseif str:find("text|/wrbs$") then UI.ToggleWrench(3, true); return true
        elseif str:find("text|/wrts$") then UI.ToggleWrench(4, true); return true
        elseif str:find("text|/donatemenu") then UI.ShowDonateDialog(); return true
        elseif str:find("text|/dmode") then
            UI.DonateMode = not UI.DonateMode
            if not UI.DonateMode then UI.DonateBoxX = 0; UI.DonateBoxY = 0; UI.LocalChat("`c[WinProxy]: `eDonate Mode `4Disabled")
            else UI.LocalChat("`c[WinProxy]: `eDonate Mode `2Enabled`0. Wrench a Donate Box to set position!") end
            UI.SaveConfig(true); return true
        elseif str:find("text|/pw ") then local c = tonumber(str:match("text|/pw (%d+)")); if c then UI.DoDonate(UI.GetIcon("Creativeps World Lock", 242), c) end; return true
        elseif str:find("text|/pd ") then local c = tonumber(str:match("text|/pd (%d+)")); if c then UI.DoDonate(UI.GetIcon("Creativeps Diamond Lock", 1796), c) end; return true
        elseif str:find("text|/pb ") then local c = tonumber(str:match("text|/pb (%d+)")); if c then UI.DoDonate(UI.GetIcon("Creativeps Blue Gem Lock", 7188), c) end; return true
        elseif str:find("text|/pbl ") then local c = tonumber(str:match("text|/pbl (%d+)")); if c then UI.DoDonate(UI.GetIcon("Creativeps Black Gem Lock", 11550), c) end; return true
        elseif str:find("text|/pall") then UI.DonateAllLocks(); return true
        elseif str:find("text|/takeall") then
            if UI.DonateMode and UI.DonateBoxX ~= 0 then
                SendPacket(2, "action|dialog_return\ndialog_name|donate_edit|\nx|"..UI.DonateBoxX.."|\ny|"..UI.DonateBoxY.."|\nbuttonClicked|withdrawall")
                UI.LocalChat("`c[WinProxy]: `9Retrieving all items from Donation Box...")
            else UI.LocalChat("`c[WinProxy]: `4Please enable /dmode and set a box position first!") end
            return true
        elseif str:find("text|/trademenu") then UI.ShowTradeDialog(); return true
        elseif str:find("text|/tmode") then
            UI.ToggleWrench(4)
            return true
        elseif str:find("text|/tw ") then local c = tonumber(str:match("text|/tw (%d+)")); if c then UI.FastTradeAdd(UI.GetIcon("Creativeps World Lock", 242), c) end; return true
        elseif str:find("text|/td ") then local c = tonumber(str:match("text|/td (%d+)")); if c then UI.FastTradeAdd(UI.GetIcon("Creativeps Diamond Lock", 1796), c) end; return true
        elseif str:find("text|/tb ") then local c = tonumber(str:match("text|/tb (%d+)")); if c then UI.FastTradeAdd(UI.GetIcon("Creativeps Blue Gem Lock", 7188), c) end; return true
        elseif str:find("text|/tbl ") then local c = tonumber(str:match("text|/tbl (%d+)")); if c then UI.FastTradeAdd(UI.GetIcon("Creativeps Black Gem Lock", 11550), c) end; return true
        elseif str:find("text|/tall") then UI.TradeAllLocks(); return true
        elseif str:find("text|/tclear") then UI.TradeClearLocks(); return true
        elseif str:find("text|/telemenu") then UI.ShowTelephoneDialog(); return true
        elseif str:find("text|/cvdl") then 
            UI.TeleMode = (UI.TeleMode == 3) and 0 or 3
            UI.LocalChat("`c[WinProxy]: `9Auto Convert DL to BGL is now " .. (UI.TeleMode == 3 and "`2ON" or "`4OFF"))
            UI.SaveConfig(true); return true
        elseif str:find("text|/buybgl") then 
            UI.TeleMode = (UI.TeleMode == 2) and 0 or 2
            UI.LocalChat("`c[WinProxy]: `9Auto Buy BGL is now " .. (UI.TeleMode == 2 and "`2ON" or "`4OFF"))
            UI.SaveConfig(true); return true
        elseif str:find("text|/buydl") then 
            UI.TeleMode = (UI.TeleMode == 1) and 0 or 1
            UI.LocalChat("`c[WinProxy]: `9Auto Buy DL is now " .. (UI.TeleMode == 1 and "`2ON" or "`4OFF"))
            UI.SaveConfig(true); return true
        elseif str:find("text|/buychamp") and not str:find("text|/buychampbulk") then 
            UI.TeleMode = (UI.TeleMode == 4) and 0 or 4
            UI.LocalChat("`c[WinProxy]: `9Auto Buy Champagne is now " .. (UI.TeleMode == 4 and "`2ON" or "`4OFF"))
            UI.SaveConfig(true); return true
        elseif str:find("text|/buychampbg") then 
            UI.TeleMode = (UI.TeleMode == 5) and 0 or 5
            UI.LocalChat("`c[WinProxy]: `9Auto Buy Champagne (BGems) is now " .. (UI.TeleMode == 5 and "`2ON" or "`4OFF"))
            UI.SaveConfig(true); return true
        elseif str:find("text|/buychampbulk") then 
            UI.TeleMode = (UI.TeleMode == 6) and 0 or 6
            UI.LocalChat("`c[WinProxy]: `9Auto Buy Bulk Champagne is now " .. (UI.TeleMode == 6 and "`2ON" or "`4OFF"))
            UI.SaveConfig(true); return true
        elseif str:find("text|/casinomenu") then UI.ShowCasinoDialog(); return true
        elseif str:find("text|/allmode") then 
            UI.CasinoMode = (UI.CasinoMode == 7) and 0 or 7; UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: " .. (UI.CasinoMode == 7 and "`2Enabled" or "`4Disabled") .. " All Casino Mode"); return true
        elseif str:find("text|/reme") then
            UI.CasinoMode = (UI.CasinoMode == 1) and 0 or 1; UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: " .. (UI.CasinoMode == 1 and "`2Enabled" or "`4Disabled") .. " Reme Mode"); return true
        elseif str:find("text|/qeme") then 
            UI.CasinoMode = (UI.CasinoMode == 2) and 0 or 2; UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: " .. (UI.CasinoMode == 2 and "`2Enabled" or "`4Disabled") .. " Qeme Mode"); return true
        elseif str:find("text|/lemes") then 
            UI.CasinoMode = (UI.CasinoMode == 4) and 0 or 4; UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: " .. (UI.CasinoMode == 4 and "`2Enabled" or "`4Disabled") .. " Leme S Mode"); return true
        elseif str:find("text|/leme") then 
            UI.CasinoMode = (UI.CasinoMode == 3) and 0 or 3; UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: " .. (UI.CasinoMode == 3 and "`2Enabled" or "`4Disabled") .. " Leme Mode"); return true
        elseif str:find("text|/ceme") then 
            UI.CasinoMode = (UI.CasinoMode == 5) and 0 or 5; UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: " .. (UI.CasinoMode == 5 and "`2Enabled" or "`4Disabled") .. " Ceme Mode"); return true
        elseif str:find("text|/lewa") then
            local multiStr = str:match("text|/lewa%s+(%d+)")
            if multiStr then
                local num = tonumber(multiStr)
                if num < 5 then num = 5 end
                if num > 7 then num = 7 end
                UI.CasinoLewaMulti = num; UI.CasinoMode = 6; UI.SaveConfig(true)
                UI.LocalChat("`c[WinProxy]: `2Enabled Lewa Mode (Multi: " .. UI.CasinoLewaMulti .. ")")
            else
                UI.CasinoMode = (UI.CasinoMode == 6) and 0 or 6; UI.SaveConfig(true)
                UI.LocalChat(UI.CasinoMode == 6 and "`c[WinProxy]: `2Enabled Lewa Mode (Multi: " .. UI.CasinoLewaMulti .. ")" or "`c[WinProxy]: `4Disabled Lewa Mode")
            end
            return true
        elseif str:find("text|/blue") then SendPacket(2,"action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bluegl"); return true
        elseif str:find("text|/black") then SendPacket(2,"action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bgl"); return true
        elseif str:find("text|/depo") then
            local count = str:match("text|/depo (%d+)")
            if count then 
                SendPacket(2,"action|dialog_return\ndialog_name|bank_deposit\nbgl_count|" .. count)
                UI.BankBalance = UI.BankBalance + tonumber(count)
                UI.LocalChat("`c[WinProxy]: `9Deposited `4"..count.." `eBlue Gem Locks`4!")
            else
                local totalToDeposit = 0
                for _, inv in pairs(GetInventory()) do
                    if inv.id == UI.GetIcon("Creativeps Blue Gem Lock", 7188) then totalToDeposit = totalToDeposit + inv.amount end
                    if inv.id == UI.GetIcon("Creativeps Black Gem Lock", 11550) then totalToDeposit = totalToDeposit + (inv.amount * 100) end
                end
                if totalToDeposit > 0 then
                    SendPacket(2, "action|dialog_return\ndialog_name|bank_deposit\nbgl_count|" .. totalToDeposit)
                    UI.BankBalance = UI.BankBalance + totalToDeposit
                    UI.LocalChat("`c[WinProxy]: `9Deposited All (`4" .. totalToDeposit .. " BGL equivalent`9)`4!")
                else UI.LocalChat("`c[WinProxy]: `4You don't have any Blue Gem Locks to deposit!") end
            end
            return true
        elseif str:find("text|/with") then
            local count = str:match("text|/with (%d+)")
            if count then 
                local wAmt = tonumber(count)
                SendPacket(2,"action|dialog_return\ndialog_name|bank_withdraw\nbgl_count|" .. wAmt)
                UI.BankBalance = math.max(0, UI.BankBalance - wAmt)
                UI.LocalChat("`c[WinProxy]: `9Withdrew `4"..wAmt.." `eBlue Gem Locks`4!")
            else
                if UI.BankBalance > 0 then
                    SendPacket(2,"action|dialog_return\ndialog_name|bank_withdraw\nbgl_count|" .. UI.BankBalance)
                    UI.LocalChat("`c[WinProxy]: `9Withdrew All (`4"..UI.BankBalance.." `eBGLs`9) from Bank`4!")
                    UI.BankBalance = 0
                else UI.LocalChat("`c[WinProxy]: `4Error! `9Bank memory is 0. Please open your Bank manually once to sync, or use `w/with <amount>") end
            end
            return true
        elseif str:find("text|/dw ") then
            local count = tonumber(str:match("text|/dw (%d+)"))
            if count then UI.SmartDropLock(1, count) else UI.LocalChat("`c[WinProxy]: `4Invalid amount!") end
            return true
        elseif str:find("text|/dd ") then
            local count = tonumber(str:match("text|/dd (%d+)"))
            if count then UI.SmartDropLock(2, count) else UI.LocalChat("`c[WinProxy]: `4Invalid amount!") end
            return true
        elseif str:find("text|/db ") and not str:find("text|/dbl") then
            local count = tonumber(str:match("text|/db (%d+)"))
            if count then UI.SmartDropLock(3, count) else UI.LocalChat("`c[WinProxy]: `4Invalid amount!") end
            return true
        elseif str:find("text|/dbl ") then
            local count = tonumber(str:match("text|/dbl (%d+)"))
            if count then UI.SmartDropLock(4, count) else UI.LocalChat("`c[WinProxy]: `4Invalid amount!") end
            return true
        elseif str:find("text|/daw$") then
            RunThread(function()
                local locks = { [UI.GetIcon("Creativeps World Lock", 242)] = "WL", [UI.GetIcon("Creativeps Diamond Lock", 1796)] = "DL", [UI.GetIcon("Creativeps Blue Gem Lock", 7188)] = "BGL", [UI.GetIcon("Creativeps Black Gem Lock", 11550)] = "Black GL" }
                local droppedAny = false
                for _, inv in pairs(GetInventory()) do
                    if locks[inv.id] and inv.amount > 0 then
                        SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|"..inv.id.."|\nitem_count|"..inv.amount)
                        Sleep(400); droppedAny = true
                    end
                end
                if droppedAny then UI.LocalChat("`c[WinProxy]: `2Success `0Dropped all locks in backpack!") else UI.LocalChat("`c[WinProxy]: `4No locks found in backpack.") end
            end)
            return true
        elseif str:find("text|/calcmenu") then UI.ShowCalculatorDialog(); return true
        elseif str:find("text|/calc ") then
            local raw_input = str:match("text|/calc (.*)")
            if raw_input then
                UI.CalcInput = raw_input
                local success, clean, res = UI.CalculateMath(raw_input)
                if success then UI.LocalChat("`c[WinProxy]: `0Calc : " .. clean .. " = `2" .. res) else UI.LocalChat("`c[WinProxy]: " .. UI.CalcResult) end
            end
            return true
        elseif str:find("text|/spammenu") then UI.ShowSpamDialog(); return true
        elseif str:find("text|/spam") and not str:find("text|/spamtext") and not str:find("text|/spammenu") and not str:find("text|/addspam") and not str:find("text|/removespam") then
            UI.ToggleSpam(not UI.SpamEnabled); return true
        elseif str:find("text|/addspam ") then
            local newTxt = str:match("text|/addspam (.+)")
            if newTxt then table.insert(UI.SpamTexts, newTxt); UI.LocalChat("`c[WinProxy]: `9Added new spam text: `w" .. newTxt) end
            return true
        elseif str:find("text|/removespam") then
            if #UI.SpamTexts > 1 then
                table.remove(UI.SpamTexts); UI.LocalChat("`c[WinProxy]: `9Removed the last spam text field.")
            else
                UI.SpamTexts[1] = ""; UI.LocalChat("`c[WinProxy]: `9Cleared the first spam text field.")
            end
            return true
        elseif str:find("text|/spamtext ") then
            local id, newTxt = str:match("text|/spamtext (%d+) (.+)")
            if id and newTxt then
                local idx = tonumber(id)
                if idx > 0 and idx <= #UI.SpamTexts then
                    UI.SpamTexts[idx] = newTxt; UI.LocalChat("`c[WinProxy]: `9Typer Text " .. idx .. " set to: `w" .. newTxt)
                else UI.LocalChat("`c[WinProxy]: `4Invalid field number! You only have " .. #UI.SpamTexts .. " fields.") end
            else UI.LocalChat("`c[WinProxy]: `4Usage: /spamtext <number> <text>") end
            return true
        elseif str:find("text|/sbmenu") then UI.ShowSBDialog(); return true
        elseif str:find("text|/sbstart") then UI.SBEnabled = true; UI.SBStartTime = os.time(); UI.ManageSBThread(); return true
        elseif str:find("text|/sbstop") then UI.SBEnabled = false; UI.LocalChat("`c[WinProxy]: `4STOPPING `0SUPER BROADCAST"); return true
        elseif str:find("text|/sdbstart") then UI.SDBEnabled = true; UI.ManageSDBThread(); return true
        elseif str:find("text|/sdbstop") then UI.SDBEnabled = false; UI.LocalChat("`c[WinProxy]: `4STOPPING `0SUPER DUPER BROADCAST"); return true
        elseif str:find("text|/testpush$") then
    local log = "--- PushStyleColor Test ---\n"
    local ok1, err1 = pcall(ImGui.PushStyleColor, ImGui.Col.WindowBg, ImVec4(1,0,0,1))
    if ok1 then pcall(ImGui.PopStyleColor, 1) end
    log = log .. "Syntax 1 (ImVec4): " .. tostring(ok1) .. " - " .. tostring(err1) .. "\n"
    
    local ok2, err2 = pcall(ImGui.PushStyleColor, ImGui.Col.WindowBg, 1.0, 0.0, 0.0, 1.0)
    if ok2 then pcall(ImGui.PopStyleColor, 1) end
    log = log .. "Syntax 2 (R,G,B,A): " .. tostring(ok2) .. " - " .. tostring(err2) .. "\n"
    
    local ok3, err3 = pcall(ImGui.PushStyleColor, ImGui.Col.WindowBg, 0xFF0000FF)
    if ok3 then pcall(ImGui.PopStyleColor, 1) end
    log = log .. "Syntax 3 (U32): " .. tostring(ok3) .. " - " .. tostring(err3) .. "\n"
    
    local file = io.open("testpush_dump.txt", "w")
    if file then
        file:write(log)
        file:close()
        UI.LocalChat("`c[WinProxy]: `2PushStyleColor test dumped to testpush_dump.txt!")
    end
    return true
elseif str:find("text|/dumpstyle$") then
    local dumpStr = "--- ImGui.Col DUMP ---\n"
    if ImGui.Col then
        for k, v in pairs(ImGui.Col) do
            dumpStr = dumpStr .. tostring(k) .. " = " .. tostring(v) .. "\n"
        end
    end
    dumpStr = dumpStr .. "\n--- GetStyleColorVec4 DUMP ---\n"
    if ImGui.Col and ImGui.GetStyleColorVec4 then
        for k, v in pairs(ImGui.Col) do
            local ok, vec = pcall(ImGui.GetStyleColorVec4, v)
            if ok and _G.type(vec) == "table" then
                -- Try to grab x,y,z,w fields (R,G,B,A)
                local r = tostring(vec.x or vec[1] or vec.r or "nil")
                local g = tostring(vec.y or vec[2] or vec.g or "nil")
                local b = tostring(vec.z or vec[3] or vec.b or "nil")
                local a = tostring(vec.w or vec[4] or vec.a or "nil")
                dumpStr = dumpStr .. tostring(k) .. " ("..tostring(v)..") = R:" .. r .. " G:" .. g .. " B:" .. b .. " A:" .. a .. "\n"
            end
        end
    end
    
    local file = io.open("style_dump.txt", "w")
    if file then
        file:write(dumpStr)
        file:close()
        UI.LocalChat("`c[WinProxy]: `2Style table dumped to style_dump.txt!")
    end
    return true
elseif str:find("text|/dumpimgui$") then
    local dumpStr = ""
    for k, v in pairs(ImGui) do
        dumpStr = dumpStr .. tostring(k) .. " = " .. tostring(v) .. "\n"
    end
    local file = io.open("imgui_dump.txt", "w")
    if file then
        file:write(dumpStr)
        file:close()
        UI.LocalChat("`c[WinProxy]: `2ImGui table dumped to imgui_dump.txt!")
    end
    return true
elseif str:find("text|/imgui$") then
            UI.ShowImGui = not UI.ShowImGui; UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `9ImGui Menu is now " .. (UI.ShowImGui and "`2OPEN" or "`4CLOSED")); return true
        elseif str:find("text|/antipickup$") then
            UI.AntiPickup = not UI.AntiPickup; UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `9Anti Pickup is now " .. (UI.AntiPickup and "`2ON" or "`4OFF")); return true
        elseif str:find("text|/modfly$") then 
            UI.Modfly = not UI.Modfly; pcall(function() ChangeValue("[C] Modfly", UI.Modfly) end); UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `9Modfly is now " .. (UI.Modfly and "`2ON" or "`4OFF")); return true
        elseif str:find("text|/antiportal$") then 
            UI.AntiPortal = not UI.AntiPortal; pcall(function() ChangeValue("[C] Anti portal", UI.AntiPortal) end); UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `9Anti Portal is now " .. (UI.AntiPortal and "`2ON" or "`4OFF")); return true
        elseif str:find("text|/nightvision$") then 
            UI.NightVision = not UI.NightVision; pcall(function() ChangeValue("[C] Night vision", UI.NightVision) end); UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `9Night Vision is now " .. (UI.NightVision and "`2ON" or "`4OFF")); return true
        elseif str:find("text|/blocksdb$") then
            UI.BlockSDB = not UI.BlockSDB; UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `9Block SDB Dialog is now " .. (UI.BlockSDB and "`2ON" or "`4OFF")); return true
        elseif str:find("text|/autopull$") then
            UI.AutoPull = not UI.AutoPull
            UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `9Auto Pull is now " .. (UI.AutoPull and "`2ON" or "`4OFF")); return true
        elseif str:find("text|/autopullscan$") then
            UI.AutoPullAreaScan = not UI.AutoPullAreaScan
            if UI.AutoPullAreaScan then UI.ManageAreaPullThread() end
            UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `9Auto Pull Scan is now " .. (UI.AutoPullAreaScan and "`2ON" or "`4OFF")); return true
        elseif str:find("text|/posautopull$") then
            local lp = GetLocal()
            if lp and lp.pos then
                UI.AutoPullTileX = math.floor(lp.pos.x / 32)
                UI.AutoPullTileY = math.floor(lp.pos.y / 32)
                UI.SaveConfig(true)
                UI.LocalChat("`c[WinProxy]: `2[APT] Target tile set to your position: (" .. UI.AutoPullTileX .. ", " .. UI.AutoPullTileY .. ")")
            end
            return true
        elseif str:find("text|/clearposautopull$") then
            UI.AutoPullTileX = 0
            UI.AutoPullTileY = 0
            UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `2[APT] Target tile reset to Auto White Door.")
            return true
        elseif str:find("text|/antilag$") then
            UI.ToggleAntiLag(); return true
        elseif str:find("text|/hidespammer$") then
            UI.ToggleHideSpammer(); return true
        elseif str:find("text|/tp$") then
            UI.TPDisplay = not UI.TPDisplay; UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `9Teleport Punch is now " .. (UI.TPDisplay and "`2ON" or "`4OFF")); return true
        elseif str:find("text|/showbal$") then
            UI.ShowBal = not UI.ShowBal; UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `9Show Balance is now " .. (UI.ShowBal and "`2ON" or "`4OFF")); return true
        elseif str:find("text|/fastdrop$") then
            UI.FastDrop = not UI.FastDrop; UI.LocalChat("`c[WinProxy]: `9Fast Drop is now " .. (UI.FastDrop and "`2ON" or "`4OFF")); return true
        elseif str:find("text|/fasttrash$") then
            UI.FastTrash = not UI.FastTrash; UI.LocalChat("`c[WinProxy]: `9Fast Trash is now " .. (UI.FastTrash and "`2ON" or "`4OFF")); return true
        elseif str:find("text|/vendfilter$") then
            UI.VendFilter = not UI.VendFilter; UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `9Vend Filter is now " .. (UI.VendFilter and "`2ON" or "`4OFF")); return true
        elseif str:find("text|/donfilter$") then
            UI.DonationFilter = not UI.DonationFilter; UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `9Donation Box Filter is now " .. (UI.DonationFilter and "`2ON" or "`4OFF")); return true
        elseif str:find("text|/sboxfilter$") then
            UI.StorageFilter = not UI.StorageFilter; UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `9Storage Box Filter is now " .. (UI.StorageFilter and "`2ON" or "`4OFF")); return true
        elseif str:find("text|/modal$") then UI.CalculateMyModal(); return true
        elseif str:find("text|/btkmenu$") or str:find("text|/bjmenu$") then UI.ShowBTKBJDialog(); return true
        elseif str:find("text|/btkcmd$") or str:find("text|/bjcmd$") then UI.ShowBTKCommandsDialog(); return true
        elseif str:find("text|/btk$") then
            UI.BTK_Mode = "BTK"; UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `2Game Mode set to BTK (Most Gems)"); return true
        elseif str:find("text|/bj$") then
            UI.BTK_Mode = "BJ"; UI.SaveConfig(true)
            UI.LocalChat("`c[WinProxy]: `2Game Mode set to BJ (Blackjack 21)"); return true
        elseif str:find("text|/btkremote$") or str:find("text|/bjremote$") then
            UI.BTK_ActionTakeRemote(); return true
        elseif str:find("text|/btkbet$") or str:find("text|/bjbet$") then
            UI.BTK_ActionTakeBets(); return true
        elseif str:find("text|/btkgems$") or str:find("text|/bjgems$") then
            UI.BTK_ActionCheckGems(); return true
        elseif str:find("text|/btkdrop$") or str:find("text|/bjdrop$") then
            UI.BTK_ActionDropReset(); return true
        elseif str:find("text|/btkcenter$") or str:find("text|/bjcenter$") then
            UI.BTK_SelectingTarget = "Host Center"; UI.LocalChat("`c[WinProxy]: `9Touch or Punch any tile to set `2Host Center"); return true
        elseif str:find("text|/btkposbet1$") or str:find("text|/bjposbet1$") then
            UI.BTK_SelectingTarget = "Bet P1"; UI.LocalChat("`c[WinProxy]: `9Touch or Punch any tile to set `2Bet P1"); return true
        elseif str:find("text|/btkposbet2$") or str:find("text|/bjposbet2$") then
            UI.BTK_SelectingTarget = "Bet P2"; UI.LocalChat("`c[WinProxy]: `9Touch or Punch any tile to set `2Bet P2"); return true
        elseif str:find("text|/btkposbreak1$") or str:find("text|/bjposbreak1$") then
            UI.BTK_SelectingTarget = "Break P1 (Mid)"; UI.LocalChat("`c[WinProxy]: `9Touch or Punch any tile to set `2Break P1 (Mid)"); return true
        elseif str:find("text|/btkposbreak2$") or str:find("text|/bjposbreak2$") then
            UI.BTK_SelectingTarget = "Break P2 (Mid)"; UI.LocalChat("`c[WinProxy]: `9Touch or Punch any tile to set `2Break P2 (Mid)"); return true
        elseif str:find("text|/btktax$") or str:find("text|/bjtax$") then
            UI.BTK_SelectingTarget = "Tax Drop (Mid)"; UI.LocalChat("`c[WinProxy]: `9Touch or Punch any tile to set `2Tax Drop (Mid)"); return true
        elseif str:find("text|/btkmag$") or str:find("text|/bjmag$") then
            UI.BTK_SelectingTarget = "Magplant (Top)"; UI.LocalChat("`c[WinProxy]: `9Touch or Punch any tile to set `2Magplant (Top)"); return true
        elseif str:find("text|/g$") then SendPacket(2, "action|input\n|text|/ghost"); return true
        elseif str:find("text|/res$") then SendPacket(2, "action|respawn"); return true
        elseif str:find("text|/re$") then 
            local world = GetWorld() and GetWorld().name or ""
            if world ~= "" then SendPacket(3, "action|join_request\nname|" .. world .. "\ninvitedWorld|0") end
            return true
        elseif str:find("text|/relog$") then 
            SendVariantList({[0] = "OnReconnect"}); UI.LocalChat("`c[WinProxy]: `9Reconnecting to server..."); return true
        end
    end

    if type == 2 and str:find("action|wrench") and str:find("netid|(%d+)") then
        local netid = str:match("netid|(%d+)")
        local handled = false

        local l_click = 0
        local r_click = 0
        local isRightClick = false
        
        if GetAsyncKeyState then
            l_click = tonumber(GetAsyncKeyState(1)) or 0
            r_click = tonumber(GetAsyncKeyState(2)) or 0
            
            if r_click ~= 0 then
                isRightClick = true
            end
            if l_click < 0 or l_click >= 32768 then
                isRightClick = false
            end
        end

        local activeMode = isRightClick and UI.WrenchModeRight or UI.WrenchMode

        if activeMode == 1 then 
            SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netid .. "|\nbuttonClicked|pull")
            if UI.WrenchPullText ~= "" then
                local pName = UI.GetPlayerNameByNetID(netid)
                local chatMsg = UI.WrenchPullText:gsub("{GrowID}", function() return pName end)
                SendPacket(2, "action|input\n|text|" .. chatMsg)
            end
            handled = true
        elseif activeMode == 2 then 
            SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netid .. "|\nbuttonClicked|kick")
            if UI.WrenchKickText ~= "" then
                local pName = UI.GetPlayerNameByNetID(netid)
                local chatMsg = UI.WrenchKickText:gsub("{GrowID}", function() return pName end)
                SendPacket(2, "action|input\n|text|" .. chatMsg)
            end
            handled = true
        elseif activeMode == 3 then 
            SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netid .. "|\nbuttonClicked|world_ban")
            if UI.WrenchBanText ~= "" then
                local pName = UI.GetPlayerNameByNetID(netid)
                local chatMsg = UI.WrenchBanText:gsub("{GrowID}", function() return pName end)
                SendPacket(2, "action|input\n|text|" .. chatMsg)
            end
            handled = true
        elseif activeMode == 4 then 
            SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netid .. "|\nbuttonClicked|trade")
            UI.TradeTargetName = UI.GetPlayerNameByNetID(netid)
            UI.TradeTargetUID = 0
            local success, players = pcall(GetPlayerList)
            if success and players then
                for _, p in pairs(players) do
                    if p.netid == tonumber(netid) then
                        UI.TradeTargetUID = p.userid or 0
                        break
                    end
                end
            end
            handled = true 
        end

        if UI.ShowBal then
            if handled then
                RunThread(function() Sleep(250); SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netid .. "|\nbuttonClicked|viewinv") end)
            else SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netid .. "|\nbuttonClicked|viewinv") end
            handled = true
        end

        if handled then return true end
    end

    if type == 2 and str:find("action|wrench") then
        if UI.AutoSurg then
            local netid = str:match("netid|(%d+)")
            if netid then
                UI.SurgTarget = netid
                local lp = GetLocal()
                if lp and lp.pos then
                    UI.SurgPos = { x = math.floor(lp.pos.x / 32), y = math.floor(lp.pos.y / 32) }
                end
                UI.LocalChat("`c[WinProxy]: `9Surgery Target Locked! Player ID: `2" .. netid)
            end
        end
    end

    return false
end


-- ==========================================
-- HOOK : Incoming Variant
-- ==========================================

function UI.OnVariant(var)
    if type(var) == "table" and var[0] then

        -- ==========================================
        -- ==========================================
        if var[0] == "OnDialogRequest" and type(var[1]) == "string" then
            local d = var[1]
            
            -- Inject theme to all dialogs
            local themedD = UI.ApplyTheme(d)
            if themedD ~= d then
                var[1] = themedD
            end
            
            if d:find("Wow, that's fast delivery") or d:find("One Champagne Bottle") or d:find("exchange for 100 Diamond Lock") then
                if UI.IsAutoCVRunning or UI.TeleMode > 0 then
                    return true 
                end
            end

            if UI.TeleMode > 0 and (d:find("Phone #") or d:find("end_dialog|telephone")) then
                local tx = d:match("embed_data|x|(%d+)")
                local ty = d:match("embed_data|y|(%d+)")
                
                if tx and ty then
                    local packetStr = "action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|" .. tx .. "|\ny|" .. ty .. "|\nbuttonClicked|"
                    
                    if UI.TeleMode == 1 then SendPacket(2, packetStr .. "dlconvert")
                    elseif UI.TeleMode == 2 then SendPacket(2, packetStr .. "bglconvert2")
                    elseif UI.TeleMode == 3 then SendPacket(2, packetStr .. "bglconvert")
                    elseif UI.TeleMode == 4 then SendPacket(2, packetStr .. "getchamp")
                    elseif UI.TeleMode == 5 then SendPacket(2, packetStr .. "getchamp2")
                    elseif UI.TeleMode == 6 then SendPacket(2, packetStr .. "getchamp3") end
                end
                
                return true
            end
        end

        -- ==========================================
        -- ==========================================
        if UI.AutoSurg then
            for idx = 1, 4 do
                if type(var[idx]) == "string" then
                    local cleanStr = var[idx]:gsub("`.", ""):lower()
                    if cleanStr:find("already performing surgery") or cleanStr:find("performing surgery on somebody") then
                        local now = os.time()
                        if (now - (UI.LastWarpResetTime or 0)) >= 3 then
                            UI.LastWarpResetTime = now
                            UI.PerformSurgAntiStuck("Already In Surgery Session")
                        end
                        return true
                    end
                end
            end
        end

        -- ==========================================
        -- ==========================================
        if UI.AutoSurg and (UI.SurgAutoModage or UI.SurgUseLegalBrief) then
            for idx = 1, 4 do
                if type(var[idx]) == "string" then
                    local rawStr = var[idx]
                    local cleanStr = rawStr:gsub("`.", ""):lower()
                    if cleanStr:find("allow") or cleanStr:find("surgery right now") or cleanStr:find("malpractice") or cleanStr:find("mistake") or cleanStr:find("debt to society") or cleanStr:find("patient died") or cleanStr:find("failed the surgery") then
                        UI.LocalChat("`c[WinProxy]: `4[Detected Malpractice via " .. tostring(var[0]) .. "] `wBypassing...")
                        UI.BypassMalpractice()
                        return true
                    end
                end
            end
        end


        -- ==========================================
        -- ==========================================
        if var[0] == "OnDialogRequest" and type(var[1]) == "string" and var[1]:find("eliteitem") then
            local raw = var[1]
            
            local modifiedRaw = raw:gsub("(add_small_font_button|eliteitem|[^\n]+)\n", "%1\nadd_label|small|`9Richest Player :|left|\nadd_button|win_profile|`4#0 `9@Win of Legend `c[W`3I`1N`c-`!C`cO`3M`1M`cU`3N`!I`1T`cY]|noflags|0|0|\n", 1)
            
            SendVariantList({[0] = "OnDialogRequest", [1] = modifiedRaw})
            return true 
        end

        -- ==========================================
        -- ==========================================
        if var[0] == "OnRequestWorldSelectMenu" and type(var[1]) == "string" then
            local menuData = var[1]
            
            if menuData:find("add_floater|BUY|") then
                local modifiedMenu = menuData:gsub("add_floater|([^|]+)|%-1|", "add_floater|%1|-2|")
                
                modifiedMenu = modifiedMenu:gsub("(add_floater|BUY|[^\n]+)\n", "%1\nadd_floater|WIN COMMUNITY|-1|0.467896|65535\n", 1)
                
                SendVariantList({[0] = "OnRequestWorldSelectMenu", [1] = modifiedMenu})
                return true
            end
        end

        if UI.HideSpammer then
            if var[0] == "OnConsoleMessage" and type(var[1]) == "string" then
                if var[1]:find("'s Spammer Slave.") then return true end
            elseif var[0] == "OnTalkBubble" and type(var[2]) == "string" then
                if var[2]:lower():find("spammer slave") then return true end
            elseif var[0] == "OnSpawn" and type(var[1]) == "string" then
                local spawnData = var[1]
                if not (spawnData:find("type%s*|%s*local") or spawnData:find("type|local")) then
                    if spawnData:lower():find("spammer slave") then return true end
                end
            end
        end

        if UI.AutoPull and var[0] == "OnSpawn" and type(var[1]) == "string" then
            local spawnData = var[1]
            if spawnData:find("type%s*|%s*local") or spawnData:find("type|local") then return false end
            
            if spawnData:lower():find("spammer slave") then return false end
            
            local netID = spawnData:match("netID%s*|%s*(%d+)")
            local userID = spawnData:match("userID%s*|%s*(%d+)")
            local nameMatch = spawnData:match("name%s*|%s*([^|\n]+)")
            
            local posX, posY = spawnData:match("posXY%|(%d+)%|(%d+)")
            if not posX then
                posX = spawnData:match("pos_x%|(%d+)")
                posY = spawnData:match("pos_y%|(%d+)")
            end
            
            if netID then
                local playerObj = {
                    netid = tonumber(netID),
                    netID = tonumber(netID),
                    userid = tonumber(userID),
                    name = nameMatch and Filter(nameMatch) or "Unknown",
                }
                
                if posX and posY then
                    local spawnTileX = math.floor(tonumber(posX) / 32)
                    local spawnTileY = math.floor(tonumber(posY) / 32)
                    
                    local pulled = false
                    for i = 1, 5 do
                        local targetX = UI.AutoPullPos[i].x
                        local targetY = UI.AutoPullPos[i].y
                        if targetX > 0 and targetY > 0 then
                            if (spawnTileX == targetX) and (spawnTileY == targetY or spawnTileY == targetY + 1 or spawnTileY == targetY - 1) then
                                UI.CheckAndExecutePull(playerObj, "OnSpawn (Pos " .. i .. ")")
                                pulled = true
                                break
                            end
                        end
                    end
                    
                    if not pulled then
                        local allEmpty = true
                        for i = 1, 5 do if UI.AutoPullPos[i].x > 0 then allEmpty = false; break end end
                        if allEmpty then
                            UI.CheckAndExecutePull(playerObj, "OnSpawn (Anywhere)")
                        end
                    end
                end
            end
        end
        
        if UI.AutoSurg then
            if var[0] == "OnDialogRequest" and type(var[1]) == "string" then
                local d = var[1]
                
                if d:find("`!Perform Surgery``") or (d:find("end_dialog|popup") and d:find("buttonClicked|surgery")) then
                    local targetNetID = d:match("embed_data|netID|(%d+)") or UI.SurgTarget
                    if targetNetID then
                        UI.SurgTarget = targetNetID
                        UI.IsSurging = true
                        UI.SurgStartTime = os.time()
                        SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. targetNetID .. "|\nbuttonClicked|surgery\n\n")
                        return true
                    end
                end

                if d:find("end_dialog|surge_edit") or d:find("Anatomical") then
                    local bx = d:match("embed_data|x|(%d+)") or d:match("|x|(%d+)")
                    local by = d:match("embed_data|y|(%d+)") or d:match("|y|(%d+)")
                    if bx and by then
                        SendPacket(2, "action|dialog_return\ndialog_name|surge_edit\nx|" .. bx .. "|\ny|" .. by .. "|\n\n")
                        UI.IsSurging = true
                        UI.SurgStartTime = os.time()
                        return true
                    end
                end

                if d:find("You aren't allowed to do surgery right now.") or d:find("allowed") or d:find("malpractice") or d:find("mistake") then
                    UI.BypassMalpractice()
                    return true
                end

                if d:find("Recovering") or d:lower():find("recovering") then
                    UI.IsSurging = false
                    UI.SurgStartTime = 0
                    if UI.SurgTarget then
                        SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. UI.SurgTarget .. "|\nbuttonClicked|chc0\n\n")
                        UI.LocalChat("`c[WinProxy]: `4Patient is recovering! `9Target locked (waiting for patient).")
                        UI.SurgAction = "Patient Recovering..."
                    end
                    return true
                end

                if d:find("end_dialog|surgery") then
                    UI.IsSurging = true
                    UI.SurgStartTime = os.time()
                    local toolCmd = ""
                    local toolName = ""
                    
                    if d:find("It is becoming") or d:find("You can't see") then
                        toolCmd, toolName = "command_0", "Sponge"
                    elseif d:find("Patient's fever") then
                        toolCmd, toolName = "command_4", "Antibiotics"
                    elseif d:find("Not sanitized") or d:find("Unclean") or d:find("Unsanitary") then
                        toolCmd, toolName = "command_3", "Antiseptic"
                    elseif d:find("Awake!") then
                        toolCmd, toolName = "command_2", "Anesthetic"
                    elseif d:find("losing") then
                        toolCmd, toolName = "command_6", "Stitches"
                    elseif d:find("Fix It!") and not (d:find("Incisions: `30``") or d:find("Incisions: `60``") or d:find("Incisions: 0")) then
                        toolCmd, toolName = "command_6", "Stitches"
                    elseif d:find("Unconscious") and d:find("Clean") and not d:find("Fix It!") then
                        toolCmd, toolName = "command_1", "Scalpel"
                    elseif (d:find("Incisions: `30``") or d:find("Incisions: `60``") or d:find("Incisions: 0")) and d:find("Fix It!") then
                        toolCmd, toolName = "command_7", "Fix It!"
                        UI.OnSurgerySuccess()
                    elseif d:find("command_7") then
                        toolCmd, toolName = "command_7", "Fix It!"
                    elseif d:find("command_1") then
                        toolCmd, toolName = "command_1", "Scalpel"
                    end
                    
                    if toolCmd ~= "" then
                        if toolCmd ~= "command_7" or not (d:find("Incisions: `30``") or d:find("Incisions: `60``") or d:find("Incisions: 0")) then
                            UI.SurgAction = "Using " .. toolName .. "..."
                        end
                        RunThread(function()
                            Sleep(60)
                            SendPacket(2, "action|dialog_return\ndialog_name|surgery\nbuttonClicked|" .. toolCmd .. "\n\n")
                        end)
                    end
                    return true
                end

            elseif var[0] == "OnConsoleMessage" and type(var[1]) == "string" then
                local rawMsg = var[1]
                local cleanMsg = rawMsg:gsub("`.", ""):lower()

                if rawMsg:find("You are not allowed to perform surgery for a while") or cleanMsg:find("allowed") or cleanMsg:find("mistake") or cleanMsg:find("malpractice") or cleanMsg:find("debt to society") or cleanMsg:find("patient died") or cleanMsg:find("failed the surgery") then
                    UI.BypassMalpractice()
                    return true
                end

                if cleanMsg:find("already performing surgery") then
                    UI.IsSurging = false
                    UI.SurgStartTime = 0
                    UI.SurgAction = "Session Stuck! Rejoining World..."
                    UI.LocalChat("`c[WinProxy]: `4Stuck in session! `9Re-warping world to reset surgery state...")
                    local world = GetWorld() and GetWorld().name
                    if world and world ~= "" then
                        SendPacket(2, "action|input\n|text|/warp " .. world)
                    end
                    return true
                end

                if cleanMsg:find("recovering from surgery") or cleanMsg:find("is recovering") or cleanMsg:find("has recovered") then
                    UI.IsSurging = false
                    UI.SurgStartTime = 0
                    if UI.SurgTarget then
                        UI.LocalChat("`c[WinProxy]: `4Patient is recovering! `9Target locked (waiting for patient).")
                        UI.SurgAction = "Patient Recovering..."
                    end
                    return true
                end

                if UI.IsSurging and (cleanMsg:find("surgery was a success") or cleanMsg:find("treated the patient") or cleanMsg:find("completed the surgery")) then
                    UI.OnSurgerySuccess()
                    return true
                end
            end
        end

        if UI.AutoFish and var[0] == "OnConsoleMessage" and type(var[1]) == "string" then
            local cleanMsg = var[1]:gsub("`.", ""):lower()
            if cleanMsg:find("caught") or cleanMsg:find("reeled") or cleanMsg:find("there was") then UI.FishStats.caught = UI.FishStats.caught + 1
            elseif cleanMsg:find("got away") or cleanMsg:find("escaped") then UI.FishStats.missed = UI.FishStats.missed + 1 end
        end

        if UI.AutoCrime then
            if var[0] == "OnDialogRequest" and type(var[1]) == "string" then
                if var[1]:find("crimewave") or var[1]:find("Fighting Crime") then return true end
            elseif UI.IsFightingCrime and UI.CrimeTarget and var[0] == "OnConsoleMessage" and type(var[1]) == "string" then
                local rawMsg = var[1]
                if rawMsg:find("Reward:") then
                    UI.IsFightingCrime = false
                    UI.CrimeWon = true
                    UI.CrimeAction = "Won against " .. UI.CrimeTarget.name
                    UI.LocalChat("`c[WinProxy]: `2" .. UI.CrimeAction)
                    return true
                end
                
                local cleanMsg = rawMsg:gsub("`.", "")
                local losePattern = UI.CrimeTarget.name .. " crushed"
                if cleanMsg:find(losePattern) then
                    UI.IsFightingCrime = false
                    UI.CrimeWon = false
                    UI.CrimeAction = "Lost against " .. UI.CrimeTarget.name
                    UI.LocalChat("`c[WinProxy]: `4" .. UI.CrimeAction)
                    return true
                end
            end
        end
        
        if UI.ABP_IsScanningShop and type(var[1]) == "string" and (var[0] == "OnStoreRequest" or var[0] == "OnDialogRequest") then
            local storeData = var[1]
            if storeData:find("add_button") and storeData:find("buy_") then
                local secretName = storeData:match("end_dialog|([^|]*)|")
                if secretName then UI.ABP_ShopDialogName = secretName end

                for cmd, name in storeData:gmatch("add_button%s*|%s*(buy_[%w_]+)%s*|%s*([^|]+)") do
                    if not UI.ABP_AddedCmds[cmd] then
                        UI.ABP_AddedCmds[cmd] = true
                        local cleanName = name:gsub("`.", ""):gsub("\n", " "):match("^%s*(.-)%s*$")
                        table.insert(UI.ABP_Packs, {name = cleanName, cmd = cmd})
                        table.insert(UI.ABP_PackNames, cleanName)
                    end
                end
                return true 
            end
        end

        if var[0] == "OnSDBroadcast" and UI.BlockSDB then
            UI.LocalChat("`c[WinProxy]: `9Blocked incoming SDB dialog.")
            return true
        end
        
        if var[0] == "OnConsoleMessage" and type(var[1]) == "string" then
            local msg = var[1]
            local rawClean = msg:gsub("`.", "")
            
            -- Encrypt Chat Auto-Decrypt (Console Log)
            if UI.EncryptChat then
                local prefixStr, lastWord = msg:match("^(.-)(%S+)%s*$")
                
                if lastWord then
                    local cleanLast = lastWord:gsub("`.", "")
                    if #cleanLast >= 4 and #cleanLast % 4 == 0 and cleanLast:match("^[A-Za-z0-9+/=]+$") then
                        local b64Decoded = UI.Base64Decode(cleanLast)
                        if b64Decoded and b64Decoded ~= "" then
                            local decoded = UI.XORCipher(b64Decoded, UI.EncryptKey)
                            if decoded:match("^[%w%p%s]+$") then
                                if msg:find(">") or msg:find(":") then
                                    local cleanPrefix = prefixStr:gsub("CP:_PL:.-_CT:", "")
                                    cleanPrefix = cleanPrefix:gsub("%[W%]_", "[W]")
                                    
                                    local modifiedMsg = msg .. "\n`2(Decrypted) " .. cleanPrefix .. "`w" .. decoded
                                    SendVariantList({[0] = "OnConsoleMessage", [1] = modifiedMsg})
                                    return true
                                end
                            end
                        end
                    end
                end
            end

            local cleanMsg = rawClean:lower()

            if UI.BlockSB and rawClean:find("%*%* from %(.+%) in %[.+%] %*%* :") then
                return true
            end
            
            local isChat = cleanMsg:match("^%s*<")
            local isSys = cleanMsg:find("cp:_pl:0_oid:")
            
            if not isChat and not isSys then
                if UI.LogsEnabled then
                    local function GetItemColorCode(name)
                        if name:find("World Lock") then return "`9" end
                        if name:find("Diamond Lock") then return "`c" end
                        if name:find("Blue Gem Lock") then return "`e" end
                        if name:find("Black Gem Lock") then return "`b" end
                        return "`w"
                    end
                    
                    if rawClean:find("Collected ") then
                        local amount, itemName = rawClean:match("Collected%s+(%d+)%s+(.+)")
                        if amount and itemName then
                            itemName = itemName:gsub("%.%s*$", "")
                            local colorCode = GetItemColorCode(itemName)
                            UI.AddLog("Inventory", "`2Collected `0" .. amount .. " " .. colorCode .. itemName)
                            
                            if itemName:find("World Lock") or itemName:find("Diamond Lock") or itemName:find("Blue Gem Lock") or itemName:find("Black Gem Lock") then
                                UI.LocalChat("`c[WinProxy] `2Collected `0" .. amount .. " " .. colorCode .. itemName)
                            end

                            if UI.AutoCVLocks then
                                RunThread(function()
                                    UI.IsAutoCVRunning = true
                                    Sleep(250)
                                    
                                    if itemName:find("World Lock") and UI.GetItemCount(UI.GetIcon("Creativeps World Lock", 242)) >= 100 then
                                        SendPacketRaw(false, {type = 10, value = 242})
                                        UI.LocalChat("`c[WinProxy]: `2[Auto-CV] `9Converted 100 WL to 1 DL!")
                                        
                                    elseif itemName:find("Diamond Lock") and UI.GetItemCount(UI.GetIcon("Creativeps Diamond Lock", 1796)) >= 100 then
                                        local tx, ty = UI.GetNearestTelephone()
                                        if tx and ty then
                                            local packetStr = "action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|" .. tx .. "|\ny|" .. ty .. "|\nbuttonClicked|bglconvert"
                                            SendPacket(2, packetStr)
                                            UI.LocalChat("`c[WinProxy]: `2[Auto-CV] `9Converted 100 DL to 1 BlueGL via Telephone!")
                                        else
                                            UI.LocalChat("`c[WinProxy]: `4[Auto-CV Failed] `wNo Telephone nearby to convert DL!")
                                        end
                                        
                                    elseif itemName:find("Blue Gem Lock") and UI.GetItemCount(UI.GetIcon("Creativeps Blue Gem Lock", 7188)) >= 100 then
                                        SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bgl")
                                        UI.LocalChat("`c[WinProxy]: `2[Auto-CV] `9Converted 100 BlueGL to 1 BlackGL!")
                                    end
                                    
                                    Sleep(500)
                                    UI.IsAutoCVRunning = false
                                end)
                            end
                        end
                    elseif cleanMsg:find("%[winproxy%] dropped") or cleanMsg:find("%[winproxy%]: dropped") then
                        local amount, itemName = rawClean:match("Dropped%s+(%d+)%s+(.+)")
                        if amount and itemName then
                            itemName = itemName:gsub("%.%s*$", "")
                            UI.AddLog("Inventory", "`4Dropped `0" .. amount .. " " .. GetItemColorCode(itemName) .. itemName)
                        end
                    end
                end 
                
                if cleanMsg:find("merged 1 black gem lock") then
                    UI.LocalChat("`c[WinProxy]: `2Succeed `9Converted to `4100 `eCreativePS Blue Gem Locks`4!")
                    return true
                elseif cleanMsg:find("merged 100 blue gem lock") then
                    UI.LocalChat("`c[WinProxy]: `2Succeed `9Converted to `41 `bCreativePS Black Gem Lock`4!")
                    return true
                end
            end
        end

        if var[0] == "OnConsoleMessage" and type(var[1]) == "string" then
            local msg = var[1]
            if msg:find("spun the wheel") then return true end
            if msg:find(">> `5Super") then
                if msg:find("Used `$(%d+) Gems") then
                    UI.SBUseGems = true; UI.SBUseBGems = false
                    UI.SBUsedGems = tonumber(msg:match("Used `$(%d+) Gems")) or 0
                    UI.SBTotUsedGems = UI.SBTotUsedGems + UI.SBUsedGems
                elseif msg:find("Used `$(%d+) Black Gems") then
                    UI.SBUseBGems = true; UI.SBUseGems = false
                    UI.SBUsedBGems = tonumber(msg:match("Used `$(%d+) Black Gems")) or 0
                    UI.SBTotUsedBGems = UI.SBTotUsedBGems + UI.SBUsedBGems
                    UI.SBLeftBGems = tonumber(msg:match("`$(%d+)`` left")) or 0
                end
            end
            
            if msg:find("have a pending one") then UI.SBPending = true end
            
            if UI.SBEnabled and UI.SBSafeMode and msg:find("```w(.+)`` `%$World Locked``") then
                local lockedWorld = msg:match("```w(.+)`` `%$World Locked``")
                if lockedWorld ~= UI.SBWorld then
                    SendPacket(3, "action|join_request\nname|" .. UI.SBWorld .. "\ninvitedWorld|0")
                    return true
                end
            end
            
            if UI.SBEnabled and msg:find("Where would you like to go?") then
                SendPacket(3, "action|join_request\nname|" .. UI.SBWorld .. "\ninvitedWorld|0")
                return true
            end
        end

        -- ==========================================
        -- ==========================================
        if var[0] == "OnTalkBubble" and type(var[2]) == "string" then
            local bubbleTxt = var[2]
            
            if bubbleTxt:find("spun the wheel") then
                local colorCode, numStr = bubbleTxt:match("and got%s*(`[%w#^])(%d+)")
                local spinNum = bubbleTxt:gsub("`.", ""):match("and got (%d+)")
                local coloredSpin = (colorCode and numStr) and (colorCode .. numStr .. "`w") or (spinNum or "?")
                
                local pName = bubbleTxt:match("^(.-) spun the wheel") or "Unknown"
                local cleanName = pName:gsub("`.", "")
                
                -- Cleanup bubble prefix artifact if any
                if cleanName:sub(1,1) == "[" then cleanName = cleanName:sub(2) end
                
                -- Fast Console
                LogToConsole("`0[`2REAL`0] " .. cleanName .. " `0spun " .. coloredSpin .. "`0!")
                
                -- Update Name Tag with Last Spin
                if var[1] then
                    local netID = tonumber(var[1])
                    local realName = pName
                    local success, pList = pcall(GetPlayerList)
                    if success and pList then
                        for _, p in pairs(pList) do
                            if p.netid == netID and p.name then
                                realName = p.name
                                break
                            end
                        end
                    end
                    
                    if realName:sub(1,1) == "[" then realName = realName:sub(2) end
                    
                    -- Hapus angka spin yang sebelumnya sudah menempel
                    realName = realName:gsub(" `9%[`2%d+`9%]", "")
                    realName = realName:gsub(" `9%[`2%?`9%]", "")
                    
                    local newName = realName .. " `9[`2" .. (spinNum or "?") .. "`9]"
                    pcall(SendVariantList, {[0] = "OnNameChanged", [1] = newName}, netID)
                end
            end
            
            -- Encrypt Chat Auto-Decrypt (Talk Bubble)
            if UI.EncryptChat then
                local prefixStr, lastWord = bubbleTxt:match("^(.-)(%S+)%s*$")
                
                if lastWord then
                    local cleanLast = lastWord:gsub("`.", "")
                    if #cleanLast >= 4 and #cleanLast % 4 == 0 and cleanLast:match("^[A-Za-z0-9+/=]+$") then
                        local b64Decoded = UI.Base64Decode(cleanLast)
                        if b64Decoded and b64Decoded ~= "" then
                            local decoded = UI.XORCipher(b64Decoded, UI.EncryptKey)
                            if decoded:match("^[%w%p%s]+$") then
                                local modifiedBubble = "`2(Decrypted) " .. prefixStr .. "`w" .. decoded
                                SendVariantList({[0] = "OnTalkBubble", [1] = var[1], [2] = modifiedBubble, [3] = var[3] or 0})
                                return true
                            end
                        end
                    end
                end
            end
            
            if bubbleTxt:find("spun the wheel") then
                UI.AddLog("Casino", bubbleTxt)
                
                local clean = bubbleTxt:gsub("`.", "") 
                local num = clean:match("and got (%d+)")
                
                if num then
                    local isReal = not (bubbleTxt:find("<") or bubbleTxt:find("%[FAKE%]"))
                    local modifiedBubble = bubbleTxt
                    
                    if UI.CasinoMode > 0 then
                        modifiedBubble = UI.GetCasinoText(tonumber(num), isReal)
                    end
                    
                    SendVariantList({[0] = "OnTalkBubble", [1] = var[1], [2] = modifiedBubble, [3] = var[3] or 0})
                    
                    return true
                end
            end
        end
        
        if var[0] == "OnDialogRequest" and type(var[1]) == "string" then
            local d = var[1]
            
            -- Inject theme to all dialogs
            local themedD = UI.ApplyTheme(d)
            if themedD ~= d then
                var[1] = themedD
            end
            if UI.AutoBuyPack and type(d) == "string" then
                if d:find("Purchase Unsuccessful") or d:find("not enough space") then
                    local lowerD = d:lower()
                    if lowerD:find("space") or lowerD:find("room") or lowerD:find("inventory") or lowerD:find("full") then
                        UI.ABP_ForceDrop = true
                        UI.LocalChat("`c[WinProxy]: `e[INFO] `wInventory Full! Forcing Drop Phase...")
                    else
                        UI.AutoBuyPack = false
                        UI.LocalChat("`c[WinProxy]: `4[WARNING] `wPurchase Unsuccessful! (Out of Gems?)")
                        UI.LocalChat("`c[WinProxy]: `wAuto Buy Pack is now `4STOPPED`w.")
                    end
                    return true 
                elseif d:find("Thank you for your purchase!") then
                    return true
                end
            end

            if UI.VendFilter and d:lower():find("vend") then
                if d:find("%d+%s*x%s*[^\n|]-World Lock") then
                    d = d:gsub("[^\n]+", function(line)
                        local amt = line:match("(%d+)%s*x%s*[^\n|]-World Lock")
                        if amt then return UI.FormatVendPrice(amt) end
                        return line
                    end)
                    SendVariantList({[0] = "OnDialogRequest", [1] = d})
                    return true
                end
            end

            if UI.DonateMode then
                if d:find("gifts waiting") or d:find("How many to put in the box") or d:find("The box is currently empty%.") then
                    local bx, by = d:match("embed_data|x|(%d+)"), d:match("embed_data|y|(%d+)")
                    if bx and by then 
                        UI.DonateBoxX = bx; UI.DonateBoxY = by 
                        UI.LocalChat("`c[WinProxy]: `9Successfully set Donation Box position to X: `2" .. bx .. " `9Y: `2" .. by) 
                    end
                    return true 
                end
            end

            if UI.DonationFilter and d:find("gifts waiting") then
                d = d:gsub("add_label_with_icon|small|([^|]+)|left|(%d+)|", function(text, oldIconID)
                    local newIcon = oldIconID
                    local itemName = text:match("^(.-)%s+%(")
                    if itemName then
                        local lowerName = itemName:lower()
                        local foundID = UI.ItemDB[lowerName] or UI.ItemDB[lowerName:gsub("^creativeps ", "")]
                        if foundID then newIcon = tostring(foundID) end
                    end
                    return "add_label_with_icon|small|" .. text .. "|left|" .. newIcon .. "|"
                end)
                SendVariantList({[0] = "OnDialogRequest", [1] = d})
                return true
            end

            if UI.StorageFilter then
                -- [FIX] Deteksi ketat: pastikan ini dialog storage asli dan BUKAN tas inventory pemain
                local is_storage_dialog = (d:find("end_dialog|storage|") or d:find("Withdraw how many?")) and not d:find("'s Inventory")

                if is_storage_dialog then
                    if d:find("How many to store?") then
                        return false 
                    end

                    local raw_sx = tonumber(d:match("embed_data|x|(%d+)") or d:match("\nx|(%d+)"))
                    local raw_sy = tonumber(d:match("embed_data|y|(%d+)") or d:match("\ny|(%d+)"))
                    if raw_sx and raw_sx ~= 0 then UI.StorageBoxState.last_x = raw_sx end
                    if raw_sy and raw_sy ~= 0 then UI.StorageBoxState.last_y = raw_sy end
                    local sx = UI.StorageBoxState.last_x or 0
                    local sy = UI.StorageBoxState.last_y or 0

                    if d:find("Withdraw how many?") or d:find("add_button|withdraw|") or d:find("embed_data|hash|") then
                        local hash = d:match("embed_data|hash|([%w%d_]+)") or d:match("\nhash|([%w%d_]+)")
                        local current_item = UI.StorageBoxState.current_item
                        local parsed_max = tonumber(d:match("add_text_input|item_count||(%d+)|") or d:match("You have `?w?(%d+)"))
                        local max_count = parsed_max or (current_item and current_item.count) or 250

                        if UI.StorageBoxState.active_withdraw and hash then
                            local icon_id = current_item and current_item.icon_id or 0
                            local in_bag = (icon_id > 0) and UI.GetItemCount(icon_id) or 0
                            local can_hold = math.max(0, 250 - in_bag)
                            local to_take = math.min(can_hold, max_count)

                            if to_take <= 0 then
                                UI.StorageBoxState.active_withdraw = false
                                UI.StorageBoxState.suppress_reopen_until = os.clock() + 1.5
                                RunThread(function()
                                    Sleep(20)
                                    SendPacket(2, "action|dialog_return\ndialog_name|storage\nx|" .. sx .. "|\ny|" .. sy .. "|\nbuttonClicked|Exit\n")
                                end)
                                UI.LocalChat("`c[WinProxy]: `4[Storage] Backpack is full for remaining items!")
                                return true
                            end

                            local return_packet = "action|dialog_return\ndialog_name|storage\nx|" .. sx .. "|\ny|" .. sy .. "|\nhash|" .. hash .. "|\nbuttonClicked|withdraw\nitem_count|" .. to_take .. "\n"
                            RunThread(function()
                                Sleep(30)
                                SendPacket(2, return_packet)
                            end)
                            return true
                        elseif not UI.StorageBoxState.active_withdraw then
                            return false
                        end
                        return false
                    end

                    if d:find("add_item_picker|item|") or d:find("items stored") or d:find("Storage Box") then
                        local parsed_items = {}
                        local seen_hashes = {}

                        for btn_id, item_name, icon_id, count in d:gmatch("add_button_with_icon|([%w%d_%-]+)|(.-)|[%w_]*|(%d+)|(%d+)|") do
                            if btn_id and btn_id ~= "END_LIST" and not seen_hashes[btn_id] then
                                seen_hashes[btn_id] = true
                                local clean_btn = btn_id:gsub("^item_", "")
                                local clean_name = Filter(item_name):gsub("^%s+", ""):gsub("%s+$", "")
                                table.insert(parsed_items, {
                                    hash = clean_btn,
                                    raw_btn = btn_id,
                                    name = clean_name,
                                    count = tonumber(count) or 1,
                                    icon_id = tonumber(icon_id) or 0
                                })
                            end
                        end
                        
                        if #parsed_items == 0 then
                            for btn_id, item_name, icon_id in d:gmatch("add_button_with_icon|([%w%d_%-]+)|(.-)|[%w_]*|(%d+)|") do
                                if btn_id and btn_id ~= "END_LIST" and not seen_hashes[btn_id] then
                                    seen_hashes[btn_id] = true
                                    local clean_btn = btn_id:gsub("^item_", "")
                                    local clean_name = Filter(item_name):gsub("^%s+", ""):gsub("%s+$", "")
                                    table.insert(parsed_items, {
                                        hash = clean_btn,
                                        raw_btn = btn_id,
                                        name = clean_name,
                                        count = 1,
                                        icon_id = tonumber(icon_id) or 0
                                    })
                                end
                            end
                        end

                        local stored_label = d:match("add_label|small|`?w?([%d/]+%s*items?%s*stored%.)") or d:match("([%d/]+%s*items?%s*stored%.)") or (#parsed_items .. "/100 items stored.")

                        UI.StorageBoxState.item_queue = parsed_items
                        UI.StorageBoxState.last_x = sx
                        UI.StorageBoxState.last_y = sy

                        if UI.StorageBoxState.active_withdraw and UI.StorageBoxState.last_action_time and (os.time() - UI.StorageBoxState.last_action_time > 4) then
                            UI.StorageBoxState.active_withdraw = false
                        end

                        if UI.StorageBoxState.suppress_reopen_until and (os.clock() < UI.StorageBoxState.suppress_reopen_until) then
                            SendPacket(2, "action|dialog_return\ndialog_name|storage\nx|" .. sx .. "|\ny|" .. sy .. "|\nbuttonClicked|Exit\n")
                            return true
                        end

                        if UI.StorageBoxState.active_withdraw then
                            local next_item, can_hold = UI.GetNextWithdrawableStorageItem(parsed_items)
                            if next_item and can_hold > 0 then
                                UI.StorageBoxState.current_item = next_item
                                UI.StorageBoxState.last_action_time = os.time()
                                local btn_name = next_item.raw_btn or ("item_" .. next_item.hash)
                                RunThread(function()
                                    Sleep(30)
                                    SendPacket(2, "action|dialog_return\ndialog_name|storage\nx|" .. sx .. "|\ny|" .. sy .. "|\nbuttonClicked|" .. btn_name .. "\n")
                                end)
                                return true
                            else
                                UI.StorageBoxState.active_withdraw = false
                                UI.StorageBoxState.suppress_reopen_until = os.clock() + 1.5
                                RunThread(function()
                                    Sleep(20)
                                    SendPacket(2, "action|dialog_return\ndialog_name|storage\nx|" .. sx .. "|\ny|" .. sy .. "|\nbuttonClicked|Exit\n")
                                end)
                                if #parsed_items == 0 then
                                    UI.LocalChat("`c[WinProxy]: `2[Storage Box] All items taken successfully!")
                                else
                                    UI.LocalChat("`c[WinProxy]: `2[Storage Box] Take Everything done! `7(Remaining items full in bag)")
                                end
                                return true
                            end
                        end

                        local custom_dialog = "set_default_color|`o\n\n"
                        custom_dialog = custom_dialog .. "add_label_with_icon|big|`wStorage Box Xtreme````|left|6290|\n"
                        custom_dialog = custom_dialog .. "add_spacer|small|\n"
                        custom_dialog = custom_dialog .. "add_label|small|`w" .. stored_label .. "|left|\n"
                        custom_dialog = custom_dialog .. "add_spacer|small|\n"

                        if #parsed_items > 0 then
                            for _, it in ipairs(parsed_items) do
                                custom_dialog = custom_dialog .. "add_label_with_icon_button|small|`w" .. it.name .. " : " .. it.count .. "````|left|" .. it.icon_id .. "|" .. it.raw_btn .. "|\n"
                            end
                            custom_dialog = custom_dialog .. "add_spacer|small|\n"
                            custom_dialog = custom_dialog .. "add_button|take_all_sbox|Take Everything|noflags|0|0|\n"
                        else
                            custom_dialog = custom_dialog .. "add_textbox|`7No items stored in this box.|left|\n"
                            custom_dialog = custom_dialog .. "add_spacer|small|\n"
                        end

                        custom_dialog = custom_dialog .. "add_item_picker|item|`wDeposit Item``|`wChoose an item to store``\n"
                        custom_dialog = custom_dialog .. "embed_data|x|" .. sx .. "\n"
                        custom_dialog = custom_dialog .. "embed_data|y|" .. sy .. "\n"
                        custom_dialog = custom_dialog .. "end_dialog|storage|Exit||\n"

                        SendVariantList({ [0] = "OnDialogRequest", [1] = custom_dialog })
                        return true
                    end
                end
            end

            if d:find("'s Inventory") then
                local text = d:gsub("`.", "")
                local now = os.clock()
                local matched_netid = nil
                local matched_info = nil
                
                for nid, info in pairs(UI.PendingModalPull) do
                    if (now - info.timestamp) < 4.0 then
                        matched_netid = nid
                        matched_info = info
                        break
                    end
                end
                
                if matched_netid and matched_info then
                    UI.PendingModalPull[matched_netid] = nil 
                    
                    local bglbank = UI.ParseDialogNumber(text:match("Blue Gem Locks in the Bank:%s*([%d,]+)"))
                    local blackgl_count = UI.ParseDialogNumber(text:match("|" .. UI.GetIcon("Creativeps Black Gem Lock", 11550) .. "|([%d,]+)|") or text:match("|" .. UI.GetIcon("Creativeps Black Gem Lock", 11550) .. "|(%d+)"))
                    local bgl_count = UI.ParseDialogNumber(text:match("|" .. UI.GetIcon("Creativeps Blue Gem Lock", 7188) .. "|([%d,]+)|") or text:match("|" .. UI.GetIcon("Creativeps Blue Gem Lock", 7188) .. "|(%d+)"))
                    local dl_count = UI.ParseDialogNumber(text:match("|" .. UI.GetIcon("Creativeps Diamond Lock", 1796) .. "|([%d,]+)|") or text:match("|" .. UI.GetIcon("Creativeps Diamond Lock", 1796) .. "|(%d+)"))
                    local wl_count = UI.ParseDialogNumber(text:match("|" .. UI.GetIcon("Creativeps World Lock", 242) .. "|([%d,]+)|") or text:match("|" .. UI.GetIcon("Creativeps World Lock", 242) .. "|(%d+)"))
                    
                    local total_bgl_equiv = (blackgl_count * 100) + bglbank + bgl_count + (dl_count / 100) + (wl_count / 10000)
                    local min_modal = tonumber(UI.AutoPullMinModal) or 0
                    
                    if total_bgl_equiv >= min_modal then
                        SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. matched_netid .. "|\nbuttonClicked|pull")
                        RunThread(function()
                            Sleep(50)
                            SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. matched_netid .. "|\nbuttonClicked|pull")
                        end)
                        
                        if UI.WrenchPullText ~= "" then
                            local chatMsg = UI.WrenchPullText:gsub("{GrowID}", matched_info.name)
                            SendPacket(2, "action|input\n|text|" .. chatMsg)
                        end
                        UI.LocalChat("`c[WinProxy]: `2Auto Pulled `w" .. matched_info.name .. " `2(Modal: " .. string.format("%.2f", total_bgl_equiv) .. " BGL)")
                    else
                        UI.LocalChat("`c[WinProxy]: `4Skipped `w" .. matched_info.name .. " `4(Modal: " .. string.format("%.2f", total_bgl_equiv) .. " BGL < " .. min_modal .. " BGL)")
                    end
                    
                    if UI.ShowBal then
                        local modalMsg = UI.ParseInventorySummary(d)
                        if modalMsg then SendVariantList({[0] = "OnTextOverlay", [1] = modalMsg}) end
                    end
                    
                    return true 
                end
                
                if UI.ShowBal then
                    local modalMsg = UI.ParseInventorySummary(d)
                    if modalMsg then SendVariantList({[0] = "OnTextOverlay", [1] = modalMsg}); return true end
                end
            end

            if UI.FastDrop and d:lower():find("drop") and d:lower():find("you have") then
                local itemID = d:match("add_label_with_icon|big|.-|left|(%d+)") or d:match("embed_data|itemID|(%d+)")
                local count = d:match("you have (%d+)")
                if itemID and count then
                    SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|"..itemID.."|\nitem_count|"..count.."|\ncount|"..count)
                    return true 
                end
            end
            
            if UI.FastTrash and d:lower():find("destroy") and d:lower():find("you have") then
                local itemID = d:match("add_label_with_icon|big|.-|left|(%d+)") or d:match("embed_data|itemID|(%d+)")
                local count = d:match("you have (%d+)")
                if itemID and count then
                    SendPacket(2, "action|dialog_return\ndialog_name|trash\nitem_trash|"..itemID.."|\nitem_count|"..count.."|\ncount|"..count)
                    return true 
                end
            end

            if d:find("BGLs in the Bank") or d:find("Blue Gem Locks in the Bank") then
                local bal = d:match("You have (%d+) BGLs in the Bank") or d:match("Blue Gem Locks in the Bank: %`%$(%d+)")
                if bal then 
                    UI.BankBalance = tonumber(bal)
                    LogToConsole("`2[WinProxy]: `9Bank Balance Synced: `e" .. UI.BankBalance .. " BGLs")
                end
            end

            if UI.SBCopyText and d:find("add_text_input") and d:find("display_text||") then
                local left, right = d:find("display_text||")
                if left then
                    local textsign = d:find("|", right + 1)
                    if textsign then
                        local text = d:sub(right + 1, textsign - 1)
                        UI.SBText = text
                        UI.LocalChat("`c[WinProxy]: `2Success `0Set SB TEXT: " .. text)
                        return true
                    end
                end
            end
            
            if UI.TeleMode > 0 then
                if d:find("Wow, that's fast delivery.")then return true 
                elseif d:find("dialog_name|telephone") then
                    local tx = d:match("embed_data|x|(%d+)")
                    local ty = d:match("embed_data|y|(%d+)")
                    if tx and ty then
                        local packetStr = "action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|" .. tx .. "|\ny|" .. ty .. "|\nbuttonClicked|"
                        if UI.TeleMode == 1 then SendPacket(2, packetStr .. "dlconvert")
                        elseif UI.TeleMode == 2 then SendPacket(2, packetStr .. "bglconvert2")
                        elseif UI.TeleMode == 3 then SendPacket(2, packetStr .. "bglconvert")
                        elseif UI.TeleMode == 4 then SendPacket(2, packetStr .. "getchamp")
                        elseif UI.TeleMode == 5 then SendPacket(2, packetStr .. "getchamp2")
                        elseif UI.TeleMode == 6 then SendPacket(2, packetStr .. "getchamp3") end
                    end
                    return true 
                end
            end

            if d:find("add_button|trade_accept|") then
                if UI.TradeAutoAccept then SendPacket(2, "action|dialog_return\ndialog_name|trade_accept") end
            elseif d:find("add_button|trade_confirm|") then
                if UI.TradeAutoConfirm then SendPacket(2, "action|dialog_return\ndialog_name|trade_confirm") end
            end
        end
    end
    return false
end


-- ==========================================
-- HOOK : Tank Update
-- ==========================================

function UI.OnTankPacket(pkt)
    if UI.AutoFish and pkt.type == 17 then
        UI.FishBite = true
    end

    if not UI.LogsEnabled then return false end 

    if pkt.type == 14 and pkt.netid == -1 and GetLocal() ~= nil and pkt.snetid == GetLocal().netid then
        local count = math.floor(pkt.padding4 or 0)
        local itemID = pkt.value or 0
        local itemName = "Item ID " .. itemID
        
        local success, itemData = pcall(function() return GetItemInfo(itemID) end)
        if success and itemData and itemData.name then itemName = itemData.name end
        
        if count > 0 then
            local colorCode = "`w"
            if itemName:find("World Lock") then colorCode = "`9"
            elseif itemName:find("Diamond Lock") then colorCode = "`c"
            elseif itemName:find("Blue Gem Lock") then colorCode = "`e"
            elseif itemName:find("Black Gem Lock") then colorCode = "`b" end
            
            UI.AddLog("Inventory", "`4Dropped `0" .. count .. " " .. colorCode .. itemName)
        end
    end
    return false
end


-- ==========================================
-- HOOK : Raw Packets
-- ==========================================

local function is_shift_held()
    local is_down = false
    if isWindows and type(GetAsyncKeyState) == "function" then
        local lshift = tonumber(GetAsyncKeyState(160)) or 0
        local rshift = tonumber(GetAsyncKeyState(161)) or 0
        local shift  = tonumber(GetAsyncKeyState(16))  or 0
        is_down = (lshift < 0 or lshift >= 32768 or rshift < 0 or rshift >= 32768 or shift < 0 or shift >= 32768)
    end
    return is_down
end

local function is_ctrl_held()
    local is_down = false
    if isWindows and type(GetAsyncKeyState) == "function" then
        local lctrl = tonumber(GetAsyncKeyState(162)) or 0
        local rctrl = tonumber(GetAsyncKeyState(163)) or 0
        local ctrl  = tonumber(GetAsyncKeyState(17))  or 0
        is_down = (lctrl < 0 or lctrl >= 32768 or rctrl < 0 or rctrl >= 32768 or ctrl < 0 or ctrl >= 32768)
    end
    return is_down
end

local palette = UI.GetDialogColorPalette()
for _, entry in ipairs(palette) do
    DialogActions[entry.id] = function(str)
        UI.DialogBg = entry.bg
        UI.DialogBorder = entry.border
        UI.SaveConfig(true)
        UI.ChangeDialogColor()
    end
end

local function OnSendPacketRaw(pkt)
    if pkt.type == 11 and UI.AntiPickup then return true end

    if UI.BTK_SelectingTarget and pkt.type == 3 and pkt.px and pkt.py then
        if pkt.px >= 0 and pkt.px < 100 and pkt.py >= 0 and pkt.py < 60 then
            UI.SetBTKCoordByTouch(UI.BTK_SelectingTarget, pkt.px, pkt.py)
            return true
        end
    end

    if (is_shift_held() or is_ctrl_held()) and pkt.type == 3 then
        return true
    end

    if UI.TPDisplay and pkt.type == 3 and pkt.value == 18 then
        if pkt.px and pkt.py then
            local target_tile = GetTile(pkt.px, pkt.py)
            local target_fg = target_tile and target_tile.fg or 0
            
            if target_fg == 1422 or target_fg == 9268 then
                RunThread(function()
                    local lp = GetLocal()
                    if lp and lp.pos then
                        local originX = math.floor(lp.pos.x / 32)
                        local originY = math.floor(lp.pos.y / 32)
                        
                        FindPath(pkt.px, pkt.py)
                        Sleep(150)
                        
                        FindPath(originX, originY)
                    end
                end)
                return true
            end
        end
    end
    return false
end

-- ==========================================
-- HOOK : World Touch
-- ==========================================

function OnWorldTouch_WrenchPull(position, mouse_down)
    if not mouse_down then return false end
    if position == nil or position.x == nil or position.y == nil then return false end

    if UI.AutoPullSettingSlot > 0 then
        local clickX = math.floor(position.x / 32)
        local clickY = math.floor(position.y / 32)
        UI.AutoPullPos[UI.AutoPullSettingSlot] = {x = clickX, y = clickY}
        UI.LocalChat("`c[WinProxy]: `9Auto Pull Pos `2" .. UI.AutoPullSettingSlot .. " `9set to `2(" .. clickX .. ", " .. clickY .. ")")
        UI.AutoPullSettingSlot = 0
        UI.SaveConfig(true)
        return true
    end

    if UI.BTK_SelectingTarget then
        local clickX = math.floor(position.x / 32)
        local clickY = math.floor(position.y / 32)
        if clickX >= 0 and clickX < 100 and clickY >= 0 and clickY < 60 then
            UI.SetBTKCoordByTouch(UI.BTK_SelectingTarget, clickX, clickY)
            return true
        end
    end

    if is_shift_held() then
        local clickX = math.floor(position.x / 32)
        local clickY = math.floor(position.y / 32)

        RunThread(function()
            FindPath(clickX, clickY)

            local waited = 0
            while waited < 4000 do
                local ok, lp = pcall(GetLocal)
                if ok and lp and lp.pos then
                    local nowX = math.floor(lp.pos.x / 32)
                    local nowY = math.floor(lp.pos.y / 32)
                    if nowX == clickX and nowY == clickY then
                        break
                    end
                end
                Sleep(50)
                waited = waited + 50
            end
            
        end)
        return true
    end

    local ctrl_state = 0
    
    if isWindows and type(GetAsyncKeyState) == "function" then
        ctrl_state = tonumber(GetAsyncKeyState(0x11)) or 0
    end
    
    if ctrl_state < 0 or ctrl_state >= 32768 then
        local clickX = math.floor(position.x / 32)
        local clickY = math.floor(position.y / 32)
        UI.LocalChat("`c[WinProxy]: `wCollect-only at (" .. clickX .. ", " .. clickY .. ")")
        local isObjSuccess, objList = pcall(GetObjectList)
        if isObjSuccess and objList then
            local maxDistSq = 64 * 64
            for _, obj in pairs(objList) do
                if obj and obj.pos and obj.oid then
                    local dx = obj.pos.x - position.x
                    local dy = obj.pos.y - position.y
                    local distSq = (dx * dx) + (dy * dy)
                    if distSq <= maxDistSq then
                        SendPacketRaw(false, {
                            type = 11,
                            value = obj.oid,
                            x = obj.pos.x,
                            y = obj.pos.y
                        })
                    end
                end
            end
        end
        return true
    end

    if UI.WrenchMode ~= 1 then
        return false
    end

    local success, player_items = pcall(GetPlayerItems)
    if not success or not player_items or not player_items.backpack then
        return false
    end
    local selected = tonumber(player_items.backpack.selected) or 0
    if selected ~= 32 then
        return false
    end

    local target = UI.FindClosestPlayer(position)
    if not target then
        return false
    end

    local targetNetID = target.netID or target.netid
    local targetUserID = target.userid
    if not targetNetID then
        return false
    end

    SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. targetNetID .. "|\nbuttonClicked|pull")
    local pName = UI.GetPlayerNameByNetID(targetNetID)
    if UI.WrenchPullText ~= "" then
        local chatMsg = UI.WrenchPullText:gsub("{GrowID}", pName)
        SendPacket(2, "action|input\n|text|" .. chatMsg)
    end
    if UI.ShowBal then
        RunThread(function()
            Sleep(250)
            SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. targetNetID .. "|\nbuttonClicked|viewinv")
        end)
    end
    return true
end

-- ==========================================
-- STARTUP : Hook Registration & Init Thread
-- ==========================================

local function SafeRenderImGui()
    local success, err = pcall(UI.RenderImGui)
    if not success then
        if not UI.ErrorSpamGuard or (os.time() - UI.ErrorSpamGuard > 3) then
            LogToConsole("`4[ImGui Error Caught]: `w" .. tostring(err))
            UI.ErrorSpamGuard = os.time()
        end
    end
end

AddHook("OnDraw", "UIManager_Draw", SafeRenderImGui)
AddHook("onsendpacket", "UIManager_Packet", UI.OnOutgoingPacket)
AddHook("onvariant", "UIManager_Variant", UI.OnVariant)
AddHook("onprocesstankupdatepacket", "UIManager_TankPacket", UI.OnTankPacket)
AddHook("onsendpacketraw", "UIManager_Raw", OnSendPacketRaw)
AddHook("onworldtouch", "OnWorldTouch_WrenchPull", OnWorldTouch_WrenchPull)

RunThread(function()
    LogToConsole("`9[WinProxy]: `bLoading config from: `w" .. UI.ConfigFileName)
    local loaded = UI.LoadConfig()
    
    if loaded then 
        LogToConsole("`9[WinProxy]: `2Config loaded successfully. Merging settings...") 
    end

    LogToConsole("`9[WinProxy]: `bBuilding Item Database cache in background...")
    for i = -3000, 100000 do
        local success, item = pcall(GetItemInfo, i)
        if success and item and item.name then
            UI.ItemDB[item.name:lower()] = i
        end
        if math.abs(i) % 1000 == 0 then Sleep(10) end
    end

    LogToConsole("`9[WinProxy]: `2Script was Started successfully.")
    Sleep(500) 
    
    local myPlayer = GetLocal()
    if myPlayer and myPlayer.name then
        UI.LocalChat("`cWinProxy `wis `2Active !")
        SendAuthNotification("Authorized")
        UI.DownloadAsset(UI.BannerURL, UI.BannerSavePath)
        UI.ShowMainDialog()
    end
end)

-- ==========================================
-- UNUSED / DEAD CODE
-- ==========================================
