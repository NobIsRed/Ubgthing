local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")
local VIM = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

local WEBHOOK_URL = "https://discord.com/api/webhooks/1495231530140696768/lyQMU0RhiuHWbVYx7XcaGVsWSkPAxiBUXx5VLXuGlNJSnHR3Zl6oOpvLsPHEvFTXlHSg"
local WEBHOOK_USERNAME = "UBG Stats"
local MAIN_WEBHOOK_ACCOUNT = "GHHTWHOWR"
local COLOR_CURRENT = 3447003
local COLOR_POS = 3066993
local COLOR_NEG = 15158332
local COLOR_MIX = 16776960
local UBG_INTERVAL = 5

local PADS = {
    ["Pad 1"] = Vector3.new(-8, 0, -161),
    ["Pad 2"] = Vector3.new(16, 0, -162),
    ["Pad 3"] = Vector3.new(18, 0, -140),
    ["Pad 4"] = Vector3.new(17, 0, -118),
}

-- ===== TARGET WHITELIST =====
local TARGET_WHITELIST = {
    ["GHHTWHOWR"]    = true,
    ["GHfhahfiuaf2"] = true,
    ["GHfhahfiuaf3"] = true,
    ["NoobIsRedI"]   = true,
}
local WHITELIST_LOWER = {}
for name in pairs(TARGET_WHITELIST) do
    WHITELIST_LOWER[name:lower()] = name
end

local MY_NAME = LP.Name
local MY_NAME_LOWER = MY_NAME:lower()
local IS_MAIN_ACCOUNT = (MY_NAME == MAIN_WEBHOOK_ACCOUNT)

getgenv().SelectedPad = getgenv().SelectedPad or "Pad 1"
getgenv().PadPosition = PADS[getgenv().SelectedPad] or PADS["Pad 1"]

local function isPad2()
    local p = getgenv().SelectedPad
    return p == "Pad 2" or p == "Pad 4"
end

local MATCH_END_DEBOUNCE = 2.0
local TP_OFFSET = 4
local COMBO_PAUSE_MIN = 0.20
local COMBO_PAUSE_MAX = 0.50
local BLOCK_KEY = Enum.KeyCode.F
local BLOCK_DURATION = 2.0
local BLOCK_COOLDOWN = 3.5
local COUNTER_DURATION = 1.2
local STAMINA_LOW = 20
local STAMINA_BLOCK_DUR = 2.0
local STAMINA_BLOCK_CD = 2.5
local DODGE_CHECK_INTERVAL = 0.20
local DODGE_CHANCE = 0.55
local DODGE_HOLD = 0.12
local DODGE_CHAIN_CHANCE = 0.50
local DODGE_TRIPLE_CHANCE = 0.20
local DODGE_CHAIN_DELAY = 0.08
local DODGE_JUMP_ONLY_CHANCE = 0.15
local DODGE_KEYS = {
    Enum.KeyCode.A, Enum.KeyCode.D,
    Enum.KeyCode.A, Enum.KeyCode.D,
    Enum.KeyCode.S, Enum.KeyCode.W,
}

local COMBOS = {
    { {0, 0.08}, {0, 0.08}, {0, 0.08}, {1, 0.12}, {1, 0.15} },
    { {0, 0.07}, {0, 0.07}, {0, 0.07}, {0, 0.08}, {1, 0.15} },
    { {0, 0.08}, {0, 0.10}, {1, 0.20} },
    { {0, 0.06}, {0, 0.06}, {0, 0.06}, {0, 0.06}, {0, 0.10} },
    { {0, 0.055},{0, 0.055},{0, 0.055},{0, 0.055},{0, 0.055},{0, 0.10} },
    { {0, 0.09}, {1, 0.12}, {0, 0.09}, {1, 0.12} },
    { {0, 0.08}, {1, 0.10}, {0, 0.08}, {1, 0.10}, {0, 0.10} },
    { {1, 0.10}, {0, 0.08}, {0, 0.08}, {1, 0.15} },
    { {1, 0.09}, {0, 0.07}, {1, 0.09}, {0, 0.07}, {1, 0.15} },
    { {0, 0.08}, {1, 0.08}, {0, 0.08}, {1, 0.08}, {0, 0.08}, {1, 0.15} },
    { {1, 0.10}, {0, 0.07}, {0, 0.07}, {0, 0.07}, {1, 0.15} },
    { {1, 0.09}, {1, 0.10}, {0, 0.07}, {0, 0.07}, {0, 0.10} },
    { {0, 0.07}, {0, 0.07}, {0, 0.07}, {1, 0.10}, {1, 0.10}, {0, 0.10} },
    { {0, 0.07}, {0, 0.07}, {1, 0.30}, {0, 0.08}, {1, 0.15} },
    { {0, 0.06}, {0, 0.06}, {0, 0.06}, {1, 0.28} },
}
local COUNTER_COMBO = {
    {1, 0.06}, {0, 0.05}, {1, 0.06}, {0, 0.05}, {0, 0.05}, {1, 0.10},
}

getgenv().AutoTP = false
getgenv().AutoLight = false
getgenv().AutoDodge = true
getgenv().AutoBlock = true
getgenv().TPBusy = false
getgenv().TpToOppDone = false
getgenv().InMatch = false
getgenv().Blocking = false
getgenv().Countering = false
getgenv().Dodging = false
getgenv().ComboIdx = 1
getgenv().DodgeCount = 0
getgenv().CounterCount = 0
getgenv().StaminaBlocks = 0
getgenv().MatchStartTick = nil
getgenv().WebhookSent = 0
getgenv().WebhookFailed = 0
getgenv().HttpMethod = "?"
getgenv().WebhookToggle = getgenv().WebhookToggle or true
getgenv().WebhookMode = getgenv().WebhookMode or "MAIN"
getgenv().LastWebhookResult = "none"

-- ===== TARGET LOCK STATE =====
-- Auto: nếu tên mình nằm trong whitelist -> bật lock, ngược lại -> tắt
if getgenv().TargetLock == nil then
    getgenv().TargetLock = WHITELIST_LOWER[MY_NAME_LOWER] ~= nil
end
getgenv().RejectBusy = false
getgenv().RejectedCount = getgenv().RejectedCount or 0
getgenv().LastRejectedName = nil
getgenv().LastRejectedAt = 0

-- ===== WEBHOOK NOTIFY TOGGLES =====
-- Cash mặc định OFF, Spins & Lucky mặc định ON
if getgenv().NotifyCash  == nil then getgenv().NotifyCash  = false end
if getgenv().NotifySpins == nil then getgenv().NotifySpins = true  end
if getgenv().NotifyLucky == nil then getgenv().NotifyLucky = true  end

local httpRequest, httpMethod = nil, "none"
for _, c in ipairs({
    { "syn.request", (syn and syn.request) },
    { "fluxus.request", (fluxus and fluxus.request) },
    { "krnl.request", (krnl and krnl.request) },
    { "http_request", http_request },
    { "http.request", (http and http.request) },
    { "request", request },
}) do
    if type(c[2]) == "function" then
        httpRequest, httpMethod = c[2], c[1]
        break
    end
end
if not httpRequest then httpMethod = "HttpService:RequestAsync" end
getgenv().HttpMethod = httpMethod

local function loadRayfield()
    local url = "https://sirius.menu/rayfield"
    local ok, result = pcall(function()
        local src
        if syn and syn.request then
            src = syn.request({Url=url, Method="GET"}).Body
        elseif fluxus and fluxus.request then
            src = fluxus.request({Url=url, Method="GET"}).Body
        elseif request then
            src = request({Url=url, Method="GET"}).Body
        elseif http_request then
            src = http_request({Url=url, Method="GET"}).Body
        elseif http and http.request then
            src = http.request({Url=url, Method="GET"}).Body
        elseif game.HttpGet then
            src = game:HttpGet(url)
        else
            error("no HTTP")
        end
        return loadstring(src)()
    end)
    if ok and result then return result end
    warn("[RAYFIELD] Load failed: " .. tostring(result))
    return nil
end
local Rayfield = loadRayfield()
if not Rayfield then
    warn("[AI v28] Rayfield fail, stop")
    return
end
print("[AI v28] Rayfield loaded, HTTP=" .. httpMethod)
print(string.format("[AI v28] ME=%s | Whitelist: GHHTWHOWR, GHfhahfiuaf2, GHfhahfiuaf3, NoobIsRedI | TargetLock default=%s",
    MY_NAME, tostring(getgenv().TargetLock)))

local function checkWebhookReason()
    if getgenv().WebhookMode == "ALL" then return true, "ALL mode" end
    if not IS_MAIN_ACCOUNT then return false, "not main (mode=MAIN)" end
    if not getgenv().WebhookToggle then return false, "toggle OFF (mode=MAIN)" end
    return true, "main + toggle ON"
end

local function sendWebhook(payload)
    local ok, reason = checkWebhookReason()
    if not ok then
        getgenv().LastWebhookResult = "skip: " .. reason
        print("[WEBHOOK] skip: " .. reason)
        return false, reason
    end
    payload.username = WEBHOOK_USERNAME
    local encOk, body = pcall(HttpService.JSONEncode, HttpService, payload)
    if not encOk then
        getgenv().WebhookFailed = getgenv().WebhookFailed + 1
        getgenv().LastWebhookResult = "encode fail"
        return false, "encode"
    end
    local sendOk, result
    if httpRequest then
        sendOk, result = pcall(httpRequest, {
            Url = WEBHOOK_URL, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" }, Body = body,
        })
    else
        sendOk, result = pcall(HttpService.RequestAsync, HttpService, {
            Url = WEBHOOK_URL, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" }, Body = body,
        })
    end
    if not sendOk then
        getgenv().WebhookFailed = getgenv().WebhookFailed + 1
        getgenv().LastWebhookResult = "send fail"
        warn("[WEBHOOK] send fail: " .. tostring(result))
        return false, "send"
    end
    local status
    if type(result) == "table" then
        status = result.StatusCode or (result.Status and result.Status.Code)
    end
    if status and (status < 200 or status >= 300) then
        getgenv().WebhookFailed = getgenv().WebhookFailed + 1
        getgenv().LastWebhookResult = "HTTP " .. tostring(status)
        return false, "http_" .. tostring(status)
    end
    getgenv().WebhookSent = getgenv().WebhookSent + 1
    getgenv().LastWebhookResult = "OK (" .. reason .. ")"
    print("[WEBHOOK] sent OK (" .. reason .. ")")
    return true, reason
end

local function deepFind(root, ...)
    for _, name in ipairs({...}) do
        if not root then return nil end
        root = root:FindFirstChild(name)
    end
    return root
end

local function readUBG()
    local ss = deepFind(PG, "Main", "StyleShop")
    if not ss then return nil end
    local s = deepFind(ss, "Spin", "SpinsLeft")
    local c = deepFind(ss, "Money", "Cash")
    local l = deepFind(ss, "LuckySpin", "SpinButton", "Earned")
    if not (s and c and l) then return nil end
    return { spins = s.Text, cash = c.Text, lucky = l.Text }
end

local function waitForUBG(t)
    t = t or 2
    local t0 = tick()
    while tick() - t0 < t do
        if readUBG() then return true end
        task.wait(0.2)
    end
    return false
end

local function parseNum(raw)
    if not raw or raw == "" then return nil end
    local s = tostring(raw):gsub("[,%s]", "")
    local mult, sfx = 1, s:match("([KkMmBb])$")
    if sfx then
        local l = sfx:lower()
        if l == "k" then mult = 1e3
        elseif l == "m" then mult = 1e6
        elseif l == "b" then mult = 1e9 end
        s = s:gsub("[KkMmBb]$", "")
    end
    s = s:gsub("[^%d%-%.]", "")
    if s == "" or s == "-" or s == "." or s == "-." then return nil end
    local n = tonumber(s)
    return n and n * mult or nil
end

local function fmtNum(n)
    local sign = ""
    if n < 0 then sign = "-"; n = -n end
    local s = tostring(math.floor(n + 0.5))
    return sign .. s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function footerText()
    return string.format("UBG Stats | %s | %s", MY_NAME, os.date("%H:%M:%S"))
end

local function webhookCurrently()
    local ubg = readUBG()
    if not ubg then return false, "no UBG labels" end
    return sendWebhook({
        embeds = {{
            title = "UBG Stats - Currently",
            color = COLOR_CURRENT,
            fields = {
                { name = "Spins", value = "**" .. (ubg.spins ~= "" and ubg.spins or "?") .. "**", inline = true },
                { name = "Cash", value = "**" .. (ubg.cash ~= "" and ubg.cash or "?") .. "**", inline = true },
                { name = "Lucky Spins", value = "**" .. (ubg.lucky ~= "" and ubg.lucky or "?") .. "**", inline = true },
            },
            timestamp = DateTime.now():ToIsoDate(),
            footer = { text = footerText() },
        }},
    })
end

local function webhookStatsChanged(fields, pos, neg)
    local color
    if neg == 0 then color = COLOR_POS
    elseif pos == 0 then color = COLOR_NEG
    else color = COLOR_MIX end
    return sendWebhook({
        embeds = {{
            title = "UBG Stats Changed",
            color = color,
            fields = fields,
            timestamp = DateTime.now():ToIsoDate(),
            footer = { text = footerText() },
        }},
    })
end

local function getHRP()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function readRawOpponent()
    local raw
    pcall(function()
        local st = workspace:FindFirstChild("States")
        if not st then return end
        local me = st:FindFirstChild(MY_NAME)
        if not me then return end
        local d = me:FindFirstChild("CharacterData")
        if not d then return end
        local o = d:FindFirstChild("Opponent")
        if o then raw = o.Value end
    end)
    return raw
end

local function normalizeName(v)
    if v == nil then return nil end
    local t = typeof(v)
    if t == "string" then
        local s = v:gsub("^%s+", ""):gsub("%s+$", "")
        if s ~= "" then return s end
        return nil
    end
    if t == "Instance" then
        if v.Name and v.Name ~= "" then return v.Name end
        return nil
    end
    if t == "number" then
        local p = Players:GetPlayerByUserId(v)
        if p then return p.Name end
        return nil
    end
    if t == "table" and v.Name then
        return tostring(v.Name)
    end
    return nil
end

-- ===== TARGET LOCK HELPERS =====
local function readRawOpponentName()
    local raw = readRawOpponent()
    local name = normalizeName(raw)
    if not name or name == "" then return nil end
    if name:lower() == MY_NAME_LOWER then return nil end
    return name
end

local function isWhitelisted(name)
    if not name then return false end
    return WHITELIST_LOWER[name:lower()] ~= nil
end

-- TargetLock ON  -> chỉ trả whitelist (nil = không tính là trận)
-- TargetLock OFF -> trả ai cũng được
local function readOpponentName()
    local name = readRawOpponentName()
    if not name then return nil end
    local canonical = WHITELIST_LOWER[name:lower()]
    if getgenv().TargetLock then
        return canonical
    else
        return canonical or name
    end
end

local function getOpponentHRP()
    local name = readOpponentName()
    if not name then return nil end
    local opp = Players:FindFirstChild(name)
    if not opp or not opp.Character then return nil end
    local hum = opp.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return nil end
    return opp.Character:FindFirstChild("HumanoidRootPart")
end

local function readMyHealth()
    local h
    pcall(function()
        local st = workspace:FindFirstChild("States")
        if not st then return end
        local me = st:FindFirstChild(MY_NAME)
        if not me then return end
        local d = me:FindFirstChild("CharacterData")
        if not d then return end
        local hp = d:FindFirstChild("Health")
        if hp then h = hp.Value end
    end)
    if h ~= nil then return h end
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health
end

local function readMyStamina()
    local s
    pcall(function()
        local st = workspace:FindFirstChild("States")
        if not st then return end
        local me = st:FindFirstChild(MY_NAME)
        if not me then return end
        local d = me:FindFirstChild("CharacterData")
        if not d then return end
        local stv = d:FindFirstChild("Stamina")
        if stv then s = stv.Value end
    end)
    return s
end

local function isMatchActive()
    return readOpponentName() ~= nil
end

local function clickAt(sx, sy, button)
    pcall(function()
        VIM:SendMouseButtonEvent(sx, sy, button, true, nil, 0)
        VIM:SendMouseButtonEvent(sx, sy, button, false, nil, 0)
    end)
end

local function clickTarget(button)
    local target = getOpponentHRP()
    if not target then return false end
    local cam = workspace.CurrentCamera
    if not cam then return false end
    local sp, onScreen = cam:WorldToViewportPoint(target.Position)
    if not onScreen then return false end
    local vp = cam.ViewportSize
    if sp.X < 0 or sp.Y < 0 or sp.X > vp.X or sp.Y > vp.Y then return false end
    clickAt(sp.X, sp.Y, button)
    return true
end

local function keyEvent(pressed, key)
    pcall(function() VIM:SendKeyEvent(pressed, key, false, nil) end)
end

local function tpToOpponentOnce()
    local hrp = getHRP()
    local target = getOpponentHRP()
    if not hrp or not target then return false, "no hrp/target" end
    local dir = hrp.Position - target.Position
    if dir.Magnitude < 0.1 then dir = Vector3.new(0, 0, 1) end
    hrp.CFrame = CFrame.lookAt(target.Position + dir.Unit * TP_OFFSET, target.Position)
    return true
end

-- ===== REJECT: reset + TP to pad =====
local function rejectOpponent(name)
    if getgenv().RejectBusy then return end
    getgenv().RejectBusy = true
    getgenv().LastRejectedName = name
    getgenv().LastRejectedAt = tick()
    getgenv().RejectedCount = (getgenv().RejectedCount or 0) + 1
    print("[LOCK] Rejecting non-whitelist: " .. tostring(name))

    task.spawn(function()
        pcall(function()
            local char = LP.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.Health = 0 end
            end
        end)

        task.wait(2.0)
        local hrp
        for _ = 1, 10 do
            hrp = getHRP()
            if hrp then break end
            task.wait(0.3)
        end

        if hrp then
            local p = getgenv().PadPosition
            hrp.CFrame = CFrame.new(p.X, p.Y + 50, p.Z)
            for _ = 1, 25 do
                if hrp.Position.Y <= p.Y + 1 then break end
                hrp.CFrame = CFrame.new(p.X, hrp.Position.Y - 5, p.Z)
                task.wait(0.08)
            end
        end

        pcall(function()
            Rayfield:Notify({
                Title    = "🔒 TARGET LOCK",
                Content  = "Rejected " .. tostring(name) .. " -> back to pad",
                Duration = 3,
                Image    = 4483362458,
            })
        end)

        task.wait(1.0)
        getgenv().RejectBusy = false
    end)
end

local Window = Rayfield:CreateWindow({
    Name = "AI v28 BATTLE",
    LoadingTitle = "AI v28 BATTLE",
    LoadingSubtitle = "Loading",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)
MainTab:CreateSection("Account")
local SelfLabel = MainTab:CreateLabel(
    string.format("%s | PAD: %s | Opp: none", MY_NAME, getgenv().SelectedPad), 4483362458)

MainTab:CreateSection("Pad Selection")

local padOptions = {}
for name, _ in pairs(PADS) do
    table.insert(padOptions, name)
end
table.sort(padOptions)

MainTab:CreateDropdown({
    Name = "Chọn PAD",
    Options = padOptions,
    CurrentOption = { getgenv().SelectedPad },
    MultipleOptions = false,
    Callback = function(opt)
        local v = type(opt) == "table" and opt[1] or opt
        if not v or not PADS[v] then return end
        getgenv().SelectedPad = v
        getgenv().PadPosition = PADS[v]
        print(string.format("[PAD] Selected: %s = (%.0f, %.0f, %.0f) | TP-to-opp: %s",
            v, PADS[v].X, PADS[v].Y, PADS[v].Z, isPad2() and "YES" or "NO"))
        pcall(function()
            Rayfield:Notify({
                Title = "PAD changed",
                Content = v .. (isPad2() and " (TP to opp)" or " (no TP)"),
                Duration = 2,
                Image = 4483362458,
            })
        end)
    end,
})

MainTab:CreateButton({
    Name = "🔄 Teleport về PAD đã chọn",
    Callback = function()
        task.spawn(function()
            local hrp = getHRP()
            if not hrp then return end
            local p = getgenv().PadPosition
            hrp.CFrame = CFrame.new(p.X, p.Y + 50, p.Z)
            for _ = 1, 20 do
                if hrp.Position.Y <= p.Y + 1 then break end
                hrp.CFrame = CFrame.new(p.X, hrp.Position.Y - 5, p.Z)
                task.wait(0.08)
            end
            pcall(function()
                Rayfield:Notify({
                    Title = "Teleported",
                    Content = getgenv().SelectedPad,
                    Duration = 2,
                    Image = 4483362458,
                })
            end)
        end)
    end,
})

MainTab:CreateSection("Automation")

local _codeUpdate = false
local TPToggle, LightToggle, DodgeToggle, BlockToggle, TargetLockToggle

local function uiSetTP(v)
    if _codeUpdate then return end
    getgenv().AutoTP = v
    if v then getgenv().TPBusy = false end
end
local function uiSetLight(v)
    if not _codeUpdate then getgenv().AutoLight = v end
end
local function uiSetDodge(v)
    if not _codeUpdate then getgenv().AutoDodge = v end
end
local function uiSetBlock(v)
    if _codeUpdate then return end
    getgenv().AutoBlock = v
    if not v and getgenv().Blocking then
        getgenv().Blocking = false
        keyEvent(false, BLOCK_KEY)
    end
end

TPToggle = MainTab:CreateToggle({ Name = "Auto TP Pad", CurrentValue = false, Callback = uiSetTP })
LightToggle = MainTab:CreateToggle({ Name = "Auto Light (Combo)", CurrentValue = false, Callback = uiSetLight })
DodgeToggle = MainTab:CreateToggle({ Name = "Auto Evade", CurrentValue = true, Callback = uiSetDodge })
BlockToggle = MainTab:CreateToggle({ Name = "Auto Block", CurrentValue = true, Callback = uiSetBlock })

local function uiSetTargetLock(v)
    if _codeUpdate then return end
    getgenv().TargetLock = v
    print("[LOCK] TargetLock -> " .. tostring(v))
end

TargetLockToggle = MainTab:CreateToggle({
    Name         = "🎯 Target Lock (Whitelist only)",
    CurrentValue = getgenv().TargetLock,
    Callback     = uiSetTargetLock,
})

-- ===== WEBHOOK TAB (chỉ giữ toggle + dropdown + test button) =====
local WebhookTab = Window:CreateTab("Webhook", 4483362458)

WebhookTab:CreateSection("Settings")

WebhookTab:CreateToggle({
    Name = "Webhook Enabled",
    CurrentValue = getgenv().WebhookToggle,
    Callback = function(v)
        getgenv().WebhookToggle = v
        print("[WEBHOOK] Toggle -> " .. tostring(v))
    end,
})

WebhookTab:CreateDropdown({
    Name = "Webhook Mode",
    Options = { "MAIN only", "ALL accounts" },
    CurrentOption = { getgenv().WebhookMode == "ALL" and "ALL accounts" or "MAIN only" },
    MultipleOptions = false,
    Callback = function(opt)
        local v = type(opt) == "table" and opt[1] or opt
        if not v then return end
        if string.find(v, "MAIN") then
            getgenv().WebhookMode = "MAIN"
        else
            getgenv().WebhookMode = "ALL"
        end
        print("[WEBHOOK] Mode -> " .. getgenv().WebhookMode)
    end,
})

WebhookTab:CreateSection("Notifications")

WebhookTab:CreateToggle({
    Name = "Thông báo Cash",
    CurrentValue = getgenv().NotifyCash,
    Callback = function(v)
        getgenv().NotifyCash = v
        print("[NOTIFY] Cash -> " .. tostring(v))
    end,
})

WebhookTab:CreateToggle({
    Name = "Thông báo Spins",
    CurrentValue = getgenv().NotifySpins,
    Callback = function(v)
        getgenv().NotifySpins = v
        print("[NOTIFY] Spins -> " .. tostring(v))
    end,
})

WebhookTab:CreateToggle({
    Name = "Thông báo Lucky Spins",
    CurrentValue = getgenv().NotifyLucky,
    Callback = function(v)
        getgenv().NotifyLucky = v
        print("[NOTIFY] Lucky Spins -> " .. tostring(v))
    end,
})

WebhookTab:CreateSection("Tools")

WebhookTab:CreateButton({
    Name = "Test webhook now",
    Callback = function()
        task.spawn(function()
            local sent = webhookCurrently()
            Rayfield:Notify({
                Title = sent and "Sent OK" or "Blocked/Failed",
                Content = getgenv().LastWebhookResult,
                Duration = 4,
                Image = 4483362458,
            })
        end)
    end,
})

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            SelfLabel:Set(string.format("%s | PAD: %s | Opp: %s",
                MY_NAME, getgenv().SelectedPad, readOpponentName() or "none"))
        end)
    end
end)

-- ===== MATCH DETECTION + TP (Pad 2/4) + AUTO COMBO =====
task.spawn(function()
    local matchEndAt = nil
    while task.wait(0.3) do
        local active = isMatchActive()
        if active then
            matchEndAt = nil
            if not getgenv().InMatch then
                getgenv().InMatch = true
                getgenv().MatchStartTick = tick()
                getgenv().TpToOppDone = false
                getgenv().AutoTP = false
                _codeUpdate = true
                if TPToggle then TPToggle:Set(false) end
                _codeUpdate = false

                local padMode = isPad2() and (getgenv().SelectedPad .. " (TP)") or (getgenv().SelectedPad .. " (no TP)")
                print("[MATCH] Started | opp=" .. tostring(readOpponentName()) .. " | " .. padMode)

                task.spawn(function()
                    task.wait(0.5)
                    if getgenv().InMatch and not getgenv().AutoLight then
                        getgenv().AutoLight = true
                        _codeUpdate = true
                        if LightToggle then LightToggle:Set(true) end
                        _codeUpdate = false
                    end
                end)

                if isPad2() then
                    task.spawn(function()
                        for i = 1, 20 do
                            if not getgenv().InMatch then return end
                            if not isPad2() then return end
                            local ok, reason = tpToOpponentOnce()
                            if ok then
                                getgenv().TpToOppDone = true
                                print("[MATCH] " .. getgenv().SelectedPad .. " -> TP to opponent (try #" .. i .. ")")
                                return
                            end
                            task.wait(0.5)
                        end
                        warn("[MATCH] " .. getgenv().SelectedPad .. " TP failed after 10s - opponent char chưa load?")
                    end)
                else
                    print("[MATCH] " .. getgenv().SelectedPad .. " -> không TP, đứng yên")
                end
            end
        else
            if getgenv().InMatch then
                if not matchEndAt then
                    matchEndAt = tick()
                elseif tick() - matchEndAt >= MATCH_END_DEBOUNCE then
                    getgenv().InMatch = false
                    getgenv().TpToOppDone = false
                    getgenv().DodgeCount = 0
                    getgenv().CounterCount = 0
                    getgenv().StaminaBlocks = 0
                    getgenv().MatchStartTick = nil
                    matchEndAt = nil
                    getgenv().AutoTP = true
                    _codeUpdate = true
                    if TPToggle then TPToggle:Set(true) end
                    _codeUpdate = false
                    print("[MATCH] Ended -> TP pad")
                end
            end
        end
    end
end)

-- ===== TARGET LOCK REJECT (reset + TP to pad) =====
task.spawn(function()
    local badStart = nil
    while task.wait(0.5) do
        if not getgenv().TargetLock or getgenv().RejectBusy then
            badStart = nil
            continue
        end

        local name = readRawOpponentName()
        if not name or isWhitelisted(name) then
            badStart = nil
            continue
        end

        if getgenv().LastRejectedName == name
            and (tick() - getgenv().LastRejectedAt) < 30 then
            badStart = nil
            continue
        end

        if not badStart then
            badStart = tick()
            print("[LOCK] Non-whitelist detected: " .. name .. " (pending reject...)")
        elseif tick() - badStart > 2 then
            rejectOpponent(name)
            badStart = nil
        end
    end
end)

-- ===== AUTO TP PAD =====
task.spawn(function()
    while task.wait(0.5) do
        if not getgenv().AutoTP or getgenv().TPBusy then continue end
        if getgenv().InMatch then continue end
        getgenv().TPBusy = true
        pcall(function()
            local hrp = getHRP()
            if not hrp then return end
            local p = getgenv().PadPosition
            hrp.CFrame = CFrame.new(p.X, p.Y + 50, p.Z)
            for _ = 1, 20 do
                if not getgenv().AutoTP then return end
                if hrp.Position.Y <= p.Y + 1 then break end
                hrp.CFrame = CFrame.new(p.X, hrp.Position.Y - 5, p.Z)
                task.wait(0.08)
            end
            for _ = 1, 40 do
                if not getgenv().AutoTP then return end
                if isMatchActive() then return end
                task.wait(0.5)
            end
        end)
        getgenv().TPBusy = false
    end
end)

-- ===== AUTO BLOCK =====
task.spawn(function()
    local lastHealth, blockUntil, blockCooldownUntil = nil, 0, 0
    local counterUntil, wasBlocking = 0, false
    local staminaBlockUntil, staminaCooldownUntil = 0, 0
    while task.wait(0.05) do
        local canBlock = getgenv().AutoBlock and getgenv().InMatch
        if not canBlock then
            if getgenv().Blocking then
                getgenv().Blocking = false
                keyEvent(false, BLOCK_KEY)
            end
            getgenv().Countering = false
            wasBlocking, lastHealth = false, nil
            blockUntil, staminaBlockUntil, staminaCooldownUntil = 0, 0, 0
            continue
        end
        local h = readMyHealth()
        local stam = readMyStamina()
        local now = tick()
        if h and lastHealth and h < lastHealth then
            if now > blockCooldownUntil then
                blockUntil = now + BLOCK_DURATION
                blockCooldownUntil = blockUntil + BLOCK_COOLDOWN
            end
        end
        lastHealth = h
        if stam and stam < STAMINA_LOW and now > staminaCooldownUntil then
            staminaBlockUntil = now + STAMINA_BLOCK_DUR
            staminaCooldownUntil = staminaBlockUntil + STAMINA_BLOCK_CD
            getgenv().StaminaBlocks = getgenv().StaminaBlocks + 1
        end
        local shouldBlock = now < blockUntil or now < staminaBlockUntil
        if wasBlocking and not shouldBlock then
            counterUntil = now + COUNTER_DURATION
            getgenv().CounterCount = getgenv().CounterCount + 1
        end
        wasBlocking = shouldBlock
        if shouldBlock ~= getgenv().Blocking then
            getgenv().Blocking = shouldBlock
            keyEvent(shouldBlock, BLOCK_KEY)
        end
        getgenv().Countering = now < counterUntil
    end
end)

-- ===== AUTO COMBO =====
task.spawn(function()
    while task.wait(0.05) do
        if not getgenv().AutoLight or not getgenv().InMatch
            or getgenv().Blocking or getgenv().Dodging then continue end
        local combo = getgenv().Countering and COUNTER_COMBO or COMBOS[getgenv().ComboIdx]
        for _, move in ipairs(combo) do
            if not getgenv().AutoLight or not getgenv().InMatch
                or getgenv().Blocking or getgenv().Dodging then break end
            clickTarget(move[1])
            task.wait(move[2])
        end
        if not getgenv().Countering then
            getgenv().ComboIdx = (getgenv().ComboIdx % #COMBOS) + 1
            task.wait(COMBO_PAUSE_MIN + math.random() * (COMBO_PAUSE_MAX - COMBO_PAUSE_MIN))
        else
            task.wait(0.05)
        end
    end
end)

-- ===== AUTO EVADE =====
local function doDodge(jumpOnly)
    if jumpOnly then
        keyEvent(true, Enum.KeyCode.Space)
        task.wait(DODGE_HOLD)
        keyEvent(false, Enum.KeyCode.Space)
    else
        local dirKey = DODGE_KEYS[math.random(1, #DODGE_KEYS)]
        keyEvent(true, Enum.KeyCode.Space)
        keyEvent(true, dirKey)
        task.wait(DODGE_HOLD)
        keyEvent(false, dirKey)
        keyEvent(false, Enum.KeyCode.Space)
    end
end

task.spawn(function()
    while task.wait(DODGE_CHECK_INTERVAL) do
        if not getgenv().AutoDodge then continue end
        if not getgenv().InMatch then continue end
        if getgenv().Blocking or getgenv().Dodging then continue end
        if math.random() < DODGE_CHANCE then
            getgenv().Dodging = true
            getgenv().DodgeCount = getgenv().DodgeCount + 1
            task.spawn(function()
                doDodge(math.random() < DODGE_JUMP_ONLY_CHANCE)
                if math.random() < DODGE_CHAIN_CHANCE then
                    task.wait(DODGE_CHAIN_DELAY)
                    if getgenv().AutoDodge and getgenv().InMatch
                        and not getgenv().Blocking then
                        getgenv().DodgeCount = getgenv().DodgeCount + 1
                        doDodge(math.random() < DODGE_JUMP_ONLY_CHANCE)
                    end
                    if math.random() < DODGE_TRIPLE_CHANCE then
                        task.wait(DODGE_CHAIN_DELAY)
                        if getgenv().AutoDodge and getgenv().InMatch
                            and not getgenv().Blocking then
                            getgenv().DodgeCount = getgenv().DodgeCount + 1
                            doDodge(math.random() < DODGE_JUMP_ONLY_CHANCE)
                        end
                    end
                end
                task.wait(0.05)
                getgenv().Dodging = false
            end)
        end
    end
end)

-- ===== STARTUP WEBHOOK =====
task.spawn(function()
    task.wait(1.0)
    waitForUBG(3)
    local ok, reason = checkWebhookReason()
    print(string.format("[WEBHOOK] Startup: mode=%s main=%s toggle=%s -> %s (%s)",
        getgenv().WebhookMode, tostring(IS_MAIN_ACCOUNT), tostring(getgenv().WebhookToggle),
        tostring(ok), reason))
    if ok then
        webhookCurrently()
    end
end)

-- ===== UBG TRACKER (đã bỏ baseline, tôn trọng 3 toggle notify) =====
task.spawn(function()
    waitForUBG(6)
    if not readUBG() then
        print("[UBG] Tracker skip - labels not found")
        return
    end
    print("[UBG] Tracker active - track spins + cash + lucky (notify: spins="
        .. tostring(getgenv().NotifySpins) .. " cash=" .. tostring(getgenv().NotifyCash)
        .. " lucky=" .. tostring(getgenv().NotifyLucky) .. ")")
    local last = readUBG()
    if not last then return end

    local lastSpins = parseNum(last.spins)
    local lastCash  = parseNum(last.cash)
    local lastLucky = parseNum(last.lucky)

    getgenv().StopWebhook = false
    while not getgenv().StopWebhook do
        task.wait(UBG_INTERVAL)
        local cur = readUBG()
        if not cur then break end

        local curSpins = parseNum(cur.spins)
        local curCash  = parseNum(cur.cash)
        local curLucky = parseNum(cur.lucky)

        local fields = {}
        local pos, neg = 0, 0

        -- Spins
        if curSpins and lastSpins and curSpins ~= lastSpins then
            if getgenv().NotifySpins then
                local d = curSpins - lastSpins
                if d >= 0 then pos = pos + 1 else neg = neg + 1 end
                table.insert(fields, {
                    name = "Spins",
                    value = ("**%s%s** `%s -> %s`"):format(
                        d >= 0 and "+" or "", fmtNum(d),
                        fmtNum(lastSpins), fmtNum(curSpins)),
                })
            end
            lastSpins = curSpins
        else
            if curSpins then lastSpins = curSpins end
        end

        -- Cash
        if curCash and lastCash and curCash ~= lastCash then
            if getgenv().NotifyCash then
                local d = curCash - lastCash
                if d >= 0 then pos = pos + 1 else neg = neg + 1 end
                table.insert(fields, {
                    name = "Cash",
                    value = ("**%s%s** `%s -> %s`"):format(
                        d >= 0 and "+" or "", fmtNum(d),
                        fmtNum(lastCash), fmtNum(curCash)),
                })
            end
            lastCash = curCash
        else
            if curCash then lastCash = curCash end
        end

        -- Lucky Spins
        if curLucky and lastLucky and curLucky ~= lastLucky then
            if getgenv().NotifyLucky then
                local d = curLucky - lastLucky
                if d >= 0 then pos = pos + 1 else neg = neg + 1 end
                table.insert(fields, {
                    name = "Lucky Spins",
                    value = ("**%s%s** `%s -> %s`"):format(
                        d >= 0 and "+" or "", fmtNum(d),
                        fmtNum(lastLucky), fmtNum(curLucky)),
                })
            end
            lastLucky = curLucky
        else
            if curLucky then lastLucky = curLucky end
        end

        if #fields > 0 then
            print(string.format("[STATS] %d change(s) detected", #fields))
            local ok, reason = checkWebhookReason()
            if ok then
                webhookStatsChanged(fields, pos, neg)
            else
                print("[STATS] skip: " .. reason)
                getgenv().LastWebhookResult = "skip: " .. reason
            end
        end
    end
end)

Rayfield:Notify({
    Title = "AI v28 BATTLE",
    Content = string.format("%s | PAD: %s%s | Lock: %s", MY_NAME, getgenv().SelectedPad,
        isPad2() and " (TP)" or " (no TP)",
        getgenv().TargetLock and "ON" or "OFF"),
    Duration = 6,
    Image = 4483362458,
})

print(string.format("[AI v28] %s | PAD=%s (%.0f,%.0f,%.0f) | TP-to-opp=%s | Lock=%s | HTTP=%s",
    MY_NAME, getgenv().SelectedPad,
    getgenv().PadPosition.X, getgenv().PadPosition.Y, getgenv().PadPosition.Z,
    isPad2() and "YES" or "NO",
    getgenv().TargetLock and "ON" or "OFF",
    httpMethod))

-- ============================================================
-- 💔 FLOATING STOP BUTTON — ✗ / ✓ (bottom-left, mobile)
-- ============================================================
do
    local UIS = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")

    local old = PG:FindFirstChild("StopEverythingBtn")
    if old then old:Destroy() end

    local COL_RED   = Color3.fromRGB(220, 38, 38)
    local COL_GREEN = Color3.fromRGB(34, 197, 94)
    local BASE_W, BASE_H = 190, 52

    local btn = Instance.new("TextButton")
    btn.Name              = "StopEverythingBtn"
    btn.Size              = UDim2.fromOffset(BASE_W, BASE_H)
    btn.Position          = UDim2.new(0, 16, 1, -100)
    btn.BackgroundColor3  = COL_RED
    btn.TextColor3        = Color3.fromRGB(255, 255, 255)
    btn.Font              = Enum.Font.GothamBold
    btn.TextSize          = 14
    btn.Text              = "✗   STOP EVERYTHING"
    btn.AutoButtonColor   = false
    btn.BorderSizePixel   = 0
    btn.ZIndex            = 999
    btn.Parent            = PG

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, BASE_H / 2)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color        = Color3.fromRGB(255, 255, 255)
    stroke.Thickness    = 2
    stroke.Transparency = 0.35
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent       = btn

    local glow = Instance.new("Frame")
    glow.Name                    = "Glow"
    glow.Size                    = UDim2.new(1, 12, 1, 12)
    glow.Position                = UDim2.new(0, -6, 0, -6)
    glow.BackgroundColor3        = COL_RED
    glow.BackgroundTransparency  = 0.75
    glow.BorderSizePixel         = 0
    glow.ZIndex                  = 998
    glow.Parent                  = btn
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(1, 0)
    glowCorner.Parent = glow

    local dragging, dragStart, startPos, dragMoved = false, nil, nil, false
    local DRAG_THRESHOLD = 8

    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragMoved = false
            dragStart = i.Position
            startPos  = btn.Position
        end
    end)

    UIS.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            local d = i.Position - dragStart
            if math.abs(d.X) > DRAG_THRESHOLD or math.abs(d.Y) > DRAG_THRESHOLD then
                dragMoved = true
            end
            if dragMoved then
                btn.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end)

    local function stopEverything()
        getgenv().AutoTP     = false
        getgenv().AutoLight  = false
        getgenv().AutoDodge  = false
        getgenv().AutoBlock  = false
        getgenv().TPBusy     = false
        getgenv().Dodging    = false
        getgenv().Countering = false
        getgenv().TpToOppDone = false
        getgenv().StopWebhook = true
        getgenv().TargetLock = false
        getgenv().RejectBusy = false

        if getgenv().Blocking then
            getgenv().Blocking = false
            pcall(function() VIM:SendKeyEvent(false, BLOCK_KEY, false, nil) end)
        end

        _codeUpdate = true
        pcall(function() if TPToggle    then TPToggle:Set(false)    end end)
        pcall(function() if LightToggle then LightToggle:Set(false) end end)
        pcall(function() if DodgeToggle then DodgeToggle:Set(false) end end)
        pcall(function() if BlockToggle then BlockToggle:Set(false) end end)
        pcall(function() if TargetLockToggle then TargetLockToggle:Set(false) end end)
        _codeUpdate = false

        local bounce = TweenInfo.new(0.12, Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out, 0, true)
        TweenService:Create(btn, bounce, {
            Size = UDim2.fromOffset(BASE_W - 8, BASE_H - 6),
        }):Play()

        TweenService:Create(btn, TweenInfo.new(0.25), {
            BackgroundColor3 = COL_GREEN,
        }):Play()
        TweenService:Create(glow, TweenInfo.new(0.25), {
            BackgroundColor3 = COL_GREEN,
        }):Play()
        btn.Text = "✓   STOPPED"

        print("[STOP] Everything stopped by user")
        pcall(function()
            Rayfield:Notify({
                Title    = "🛑 STOPPED",
                Content  = "All automation disabled",
                Duration = 3,
                Image    = 4483362458,
            })
        end)

        task.delay(1.6, function()
            if not (btn and btn.Parent) then return end
            TweenService:Create(btn, TweenInfo.new(0.3), {
                BackgroundColor3 = COL_RED,
            }):Play()
            TweenService:Create(glow, TweenInfo.new(0.3), {
                BackgroundColor3 = COL_RED,
            }):Play()
            btn.Text = "✗   STOP EVERYTHING"
        end)
    end

    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            if dragging and not dragMoved then
                stopEverything()
            end
            dragging = false
        end
    end)
end
-- ============================================================