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

local PAD_1 = Vector3.new(-8, 0, -161)
local PAD_2 = Vector3.new(16, 0, -162)

local PAIRS = {
    { "GHHTWHOWR", "GHfhahfiuaf2" },
    { "GHfhahfiuaf2", "GHfhahfiuaf3" },
}

local MY_NAME = LP.Name
local IS_MAIN_ACCOUNT = (MY_NAME == MAIN_WEBHOOK_ACCOUNT)
local MY_TARGET_NAME, IS_PLAYER_2, WHO, MY_PAD, PAIR_LABEL

local function recomputePair()
    local oldTarget = MY_TARGET_NAME
    local candidates = {}
    for i, pair in ipairs(PAIRS) do
        if MY_NAME == pair[1] then
            table.insert(candidates, { target = pair[2], role = "P1", idx = i })
        elseif MY_NAME == pair[2] then
            table.insert(candidates, { target = pair[1], role = "P2", idx = i })
        end
    end
    if #candidates == 0 then
        MY_TARGET_NAME, IS_PLAYER_2, PAIR_LABEL = nil, false, "-"
        WHO, MY_PAD = "P1", PAD_1
        return
    end
    local chosen = nil
    for _, c in ipairs(candidates) do
        if Players:FindFirstChild(c.target) then chosen = c; break end
    end
    if not chosen then chosen = candidates[1] end
    MY_TARGET_NAME = chosen.target
    IS_PLAYER_2 = (chosen.role == "P2")
    PAIR_LABEL = "#" .. chosen.idx
    WHO = IS_PLAYER_2 and "P2" or "P1"
    MY_PAD = IS_PLAYER_2 and PAD_2 or PAD_1
    if oldTarget ~= MY_TARGET_NAME then
        print(string.format("[PAIR] %s -> %s (%s, pair %s)", MY_NAME, MY_TARGET_NAME, WHO, PAIR_LABEL))
    end
end
recomputePair()

local CAN_ULT = true
local DELAY_BEFORE_FIGHT = 1.5
local MATCH_END_DEBOUNCE = 2.0
local ATTACK_RANGE = 10
local TP_OFFSET = 3.5
local COMBO_PAUSE_MIN = 0.20
local COMBO_PAUSE_MAX = 0.50
local BLOCK_KEY = Enum.KeyCode.F
local BLOCK_DURATION = 2.0
local BLOCK_COOLDOWN = 3.5
local COUNTER_DURATION = 1.2
local STAMINA_LOW = 20
local STAMINA_BLOCK_DUR = 2.0
local STAMINA_BLOCK_CD = 2.5
local ULT_KEY = Enum.KeyCode.Q
local ULT_HOLD = 0.15
local ULT_COOLDOWN_MIN = 10.0
local ULT_COOLDOWN_MAX = 16.0
local ULT_BUFFER_MAX = 5.0
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
getgenv().AutoFight = false
getgenv().AutoLight = false
getgenv().AutoDodge = true
getgenv().AutoBlock = true
getgenv().TPBusy = false
getgenv().InMatch = false
getgenv().Blocking = false
getgenv().Countering = false
getgenv().Dodging = false
getgenv().ComboIdx = 1
getgenv().DodgeCount = 0
getgenv().CounterCount = 0
getgenv().UltCount = 0
getgenv().UltFails = 0
getgenv().StaminaBlocks = 0
getgenv().MatchStartTick = nil
getgenv().WebhookSent = 0
getgenv().WebhookFailed = 0
getgenv().HttpMethod = "?"
getgenv().WebhookToggle = getgenv().WebhookToggle or true
getgenv().WebhookMode = getgenv().WebhookMode or "MAIN"
getgenv().LastWebhookResult = "none"
getgenv().CashBaseline = "?"
getgenv().SpinsBaseline = "?"
getgenv().LuckyBaseline = "?"

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
    warn("[AI v22] Rayfield fail, stop")
    return
end
print("[AI v22] Rayfield loaded, HTTP=" .. httpMethod)

local function checkWebhookReason()
    if getgenv().WebhookMode == "ALL" then
        return true, "ALL mode"
    end
    if not IS_MAIN_ACCOUNT then
        return false, "not main (mode=MAIN)"
    end
    if not getgenv().WebhookToggle then
        return false, "toggle OFF (mode=MAIN)"
    end
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

local function getTargetHRP()
    if not MY_TARGET_NAME then return nil end
    local opp = Players:FindFirstChild(MY_TARGET_NAME)
    if not opp or not opp.Character then return nil end
    local hum = opp.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return nil end
    return opp.Character:FindFirstChild("HumanoidRootPart")
end

local function readOpponentValue()
    local val
    pcall(function()
        local st = workspace:FindFirstChild("States")
        if not st then return end
        local me = st:FindFirstChild(MY_NAME)
        if not me then return end
        local d = me:FindFirstChild("CharacterData")
        if not d then return end
        local o = d:FindFirstChild("Opponent")
        if o then val = o.Value end
    end)
    return val
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
    local v = readOpponentValue()
    return v ~= nil and v ~= ""
end

local function clickAt(sx, sy, button)
    pcall(function()
        VIM:SendMouseButtonEvent(sx, sy, button, true, nil, 0)
        VIM:SendMouseButtonEvent(sx, sy, button, false, nil, 0)
    end)
end

local function clickTarget(button)
    local target = getTargetHRP()
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

local function fireUlt()
    local ok, err = pcall(function()
        VIM:SendKeyEvent(true, ULT_KEY, false, nil)
        task.wait(ULT_HOLD)
        VIM:SendKeyEvent(false, ULT_KEY, false, nil)
    end)
    if ok then
        getgenv().UltCount = getgenv().UltCount + 1
        return true
    else
        getgenv().UltFails = getgenv().UltFails + 1
        return false
    end
end

local Window = Rayfield:CreateWindow({
    Name = "AI v22 BATTLE",
    LoadingTitle = "AI v22 BATTLE",
    LoadingSubtitle = "Loading",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)
MainTab:CreateSection("Account")
local SelfLabel = MainTab:CreateLabel(
    string.format("%s | %s | target: %s", MY_NAME, WHO, MY_TARGET_NAME or "none"), 4483362458)

MainTab:CreateSection("Automation")

local _codeUpdate = false
local FightToggle, LightToggle, TPToggle, DodgeToggle, BlockToggle

local function uiSetLight(v)
    if _codeUpdate then return end
    getgenv().AutoLight = v
end
local function uiSetFight(v)
    if _codeUpdate then return end
    getgenv().AutoFight = v
    if v and not getgenv().AutoLight then
        getgenv().AutoLight = true
        _codeUpdate = true
        if LightToggle then LightToggle:Set(true) end
        _codeUpdate = false
    end
end
local function uiSetTP(v)
    if _codeUpdate then return end
    getgenv().AutoTP = v
    if v then getgenv().TPBusy = false end
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

FightToggle = MainTab:CreateToggle({ Name = "Fight", CurrentValue = false, Callback = uiSetFight })
LightToggle = MainTab:CreateToggle({ Name = "Auto Light", CurrentValue = false, Callback = uiSetLight })
TPToggle = MainTab:CreateToggle({ Name = "TP PAD", CurrentValue = false, Callback = uiSetTP })
DodgeToggle = MainTab:CreateToggle({ Name = "Auto Evade", CurrentValue = true, Callback = uiSetDodge })
BlockToggle = MainTab:CreateToggle({ Name = "Auto Block", CurrentValue = true, Callback = uiSetBlock })

local WebhookTab = Window:CreateTab("Webhook", 4483362458)
WebhookTab:CreateSection("Status")

local HttpLbl = WebhookTab:CreateLabel("HTTP: " .. httpMethod, 4483362458)
local ModeLbl = WebhookTab:CreateLabel("Mode: " .. getgenv().WebhookMode, 4483362458)
local ToggleLbl = WebhookTab:CreateLabel("Toggle: " .. (getgenv().WebhookToggle and "ON" or "OFF"), 4483362458)
local EffectiveLbl = WebhookTab:CreateLabel("Effective: ?", 4483362458)
local LastResultLbl = WebhookTab:CreateLabel("Last: none", 4483362458)
local CashBaselineLbl = WebhookTab:CreateLabel("Cash baseline: ?", 4483362458)
local SpinsBaselineLbl = WebhookTab:CreateLabel("Spins baseline: ?", 4483362458)
local LuckyBaselineLbl = WebhookTab:CreateLabel("Lucky baseline: ?", 4483362458)
local UBGStatusLbl = WebhookTab:CreateLabel("UBG labels: ?", 4483362458)

local function refreshStatus()
    local ok, reason = checkWebhookReason()
    local ubgFound = readUBG() ~= nil
    pcall(function()
        ModeLbl:Set("Mode: " .. getgenv().WebhookMode)
        ToggleLbl:Set("Toggle: " .. (getgenv().WebhookToggle and "ON" or "OFF"))
        EffectiveLbl:Set((ok and "Effective: YES (" or "Effective: NO (") .. reason .. ")")
        LastResultLbl:Set("Last: " .. getgenv().LastWebhookResult)
        CashBaselineLbl:Set("Cash baseline: " .. (getgenv().CashBaseline or "?"))
        SpinsBaselineLbl:Set("Spins baseline: " .. (getgenv().SpinsBaseline or "?"))
        LuckyBaselineLbl:Set("Lucky baseline: " .. (getgenv().LuckyBaseline or "?"))
        UBGStatusLbl:Set("UBG labels: " .. (ubgFound and "FOUND" or "NOT FOUND"))
    end)
end

WebhookTab:CreateSection("Settings")

WebhookTab:CreateToggle({
    Name = "Webhook Enabled",
    CurrentValue = getgenv().WebhookToggle,
    Callback = function(v)
        getgenv().WebhookToggle = v
        print("[WEBHOOK] Toggle -> " .. tostring(v))
        refreshStatus()
    end,
})

WebhookTab:CreateDropdown({
    Name = "Webhook Mode",
    Options = { "MAIN only", "ALL accounts" },
    CurrentOption = { getgenv().WebhookMode == "ALL" and "ALL accounts" or "MAIN only" },
    MultipleOptions = false,
    Callback = function(opt)
        local v = type(opt) == "table" and opt[1] or opt
        print("[WEBHOOK] Dropdown raw: " .. tostring(v))
        if not v then return end
        if string.find(v, "MAIN") then
            getgenv().WebhookMode = "MAIN"
        else
            getgenv().WebhookMode = "ALL"
        end
        print("[WEBHOOK] Mode -> " .. getgenv().WebhookMode)
        refreshStatus()
        task.spawn(function()
            local ok = checkWebhookReason()
            if ok then
                webhookCurrently()
                Rayfield:Notify({
                    Title = "Mode changed + sent",
                    Content = getgenv().LastWebhookResult,
                    Duration = 4,
                    Image = 4483362458,
                })
            else
                Rayfield:Notify({
                    Title = "Mode changed",
                    Content = getgenv().LastWebhookResult,
                    Duration = 4,
                    Image = 4483362458,
                })
            end
            refreshStatus()
        end)
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
            refreshStatus()
        end)
    end,
})

WebhookTab:CreateButton({
    Name = "Force send (bypass mode/toggle)",
    Callback = function()
        task.spawn(function()
            local oldMode, oldToggle = getgenv().WebhookMode, getgenv().WebhookToggle
            getgenv().WebhookMode = "ALL"
            getgenv().WebhookToggle = true
            local sent = webhookCurrently()
            getgenv().WebhookMode = oldMode
            getgenv().WebhookToggle = oldToggle
            Rayfield:Notify({
                Title = sent and "Force sent OK" or "Force FAILED",
                Content = getgenv().LastWebhookResult,
                Duration = 4,
                Image = 4483362458,
            })
            refreshStatus()
        end)
    end,
})

refreshStatus()

local StatsTab = Window:CreateTab("Stats", 4483362458)
StatsTab:CreateSection("Battle")

local InMatchLbl = StatsTab:CreateLabel("In Match: NO", 4483362458)
local BlockLbl = StatsTab:CreateLabel("Blocking: OFF", 4483362458)
local DodgeLbl = StatsTab:CreateLabel("Dodges: 0", 4483362458)
local CounterLbl = StatsTab:CreateLabel("Counters: 0", 4483362458)
local StaminaBlockLbl = StatsTab:CreateLabel("Stamina Blocks: 0", 4483362458)
local UltLbl = StatsTab:CreateLabel("ULT: 0 (F:0)", 4483362458)
local WebhookCounterLbl = StatsTab:CreateLabel("Webhook: 0 (F:0)", 4483362458)
local ComboLbl = StatsTab:CreateLabel("Combo: #1/" .. #COMBOS, 4483362458)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            InMatchLbl:Set("In Match: " .. (getgenv().InMatch and "YES" or "NO"))
            BlockLbl:Set(string.format("Blocking: %s | CT: %s",
                getgenv().Blocking and "ON" or "OFF", getgenv().Countering and "Y" or "-"))
            DodgeLbl:Set("Dodges: " .. getgenv().DodgeCount)
            CounterLbl:Set("Counters: " .. getgenv().CounterCount)
            StaminaBlockLbl:Set("Stamina Blocks: " .. getgenv().StaminaBlocks)
            UltLbl:Set(string.format("ULT: %d (F:%d)", getgenv().UltCount, getgenv().UltFails))
            WebhookCounterLbl:Set(string.format("Webhook: %d (F:%d)", getgenv().WebhookSent, getgenv().WebhookFailed))
            ComboLbl:Set(string.format("Combo: #%d/%d", getgenv().ComboIdx, #COMBOS))
        end)
    end
end)

task.spawn(function()
    while task.wait(5) do
        if getgenv().InMatch then continue end
        local oldTarget = MY_TARGET_NAME
        recomputePair()
        pcall(function()
            SelfLabel:Set(string.format("%s | %s | target: %s", MY_NAME, WHO, MY_TARGET_NAME or "none"))
        end)
        if oldTarget ~= MY_TARGET_NAME then
            Rayfield:Notify({
                Title = "Target changed",
                Content = string.format("%s -> %s", tostring(oldTarget), tostring(MY_TARGET_NAME)),
                Duration = 3,
                Image = 4483362458,
            })
        end
    end
end)

task.spawn(function()
    local matchEndAt = nil
    while task.wait(0.3) do
        local active = isMatchActive()
        if active then
            matchEndAt = nil
            if not getgenv().InMatch then
                getgenv().InMatch = true
                getgenv().MatchStartTick = tick()
                print("[MATCH] Started")
                task.spawn(function()
                    task.wait(DELAY_BEFORE_FIGHT)
                    if getgenv().InMatch and not getgenv().AutoFight then
                        getgenv().AutoFight = true
                        getgenv().AutoLight = true
                        _codeUpdate = true
                        if FightToggle then FightToggle:Set(true) end
                        if LightToggle then LightToggle:Set(true) end
                        _codeUpdate = false
                    end
                end)
            end
        else
            if getgenv().InMatch then
                if not matchEndAt then
                    matchEndAt = tick()
                elseif tick() - matchEndAt >= MATCH_END_DEBOUNCE then
                    getgenv().InMatch = false
                    getgenv().AutoTP = true
                    getgenv().DodgeCount = 0
                    getgenv().CounterCount = 0
                    getgenv().UltCount = 0
                    getgenv().UltFails = 0
                    getgenv().StaminaBlocks = 0
                    getgenv().MatchStartTick = nil
                    matchEndAt = nil
                    _codeUpdate = true
                    if TPToggle then TPToggle:Set(true) end
                    _codeUpdate = false
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if getgenv().AutoFight and not getgenv().AutoLight then
            getgenv().AutoLight = true
            _codeUpdate = true
            if LightToggle then LightToggle:Set(true) end
            _codeUpdate = false
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if not getgenv().AutoTP or getgenv().TPBusy then continue end
        if getgenv().InMatch then
            getgenv().AutoTP = false
            _codeUpdate = true
            if TPToggle then TPToggle:Set(false) end
            _codeUpdate = false
            continue
        end
        getgenv().TPBusy = true
        pcall(function()
            local hrp = getHRP()
            if not hrp then return end
            hrp.CFrame = CFrame.new(MY_PAD.X, MY_PAD.Y + 50, MY_PAD.Z)
            for _ = 1, 20 do
                if not getgenv().AutoTP then return end
                if hrp.Position.Y <= MY_PAD.Y + 1 then break end
                hrp.CFrame = CFrame.new(MY_PAD.X, hrp.Position.Y - 5, MY_PAD.Z)
                task.wait(0.08)
            end
            for _ = 1, 40 do
                if not getgenv().AutoTP then return end
                if isMatchActive() then
                    getgenv().AutoTP = false
                    _codeUpdate = true
                    if TPToggle then TPToggle:Set(false) end
                    _codeUpdate = false
                    return
                end
                task.wait(0.5)
            end
        end)
        getgenv().TPBusy = false
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if not getgenv().AutoFight or not getgenv().InMatch then continue end
        pcall(function()
            local hrp = getHRP()
            local target = getTargetHRP()
            if not hrp or not target then return end
            local dist = (target.Position - hrp.Position).Magnitude
            if dist > ATTACK_RANGE and not getgenv().Dodging then
                local dir = hrp.Position - target.Position
                if dir.Magnitude < 0.1 then dir = Vector3.new(0, 0, 1) end
                hrp.CFrame = CFrame.lookAt(target.Position + dir.Unit * TP_OFFSET, target.Position)
                return
            end
            if not getgenv().Dodging then
                local look = Vector3.new(target.Position.X, hrp.Position.Y, target.Position.Z)
                local diff = look - hrp.Position
                if diff.Magnitude > 0.01 and hrp.CFrame.LookVector:Dot(diff.Unit) < 0.7 then
                    hrp.CFrame = CFrame.lookAt(hrp.Position, look)
                end
            end
        end)
    end
end)

task.spawn(function()
    local lastHealth, blockUntil, blockCooldownUntil = nil, 0, 0
    local counterUntil, wasBlocking = 0, false
    local staminaBlockUntil, staminaCooldownUntil = 0, 0
    while task.wait(0.05) do
        local canBlock = getgenv().AutoBlock and getgenv().AutoFight and getgenv().InMatch
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

task.spawn(function()
    local ultReadyAt = tick() + math.random(3, 6)
    local pendingSince = nil
    while task.wait(0.1) do
        if not CAN_ULT or not getgenv().AutoFight or not getgenv().InMatch then
            pendingSince = nil
            continue
        end
        local now = tick()
        if now < ultReadyAt then continue end
        if getgenv().Blocking then
            if not pendingSince then pendingSince = now end
            if now - pendingSince < ULT_BUFFER_MAX then continue end
        end
        if fireUlt() then
            ultReadyAt = now + ULT_COOLDOWN_MIN + math.random() * (ULT_COOLDOWN_MAX - ULT_COOLDOWN_MIN)
            pendingSince = nil
        else
            ultReadyAt = now + 1.0
        end
    end
end)

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
        if not getgenv().AutoFight or not getgenv().InMatch then continue end
        if getgenv().Blocking or getgenv().Dodging then continue end
        if math.random() < DODGE_CHANCE then
            getgenv().Dodging = true
            getgenv().DodgeCount = getgenv().DodgeCount + 1
            task.spawn(function()
                doDodge(math.random() < DODGE_JUMP_ONLY_CHANCE)
                if math.random() < DODGE_CHAIN_CHANCE then
                    task.wait(DODGE_CHAIN_DELAY)
                    if getgenv().AutoDodge and getgenv().AutoFight
                        and getgenv().InMatch and not getgenv().Blocking then
                        getgenv().DodgeCount = getgenv().DodgeCount + 1
                        doDodge(math.random() < DODGE_JUMP_ONLY_CHANCE)
                    end
                    if math.random() < DODGE_TRIPLE_CHANCE then
                        task.wait(DODGE_CHAIN_DELAY)
                        if getgenv().AutoDodge and getgenv().AutoFight
                            and getgenv().InMatch and not getgenv().Blocking then
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
    refreshStatus()
end)

task.spawn(function()
    waitForUBG(6)
    if not readUBG() then
        print("[UBG] Tracker skip - labels not found")
        return
    end
    print("[UBG] Tracker active - track spins + cash + lucky")
    local last = readUBG()
    if not last then return end

    local lastSpins = parseNum(last.spins)
    local lastCash = parseNum(last.cash)
    local lastLucky = parseNum(last.lucky)

    getgenv().SpinsBaseline = lastSpins and fmtNum(lastSpins) or "?"
    getgenv().CashBaseline = lastCash and fmtNum(lastCash) or "?"
    getgenv().LuckyBaseline = lastLucky and fmtNum(lastLucky) or "?"
    refreshStatus()

    while true do
        task.wait(UBG_INTERVAL)
        local cur = readUBG()
        if not cur then break end

        local curSpins = parseNum(cur.spins)
        local curCash = parseNum(cur.cash)
        local curLucky = parseNum(cur.lucky)

        local fields = {}
        local pos, neg = 0, 0

        if curSpins and lastSpins and curSpins ~= lastSpins then
            local d = curSpins - lastSpins
            if d >= 0 then pos = pos + 1 else neg = neg + 1 end
            table.insert(fields, {
                name = "Spins",
                value = ("**%s%s** `%s -> %s`"):format(
                    d >= 0 and "+" or "", fmtNum(d),
                    fmtNum(lastSpins), fmtNum(curSpins)),
            })
            lastSpins = curSpins
            getgenv().SpinsBaseline = fmtNum(lastSpins)
        else
            if curSpins then lastSpins = curSpins end
        end

        if curCash and lastCash and curCash ~= lastCash then
            local d = curCash - lastCash
            if d >= 0 then pos = pos + 1 else neg = neg + 1 end
            table.insert(fields, {
                name = "Cash",
                value = ("**%s%s** `%s -> %s`"):format(
                    d >= 0 and "+" or "", fmtNum(d),
                    fmtNum(lastCash), fmtNum(curCash)),
            })
            lastCash = curCash
            getgenv().CashBaseline = fmtNum(lastCash)
        else
            if curCash then lastCash = curCash end
        end

        if curLucky and lastLucky and curLucky ~= lastLucky then
            local d = curLucky - lastLucky
            if d >= 0 then pos = pos + 1 else neg = neg + 1 end
            table.insert(fields, {
                name = "Lucky Spins",
                value = ("**%s%s** `%s -> %s`"):format(
                    d >= 0 and "+" or "", fmtNum(d),
                    fmtNum(lastLucky), fmtNum(curLucky)),
            })
            lastLucky = curLucky
            getgenv().LuckyBaseline = fmtNum(lastLucky)
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

        refreshStatus()
    end
end)
-- TẠO MINI TOOLBAR NỔI (THAY CHO NÚT BÁNH RĂNG)
local miniGui = Instance.new("ScreenGui")
miniGui.Name = "UgbMiniToolbar"
miniGui.ResetOnSpawn = false
miniGui.DisplayOrder = 999999 -- Luôn nổi lên trên cùng
miniGui.Parent = PG

local bar = Instance.new("Frame")
bar.Size = UDim2.new(0, 260, 0, 32)
bar.Position = UDim2.new(0.5, -130, 0, 20)
bar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
bar.BackgroundTransparency = 0.2
bar.Active = true
bar.Parent = miniGui
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", bar).Color = Color3.fromRGB(60, 60, 80)

local function makeMiniBtn(text, x, w)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 24)
    b.Position = UDim2.new(0, x, 0.5, -12)
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Parent = bar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    return b
end

local btnDrag   = makeMiniBtn("≡", 4, 24)
local btnFight  = makeMiniBtn("FIGHT", 32, 45)
local btnLight  = makeMiniBtn("LIGHT", 81, 45)
local btnDodge  = makeMiniBtn("DODGE", 130, 50)
local btnBlock  = makeMiniBtn("BLOCK", 184, 45)
local btnClose  = makeMiniBtn("✕", 233, 24)
btnClose.BackgroundColor3 = Color3.fromRGB(200, 50, 50)

-- Kéo thả thanh toolbar
local dragging, dragStart, startPos
bar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = bar.Position
    end
end)
bar.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        bar.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
bar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- Cập nhật màu sắc nút dựa trên trạng thái
local function updateMiniUI()
    btnFight.BackgroundColor3 = getgenv().AutoFight and Color3.fromRGB(40, 170, 80) or Color3.fromRGB(40, 40, 60)
    btnLight.BackgroundColor3 = getgenv().AutoLight and Color3.fromRGB(40, 170, 80) or Color3.fromRGB(40, 40, 60)
    btnDodge.BackgroundColor3 = getgenv().AutoDodge and Color3.fromRGB(40, 170, 80) or Color3.fromRGB(40, 40, 60)
    btnBlock.BackgroundColor3 = getgenv().AutoBlock and Color3.fromRGB(40, 170, 80) or Color3.fromRGB(40, 40, 60)
end

-- Xử lý ẩn/hiện Rayfield
local function setRayfieldVisible(visible)
    local rgui = game:GetService("CoreGui"):FindFirstChild("Rayfield") or PG:FindFirstChild("Rayfield")
    if rgui then rgui.Enabled = visible end
end

-- Gắn sự kiện cho các nút trên Mini Toolbar
btnFight.MouseButton1Click:Connect(function()
    getgenv().AutoFight = not getgenv().AutoFight
    if getgenv().AutoFight then getgenv().AutoLight = true end
    _codeUpdate = true
    if FightToggle then FightToggle:Set(getgenv().AutoFight) end
    if LightToggle then LightToggle:Set(getgenv().AutoLight) end
    _codeUpdate = false
    updateMiniUI()
end)

btnLight.MouseButton1Click:Connect(function()
    getgenv().AutoLight = not getgenv().AutoLight
    _codeUpdate = true
    if LightToggle then LightToggle:Set(getgenv().AutoLight) end
    _codeUpdate = false
    updateMiniUI()
end)

btnDodge.MouseButton1Click:Connect(function()
    getgenv().AutoDodge = not getgenv().AutoDodge
    _codeUpdate = true
    if DodgeToggle then DodgeToggle:Set(getgenv().AutoDodge) end
    _codeUpdate = false
    updateMiniUI()
end)

btnBlock.MouseButton1Click:Connect(function()
    getgenv().AutoBlock = not getgenv().AutoBlock
    if not getgenv().AutoBlock and getgenv().Blocking then
        getgenv().Blocking = false
        keyEvent(false, BLOCK_KEY)
    end
    _codeUpdate = true
    if BlockToggle then BlockToggle:Set(getgenv().AutoBlock) end
    _codeUpdate = false
    updateMiniUI()
end)

btnDrag.MouseButton1Click:Connect(function()
    -- Bấm nút ≡ để mở bảng lớn Rayfield
    setRayfieldVisible(true)
end)

btnClose.MouseButton1Click:Connect(function()
    -- Bấm ✕ để ẩn hoàn toàn thanh toolbar này
    miniGui.Enabled = false
    Rayfield:Notify({Title="Toolbar Hidden", Content="Nhấn phím Z để bật lại thanh công cụ", Duration=4, Image=4483362458})
end)

-- Phím tắt: Nhấn Z để ẩn/hiện Toolbar
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.Z then
        miniGui.Enabled = not miniGui.Enabled
    end
end)

-- KHỞI TẠO UI RAYFIELD
local Window = Rayfield:CreateWindow({
    Name = "AI v22 BATTLE v33",
    LoadingTitle = "AI v22 BATTLE",
    LoadingSubtitle = "Loading",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)
MainTab:CreateSection("Account")
local SelfLabel = MainTab:CreateLabel(string.format("%s | %s | target: %s", MY_NAME, WHO, MY_TARGET_NAME or "none"), 4483362458)

MainTab:CreateSection("Automation")
local _codeUpdate = false
local FightToggle, LightToggle, TPToggle, DodgeToggle, BlockToggle

local function uiSetLight(v) if not _codeUpdate then getgenv().AutoLight = v; updateMiniUI() end end
local function uiSetFight(v)
    if _codeUpdate then return end
    getgenv().AutoFight = v
    if v and not getgenv().AutoLight then
        getgenv().AutoLight = true
        _codeUpdate = true; if LightToggle then LightToggle:Set(true) end; _codeUpdate = false
    end
    updateMiniUI()
end
local function uiSetTP(v) if not _codeUpdate then getgenv().AutoTP = v; if v then getgenv().TPBusy = false end end end
local function uiSetDodge(v) if not _codeUpdate then getgenv().AutoDodge = v; updateMiniUI() end end
local function uiSetBlock(v) 
    if not _codeUpdate then 
        getgenv().AutoBlock = v
        if not v and getgenv().Blocking then getgenv().Blocking = false; keyEvent(false, BLOCK_KEY) end 
        updateMiniUI()
    end 
end

FightToggle = MainTab:CreateToggle({ Name = "Fight", CurrentValue = false, Callback = uiSetFight })
LightToggle = MainTab:CreateToggle({ Name = "Auto Light", CurrentValue = false, Callback = uiSetLight })
TPToggle = MainTab:CreateToggle({ Name = "TP PAD", CurrentValue = false, Callback = uiSetTP })
DodgeToggle = MainTab:CreateToggle({ Name = "Auto Evade", CurrentValue = true, Callback = uiSetDodge })
BlockToggle = MainTab:CreateToggle({ Name = "Auto Block", CurrentValue = true, Callback = uiSetBlock })

local WebhookTab = Window:CreateTab("Webhook", 4483362458)
WebhookTab:CreateSection("Settings")
WebhookTab:CreateToggle({
    Name = "Webhook Enabled",
    CurrentValue = getgenv().WebhookToggle,
    Callback = function(v) getgenv().WebhookToggle = v end,
})
WebhookTab:CreateDropdown({
    Name = "Webhook Mode",
    Options = { "MAIN only", "ALL accounts" },
    CurrentOption = { getgenv().WebhookMode == "ALL" and "ALL accounts" or "MAIN only" },
    Callback = function(opt)
        local v = type(opt) == "table" and opt[1] or opt
        getgenv().WebhookMode = string.find(v, "MAIN") and "MAIN" or "ALL"
    end,
})

local StatsTab = Window:CreateTab("Stats", 4483362458)
StatsTab:CreateSection("Battle")
local ComboLbl = StatsTab:CreateLabel("Combo: #1/" .. #COMBOS, 4483362458)
local WebhookLbl = StatsTab:CreateLabel("Webhook: 0 (F:0)", 4483362458)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            WebhookLbl:Set(string.format("Webhook: %d (F:%d)", getgenv().WebhookSent, getgenv().WebhookFailed))
            ComboLbl:Set(string.format("Combo: #%d/%d", getgenv().ComboIdx, #COMBOS))
            updateMiniUI()
        end)
    end
end)

-- CÁC VÒNG LẶP CHIẾN ĐẤU
task.spawn(function()
    local matchEndAt = nil
    while task.wait(0.3) do
        if isMatchActive() then
            matchEndAt = nil
            if not getgenv().InMatch then
                getgenv().InMatch = true
                task.spawn(function()
                    task.wait(DELAY_BEFORE_FIGHT)
                    if getgenv().InMatch and not getgenv().AutoFight then
                        getgenv().AutoFight = true; getgenv().AutoLight = true
                        _codeUpdate = true; if FightToggle then FightToggle:Set(true) end; if LightToggle then LightToggle:Set(true) end; _codeUpdate = false
                        updateMiniUI()
                    end
                end)
            end
        else
            if getgenv().InMatch then
                if not matchEndAt then matchEndAt = tick()
                elseif tick() - matchEndAt >= MATCH_END_DEBOUNCE then
                    getgenv().InMatch = false; getgenv().AutoTP = true
                    _codeUpdate = true; if TPToggle then TPToggle:Set(true) end; _codeUpdate = false
                    matchEndAt = nil
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if getgenv().AutoFight and not getgenv().AutoLight then getgenv().AutoLight = true; _codeUpdate = true; if LightToggle then LightToggle:Set(true) end; _codeUpdate = false; updateMiniUI() end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if getgenv().AutoTP and not getgenv().TPBusy and not getgenv().InMatch then
            getgenv().TPBusy = true
            pcall(function()
                local hrp = getHRP()
                if hrp then
                    hrp.CFrame = CFrame.new(MY_PAD.X, MY_PAD.Y + 50, MY_PAD.Z)
                    for _ = 1, 20 do if not getgenv().AutoTP or hrp.Position.Y <= MY_PAD.Y + 1 then break end; hrp.CFrame = CFrame.new(MY_PAD.X, hrp.Position.Y - 5, MY_PAD.Z); task.wait(0.08) end
                    for _ = 1, 40 do if not getgenv().AutoTP or isMatchActive() then getgenv().AutoTP = false; _codeUpdate = true; if TPToggle then TPToggle:Set(false) end; _codeUpdate = false; break end; task.wait(0.5) end
                end
            end)
            getgenv().TPBusy = false
        elseif getgenv().AutoTP and getgenv().InMatch then
            getgenv().AutoTP = false; _codeUpdate = true; if TPToggle then TPToggle:Set(false) end; _codeUpdate = false
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if getgenv().AutoFight and getgenv().InMatch then
            pcall(function()
                local hrp, target = getHRP(), getTargetHRP()
                if hrp and target and not getgenv().Dodging then
                    local dist = (target.Position - hrp.Position).Magnitude
                    if dist > ATTACK_RANGE then hrp.CFrame = CFrame.lookAt(target.Position + (hrp.Position - target.Position).Unit * TP_OFFSET, target.Position)
                    else hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(target.Position.X, hrp.Position.Y, target.Position.Z)) end
                end
            end)
        end
    end
end)

task.spawn(function()
    local lastHealth, blockUntil, blockCooldownUntil, staminaBlockUntil, staminaCooldownUntil = nil, 0, 0, 0, 0
    while task.wait(0.05) do
        if getgenv().AutoBlock and getgenv().AutoFight and getgenv().InMatch then
            local h, stam, now = readMyHealth(), readMyStamina(), tick()
            if h and lastHealth and h < lastHealth and now > blockCooldownUntil then blockUntil = now + BLOCK_DURATION; blockCooldownUntil = blockUntil + BLOCK_COOLDOWN end
            lastHealth = h
            if stam and stam < STAMINA_LOW and now > staminaCooldownUntil then staminaBlockUntil = now + STAMINA_BLOCK_DUR; staminaCooldownUntil = staminaBlockUntil + STAMINA_BLOCK_CD end
            local shouldBlock = now < blockUntil or now < staminaBlockUntil
            if shouldBlock ~= getgenv().Blocking then getgenv().Blocking = shouldBlock; keyEvent(shouldBlock, BLOCK_KEY) end
        else
            if getgenv().Blocking then getgenv().Blocking = false; keyEvent(false, BLOCK_KEY) end
            lastHealth = nil
        end
    end
end)

task.spawn(function()
    local ultReadyAt = tick() + math.random(3, 6)
    while task.wait(0.1) do
        if CAN_ULT and getgenv().AutoFight and getgenv().InMatch and not getgenv().Blocking and tick() >= ultReadyAt then
            if fireUlt() then ultReadyAt = tick() + ULT_COOLDOWN_MIN + math.random() * (ULT_COOLDOWN_MAX - ULT_COOLDOWN_MIN) end
        end
    end
end)

task.spawn(function()
    while task.wait(0.05) do
        if getgenv().AutoLight and getgenv().InMatch and not getgenv().Blocking and not getgenv().Dodging then
            local combo = COMBOS[getgenv().ComboIdx]
            for _, move in ipairs(combo) do
                if not getgenv().AutoLight or not getgenv().InMatch or getgenv().Blocking or getgenv().Dodging then break end
                clickTarget(move[1]); task.wait(move[2])
            end
            getgenv().ComboIdx = (getgenv().ComboIdx % #COMBOS) + 1
            task.wait(COMBO_PAUSE_MIN + math.random() * (COMBO_PAUSE_MAX - COMBO_PAUSE_MIN))
        end
    end
end)

task.spawn(function()
    while task.wait(DODGE_CHECK_INTERVAL) do
        if getgenv().AutoDodge and getgenv().AutoFight and getgenv().InMatch and not getgenv().Blocking and not getgenv().Dodging and math.random() < DODGE_CHANCE then
            getgenv().Dodging = true
            task.spawn(function()
                local dirKey = DODGE_KEYS[math.random(1, #DODGE_KEYS)]
                keyEvent(true, Enum.KeyCode.Space); keyEvent(true, dirKey); task.wait(DODGE_HOLD); keyEvent(false, dirKey); keyEvent(false, Enum.KeyCode.Space)
                task.wait(0.05); getgenv().Dodging = false
            end)
        end
    end
end)

-- WEBHOOK STARTUP & TRACKER
task.spawn(function()
    task.wait(1.0); waitForUBG(3)
    if checkWebhookReason() then webhookCurrently() end
end)

task.spawn(function()
    waitForUBG(6)
    local last = readUBG()
    if not last then return end
    local lastSpins, lastCash, lastLucky = parseNum(last.spins), parseNum(last.cash), parseNum(last.lucky)

    while true do
        task.wait(UBG_INTERVAL)
        local cur = readUBG()
        if not cur then break end
        local curSpins, curCash, curLucky = parseNum(cur.spins), parseNum(cur.cash), parseNum(cur.lucky)
        local fields, pos, neg = {}, 0, 0

        if curSpins and lastSpins and curSpins ~= lastSpins then
            local d = curSpins - lastSpins; if d >= 0 then pos = pos + 1 else neg = neg + 1 end
            table.insert(fields, { name = "Spins", value = ("**%s%s** `%s -> %s`"):format(d >= 0 and "+" or "", fmtNum(d), fmtNum(lastSpins), fmtNum(curSpins)) })
            lastSpins = curSpins
        end
        if curCash and lastCash and curCash ~= lastCash then
            local d = curCash - lastCash; if d >= 0 then pos = pos + 1 else neg = neg + 1 end
            table.insert(fields, { name = "Cash", value = ("**%s%s** `%s -> %s`"):format(d >= 0 and "+" or "", fmtNum(d), fmtNum(lastCash), fmtNum(curCash)) })
            lastCash = curCash
        end
        if curLucky and lastLucky and curLucky ~= lastLucky then
            local d = curLucky - lastLucky; if d >= 0 then pos = pos + 1 else neg = neg + 1 end
            table.insert(fields, { name = "Lucky Spins", value = ("**%s%s** `%s -> %s`"):format(d >= 0 and "+" or "", fmtNum(d), fmtNum(lastLucky), fmtNum(curLucky)) })
            lastLucky = curLucky
        end

        if #fields > 0 and checkWebhookReason() then webhookStatsChanged(fields, pos, neg) end
    end
end)

Rayfield:Notify({
    Title = "AI v22 BATTLE",
    Content = string.format("%s | %s | target: %s", MY_NAME, WHO, MY_TARGET_NAME or "none"),
    Duration = 6,
    Image = 4483362458,
})

print(string.format("[AI v22] %s | %s | target=%s | mode=%s main=%s toggle=%s HTTP=%s",
    MY_NAME, WHO, MY_TARGET_NAME or "NONE",
    getgenv().WebhookMode, tostring(IS_MAIN_ACCOUNT), tostring(getgenv().WebhookToggle), httpMethod))
    
