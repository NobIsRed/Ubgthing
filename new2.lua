local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")
local VIM = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

local APP_NAME = "Untitle Boxing Game By Nobred"
local APP_VERSION = "2.1 Mono"

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

local PAD_GROUPS = {
    ["Pad 1"] = {
        ["GHHTWHOWR"]          = true,
        ["GHfhahfiuaf3"]       = true,
        ["TamMiniMini"]        = true,
        ["HE4RTSFORJ1"]        = true,
        ["tristitia006"]       = true,
        ["XxStar_R0guexX2013"] = true,
        ["torosushie"]         = true,
    },
    ["Pad 2"] = {
        ["GHfhahfiuaf2"]       = true,
        ["NoobIsRedI"]         = true,
        ["RRecruiter1"]        = true,
        ["ElRusoBB0"]          = true,
        ["therealdavidbro770"] = true,
        ["MannsLease_844"]     = true,
        ["IraciDrane_670"]     = true,
    },
}

local TARGET_WHITELIST = {
    ["GHHTWHOWR"]          = true,
    ["GHfhahfiuaf2"]       = true,
    ["GHfhahfiuaf3"]       = true,
    ["NoobIsRedI"]         = true,
    ["TamMiniMini"]        = true,
    ["RRecruiter1"]        = true,
    ["HE4RTSFORJ1"]        = true,
    ["ElRusoBB0"]          = true,
    ["tristitia006"]       = true,
    ["therealdavidbro770"] = true,
    ["XxStar_R0guexX2013"] = true,
    ["MannsLease_844"]     = true,
    ["torosushie"]         = true,
    ["IraciDrane_670"]     = true,
}
local WHITELIST_LOWER = {}
for name in pairs(TARGET_WHITELIST) do
    WHITELIST_LOWER[name:lower()] = name
end

local MY_NAME = LP.Name
local MY_NAME_LOWER = MY_NAME:lower()
local IS_MAIN_ACCOUNT = (MY_NAME == MAIN_WEBHOOK_ACCOUNT)

local MY_PAD = nil
for padName, accounts in pairs(PAD_GROUPS) do
    if accounts[MY_NAME] then
        MY_PAD = padName
        break
    end
end

if MY_PAD then
    getgenv().SelectedPad = MY_PAD
    print("[PAD] Auto-assigned: " .. MY_PAD .. " for " .. MY_NAME)
else
    getgenv().SelectedPad = getgenv().SelectedPad or "Pad 1"
    print("[PAD] No group match for " .. MY_NAME .. ", fallback: " .. getgenv().SelectedPad)
end
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
getgenv().WebhookMode = getgenv().WebhookMode or "ALL"
getgenv().LastWebhookResult = "none"

if getgenv().TargetLock == nil then
    getgenv().TargetLock = WHITELIST_LOWER[MY_NAME_LOWER] ~= nil
end
getgenv().RejectBusy = false
getgenv().RejectedCount = getgenv().RejectedCount or 0
getgenv().LastRejectedName = nil
getgenv().LastRejectedAt = 0

if getgenv().NotifyCash        == nil then getgenv().NotifyCash        = false end
if getgenv().NotifySpins       == nil then getgenv().NotifySpins       = true  end
if getgenv().NotifyLucky       == nil then getgenv().NotifyLucky       = true  end
if getgenv().NotifyLuckyCrate  == nil then getgenv().NotifyLuckyCrate  = true  end
if getgenv().NotifyDisconnect  == nil then getgenv().NotifyDisconnect  = true  end

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

-- ============================================================
-- CUSTOM UI — Clean Minimal Monochrome v2.1
-- Fixed: proper centering, no floating UI, in-place dropdown
-- Clean toggles, clean buttons, clean icons
-- ============================================================
local function buildCustomUI()
    local UIS = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")

    local oldGui = PG:FindFirstChild("UBG_MonoUI")
    if oldGui then oldGui:Destroy() end

    -- ===== THEME (pure mono, flat, minimal) =====
    local COL_BG       = Color3.fromRGB(10, 10, 10)
    local COL_SIDEBAR  = Color3.fromRGB(14, 14, 14)
    local COL_CARD     = Color3.fromRGB(20, 20, 20)
    local COL_CARD_H   = Color3.fromRGB(26, 26, 26)
    local COL_TEXT     = Color3.fromRGB(245, 245, 245)
    local COL_TEXT2    = Color3.fromRGB(180, 180, 180)
    local COL_DIM      = Color3.fromRGB(130, 130, 130)
    local COL_MUTED    = Color3.fromRGB(70, 70, 70)
    local COL_BORDER   = Color3.fromRGB(28, 28, 28)
    local COL_BORDER_H = Color3.fromRGB(44, 44, 44)
    local COL_TRACK_OFF = Color3.fromRGB(38, 38, 38)
    local COL_KNOB_OFF  = Color3.fromRGB(110, 110, 110)
    local COL_TRACK_ON  = Color3.fromRGB(245, 245, 245)
    local COL_KNOB_ON   = Color3.fromRGB(10, 10, 10)
    local COL_ERR      = Color3.fromRGB(232, 80, 80)
    local COL_OK       = Color3.fromRGB(74, 200, 118)

    local F_REG  = Enum.Font.Gotham
    local F_MED  = Enum.Font.GothamMedium
    local F_BOLD = Enum.Font.GothamBold

    -- ===== RESPONSIVE SCALE =====
    local cam = workspace.CurrentCamera
    local vpSize = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local IS_TOUCH = UIS.TouchEnabled and not UIS.MouseEnabled
    local SCALE = math.clamp(vpSize.X / 1100, 0.85, 1.05)
    if IS_TOUCH then SCALE = math.clamp(vpSize.X / 720, 0.9, 1.15) end
    local function S(n) return math.max(1, math.floor(n * SCALE + 0.5)) end

    local WIN_W = math.min(S(560), vpSize.X - S(28))
    local WIN_H = math.min(S(440), vpSize.Y - S(80))
    if IS_TOUCH and vpSize.X < 720 then
        WIN_W = vpSize.X - S(20)
        WIN_H = math.min(vpSize.Y - S(30), S(600))
    end

    -- ===== HELPERS =====
    local function corner(inst, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r or S(8))
        c.Parent = inst
        return c
    end
    local function stroke(inst, color, thick)
        local s = Instance.new("UIStroke")
        s.Color = color or COL_BORDER
        s.Thickness = thick or 1
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = inst
        return s
    end
    local function tween(inst, props, dur, style)
        local t = TweenService:Create(inst,
            TweenInfo.new(dur or 0.15, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            props)
        t:Play()
        return t
    end

    -- ===== SCREENGUI =====
    local gui = Instance.new("ScreenGui")
    gui.Name = "UBG_MonoUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 100
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PG

    -- ===== NOTIFICATIONS (bottom-right, auto-size, max 4) =====
    local NOTIFY_MAX = 4
    local NOTIFY_W = math.min(S(280), vpSize.X - S(32))
    local notifyHolder = Instance.new("Frame")
    notifyHolder.Name = "NotifyHolder"
    notifyHolder.Size = UDim2.fromOffset(NOTIFY_W, 0)
    notifyHolder.AnchorPoint = Vector2.new(1, 1)
    notifyHolder.Position = UDim2.new(1, -S(16), 1, -S(16))
    notifyHolder.BackgroundTransparency = 1
    notifyHolder.AutomaticSize = Enum.AutomaticSize.Y
    notifyHolder.ZIndex = 2000
    notifyHolder.Parent = gui
    local nl = Instance.new("UIListLayout")
    nl.SortOrder = Enum.SortOrder.LayoutOrder
    nl.VerticalAlignment = Enum.VerticalAlignment.Bottom
    nl.Padding = UDim.new(0, S(6))
    nl.Parent = notifyHolder
    local nCount = 0

    local Rayfield = {}

    function Rayfield:Notify(o)
        o = o or {}
        if nCount >= NOTIFY_MAX then
            local cards = {}
            for _, c in ipairs(notifyHolder:GetChildren()) do
                if c:IsA("Frame") then table.insert(cards, c) end
            end
            table.sort(cards, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
            if cards[1] then cards[1]:Destroy(); nCount = math.max(0, nCount - 1) end
        end
        nCount = nCount + 1

        local cardH = S(62)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 0)
        card.BackgroundColor3 = COL_CARD
        card.BorderSizePixel = 0
        card.LayoutOrder = math.floor(tick() * 1000)
        card.ZIndex = 2001
        card.ClipsDescendants = true
        card.Parent = notifyHolder
        corner(card, S(10))
        stroke(card, COL_BORDER, 1)

        local accent = Instance.new("Frame")
        accent.Size = UDim2.new(0, 2, 1, -S(16))
        accent.Position = UDim2.fromOffset(0, S(8))
        accent.BackgroundColor3 = COL_TEXT
        accent.BorderSizePixel = 0
        accent.ZIndex = 2002
        accent.Parent = card
        corner(accent, S(1))

        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, -S(44), 0, S(16))
        tl.Position = UDim2.fromOffset(S(14), S(9))
        tl.BackgroundTransparency = 1
        tl.Text = o.Title or "Notify"
        tl.TextColor3 = COL_TEXT
        tl.Font = F_MED
        tl.TextSize = S(11)
        tl.TextXAlignment = Enum.TextXAlignment.Left
        tl.TextTruncate = Enum.TextTruncate.AtEnd
        tl.ZIndex = 2002
        tl.Parent = card

        local cl = Instance.new("TextLabel")
        cl.Size = UDim2.new(1, -S(38), 0, S(28))
        cl.Position = UDim2.fromOffset(S(14), S(28))
        cl.BackgroundTransparency = 1
        cl.Text = o.Content or ""
        cl.TextColor3 = COL_DIM
        cl.Font = F_REG
        cl.TextSize = S(10)
        cl.TextWrapped = true
        cl.TextXAlignment = Enum.TextXAlignment.Left
        cl.TextYAlignment = Enum.TextYAlignment.Top
        cl.ZIndex = 2002
        cl.Parent = card

        local cb = Instance.new("TextButton")
        cb.Size = UDim2.fromOffset(S(20), S(20))
        cb.Position = UDim2.new(1, -S(24), 0, S(7))
        cb.BackgroundTransparency = 1
        cb.Text = "✕"
        cb.TextColor3 = COL_MUTED
        cb.Font = F_BOLD
        cb.TextSize = S(10)
        cb.AutoButtonColor = false
        cb.ZIndex = 2003
        cb.Parent = card
        cb.MouseEnter:Connect(function() cb.TextColor3 = COL_TEXT end)
        cb.MouseLeave:Connect(function() cb.TextColor3 = COL_MUTED end)
        cb.MouseButton1Click:Connect(function()
            if card and card.Parent then
                nCount = math.max(0, nCount - 1)
                card:Destroy()
            end
        end)

        tween(card, { Size = UDim2.new(1, 0, 0, cardH) }, 0.25)

        task.delay(o.Duration or 4, function()
            if not card or not card.Parent then return end
            nCount = math.max(0, nCount - 1)
            local t = tween(card, { Size = UDim2.new(1, 0, 0, 0) }, 0.2, Enum.EasingStyle.Quart)
            t.Completed:Connect(function()
                if card and card.Parent then card:Destroy() end
            end)
        end)
    end

    -- ===== RESTORE PILL =====
    local restoreBtn = Instance.new("TextButton")
    restoreBtn.Name = "RestoreUI"
    restoreBtn.Size = UDim2.fromOffset(S(104), S(38))
    restoreBtn.AnchorPoint = Vector2.new(0.5, 0)
    restoreBtn.Position = UDim2.new(0.5, 0, 0, S(16))
    restoreBtn.BackgroundColor3 = COL_CARD
    restoreBtn.TextColor3 = COL_TEXT
    restoreBtn.Text = "◉  UBG"
    restoreBtn.Font = F_MED
    restoreBtn.TextSize = S(12)
    restoreBtn.BorderSizePixel = 0
    restoreBtn.AutoButtonColor = false
    restoreBtn.Visible = false
    restoreBtn.ZIndex = 500
    restoreBtn.Parent = gui
    corner(restoreBtn, S(19))
    stroke(restoreBtn, COL_BORDER, 1)
    restoreBtn.MouseEnter:Connect(function()
        tween(restoreBtn, { BackgroundColor3 = COL_CARD_H }, 0.15)
    end)
    restoreBtn.MouseLeave:Connect(function()
        tween(restoreBtn, { BackgroundColor3 = COL_CARD }, 0.15)
    end)

    -- ===== DRAG RESTORE TOGGLE =====
    local restoreDragging = false
    local restoreDragStart = nil
    local restoreStartPos = nil
    local restoreMoved = false

    restoreBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            restoreDragging = true
            restoreMoved = false
            restoreDragStart = input.Position
            restoreStartPos = restoreBtn.Position
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if not restoreDragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - restoreDragStart
            if math.abs(delta.X) > S(4) or math.abs(delta.Y) > S(4) then
                restoreMoved = true
            end
            if restoreMoved then
                local nx = restoreStartPos.X.Offset + delta.X
                local ny = restoreStartPos.Y.Offset + delta.Y
                local halfW = restoreBtn.AbsoluteSize.X / 2
                local halfH = restoreBtn.AbsoluteSize.Y / 2
                nx = math.clamp(nx, -vpSize.X / 2 + halfW, vpSize.X / 2 - halfW)
                ny = math.clamp(ny, S(4), vpSize.Y - halfH * 2 - S(4))
                restoreBtn.Position = UDim2.new(0.5, nx, 0, ny)
            end
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            restoreDragging = false
        end
    end)

    -- ===== WINDOW =====
    function Rayfield:CreateWindow(o)
        o = o or {}
        local W, H = WIN_W, WIN_H

        local window = Instance.new("Frame")
        window.Name = "Window"
        window.AnchorPoint = Vector2.new(0.5, 0.5)
        window.Size = UDim2.fromOffset(W, H)
        window.Position = UDim2.new(0.5, 0, 0.5, 0)   -- ← properly centered, no floating
        window.BackgroundColor3 = COL_BG
        window.BorderSizePixel = 0
        window.ClipsDescendants = true
        window.ZIndex = 100
        window.Parent = gui
        corner(window, S(12))
        stroke(window, COL_BORDER, 1)

        -- ===== HEADER =====
        local header = Instance.new("Frame")
        header.Name = "Header"
        header.Size = UDim2.new(1, 0, 0, S(56))
        header.BackgroundTransparency = 1
        header.Active = true
        header.ZIndex = 101
        header.Parent = window

        -- App icon box (minimal, no emoji)
        local iconBox = Instance.new("Frame")
        iconBox.Size = UDim2.fromOffset(S(28), S(28))
        iconBox.Position = UDim2.fromOffset(S(18), S(14))
        iconBox.BackgroundColor3 = COL_TEXT
        iconBox.BorderSizePixel = 0
        iconBox.ZIndex = 103
        iconBox.Parent = header
        corner(iconBox, S(6))

        local iconTxt = Instance.new("TextLabel")
        iconTxt.Size = UDim2.new(1, 0, 1, 0)
        iconTxt.BackgroundTransparency = 1
        iconTxt.Text = "◉"
        iconTxt.TextColor3 = COL_BG
        iconTxt.Font = F_BOLD
        iconTxt.TextSize = S(15)
        iconTxt.ZIndex = 104
        iconTxt.Parent = iconBox

        -- Title
        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -S(160), 0, S(16))
        titleLbl.Position = UDim2.fromOffset(S(56), S(12))
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = o.Name or "Window"
        titleLbl.TextColor3 = COL_TEXT
        titleLbl.Font = F_MED
        titleLbl.TextSize = S(12)
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
        titleLbl.ZIndex = 103
        titleLbl.Parent = header

        -- Subtitle
        local subLbl = Instance.new("TextLabel")
        subLbl.Size = UDim2.new(1, -S(160), 0, S(12))
        subLbl.Position = UDim2.fromOffset(S(56), S(30))
        subLbl.BackgroundTransparency = 1
        subLbl.Text = MY_NAME .. "  ·  " .. getgenv().SelectedPad .. "  ·  v" .. APP_VERSION
        subLbl.TextColor3 = COL_DIM
        subLbl.Font = F_REG
        subLbl.TextSize = S(9)
        subLbl.TextXAlignment = Enum.TextXAlignment.Left
        subLbl.TextTruncate = Enum.TextTruncate.AtEnd
        subLbl.ZIndex = 103
        subLbl.Parent = header

        -- Minimize button
        local minBtn = Instance.new("TextButton")
        minBtn.Size = UDim2.fromOffset(S(26), S(26))
        minBtn.Position = UDim2.new(1, -S(60), 0, S(15))
        minBtn.BackgroundColor3 = Color3.new(1, 1, 1)
        minBtn.BackgroundTransparency = 1
        minBtn.TextColor3 = COL_DIM
        minBtn.Text = "—"
        minBtn.Font = F_BOLD
        minBtn.TextSize = S(13)
        minBtn.BorderSizePixel = 0
        minBtn.AutoButtonColor = false
        minBtn.ZIndex = 103
        minBtn.Parent = header
        corner(minBtn, S(6))
        minBtn.MouseEnter:Connect(function()
            tween(minBtn, { BackgroundTransparency = 0, BackgroundColor3 = COL_CARD, TextColor3 = COL_TEXT }, 0.12)
        end)
        minBtn.MouseLeave:Connect(function()
            tween(minBtn, { BackgroundTransparency = 1, TextColor3 = COL_DIM }, 0.12)
        end)

        -- Close button (also minimizes — script keeps running)
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.fromOffset(S(26), S(26))
        closeBtn.Position = UDim2.new(1, -S(30), 0, S(15))
        closeBtn.BackgroundColor3 = Color3.new(1, 1, 1)
        closeBtn.BackgroundTransparency = 1
        closeBtn.TextColor3 = COL_DIM
        closeBtn.Text = "✕"
        closeBtn.Font = F_BOLD
        closeBtn.TextSize = S(11)
        closeBtn.BorderSizePixel = 0
        closeBtn.AutoButtonColor = false
        closeBtn.ZIndex = 103
        closeBtn.Parent = header
        corner(closeBtn, S(6))
        closeBtn.MouseEnter:Connect(function()
            tween(closeBtn, { BackgroundTransparency = 0, BackgroundColor3 = COL_ERR, TextColor3 = COL_TEXT }, 0.12)
        end)
        closeBtn.MouseLeave:Connect(function()
            tween(closeBtn, { BackgroundTransparency = 1, TextColor3 = COL_DIM }, 0.12)
        end)

        -- ===== DRAG (safe, no drift) =====
        local dragging, dragStart, startPos = false, nil, nil
        header.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = i.Position
                startPos = window.Position
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if not dragging then return end
            if i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch then
                local d = i.Position - dragStart
                local nx = startPos.X.Offset + d.X
                local ny = startPos.Y.Offset + d.Y
                local maxX = vpSize.X / 2 - S(60)
                local minX = -vpSize.X / 2 + S(60)
                local maxY = vpSize.Y / 2 - S(80)
                local minY = -vpSize.Y / 2 + S(40)
                nx = math.clamp(nx, minX, maxX)
                ny = math.clamp(ny, minY, maxY)
                window.Position = UDim2.new(0.5, nx, 0.5, ny)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        -- ===== MINIMIZE / RESTORE (script keeps running) =====
        local openDropdowns = {}
        local function registerDropdown(fn)
            table.insert(openDropdowns, fn)
        end
        local function closeAllDropdowns()
            for _, fn in ipairs(openDropdowns) do pcall(fn) end
        end

        local function minimize()
            closeAllDropdowns()
            window.Visible = false
            restoreBtn.Visible = true
            restoreBtn.Size = UDim2.fromOffset(S(0), S(0))
            tween(restoreBtn, { Size = UDim2.fromOffset(S(104), S(38)) }, 0.22, Enum.EasingStyle.Back)
        end
        local function restore()
            restoreBtn.Visible = false
            window.Visible = true
            window.Size = UDim2.fromOffset(0, 0)
            tween(window, { Size = UDim2.fromOffset(W, H) }, 0.25, Enum.EasingStyle.Back)
        end
        minBtn.MouseButton1Click:Connect(minimize)
        closeBtn.MouseButton1Click:Connect(minimize)
        restoreBtn.MouseButton1Click:Connect(function()
            if restoreMoved then
                restoreMoved = false
                return
            end
            restore()
        end)

        UIS.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode == Enum.KeyCode.RightShift then
                if window.Visible then minimize() else restore() end
            end
        end)

        -- ===== SIDEBAR =====
        local SIDEBAR_W = math.min(S(150), W * 0.32)
        local sidebar = Instance.new("Frame")
        sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -S(72))
        sidebar.Position = UDim2.fromOffset(S(14), S(64))
        sidebar.BackgroundColor3 = COL_SIDEBAR
        sidebar.BorderSizePixel = 0
        sidebar.ZIndex = 101
        sidebar.Parent = window
        corner(sidebar, S(10))
        stroke(sidebar, COL_BORDER, 1)

        local tabList = Instance.new("Frame")
        tabList.Size = UDim2.new(1, -S(8), 1, -S(12))
        tabList.Position = UDim2.fromOffset(S(4), S(6))
        tabList.BackgroundTransparency = 1
        tabList.ZIndex = 102
        tabList.Parent = sidebar
        local tLay = Instance.new("UIListLayout")
        tLay.SortOrder = Enum.SortOrder.LayoutOrder
        tLay.Padding = UDim.new(0, S(2))
        tLay.Parent = tabList

        -- ===== CONTENT =====
        local content = Instance.new("Frame")
        content.Size = UDim2.new(1, -(SIDEBAR_W + S(22)), 1, -S(72))
        content.Position = UDim2.fromOffset(SIDEBAR_W + S(22), S(64))
        content.BackgroundTransparency = 1
        content.ZIndex = 101
        content.Parent = window

        local tabs = {}
        local activeName = nil
        local tabIdx = 0

        local Window = {}

        function Window:CreateTab(name, icon)
            tabIdx = tabIdx + 1
            icon = icon or "•"

            local tBtn = Instance.new("TextButton")
            tBtn.Size = UDim2.new(1, 0, 0, S(38))
            tBtn.BackgroundColor3 = COL_CARD
            tBtn.BackgroundTransparency = 1
            tBtn.TextColor3 = COL_DIM
            tBtn.Text = ""
            tBtn.Font = F_MED
            tBtn.TextSize = S(12)
            tBtn.BorderSizePixel = 0
            tBtn.AutoButtonColor = false
            tBtn.LayoutOrder = tabIdx
            tBtn.ZIndex = 103
            tBtn.TextXAlignment = Enum.TextXAlignment.Left
            tBtn.Parent = tabList
            corner(tBtn, S(7))

            -- Active indicator bar
            local indicator = Instance.new("Frame")
            indicator.Size = UDim2.new(0, S(2), 0, S(16))
            indicator.Position = UDim2.new(0, 0, 0.5, -S(8))
            indicator.BackgroundColor3 = COL_TEXT
            indicator.BackgroundTransparency = 1
            indicator.BorderSizePixel = 0
            indicator.ZIndex = 104
            indicator.Parent = tBtn
            corner(indicator, S(1))

            -- Icon
            local iconLbl = Instance.new("TextLabel")
            iconLbl.Size = UDim2.fromOffset(S(18), S(18))
            iconLbl.Position = UDim2.fromOffset(S(14), 0.5 * S(38) - S(9))
            iconLbl.BackgroundTransparency = 1
            iconLbl.Text = icon
            iconLbl.TextColor3 = COL_MUTED
            iconLbl.Font = F_MED
            iconLbl.TextSize = S(12)
            iconLbl.ZIndex = 104
            iconLbl.Parent = tBtn

            -- Text
            local txtLbl = Instance.new("TextLabel")
            txtLbl.Size = UDim2.new(1, -S(40), 1, 0)
            txtLbl.Position = UDim2.fromOffset(S(34), 0)
            txtLbl.BackgroundTransparency = 1
            txtLbl.Text = name
            txtLbl.TextColor3 = COL_DIM
            txtLbl.Font = F_MED
            txtLbl.TextSize = S(12)
            txtLbl.TextXAlignment = Enum.TextXAlignment.Left
            txtLbl.TextTruncate = Enum.TextTruncate.AtEnd
            txtLbl.ZIndex = 104
            txtLbl.Parent = tBtn

            -- Page
            local page = Instance.new("ScrollingFrame")
            page.Size = UDim2.new(1, 0, 1, 0)
            page.BackgroundTransparency = 1
            page.BorderSizePixel = 0
            page.ScrollBarThickness = S(3)
            page.ScrollBarImageColor3 = COL_BORDER_H
            page.CanvasSize = UDim2.new(0, 0, 0, 0)
            page.Visible = false
            page.ZIndex = 102
            page.Parent = content
            local pLay = Instance.new("UIListLayout")
            pLay.SortOrder = Enum.SortOrder.LayoutOrder
            pLay.Padding = UDim.new(0, S(6))
            pLay.Parent = page
            pLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                page.CanvasSize = UDim2.new(0, 0, 0, pLay.AbsoluteContentSize.Y + S(8))
            end)

            local tab = { page = page, btn = tBtn, indicator = indicator, order = 0, name = name }
            tabs[name] = tab

            local function activate()
                for _n, t in pairs(tabs) do
                    t.page.Visible = false
                    tween(t.btn, { BackgroundTransparency = 1 }, 0.12)
                    tween(t.indicator, { BackgroundTransparency = 1 }, 0.12)
                    for _, ch in ipairs(t.btn:GetChildren()) do
                        if ch:IsA("TextLabel") then
                            tween(ch, { TextColor3 = COL_DIM }, 0.12)
                        end
                    end
                end
                page.Visible = true
                tween(tBtn, { BackgroundTransparency = 1 }, 0.12)
                tween(indicator, { BackgroundTransparency = 0 }, 0.12)
                tween(txtLbl, { TextColor3 = COL_TEXT }, 0.12)
                tween(iconLbl, { TextColor3 = COL_TEXT }, 0.12)
                activeName = name
            end
            tBtn.MouseButton1Click:Connect(activate)
            if not activeName then activate() end

            local Tab = {}

            function Tab:CreateSection(sName)
                tab.order = tab.order + 1
                local s = Instance.new("Frame")
                s.Size = UDim2.new(1, -S(6), 0, S(26))
                s.BackgroundTransparency = 1
                s.LayoutOrder = tab.order
                s.ZIndex = 103
                s.Parent = page

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -S(12), 1, 0)
                lbl.Position = UDim2.fromOffset(S(6), 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = string.upper(sName)
                lbl.TextColor3 = COL_DIM
                lbl.Font = F_BOLD
                lbl.TextSize = S(9)
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextYAlignment = Enum.TextYAlignment.Bottom
                lbl.ZIndex = 104
                lbl.Parent = s
                return s
            end

            function Tab:CreateToggle(to)
                to = to or {}
                tab.order = tab.order + 1

                local card = Instance.new("Frame")
                card.Size = UDim2.new(1, -S(6), 0, S(44))
                card.BackgroundColor3 = COL_CARD
                card.BorderSizePixel = 0
                card.LayoutOrder = tab.order
                card.ZIndex = 103
                card.Parent = page
                corner(card, S(8))
                stroke(card, COL_BORDER, 1)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -S(76), 1, 0)
                lbl.Position = UDim2.fromOffset(S(14), 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = to.Name or "Toggle"
                lbl.TextColor3 = COL_TEXT
                lbl.Font = F_MED
                lbl.TextSize = S(12)
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextTruncate = Enum.TextTruncate.AtEnd
                lbl.ZIndex = 104
                lbl.Parent = card

                -- Clean toggle
                local trackW, trackH = S(36), S(20)
                local knobSz = trackH - S(4)
                local travel = trackW - knobSz - S(4)

                local track = Instance.new("Frame")
                track.Size = UDim2.fromOffset(trackW, trackH)
                track.Position = UDim2.new(1, -trackW - S(12), 0.5, -trackH/2)
                track.BackgroundColor3 = COL_TRACK_OFF
                track.BorderSizePixel = 0
                track.ZIndex = 104
                track.Parent = card
                corner(track, trackH/2)
                stroke(track, COL_BORDER, 1)

                local knob = Instance.new("Frame")
                knob.Size = UDim2.fromOffset(knobSz, knobSz)
                knob.Position = UDim2.fromOffset(S(2), S(2))
                knob.BackgroundColor3 = COL_KNOB_OFF
                knob.BorderSizePixel = 0
                knob.ZIndex = 105
                knob.Parent = track
                corner(knob, knobSz/2)

                local val = to.CurrentValue and true or false
                local function render(anim)
                    local info = TweenInfo.new(anim and 0.15 or 0,
                        Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                    TweenService:Create(track, info, {
                        BackgroundColor3 = val and COL_TRACK_ON or COL_TRACK_OFF
                    }):Play()
                    TweenService:Create(knob, info, {
                        Position = val and UDim2.fromOffset(S(2) + travel, S(2)) or UDim2.fromOffset(S(2), S(2)),
                        BackgroundColor3 = val and COL_KNOB_ON or COL_KNOB_OFF
                    }):Play()
                end
                render(false)

                local click = Instance.new("TextButton")
                click.Size = UDim2.new(1, 0, 1, 0)
                click.BackgroundTransparency = 1
                click.Text = ""
                click.ZIndex = 106
                click.Parent = card
                click.MouseEnter:Connect(function()
                    tween(card, { BackgroundColor3 = COL_CARD_H }, 0.12)
                end)
                click.MouseLeave:Connect(function()
                    tween(card, { BackgroundColor3 = COL_CARD }, 0.12)
                end)
                click.MouseButton1Click:Connect(function()
                    val = not val
                    render(true)
                    if to.Callback then task.spawn(function() to.Callback(val) end) end
                end)

                local Toggle = {}
                function Toggle:Set(v)
                    v = v and true or false
                    if val ~= v then val = v; render(true) end
                end
                function Toggle:Get() return val end
                return Toggle
            end

            function Tab:CreateButton(bo)
                bo = bo or {}
                tab.order = tab.order + 1
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(1, -S(6), 0, S(40))
                b.BackgroundColor3 = COL_CARD
                b.TextColor3 = COL_TEXT
                b.Text = bo.Name or "Button"
                b.Font = F_MED
                b.TextSize = S(12)
                b.BorderSizePixel = 0
                b.AutoButtonColor = false
                b.LayoutOrder = tab.order
                b.ZIndex = 103
                b.Parent = page
                corner(b, S(8))
                stroke(b, COL_BORDER, 1)
                b.MouseEnter:Connect(function()
                    tween(b, { BackgroundColor3 = COL_CARD_H }, 0.12)
                end)
                b.MouseLeave:Connect(function()
                    tween(b, { BackgroundColor3 = COL_CARD }, 0.12)
                end)
                b.MouseButton1Click:Connect(function()
                    if bo.Callback then task.spawn(function() bo.Callback() end) end
                end)
                return b
            end

            function Tab:CreateDropdown(do_)
                do_ = do_ or {}
                tab.order = tab.order + 1
                local options = do_.Options or {}
                local HEADER_H = S(46)
                local OPT_H = S(34)
                local PAD = S(4)

                -- Card (grows in-place, no floating popup)
                local card = Instance.new("Frame")
                card.Size = UDim2.new(1, -S(6), 0, HEADER_H)
                card.BackgroundColor3 = COL_CARD
                card.BorderSizePixel = 0
                card.LayoutOrder = tab.order
                card.ZIndex = 103
                card.ClipsDescendants = true
                card.Parent = page
                corner(card, S(8))
                stroke(card, COL_BORDER, 1)

                -- Header row
                local header = Instance.new("Frame")
                header.Size = UDim2.new(1, 0, 0, HEADER_H)
                header.BackgroundTransparency = 1
                header.ZIndex = 104
                header.Parent = card

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.5, -S(14), 1, 0)
                lbl.Position = UDim2.fromOffset(S(14), 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = do_.Name or "Dropdown"
                lbl.TextColor3 = COL_TEXT
                lbl.Font = F_MED
                lbl.TextSize = S(12)
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextTruncate = Enum.TextTruncate.AtEnd
                lbl.ZIndex = 105
                lbl.Parent = header

                local cur = do_.CurrentOption
                local function curText()
                    if type(cur) == "table" then return cur[1] or "—" end
                    return cur or "—"
                end

                local valLbl = Instance.new("TextLabel")
                valLbl.Size = UDim2.new(0.5, -S(48), 1, 0)
                valLbl.Position = UDim2.new(0.5, 0, 0, 0)
                valLbl.BackgroundTransparency = 1
                valLbl.Text = curText()
                valLbl.TextColor3 = COL_DIM
                valLbl.Font = F_MED
                valLbl.TextSize = S(11)
                valLbl.TextXAlignment = Enum.TextXAlignment.Right
                valLbl.TextTruncate = Enum.TextTruncate.AtEnd
                valLbl.ZIndex = 105
                valLbl.Parent = header

                -- Arrow (rotates on expand)
                local arrow = Instance.new("TextLabel")
                arrow.Size = UDim2.fromOffset(S(18), S(18))
                arrow.Position = UDim2.new(1, -S(26), 0.5, -S(9))
                arrow.BackgroundTransparency = 1
                arrow.Text = "▾"
                arrow.TextColor3 = COL_DIM
                arrow.Font = F_BOLD
                arrow.TextSize = S(11)
                arrow.Rotation = 0
                arrow.ZIndex = 105
                arrow.Parent = header

                -- Options container (expands downward, no popup)
                local optionsHolder = Instance.new("Frame")
                optionsHolder.Size = UDim2.new(1, 0, 0, 0)
                optionsHolder.Position = UDim2.fromOffset(0, HEADER_H)
                optionsHolder.BackgroundTransparency = 1
                optionsHolder.ClipsDescendants = true
                optionsHolder.ZIndex = 104
                optionsHolder.Parent = card

                local oLay = Instance.new("UIListLayout")
                oLay.Padding = UDim.new(0, S(2))
                oLay.Parent = optionsHolder
                local oPad = Instance.new("UIPadding")
                oPad.PaddingLeft = UDim.new(0, S(4))
                oPad.PaddingRight = UDim.new(0, S(4))
                oPad.PaddingBottom = UDim.new(0, S(4))
                oPad.Parent = optionsHolder

                for i, opt in ipairs(options) do
                    local ob = Instance.new("TextButton")
                    ob.Size = UDim2.new(1, 0, 0, OPT_H)
                    ob.BackgroundColor3 = COL_SIDEBAR
                    ob.TextColor3 = COL_TEXT2
                    ob.Text = "  " .. tostring(opt)
                    ob.Font = F_REG
                    ob.TextSize = S(11)
                    ob.TextXAlignment = Enum.TextXAlignment.Left
                    ob.BorderSizePixel = 0
                    ob.AutoButtonColor = false
                    ob.LayoutOrder = i
                    ob.ZIndex = 105
                    ob.Parent = optionsHolder
                    corner(ob, S(5))
                    ob.MouseEnter:Connect(function()
                        tween(ob, { BackgroundColor3 = COL_CARD_H, TextColor3 = COL_TEXT }, 0.1)
                    end)
                    ob.MouseLeave:Connect(function()
                        tween(ob, { BackgroundColor3 = COL_SIDEBAR, TextColor3 = COL_TEXT2 }, 0.1)
                    end)
                    ob.MouseButton1Click:Connect(function()
                        cur = opt
                        valLbl.Text = curText()
                        collapse()
                        if do_.Callback then
                            task.spawn(function()
                                if do_.MultipleOptions then do_.Callback({opt})
                                else do_.Callback(opt) end
                            end)
                        end
                    end)
                end

                -- Expand / collapse logic
                local expanded = false
                local optsH = #options * (OPT_H + S(2)) + S(4)

                local function collapse()
                    if not expanded then return end
                    expanded = false
                    tween(card, { Size = UDim2.new(1, -S(6), 0, HEADER_H) }, 0.2)
                    tween(optionsHolder, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
                    tween(arrow, { Rotation = 0 }, 0.2)
                end
                local function expand()
                    if expanded then return end
                    expanded = true
                    tween(card, { Size = UDim2.new(1, -S(6), 0, HEADER_H + optsH) }, 0.2)
                    tween(optionsHolder, { Size = UDim2.new(1, 0, 0, optsH) }, 0.2)
                    tween(arrow, { Rotation = 180 }, 0.2)
                end
                registerDropdown(collapse)

                -- Header click area
                local clickArea = Instance.new("TextButton")
                clickArea.Size = UDim2.new(1, 0, 0, HEADER_H)
                clickArea.BackgroundTransparency = 1
                clickArea.Text = ""
                clickArea.ZIndex = 106
                clickArea.Parent = header
                clickArea.MouseEnter:Connect(function()
                    tween(card, { BackgroundColor3 = COL_CARD_H }, 0.12)
                end)
                clickArea.MouseLeave:Connect(function()
                    tween(card, { BackgroundColor3 = COL_CARD }, 0.12)
                end)
                clickArea.MouseButton1Click:Connect(function()
                    if expanded then collapse() else expand() end
                end)

                return {}
            end

            return Tab
        end

        return Window
    end

    return Rayfield
end

local Rayfield = buildCustomUI()
if not Rayfield then
    warn("[" .. APP_NAME .. "] UI fail, stop")
    return
end
print("[" .. APP_NAME .. "] Custom UI v" .. APP_VERSION .. " loaded, HTTP=" .. httpMethod)
print(string.format("[" .. APP_NAME .. "] ME=%s | AutoPad=%s | Whitelist: 14 accounts", MY_NAME, tostring(MY_PAD)))

local function checkWebhookReason()
    if getgenv().WebhookMode == "ALL" then return true, "ALL mode" end
    if not IS_MAIN_ACCOUNT then return false, "not main (mode=MAIN)" end
    if not getgenv().WebhookToggle then return false, "toggle OFF (mode=MAIN)" end
    return true, "main + toggle ON"
end

local function sendWebhook(payload, bypassMode)
    local ok, reason
    if bypassMode then
        if not getgenv().WebhookToggle then
            ok, reason = false, "toggle OFF"
        else
            ok, reason = true, "critical (bypass mode check)"
        end
    else
        ok, reason = checkWebhookReason()
    end
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

local function readLuckyCrate()
    local lc = deepFind(PG, "Main", "GloveShop", "Tab", "Container", "Crate", "Lucky", "SpinButton", "Earned")
    if not lc then return nil end
    return lc.Text
end

local function readUBG()
    local ss = deepFind(PG, "Main", "StyleShop")
    if not ss then return nil end
    local s = deepFind(ss, "Spin", "SpinsLeft")
    local c = deepFind(ss, "Money", "Cash")
    local l = deepFind(ss, "LuckySpin", "SpinButton", "Earned")
    if not (s and c and l) then return nil end
    return {
        spins      = s.Text,
        cash       = c.Text,
        lucky      = l.Text,
        luckyCrate = readLuckyCrate(),
    }
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
    local fields = {
        { name = "Spins",       value = "**" .. (ubg.spins ~= "" and ubg.spins or "?") .. "**", inline = true },
        { name = "Cash",        value = "**" .. (ubg.cash  ~= "" and ubg.cash  or "?") .. "**", inline = true },
        { name = "Lucky Spins", value = "**" .. (ubg.lucky ~= "" and ubg.lucky or "?") .. "**", inline = true },
    }
    if ubg.luckyCrate then
        table.insert(fields, {
            name = "Lucky Crates",
            value = "**" .. (ubg.luckyCrate ~= "" and ubg.luckyCrate or "?") .. "**",
            inline = true,
        })
    end
    return sendWebhook({
        embeds = {{
            title = "UBG Stats - Currently",
            color = COLOR_CURRENT,
            fields = fields,
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

do
    local GuiService = game:GetService("GuiService")
    local DISCONNECT_SENT = false
    local SCRIPT_ARMED_AT = tick()
    local GRACE_PERIOD = 8

    local function reportDisconnect(sourceMsg)
        if DISCONNECT_SENT then return end
        if not getgenv().NotifyDisconnect then return end
        if not getgenv().WebhookToggle then return end
        DISCONNECT_SENT = true
        print("[DISCONNECT] " .. tostring(sourceMsg or ""):sub(1, 120))
        sendWebhook({
            content = string.format("**%s** got disconnect/kick, please rejoin.", MY_NAME),
        }, true)
    end

    Players.PlayerRemoving:Connect(function(p)
        if p == LP then reportDisconnect("PlayerRemoving") end
    end)
    LP.AncestryChanged:Connect(function(_, parent)
        if not parent then reportDisconnect("AncestryChanged") end
    end)
    Players.ChildRemoved:Connect(function(p)
        if p == LP then reportDisconnect("ChildRemoved") end
    end)
    GuiService.ErrorMessageChanged:Connect(function()
        local msg = GuiService.ErrorMessage
        if not msg or msg == "" then return end
        if (tick() - SCRIPT_ARMED_AT) < GRACE_PERIOD then return end
        reportDisconnect(msg)
    end)
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
    if t == "table" and v.Name then return tostring(v.Name) end
    return nil
end

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

local function readOpponentName()
    local name = readRawOpponentName()
    if not name then return nil end
    local canonical = WHITELIST_LOWER[name:lower()]
    if getgenv().TargetLock then return canonical
    else return canonical or name end
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

local function isMatchActive() return readOpponentName() ~= nil end

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
                Content  = "Rejected " .. tostring(name),
                Duration = 3,
            })
        end)
        task.wait(1.0)
        getgenv().RejectBusy = false
    end)
end

-- ===== BUILD UI =====
local Window = Rayfield:CreateWindow({ Name = APP_NAME })

local MainTab = Window:CreateTab("Main", "◉")
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
        if MY_PAD and v ~= MY_PAD then
            pcall(function()
                Rayfield:Notify({
                    Title = "⚠ PAD MISMATCH",
                    Content = "Assigned: " .. MY_PAD .. " | Chọn: " .. v,
                    Duration = 5,
                })
            end)
        end
        print(string.format("[PAD] Selected: %s | TP-to-opp: %s", v, isPad2() and "YES" or "NO"))
        pcall(function()
            Rayfield:Notify({
                Title = "PAD changed",
                Content = v .. (isPad2() and " (TP to opp)" or " (no TP)"),
                Duration = 2,
            })
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
    Name = "Target Lock (Whitelist only)",
    CurrentValue = getgenv().TargetLock,
    Callback = uiSetTargetLock,
})

-- ===== WEBHOOK TAB =====
local WebhookTab = Window:CreateTab("Webhook", "◈")

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
        getgenv().WebhookMode = string.find(v, "MAIN") and "MAIN" or "ALL"
        print("[WEBHOOK] Mode -> " .. getgenv().WebhookMode)
    end,
})

WebhookTab:CreateSection("Notifications")

WebhookTab:CreateToggle({
    Name = "Thông báo Cash",
    CurrentValue = getgenv().NotifyCash,
    Callback = function(v) getgenv().NotifyCash = v end,
})

WebhookTab:CreateToggle({
    Name = "Thông báo Spins",
    CurrentValue = getgenv().NotifySpins,
    Callback = function(v) getgenv().NotifySpins = v end,
})

WebhookTab:CreateToggle({
    Name = "Thông báo Lucky Spins",
    CurrentValue = getgenv().NotifyLucky,
    Callback = function(v) getgenv().NotifyLucky = v end,
})

WebhookTab:CreateToggle({
    Name = "Thông báo Lucky Crates",
    CurrentValue = getgenv().NotifyLuckyCrate,
    Callback = function(v) getgenv().NotifyLuckyCrate = v end,
})

WebhookTab:CreateToggle({
    Name = "Thông báo Disconnect",
    CurrentValue = getgenv().NotifyDisconnect,
    Callback = function(v) getgenv().NotifyDisconnect = v end,
})

WebhookTab:CreateSection("Tools")

WebhookTab:CreateButton({
    Name = "Test webhook now",
    Callback = function()
        task.spawn(function()
            local sent = webhookCurrently()
            Rayfield:Notify({
                Title = sent and "✓ Sent OK" or "✕ Failed",
                Content = getgenv().LastWebhookResult,
                Duration = 4,
            })
        end)
    end,
})

-- ===== SETTINGS TAB (new page "trang tú") =====
local SettingsTab = Window:CreateTab("Settings", "⬢")

SettingsTab:CreateSection("Account Info")

local infoCard = Instance.new("Frame")
-- Not needed; use button-like display via CreateButton or simple toggles

-- Info shown via notification button
SettingsTab:CreateButton({
    Name = "Xem thông tin tài khoản",
    Callback = function()
        Rayfield:Notify({
            Title = "📋 Account Info",
            Content = string.format(
                "User: %s\nPad: %s%s\nWhitelist: %s\nWebhook: %s\nHTTP: %s",
                MY_NAME,
                getgenv().SelectedPad,
                isPad2() and " (TP)" or " (no TP)",
                WHITELIST_LOWER[MY_NAME_LOWER] and "✓ yes" or "✕ no",
                getgenv().WebhookMode,
                httpMethod
            ),
            Duration = 8,
        })
    end,
})

SettingsTab:CreateSection("UI Controls")

SettingsTab:CreateButton({
    Name = "Reset vị trí UI (về giữa)",
    Callback = function()
        local wins = PG:FindFirstChild("UBG_MonoUI")
        if not wins then return end
        local w = wins:FindFirstChild("Window")
        if w then
            w.Position = UDim2.new(0.5, 0, 0.5, 0)
            Rayfield:Notify({
                Title = "✓ UI Reset",
                Content = "Đã đưa UI về giữa màn hình",
                Duration = 2,
            })
        end
    end,
})

SettingsTab:CreateButton({
    Name = "Test notification",
    Callback = function()
        Rayfield:Notify({
            Title = "🔔 Test Notification",
            Content = "Đây là một thông báo thử nghiệm.\nNó nằm ở góc dưới-phải.",
            Duration = 5,
        })
    end,
})

SettingsTab:CreateSection("Shortcuts")

SettingsTab:CreateButton({
    Name = "RightShift  →  Thu gọn / Mở UI",
    Callback = function()
        Rayfield:Notify({
            Title = "⌨ Shortcut",
            Content = "Nhấn phím RightShift để thu gọn hoặc mở lại UI bất cứ lúc nào.",
            Duration = 4,
        })
    end,
})

SettingsTab:CreateSection("About")

SettingsTab:CreateButton({
    Name = "Version: " .. APP_VERSION .. "  ·  Made by Nobred",
    Callback = function()
        Rayfield:Notify({
            Title = "ℹ About",
            Content = "Untitle Boxing Game Assistant\nVersion " .. APP_VERSION .. "\nClean monochrome UI\nAll automation features preserved.",
            Duration = 6,
        })
    end,
})

-- ===== MATCH DETECTION =====
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
                            local ok = tpToOpponentOnce()
                            if ok then
                                getgenv().TpToOppDone = true
                                return
                            end
                            task.wait(0.5)
                        end
                    end)
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
                end
            end
        end
    end
end)

-- ===== TARGET LOCK REJECT =====
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
    local ok = checkWebhookReason()
    if ok then webhookCurrently() end
end)

-- ===== UBG TRACKER =====
task.spawn(function()
    waitForUBG(6)
    if not readUBG() then return end
    local last = readUBG()
    if not last then return end

    local lastSpins      = parseNum(last.spins)
    local lastCash       = parseNum(last.cash)
    local lastLucky      = parseNum(last.lucky)
    local lastLuckyCrate = parseNum(last.luckyCrate)

    getgenv().StopWebhook = false
    while not getgenv().StopWebhook do
        task.wait(UBG_INTERVAL)
        local cur = readUBG()
        if not cur then break end
        local curSpins      = parseNum(cur.spins)
        local curCash       = parseNum(cur.cash)
        local curLucky      = parseNum(cur.lucky)
        local curLuckyCrate = parseNum(cur.luckyCrate)
        local fields = {}
        local pos, neg = 0, 0

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
        if curLuckyCrate and lastLuckyCrate and curLuckyCrate ~= lastLuckyCrate then
            if getgenv().NotifyLuckyCrate then
                local d = curLuckyCrate - lastLuckyCrate
                if d >= 0 then pos = pos + 1 else neg = neg + 1 end
                table.insert(fields, {
                    name = "Lucky Crates",
                    value = ("**%s%s** `%s -> %s`"):format(
                        d >= 0 and "+" or "", fmtNum(d),
                        fmtNum(lastLuckyCrate), fmtNum(curLuckyCrate)),
                })
            end
            lastLuckyCrate = curLuckyCrate
        else
            if curLuckyCrate then lastLuckyCrate = curLuckyCrate end
        end

        if #fields > 0 then
            if checkWebhookReason() then
                webhookStatsChanged(fields, pos, neg)
            end
        end
    end
end)

Rayfield:Notify({
    Title = APP_NAME,
    Content = string.format(
        "%s · %s%s\nLock: %s · WH: %s\nRightShift để thu gọn UI",
        MY_NAME, getgenv().SelectedPad,
        isPad2() and " (TP)" or "",
        getgenv().TargetLock and "ON" or "OFF",
        getgenv().WebhookMode
    ),
    Duration = 7,
})

print(string.format("[" .. APP_NAME .. "] %s | AutoPad=%s | TP-to-opp=%s | Lock=%s | WH=%s | HTTP=%s",
    MY_NAME, getgenv().SelectedPad,
    isPad2() and "YES" or "NO",
    getgenv().TargetLock and "ON" or "OFF",
    getgenv().WebhookMode,
    httpMethod))

-- ============================================================
-- FLOATING STOP BUTTON
-- ============================================================
do
    local UIS = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")

    local old = PG:FindFirstChild("StopEverythingBtn")
    if old then old:Destroy() end

    local COL_RED   = Color3.fromRGB(220, 38, 38)
    local COL_GREEN = Color3.fromRGB(34, 197, 94)
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local MOBILE_SCALE = UIS.TouchEnabled and not UIS.MouseEnabled and math.clamp(vp.X / 700, 1, 1.3) or 1
    local BASE_W, BASE_H = math.floor(190 * MOBILE_SCALE), math.floor(52 * MOBILE_SCALE)

    local btn = Instance.new("TextButton")
    btn.Name              = "StopEverythingBtn"
    btn.Size              = UDim2.fromOffset(BASE_W, BASE_H)
    btn.Position          = UDim2.new(0, 16, 1, -100)
    btn.BackgroundColor3  = COL_RED
    btn.TextColor3        = Color3.fromRGB(255, 255, 255)
    btn.Font              = Enum.Font.GothamBold
    btn.TextSize          = math.floor(14 * MOBILE_SCALE)
    btn.Text              = "✗   STOP EVERYTHING"
    btn.AutoButtonColor   = false
    btn.BorderSizePixel   = 0
    btn.ZIndex            = 999
    btn.Parent            = PG

    local corner_ = Instance.new("UICorner")
    corner_.CornerRadius = UDim.new(0, BASE_H / 2)
    corner_.Parent = btn

    local stroke_ = Instance.new("UIStroke")
    stroke_.Color        = Color3.fromRGB(255, 255, 255)
    stroke_.Thickness    = 2
    stroke_.Transparency = 0.35
    stroke_.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke_.Parent       = btn

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
        btn.Text = "✓   STOPPED"
        print("[STOP] Everything stopped by user")
        pcall(function()
            Rayfield:Notify({
                Title    = "STOPPED",
                Content  = "All automation disabled",
                Duration = 3,
            })
        end)
        task.delay(1.6, function()
            if not (btn and btn.Parent) then return end
            TweenService:Create(btn, TweenInfo.new(0.3), {
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