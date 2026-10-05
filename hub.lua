--[[
    ███╗   ███╗██████╗     ██╗  ██╗███████╗███╗   ██╗ ██████╗
    ████╗ ████║██╔══██╗    ╚██╗██╔╝██╔════╝████╗  ██║██╔═══██╗
    ██╔████╔██║██████╔╝     ╚███╔╝ █████╗  ██╔██╗ ██║██║   ██║
    ██║╚██╔╝██║██╔══██╗     ██╔██╗ ██╔══╝  ██║╚██╗██║██║   ██║
    ██║ ╚═╝ ██║██║  ██║    ██╔╝ ██╗███████╗██║ ╚████║╚██████╔╝
    ╚═╝     ╚═╝╚═╝  ╚═╝    ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝
        H U B   S C R I P T   v3.0  (Thumbnail + JSON Live)
]]

--=====================================================================
-- ⚙️ KONFIGURASI UTAMA — GANTI URL INI KE PUNYAMU
--=====================================================================
local SCRIPTS_JSON_URL = "https://github.com/xanderzachky/mrxenohub.lua/blob/main/scripts.json"

-- Fallback (kalau JSON gagal di-fetch / offline)
local FALLBACK_SCRIPTS = {
    {
        name     = "John Doe",
        category = "Combat",
        icon     = "🔫",
        thumbnail= "",
        desc     = "Script John Doe",
        type     = "button",
        url      = "https://pastebin.com/raw/Q8dznf77",
    },
    {
        name     = "GluttonyKid",
        category = "Combat",
        icon     = "😈",
        thumbnail= "",
        desc     = "Script GluttonyKid",
        type     = "button",
        url      = "https://pastebin.com/raw/w3WFT9Vf",
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
-- CONFIG UI
--=====================================================================
local CONFIG = {
    Title     = "Mr.Xeno Hub",
    Version   = "v3.0",
    Keybind   = Enum.KeyCode.RightShift,
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
    }
}

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
-- FETCH + RESOLVE THUMBNAIL
--=====================================================================
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

-- Cek thumbnail: rbxassetid:// / rbxthumb:// valid, selain itu pakai emoji
local function isRobloxAsset(str)
    if type(str) ~= "string" or str == "" then return false end
    return str:match("^rbxassetid://") or str:match("^rbxthumb://")
        or str:match("^rbxasset://") or str:match("^http")
end

--=====================================================================
-- HUB API
--=====================================================================
local Hub = {}
Hub.Scripts = {}
Hub.UI      = {}

-- Normalisasi dari JSON → internal format
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
                if not ok then
                    return false, tostring(err)
                end
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
        ZIndex = 100,
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
        ZIndex = 100,
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
    local parent
    pcall(function()
        if CoreGui:FindFirstChild("MrXenoHubUI") then
            CoreGui.MrXenoHubUI:Destroy()
        end
        parent = Utils.new("ScreenGui", {
            Name = "MrXenoHubUI",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent = CoreGui,
        })
    end)
    if not parent then
        parent = Utils.new("ScreenGui", {
            Name = "MrXenoHubUI",
            ResetOnSpawn = false,
            Parent = LocalPlayer:WaitForChild("PlayerGui"),
        })
    end
    Hub.UI.ScreenGui = parent

    --========================= MAIN =========================
    local mainW = CARD_W * 3 + CARD_GAP * 2 + 60
    local main = Utils.new("Frame", {
        Name = "Main",
        Size = UDim2.new(0, mainW, 0, 440),
        Position = UDim2.new(0.5, -mainW/2, 0.5, -220),
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
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = CONFIG.Colors.Panel,
        BorderSizePixel = 0,
        Parent = main,
    })
    Utils.corner(header, 14)
    Utils.new("Frame", {
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 1, -14),
        BackgroundColor3 = CONFIG.Colors.Panel,
        BorderSizePixel = 0,
        Parent = header,
    })

    Utils.new("Frame", {
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 18, 0.5, 0),
        AnchorPoint = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = CONFIG.Colors.Accent,
        Parent = header,
    }):Let(function(d) Utils.corner(d, 5) end) -- fallback, ok kalau error

    Utils.new("TextLabel", {
        Size = UDim2.new(0, 250, 1, 0),
        Position = UDim2.new(0, 38, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = CONFIG.Title,
        TextColor3 = CONFIG.Colors.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })

    -- Refresh button
    local refreshBtn = Utils.new("TextButton", {
        Size = UDim2.new(0, 30, 0, 26),
        Position = UDim2.new(1, -108, 0.5, 0),
        AnchorPoint = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = CONFIG.Colors.PanelAlt,
        Text = "⟳",
        Font = Enum.Font.GothamBold,
        TextColor3 = CONFIG.Colors.SubText,
        TextSize = 16,
        AutoButtonColor = false,
        Parent = header,
    })
    Utils.corner(refreshBtn, 6)

    Utils.new("TextLabel", {
        Size = UDim2.new(0, 70, 1, 0),
        Position = UDim2.new(1, -74, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = CONFIG.Version,
        TextColor3 = CONFIG.Colors.SubText,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = header,
    })

    local closeBtn = Utils.new("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -36, 0.5, 0),
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
    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        Notify:Push("Hub disembunyikan. Tekan [" .. CONFIG.Keybind.Name .. "]", CONFIG.Colors.Accent)
    end)

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

        -- Hero image / gradient header
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

        -- Thumbnail image (kalau ada)
        if isRobloxAsset(s.Thumbnail) then
            local img = Utils.new("ImageLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Image = s.Thumbnail,
                ScaleType = Enum.ScaleType.Crop,
                Parent = hero,
            })
            -- overlay gelap biar tulisan keliatan
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
            -- fallback: emoji besar
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

        -- Back button overlay
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

        -- Badge kategori
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

        -- Desc panel
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

        -- RUN button
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
            Utils.tween(runBtn, {
                Size = UDim2.new(1, -34, 0, 54),
                Position = UDim2.new(0, 17, 1, -68),
            }, 0.15)
        end)
        runBtn.MouseLeave:Connect(function()
            Utils.tween(runBtn, {
                Size = UDim2.new(1, -40, 0, 50),
                Position = UDim2.new(0, 20, 1, -66),
            }, 0.15)
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

        -- Thumbnail top area (140px)
        local thumbHolder = Utils.new("Frame", {
            Size = UDim2.new(1, 0, 0, 140),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Parent = card,
        })
        Utils.corner(thumbHolder, 12)
        -- fill bawah biar cuma sudut atas yang rounded
        Utils.new("Frame", {
            Size = UDim2.new(1, 0, 0, 12),
            Position = UDim2.new(0, 0, 1, -12),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Parent = thumbHolder,
        })

        -- Gradient fallback (kalau thumbnail kosong)
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
            -- fallback: emoji besar
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

        -- Hover
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

        card.MouseButton1Click:Connect(function()
            openDetail(s, color)
        end)
    end

    --========================= POPULATE =========================
    local function populate(scripts)
        for _, c in ipairs(scroller:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for i, s in ipairs(scripts) do
            makeCard(s, i, pickColor(i))
        end
        scroller.CanvasSize = UDim2.new(0, #scripts * (CARD_W + CARD_GAP) + 10, 0, 0)
    end

    --========================= REFRESH BTN =========================
    refreshBtn.MouseButton1Click:Connect(function()
        refreshBtn.Text = "⏳"
        Notify:Push("⟳  Refresh daftar script...", CONFIG.Colors.Accent)
        task.spawn(function()
            local fetched = fetchJSON(SCRIPTS_JSON_URL)
            if fetched then
                Hub:LoadScripts(fetched)
                populate(Hub.Scripts)
                Notify:Push("✅  " .. #Hub.Scripts .. " script ter-load", CONFIG.Colors.Accent)
            else
                Hub:LoadScripts(FALLBACK_SCRIPTS)
                populate(Hub.Scripts)
                Notify:Push("⚠️  Gagal fetch, pakai fallback", Color3.fromRGB(255, 170, 60))
            end
            refreshBtn.Text = "⟳"
        end)
    end)
    refreshBtn.MouseEnter:Connect(function()
        Utils.tween(refreshBtn, { BackgroundColor3 = CONFIG.Colors.AccentDark })
    end)
    refreshBtn.MouseLeave:Connect(function()
        Utils.tween(refreshBtn, { BackgroundColor3 = CONFIG.Colors.PanelAlt })
    end)

    --========================= INIT LOAD =========================
    Hub.UI.Scroller = scroller
    Hub.UI.Populate = populate

    -- Notify holder DULU sebelum async
    Notify:Init(parent)

    populate(Hub.Scripts)
end

--=====================================================================
-- KEYBIND
--=====================================================================
local function hookKeybind()
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == CONFIG.Keybind then
            local main = Hub.UI.Main
            if main then
                main.Visible = not main.Visible
                if not main.Visible and Hub.UI.Detail then
                    Hub.UI.Detail.Position = UDim2.new(1, 0, 0, 54)
                end
            end
        end
    end)
end

--=====================================================================
-- MAIN FLOW
--=====================================================================
task.spawn(function()
    -- Load fallback dulu biar UI cepet muncul
    Hub:LoadScripts(FALLBACK_SCRIPTS)
    buildUI()
    hookKeybind()

    -- Baru fetch dari JSON
    Notify:Push("🌐  Fetching script list...", CONFIG.Colors.Accent)
    local fetched = fetchJSON(SCRIPTS_JSON_URL)
    if fetched then
        Hub:LoadScripts(fetched)
        if Hub.UI.Populate then Hub.UI.Populate(Hub.Scripts) end
        Notify:Push("✨  " .. #Hub.Scripts .. " script siap dipakai", CONFIG.Colors.Accent)
    else
        Notify:Push("⚠️  Gagal fetch JSON, pakai daftar default", Color3.fromRGB(255, 170, 60))
    end
end)
