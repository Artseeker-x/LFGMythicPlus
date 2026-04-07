local _, NS = ...

local MW = {}
NS.MainWindow = MW

local C = NS.CONSTANTS

MW.frame = nil

function MW:Initialize()
    if self.frame then return end

    local f = CreateFrame("Frame", "LFGMythicPlusFrame", UIParent, "BackdropTemplate")
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(100)
    f:SetClampedToScreen(true)
    f:SetSize(C.FRAME_DEFAULT_WIDTH, C.FRAME_DEFAULT_HEIGHT)
    f:Hide()

    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16,
        edgeSize = 14,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0.06, 0.06, 0.10, 0.94)
    f:SetBackdropBorderColor(0.30, 0.30, 0.40, 0.85)

    self.frame = f

    local titleBg = f:CreateTexture(nil, "ARTWORK")
    titleBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    titleBg:SetVertexColor(0.10, 0.10, 0.16, 0.98)
    titleBg:SetHeight(22)
    titleBg:SetPoint("TOPLEFT", f, "TOPLEFT", 3, -3)
    titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -3)
    self.titleBg = titleBg

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("CENTER", titleBg, "CENTER", 0, 0)
    title:SetText("LFG Mythic+")
    title:SetTextColor(C.COLOR_HEADER.r, C.COLOR_HEADER.g, C.COLOR_HEADER.b)
    self.titleText = title

    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -26)
    content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 6)
    self.content = content

    NS.Layout:Initialize(content)
end

-- Anchored permanently to PVEFrame TOPRIGHT. RaiderIOCompat redirects the
-- Raider.IO tooltip anchor to appear right of our frame instead of on top of it.
function MW:AnchorToPVEFrame()
    local f = self.frame
    if not f or not PVEFrame then return end
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", PVEFrame, "TOPRIGHT", 4, 0)
end

function MW:Show()
    if not self.frame then return end
    self:AnchorToPVEFrame()
    self.frame:Show()
    NS.State.dirty = true
    self:Refresh()
    if NS.GroupScanner then
        NS.GroupScanner:StartSafetyNet()
    end
end

function MW:Hide()
    if not self.frame then return end
    self.frame:Hide()
    if NS.GroupScanner then
        NS.GroupScanner:StopSafetyNet()
    end
end

function MW:IsShown()
    return self.frame and self.frame:IsShown()
end

function MW:Refresh()
    if not self:IsShown() then return end
    NS.Layout:Update()
end
