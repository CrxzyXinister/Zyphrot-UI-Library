--[[
╔══════════════════════════════════════════════════════╗
║              ZYPHROT UI LIBRARY v1.0                 ║
║         Extracted from Zyphrot Hub by Claude         ║
╠══════════════════════════════════════════════════════╣
║  A clean, reusable Roblox UI library with:           ║
║  • Draggable windows                                 ║
║  • Tabbed navigation                                 ║
║  • Toggle switches (with keybind support)            ║
║  • Sliders (with live text input)                    ║
║  • Buttons (with ripple effect)                      ║
║  • Section headers                                   ║
║  • Theme system (multi-theme + rainbow)              ║
║  • Animated backgrounds                              ║
║  • Mobile scaling support                            ║
╚══════════════════════════════════════════════════════╝

QUICK START:
    local UI = loadstring(...)() -- or require/load however you load modules
    local Window = UI.new("My Hub")
    local Tab = Window:AddTab("Settings")
    Tab:AddToggle("Speed Boost", false, function(state) print(state) end)
    Tab:AddSlider("Speed", 10, 100, 30, function(val) print(val) end)
    Tab:AddButton("Do Something", function() print("clicked!") end)
]]

local ZyphrotUI = {}
ZyphrotUI.__index = ZyphrotUI

-- ============================================================
-- SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local SoundService     = game:GetService("SoundService")

local Player = Players.LocalPlayer

-- ============================================================
-- MOBILE DETECTION & SCALE
-- ============================================================
-- `s` is a universal scale factor applied to every size/position/
-- textsize so the UI looks correct on both PC and mobile.
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local s = isMobile and 0.65 or 1

-- ============================================================
-- DEFAULT THEME COLORS
-- Built-in themes: "Crimson Red", "Cyberpunk Yellow",
--                  "Neon Green", "Royal Purple", "Rainbow"
-- ============================================================
local Themes = {
    ["Crimson Red"]     = { P = Color3.fromRGB(220, 20,  60),  L = Color3.fromRGB(255, 60,  90),  D = Color3.fromRGB(150, 15,  40)  },
    ["Cyberpunk Yellow"]= { P = Color3.fromRGB(255, 215, 0),   L = Color3.fromRGB(255, 235, 100), D = Color3.fromRGB(180, 150, 0)   },
    ["Neon Green"]      = { P = Color3.fromRGB(50,  255, 50),  L = Color3.fromRGB(100, 255, 100), D = Color3.fromRGB(20,  180, 20)  },
    ["Royal Purple"]    = { P = Color3.fromRGB(138, 43,  226), L = Color3.fromRGB(170, 80,  255), D = Color3.fromRGB(90,  20,  150) },
    ["Toxic Neon"]      = { P = Color3.fromRGB(50, 255, 50), L = Color3.fromRGB(100, 255, 100), Do = Color.3fromRGB(20, 185, 20), }
}

-- C holds the live color values — mutated by UpdateTheme()
local C = {
    bg          = Color3.fromRGB(12,  12,  15),
    sidebar     = Color3.fromRGB(18,  18,  22),
    primary     = Themes["Crimson Red"].P,
    primaryLight= Themes["Crimson Red"].L,
    primaryDark = Themes["Crimson Red"].D,
    text        = Color3.fromRGB(245, 245, 245),
    textMuted   = Color3.fromRGB(130, 130, 140),
    elementBg   = Color3.fromRGB(24,  24,  28),
    border      = Color3.fromRGB(40,  40,  48),
    success     = Color3.fromRGB(40,  200, 100),
}

-- ============================================================
-- INTERNAL HELPERS
-- ============================================================

-- ThemeUpdateFuncs: every UI element that needs recoloring
-- registers a callback here via _onTheme(fn).
local ThemeUpdateFuncs = {}
local function _onTheme(fn) table.insert(ThemeUpdateFuncs, fn) end

--- Applies a new primary/light/dark triplet and calls all
--- registered recolor callbacks.
local function UpdateTheme(p, l, d)
    C.primary      = p
    C.primaryLight = l
    C.primaryDark  = d
    for _, fn in ipairs(ThemeUpdateFuncs) do
        pcall(fn, p, l, d)
    end
end

--- Plays a short UI click sound.
local function playSound(id, vol)
    pcall(function()
        local snd = Instance.new("Sound", SoundService)
        snd.SoundId  = id or "rbxassetid://6895079813"
        snd.Volume   = vol or 0.3
        snd:Play()
        game:GetService("Debris"):AddItem(snd, 1)
    end)
end

--- Spawns a ripple effect inside a frame when clicked.
--- @param btn TextButton — the button that receives InputBegan
--- @param target Frame   — the frame the ripple renders inside (defaults to btn)
local function attachRipple(btn, target)
    target = target or btn
    target.ClipsDescendants = true
    btn.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        task.spawn(function()
            local ripple = Instance.new("Frame", target)
            ripple.BackgroundColor3  = Color3.new(1, 1, 1)
            ripple.AnchorPoint       = Vector2.new(0.5, 0.5)
            ripple.Size              = UDim2.new(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.6
            ripple.ZIndex            = (target.ZIndex or 1) + 1
            local lx = input.Position.X - target.AbsolutePosition.X
            local ly = input.Position.Y - target.AbsolutePosition.Y
            ripple.Position          = UDim2.new(0, lx, 0, ly)
            Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)
            local maxSz = math.max(target.AbsoluteSize.X, target.AbsoluteSize.Y) * 2
            TweenService:Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, maxSz, 0, maxSz),
                BackgroundTransparency = 1,
            }):Play()
            task.wait(0.4)
            ripple:Destroy()
        end)
    end)
end

--- Makes any Frame draggable with both mouse and touch.
--- @param frame Frame — the frame to make draggable
local function MakeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
    frame.InputBegan:Connect(function(input)
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
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then update(input) end
    end)
end

-- ============================================================
-- BACKGROUND EFFECTS
-- Available values: "Stars", "Matrix", "Grid", "Pulse",
--                   "Snow", "Circles", "None"
-- ============================================================
local bgEffectLoopId = 0

--- Starts an animated background inside the given container frame.
--- @param container Frame   — clipped frame to render particles inside
--- @param effectName string — one of the effect names listed above
local function StartBackgroundEffect(container, effectName)
    bgEffectLoopId = bgEffectLoopId + 1
    local loopId = bgEffectLoopId
    container:ClearAllChildren()

    if effectName == "Stars" then
        task.spawn(function()
            while loopId == bgEffectLoopId and container.Parent do
                local sz   = math.random(2, 6) * s
                local star = Instance.new("Frame", container)
                star.Size             = UDim2.new(0, sz, 0, sz)
                star.Position         = UDim2.new(math.random(1, 1000) / 1000, 0, 1.1, 0)
                star.BackgroundColor3 = math.random(1, 3) == 1 and C.primaryLight or Color3.fromRGB(255, 255, 255)
                star.BorderSizePixel  = 0
                star.ZIndex           = 1
                star.BackgroundTransparency = 0
                Instance.new("UICorner", star).CornerRadius = UDim.new(1, 0)
                local glow = Instance.new("UIStroke", star)
                glow.Color        = star.BackgroundColor3
                glow.Thickness    = sz / 1.5
                glow.Transparency = 0.6
                local dur  = math.random(6, 14)
                local endX = star.Position.X.Scale + (math.random(-10, 10) / 100)
                TweenService:Create(star, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(endX, 0, -0.2, 0)
                }):Play()
                task.delay(dur, function() if star then star:Destroy() end end)
                task.wait(0.15)
            end
        end)

    elseif effectName == "Matrix" then
        task.spawn(function()
            while loopId == bgEffectLoopId and container.Parent do
                local char  = string.char(math.random(33, 126))
                local startX = math.random(1, 1000) / 1000
                local dur   = math.random(3, 7)
                local lbl   = Instance.new("TextLabel", container)
                lbl.Text              = char
                lbl.TextColor3        = C.primaryLight
                lbl.BackgroundTransparency = 1
                lbl.Size              = UDim2.new(0, 15, 0, 15)
                lbl.Position          = UDim2.new(startX, 0, -0.1, 0)
                lbl.Font              = Enum.Font.Code
                lbl.TextSize          = 14 * s
                lbl.ZIndex            = 1
                TweenService:Create(lbl, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(startX, 0, 1.1, 0),
                    TextTransparency = 1
                }):Play()
                task.delay(dur, function() if lbl then lbl:Destroy() end end)
                task.wait(0.05)
            end
        end)

    elseif effectName == "Grid" then
        local grid = Instance.new("Frame", container)
        grid.Size = UDim2.new(1, 0, 1, 0)
        grid.BackgroundTransparency = 1
        for i = 1, 10 do
            local hLine = Instance.new("Frame", grid)
            hLine.Size             = UDim2.new(1, 0, 0, 1)
            hLine.Position         = UDim2.new(0, 0, i / 10, 0)
            hLine.BackgroundColor3 = C.primary
            hLine.BackgroundTransparency = 0.8
            hLine.BorderSizePixel  = 0
            _onTheme(function(p) if hLine.Parent then hLine.BackgroundColor3 = p end end)
            local vLine = Instance.new("Frame", grid)
            vLine.Size             = UDim2.new(0, 1, 1, 0)
            vLine.Position         = UDim2.new(i / 10, 0, 0, 0)
            vLine.BackgroundColor3 = C.primary
            vLine.BackgroundTransparency = 0.8
            vLine.BorderSizePixel  = 0
            _onTheme(function(p) if vLine.Parent then vLine.BackgroundColor3 = p end end)
        end
        task.spawn(function()
            local offset = 0
            while loopId == bgEffectLoopId and container.Parent do
                offset = (offset + 0.001) % 0.1
                for i, child in ipairs(grid:GetChildren()) do
                    if child.Size.Y.Offset == 1 then
                        child.Position = UDim2.new(0, 0, ((math.floor((i - 1) / 2)) / 10 + offset) % 1, 0)
                    else
                        child.Position = UDim2.new(((math.floor((i - 1) / 2)) / 10 + offset) % 1, 0, 0, 0)
                    end
                end
                task.wait(0.03)
            end
        end)

    end
    -- "None" just leaves container empty — intentional.
end

-- ============================================================
-- WINDOW CLASS
-- ============================================================

--- Creates a new draggable hub window.
--- @param title  string  — text shown in the title bar
--- @param opts   table?  — optional: { width, height, theme, background }
--- @return Window object with :AddTab(), :SetTheme(), etc.
function ZyphrotUI.new(title, opts)
    opts = opts or {}

    local width  = (opts.width  or 650) * s
    local height = (opts.height or 420) * s

    -- ScreenGui
    local sg = Instance.new("ScreenGui", Player.PlayerGui)
    sg.Name           = "ZyphrotUI_" .. title
    sg.ResetOnSpawn   = false
    sg.IgnoreGuiInset = true

    -- ── Toggle button (always visible, press to show/hide) ──
    local toggleBtn = Instance.new("TextButton", sg)
    toggleBtn.Size                = UDim2.new(0, 45, 0, 45)
    toggleBtn.Position            = UDim2.new(1, -65, 0, 15)
    toggleBtn.BackgroundColor3    = C.elementBg
    toggleBtn.Text                = "ZH"
    toggleBtn.TextColor3          = C.primary
    toggleBtn.Font                = Enum.Font.GothamBlack
    toggleBtn.TextSize            = 18
    toggleBtn.BackgroundTransparency = 0.1
    toggleBtn.ZIndex              = 10
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)
    attachRipple(toggleBtn)
    local tgStroke = Instance.new("UIStroke", toggleBtn)
    tgStroke.Thickness = 2
    local tgGrad = Instance.new("UIGradient", tgStroke)
    tgGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   C.primaryLight),
        ColorSequenceKeypoint.new(0.5, C.border),
        ColorSequenceKeypoint.new(1,   C.primaryDark),
    })
    _onTheme(function(p, l, d)
        if toggleBtn.Parent then toggleBtn.TextColor3 = p end
        if tgGrad.Parent then
            tgGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   l),
                ColorSequenceKeypoint.new(0.5, C.border),
                ColorSequenceKeypoint.new(1,   d),
            })
        end
    end)

    -- ── Main window frame ──
    local main = Instance.new("Frame", sg)
    main.Size             = UDim2.new(0, width, 0, height)
    main.Position         = UDim2.new(0.5, -width / 2, 0.5, -height / 2)
    main.BackgroundColor3 = C.bg
    main.BackgroundTransparency = 0.05
    main.BorderSizePixel  = 0
    main.Active           = true
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8 * s)
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

    -- Rotating gradient animation
    task.spawn(function()
        local r = 0
        while sg.Parent do
            r = (r + 1.5) % 360
            mainGrad.Rotation   = r
            tgGrad.Rotation     = -r
            task.wait(0.02)
        end
    end)

    -- ── Background container ──
    local bgContainer = Instance.new("Frame", main)
    bgContainer.Name               = "BgContainer"
    bgContainer.Size               = UDim2.new(1, 0, 1, 0)
    bgContainer.BackgroundTransparency = 1
    bgContainer.ZIndex             = 1
    bgContainer.ClipsDescendants   = true

    -- ── Sidebar ──
    local sidebar = Instance.new("Frame", main)
    sidebar.Size             = UDim2.new(0, 160 * s, 1, 0)
    sidebar.BackgroundColor3 = C.sidebar
    sidebar.BorderSizePixel  = 0
    sidebar.ZIndex           = 2
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 8 * s)

    -- Sidebar border line
    local sidebarLine = Instance.new("Frame", main)
    sidebarLine.Size             = UDim2.new(0, 1, 1, 0)
    sidebarLine.Position         = UDim2.new(0, 160 * s, 0, 0)
    sidebarLine.BackgroundColor3 = C.border
    sidebarLine.BorderSizePixel  = 0
    sidebarLine.ZIndex           = 2

    -- Logo
    local logoTitle = Instance.new("TextLabel", sidebar)
    logoTitle.Size             = UDim2.new(1, 0, 0, 55 * s)
    logoTitle.BackgroundTransparency = 1
    logoTitle.Text             = title
    logoTitle.Font             = Enum.Font.GothamBlack
    logoTitle.TextSize         = 20 * s
    logoTitle.TextColor3       = Color3.new(1, 1, 1)
    logoTitle.ZIndex           = 2
    local titleGrad = Instance.new("UIGradient", logoTitle)
    titleGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   C.primaryLight),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1,   C.primaryDark),
    })
    _onTheme(function(p, l, d)
        if titleGrad.Parent then
            titleGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   l),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1,   d),
            })
        end
    end)
    task.spawn(function()
        local r = 0
        while sg.Parent do
            r = (r + 1.5) % 360
            if titleGrad then titleGrad.Rotation = r end
            task.wait(0.02)
        end
    end)

    -- Separator
    local sep = Instance.new("Frame", sidebar)
    sep.Size             = UDim2.new(0.8, 0, 0, 2 * s)
    sep.Position         = UDim2.new(0.1, 0, 0, 55 * s)
    sep.BackgroundColor3 = C.border
    sep.BackgroundTransparency = 0.5
    sep.BorderSizePixel  = 0
    sep.ZIndex           = 2

    -- Tab container
    local tabContainer = Instance.new("Frame", sidebar)
    tabContainer.Size             = UDim2.new(1, 0, 1, -140 * s)
    tabContainer.Position         = UDim2.new(0, 0, 0, 65 * s)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ZIndex           = 2

    -- User info strip at bottom of sidebar
    local userInfoFrame = Instance.new("Frame", sidebar)
    userInfoFrame.Size             = UDim2.new(1, 0, 0, 60 * s)
    userInfoFrame.Position         = UDim2.new(0, 0, 1, -60 * s)
    userInfoFrame.BackgroundTransparency = 1
    userInfoFrame.ZIndex           = 2

    local userAvatar = Instance.new("ImageLabel", userInfoFrame)
    userAvatar.Size           = UDim2.new(0, 32 * s, 0, 32 * s)
    userAvatar.Position       = UDim2.new(0, 12 * s, 0.5, -16 * s)
    userAvatar.BackgroundColor3 = C.elementBg
    userAvatar.Image          = "rbxthumb://type=AvatarHeadShot&id=" .. Player.UserId .. "&w=150&h=150"
    userAvatar.ZIndex         = 2
    Instance.new("UICorner", userAvatar).CornerRadius = UDim.new(1, 0)
    local avatarStroke = Instance.new("UIStroke", userAvatar)
    avatarStroke.Color     = C.primary
    avatarStroke.Thickness = 1.5
    _onTheme(function(p) if avatarStroke.Parent then avatarStroke.Color = p end end)

    local userNameLabel = Instance.new("TextLabel", userInfoFrame)
    userNameLabel.Size             = UDim2.new(1, -55 * s, 0, 15 * s)
    userNameLabel.Position         = UDim2.new(0, 52 * s, 0.5, -6 * s)
    userNameLabel.BackgroundTransparency = 1
    userNameLabel.Text             = Player.Name
    userNameLabel.TextColor3       = C.text
    userNameLabel.Font             = Enum.Font.GothamBold
    userNameLabel.TextSize         = 11 * s
    userNameLabel.TextXAlignment   = Enum.TextXAlignment.Left
    userNameLabel.TextTruncate     = Enum.TextTruncate.AtEnd
    userNameLabel.ZIndex           = 2

    -- Content area (right of sidebar)
    local contentArea = Instance.new("Frame", main)
    contentArea.Size              = UDim2.new(1, -160 * s, 1, 0)
    contentArea.Position          = UDim2.new(0, 160 * s, 0, 0)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants  = true
    contentArea.ZIndex            = 2

    -- Toggle visibility
    local guiVisible = true
    toggleBtn.MouseButton1Click:Connect(function()
        guiVisible = not guiVisible
        main.Visible = guiVisible
    end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.U then
            guiVisible = not guiVisible
            main.Visible = guiVisible
        end
    end)

    -- Tab state
    local pages      = {}
    local tabButtons = {}
    local activeTab  = nil

    -- ── switchTab: animate the tab transition ──
    local function switchTab(name)
        if activeTab == name then return end
        activeTab = name
        for n, page in pairs(pages) do
            if n == name then
                page.Visible  = true
                page.Position = UDim2.new(0, 40 * s, 0, 10 * s)
                TweenService:Create(page, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, 10 * s, 0, 10 * s)
                }):Play()
            else
                page.Visible = false
            end
        end
        for n, btn in pairs(tabButtons) do
            if n == name then
                TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = C.elementBg, TextColor3 = C.text }):Play()
                TweenService:Create(btn.GlowEffect,  TweenInfo.new(0.2), { BackgroundTransparency = 0.85 }):Play()
                TweenService:Create(btn.UIStroke,    TweenInfo.new(0.2), { Transparency = 0 }):Play()
                btn.Indicator.Visible = true
            else
                TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = C.sidebar, TextColor3 = C.textMuted }):Play()
                TweenService:Create(btn.GlowEffect,  TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
                TweenService:Create(btn.UIStroke,    TweenInfo.new(0.2), { Transparency = 1 }):Play()
                btn.Indicator.Visible = false
            end
        end
        playSound("rbxassetid://6895079813", 0.2)
    end

    -- Window object
    local Window = {}

    -- ── Window:AddTab(name) ──
    --- Adds a sidebar tab and returns a Tab object.
    --- @param name string — label shown on the sidebar button
    --- @return Tab object with :AddToggle(), :AddSlider(), etc.
    function Window:AddTab(name)
        -- Sidebar button
        local btn = Instance.new("TextButton", tabContainer)
        btn.Size             = UDim2.new(1, -20 * s, 0, 40 * s)
        btn.Position         = UDim2.new(0, 10 * s, 0, #tabContainer:GetChildren() * (50 * s))
        btn.BackgroundColor3 = C.sidebar
        btn.Text             = "   " .. name
        btn.TextColor3       = C.textMuted
        btn.Font             = Enum.Font.GothamSemibold
        btn.TextSize         = 14 * s
        btn.TextXAlignment   = Enum.TextXAlignment.Left
        btn.ZIndex           = 2
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6 * s)
        attachRipple(btn)

        local glow = Instance.new("Frame", btn)
        glow.Name             = "GlowEffect"
        glow.Size             = UDim2.new(1, 0, 1, 0)
        glow.BackgroundColor3 = C.primary
        glow.BackgroundTransparency = 1
        glow.ZIndex           = 1
        Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 6 * s)

        local strk = Instance.new("UIStroke", btn)
        strk.Name        = "UIStroke"
        strk.Color       = C.primaryLight
        strk.Thickness   = 1.5
        strk.Transparency = 1

        local indicator = Instance.new("Frame", btn)
        indicator.Name            = "Indicator"
        indicator.Size            = UDim2.new(0, 4 * s, 0, 20 * s)
        indicator.Position        = UDim2.new(0, 0, 0.5, -10 * s)
        indicator.BackgroundColor3 = C.primary
        indicator.BorderSizePixel = 0
        indicator.Visible         = false
        indicator.ZIndex          = 2
        Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 4 * s)

        _onTheme(function(p, l, d)
            if glow.Parent      then glow.BackgroundColor3      = p end
            if strk.Parent      then strk.Color                 = l end
            if indicator.Parent then indicator.BackgroundColor3  = p end
        end)

        -- Scrolling page
        local page = Instance.new("ScrollingFrame", contentArea)
        page.Size                = UDim2.new(1, -20 * s, 1, -20 * s)
        page.Position            = UDim2.new(0, 10 * s, 0, 10 * s)
        page.BackgroundTransparency = 1
        page.ScrollBarThickness  = 4 * s
        page.ScrollBarImageColor3 = C.border
        page.Visible             = false
        page.ZIndex              = 2
        local layout = Instance.new("UIListLayout", page)
        layout.Padding    = UDim.new(0, 8 * s)
        layout.SortOrder  = Enum.SortOrder.LayoutOrder
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20 * s)
        end)

        btn.MouseButton1Click:Connect(function() switchTab(name) end)
        tabButtons[name] = btn
        pages[name]      = page

        -- Open first tab automatically
        if activeTab == nil then switchTab(name) end

        -- ── Tab object ──
        local Tab = {}

        --- Adds a labelled section header (non-interactive).
        --- @param text string
        function Tab:AddSection(text)
            local lbl = Instance.new("TextLabel", page)
            lbl.Size             = UDim2.new(1, -10 * s, 0, 28 * s)
            lbl.BackgroundColor3 = C.elementBg
            lbl.BackgroundTransparency = 0.3
            lbl.Text             = text
            lbl.TextColor3       = C.primaryLight
            lbl.Font             = Enum.Font.GothamBold
            lbl.TextSize         = 11 * s
            lbl.TextXAlignment   = Enum.TextXAlignment.Left
            lbl.ZIndex           = 2
            Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 4 * s)
            local pad = Instance.new("UIPadding", lbl)
            pad.PaddingLeft = UDim.new(0, 12 * s)
            _onTheme(function(p, l) if lbl.Parent then lbl.TextColor3 = l end end)
        end

        --- Adds a toggle switch row.
        --- @param label      string   — display text
        --- @param default    boolean  — initial state
        --- @param callback   function — called with (newState: boolean) on change
        --- @param keybindKey string?  — KEYBINDS table key; shows a rebind button if provided
        --- @param KEYBINDS   table?   — your keybinds table (required if keybindKey provided)
        --- @return setVisual function — call setVisual(bool) to change state externally
        function Tab:AddToggle(label, default, callback, keybindKey, KEYBINDS)
            local row = Instance.new("Frame", page)
            row.Size             = UDim2.new(1, -10 * s, 0, 50 * s)
            row.BackgroundColor3 = C.elementBg
            row.BackgroundTransparency = 0.55
            row.ZIndex           = 2
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6 * s)
            Instance.new("UIStroke", row).Color        = C.border

            local lbl = Instance.new("TextLabel", row)
            lbl.Size             = UDim2.new(0.55, 0, 1, 0)
            lbl.Position         = UDim2.new(0, 15 * s, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text             = label
            lbl.TextColor3       = C.text
            lbl.Font             = Enum.Font.GothamSemibold
            lbl.TextSize         = 14 * s
            lbl.TextXAlignment   = Enum.TextXAlignment.Left
            lbl.ZIndex           = 2

            local rightOffset = -15 * s
            local isOn = default or false

            -- Switch background
            local toggleBg = Instance.new("Frame", row)
            toggleBg.Size             = UDim2.new(0, 44 * s, 0, 24 * s)
            toggleBg.Position         = UDim2.new(1, rightOffset - (44 * s), 0.5, -12 * s)
            toggleBg.BackgroundColor3 = isOn and C.primary or C.sidebar
            toggleBg.ZIndex           = 2
            Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)

            -- Switch knob
            local toggleCircle = Instance.new("Frame", toggleBg)
            toggleCircle.Size             = UDim2.new(0, 18 * s, 0, 18 * s)
            toggleCircle.Position         = isOn and UDim2.new(1, -21 * s, 0.5, -9 * s) or UDim2.new(0, 3 * s, 0.5, -9 * s)
            toggleCircle.BackgroundColor3 = Color3.new(1, 1, 1)
            toggleCircle.ZIndex           = 2
            Instance.new("UICorner", toggleCircle).CornerRadius = UDim.new(1, 0)

            -- Invisible click region (covers full row)
            local clickBtn = Instance.new("TextButton", row)
            clickBtn.Size             = UDim2.new(1, 0, 1, 0)
            clickBtn.BackgroundTransparency = 1
            clickBtn.Text             = ""
            clickBtn.ZIndex           = 3
            attachRipple(clickBtn, row)

            _onTheme(function(p)
                if toggleBg.Parent and isOn then toggleBg.BackgroundColor3 = p end
            end)

            -- Optional keybind button
            if keybindKey and KEYBINDS then
                local keyBtn = Instance.new("TextButton", row)
                keyBtn.Size             = UDim2.new(0, 30 * s, 0, 24 * s)
                keyBtn.Position         = UDim2.new(1, rightOffset - (44 * s) - (40 * s), 0.5, -12 * s)
                keyBtn.BackgroundColor3 = C.sidebar
                keyBtn.Text             = KEYBINDS[keybindKey] and KEYBINDS[keybindKey].Name or "?"
                keyBtn.TextColor3       = C.text
                keyBtn.Font             = Enum.Font.GothamBold
                keyBtn.TextSize         = 12 * s
                keyBtn.ZIndex           = 3
                Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 4 * s)
                Instance.new("UIStroke", keyBtn).Color        = C.border
                local waiting = false
                keyBtn.MouseButton1Click:Connect(function()
                    waiting = true
                    keyBtn.Text = "..."
                    playSound("rbxassetid://6895079813", 0.4)
                end)
                UserInputService.InputBegan:Connect(function(input, gpe)
                    if gpe or not waiting then return end
                    if input.KeyCode ~= Enum.KeyCode.Unknown then
                        KEYBINDS[keybindKey] = input.KeyCode
                        keyBtn.Text = input.KeyCode.Name
                        waiting = false
                    end
                end)
            end

            -- setVisual: externally drive the toggle state
            local function setVisual(state, skipCallback)
                isOn = state
                TweenService:Create(toggleBg, TweenInfo.new(0.2), {
                    BackgroundColor3 = isOn and C.primary or C.sidebar
                }):Play()
                TweenService:Create(toggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
                    Position = isOn
                        and UDim2.new(1, -21 * s, 0.5, -9 * s)
                        or  UDim2.new(0,  3 * s, 0.5, -9 * s)
                }):Play()
                if not skipCallback and callback then callback(isOn) end
            end

            clickBtn.MouseButton1Click:Connect(function()
                isOn = not isOn
                setVisual(isOn)
                playSound("rbxassetid://6895079813", 0.4)
            end)

            return setVisual
        end

        --- Adds a labelled slider with a live-editable value box.
        --- @param label    string   — display text
        --- @param minVal   number   — minimum value
        --- @param maxVal   number   — maximum value
        --- @param default  number   — starting value
        --- @param callback function — called with (value: number) while dragging
        --- @param isFloat  boolean? — true allows decimals (2 dp), false snaps to integers
        --- @return setVal function  — call setVal(number) to set value externally
        function Tab:AddSlider(label, minVal, maxVal, default, callback, isFloat)
            local row = Instance.new("Frame", page)
            row.Size             = UDim2.new(1, -10 * s, 0, 65 * s)
            row.BackgroundColor3 = C.elementBg
            row.BackgroundTransparency = 0.55
            row.ZIndex           = 2
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6 * s)
            Instance.new("UIStroke", row).Color        = C.border

            local lbl = Instance.new("TextLabel", row)
            lbl.Size             = UDim2.new(0.5, 0, 0, 20 * s)
            lbl.Position         = UDim2.new(0, 15 * s, 0, 10 * s)
            lbl.BackgroundTransparency = 1
            lbl.Text             = label
            lbl.TextColor3       = C.text
            lbl.Font             = Enum.Font.GothamSemibold
            lbl.TextSize         = 14 * s
            lbl.TextXAlignment   = Enum.TextXAlignment.Left
            lbl.ZIndex           = 2

            local currentVal = default or minVal

            -- Editable value box
            local valueBox = Instance.new("TextBox", row)
            valueBox.Size             = UDim2.new(0, 50 * s, 0, 24 * s)
            valueBox.Position         = UDim2.new(1, -65 * s, 0, 8 * s)
            valueBox.BackgroundColor3 = C.sidebar
            valueBox.Text             = tostring(currentVal)
            valueBox.TextColor3       = C.primary
            valueBox.Font             = Enum.Font.GothamBold
            valueBox.TextSize         = 13 * s
            valueBox.ClearTextOnFocus = false
            valueBox.ZIndex           = 3
            Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 4 * s)
            Instance.new("UIStroke", valueBox).Color        = C.border

            _onTheme(function(p) if valueBox.Parent then valueBox.TextColor3 = p end end)

            -- Track
            local sliderBg = Instance.new("Frame", row)
            sliderBg.Size             = UDim2.new(1, -30 * s, 0, 6 * s)
            sliderBg.Position         = UDim2.new(0, 15 * s, 0, 45 * s)
            sliderBg.BackgroundColor3 = C.sidebar
            sliderBg.ZIndex           = 2
            Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

            local pct = math.clamp((currentVal - minVal) / (maxVal - minVal), 0, 1)

            local sliderFill = Instance.new("Frame", sliderBg)
            sliderFill.Size             = UDim2.new(pct, 0, 1, 0)
            sliderFill.BackgroundColor3 = C.primary
            sliderFill.ZIndex           = 2
            Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

            local thumb = Instance.new("Frame", sliderBg)
            thumb.Size             = UDim2.new(0, 14 * s, 0, 14 * s)
            thumb.Position         = UDim2.new(pct, -7 * s, 0.5, -7 * s)
            thumb.BackgroundColor3 = Color3.new(1, 1, 1)
            thumb.ZIndex           = 3
            Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

            _onTheme(function(p) if sliderFill.Parent then sliderFill.BackgroundColor3 = p end end)

            -- Larger invisible drag zone
            local dragBtn = Instance.new("TextButton", sliderBg)
            dragBtn.Size             = UDim2.new(1, 0, 3, 0)
            dragBtn.Position         = UDim2.new(0, 0, -1, 0)
            dragBtn.BackgroundTransparency = 1
            dragBtn.Text             = ""
            dragBtn.ZIndex           = 4

            local dragging = false

            local function update(rel, skipCall)
                rel = math.clamp(rel, 0, 1)
                sliderFill.Size   = UDim2.new(rel, 0, 1, 0)
                thumb.Position    = UDim2.new(rel, -7 * s, 0.5, -7 * s)
                local val = minVal + (maxVal - minVal) * rel
                if not isFloat then
                    val = math.floor(val)
                else
                    val = math.floor(val * 100) / 100
                end
                currentVal = val
                valueBox.Text = tostring(val)
                if not skipCall and callback then callback(val) end
            end

            dragBtn.MouseButton1Down:Connect(function() dragging = true end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                    update((i.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X)
                end
            end)

            valueBox.FocusLost:Connect(function()
                local n = tonumber(valueBox.Text)
                if n then
                    n = math.clamp(n, minVal, maxVal)
                    n = isFloat and (math.floor(n * 100) / 100) or math.floor(n)
                    valueBox.Text = tostring(n)
                    local r = (n - minVal) / (maxVal - minVal)
                    sliderFill.Size = UDim2.new(r, 0, 1, 0)
                    thumb.Position  = UDim2.new(r, -7 * s, 0.5, -7 * s)
                    currentVal = n
                    if callback then callback(n) end
                else
                    valueBox.Text = tostring(currentVal)
                end
            end)

            local function setVal(v)
                local rel = math.clamp((v - minVal) / (maxVal - minVal), 0, 1)
                sliderFill.Size = UDim2.new(rel, 0, 1, 0)
                thumb.Position  = UDim2.new(rel, -7 * s, 0.5, -7 * s)
                currentVal = v
                valueBox.Text = tostring(v)
            end

            return setVal
        end

        --- Adds a clickable button.
        --- @param text     string   — button label
        --- @param callback function — called with (button: TextButton) on click
        --- @param color    Color3?  — custom background; defaults to elementBg
        --- @return TextButton
        function Tab:AddButton(text, callback, color)
            local btn = Instance.new("TextButton", page)
            btn.Size             = UDim2.new(1, -10 * s, 0, 44 * s)
            btn.BackgroundColor3 = color or C.elementBg
            btn.BackgroundTransparency = 0.55
            btn.Text             = text
            btn.TextColor3       = C.text
            btn.Font             = Enum.Font.GothamBold
            btn.TextSize         = 14 * s
            btn.ZIndex           = 2
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6 * s)
            Instance.new("UIStroke", btn).Color        = C.border
            attachRipple(btn)
            btn.MouseButton1Click:Connect(function()
                playSound("rbxassetid://6895079813", 0.4)
                if callback then callback(btn) end
            end)
            return btn
        end

        --- Adds a text label (non-interactive).
        --- @param text  string
        --- @param color Color3?
        function Tab:AddLabel(text, color)
            local lbl = Instance.new("TextLabel", page)
            lbl.Size             = UDim2.new(1, -10 * s, 0, 36 * s)
            lbl.BackgroundTransparency = 1
            lbl.Text             = text
            lbl.TextColor3       = color or C.textMuted
            lbl.Font             = Enum.Font.Gotham
            lbl.TextSize         = 12 * s
            lbl.TextXAlignment   = Enum.TextXAlignment.Left
            lbl.ZIndex           = 2
            local pad = Instance.new("UIPadding", lbl)
            pad.PaddingLeft = UDim.new(0, 10 * s)
            return lbl
        end

        return Tab
    end

    --- Sets the active colour theme.
    --- @param name string — "Crimson Red" | "Cyberpunk Yellow" | "Neon Green" | "Royal Purple" | "Rainbow"
    function Window:SetTheme(name)
        if name == "Rainbow" then
            RunService.RenderStepped:Connect(function()
                local hue = tick() % 5 / 5
                UpdateTheme(
                    Color3.fromHSV(hue, 1, 1),
                    Color3.fromHSV(hue, 0.6, 1),
                    Color3.fromHSV(hue, 1, 0.5)
                )
            end)
        elseif Themes[name] then
            local t = Themes[name]
            UpdateTheme(t.P, t.L, t.D)
        end
    end

    --- Starts an animated background inside the window.
    --- @param effectName string — "Stars" | "Matrix" | "Grid" | "None"
    function Window:SetBackground(effectName)
        StartBackgroundEffect(bgContainer, effectName)
    end

    --- Destroys the entire ScreenGui.
    function Window:Destroy()
        sg:Destroy()
    end

    -- Apply opts theme/bg
    if opts.theme     then Window:SetTheme(opts.theme)           end
    if opts.background then Window:SetBackground(opts.background) end

    return Window
end

return ZyphrotUI
