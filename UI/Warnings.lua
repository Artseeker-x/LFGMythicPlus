local _, NS = ...

local Warn = {}
NS.Warnings = Warn

local C     = NS.CONSTANTS
local State = NS.State
local SV    = NS.SavedVariables

local INDICATOR_SIZE = 14
local INDICATOR_GAP  = 4

local CRITICAL_UTILITIES = {
    { key = C.UTIL_BLOODLUST, icon = C.UTILITY_ICONS.BLOODLUST, tip = "No Bloodlust / Heroism in group" },
    { key = C.UTIL_BREZ,      icon = C.UTILITY_ICONS.BREZ,      tip = "No Battle Res in group" },
}

Warn.indicators = {}

function Warn:Initialize(parent, rightEdge)
    self.anchor = parent

    for i, def in ipairs(CRITICAL_UTILITIES) do
        self.indicators[i] = self:CreateIndicator(parent, rightEdge, def, i)
    end

    local mainFrame = NS.MainWindow and NS.MainWindow.frame
    if mainFrame then
        local pending = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        pending:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -8, 8)
        pending:SetTextColor(0.45, 0.45, 0.45, 0.7)
        pending:SetText("Loading specs...")
        pending:Hide()
        self.pendingText = pending
    end
end

function Warn:CreateIndicator(parent, rightEdge, def, index)
    local btn = CreateFrame("Frame", nil, parent)
    btn:SetSize(INDICATOR_SIZE, INDICATOR_SIZE)
    btn:Hide()

    btn:SetPoint("RIGHT", rightEdge, "RIGHT", -(4 + (index - 1) * (INDICATOR_SIZE + INDICATOR_GAP)), 2)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(def.icon)
    icon:SetVertexColor(0.9, 0.25, 0.25)
    btn.icon = icon

    local xMark = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xMark:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
    xMark:SetText("|cffee3333x|r")
    xMark:SetScale(0.8)
    btn.xMark = xMark

    btn:EnableMouse(true)
    btn:SetScript("OnEnter", function(frame)
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:SetText(def.tip, C.COLOR_MISSING.r, C.COLOR_MISSING.g, C.COLOR_MISSING.b)
        GameTooltip:AddLine("Critical M+ utility — not covered by any group member.", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)

    btn.utilKey = def.key
    return btn
end

function Warn:Update()
    local showWarnings = SV:Get("showWarnings")

    for _, ind in ipairs(self.indicators) do
        if showWarnings and not State:IsUtilityCovered(ind.utilKey) then
            ind:Show()
        else
            ind:Hide()
        end
    end

    if self.pendingText then
        if State:HasPendingInspects() then
            self.pendingText:Show()
        else
            self.pendingText:Hide()
        end
    end
end
