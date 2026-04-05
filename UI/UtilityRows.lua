------------------------------------------------------------------------
-- UI/UtilityRows.lua
-- Renders two sections: Utility Coverage (6 rows, always visible) and
-- Raid Buffs (0-11 rows, only visible when covered by a party member).
--
-- Utility rows always show — uncovered ones are greyed out as before.
-- Buff rows are hidden when no party member provides them, and
-- dynamically repositioned on each update to stack without gaps.
--
-- Both sections read from the same State.utilities table, populated
-- by CompEvaluator:Evaluate() on every scan cycle.
------------------------------------------------------------------------
local _, NS = ...

local UR = {}
NS.UtilityRows = UR

local C     = NS.CONSTANTS
local CSD   = NS.ClassSpecData
local State = NS.State

local ROW_HEIGHT        = 18
local ROW_GAP           = 1
local ICON_SIZE         = 14
local CONTRIB_ICON_SIZE = 13
local MAX_CONTRIB_ICONS = 5
local HEADER_HEIGHT     = 16
local HEADER_GAP        = 4  -- space below header + separator
local SECTION_GAP       = 4  -- gap between sections

UR.utilRows = {}   -- utility row frames (always visible)
UR.buffRows = {}   -- buff row frames (visibility driven by coverage)

------------------------------------------------------------------------
-- Section definitions
------------------------------------------------------------------------
local utilSection = {
    header  = "Utility Coverage",
    order   = C.UTILITY_ORDER,
    labels  = C.UTILITY_LABELS,
    icons   = C.UTILITY_ICONS,
    isBuff  = false,
}

local buffSection = {
    header  = "Raid Buffs",
    order   = C.BUFF_ORDER,
    labels  = C.BUFF_LABELS,
    icons   = C.BUFF_ICONS,
    isBuff  = true,
}

------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------
function UR:Initialize(parent)
    self.anchor = parent

    local yPos = 0

    ----------------------------------------------------------------
    -- Utility section (always visible, all 6 rows)
    ----------------------------------------------------------------
    -- Header line frame (used as anchor for warning indicators)
    local uHeaderLine = CreateFrame("Frame", nil, parent)
    uHeaderLine:SetHeight(HEADER_HEIGHT)
    uHeaderLine:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -yPos)
    uHeaderLine:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    self.utilHeaderLine = uHeaderLine

    local uHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    uHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -yPos - 2)
    uHeader:SetText(utilSection.header)
    uHeader:SetTextColor(C.COLOR_HEADER.r, C.COLOR_HEADER.g, C.COLOR_HEADER.b)

    local uSep = parent:CreateTexture(nil, "ARTWORK")
    uSep:SetTexture("Interface\\Buttons\\WHITE8x8")
    uSep:SetVertexColor(0.35, 0.35, 0.45, 0.5)
    uSep:SetHeight(1)
    uSep:SetPoint("TOPLEFT", uHeader, "BOTTOMLEFT", -2, -2)
    uSep:SetPoint("RIGHT", parent, "RIGHT", -2, 0)

    yPos = yPos + HEADER_HEIGHT + HEADER_GAP

    for i, key in ipairs(C.UTILITY_ORDER) do
        local rowY = -yPos - ((i - 1) * (ROW_HEIGHT + ROW_GAP))
        self.utilRows[i] = self:CreateRow(parent, key, rowY, i, utilSection)
    end

    yPos = yPos + #C.UTILITY_ORDER * (ROW_HEIGHT + ROW_GAP)
    self.utilSectionBottom = yPos  -- Y offset where utility section ends

    ----------------------------------------------------------------
    -- Buff section (header + rows created once, visibility dynamic)
    ----------------------------------------------------------------
    local bHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bHeader:SetText(buffSection.header)
    bHeader:SetTextColor(C.COLOR_HEADER.r, C.COLOR_HEADER.g, C.COLOR_HEADER.b)
    bHeader:Hide()
    self.buffHeader = bHeader

    local bSep = parent:CreateTexture(nil, "ARTWORK")
    bSep:SetTexture("Interface\\Buttons\\WHITE8x8")
    bSep:SetVertexColor(0.35, 0.35, 0.45, 0.5)
    bSep:SetHeight(1)
    bSep:Hide()
    self.buffSep = bSep

    -- Create all buff row frames (hidden by default)
    for i, key in ipairs(C.BUFF_ORDER) do
        local row = self:CreateRow(parent, key, 0, #C.UTILITY_ORDER + i, buffSection)
        row:Hide()
        self.buffRows[i] = row
    end
end

------------------------------------------------------------------------
-- Create a single row frame (shared by both sections)
------------------------------------------------------------------------
function UR:CreateRow(parent, key, yOffset, globalIndex, section)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)
    row:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    row.utilKey = key
    row.section = section

    -- Alternating background
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    if globalIndex % 2 == 0 then
        bg:SetVertexColor(1, 1, 1, 0.03)
    else
        bg:SetVertexColor(0, 0, 0, 0.02)
    end
    row.bg = bg

    -- Coverage tint overlay (very subtle green or red)
    local tint = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    tint:SetAllPoints()
    tint:SetTexture("Interface\\Buttons\\WHITE8x8")
    tint:SetAlpha(0)
    row.tint = tint

    -- Hover highlight
    row:EnableMouse(true)
    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
    highlight:SetVertexColor(1, 1, 1, 0.06)

    -- Icon
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("LEFT", row, "LEFT", 4, 0)
    icon:SetTexture(section.icons[key])
    row.icon = icon

    -- Label
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    label:SetPoint("RIGHT", row, "RIGHT", -50, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetText(section.labels[key])
    row.label = label

    -- Status text (right edge)
    local status = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    status:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.status = status

    -- Contributor spec icons (anchored right-to-left from status)
    row.contribIcons = {}
    for ci = 1, MAX_CONTRIB_ICONS do
        local tex = row:CreateTexture(nil, "ARTWORK")
        tex:SetSize(CONTRIB_ICON_SIZE, CONTRIB_ICON_SIZE)
        tex:Hide()
        row.contribIcons[ci] = tex
    end

    -- Tooltip
    row:SetScript("OnEnter", function(rowFrame)
        local rKey = rowFrame.utilKey
        local rSection = rowFrame.section
        local contributors = State:GetUtilityContributors(rKey)

        GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
        GameTooltip:SetText(rSection.labels[rKey] or rKey, 1, 0.82, 0)

        -- Buff description (what the buff does)
        if rSection.isBuff and C.BUFF_DESCRIPTIONS and C.BUFF_DESCRIPTIONS[rKey] then
            GameTooltip:AddLine(C.BUFF_DESCRIPTIONS[rKey], 0.75, 0.75, 0.75, true)
        end

        if #contributors == 0 then
            if rSection.isBuff and C.BUFF_SOURCES and C.BUFF_SOURCES[rKey] then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Provided by: " .. C.BUFF_SOURCES[rKey], 0.6, 0.6, 0.6)
            end
            GameTooltip:AddLine("Not covered by any group member", 0.7, 0.3, 0.3)
        else
            GameTooltip:AddLine(" ")
            for _, contrib in ipairs(contributors) do
                local colorHex = CSD:GetClassColor(contrib.classFile)
                local specInfo = contrib.specID and CSD:GetSpecInfo(contrib.specID)
                local specName = specInfo and specInfo.name or ""
                GameTooltip:AddLine(
                    string.format("|cff%s%s|r  %s", colorHex, contrib.name, specName),
                    1, 1, 1
                )
            end
        end

        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)

    return row
end

------------------------------------------------------------------------
-- Update: refresh all rows from current State.
-- Utility rows: always visible, grey when uncovered.
-- Buff rows: hidden when uncovered, dynamically repositioned.
------------------------------------------------------------------------
function UR:Update()
    -- 1. Update utility rows (always visible)
    for _, row in ipairs(self.utilRows) do
        self:ApplyRowState(row)
    end

    -- 2. Determine which buff rows are covered
    local visibleBuffs = {}
    for _, row in ipairs(self.buffRows) do
        if State:IsUtilityCovered(row.utilKey) then
            visibleBuffs[#visibleBuffs + 1] = row
        end
    end

    -- 3. Hide all buff rows first
    for _, row in ipairs(self.buffRows) do
        row:Hide()
    end

    local hasBuffs = #visibleBuffs > 0

    -- 4. Show/hide buff section header
    if hasBuffs then
        self.buffHeader:Show()
        self.buffSep:Show()
    else
        self.buffHeader:Hide()
        self.buffSep:Hide()
    end

    -- 5. Reposition visible buff rows and the header
    local yPos = self.utilSectionBottom + SECTION_GAP

    if hasBuffs then
        -- Position buff header
        self.buffHeader:ClearAllPoints()
        self.buffHeader:SetPoint("TOPLEFT", self.anchor, "TOPLEFT", 2, -yPos - 2)

        self.buffSep:ClearAllPoints()
        self.buffSep:SetPoint("TOPLEFT", self.buffHeader, "BOTTOMLEFT", -2, -2)
        self.buffSep:SetPoint("RIGHT", self.anchor, "RIGHT", -2, 0)

        yPos = yPos + HEADER_HEIGHT + HEADER_GAP

        -- Position and show each visible buff row
        for i, row in ipairs(visibleBuffs) do
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", self.anchor, "TOPLEFT", 0, -yPos - ((i - 1) * (ROW_HEIGHT + ROW_GAP)))
            row:SetPoint("RIGHT", self.anchor, "RIGHT", 0, 0)

            -- Re-stripe alternating background based on visible position
            if i % 2 == 0 then
                row.bg:SetVertexColor(1, 1, 1, 0.03)
            else
                row.bg:SetVertexColor(0, 0, 0, 0.02)
            end

            self:ApplyRowState(row)
            row:Show()
        end

        yPos = yPos + #visibleBuffs * (ROW_HEIGHT + ROW_GAP)
    end

    -- 6. Resize container to fit actual content
    self.anchor:SetHeight(math.max(yPos, 1))
end

------------------------------------------------------------------------
-- Apply covered/uncovered visual state to a single row
------------------------------------------------------------------------
function UR:ApplyRowState(row)
    local covered = State:IsUtilityCovered(row.utilKey)
    local contributors = State:GetUtilityContributors(row.utilKey)

    if covered then
        row.icon:SetDesaturated(false)
        row.icon:SetAlpha(1)
        row.label:SetTextColor(C.COLOR_TEXT.r, C.COLOR_TEXT.g, C.COLOR_TEXT.b)
        row.status:SetText(string.format("|cff4ddb4d%dx|r", #contributors))
        row.tint:SetVertexColor(0.2, 0.8, 0.2, 0.04)
        row.tint:SetAlpha(0.04)
    else
        row.icon:SetDesaturated(true)
        row.icon:SetAlpha(0.45)
        row.label:SetTextColor(C.COLOR_DIM.r, C.COLOR_DIM.g, C.COLOR_DIM.b)
        row.status:SetText("|cffcc3333---|r")
        row.tint:SetVertexColor(0.8, 0.2, 0.2, 0.04)
        row.tint:SetAlpha(0.04)
    end

    self:UpdateContributorIcons(row, contributors)
end

------------------------------------------------------------------------
-- Position contributor spec icons inline
------------------------------------------------------------------------
function UR:UpdateContributorIcons(row, contributors)
    local statusWidth = row.status:GetStringWidth() + 8
    local spacing = 1

    for i = 1, MAX_CONTRIB_ICONS do
        local tex = row.contribIcons[i]
        local contrib = contributors[i]

        if contrib and contrib.specID then
            local specInfo = CSD:GetSpecInfo(contrib.specID)
            if specInfo then
                tex:SetTexture(specInfo.icon)
                tex:ClearAllPoints()
                tex:SetPoint("RIGHT", row, "RIGHT", -(statusWidth + (i - 1) * (CONTRIB_ICON_SIZE + spacing)), 0)
                tex:Show()
            else
                tex:Hide()
            end
        else
            tex:Hide()
        end
    end
end
