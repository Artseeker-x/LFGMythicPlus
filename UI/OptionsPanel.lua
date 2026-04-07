local _, NS = ...

local C = NS.CONSTANTS

-- Challenge Mode keystone icon (fileDataID 525134).
-- FileDataIDs are stable across patches; path-based texture references are not.
local KEYSTONE_ICON = 525134
local ICON_SIZE     = 64

local function InitPanel(self)
    if self.initialized then return end
    self.initialized = true

    local icon = self:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("TOP", self, "TOP", 0, -24)
    icon:SetTexture(KEYSTONE_ICON)

    local title = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", icon, "BOTTOM", 0, -10)
    title:SetText("LFG Mythic+")
    title:SetTextColor(C.COLOR_HEADER.r, C.COLOR_HEADER.g, C.COLOR_HEADER.b)

    local version = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    version:SetPoint("TOP", title, "BOTTOM", 0, -4)
    version:SetText("v" .. C.ADDON_VERSION)

    local sep = self:CreateTexture(nil, "ARTWORK")
    sep:SetTexture("Interface\\Buttons\\WHITE8x8")
    sep:SetVertexColor(0.35, 0.35, 0.45, 0.5)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", self, "TOPLEFT", 32, -130)
    sep:SetPoint("RIGHT", self, "RIGHT", -32, 0)

    local desc = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOP", sep, "BOTTOM", 0, -16)
    desc:SetPoint("LEFT", self, "LEFT", 40, 0)
    desc:SetPoint("RIGHT", self, "RIGHT", -40, 0)
    desc:SetJustifyH("CENTER")
    desc:SetWordWrap(true)
    desc:SetSpacing(3)
    desc:SetText(
        "Enhanced group composition companion\n" ..
        "for Mythic+ dungeon forming.\n" ..
        "\n" ..
        "The panel appears automatically alongside\n" ..
        "the Blizzard Group Finder window."
    )

    local cmdHeader = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cmdHeader:SetPoint("TOP", desc, "BOTTOM", 0, -20)
    cmdHeader:SetText("Slash Commands")
    cmdHeader:SetTextColor(C.COLOR_HEADER.r, C.COLOR_HEADER.g, C.COLOR_HEADER.b, 0.8)

    local cmds = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cmds:SetPoint("TOP", cmdHeader, "BOTTOM", 0, -8)
    cmds:SetJustifyH("CENTER")
    cmds:SetSpacing(2)
    cmds:SetText(
        "|cffffffff/lfgmp warnings|r   Toggle missing utility indicators\n" ..
        "|cffffffff/lfgmp reset|r           Reset all settings\n" ..
        "|cffffffff/lfgmp debug|r          Toggle debug output"
    )
    cmds:SetTextColor(0.7, 0.7, 0.7)
end

if Settings and Settings.RegisterCanvasLayoutCategory then
    local panel = CreateFrame("Frame")
    panel.name = C.ADDON_NAME
    panel:SetScript("OnShow", InitPanel)

    local DISPLAY_NAME = "LFG Mythic+"
    local category = Settings.RegisterCanvasLayoutCategory(panel, DISPLAY_NAME)
    category.ID = C.ADDON_NAME
    Settings.RegisterAddOnCategory(category)
end
