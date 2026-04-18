--[[
╔══════════════════════════════════════════════════════════════╗
║                    DIVINE UI LIBRARY                         ║
║                       Version 1.0                            ║
║                   By CrxzyXinister                           ║
╠══════════════════════════════════════════════════════════════╣
║  A complete, standalone Roblox UI library.                   ║
║                                                              ║
║  FEATURES:                                                   ║
║  • Key System (3 attempts, kick on fail)                     ║
║  • Loading Screen (progress bar + percentage)                ║
║  • Draggable window + draggable floating button              ║
║  • Icon support on the floating button                       ║
║  • Tabbed navigation with Lucide-style icons                 ║
║  • Toggle  (Switch or Box style)                             ║
║  • Slider  (FIXED drag — works on fast movement)             ║
║  • Button  (ripple effect + icon)                            ║
║  • Dropdown                                                  ║
║  • Paragraph                                                 ║
║  • Section headers                                           ║
║  • Notifications (Success / Error / Invalid)                 ║
║  • Tags (Star / Diamond / GitHub / Roblox / Verified)        ║
║  • Theme system (Crimson Red, Cyberpunk Yellow,              ║
║                  Neon Green, Royal Purple, Rainbow)          ║
║  • Background effects (Stars, Matrix, Grid, None)            ║
║  • ShowProfile (avatar strip, Anonymous mode)                ║
║  • Mobile scaling                                            ║
║                                                              ║
║  USAGE:                                                      ║
║  local DivineUI = loadstring(game:HttpGet("RAW_URL"))()      ║
║                                                              ║
║  -- 1. Key gate                                              ║
║  DivineUI.KeySystem({ Valid_Key="MyKey", ... }, function()   ║
║    -- 2. Loading screen                                      ║
║    DivineUI.LoadingScreen({ ... }, function()                ║
║      -- 3. Build window                                      ║
║      local W = DivineUI.new({ Title="My Hub", ... })         ║
║      local Tab = W:Tab({ Title="Home", Icon="home" })        ║
║      Tab:Toggle({ Title="Speed", Logic=function(s) end })    ║
║      Tab:Slider({ Title="Speed Value", Min=16, Max=300 })    ║
║      Tab:Button({ Title="Do Thing", Logic=function() end })  ║
║      Tab:Dropdown({ Title="Pick", Options={"A","B","C"} })   ║
║      Tab:Paragraph({ Content="Some info text here." })       ║
║      DivineUI.Notify({ Title="Loaded!", Type="Success" })    ║
║    end)                                                      ║
║  end)                                                        ║
╚══════════════════════════════════════════════════════════════╝
]]

-- ================================================================
-- SERVICES
-- ================================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")

local Player = Players.LocalPlayer

-- ================================================================
-- MOBILE SCALE
-- ================================================================
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local s = isMobile and 0.65 or 1

-- ================================================================
-- ICON MAP
-- Replace these asset IDs with your own uploaded Lucide icons.
-- ================================================================
local Icons = {
    ["home"]     = "rbxassetid://11963311670",
    ["shield"]   = "rbxassetid://11963311040",
    ["eye"]      = "rbxassetid://11963310579",
    ["zap"]      = "rbxassetid://11963311201",
    ["settings"] = "rbxassetid://11963310898",
    ["user"]     = "rbxassetid://11963311120",
    ["sword"]    = "rbxassetid://11963311080",
    ["wind"]     = "rbxassetid://11963311160",
    ["star"]     = "rbxassetid://11963311000",
    ["github"]   = "rbxassetid://11963310760",
    ["roblox"]   = "rbxassetid://11963310840",
    ["verified"] = "rbxassetid://11963311140",
    ["diamond"]  = "rbxassetid://11963310620",
    ["player"]   = "rbxassetid://11963310800",
    ["info"]     = "rbxassetid://11963310700",
    ["check"]    = "rbxassetid://11963310540",
    ["x"]        = "rbxassetid://11963311180",
    ["alert"]    = "rbxassetid://11963310500",
    ["key"]      = "rbxassetid://11963310720",
    ["move"]     = "rbxassetid://11963310780",
}

local function getIcon(name)
    return Icons[name] or Icons["alert"] or ""
end

-- ================================================================
-- THEMES
-- ================================================================
local Themes = {
    ["Crimson Red"]      = { P = Color3.fromRGB(220, 20,  60),  L = Color3.fromRGB(255, 60,  90),  D = Color3.fromRGB(150, 15,  40)  },
    ["Cyberpunk Yellow"] = { P = Color3.fromRGB(255, 215, 0),   L = Color3.fromRGB(255, 235, 100), D = Color3.fromRGB(180, 150, 0)   },
    ["Neon Green"]       = { P = Color3.fromRGB(50,  255, 50),  L = Color3.fromRGB(100, 255, 100), D = Color3.fromRGB(20,  180, 20)  },
    ["Royal Purple"]     = { P = Color3.fromRGB(138, 43,  226), L = Color3.fromRGB(170, 80,  255), D = Color3.fromRGB(90,  20,  150) },
}

-- Live colour table — mutated by UpdateTheme()
local C = {
    bg           = Color3.fromRGB(12,  12,  15),
    sidebar      = Color3.fromRGB(18,  18,  22),
    primary      = Themes["Crimson Red"].P,
    primaryLight = Themes["Crimson Red"].L,
    primaryDark  = Themes["Crimson Red"].D,
    text         = Color3.fromRGB(245, 245, 245),
    textMuted    = Color3.fromRGB(130, 130, 140),
    elementBg    = Color3.fromRGB(24,  24,  28),
    border       = Color3.fromRGB(40,  40,  48),
    success      = Color3.fromRGB(40,  200, 100),
    error        = Color3.fromRGB(220, 50,  50),
    warning      = Color3.fromRGB(255, 180, 0),
}

-- All UI elements that need recolouring register here
local ThemeUpdateFuncs = {}
local function _onTheme(fn)
    table.insert(ThemeUpdateFuncs, fn)
end

local function UpdateTheme(p, l, d)
    C.primary      = p
    C.primaryLight = l
    C.primaryDark  = d
    for _, fn in ipairs(ThemeUpdateFuncs) do
        pcall(fn, p, l, d)
    end
end

-- ================================================================
-- INTERNAL HELPERS
-- ================================================================

local function playSound(id, vol)
    pcall(function()
        local snd = Instance.new("Sound", game:GetService("SoundService"))
        snd.SoundId = id or "rbxassetid://6895079813"
        snd.Volume  = vol or 0.3
        snd:Play()
        game:GetService("Debris"):AddItem(snd, 1)
    end)
end

-- Ripple click effect
local function attachRipple(btn, target)
    target = target or btn
    target.ClipsDescendants = true
    btn.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        task.spawn(function()
            local ripple = Instance.new("Frame", target)
            ripple.BackgroundColor3       = Color3.new(1, 1, 1)
            ripple.AnchorPoint            = Vector2.new(0.5, 0.5)
            ripple.Size                   = UDim2.new(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.6
            ripple.ZIndex                 = (target.ZIndex or 1) + 5
            ripple.Position               = UDim2.new(
                0, input.Position.X - target.AbsolutePosition.X,
                0, input.Position.Y - target.AbsolutePosition.Y
            )
            Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)
            local maxSz = math.max(target.AbsoluteSize.X, target.AbsoluteSize.Y) * 2
            TweenService:Create(ripple,
                TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { Size = UDim2.new(0, maxSz, 0, maxSz), BackgroundTransparency = 1 }
            ):Play()
            task.wait(0.4)
            ripple:Destroy()
        end)
    end)
end

-- Draggable — works on both mouse and touch.
-- frame = the frame to move, handle = the frame that receives input (defaults to frame)
local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ================================================================
-- BACKGROUND EFFECTS
-- ================================================================
local bgLoopId = 0

local function StartBgEffect(container, effectName)
    bgLoopId = bgLoopId + 1
    local id  = bgLoopId
    container:ClearAllChildren()

    if effectName == "Stars" then
        task.spawn(function()
            while id == bgLoopId and container.Parent do
                local sz   = math.random(2, 5) * s
                local star = Instance.new("Frame", container)
                star.Size                   = UDim2.new(0, sz, 0, sz)
                star.Position               = UDim2.new(math.random(1000) / 1000, 0, 1.1, 0)
                star.BackgroundColor3       = math.random(3) == 1 and C.primaryLight or Color3.new(1, 1, 1)
                star.BorderSizePixel        = 0
                star.ZIndex                 = 1
                star.BackgroundTransparency = 0
                Instance.new("UICorner", star).CornerRadius = UDim.new(1, 0)
                local glow = Instance.new("UIStroke", star)
                glow.Color        = star.BackgroundColor3
                glow.Thickness    = sz / 1.5
                glow.Transparency = 0.6
                local dur  = math.random(6, 14)
                local endX = star.Position.X.Scale + math.random(-10, 10) / 100
                TweenService:Create(star, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(endX, 0, -0.2, 0)
                }):Play()
                task.delay(dur, function() if star then star:Destroy() end end)
                task.wait(0.15)
            end
        end)

    elseif effectName == "Matrix" then
        task.spawn(function()
            while id == bgLoopId and container.Parent do
                local sx  = math.random(1000) / 1000
                local dur = math.random(3, 7)
                local lbl = Instance.new("TextLabel", container)
                lbl.Text                   = string.char(math.random(33, 126))
                lbl.TextColor3             = C.primaryLight
                lbl.BackgroundTransparency = 1
                lbl.Size                   = UDim2.new(0, 15, 0, 15)
                lbl.Position               = UDim2.new(sx, 0, -0.1, 0)
                lbl.Font                   = Enum.Font.Code
                lbl.TextSize               = 14 * s
                lbl.ZIndex                 = 1
                TweenService:Create(lbl, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
                    Position         = UDim2.new(sx, 0, 1.1, 0),
                    TextTransparency = 1,
                }):Play()
                task.delay(dur, function() if lbl then lbl:Destroy() end end)
                task.wait(0.05)
            end
        end)

    elseif effectName == "Grid" then
        local grid = Instance.new("Frame", container)
        grid.Size                   = UDim2.new(1, 0, 1, 0)
        grid.BackgroundTransparency = 1

        for i = 1, 10 do
            local hLine = Instance.new("Frame", grid)
            hLine.Size                   = UDim2.new(1, 0, 0, 1)
            hLine.Position               = UDim2.new(0, 0, i / 10, 0)
            hLine.BackgroundColor3       = C.primary
            hLine.BackgroundTransparency = 0.8
            hLine.BorderSizePixel        = 0
            _onTheme(function(p) if hLine.Parent then hLine.BackgroundColor3 = p end end)

            local vLine = Instance.new("Frame", grid)
            vLine.Size                   = UDim2.new(0, 1, 1, 0)
            vLine.Position               = UDim2.new(i / 10, 0, 0, 0)
            vLine.BackgroundColor3       = C.primary
            vLine.BackgroundTransparency = 0.8
            vLine.BorderSizePixel        = 0
            _onTheme(function(p) if vLine.Parent then vLine.BackgroundColor3 = p end end)
        end

        task.spawn(function()
            local offset = 0
            while id == bgLoopId and container.Parent do
                offset = (offset + 0.001) % 0.1
                for i, child in ipairs(grid:GetChildren()) do
                    if child:IsA("Frame") then
                        if child.Size.Y.Offset == 1 then
                            child.Position = UDim2.new(0, 0, ((math.floor((i - 1) / 2)) / 10 + offset) % 1, 0)
                        else
                            child.Position = UDim2.new(((math.floor((i - 1) / 2)) / 10 + offset) % 1, 0, 0, 0)
                        end
                    end
                end
                task.wait(0.03)
            end
        end)
    end
    -- "None" intentionally leaves container empty
end

-- ================================================================
-- DIVINE UI MODULE
-- ================================================================
local DivineUI = {}

-- ────────────────────────────────────────────────────────────────
-- DivineUI.KeySystem(config, onSuccess)
--
-- Shows a modal key-entry screen before anything else.
-- config = {
--   Title           = "Divine Hub | Key-System",
--   Content         = "Enter your key to continue.",
--   Valid_Key       = "MySecretKey",
--   Attempts        = "3",           -- max wrong attempts (string or number)
--   KickOnThirdFail = true,          -- kick player after max attempts
-- }
-- onSuccess = function called if correct key is entered
-- ────────────────────────────────────────────────────────────────
function DivineUI.KeySystem(config, onSuccess)
    config = config or {}

    local title      = config.Title           or "Key System"
    local content    = config.Content         or "Enter your key to continue."
    local validKey   = config.Valid_Key        or ""
    local maxTries   = tonumber(config.Attempts) or 3
    local kickOnFail = config.KickOnThirdFail ~= false

    local tries = 0
    local done  = false

    local sg = Instance.new("ScreenGui")
    sg.Name             = "DivineUI_KeySystem"
    sg.ResetOnSpawn     = false
    sg.IgnoreGuiInset   = true
    sg.DisplayOrder     = 999
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = Player.PlayerGui end

    -- Dim overlay
    local overlay = Instance.new("Frame", sg)
    overlay.Size                   = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3       = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.45
    overlay.BorderSizePixel        = 0

    -- Card
    local card = Instance.new("Frame", sg)
    card.Size                   = UDim2.new(0, 430, 0, 250)
    card.Position               = UDim2.new(0.5, -215, 0.6, -125)
    card.BackgroundColor3       = C.elementBg
    card.BorderSizePixel        = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Color     = C.primary
    cardStroke.Thickness = 2

    -- Key emoji header
    local keyIcon = Instance.new("TextLabel", card)
    keyIcon.Size                   = UDim2.new(0, 44, 0, 44)
    keyIcon.Position               = UDim2.new(0.5, -22, 0, 14)
    keyIcon.BackgroundColor3       = C.primary
    keyIcon.BackgroundTransparency = 0.7
    keyIcon.Text                   = "🔑"
    keyIcon.TextSize               = 20
    keyIcon.Font                   = Enum.Font.GothamBold
    keyIcon.TextColor3             = C.text
    Instance.new("UICorner", keyIcon).CornerRadius = UDim.new(0, 8)

    local titleLbl = Instance.new("TextLabel", card)
    titleLbl.Size                   = UDim2.new(1, -40, 0, 28)
    titleLbl.Position               = UDim2.new(0, 20, 0, 64)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text                   = title
    titleLbl.TextColor3             = C.text
    titleLbl.Font                   = Enum.Font.GothamBlack
    titleLbl.TextSize               = 17
    local titleGrad = Instance.new("UIGradient", titleLbl)
    titleGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.primaryLight),
        ColorSequenceKeypoint.new(1, C.primaryDark),
    })

    local contentLbl = Instance.new("TextLabel", card)
    contentLbl.Size                   = UDim2.new(1, -40, 0, 20)
    contentLbl.Position               = UDim2.new(0, 20, 0, 94)
    contentLbl.BackgroundTransparency = 1
    contentLbl.Text                   = content
    contentLbl.TextColor3             = C.textMuted
    contentLbl.Font                   = Enum.Font.Gotham
    contentLbl.TextSize               = 12

    -- Input box
    local inputBg = Instance.new("Frame", card)
    inputBg.Size             = UDim2.new(1, -40, 0, 36)
    inputBg.Position         = UDim2.new(0, 20, 0, 124)
    inputBg.BackgroundColor3 = C.sidebar
    inputBg.BorderSizePixel  = 0
    Instance.new("UICorner", inputBg).CornerRadius = UDim.new(0, 6)
    local inputStroke = Instance.new("UIStroke", inputBg)
    inputStroke.Color     = C.border
    inputStroke.Thickness = 1.5

    local inputBox = Instance.new("TextBox", inputBg)
    inputBox.Size                   = UDim2.new(1, -20, 1, 0)
    inputBox.Position               = UDim2.new(0, 10, 0, 0)
    inputBox.BackgroundTransparency = 1
    inputBox.Text                   = ""
    inputBox.PlaceholderText        = "Enter key here..."
    inputBox.PlaceholderColor3      = C.textMuted
    inputBox.TextColor3             = C.text
    inputBox.Font                   = Enum.Font.GothamMedium
    inputBox.TextSize               = 13
    inputBox.ClearTextOnFocus       = false

    -- Attempts label
    local triesLbl = Instance.new("TextLabel", card)
    triesLbl.Size                   = UDim2.new(0.5, -20, 0, 20)
    triesLbl.Position               = UDim2.new(0, 20, 0, 170)
    triesLbl.BackgroundTransparency = 1
    triesLbl.Text                   = "Attempts: 0 / " .. maxTries
    triesLbl.TextColor3             = C.textMuted
    triesLbl.Font                   = Enum.Font.GothamMedium
    triesLbl.TextSize               = 11
    triesLbl.TextXAlignment         = Enum.TextXAlignment.Left

    -- Submit button
    local submitBtn = Instance.new("TextButton", card)
    submitBtn.Size             = UDim2.new(1, -40, 0, 36)
    submitBtn.Position         = UDim2.new(0, 20, 0, 198)
    submitBtn.BackgroundColor3 = C.primary
    submitBtn.Text             = "Submit Key"
    submitBtn.TextColor3       = Color3.new(1, 1, 1)
    submitBtn.Font             = Enum.Font.GothamBold
    submitBtn.TextSize         = 14
    submitBtn.BorderSizePixel  = 0
    Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0, 6)
    attachRipple(submitBtn)

    local function shakeCard()
        local orig = card.Position
        local offsets = {10, -10, 7, -7, 4, -4, 0}
        for _, ox in ipairs(offsets) do
            card.Position = UDim2.new(orig.X.Scale, orig.X.Offset + ox, orig.Y.Scale, orig.Y.Offset)
            task.wait(0.04)
        end
        card.Position = orig
    end

    local function tryKey()
        if done then return end
        local entered = inputBox.Text

        if entered == validKey then
            -- Correct
            done = true
            cardStroke.Color           = C.success
            submitBtn.BackgroundColor3 = C.success
            submitBtn.Text             = "✅  Key Accepted!"
            playSound("rbxassetid://6895079813", 0.5)
            task.wait(0.9)
            TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position             = UDim2.new(0.5, -215, 0.4, -125),
                BackgroundTransparency = 1,
            }):Play()
            task.wait(0.35)
            sg:Destroy()
            if onSuccess then onSuccess() end
        else
            -- Wrong
            tries = tries + 1
            triesLbl.Text       = "Attempts: " .. tries .. " / " .. maxTries
            triesLbl.TextColor3 = tries >= maxTries and C.error or C.warning

            inputStroke.Color          = C.error
            submitBtn.BackgroundColor3 = C.error
            submitBtn.Text             = "❌  Wrong! (" .. math.max(0, maxTries - tries) .. " left)"
            shakeCard()

            task.wait(1.5)
            if not done then
                inputStroke.Color          = C.border
                submitBtn.BackgroundColor3 = C.primary
                submitBtn.Text             = "Submit Key"
            end

            if tries >= maxTries and kickOnFail then
                done           = true
                submitBtn.Text = "⛔  Kicked!"
                task.wait(0.8)
                Player:Kick("You have put the key wrong for 3 times.")
            end
        end
    end

    submitBtn.MouseButton1Click:Connect(tryKey)
    inputBox.FocusLost:Connect(function(entered)
        if entered then tryKey() end
    end)

    -- Slide in animation
    TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -215, 0.5, -125)
    }):Play()
end

-- ────────────────────────────────────────────────────────────────
-- DivineUI.LoadingScreen(config, onDone)
--
-- Animated loading intro. Runs 4 steps then fades out.
-- config = {
--   Title       = "Loading Divine Hub...",
--   Content     = "Please wait...",
--   ProgressBar = true,
--   Percentage  = true,
-- }
-- onDone = function called after animation completes
-- ────────────────────────────────────────────────────────────────
function DivineUI.LoadingScreen(config, onDone)
    config = config or {}

    local title   = config.Title       or "Loading..."
    local content = config.Content     or "Please wait..."
    local useBar  = config.ProgressBar ~= false
    local usePct  = config.Percentage  ~= false

    local sg = Instance.new("ScreenGui")
    sg.Name           = "DivineUI_Loading"
    sg.ResetOnSpawn   = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder   = 998
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = Player.PlayerGui end

    local bg = Instance.new("Frame", sg)
    bg.Size             = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = C.bg
    bg.BorderSizePixel  = 0

    -- Subtle grid lines in background
    for i = 1, 8 do
        local ln = Instance.new("Frame", bg)
        ln.Size                   = UDim2.new(1, 0, 0, 1)
        ln.Position               = UDim2.new(0, 0, i / 8, 0)
        ln.BackgroundColor3       = C.border
        ln.BackgroundTransparency = 0.6
        ln.BorderSizePixel        = 0
    end

    local card = Instance.new("Frame", bg)
    card.Size             = UDim2.new(0, 400, 0, 200)
    card.Position         = UDim2.new(0.5, -200, 0.5, -100)
    card.BackgroundColor3 = C.elementBg
    card.BorderSizePixel  = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Color     = C.primary
    cardStroke.Thickness = 2

    local titleLbl = Instance.new("TextLabel", card)
    titleLbl.Size                   = UDim2.new(1, -40, 0, 36)
    titleLbl.Position               = UDim2.new(0, 20, 0, 18)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text                   = title
    titleLbl.TextColor3             = C.text
    titleLbl.Font                   = Enum.Font.GothamBlack
    titleLbl.TextSize               = 20
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
    local titleGrad = Instance.new("UIGradient", titleLbl)
    titleGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   C.primaryLight),
        ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1,   C.primaryDark),
    })

    local contentLbl = Instance.new("TextLabel", card)
    contentLbl.Size                   = UDim2.new(1, -40, 0, 22)
    contentLbl.Position               = UDim2.new(0, 20, 0, 56)
    contentLbl.BackgroundTransparency = 1
    contentLbl.Text                   = content
    contentLbl.TextColor3             = C.textMuted
    contentLbl.Font                   = Enum.Font.Gotham
    contentLbl.TextSize               = 13
    contentLbl.TextXAlignment         = Enum.TextXAlignment.Left

    local pctLbl
    if usePct then
        pctLbl = Instance.new("TextLabel", card)
        pctLbl.Size                   = UDim2.new(1, -40, 0, 20)
        pctLbl.Position               = UDim2.new(0, 20, 0, 96)
        pctLbl.BackgroundTransparency = 1
        pctLbl.Text                   = "0%"
        pctLbl.TextColor3             = C.primaryLight
        pctLbl.Font                   = Enum.Font.GothamBold
        pctLbl.TextSize               = 13
        pctLbl.TextXAlignment         = Enum.TextXAlignment.Left
    end

    local barFill
    if useBar then
        local barBg = Instance.new("Frame", card)
        barBg.Size             = UDim2.new(1, -40, 0, 8)
        barBg.Position         = UDim2.new(0, 20, 0, 124)
        barBg.BackgroundColor3 = C.sidebar
        barBg.BorderSizePixel  = 0
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

        barFill = Instance.new("Frame", barBg)
        barFill.Size             = UDim2.new(0, 0, 1, 0)
        barFill.BackgroundColor3 = C.primary
        barFill.BorderSizePixel  = 0
        Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)
    end

    local stepLbl = Instance.new("TextLabel", card)
    stepLbl.Size                   = UDim2.new(1, -40, 0, 20)
    stepLbl.Position               = UDim2.new(0, 20, 0, 148)
    stepLbl.BackgroundTransparency = 1
    stepLbl.Text                   = "Initializing..."
    stepLbl.TextColor3             = C.textMuted
    stepLbl.Font                   = Enum.Font.GothamMedium
    stepLbl.TextSize               = 11
    stepLbl.TextXAlignment         = Enum.TextXAlignment.Left

    -- Animate
    task.spawn(function()
        local steps = {
            "Loading library...",
            "Setting up UI...",
            "Applying theme...",
            "Almost done...",
        }
        for i, step in ipairs(steps) do
            stepLbl.Text = step
            local pct = i / #steps
            if barFill then
                TweenService:Create(barFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
                    Size = UDim2.new(pct, 0, 1, 0)
                }):Play()
            end
            if pctLbl then
                pctLbl.Text = math.floor(pct * 100) .. "%"
            end
            task.wait(0.55)
        end

        if pctLbl then pctLbl.Text = "100%" end
        task.wait(0.3)

        TweenService:Create(bg, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        }):Play()
        TweenService:Create(card, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, -200, 0.4, -100),
        }):Play()
        task.wait(0.5)
        sg:Destroy()
        if onDone then onDone() end
    end)
end

-- ────────────────────────────────────────────────────────────────
-- DivineUI.Notify(config)
--
-- Toast notification — slides in from right, auto-dismisses after 4s.
-- config = {
--   Title   = "Divine Hub Loaded!",
--   Content = "Script initialized successfully.",
--   Type    = "Success",  -- "Success" | "Error" | "Invalid"
-- }
-- ────────────────────────────────────────────────────────────────
local notifGui
local notifContainer
local notifCount = 0

local function ensureNotifGui()
    if notifGui and notifGui.Parent then return end
    notifGui = Instance.new("ScreenGui")
    notifGui.Name           = "DivineUI_Notifications"
    notifGui.ResetOnSpawn   = false
    notifGui.IgnoreGuiInset = true
    notifGui.DisplayOrder   = 1000
    pcall(function() notifGui.Parent = CoreGui end)
    if not notifGui.Parent then notifGui.Parent = Player.PlayerGui end

    notifContainer = Instance.new("Frame", notifGui)
    notifContainer.Size                   = UDim2.new(0, 300, 1, -20)
    notifContainer.Position               = UDim2.new(1, -310, 0, 10)
    notifContainer.BackgroundTransparency = 1

    local notifLayout = Instance.new("UIListLayout", notifContainer)
    notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    notifLayout.Padding           = UDim.new(0, 8)
    notifLayout.SortOrder         = Enum.SortOrder.LayoutOrder
end

function DivineUI.Notify(config)
    config = config or {}
    ensureNotifGui()

    local ntype   = config.Type    or "Success"
    local title   = config.Title   or "Notification"
    local content = config.Content or ""

    local iconMap  = { Success = "✅", Error = "❌", Invalid = "⛔" }
    local colorMap = { Success = C.success, Error = C.error, Invalid = C.warning }

    local accent = colorMap[ntype] or C.primary
    local icon   = iconMap[ntype]  or "🔔"

    notifCount = notifCount + 1

    local card = Instance.new("Frame", notifContainer)
    card.Size                   = UDim2.new(1, 0, 0, 68)
    card.BackgroundColor3       = C.elementBg
    card.BackgroundTransparency = 0.1
    card.BorderSizePixel        = 0
    card.LayoutOrder            = notifCount
    card.Position               = UDim2.new(1.1, 0, 0, 0)
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local accentBar = Instance.new("Frame", card)
    accentBar.Size             = UDim2.new(0, 4, 1, 0)
    accentBar.BackgroundColor3 = accent
    accentBar.BorderSizePixel  = 0
    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 4)

    local iconLbl = Instance.new("TextLabel", card)
    iconLbl.Size                   = UDim2.new(0, 30, 1, 0)
    iconLbl.Position               = UDim2.new(0, 12, 0, 0)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text                   = icon
    iconLbl.TextSize               = 18
    iconLbl.Font                   = Enum.Font.GothamBold
    iconLbl.TextColor3             = accent

    local titleLbl = Instance.new("TextLabel", card)
    titleLbl.Size                   = UDim2.new(1, -54, 0, 24)
    titleLbl.Position               = UDim2.new(0, 48, 0, 8)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text                   = title
    titleLbl.TextColor3             = C.text
    titleLbl.Font                   = Enum.Font.GothamBold
    titleLbl.TextSize               = 13
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Left

    local contentLbl = Instance.new("TextLabel", card)
    contentLbl.Size                   = UDim2.new(1, -54, 0, 26)
    contentLbl.Position               = UDim2.new(0, 48, 0, 30)
    contentLbl.BackgroundTransparency = 1
    contentLbl.Text                   = content
    contentLbl.TextColor3             = C.textMuted
    contentLbl.Font                   = Enum.Font.Gotham
    contentLbl.TextSize               = 11
    contentLbl.TextXAlignment         = Enum.TextXAlignment.Left
    contentLbl.TextWrapped            = true

    -- Slide in
    TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()

    -- Auto dismiss after 4s
    task.delay(4, function()
        TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(1.1, 0, 0, 0)
        }):Play()
        task.wait(0.35)
        card:Destroy()
    end)
end

-- ────────────────────────────────────────────────────────────────
-- DivineUI.new(config) → Window
--
-- Creates the main hub window.
-- config = {
--   Title           = "Divine Hub",
--   Author          = "CrxzyXinister",
--   Icon            = "rbxassetid://...",   -- sidebar logo + floating button
--   TheDesignThing  = "Stars",               -- background effect
--   Theme           = "Crimson Red",
--   Tags = {
--     { Title = "V1 Beta", Type = "Star" },
--   },
--   ShowProfile = {
--     Enabled   = true,
--     Anonymous = false,
--   },
-- }
-- ────────────────────────────────────────────────────────────────
function DivineUI.new(config)
    config = config or {}

    local title       = config.Title          or "Divine Hub"
    local author      = config.Author         or ""
    local iconId      = config.Icon           or ""
    local bgEffect    = config.TheDesignThing or "Stars"
    local themeName   = config.Theme          or "Crimson Red"
    local tags        = config.Tags           or {}
    local showProfile = config.ShowProfile    or { Enabled = true, Anonymous = false }

    -- Apply initial theme
    if themeName == "Rainbow" then
        RunService.RenderStepped:Connect(function()
            local hue = tick() % 5 / 5
            UpdateTheme(
                Color3.fromHSV(hue, 1,   1),
                Color3.fromHSV(hue, 0.6, 1),
                Color3.fromHSV(hue, 1,   0.5)
            )
        end)
    elseif Themes[themeName] then
        local t = Themes[themeName]
        UpdateTheme(t.P, t.L, t.D)
    end

    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name           = "DivineUI_" .. title
    sg.ResetOnSpawn   = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder   = 10
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = Player.PlayerGui end

    local winW = 660 * s
    local winH = 430 * s

    -- ────────────────────────────────────────
    -- Floating toggle button (DRAGGABLE)
    -- ────────────────────────────────────────
    local floatBtn = Instance.new("ImageButton", sg)
    floatBtn.Size                   = UDim2.new(0, 48, 0, 48)
    floatBtn.Position               = UDim2.new(1, -68, 0, 16)
    floatBtn.BackgroundColor3       = C.elementBg
    floatBtn.BackgroundTransparency = 0.1
    floatBtn.ZIndex                 = 20
    floatBtn.Image                  = iconId
    floatBtn.ImageColor3            = C.primary
    Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(0, 10)
    attachRipple(floatBtn)
    MakeDraggable(floatBtn, floatBtn)  -- the button drags itself

    -- Text fallback if no icon supplied
    if iconId == "" then
        local fallbackLbl = Instance.new("TextLabel", floatBtn)
        fallbackLbl.Size                   = UDim2.new(1, 0, 1, 0)
        fallbackLbl.BackgroundTransparency = 1
        fallbackLbl.Text                   = "D"
        fallbackLbl.Font                   = Enum.Font.GothamBlack
        fallbackLbl.TextSize               = 20
        fallbackLbl.TextColor3             = C.primary
        fallbackLbl.ZIndex                 = 21
        _onTheme(function(p) if fallbackLbl.Parent then fallbackLbl.TextColor3 = p end end)
    end
    _onTheme(function(p) if floatBtn.Parent then floatBtn.ImageColor3 = p end end)

    -- Animated gradient border on the float button
    local floatStroke = Instance.new("UIStroke", floatBtn)
    floatStroke.Thickness = 2
    local floatGrad = Instance.new("UIGradient", floatStroke)
    floatGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   C.primaryLight),
        ColorSequenceKeypoint.new(0.5, C.border),
        ColorSequenceKeypoint.new(1,   C.primaryDark),
    })
    _onTheme(function(p, l, d)
        if floatGrad.Parent then
            floatGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   l),
                ColorSequenceKeypoint.new(0.5, C.border),
                ColorSequenceKeypoint.new(1,   d),
            })
        end
    end)
    task.spawn(function()
        local r = 0
        while sg.Parent do
            r = (r + 1.5) % 360
            floatGrad.Rotation = r
            task.wait(0.02)
        end
    end)

    -- ────────────────────────────────────────
    -- Main window frame (DRAGGABLE)
    -- ────────────────────────────────────────
    local main = Instance.new("Frame", sg)
    main.Size                   = UDim2.new(0, winW, 0, winH)
    main.Position               = UDim2.new(0.5, -winW / 2, 0.5, -winH / 2)
    main.BackgroundColor3       = C.bg
    main.BackgroundTransparency = 0.05
    main.BorderSizePixel        = 0
    main.Active                 = true
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10 * s)
    MakeDraggable(main)

    local mainStroke = Instance.new("UIStroke", main)
    mainStroke.Thickness = 2
    local mainGrad = Instance.new("UIGradient", mainStroke)
    mainGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   C.primaryLight),
        ColorSequenceKeypoint.new(0.5, C.border),
        ColorSequenceKeypoint.new(1,   C.primaryDark),
    })
    _onTheme(function(p, l, d)
        if mainGrad.Parent then
            mainGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   l),
                ColorSequenceKeypoint.new(0.5, C.border),
                ColorSequenceKeypoint.new(1,   d),
            })
        end
    end)
    task.spawn(function()
        local r = 0
        while sg.Parent do
            r = (r + 1.5) % 360
            mainGrad.Rotation = r
            task.wait(0.02)
        end
    end)

    -- Background container
    local bgContainer = Instance.new("Frame", main)
    bgContainer.Name               = "BgContainer"
    bgContainer.Size               = UDim2.new(1, 0, 1, 0)
    bgContainer.BackgroundTransparency = 1
    bgContainer.ZIndex             = 1
    bgContainer.ClipsDescendants   = true
    StartBgEffect(bgContainer, bgEffect)

    -- ────────────────────────────────────────
    -- Sidebar
    -- ────────────────────────────────────────
    local sidebarW = 165 * s

    local sidebar = Instance.new("Frame", main)
    sidebar.Size             = UDim2.new(0, sidebarW, 1, 0)
    sidebar.BackgroundColor3 = C.sidebar
    sidebar.BorderSizePixel  = 0
    sidebar.ZIndex           = 2
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10 * s)

    local sidebarBorder = Instance.new("Frame", main)
    sidebarBorder.Size             = UDim2.new(0, 1, 1, 0)
    sidebarBorder.Position         = UDim2.new(0, sidebarW, 0, 0)
    sidebarBorder.BackgroundColor3 = C.border
    sidebarBorder.BorderSizePixel  = 0
    sidebarBorder.ZIndex           = 2

    -- Logo row
    local logoFrame = Instance.new("Frame", sidebar)
    logoFrame.Size             = UDim2.new(1, 0, 0, 56 * s)
    logoFrame.BackgroundTransparency = 1
    logoFrame.ZIndex           = 2

    if iconId ~= "" then
        local logoImg = Instance.new("ImageLabel", logoFrame)
        logoImg.Size                   = UDim2.new(0, 26 * s, 0, 26 * s)
        logoImg.Position               = UDim2.new(0, 10 * s, 0.5, -13 * s)
        logoImg.BackgroundTransparency = 1
        logoImg.Image                  = iconId
        logoImg.ImageColor3            = C.primaryLight
        logoImg.ZIndex                 = 2
        _onTheme(function(p, l) if logoImg.Parent then logoImg.ImageColor3 = l end end)
    end

    local logoOffset = iconId ~= "" and (42 * s) or (12 * s)
    local logoTitle  = Instance.new("TextLabel", logoFrame)
    logoTitle.Size             = UDim2.new(1, -logoOffset - 6 * s, 0, 24 * s)
    logoTitle.Position         = UDim2.new(0, logoOffset, 0.5, -12 * s)
    logoTitle.BackgroundTransparency = 1
    logoTitle.Text             = title
    logoTitle.Font             = Enum.Font.GothamBlack
    logoTitle.TextSize         = 16 * s
    logoTitle.TextColor3       = Color3.new(1, 1, 1)
    logoTitle.TextXAlignment   = Enum.TextXAlignment.Left
    logoTitle.ZIndex           = 2
    local logoGrad = Instance.new("UIGradient", logoTitle)
    logoGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   C.primaryLight),
        ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1,   C.primaryDark),
    })
    _onTheme(function(p, l, d)
        if logoGrad.Parent then
            logoGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   l),
                ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1,   d),
            })
        end
    end)
    task.spawn(function()
        local r = 0
        while sg.Parent do
            r = (r + 1.5) % 360
            if logoGrad.Parent then logoGrad.Rotation = r end
            task.wait(0.02)
        end
    end)

    -- Tags row
    local tagOffset = 56 * s
    if #tags > 0 then
        local tagsRow = Instance.new("Frame", sidebar)
        tagsRow.Size             = UDim2.new(1, -14 * s, 0, 20 * s)
        tagsRow.Position         = UDim2.new(0, 7 * s, 0, tagOffset)
        tagsRow.BackgroundTransparency = 1
        tagsRow.ZIndex           = 2
        local tagsLayout = Instance.new("UIListLayout", tagsRow)
        tagsLayout.FillDirection = Enum.FillDirection.Horizontal
        tagsLayout.Padding       = UDim.new(0, 4 * s)

        local tagIcons = {
            Star = "⭐", Diamond = "💎",
            GitHub = "◈", Roblox = "🔵", Verified = "✔",
        }
        for _, tag in ipairs(tags) do
            local badge = Instance.new("TextLabel", tagsRow)
            badge.BackgroundColor3       = C.elementBg
            badge.BackgroundTransparency = 0.3
            badge.Text                   = (tagIcons[tag.Type] or "") .. " " .. (tag.Title or "")
            badge.TextColor3             = C.primaryLight
            badge.Font                   = Enum.Font.GothamBold
            badge.TextSize               = 9 * s
            badge.ZIndex                 = 2
            badge.AutomaticSize          = Enum.AutomaticSize.X
            badge.Size                   = UDim2.new(0, 0, 1, 0)
            Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4 * s)
            local pad = Instance.new("UIPadding", badge)
            pad.PaddingLeft  = UDim.new(0, 4 * s)
            pad.PaddingRight = UDim.new(0, 4 * s)
            _onTheme(function(p, l) if badge.Parent then badge.TextColor3 = l end end)
        end
        tagOffset = tagOffset + 24 * s
    end

    -- Separator below logo / tags
    local topSep = Instance.new("Frame", sidebar)
    topSep.Size             = UDim2.new(0.85, 0, 0, 1)
    topSep.Position         = UDim2.new(0.075, 0, 0, tagOffset)
    topSep.BackgroundColor3 = C.border
    topSep.BackgroundTransparency = 0.3
    topSep.BorderSizePixel  = 0
    topSep.ZIndex           = 2

    local tabAreaTop = tagOffset + 8 * s

    -- Tab list container (with auto UIListLayout)
    local tabList = Instance.new("Frame", sidebar)
    tabList.Size                   = UDim2.new(1, 0, 1, -(tabAreaTop + 62 * s))
    tabList.Position               = UDim2.new(0, 0, 0, tabAreaTop)
    tabList.BackgroundTransparency = 1
    tabList.ZIndex                 = 2
    local tabListLayout = Instance.new("UIListLayout", tabList)
    tabListLayout.Padding   = UDim.new(0, 4 * s)
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local tabListPad = Instance.new("UIPadding", tabList)
    tabListPad.PaddingTop  = UDim.new(0, 4 * s)
    tabListPad.PaddingLeft = UDim.new(0, 6 * s)
    tabListPad.PaddingRight = UDim.new(0, 6 * s)

    -- Profile strip (bottom of sidebar)
    if showProfile and showProfile.Enabled then
        local botSep = Instance.new("Frame", sidebar)
        botSep.Size             = UDim2.new(0.85, 0, 0, 1)
        botSep.Position         = UDim2.new(0.075, 0, 1, -60 * s)
        botSep.BackgroundColor3 = C.border
        botSep.BackgroundTransparency = 0.3
        botSep.BorderSizePixel  = 0
        botSep.ZIndex           = 2

        local profileStrip = Instance.new("Frame", sidebar)
        profileStrip.Size             = UDim2.new(1, 0, 0, 56 * s)
        profileStrip.Position         = UDim2.new(0, 0, 1, -56 * s)
        profileStrip.BackgroundTransparency = 1
        profileStrip.ZIndex           = 2

        local avatar = Instance.new("ImageLabel", profileStrip)
        avatar.Size             = UDim2.new(0, 30 * s, 0, 30 * s)
        avatar.Position         = UDim2.new(0, 10 * s, 0.5, -15 * s)
        avatar.BackgroundColor3 = C.elementBg
        avatar.ZIndex           = 2
        avatar.Image            = showProfile.Anonymous
            and "rbxassetid://7072706960"
            or ("rbxthumb://type=AvatarHeadShot&id=" .. Player.UserId .. "&w=150&h=150")
        Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
        local avStroke = Instance.new("UIStroke", avatar)
        avStroke.Color     = C.primary
        avStroke.Thickness = 1.5
        _onTheme(function(p) if avStroke.Parent then avStroke.Color = p end end)

        local nameLbl = Instance.new("TextLabel", profileStrip)
        nameLbl.Size             = UDim2.new(1, -50 * s, 0, 14 * s)
        nameLbl.Position         = UDim2.new(0, 46 * s, 0.5, -14 * s)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text             = showProfile.Anonymous and "Anonymous" or Player.Name
        nameLbl.TextColor3       = C.text
        nameLbl.Font             = Enum.Font.GothamBold
        nameLbl.TextSize         = 11 * s
        nameLbl.TextXAlignment   = Enum.TextXAlignment.Left
        nameLbl.TextTruncate     = Enum.TextTruncate.AtEnd
        nameLbl.ZIndex           = 2

        local roleLbl = Instance.new("TextLabel", profileStrip)
        roleLbl.Size             = UDim2.new(1, -50 * s, 0, 12 * s)
        roleLbl.Position         = UDim2.new(0, 46 * s, 0.5, 2 * s)
        roleLbl.BackgroundTransparency = 1
        roleLbl.Text             = author ~= "" and ("by " .. author) or "User"
        roleLbl.TextColor3       = C.textMuted
        roleLbl.Font             = Enum.Font.GothamMedium
        roleLbl.TextSize         = 10 * s
        roleLbl.TextXAlignment   = Enum.TextXAlignment.Left
        roleLbl.ZIndex           = 2
    end

    -- Content area (right side of window)
    local contentArea = Instance.new("Frame", main)
    contentArea.Size              = UDim2.new(1, -sidebarW, 1, 0)
    contentArea.Position          = UDim2.new(0, sidebarW, 0, 0)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants  = true
    contentArea.ZIndex            = 2

    -- Visibility toggle
    local guiVisible = true
    floatBtn.MouseButton1Click:Connect(function()
        guiVisible   = not guiVisible
        main.Visible = guiVisible
    end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == Enum.KeyCode.U then
            guiVisible   = not guiVisible
            main.Visible = guiVisible
        end
    end)

    -- Tab state
    local pages     = {}
    local tabBtns   = {}
    local activeTab = nil
    local tabOrder  = 0

    local function switchTab(name)
        if activeTab == name then return end
        activeTab = name

        for n, page in pairs(pages) do
            if n == name then
                page.Visible  = true
                page.Position = UDim2.new(0, 28 * s, 0, 8 * s)
                TweenService:Create(page, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, 8 * s, 0, 8 * s)
                }):Play()
            else
                page.Visible = false
            end
        end

        for n, t in pairs(tabBtns) do
            local isActive = n == name
            TweenService:Create(t.bg, TweenInfo.new(0.2), {
                BackgroundColor3       = isActive and C.elementBg or C.sidebar,
                BackgroundTransparency = isActive and 0.3 or 1,
            }):Play()
            TweenService:Create(t.label, TweenInfo.new(0.2), {
                TextColor3 = isActive and C.text or C.textMuted
            }):Play()
            if t.stroke then
                TweenService:Create(t.stroke, TweenInfo.new(0.2), {
                    Transparency = isActive and 0 or 1
                }):Play()
            end
            t.indicator.Visible = isActive
        end

        playSound("rbxassetid://6895079813", 0.18)
    end

    -- ============================================================
    -- WINDOW OBJECT
    -- ============================================================
    local Window = {}

    -- ────────────────────────────────────────────────────────────
    -- Window:Tab(config) → Tab
    --
    -- config = { Title = "Home", Icon = "home" }
    -- ────────────────────────────────────────────────────────────
    function Window:Tab(tabConfig)
        tabConfig  = tabConfig or {}
        local name = tabConfig.Title or ("Tab " .. tabOrder + 1)
        local icon = tabConfig.Icon  or ""
        tabOrder   = tabOrder + 1

        -- Sidebar button frame
        local btnFrame = Instance.new("Frame", tabList)
        btnFrame.Size                   = UDim2.new(1, 0, 0, 36 * s)
        btnFrame.BackgroundTransparency = 1
        btnFrame.LayoutOrder            = tabOrder
        btnFrame.ZIndex                 = 2

        local btnBg = Instance.new("Frame", btnFrame)
        btnBg.Size                   = UDim2.new(1, 0, 1, 0)
        btnBg.BackgroundColor3       = C.sidebar
        btnBg.BackgroundTransparency = 1
        btnBg.ZIndex                 = 2
        Instance.new("UICorner", btnBg).CornerRadius = UDim.new(0, 6 * s)

        local btnStroke = Instance.new("UIStroke", btnBg)
        btnStroke.Color        = C.primaryLight
        btnStroke.Thickness    = 1.5
        btnStroke.Transparency = 1
        _onTheme(function(p, l) if btnStroke.Parent then btnStroke.Color = l end end)

        local indicator = Instance.new("Frame", btnBg)
        indicator.Size             = UDim2.new(0, 3 * s, 0, 16 * s)
        indicator.Position         = UDim2.new(0, 0, 0.5, -8 * s)
        indicator.BackgroundColor3 = C.primary
        indicator.BorderSizePixel  = 0
        indicator.Visible          = false
        Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 3 * s)
        _onTheme(function(p) if indicator.Parent then indicator.BackgroundColor3 = p end end)

        -- Icon
        local lblLeft = 10 * s
        if icon ~= "" and icon ~= "nil" then
            local iconImg = Instance.new("ImageLabel", btnBg)
            iconImg.Size                   = UDim2.new(0, 15 * s, 0, 15 * s)
            iconImg.Position               = UDim2.new(0, 10 * s, 0.5, -7.5 * s)
            iconImg.BackgroundTransparency = 1
            iconImg.Image                  = getIcon(icon)
            iconImg.ImageColor3            = C.textMuted
            iconImg.ZIndex                 = 3
            lblLeft = 30 * s
        end

        local btnLabel = Instance.new("TextLabel", btnBg)
        btnLabel.Size             = UDim2.new(1, -(lblLeft + 6 * s), 1, 0)
        btnLabel.Position         = UDim2.new(0, lblLeft + 6 * s, 0, 0)
        btnLabel.BackgroundTransparency = 1
        btnLabel.Text             = name
        btnLabel.TextColor3       = C.textMuted
        btnLabel.Font             = Enum.Font.GothamSemibold
        btnLabel.TextSize         = 13 * s
        btnLabel.TextXAlignment   = Enum.TextXAlignment.Left
        btnLabel.ZIndex           = 3

        -- Click zone
        local clickZone = Instance.new("TextButton", btnFrame)
        clickZone.Size                   = UDim2.new(1, 0, 1, 0)
        clickZone.BackgroundTransparency = 1
        clickZone.Text                   = ""
        clickZone.ZIndex                 = 4
        attachRipple(clickZone, btnBg)
        clickZone.MouseButton1Click:Connect(function() switchTab(name) end)

        tabBtns[name] = { bg = btnBg, label = btnLabel, indicator = indicator, stroke = btnStroke }

        -- Scrolling page
        local page = Instance.new("ScrollingFrame", contentArea)
        page.Size                  = UDim2.new(1, -16 * s, 1, -16 * s)
        page.Position              = UDim2.new(0, 8 * s, 0, 8 * s)
        page.BackgroundTransparency = 1
        page.ScrollBarThickness    = 3 * s
        page.ScrollBarImageColor3  = C.border
        page.Visible               = false
        page.ZIndex                = 2
        local pageLayout = Instance.new("UIListLayout", page)
        pageLayout.Padding   = UDim.new(0, 7 * s)
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        local pagePad = Instance.new("UIPadding", page)
        pagePad.PaddingTop    = UDim.new(0, 4 * s)
        pagePad.PaddingBottom = UDim.new(0, 8 * s)
        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 16 * s)
        end)

        pages[name] = page
        if activeTab == nil then switchTab(name) end

        -- ============================================================
        -- TAB OBJECT
        -- ============================================================
        local Tab = {}

        -- ── Tab:Section(text) ──
        function Tab:Section(text)
            local lbl = Instance.new("TextLabel", page)
            lbl.Size                   = UDim2.new(1, -8 * s, 0, 24 * s)
            lbl.BackgroundColor3       = C.elementBg
            lbl.BackgroundTransparency = 0.2
            lbl.Text                   = (text or ""):upper()
            lbl.TextColor3             = C.primaryLight
            lbl.Font                   = Enum.Font.GothamBold
            lbl.TextSize               = 10 * s
            lbl.TextXAlignment         = Enum.TextXAlignment.Left
            lbl.ZIndex                 = 2
            Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 4 * s)
            local pad = Instance.new("UIPadding", lbl)
            pad.PaddingLeft = UDim.new(0, 10 * s)
            _onTheme(function(p, l) if lbl.Parent then lbl.TextColor3 = l end end)
        end

        -- ── Tab:Toggle(config) ──
        -- config = {
        --   Title   = "Speed Boost",
        --   Icon    = "zap",
        --   Type    = "Switch",  -- "Switch" or "Box"
        --   Default = false,
        --   Logic   = function(state: boolean) end,
        -- }
        -- Returns: setVisual(state, skipCallback?)
        function Tab:Toggle(tConfig)
            tConfig = tConfig or {}
            local label   = tConfig.Title   or "Toggle"
            local tIcon   = tConfig.Icon    or ""
            local tType   = tConfig.Type    or "Switch"
            local default = tConfig.Default or false
            local logic   = tConfig.Logic   or function() end

            local row = Instance.new("Frame", page)
            row.Size                   = UDim2.new(1, -8 * s, 0, 48 * s)
            row.BackgroundColor3       = C.elementBg
            row.BackgroundTransparency = 0.55
            row.ZIndex                 = 2
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6 * s)
            Instance.new("UIStroke", row).Color        = C.border

            local lblLeft = 12 * s
            if tIcon ~= "" and tIcon ~= "nil" then
                local ic = Instance.new("ImageLabel", row)
                ic.Size                   = UDim2.new(0, 15 * s, 0, 15 * s)
                ic.Position               = UDim2.new(0, 12 * s, 0.5, -7.5 * s)
                ic.BackgroundTransparency = 1
                ic.Image                  = getIcon(tIcon)
                ic.ImageColor3            = C.textMuted
                ic.ZIndex                 = 3
                lblLeft = 32 * s
            end

            local lbl = Instance.new("TextLabel", row)
            lbl.Size             = UDim2.new(0.55, 0, 1, 0)
            lbl.Position         = UDim2.new(0, lblLeft, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text             = label
            lbl.TextColor3       = C.text
            lbl.Font             = Enum.Font.GothamSemibold
            lbl.TextSize         = 13 * s
            lbl.TextXAlignment   = Enum.TextXAlignment.Left
            lbl.ZIndex           = 3

            local isOn = default
            local setVisual

            if tType == "Box" then
                local box = Instance.new("Frame", row)
                box.Size             = UDim2.new(0, 20 * s, 0, 20 * s)
                box.Position         = UDim2.new(1, -32 * s, 0.5, -10 * s)
                box.BackgroundColor3 = isOn and C.primary or C.sidebar
                box.ZIndex           = 3
                Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4 * s)
                Instance.new("UIStroke", box).Color        = C.border

                local tick = Instance.new("TextLabel", box)
                tick.Size                   = UDim2.new(1, 0, 1, 0)
                tick.BackgroundTransparency = 1
                tick.Text                   = isOn and "✓" or ""
                tick.TextColor3             = Color3.new(1, 1, 1)
                tick.Font                   = Enum.Font.GothamBold
                tick.TextSize               = 13 * s
                tick.ZIndex                 = 4

                _onTheme(function(p) if box.Parent and isOn then box.BackgroundColor3 = p end end)

                setVisual = function(state, skipCb)
                    isOn = state
                    box.BackgroundColor3 = isOn and C.primary or C.sidebar
                    tick.Text = isOn and "✓" or ""
                    if not skipCb then logic(isOn) end
                end
            else
                -- Switch style
                local switchBg = Instance.new("Frame", row)
                switchBg.Size             = UDim2.new(0, 42 * s, 0, 22 * s)
                switchBg.Position         = UDim2.new(1, -54 * s, 0.5, -11 * s)
                switchBg.BackgroundColor3 = isOn and C.primary or C.sidebar
                switchBg.ZIndex           = 3
                Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)

                local knob = Instance.new("Frame", switchBg)
                knob.Size             = UDim2.new(0, 16 * s, 0, 16 * s)
                knob.Position         = isOn
                    and UDim2.new(1, -19 * s, 0.5, -8 * s)
                    or  UDim2.new(0, 3 * s,   0.5, -8 * s)
                knob.BackgroundColor3 = Color3.new(1, 1, 1)
                knob.ZIndex           = 4
                Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

                _onTheme(function(p)
                    if switchBg.Parent and isOn then switchBg.BackgroundColor3 = p end
                end)

                setVisual = function(state, skipCb)
                    isOn = state
                    TweenService:Create(switchBg, TweenInfo.new(0.18), {
                        BackgroundColor3 = isOn and C.primary or C.sidebar
                    }):Play()
                    TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
                        Position = isOn
                            and UDim2.new(1, -19 * s, 0.5, -8 * s)
                            or  UDim2.new(0,  3 * s,  0.5, -8 * s)
                    }):Play()
                    if not skipCb then logic(isOn) end
                end
            end

            -- Transparent click layer over the whole row
            local click = Instance.new("TextButton", row)
            click.Size                   = UDim2.new(1, 0, 1, 0)
            click.BackgroundTransparency = 1
            click.Text                   = ""
            click.ZIndex                 = 5
            attachRipple(click, row)
            click.MouseButton1Click:Connect(function()
                isOn = not isOn
                setVisual(isOn)
                playSound("rbxassetid://6895079813", 0.3)
            end)

            return setVisual
        end

        -- ── Tab:Slider(config) ──
        -- config = {
        --   Title   = "Walk Speed",
        --   Min     = 16,       -- number or string
        --   Max     = 300,
        --   Default = 16,
        --   Float   = false,    -- true = 2 dp, false = integer
        --   Logic   = function(value: number) end,
        -- }
        -- Returns: setVal(number)
        function Tab:Slider(sConfig)
            sConfig = sConfig or {}
            local label   = sConfig.Title   or "Slider"
            local minVal  = tonumber(sConfig.Min)     or 0
            local maxVal  = tonumber(sConfig.Max)     or 100
            local default = tonumber(sConfig.Default) or minVal
            local isFloat = sConfig.Float   or false
            local logic   = sConfig.Logic   or function() end

            default = math.clamp(default, minVal, maxVal)

            local row = Instance.new("Frame", page)
            row.Size                   = UDim2.new(1, -8 * s, 0, 62 * s)
            row.BackgroundColor3       = C.elementBg
            row.BackgroundTransparency = 0.55
            row.ZIndex                 = 2
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6 * s)
            Instance.new("UIStroke", row).Color        = C.border

            local lbl = Instance.new("TextLabel", row)
            lbl.Size             = UDim2.new(0.6, 0, 0, 20 * s)
            lbl.Position         = UDim2.new(0, 12 * s, 0, 10 * s)
            lbl.BackgroundTransparency = 1
            lbl.Text             = label
            lbl.TextColor3       = C.text
            lbl.Font             = Enum.Font.GothamSemibold
            lbl.TextSize         = 13 * s
            lbl.TextXAlignment   = Enum.TextXAlignment.Left
            lbl.ZIndex           = 3

            local currentVal = default

            -- Editable value box
            local valBox = Instance.new("TextBox", row)
            valBox.Size             = UDim2.new(0, 48 * s, 0, 22 * s)
            valBox.Position         = UDim2.new(1, -60 * s, 0, 8 * s)
            valBox.BackgroundColor3 = C.sidebar
            valBox.Text             = tostring(currentVal)
            valBox.TextColor3       = C.primary
            valBox.Font             = Enum.Font.GothamBold
            valBox.TextSize         = 12 * s
            valBox.ClearTextOnFocus = false
            valBox.ZIndex           = 4
            Instance.new("UICorner", valBox).CornerRadius = UDim.new(0, 4 * s)
            Instance.new("UIStroke", valBox).Color        = C.border
            _onTheme(function(p) if valBox.Parent then valBox.TextColor3 = p end end)

            -- Track
            local track = Instance.new("Frame", row)
            track.Size             = UDim2.new(1, -24 * s, 0, 6 * s)
            track.Position         = UDim2.new(0, 12 * s, 0, 43 * s)
            track.BackgroundColor3 = C.sidebar
            track.ZIndex           = 3
            Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

            local initPct = (default - minVal) / math.max(maxVal - minVal, 0.0001)

            local fill = Instance.new("Frame", track)
            fill.Size             = UDim2.new(initPct, 0, 1, 0)
            fill.BackgroundColor3 = C.primary
            fill.ZIndex           = 4
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
            _onTheme(function(p) if fill.Parent then fill.BackgroundColor3 = p end end)

            local thumb = Instance.new("Frame", track)
            thumb.Size             = UDim2.new(0, 14 * s, 0, 14 * s)
            thumb.Position         = UDim2.new(initPct, -7 * s, 0.5, -7 * s)
            thumb.BackgroundColor3 = Color3.new(1, 1, 1)
            thumb.ZIndex           = 5
            Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

            local function applyRel(rel)
                rel = math.clamp(rel, 0, 1)
                fill.Size      = UDim2.new(rel, 0, 1, 0)
                thumb.Position = UDim2.new(rel, -7 * s, 0.5, -7 * s)
                local v = minVal + (maxVal - minVal) * rel
                v = isFloat and (math.floor(v * 100) / 100) or math.floor(v)
                currentVal  = v
                valBox.Text = tostring(v)
                logic(v)
            end

            -- ── FIXED DRAG: global InputChanged while dragging = true ──
            local dragging = false

            local function startDrag(inputPos)
                dragging = true
                local rel = (inputPos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
                applyRel(rel)
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    startDrag(input.Position)
                end
            end)
            thumb.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if not dragging then return end
                if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                    local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
                    applyRel(rel)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            -- Manual text input
            valBox.FocusLost:Connect(function()
                local n = tonumber(valBox.Text)
                if n then
                    n = math.clamp(n, minVal, maxVal)
                    n = isFloat and (math.floor(n * 100) / 100) or math.floor(n)
                    currentVal  = n
                    valBox.Text = tostring(n)
                    local rel = (n - minVal) / math.max(maxVal - minVal, 0.0001)
                    fill.Size      = UDim2.new(rel, 0, 1, 0)
                    thumb.Position = UDim2.new(rel, -7 * s, 0.5, -7 * s)
                    logic(n)
                else
                    valBox.Text = tostring(currentVal)
                end
            end)

            local function setVal(v)
                v = math.clamp(v, minVal, maxVal)
                local rel = (v - minVal) / math.max(maxVal - minVal, 0.0001)
                fill.Size      = UDim2.new(rel, 0, 1, 0)
                thumb.Position = UDim2.new(rel, -7 * s, 0.5, -7 * s)
                currentVal     = v
                valBox.Text    = tostring(v)
            end

            return setVal
        end

        -- ── Tab:Button(config) ──
        -- config = {
        --   Title = "Server Hop",
        --   Icon  = "shield",
        --   Logic = function(btn: TextButton) end,
        -- }
        -- Returns: TextButton instance
        function Tab:Button(bConfig)
            bConfig = bConfig or {}
            local label = bConfig.Title or "Button"
            local bIcon = bConfig.Icon  or ""
            local logic = bConfig.Logic or function() end

            local btn = Instance.new("TextButton", page)
            btn.Size                   = UDim2.new(1, -8 * s, 0, 42 * s)
            btn.BackgroundColor3       = C.elementBg
            btn.BackgroundTransparency = 0.5
            btn.Text                   = label
            btn.TextColor3             = C.text
            btn.Font                   = Enum.Font.GothamBold
            btn.TextSize               = 13 * s
            btn.ZIndex                 = 2
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6 * s)
            Instance.new("UIStroke", btn).Color        = C.border
            attachRipple(btn)

            if bIcon ~= "" and bIcon ~= "nil" then
                local ic = Instance.new("ImageLabel", btn)
                ic.Size                   = UDim2.new(0, 15 * s, 0, 15 * s)
                ic.Position               = UDim2.new(0, 12 * s, 0.5, -7.5 * s)
                ic.BackgroundTransparency = 1
                ic.Image                  = getIcon(bIcon)
                ic.ImageColor3            = C.primaryLight
                ic.ZIndex                 = 3
                _onTheme(function(p, l) if ic.Parent then ic.ImageColor3 = l end end)
                -- indent text
                btn.TextXAlignment = Enum.TextXAlignment.Center
            end

            btn.MouseButton1Click:Connect(function()
                playSound("rbxassetid://6895079813", 0.3)
                logic(btn)
            end)
            return btn
        end

        -- ── Tab:Dropdown(config) ──
        -- config = {
        --   Title   = "ESP Color",
        --   Icon    = "eye",
        --   Options = { "Red", "Green", "Blue" },
        --   Logic   = function(selected: string) end,
        -- }
        function Tab:Dropdown(dConfig)
            dConfig = dConfig or {}
            local label   = dConfig.Title   or "Dropdown"
            local dIcon   = dConfig.Icon    or ""
            local options = dConfig.Options or {}
            local logic   = dConfig.Logic   or function() end

            local selected = options[1] or "Select..."
            local open     = false

            local container = Instance.new("Frame", page)
            container.Size                   = UDim2.new(1, -8 * s, 0, 42 * s)
            container.BackgroundTransparency = 1
            container.ZIndex                 = 6
            container.ClipsDescendants       = false

            local header = Instance.new("Frame", container)
            header.Size                   = UDim2.new(1, 0, 0, 42 * s)
            header.BackgroundColor3       = C.elementBg
            header.BackgroundTransparency = 0.5
            header.BorderSizePixel        = 0
            header.ZIndex                 = 6
            Instance.new("UICorner", header).CornerRadius = UDim.new(0, 6 * s)
            Instance.new("UIStroke", header).Color        = C.border

            local lblLeft = 12 * s
            if dIcon ~= "" and dIcon ~= "nil" then
                local ic = Instance.new("ImageLabel", header)
                ic.Size                   = UDim2.new(0, 15 * s, 0, 15 * s)
                ic.Position               = UDim2.new(0, 12 * s, 0.5, -7.5 * s)
                ic.BackgroundTransparency = 1
                ic.Image                  = getIcon(dIcon)
                ic.ImageColor3            = C.textMuted
                ic.ZIndex                 = 7
                lblLeft = 32 * s
            end

            local titleLbl = Instance.new("TextLabel", header)
            titleLbl.Size             = UDim2.new(0.5, 0, 1, 0)
            titleLbl.Position         = UDim2.new(0, lblLeft, 0, 0)
            titleLbl.BackgroundTransparency = 1
            titleLbl.Text             = label
            titleLbl.TextColor3       = C.text
            titleLbl.Font             = Enum.Font.GothamSemibold
            titleLbl.TextSize         = 13 * s
            titleLbl.TextXAlignment   = Enum.TextXAlignment.Left
            titleLbl.ZIndex           = 7

            local selLbl = Instance.new("TextLabel", header)
            selLbl.Size             = UDim2.new(0.45, 0, 1, 0)
            selLbl.Position         = UDim2.new(0.52, 0, 0, 0)
            selLbl.BackgroundTransparency = 1
            selLbl.Text             = selected .. " ▾"
            selLbl.TextColor3       = C.primaryLight
            selLbl.Font             = Enum.Font.GothamBold
            selLbl.TextSize         = 12 * s
            selLbl.TextXAlignment   = Enum.TextXAlignment.Right
            selLbl.ZIndex           = 7
            _onTheme(function(p, l) if selLbl.Parent then selLbl.TextColor3 = l end end)

            -- Options panel (sits below header)
            local panel = Instance.new("Frame", container)
            panel.Size                   = UDim2.new(1, 0, 0, 0)
            panel.Position               = UDim2.new(0, 0, 0, 44 * s)
            panel.BackgroundColor3       = C.elementBg
            panel.BackgroundTransparency = 0.1
            panel.BorderSizePixel        = 0
            panel.Visible                = false
            panel.ZIndex                 = 8
            panel.ClipsDescendants       = true
            Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 6 * s)
            Instance.new("UIStroke", panel).Color        = C.border
            local panelLayout = Instance.new("UIListLayout", panel)
            panelLayout.SortOrder = Enum.SortOrder.LayoutOrder

            for _, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton", panel)
                optBtn.Size                   = UDim2.new(1, 0, 0, 30 * s)
                optBtn.BackgroundTransparency = 1
                optBtn.Text                   = opt
                optBtn.TextColor3             = C.textMuted
                optBtn.Font                   = Enum.Font.GothamMedium
                optBtn.TextSize               = 12 * s
                optBtn.ZIndex                 = 9
                attachRipple(optBtn)
                optBtn.MouseButton1Click:Connect(function()
                    selected      = opt
                    selLbl.Text   = opt .. " ▾"
                    open          = false
                    panel.Visible = false
                    container.Size = UDim2.new(1, -8 * s, 0, 42 * s)
                    logic(opt)
                    playSound("rbxassetid://6895079813", 0.25)
                end)
            end

            panelLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                panel.Size = UDim2.new(1, 0, 0, panelLayout.AbsoluteContentSize.Y)
            end)

            local totalH = #options * 30 * s

            local headerClick = Instance.new("TextButton", header)
            headerClick.Size                   = UDim2.new(1, 0, 1, 0)
            headerClick.BackgroundTransparency = 1
            headerClick.Text                   = ""
            headerClick.ZIndex                 = 10
            headerClick.MouseButton1Click:Connect(function()
                open = not open
                panel.Visible  = open
                container.Size = open
                    and UDim2.new(1, -8 * s, 0, 42 * s + totalH + 4 * s)
                    or  UDim2.new(1, -8 * s, 0, 42 * s)
                playSound("rbxassetid://6895079813", 0.2)
            end)
        end

        -- ── Tab:Paragraph(config) ──
        -- config = { Content = "Some informational text here." }
        function Tab:Paragraph(pConfig)
            pConfig = pConfig or {}
            local content = pConfig.Content or ""

            local lbl = Instance.new("TextLabel", page)
            lbl.Size                   = UDim2.new(1, -8 * s, 0, 0)
            lbl.AutomaticSize          = Enum.AutomaticSize.Y
            lbl.BackgroundColor3       = C.elementBg
            lbl.BackgroundTransparency = 0.6
            lbl.Text                   = content
            lbl.TextColor3             = C.textMuted
            lbl.Font                   = Enum.Font.Gotham
            lbl.TextSize               = 12 * s
            lbl.TextWrapped            = true
            lbl.TextXAlignment         = Enum.TextXAlignment.Left
            lbl.ZIndex                 = 2
            Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 6 * s)
            local pad = Instance.new("UIPadding", lbl)
            pad.PaddingLeft   = UDim.new(0, 12 * s)
            pad.PaddingRight  = UDim.new(0, 12 * s)
            pad.PaddingTop    = UDim.new(0, 8 * s)
            pad.PaddingBottom = UDim.new(0, 8 * s)
        end

        return Tab
    end

    -- ── Window:SetTheme(name) ──
    -- name = "Crimson Red"|"Cyberpunk Yellow"|"Neon Green"|"Royal Purple"|"Rainbow"
    function Window:SetTheme(name)
        if name == "Rainbow" then
            RunService.RenderStepped:Connect(function()
                local hue = tick() % 5 / 5
                UpdateTheme(
                    Color3.fromHSV(hue, 1,   1),
                    Color3.fromHSV(hue, 0.6, 1),
                    Color3.fromHSV(hue, 1,   0.5)
                )
            end)
        elseif Themes[name] then
            local t = Themes[name]
            UpdateTheme(t.P, t.L, t.D)
        end
    end

    -- ── Window:SetBackground(effectName) ──
    -- effectName = "Stars"|"Matrix"|"Grid"|"None"
    function Window:SetBackground(effectName)
        StartBgEffect(bgContainer, effectName)
    end

    -- ── Window:Destroy() ──
    function Window:Destroy()
        sg:Destroy()
    end

    return Window
end

return DivineUI
