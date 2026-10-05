--[[
    ███╗   ███╗██████╗     ██╗  ██╗███████╗███╗   ██╗ ██████╗
    ████╗ ████║██╔══██╗    ╚██╗██╔╝██╔════╝████╗  ██║██╔═══██╗
    ██╔████╔██║██████╔╝     ╚███╔╝ █████╗  ██╔██╗ ██║██║   ██║
    ██║╚██╔╝██║██╔══██╗     ██╔██╗ ██╔══╝  ██║╚██╗██║██║   ██║
    ██║ ╚═╝ ██║██║  ██║    ██╔╝ ██╗███████╗██║ ╚████║╚██████╔╝
    ╚═╝     ╚═╝╚═╝  ╚═╝    ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝
        H U B   S C R I P T   v4.0  (FINAL — Minimize + Logo)
]]

--=====================================================================
-- ⚙️  KONFIGURASI UTAMA — EDIT DI SINI
--=====================================================================
local CONFIG = {
    Title     = "Mr.Xeno Hub",
    Version   = "v4.0",
    Keybind   = Enum.KeyCode.RightShift,

    -- 🖼️  CUSTOM LOGO:
    --    Isi dengan "rbxassetid://ID_GAMBAR" → pakai image (no background)
    --    Kosongkan ""                          → fallback tampil teks "Mr"
    LogoId    = "",

    -- 🌐  URL JSON daftar script (WAJIB pakai raw.githubusercontent.com)
    ScriptsURL = "https://raw.githubusercontent.com/xanderzachky/mrxenohub.lua/main/scripts.json",

    TweenTime = 0.28,
    Colors = {
        Background = Color3.fromRGB(14, 14, 22),
        Panel      = Color3.fromRGB(22, 22, 34),
        PanelAlt   = Color3.fromRGB(30, 30, 45),
        Card       = Color3.fromRGB(28, 28, 42),
        Accent     = Color3.fromRGB(150, 90, 255),
        AccentDark = Color3.fromRGB(90, 50, 180),
        Text       = Color3.fromRGB(240, 240, 255),
        SubText    = Color3.fromRGB(150, 150, 180),
        Stroke     = Color3.fromRGB(45, 45, 65),
        Err        = Color3.fromRGB(230, 80, 80),
        Warn       = Color3.fromRGB(255, 170, 60),
        Ok         = Color3.fromRGB(100, 220, 140),
    }
}

-- Fallback (kalau JSON gagal di-fetch)
local FALLBACK_SCRIPTS = {
    {
        name = "John Doe",  category = "Combat", icon = "🔫",
        thumbnail = "",     desc = "Script John Doe",
        type = "button",    url = "https://pastebin.com/raw/Q8dznf77",
    },
    {
        name = "GluttonyKid", category = "Combat", icon = "😈",
        thumbnail = "",       desc = "Script GluttonyKid",
        type = "button",      url = "https://pastebin.com/raw/w3WFT9Vf",
    },
}

--=====================================================================
-- SERVICES
--=====================================================================
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

--=====================================================================
-- ANTI DOUBLE LOAD
--=====================================================================
if _G.MrXenoHubLoaded then
    warn("[Mr.Xeno Hub] Sudah ke-load, skip.")
    return
end
_G.MrXenoHubLoaded = true

--=====================================================================
-- PALETTE
--=====================================================================
local PALETTE = {
    Color3.fromRGB(150, 90, 255),
    Color3.fromRGB(80, 200, 255),
    Color3.fromRGB(255, 100, 180),
    Color3.fromRGB(100, 220, 140),
    Color3.fromRGB(255, 170, 60),
    Color3.fromRGB(255, 100, 100),
}
local function pickColor(i) return PALETTE[((i - 1) % #PALETTE) + 1] end

--=====================================================================
-- UTILS
--=====================================================================
local Utils = {}

function Utils.new(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then inst[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end

function Utils.corner(inst, r)
    return Utils.new("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = inst })
end

function Utils.stroke(inst, color, thick, trans)
    return Utils.new("UIStroke", {
        Color = color or CONFIG.Colors.Stroke,
        Thickness = thick or 1,
        Transparency = trans or 0.3,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = inst,
    })
end

function Utils.padding(inst, p)
    return Utils.new("UIPadding", {
        PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p),
        PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p),
        Parent = inst,
    })
end

function Utils.tween(inst, props, t)
    local tw = TweenService:Create(
        inst,
        TweenInfo.new(t or CONFIG.TweenTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

--=====================================================================
-- HELPERS (dideklarasi duluan biar bisa dipakai di manapun)
--=====================================================================
local function isRobloxAsset(str)
    if type(str) ~= "string" or str == "" then return false end
    return (str:match("^rbxassetid://") or str:match("^rbxthumb://")
        or str:match("^rbxasset://") or str:match("^http")) ~= nil
end

-- Bikin logo: image kalau ada LogoId, kalau kosong → teks "Mr"
local function makeLogo(parent, size, customColor)
    if CONFIG.LogoId ~= "" and isRobloxAsset(CONFIG.LogoId) then
        return Utils.new("ImageLabel", {
            Size = UDim2.new(0, size, 0, size),
            BackgroundTransparency = 1,
            Image = CONFIG.LogoId,
            ImageColor3 = Color3.new(1, 1, 1),
            ScaleType = Enum.ScaleType.Fit,
            Parent = parent,
        })
    else
        return Utils.new("TextLabel", {
            Size = UDim2.new(0, size, 0, size),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBlack,
            Text = "Mr",
            TextColor3 = customColor or CONFIG.Colors.Accent,
            TextSize = math.floor(size * 0.6),
            Parent = parent,
        })
    end
end

local function fetchJSON(url)
    local ok, result = pcall(function()
        local raw = game:HttpGet(url, true)
        return HttpService:JSONDecode(raw)
    end)
    if ok and result and result.scripts then
        return result.scripts
    end
    warn("[Mr.Xeno Hub] Gagal fetch JSON: " .. tostring(result))
    return nil
end

--=====================================================================
-- HUB API
--=====================================================================
local Hub = {}
Hub.Scripts = {}
Hub.UI      = {}

local function normalizeScript(t)
    return {
        Name      = t.name or "Unnamed",
        Category  = t.category or "Misc",
        Icon      = t.icon or "📜",
        Thumbnail = t.thumbnail or "",
        Desc      = t.desc or "",
        Type      = t.type or "button",
        URL       = t.url or "",
        Default   = t.default or false,
        Callback  = t.callback or function()
            if t.url and t.url ~= "" then
                local ok, err = pcall(function()
                    loadstring(game:HttpGet(t.url, true))()
                end)
                if not ok then return false, tostring(err) end
                return true
            end
            return false, "Tidak ada URL script."
        end,
    }
end

function Hub:LoadScripts(list)
    self.Scripts = {}
    for _, entry in ipairs(list) do
        table.insert(self.Scripts, normalizeScript(entry))
    end
end

--=====================================================================
-- NOTIFICATION
--=====================================================================
local Notify = {}
local notifyHolder

function Notify:Init(parent)
    notifyHolder = Utils.new("Frame", {
        Name = "NotifyHolder",
        Size = UDim2.new(0, 260, 1, -40),
        Position = UDim2.new(1, -20, 0, 20),
        BackgroundTransparency = 1,
        ZIndex = 200,
        Parent = parent,
    })
    Utils.new("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Parent = notifyHolder,
    })
end

function Notify:Push(text, color)
    if not notifyHolder then return end
    color = color or CONFIG.Colors.Accent

    local frame = Utils.new("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = CONFIG.Colors.Panel,
        BackgroundTransparency = 1,
        ZIndex = 200,
        Parent = notifyHolder,
    })
    Utils.corner(frame, 8)
    Utils.stroke(frame, color, 1, 0.2)

    local bar = Utils.new("Frame", {
        Size = UDim2.new(0, 4, 1, -10),
        Position = UDim2.new(0, 5, 0.5, 0),
        AnchorPoint = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = color,
        Parent = frame,
    })
    Utils.corner(bar, 2)

    Utils.new("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = CONFIG.Colors.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = frame,
    })

    Utils.tween(frame, { BackgroundTransparency = 0 })
    task.delay(2.5, function()
        Utils.tween(frame, { BackgroundTransparency = 1 })
        task.wait(CONFIG.TweenTime)
        frame:Destroy()
    end)
end

--=====================================================================
-- DRAGGABLE
--=====================================================================
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

--=====================================================================
-- BUILD UI
--=====================================================================
local CARD_W, CARD_H = 180, 300
local CARD_GAP = 14

local function buildUI()
    -- Parent
    local parent
    pcall(function()
        if CoreGui:FindFirstChild("MrXenoHubUI") then
            CoreGui.MrXenoHubUI:Destroy()
        end
        parent = Utils.new("ScreenGui", {
            Name = "MrXenoHubUI",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 999,
            Parent = CoreGui,
        })
    end)
    if not parent then
        parent = Utils.new("ScreenGui", {
            Name = "MrXenoHubUI",
            ResetOnSpawn = false,
            DisplayOrder = 999,
            Parent = LocalPlayer:WaitForChild("PlayerGui"),
        })
    end
    Hub.UI.ScreenGui = parent

    --========================= MAIN FRAME =========================
    local mainW = CARD_W * 3 + CARD_GAP * 2 + 60
    local mainH = 440
    local startPos = UDim2.new(0.5, -mainW/2, 0.5, -mainH/2)

    local main = Utils.new("Frame", {
        Name = "Main",
        Size = UDim2.new(0, mainW, 0, mainH),
        Position = startPos,
        BackgroundColor3 = CONFIG.Colors.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = parent,
    })
    Utils.corner(main, 14)
    Utils.stroke(main, CONFIG.Colors.Accent, 1.5, 0.4)
    Hub.UI.Main = main

    --========================= HEADER =========================
    local header = Utils.new("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = CONFIG.Colors.Panel,
        BorderSizePixel = 0,
        Parent = main,
    })
    Utils.corner(header, 14)
    Utils.new("Frame", {  -- nutup sudut bawah header
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 1, -14),
        BackgroundColor3 = CONFIG.Colors.Panel,
        BorderSizePixel = 0,
        Parent = header,
    })

    -- Logo (image / teks "Mr")
    local logoHolder = Utils.new("Frame", {
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(0, 12, 0.5, 0),
        AnchorPoint = UDim2.new(0, 0, 0.5, 0),
        BackgroundTransparency = 1,
        Parent = header,
    })
    makeLogo(logoHolder, 30, CONFIG.Colors.Accent)

    -- Judul
    Utils.new("TextLabel", {
        Size = UDim2.new(0, 250, 1, 0),
        Position = UDim2.new(0, 50, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = CONFIG.Title,
        TextColor3 = CONFIG.Colors.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })

    --========================= HEADER BUTTONS =========================
    -- 🔽 MINIMIZE
    local minBtn = Utils.new("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -108, 0.5, 0),
        AnchorPoint = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = CONFIG.Colors.PanelAlt,
        Text = "—",
        Font = Enum.Font.GothamBold,
        TextColor3 = CONFIG.Colors.SubText,
        TextSize = 15,
        AutoButtonColor = false,
        Parent = header,
    })
    Utils.corner(minBtn, 6)

    -- ⟳ REFRESH
    local refreshBtn = Utils.new("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -76, 0.5, 0),
        AnchorPoint = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = CONFIG.Colors.PanelAlt,
        Text = "⟳",
        Font = Enum.Font.GothamBold,
        TextColor3 = CONFIG.Colors.SubText,
        TextSize = 15,
        AutoButtonColor = false,
        Parent = header,
    })
    Utils.corner(refreshBtn, 6)

    -- ✕ CLOSE
    local closeBtn = Utils.new("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -44, 0.5, 0),
        AnchorPoint = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(60, 30, 40),
        Text = "✕",
        Font = Enum.Font.GothamBold,
        TextColor3 = Color3.fromRGB(255, 120, 120),
        TextSize = 13,
        AutoButtonColor = false,
        Parent = header,
    })
    Utils.corner(closeBtn, 6)

    makeDraggable(main, header)

    --========================= SCROLLER =========================
    local scroller = Utils.new("ScrollingFrame", {
        Name = "Scroller",
        Size = UDim2.new(1, -20, 1, -78),
        Position = UDim2.new(0, 10, 0, 66),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = CONFIG.Colors.Accent,
        ScrollingDirection = Enum.ScrollingDirection.X,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = main,
    })
    Utils.new("UIListLayout", {
        Padding = UDim.new(0, CARD_GAP),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = scroller,
    })
    Utils.new("UIPadding", {
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        Parent = scroller,
    })

    --========================= DETAIL PANEL =========================
    local detail = Utils.new("Frame", {
        Name = "Detail",
        Size = UDim2.new(1, 0, 1, -54),
        Position = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = CONFIG.Colors.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = main,
    })
    Hub.UI.Detail = detail

    --========================= RENDER DETAIL =========================
    local function renderDetail(s, color)
        for _, c in ipairs(detail:GetChildren()) do c:Destroy() end

        -- Hero
        local hero = Utils.new("Frame", {
            Size = UDim2.new(1, 0, 0, 140),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Parent = detail,
        })
        Utils.new("UIGradient", {
            Color = ColorSequence.new(color, color:Lerp(Color3.new(0,0,0), 0.6)),
            Rotation = 90,
            Parent = hero,
        })

        if isRobloxAsset(s.Thumbnail) then
            Utils.new("ImageLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Image = s.Thumbnail,
                ScaleType = Enum.ScaleType.Crop,
                Parent = hero,
            })
            local overlay = Utils.new("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BackgroundTransparency = 0.35,
                BorderSizePixel = 0,
                Parent = hero,
            })
            Utils.new("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.9),
                    NumberSequenceKeypoint.new(1, 0),
                }),
                Rotation = 90,
                Parent = overlay,
            })
        else
            Utils.new("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = s.Icon,
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 64,
                Parent = hero,
            })
        end

        -- Back
        local back = Utils.new("TextButton", {
            Size = UDim2.new(0, 40, 0, 34),
            Position = UDim2.new(0, 14, 0, 12),
            BackgroundColor3 = Color3.fromRGB(20, 20, 30),
            BackgroundTransparency = 0.3,
            Text = "←",
            Font = Enum.Font.GothamBold,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 18,
            AutoButtonColor = false,
            Parent = detail,
        })
        Utils.corner(back, 8)
        back.MouseButton1Click:Connect(function()
            Utils.tween(detail, { Position = UDim2.new(1, 0, 0, 54) })
        end)

        -- Nama
        Utils.new("TextLabel", {
            Size = UDim2.new(1, -40, 0, 30),
            Position = UDim2.new(0, 20, 0, 156),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = s.Name,
            TextColor3 = CONFIG.Colors.Text,
            TextSize = 22,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = detail,
        })

        -- Badge
        local badge = Utils.new("Frame", {
            Size = UDim2.new(0, 100, 0, 22),
            Position = UDim2.new(0, 20, 0, 190),
            BackgroundColor3 = color,
            BackgroundTransparency = 0.8,
            Parent = detail,
        })
        Utils.corner(badge, 11)
        Utils.stroke(badge, color, 1, 0.2)
        Utils.new("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            Text = s.Category,
            TextColor3 = color,
            TextSize = 11,
            Parent = badge,
        })

        -- Desc
        local descBox = Utils.new("Frame", {
            Size = UDim2.new(1, -40, 0, 90),
            Position = UDim2.new(0, 20, 0, 228),
            BackgroundColor3 = CONFIG.Colors.Panel,
            BorderSizePixel = 0,
            Parent = detail,
        })
        Utils.corner(descBox, 10)
        Utils.padding(descBox, 12)
        Utils.new("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = s.Desc ~= "" and s.Desc or "Tidak ada deskripsi.",
            TextColor3 = CONFIG.Colors.SubText,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            Parent = descBox,
        })

        -- RUN
        local runBtn = Utils.new("TextButton", {
            Size = UDim2.new(1, -40, 0, 50),
            Position = UDim2.new(0, 20, 1, -66),
            BackgroundColor3 = color,
            Text = "▶   RUN SCRIPT",
            Font = Enum.Font.GothamBold,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 15,
            AutoButtonColor = false,
            Parent = detail,
        })
        Utils.corner(runBtn, 10)
        Utils.new("UIGradient", {
            Color = ColorSequence.new(
                color:Lerp(Color3.new(1,1,1), 0.15),
                color:Lerp(Color3.new(0,0,0), 0.25)
            ),
            Rotation = 15,
            Parent = runBtn,
        })

        runBtn.MouseEnter:Connect(function()
            Utils.tween(runBtn, { Size = UDim2.new(1, -34, 0, 54), Position = UDim2.new(0, 17, 1, -68) }, 0.15)
        end)
        runBtn.MouseLeave:Connect(function()
            Utils.tween(runBtn, { Size = UDim2.new(1, -40, 0, 50), Position = UDim2.new(0, 20, 1, -66) }, 0.15)
        end)

        runBtn.MouseButton1Click:Connect(function()
            runBtn.Text = "⏳  LOADING..."
            task.spawn(function()
                local ok, err = pcall(s.Callback, true, s)
                if ok then
                    Notify:Push("✅  " .. s.Name .. " berhasil dijalankan", color)
                    runBtn.Text = "✅   DONE"
                else
                    Notify:Push("❌  " .. s.Name .. " error: " .. tostring(err), CONFIG.Colors.Err)
                    runBtn.Text = "❌   GAGAL — Coba lagi"
                end
                task.wait(1.5)
                runBtn.Text = "▶   RUN SCRIPT"
            end)
        end)
    end

    local function openDetail(s, color)
        renderDetail(s, color)
        Utils.tween(detail, { Position = UDim2.new(0, 0, 0, 54) }, 0.35)
    end

    --========================= MAKE CARD =========================
    local function makeCard(s, index, color)
        local card = Utils.new("TextButton", {
            Size = UDim2.new(0, CARD_W, 0, CARD_H),
            BackgroundColor3 = CONFIG.Colors.Card,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = index,
            Parent = scroller,
        })
        Utils.corner(card, 12)
        Utils.stroke(card, CONFIG.Colors.Stroke, 1, 0.5)

        -- Thumbnail area
        local thumbHolder = Utils.new("Frame", {
            Size = UDim2.new(1, 0, 0, 140),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Parent = card,
        })
        Utils.corner(thumbHolder, 12)
        Utils.new("Frame", {
            Size = UDim2.new(1, 0, 0, 12),
            Position = UDim2.new(0, 0, 1, -12),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Parent = thumbHolder,
        })
        Utils.new("UIGradient", {
            Color = ColorSequence.new(color, color:Lerp(Color3.new(0,0,0), 0.5)),
            Rotation = 45,
            Parent = thumbHolder,
        })

        if isRobloxAsset(s.Thumbnail) then
            Utils.new("ImageLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Image = s.Thumbnail,
                ScaleType = Enum.ScaleType.Crop,
                Parent = thumbHolder,
            })
        else
            Utils.new("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = s.Icon,
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 56,
                Parent = thumbHolder,
            })
        end

        -- Nama
        Utils.new("TextLabel", {
            Size = UDim2.new(1, -20, 0, 22),
            Position = UDim2.new(0, 10, 0, 152),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = s.Name,
            TextColor3 = CONFIG.Colors.Text,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = card,
        })

        -- Badge
        local badge = Utils.new("Frame", {
            Size = UDim2.new(0, 84, 0, 18),
            Position = UDim2.new(0.5, 0, 0, 180),
            AnchorPoint = UDim2.new(0.5, 0, 0, 0),
            BackgroundColor3 = color,
            BackgroundTransparency = 0.85,
            Parent = card,
        })
        Utils.corner(badge, 9)
        Utils.new("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            Text = s.Category,
            TextColor3 = color,
            TextSize = 10,
            Parent = badge,
        })

        -- Desc
        Utils.new("TextLabel", {
            Size = UDim2.new(1, -24, 0, 56),
            Position = UDim2.new(0, 12, 0, 208),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = s.Desc,
            TextColor3 = CONFIG.Colors.SubText,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = card,
        })

        Utils.new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18),
            Position = UDim2.new(0, 0, 1, -26),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            Text = "Buka  →",
            TextColor3 = color,
            TextSize = 11,
            Parent = card,
        })

        card.MouseEnter:Connect(function()
            Utils.tween(card, {
                Size = UDim2.new(0, CARD_W + 6, 0, CARD_H + 6),
                Position = UDim2.new(0, -3, 0, -3),
                BackgroundColor3 = CONFIG.Colors.PanelAlt,
            }, 0.18)
        end)
        card.MouseLeave:Connect(function()
            Utils.tween(card, {
                Size = UDim2.new(0, CARD_W, 0, CARD_H),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = CONFIG.Colors.Card,
            }, 0.18)
        end)

        card.MouseButton1Click:Connect(function() openDetail(s, color) end)
    end

    --========================= POPULATE =========================
    local function populate(scripts)
        for _, c in ipairs(scroller:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for i, s in ipairs(scripts) do
            makeCard(s, i, pickColor(i))
        end
        scroller.CanvasSize = UDim2.new(0, #scripts * (CARD_W + CARD_GAP) + 20, 0, 0)
    end

    Hub.UI.Scroller = scroller
    Hub.UI.Populate = populate

    --========================= MINIMIZE SYSTEM =========================
    -- Simpan state
    local isMinimized = false
    local savedPos = nil

    -- Bubble kecil (muncul pas minimize)
    local bubble = Utils.new("TextButton", {
        Name = "MinimizedBubble",
        Size = UDim2.new(0, 56, 0, 56),
        Position = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = CONFIG.Colors.Panel,
        Text = "",
        AutoButtonColor = false,
        Visible = false,
        ZIndex = 150,
        Parent = parent,
    })
    Utils.corner(bubble, 28)
    Utils.stroke(bubble, CONFIG.Colors.Accent, 1.5, 0.3)

    -- Logo di bubble
    local bubbleLogoHolder = Utils.new("Frame", {
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
        Parent = bubble,
    })
    makeLogo(bubbleLogoHolder, 36, CONFIG.Colors.Accent)

    makeDraggable(bubble)

    local function setMinimized(state)
        if state == isMinimized then return end
        isMinimized = state

        if state then
            -- Simpan posisi terakhir
            savedPos = main.Position

            -- Animasi mengecil ke pojok kiri atas
            local targetPos = UDim2.new(0, 20, 0, 20)

            Utils.tween(main, {
                Size = UDim2.new(0, 56, 0, 56),
                Position = targetPos,
                BackgroundTransparency = 1,
            }, 0.28)

            -- Sembunyikan isi
            header.Visible = false
            scroller.Visible = false
            detail.Visible = false

            task.wait(0.28)
            if isMinimized then
                main.Visible = false
                bubble.Visible = true
                Utils.tween(bubble, { BackgroundTransparency = 0 }, 0.2)
            end
        else
            -- Restore
            bubble.Visible = false
            main.Visible = true
            main.BackgroundTransparency = 0

            -- Balikin ukuran
            Utils.tween(main, {
                Size = UDim2.new(0, mainW, 0, mainH),
                Position = savedPos or startPos,
            }, 0.32)

            task.wait(0.05)
            header.Visible = true
            scroller.Visible = true
            -- detail sengaja dibiarkan di posisi slide kanan
            detail.Position = UDim2.new(1, 0, 0, 54)
        end
    end

    -- Klik bubble → restore
    bubble.MouseButton1Click:Connect(function() setMinimized(false) end)

    -- Klik minimize button
    minBtn.MouseButton1Click:Connect(function() setMinimized(true) end)

    --========================= CLOSE =========================
    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        bubble.Visible = false
        Notify:Push("Hub disembunyikan. Tekan [" .. CONFIG.Keybind.Name .. "]", CONFIG.Colors.Accent)
    end)

    --========================= HOVER BUTTONS =========================
    local function hoverBind(btn, normalColor, hoverColor)
        btn.MouseEnter:Connect(function()
            Utils.tween(btn, { BackgroundColor3 = hoverColor }, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            Utils.tween(btn, { BackgroundColor3 = normalColor }, 0.15)
        end)
    end
    hoverBind(minBtn,     CONFIG.Colors.PanelAlt, CONFIG.Colors.AccentDark)
    hoverBind(refreshBtn, CONFIG.Colors.PanelAlt, CONFIG.Colors.AccentDark)
    hoverBind(closeBtn,   Color3.fromRGB(60, 30, 40), Color3.fromRGB(120, 40, 55))

    --========================= REFRESH =========================
    refreshBtn.MouseButton1Click:Connect(function()
        refreshBtn.Text = "⏳"
        refreshBtn.TextColor3 = CONFIG.Colors.Warn
        Notify:Push("⟳  Refresh daftar script...", CONFIG.Colors.Accent)

        task.spawn(function()
            local fetched = fetchJSON(CONFIG.ScriptsURL)
            if fetched then
                Hub:LoadScripts(fetched)
                populate(Hub.Scripts)
                Notify:Push("✅  " .. #Hub.Scripts .. " script ter-load", CONFIG.Colors.Ok)
            else
                Hub:LoadScripts(FALLBACK_SCRIPTS)
                populate(Hub.Scripts)
                Notify:Push("⚠️  Gagal fetch, pakai fallback", CONFIG.Colors.Warn)
            end
            refreshBtn.Text = "⟳"
            refreshBtn.TextColor3 = CONFIG.Colors.SubText
        end)
    end)

    --========================= INIT =========================
    Notify:Init(parent)
    populate(Hub.Scripts)

    -- Expose untuk keybind
    Hub.UI.SetMinimized = setMinimized
    Hub.UI.IsMinimized  = function() return isMinimized end
end

--=====================================================================
-- KEYBIND
--=====================================================================
local function hookKeybind()
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == CONFIG.Keybind then
            local main = Hub.UI.Main
            if not main then return end

            -- Kalau lagi minimized → restore
            if Hub.UI.IsMinimized and Hub.UI.IsMinimized() then
                Hub.UI.SetMinimized(false)
                return
            end

            -- Kalau hidden (close) → tampilkan
            if not main.Visible then
                main.Visible = true
                if Hub.UI.Detail then
                    Hub.UI.Detail.Position = UDim2.new(1, 0, 0, 54)
                end
                return
            end

            -- Kalau udah keliatan → minimize
            Hub.UI.SetMinimized(true)
        end
    end)
end

--=====================================================================
-- MAIN FLOW
--=====================================================================
task.spawn(function()
    Hub:LoadScripts(FALLBACK_SCRIPTS)
    buildUI()
    hookKeybind()

    -- Fetch JSON
    Notify:Push("🌐  Fetching script list...", CONFIG.Colors.Accent)
    local fetched = fetchJSON(CONFIG.ScriptsURL)
    if fetched then
        Hub:LoadScripts(fetched)
        if Hub.UI.Populate then Hub.UI.Populate(Hub.Scripts) end
        Notify:Push("✨  " .. #Hub.Scripts .. " script siap dipakai", CONFIG.Colors.Accent)
    else
        Notify:Push("⚠️  Gagal fetch JSON, pakai daftar default", CONFIG.Colors.Warn)
    end
end)
