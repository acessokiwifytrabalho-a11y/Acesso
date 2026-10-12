-- =========================================================
-- CONFIGURAÇÃO
-- =========================================================

local Settings = {
    Enabled = false,
    AutoShot = true,
    Triggerbot = false,
    FOV_Visible = true,

    ToggleKey = Enum.KeyCode.Q,
    HideFOVKey = Enum.KeyCode.L,
    AutoShotKey = Enum.KeyCode.Y,
    TriggerbotKey = Enum.KeyCode.Z,

    HitBoxes = {"Head", "HumanoidRootPart"},

    FOV_Radius = 50,
    Smoothing = 0,
    ClickSpeed = 0.001,

    Prediction = true,
    PredictionAmount = 0.12,

    -- ESP
    ESP = false,
    ESPKey = Enum.KeyCode.F3,

    ESP_Box = true,
    ESP_Name = true,
    ESP_Distance = true,
    ESP_Health = true,

    -- OTIMIZAÇÃO DO ESP
    ESP_OnlyArmed = true,
    ESP_MaxDistance = 180,
    ESP_UpdateInterval = 0.05,

    -- ARMA / INVENTÁRIO
    ESP_Inventory = false,
    InventoryKey = Enum.KeyCode.F4,
    InventoryUpdateInterval = 0.5
}


-- =========================================================
-- SERVIÇOS
-- =========================================================

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera


-- =========================================================
-- TARGET
-- =========================================================

local LockedTarget = nil
local LockedPlayer = nil

local LastTargetPosition = nil
local TargetVelocity = Vector3.new()


-- =========================================================
-- FOV
-- =========================================================

local FOVCircle = Drawing.new("Circle")

FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(150, 150, 150)
FOVCircle.Transparency = 0.7
FOVCircle.Visible = true


-- =========================================================
-- FPS
-- =========================================================

local CurrentFPS = 0
local FPSFrames = 0
local FPSLastUpdate = os.clock()

local function UpdateFPS()

    FPSFrames += 1

    local Now = os.clock()
    local Delta = Now - FPSLastUpdate

    if Delta >= 0.5 then

        CurrentFPS = math.floor(
            FPSFrames / Delta + 0.5
        )

        FPSFrames = 0
        FPSLastUpdate = Now
    end
end


-- =========================================================
-- HUB
-- =========================================================

local HUDVisible = true
local HUDKey = Enum.KeyCode.F1

local StreamMode = false
local StreamModeKey = Enum.KeyCode.F2


-- =========================================================
-- TAMANHO / REDIMENSIONAMENTO
-- =========================================================

local BASE_HUD_WIDTH = 310
local BASE_HUD_HEIGHT = 292
local BASE_HEADER_HEIGHT = 47

local HUDScale = 1

local MIN_HUD_SCALE = 0.65
local MAX_HUD_SCALE = 1.40

local HUDPosition = nil

local Dragging = false
local DragOffset = Vector2.new(0, 0)

local Resizing = false
local ResizeStartMouse = Vector2.new(0, 0)
local ResizeStartScale = 1


local function S(Value)
    return Value * HUDScale
end


local function HUDWidth()
    return S(BASE_HUD_WIDTH)
end


local function HUDHeight()
    return S(BASE_HUD_HEIGHT)
end


-- =========================================================
-- CORES
-- =========================================================

local COLORS = {

    Background = Color3.fromRGB(5, 8, 13),

    Inner = Color3.fromRGB(11, 16, 23),

    Row = Color3.fromRGB(16, 22, 30),

    Border = Color3.fromRGB(34, 48, 61),

    BorderBright = Color3.fromRGB(54, 77, 94),

    Accent = Color3.fromRGB(0, 220, 255),

    AccentDark = Color3.fromRGB(0, 88, 120),

    Text = Color3.fromRGB(236, 241, 245),

    SubText = Color3.fromRGB(108, 126, 143),

    On = Color3.fromRGB(67, 240, 142),

    Off = Color3.fromRGB(100, 112, 124),

    Shadow = Color3.fromRGB(0, 0, 0)
}


local HUD = {}
local HUDRows = {}

local TextSizes = {}
local CircleSizes = {}


-- =========================================================
-- DRAWING HELPERS
-- =========================================================

local function CreateSquare(
    Filled,
    Color,
    Transparency,
    Thickness
)

    local Object = Drawing.new("Square")

    Object.Filled = Filled
    Object.Color = Color
    Object.Transparency = Transparency or 1
    Object.Thickness = Thickness or 1
    Object.Visible = true

    return Object
end


local function CreateText(
    Text,
    Size,
    Color
)

    local Object = Drawing.new("Text")

    Object.Text = Text
    Object.Size = Size
    Object.Color = Color

    Object.Outline = true
    Object.Center = false
    Object.Visible = true

    TextSizes[Object] = Size

    return Object
end


local function CreateLine(
    Color,
    Transparency,
    Thickness
)

    local Object = Drawing.new("Line")

    Object.Color = Color
    Object.Transparency = Transparency or 1
    Object.Thickness = Thickness or 1
    Object.Visible = true

    return Object
end


local function CreateCircle(
    Color,
    Radius
)

    local Object = Drawing.new("Circle")

    Object.Color = Color
    Object.Radius = Radius
    Object.Filled = true
    Object.Transparency = 1
    Object.NumSides = 20
    Object.Visible = true

    CircleSizes[Object] = Radius

    return Object
end


local function UpdateHUDScale()

    for Object, BaseSize in pairs(TextSizes) do

        Object.Size = math.max(
            7,
            math.floor(
                BaseSize * HUDScale + 0.5
            )
        )
    end


    for Object, BaseRadius in pairs(CircleSizes) do

        Object.Radius = math.max(
            1,
            BaseRadius * HUDScale
        )
    end
end


-- =========================================================
-- BACKGROUND
-- =========================================================

HUD.ShadowFar = CreateSquare(
    true,
    COLORS.Shadow,
    0.10
)

HUD.Shadow = CreateSquare(
    true,
    COLORS.Shadow,
    0.28
)

HUD.Background = CreateSquare(
    true,
    COLORS.Background,
    0.97
)

HUD.Inner = CreateSquare(
    true,
    COLORS.Inner,
    0.38
)

HUD.Border = CreateSquare(
    false,
    COLORS.Border,
    1,
    1
)


-- =========================================================
-- DETALHES
-- =========================================================

HUD.Glow = CreateSquare(
    true,
    COLORS.AccentDark,
    0.25
)

HUD.TopBar = CreateSquare(
    true,
    COLORS.Accent,
    1
)

HUD.LeftBar = CreateSquare(
    true,
    COLORS.Accent,
    0.9
)

HUD.RightBar = CreateSquare(
    true,
    COLORS.Accent,
    0.9
)


HUD.ResizeBackground = CreateSquare(
    true,
    COLORS.AccentDark,
    0.40
)

HUD.ResizeLine1 = CreateLine(
    COLORS.Accent,
    1,
    1
)

HUD.ResizeLine2 = CreateLine(
    COLORS.Accent,
    0.75,
    1
)

HUD.ResizeLine3 = CreateLine(
    COLORS.Accent,
    0.45,
    1
)


-- =========================================================
-- HEADER
-- =========================================================

HUD.Prefix = CreateText(
    "//",
    13,
    COLORS.Accent
)

HUD.Title = CreateText(
    "COMBAT",
    15,
    COLORS.Text
)

HUD.Subtitle = CreateText(
    "TACTICAL SYSTEM",
    9,
    COLORS.SubText
)

HUD.Drag = CreateText(
    "MOVE",
    8,
    COLORS.SubText
)

HUD.Online = CreateText(
    "ONLINE",
    9,
    COLORS.On
)

HUD.OnlineDot = CreateCircle(
    COLORS.On,
    3
)

HUD.HeaderLine = CreateLine(
    COLORS.BorderBright,
    0.7,
    1
)


-- =========================================================
-- ROW
-- =========================================================

local function CreateRow(Key, Name)

    local Row = {}


    Row.Background = CreateSquare(
        true,
        COLORS.Row,
        0.40
    )


    Row.KeyBox = CreateSquare(
        true,
        COLORS.Inner,
        0.95
    )


    Row.KeyBorder = CreateSquare(
        false,
        COLORS.BorderBright,
        0.85,
        1
    )


    Row.KeyAccent = CreateSquare(
        true,
        COLORS.AccentDark,
        0.9
    )


    Row.Key = CreateText(
        Key,
        10,
        COLORS.Accent
    )


    Row.Name = CreateText(
        Name,
        11,
        COLORS.Text
    )


    Row.Dot = CreateCircle(
        COLORS.Off,
        2
    )


    Row.Status = CreateText(
        "OFF",
        10,
        COLORS.Off
    )


    table.insert(
        HUDRows,
        Row
    )


    return Row
end


HUD.Aimbot = CreateRow(
    "Q",
    "AIMBOT"
)

HUD.Triggerbot = CreateRow(
    "Z",
    "TRIGGERBOT"
)

HUD.AutoShot = CreateRow(
    "Y",
    "AUTO SHOT"
)

HUD.Prediction = CreateRow(
    "P",
    "PREDICTION"
)

HUD.FOVVisible = CreateRow(
    "L",
    "FOV CIRCLE"
)

HUD.FOVSize = CreateRow(
    "+/-",
    "FOV SIZE"
)

HUD.ESP = CreateRow(
    "F3",
    "ARMED ESP"
)

HUD.Inventory = CreateRow(
    "F4",
    "WEAPON INFO"
)

HUD.FPS = CreateRow(
    "--",
    "FPS"
)


-- =========================================================
-- FOOTER
-- =========================================================

HUD.FooterLine = CreateLine(
    COLORS.Border,
    0.9,
    1
)

HUD.Footer = CreateText(
    "[F1] HIDE   [F2] STREAM",
    9,
    COLORS.SubText
)

HUD.Version = CreateText(
    "SYS // 05",
    8,
    COLORS.AccentDark
)


-- =========================================================
-- STATUS
-- =========================================================

local function SetStatus(
    Row,
    Enabled
)

    if Enabled then

        Row.Status.Text = "ACTIVE"
        Row.Status.Color = COLORS.On
        Row.Dot.Color = COLORS.On

    else

        Row.Status.Text = "OFF"
        Row.Status.Color = COLORS.Off
        Row.Dot.Color = COLORS.Off
    end
end


-- =========================================================
-- VISIBILIDADE HUB
-- =========================================================

local function SetHUDVisible(Value)

    HUD.ShadowFar.Visible = Value
    HUD.Shadow.Visible = Value

    HUD.Background.Visible = Value
    HUD.Inner.Visible = Value
    HUD.Border.Visible = Value

    HUD.Glow.Visible = Value
    HUD.TopBar.Visible = Value

    HUD.LeftBar.Visible = Value
    HUD.RightBar.Visible = Value

    HUD.ResizeBackground.Visible = Value
    HUD.ResizeLine1.Visible = Value
    HUD.ResizeLine2.Visible = Value
    HUD.ResizeLine3.Visible = Value

    HUD.Prefix.Visible = Value
    HUD.Title.Visible = Value
    HUD.Subtitle.Visible = Value
    HUD.Drag.Visible = Value

    HUD.Online.Visible = Value
    HUD.OnlineDot.Visible = Value

    HUD.HeaderLine.Visible = Value

    HUD.FooterLine.Visible = Value
    HUD.Footer.Visible = Value
    HUD.Version.Visible = Value

    for _, Row in ipairs(HUDRows) do

        Row.Background.Visible = Value

        Row.KeyBox.Visible = Value
        Row.KeyBorder.Visible = Value
        Row.KeyAccent.Visible = Value

        Row.Key.Visible = Value
        Row.Name.Visible = Value

        Row.Dot.Visible = Value
        Row.Status.Visible = Value
    end
end


-- =========================================================
-- POSIÇÃO DAS LINHAS
-- =========================================================

local function PositionRow(
    Row,
    X,
    BaseY
)

    local Y =
        HUDPosition.Y
        + S(BaseY)


    local KeyWidth =
        S(38)

    local KeyHeight =
        S(17)


    Row.Background.Position =
        Vector2.new(
            X + S(11),
            Y - S(4)
        )


    Row.Background.Size =
        Vector2.new(
            HUDWidth() - S(22),
            S(21)
        )


    Row.KeyBox.Position =
        Vector2.new(
            X + S(17),
            Y - S(2)
        )


    Row.KeyBox.Size =
        Vector2.new(
            KeyWidth,
            KeyHeight
        )


    Row.KeyBorder.Position =
        Row.KeyBox.Position

    Row.KeyBorder.Size =
        Row.KeyBox.Size


    Row.KeyAccent.Position =
        Vector2.new(
            X + S(17),
            Y - S(2)
        )


    Row.KeyAccent.Size =
        Vector2.new(
            math.max(1, S(2)),
            KeyHeight
        )


    Row.Key.Center = true


    Row.Key.Position =
        Vector2.new(
            X
            + S(17)
            + KeyWidth / 2,

            Y
        )


    Row.Name.Position =
        Vector2.new(
            X + S(69),
            Y
        )


    Row.Dot.Position =
        Vector2.new(
            X
            + HUDWidth()
            - S(84),

            Y + S(6)
        )


    Row.Status.Position =
        Vector2.new(
            X
            + HUDWidth()
            - S(72),

            Y
        )
end


-- =========================================================
-- POSIÇÃO INICIAL
-- =========================================================

local function InitializeHUDPosition()

    if HUDPosition then
        return
    end


    local CurrentCamera =
        workspace.CurrentCamera


    if not CurrentCamera then
        return
    end


    local Viewport =
        CurrentCamera.ViewportSize


    HUDPosition =
        Vector2.new(

            math.floor(
                (
                    Viewport.X
                    - HUDWidth()
                )
                / 2
            ),

            22
        )
end


local function ClampHUD()

    if not HUDPosition then
        return
    end


    local CurrentCamera =
        workspace.CurrentCamera


    if not CurrentCamera then
        return
    end


    local Viewport =
        CurrentCamera.ViewportSize


    local MaxX =
        math.max(
            5,
            Viewport.X
            - HUDWidth()
            - 5
        )


    local MaxY =
        math.max(
            5,
            Viewport.Y
            - HUDHeight()
            - 5
        )


    HUDPosition =
        Vector2.new(

            math.clamp(
                HUDPosition.X,
                5,
                MaxX
            ),

            math.clamp(
                HUDPosition.Y,
                5,
                MaxY
            )
        )
end


-- =========================================================
-- UPDATE HUD
-- =========================================================

local function UpdateHUD()

    InitializeHUDPosition()

    if not HUDPosition then
        return
    end


    UpdateHUDScale()


    local X =
        HUDPosition.X

    local Y =
        HUDPosition.Y

    local Width =
        HUDWidth()

    local Height =
        HUDHeight()


    HUD.ShadowFar.Position =
        Vector2.new(
            X + S(8),
            Y + S(8)
        )

    HUD.ShadowFar.Size =
        Vector2.new(
            Width,
            Height
        )


    HUD.Shadow.Position =
        Vector2.new(
            X + S(4),
            Y + S(4)
        )

    HUD.Shadow.Size =
        Vector2.new(
            Width,
            Height
        )


    HUD.Background.Position =
        Vector2.new(
            X,
            Y
        )

    HUD.Background.Size =
        Vector2.new(
            Width,
            Height
        )


    HUD.Inner.Position =
        Vector2.new(
            X + S(4),
            Y + S(4)
        )

    HUD.Inner.Size =
        Vector2.new(
            Width - S(8),
            Height - S(8)
        )


    HUD.Border.Position =
        Vector2.new(
            X,
            Y
        )

    HUD.Border.Size =
        Vector2.new(
            Width,
            Height
        )


    HUD.Glow.Position =
        Vector2.new(
            X,
            Y
        )

    HUD.Glow.Size =
        Vector2.new(
            Width,
            S(6)
        )


    HUD.TopBar.Position =
        Vector2.new(
            X + S(22),
            Y
        )

    HUD.TopBar.Size =
        Vector2.new(
            Width - S(44),
            math.max(1, S(2))
        )


    HUD.LeftBar.Position =
        Vector2.new(
            X,
            Y + S(10)
        )

    HUD.LeftBar.Size =
        Vector2.new(
            math.max(1, S(2)),
            S(23)
        )


    HUD.RightBar.Position =
        Vector2.new(
            X + Width - S(2),
            Y + S(10)
        )

    HUD.RightBar.Size =
        Vector2.new(
            math.max(1, S(2)),
            S(23)
        )


    HUD.Prefix.Position =
        Vector2.new(
            X + S(15),
            Y + S(10)
        )


    HUD.Title.Position =
        Vector2.new(
            X + S(36),
            Y + S(9)
        )


    HUD.Subtitle.Position =
        Vector2.new(
            X + S(37),
            Y + S(27)
        )


    HUD.Drag.Position =
        Vector2.new(
            X + S(147),
            Y + S(28)
        )


    HUD.OnlineDot.Position =
        Vector2.new(
            X
            + Width
            - S(67),

            Y + S(18)
        )


    HUD.Online.Position =
        Vector2.new(
            X
            + Width
            - S(57),

            Y + S(12)
        )


    HUD.HeaderLine.From =
        Vector2.new(
            X + S(12),
            Y + S(44)
        )


    HUD.HeaderLine.To =
        Vector2.new(
            X
            + Width
            - S(12),

            Y + S(44)
        )


    PositionRow(
        HUD.Aimbot,
        X,
        56
    )

    PositionRow(
        HUD.Triggerbot,
        X,
        79
    )

    PositionRow(
        HUD.AutoShot,
        X,
        102
    )

    PositionRow(
        HUD.Prediction,
        X,
        125
    )

    PositionRow(
        HUD.FOVVisible,
        X,
        148
    )

    PositionRow(
        HUD.FOVSize,
        X,
        171
    )

    PositionRow(
        HUD.ESP,
        X,
        194
    )

    PositionRow(
        HUD.Inventory,
        X,
        217
    )

    PositionRow(
        HUD.FPS,
        X,
        240
    )


    SetStatus(
        HUD.Aimbot,
        Settings.Enabled
    )


    SetStatus(
        HUD.Triggerbot,
        Settings.Triggerbot
    )


    SetStatus(
        HUD.AutoShot,
        Settings.AutoShot
    )


    SetStatus(
        HUD.Prediction,
        Settings.Prediction
    )


    SetStatus(
        HUD.FOVVisible,
        Settings.FOV_Visible
    )


    SetStatus(
        HUD.ESP,
        Settings.ESP
    )


    SetStatus(
        HUD.Inventory,
        Settings.ESP_Inventory
    )


    HUD.FOVSize.Status.Text =
        tostring(
            Settings.FOV_Radius
        )

    HUD.FOVSize.Status.Color =
        COLORS.Accent

    HUD.FOVSize.Dot.Color =
        COLORS.Accent


    HUD.FPS.Status.Text =
        tostring(
            CurrentFPS
        )

    HUD.FPS.Status.Color =
        COLORS.Accent

    HUD.FPS.Dot.Color =
        COLORS.Accent


    HUD.FooterLine.From =
        Vector2.new(
            X + S(12),
            Y + S(264)
        )


    HUD.FooterLine.To =
        Vector2.new(
            X
            + Width
            - S(12),

            Y + S(264)
        )


    HUD.Footer.Position =
        Vector2.new(
            X + S(15),
            Y + S(271)
        )


    HUD.Version.Position =
        Vector2.new(
            X
            + Width
            - S(58),

            Y + S(272)
        )


    -- RESIZE HANDLE

    local HandleSize =
        S(18)


    HUD.ResizeBackground.Position =
        Vector2.new(
            X
            + Width
            - HandleSize,

            Y
            + Height
            - HandleSize
        )


    HUD.ResizeBackground.Size =
        Vector2.new(
            HandleSize,
            HandleSize
        )


    HUD.ResizeLine1.From =
        Vector2.new(
            X + Width - S(3),
            Y + Height - S(13)
        )


    HUD.ResizeLine1.To =
        Vector2.new(
            X + Width - S(13),
            Y + Height - S(3)
        )


    HUD.ResizeLine2.From =
        Vector2.new(
            X + Width - S(3),
            Y + Height - S(9)
        )


    HUD.ResizeLine2.To =
        Vector2.new(
            X + Width - S(9),
            Y + Height - S(3)
        )


    HUD.ResizeLine3.From =
        Vector2.new(
            X + Width - S(3),
            Y + Height - S(5)
        )


    HUD.ResizeLine3.To =
        Vector2.new(
            X + Width - S(5),
            Y + Height - S(3)
        )


    SetHUDVisible(
        HUDVisible
        and not StreamMode
    )
end


-- =========================================================
-- MOUSE DO HUB
-- =========================================================

local function MouseInsideHeader(
    MousePosition
)

    if not HUDVisible
        or StreamMode
        or not HUDPosition
    then

        return false
    end


    return

        MousePosition.X >= HUDPosition.X

        and MousePosition.X <=
        HUDPosition.X + HUDWidth()

        and MousePosition.Y >= HUDPosition.Y

        and MousePosition.Y <=
        HUDPosition.Y
        + S(BASE_HEADER_HEIGHT)
end


local function MouseInsideResize(
    MousePosition
)

    if not HUDVisible
        or StreamMode
        or not HUDPosition
    then

        return false
    end


    local Handle = S(24)

    local Right =
        HUDPosition.X
        + HUDWidth()

    local Bottom =
        HUDPosition.Y
        + HUDHeight()


    return

        MousePosition.X >=
        Right - Handle

        and MousePosition.X <=
        Right + 4

        and MousePosition.Y >=
        Bottom - Handle

        and MousePosition.Y <=
        Bottom + 4
end


UIS.InputBegan:Connect(function(
    input,
    processed
)

    if processed then
        return
    end


    if input.UserInputType ==
        Enum.UserInputType.MouseButton1
    then

        InitializeHUDPosition()


        local MousePosition =
            UIS:GetMouseLocation()


        if MouseInsideResize(
            MousePosition
        ) then

            Resizing = true
            Dragging = false

            ResizeStartMouse =
                MousePosition

            ResizeStartScale =
                HUDScale

            return
        end


        if MouseInsideHeader(
            MousePosition
        ) then

            Dragging = true
            Resizing = false

            DragOffset =
                MousePosition
                - HUDPosition
        end
    end
end)


UIS.InputChanged:Connect(function(
    input
)

    if input.UserInputType ~=
        Enum.UserInputType.MouseMovement
    then

        return
    end


    local MousePosition =
        UIS:GetMouseLocation()


    if Resizing then

        local DeltaX =
            MousePosition.X
            - ResizeStartMouse.X


        local NewWidth =
            (
                BASE_HUD_WIDTH
                * ResizeStartScale
            )
            + DeltaX


        HUDScale =
            math.clamp(
                NewWidth
                / BASE_HUD_WIDTH,

                MIN_HUD_SCALE,
                MAX_HUD_SCALE
            )


        ClampHUD()

        return
    end


    if Dragging then

        local CurrentCamera =
            workspace.CurrentCamera


        if not CurrentCamera then
            return
        end


        local Viewport =
            CurrentCamera.ViewportSize


        local NewX =
            MousePosition.X
            - DragOffset.X


        local NewY =
            MousePosition.Y
            - DragOffset.Y


        local MaxX =
            math.max(
                5,
                Viewport.X
                - HUDWidth()
                - 5
            )


        local MaxY =
            math.max(
                5,
                Viewport.Y
                - HUDHeight()
                - 5
            )


        NewX =
            math.clamp(
                NewX,
                5,
                MaxX
            )


        NewY =
            math.clamp(
                NewY,
                5,
                MaxY
            )


        HUDPosition =
            Vector2.new(
                math.floor(NewX),
                math.floor(NewY)
            )
    end
end)


UIS.InputEnded:Connect(function(
    input
)

    if input.UserInputType ==
        Enum.UserInputType.MouseButton1
    then

        Dragging = false
        Resizing = false
    end
end)


-- =========================================================
-- ESP OTIMIZADO
-- =========================================================

local ESPObjects = {}


local function CreateESP(Player)

    if Player == LocalPlayer then
        return
    end


    local ESP = {}

    ESP.Dead = false

    ESP.DeathConnection = nil
    ESP.CharacterConnection = nil
    ESP.CharacterRemovingConnection = nil

    ESP.LastInventoryUpdate = 0
    ESP.InventoryText = ""


    ESP.Box =
        Drawing.new("Square")

    ESP.Box.Filled = false
    ESP.Box.Thickness = 1
    ESP.Box.Color = COLORS.Accent
    ESP.Box.Transparency = 1
    ESP.Box.Visible = false


    ESP.Name =
        Drawing.new("Text")

    ESP.Name.Center = true
    ESP.Name.Outline = true
    ESP.Name.Size = 12
    ESP.Name.Color = COLORS.Text
    ESP.Name.Visible = false


    ESP.Distance =
        Drawing.new("Text")

    ESP.Distance.Center = true
    ESP.Distance.Outline = true
    ESP.Distance.Size = 10
    ESP.Distance.Color = COLORS.SubText
    ESP.Distance.Visible = false


    ESP.Inventory =
        Drawing.new("Text")

    ESP.Inventory.Center = true
    ESP.Inventory.Outline = true
    ESP.Inventory.Size = 10
    ESP.Inventory.Color = COLORS.Accent
    ESP.Inventory.Visible = false


    ESP.HealthBackground =
        Drawing.new("Square")

    ESP.HealthBackground.Filled = true

    ESP.HealthBackground.Color =
        Color3.fromRGB(
            0,
            0,
            0
        )

    ESP.HealthBackground.Transparency =
        0.65

    ESP.HealthBackground.Visible =
        false


    ESP.Health =
        Drawing.new("Square")

    ESP.Health.Filled = true
    ESP.Health.Transparency = 1
    ESP.Health.Visible = false


    ESPObjects[Player] = ESP

    return ESP
end


local function HideESP(ESP)

    if not ESP then
        return
    end


    ESP.Box.Visible = false

    ESP.Name.Visible = false
    ESP.Distance.Visible = false
    ESP.Inventory.Visible = false

    ESP.Health.Visible = false
    ESP.HealthBackground.Visible = false
end


-- =========================================================
-- DETECTA ARMA EQUIPADA
-- =========================================================

local function GetEquippedWeapon(
    Character
)

    if not Character then
        return nil
    end


    for _, Object in ipairs(
        Character:GetChildren()
    ) do

        if Object:IsA("Tool") then
            return Object
        end
    end


    return nil
end


-- =========================================================
-- INVENTÁRIO
-- =========================================================

local function InventoryToText(
    Player,
    EquippedWeapon
)

    local Text =
        "Weapon: "
        .. (
            EquippedWeapon
            and EquippedWeapon.Name
            or "None"
        )


    local Backpack =
        Player:
        FindFirstChildOfClass(
            "Backpack"
        )


    if not Backpack then
        return Text
    end


    local Items = {}


    for _, Object in ipairs(
        Backpack:GetChildren()
    ) do

        if Object:IsA("Tool") then

            table.insert(
                Items,
                Object.Name
            )
        end
    end


    if #Items > 0 then

        local Display = {}

        local MaxItems =
            math.min(
                #Items,
                3
            )


        for i = 1, MaxItems do

            Display[#Display + 1] =
                Items[i]
        end


        Text =
            Text
            .. " | "
            .. table.concat(
                Display,
                ", "
            )


        if #Items > 3 then

            Text =
                Text
                .. " +"
                .. tostring(
                    #Items - 3
                )
        end
    end


    return Text
end


-- =========================================================
-- MORTE / RESPAWN
-- =========================================================

local function BindCharacter(
    Player,
    Character
)

    local ESP =
        ESPObjects[Player]


    if not ESP then
        return
    end


    ESP.Dead = false


    if ESP.DeathConnection then

        ESP.DeathConnection:
            Disconnect()

        ESP.DeathConnection = nil
    end


    task.spawn(function()

        local Humanoid =
            Character:
            WaitForChild(
                "Humanoid",
                5
            )


        if not Humanoid then
            return
        end


        ESP.Dead =
            Humanoid.Health <= 0


        ESP.DeathConnection =
            Humanoid.Died:
            Connect(function()

                ESP.Dead = true

                HideESP(
                    ESP
                )
            end)
    end)
end


local function WatchPlayer(Player)

    local ESP =
        ESPObjects[Player]


    if not ESP then
        return
    end


    if Player.Character then

        BindCharacter(
            Player,
            Player.Character
        )
    end


    ESP.CharacterConnection =
        Player.CharacterAdded:
        Connect(function(Character)

            ESP.Dead = false

            HideESP(
                ESP
            )

            BindCharacter(
                Player,
                Character
            )
        end)


    ESP.CharacterRemovingConnection =
        Player.CharacterRemoving:
        Connect(function()

            ESP.Dead = true

            HideESP(
                ESP
            )
        end)
end


local function RemoveESP(Player)

    local ESP =
        ESPObjects[Player]


    if not ESP then
        return
    end


    if ESP.DeathConnection then
        ESP.DeathConnection:Disconnect()
    end


    if ESP.CharacterConnection then
        ESP.CharacterConnection:Disconnect()
    end


    if ESP.CharacterRemovingConnection then

        ESP.CharacterRemovingConnection:
            Disconnect()
    end


    pcall(function()
        ESP.Box:Remove()
    end)

    pcall(function()
        ESP.Name:Remove()
    end)

    pcall(function()
        ESP.Distance:Remove()
    end)

    pcall(function()
        ESP.Inventory:Remove()
    end)

    pcall(function()
        ESP.Health:Remove()
    end)

    pcall(function()
        ESP.HealthBackground:Remove()
    end)


    ESPObjects[Player] = nil
end


for _, Player in ipairs(
    Players:GetPlayers()
) do

    if Player ~= LocalPlayer then

        CreateESP(Player)
        WatchPlayer(Player)
    end
end


Players.PlayerAdded:Connect(function(Player)

    CreateESP(Player)
    WatchPlayer(Player)
end)


Players.PlayerRemoving:Connect(function(Player)

    RemoveESP(Player)
end)


-- =========================================================
-- UPDATE ESP OTIMIZADO
-- =========================================================

local function UpdateESP()

    if not Settings.ESP
        or StreamMode
    then

        for _, ESP in pairs(
            ESPObjects
        ) do

            HideESP(ESP)
        end

        return
    end


    local CurrentCamera =
        workspace.CurrentCamera


    if not CurrentCamera then
        return
    end


    local MyCharacter =
        LocalPlayer.Character


    local MyRoot =
        MyCharacter
        and MyCharacter:
        FindFirstChild(
            "HumanoidRootPart"
        )


    if not MyRoot then

        for _, ESP in pairs(
            ESPObjects
        ) do

            HideESP(ESP)
        end

        return
    end


    local Now =
        os.clock()


    for Player, ESP in pairs(
        ESPObjects
    ) do


        -- MORTO

        if ESP.Dead then

            HideESP(ESP)

            continue
        end


        local Character =
            Player.Character


        if not Character then

            HideESP(ESP)

            continue
        end


        local Humanoid =
            Character:
            FindFirstChildOfClass(
                "Humanoid"
            )


        local Root =
            Character:
            FindFirstChild(
                "HumanoidRootPart"
            )


        local Head =
            Character:
            FindFirstChild(
                "Head"
            )


        if not Humanoid
            or Humanoid.Health <= 0
            or not Root
            or not Head
        then

            ESP.Dead = true

            HideESP(ESP)

            continue
        end


        -- =================================================
        -- PRIMEIRO: DISTÂNCIA
        -- =================================================

        local Distance =
            (
                MyRoot.Position
                - Root.Position
            ).Magnitude


        if Distance >
            Settings.ESP_MaxDistance
        then

            HideESP(ESP)

            continue
        end


        -- =================================================
        -- SEGUNDO: TEM ARMA EQUIPADA?
        -- =================================================

        local Weapon =
            GetEquippedWeapon(
                Character
            )


        if Settings.ESP_OnlyArmed
            and not Weapon
        then

            HideESP(ESP)

            continue
        end


        -- =================================================
        -- SÓ AGORA FAZ CONVERSÃO PARA TELA
        -- =================================================

        local HeadScreen,
        HeadVisible =

            CurrentCamera:
            WorldToViewportPoint(

                Head.Position
                + Vector3.new(
                    0,
                    0.65,
                    0
                )
            )


        if not HeadVisible
            or HeadScreen.Z <= 0
        then

            HideESP(ESP)

            continue
        end


        local FeetScreen,
        FeetVisible =

            CurrentCamera:
            WorldToViewportPoint(

                Root.Position
                - Vector3.new(
                    0,
                    3.25,
                    0
                )
            )


        if not FeetVisible then

            HideESP(ESP)

            continue
        end


        local Height =
            math.abs(
                FeetScreen.Y
                - HeadScreen.Y
            )


        if Height < 5 then

            HideESP(ESP)

            continue
        end


        local Width =
            Height * 0.53


        local X =
            HeadScreen.X
            - Width / 2


        local Y =
            HeadScreen.Y


        -- BOX

        ESP.Box.Position =
            Vector2.new(
                X,
                Y
            )


        ESP.Box.Size =
            Vector2.new(
                Width,
                Height
            )


        ESP.Box.Visible =
            Settings.ESP_Box


        -- NOME

        ESP.Name.Text =
            Player.Name


        ESP.Name.Position =
            Vector2.new(
                HeadScreen.X,
                Y - 16
            )


        ESP.Name.Visible =
            Settings.ESP_Name


        -- DISTÂNCIA

        ESP.Distance.Text =
            tostring(
                math.floor(
                    Distance
                )
            )
            .. " studs"


        ESP.Distance.Position =
            Vector2.new(
                HeadScreen.X,
                Y + Height + 3
            )


        ESP.Distance.Visible =
            Settings.ESP_Distance


        -- =================================================
        -- INVENTÁRIO COM CACHE
        -- =================================================

        if Settings.ESP_Inventory then

            if
                Now
                - ESP.LastInventoryUpdate
                >= Settings.InventoryUpdateInterval
            then

                ESP.InventoryText =
                    InventoryToText(
                        Player,
                        Weapon
                    )


                ESP.LastInventoryUpdate =
                    Now
            end


            ESP.Inventory.Text =
                ESP.InventoryText


            ESP.Inventory.Position =
                Vector2.new(
                    HeadScreen.X,
                    Y + Height + 16
                )


            ESP.Inventory.Visible =
                true

        else

            ESP.Inventory.Visible =
                false
        end


        -- HEALTH

        local HealthPercent =
            math.clamp(

                Humanoid.Health
                / math.max(
                    Humanoid.MaxHealth,
                    1
                ),

                0,
                1
            )


        local HealthHeight =
            Height
            * HealthPercent


        ESP.HealthBackground.Position =
            Vector2.new(
                X - 7,
                Y
            )


        ESP.HealthBackground.Size =
            Vector2.new(
                3,
                Height
            )


        ESP.Health.Position =
            Vector2.new(
                X - 7,

                Y
                + Height
                - HealthHeight
            )


        ESP.Health.Size =
            Vector2.new(
                3,
                HealthHeight
            )


        ESP.Health.Color =
            Color3.fromRGB(

                math.floor(
                    255
                    * (
                        1
                        - HealthPercent
                    )
                ),

                math.floor(
                    255
                    * HealthPercent
                ),

                70
            )


        ESP.HealthBackground.Visible =
            Settings.ESP_Health


        ESP.Health.Visible =
            Settings.ESP_Health
    end
end


-- =========================================================
-- VISIBILIDADE
-- =========================================================

local function CanSeeEnemy(TargetPart)

    if not TargetPart
        or not TargetPart.Parent
    then

        return false
    end


    local OriginPos =
        Camera.CFrame.Position


    local TargetPos =
        TargetPart.Position


    local Direction =
        TargetPos
        - OriginPos


    local Distance =
        Direction.Magnitude


    if Distance > 500 then
        return false
    end


    Direction =
        Direction.Unit


    local RayParams =
        RaycastParams.new()


    RayParams.FilterType =
        Enum.RaycastFilterType.Exclude


    local IgnoreList = {}


    if LocalPlayer.Character then

        table.insert(
            IgnoreList,
            LocalPlayer.Character
        )


        local Weapon =
            LocalPlayer.Character:
            FindFirstChildOfClass(
                "Tool"
            )


        if Weapon then

            table.insert(
                IgnoreList,
                Weapon
            )
        end
    end


    if TargetPart.Parent then

        table.insert(
            IgnoreList,
            TargetPart.Parent
        )
    end


    RayParams.FilterDescendantsInstances =
        IgnoreList


    local Result =
        workspace:Raycast(

            OriginPos,

            Direction
            * Distance,

            RayParams
        )


    if not Result then
        return true
    end


    if Result.Instance
        and Result.Instance:
        IsDescendantOf(
            TargetPart.Parent
        )
    then

        return true
    end


    return false
end


local function CanEnemySeeYou(
    EnemyCharacter
)

    if not EnemyCharacter then
        return false
    end


    if not LocalPlayer.Character then
        return false
    end


    local EnemyHead =
        EnemyCharacter:
        FindFirstChild(
            "Head"
        )


    if not EnemyHead then
        return false
    end


    local MyPart =
        LocalPlayer.Character:
        FindFirstChild(
            "Head"
        )


    if not MyPart then

        MyPart =
            LocalPlayer.Character:
            FindFirstChild(
                "HumanoidRootPart"
            )
    end


    if not MyPart then
        return false
    end


    local OriginPos =
        EnemyHead.Position


    local TargetPos =
        MyPart.Position


    local Direction =
        TargetPos
        - OriginPos


    local Distance =
        Direction.Magnitude


    if Distance > 500 then
        return false
    end


    Direction =
        Direction.Unit


    local RayParams =
        RaycastParams.new()


    RayParams.FilterType =
        Enum.RaycastFilterType.Exclude


    RayParams.FilterDescendantsInstances = {
        EnemyCharacter,
        LocalPlayer.Character
    }


    local Result =
        workspace:Raycast(

            OriginPos,

            Direction
            * Distance,

            RayParams
        )


    if not Result then
        return true
    end


    if Result.Instance
        and Result.Instance:
        IsDescendantOf(
            LocalPlayer.Character
        )
    then

        return true
    end


    return false
end


local function CanShoot(
    TargetPart
)

    if not TargetPart then
        return false
    end


    local EnemyCharacter =
        TargetPart.Parent


    if not EnemyCharacter then
        return false
    end


    local Hum =
        EnemyCharacter:
        FindFirstChildOfClass(
            "Humanoid"
        )


    if not Hum
        or Hum.Health <= 0
    then

        return false
    end


    if not CanSeeEnemy(
        TargetPart
    ) then

        return false
    end


    if not CanEnemySeeYou(
        EnemyCharacter
    ) then

        return false
    end


    return true
end


-- =========================================================
-- TRIGGERBOT
-- =========================================================

local function IsMouseOverEnemy()

    local MousePos =
        UIS:GetMouseLocation()


    local UnitRay =
        Camera:
        ViewportPointToRay(
            MousePos.X,
            MousePos.Y
        )


    local RayParamsObj =
        RaycastParams.new()


    RayParamsObj.FilterType =
        Enum.RaycastFilterType.Exclude


    if LocalPlayer.Character then

        RayParamsObj.FilterDescendantsInstances = {
            LocalPlayer.Character
        }
    end


    local Result =
        workspace:Raycast(

            UnitRay.Origin,

            UnitRay.Direction
            * 2000,

            RayParamsObj
        )


    if Result
        and Result.Instance
    then

        local HitPart =
            Result.Instance


        local Character =
            HitPart:
            FindFirstAncestorOfClass(
                "Model"
            )


        if Character then

            local Player =
                Players:
                GetPlayerFromCharacter(
                    Character
                )


            if Player
                and Player ~= LocalPlayer
            then

                local Hum =
                    Character:
                    FindFirstChildOfClass(
                        "Humanoid"
                    )


                if Hum
                    and Hum.Health > 0
                then

                    return CanShoot(
                        HitPart
                    )
                end
            end
        end
    end


    return false
end


-- =========================================================
-- TARGET
-- =========================================================

local function GetTarget()

    if LockedPlayer then

        if not LockedPlayer.Character then
            return nil
        end


        local Character =
            LockedPlayer.Character


        local Hum =
            Character:
            FindFirstChildOfClass(
                "Humanoid"
            )


        if not Hum
            or Hum.Health <= 0
        then

            LockedPlayer = nil
            LockedTarget = nil

            Settings.Enabled = false


            FOVCircle.Color =
                Color3.fromRGB(
                    150,
                    150,
                    150
                )


            return nil
        end


        local TargetPart = nil


        for _, HitBox in ipairs(
            Settings.HitBoxes
        ) do

            local Part =
                Character:
                FindFirstChild(
                    HitBox
                )


            if Part
                and CanShoot(
                    Part
                )
            then

                TargetPart = Part

                break
            end
        end


        if not TargetPart then
            return nil
        end


        LockedTarget =
            TargetPart


        if CanShoot(
            TargetPart
        ) then

            local TargetPos =
                TargetPart.Position


            if Settings.Prediction
                and TargetVelocity.Magnitude > 0.5
            then

                TargetPos =
                    TargetPos
                    + (
                        TargetVelocity
                        * Settings.PredictionAmount
                    )
            end


            local ScreenPos,
            OnScreen =

                Camera:
                WorldToViewportPoint(
                    TargetPos
                )


            if OnScreen then
                return ScreenPos
            end
        end


        return nil
    end


    local MaxDist =
        Settings.FOV_Radius


    local BestPos = nil

    local MousePos =
        UIS:GetMouseLocation()

    local BestPlayer = nil
    local BestPart = nil


    for _, Player in pairs(
        Players:GetPlayers()
    ) do

        if Player ~= LocalPlayer
            and Player.Character
        then

            local Hum =
                Player.Character:
                FindFirstChildOfClass(
                    "Humanoid"
                )


            if Hum
                and Hum.Health > 0
            then

                local BestPartForPlayer =
                    nil

                local BestScreenPos =
                    nil

                local BestDistance =
                    math.huge


                for _, HitBox in ipairs(
                    Settings.HitBoxes
                ) do

                    local Part =
                        Player.Character:
                        FindFirstChild(
                            HitBox
                        )


                    if Part
                        and CanShoot(
                            Part
                        )
                    then

                        local ScreenPos,
                        OnScreen =

                            Camera:
                            WorldToViewportPoint(
                                Part.Position
                            )


                        if OnScreen then

                            local Distance =

                                (
                                    Vector2.new(
                                        ScreenPos.X,
                                        ScreenPos.Y
                                    )
                                    - MousePos
                                ).Magnitude


                            if Distance <
                                BestDistance
                            then

                                BestDistance =
                                    Distance

                                BestPartForPlayer =
                                    Part

                                BestScreenPos =
                                    ScreenPos
                            end
                        end
                    end
                end


                if BestPartForPlayer
                    and BestDistance < MaxDist
                then

                    BestPos =
                        BestScreenPos

                    BestPlayer =
                        Player

                    BestPart =
                        BestPartForPlayer

                    MaxDist =
                        BestDistance
                end
            end
        end
    end


    if BestPlayer then

        LockedPlayer =
            BestPlayer

        LockedTarget =
            BestPart

        return BestPos
    end


    return nil
end


-- =========================================================
-- AIM
-- =========================================================

local function MoveMouseToTarget(
    TargetPos
)

    local MousePos =
        UIS:GetMouseLocation()


    local MoveX =
        TargetPos.X
        - MousePos.X


    local MoveY =
        TargetPos.Y
        - MousePos.Y


    if mousemoverel then

        mousemoverel(
            MoveX,
            MoveY
        )
    end
end


-- =========================================================
-- LOOP PRINCIPAL
-- =========================================================

local ESPAccumulator = 0


RunService.RenderStepped:Connect(function(
    DeltaTime
)

    UpdateFPS()

    UpdateHUD()


    -- =====================================================
    -- ESP NÃO ATUALIZA MAIS TODO FRAME
    -- =====================================================

    ESPAccumulator += DeltaTime


    if ESPAccumulator >=
        Settings.ESP_UpdateInterval
    then

        ESPAccumulator = 0

        UpdateESP()
    end


    local MousePos =
        UIS:GetMouseLocation()


    FOVCircle.Visible =
        Settings.FOV_Visible
        and not StreamMode


    FOVCircle.Position =
        MousePos


    FOVCircle.Radius =
        Settings.FOV_Radius


    if Settings.Enabled then

        local TargetPos =
            GetTarget()


        if TargetPos then

            if LockedTarget
                and LastTargetPosition
            then

                local CurrentPos =
                    LockedTarget.Position


                TargetVelocity =

                    (
                        CurrentPos
                        - LastTargetPosition
                    )
                    / 0.1
            end


            if LockedTarget then

                LastTargetPosition =
                    LockedTarget.Position
            end


            MoveMouseToTarget(
                TargetPos
            )
        end

    else

        LockedTarget = nil
        LockedPlayer = nil

        LastTargetPosition = nil

        TargetVelocity =
            Vector3.new()
    end
end)


-- =========================================================
-- AUTO SHOT
-- =========================================================

task.spawn(function()

    while true do

        local AutoShotActive =
            false


        if Settings.Enabled
            and Settings.AutoShot
            and LockedTarget
        then

            if CanShoot(
                LockedTarget
            ) then

                AutoShotActive =
                    true
            end
        end


        local TriggerbotActive =

            Settings.Triggerbot
            and IsMouseOverEnemy()


        if AutoShotActive
            or TriggerbotActive
        then

            if mouse1click then
                mouse1click()
            end
        end


        task.wait(
            Settings.ClickSpeed
        )
    end
end)


-- =========================================================
-- TECLAS
-- =========================================================

UIS.InputBegan:Connect(function(
    input,
    proc
)

    -- F1

    if input.KeyCode ==
        HUDKey
    then

        HUDVisible =
            not HUDVisible

        Dragging = false
        Resizing = false

        return
    end


    -- F2

    if input.KeyCode ==
        StreamModeKey
    then

        StreamMode =
            not StreamMode

        Dragging = false
        Resizing = false

        return
    end


    -- F3

    if input.KeyCode ==
        Settings.ESPKey
    then

        Settings.ESP =
            not Settings.ESP


        if not Settings.ESP then

            for _, ESP in pairs(
                ESPObjects
            ) do

                HideESP(ESP)
            end
        end

        return
    end


    -- F4

    if input.KeyCode ==
        Settings.InventoryKey
    then

        Settings.ESP_Inventory =
            not Settings.ESP_Inventory

        return
    end


    if proc then
        return
    end


    -- Q

    if input.KeyCode ==
        Settings.ToggleKey
    then

        Settings.Enabled =
            not Settings.Enabled


        if not Settings.Enabled then

            LockedTarget = nil
            LockedPlayer = nil
        end


        FOVCircle.Color =

            Settings.Enabled

            and Color3.fromRGB(
                0,
                255,
                0
            )

            or Color3.fromRGB(
                150,
                150,
                150
            )


    -- L

    elseif input.KeyCode ==
        Settings.HideFOVKey
    then

        Settings.FOV_Visible =
            not Settings.FOV_Visible


    -- Y

    elseif input.KeyCode ==
        Settings.AutoShotKey
    then

        Settings.AutoShot =
            not Settings.AutoShot


    -- Z

    elseif input.KeyCode ==
        Settings.TriggerbotKey
    then

        Settings.Triggerbot =
            not Settings.Triggerbot


    -- +

    elseif input.KeyCode ==
        Enum.KeyCode.Equals
    then

        Settings.FOV_Radius =
            math.min(

                Settings.FOV_Radius
                + 5,

                300
            )


    -- -

    elseif input.KeyCode ==
        Enum.KeyCode.Minus
    then

        Settings.FOV_Radius =
            math.max(

                Settings.FOV_Radius
                - 5,

                5
            )


    -- P

    elseif input.KeyCode ==
        Enum.KeyCode.P
    then

        Settings.Prediction =
            not Settings.Prediction
    end
end)


print("COMBAT SYSTEM CARREGADO!")
print("Q - Aimbot")
print("Z - Triggerbot")
print("Y - Auto Shot")
print("L - FOV")
print("+/- - FOV Size")
print("P - Prediction")
print("F1 - Hide/Show HUB")
print("F2 - Stream Mode")
print("F3 - Armed ESP")
print("F4 - Weapon Info")
print("ESP Distance: " .. Settings.ESP_MaxDistance .. " studs")
print("ESP mostra somente jogadores com Tool equipada.")
