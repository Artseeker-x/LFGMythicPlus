------------------------------------------------------------------------
-- UI/RoleSlots.lua
-- Renders 5 party member slots: role icon, spec icon, class-colored
-- name. Slots have subtle hover highlights and alternating backgrounds.
-- Handles pending-inspect, empty, and overflow members gracefully.
------------------------------------------------------------------------
local _, NS = ...

local RS = {}
NS.RoleSlots = RS

local C     = NS.CONSTANTS
local CSD   = NS.ClassSpecData
local State = NS.State

local SLOT_HEIGHT = 20
local ICON_SIZE   = 16
local SLOT_ORDER  = { "TANK", "HEALER", "DAMAGER", "DAMAGER", "DAMAGER" }
local SLOT_LABELS = { "Tank", "Healer", "DPS", "DPS", "DPS" }

RS.slots = {}

------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------
function RS:Initialize(parent)
    self.anchor = parent

    -- Section header
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -2)
    header:SetTextColor(C.COLOR_HEADER.r, C.COLOR_HEADER.g, C.COLOR_HEADER.b)
    self.header = header

    -- Separator below header
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetTexture("Interface\\Buttons\\WHITE8x8")
    sep:SetVertexColor(0.35, 0.35, 0.45, 0.5)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", header, "BOTTOMLEFT", -2, -3)
    sep:SetPoint("RIGHT", parent, "RIGHT", -2, 0)

    -- Slot frames below header (header ~12px + sep + padding = ~18px)
    for i = 1, 5 do
        self.slots[i] = self:CreateSlot(parent, i)
    end
end

------------------------------------------------------------------------
-- Create a single slot row
------------------------------------------------------------------------
function RS:CreateSlot(parent, index)
    local topOffset = -18 - ((index - 1) * (SLOT_HEIGHT + 2))

    local slot = CreateFrame("Frame", nil, parent)
    slot:SetHeight(SLOT_HEIGHT)
    slot:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, topOffset)
    slot:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

    -- Alternating row background for readability
    local bg = slot:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    if index % 2 == 0 then
        bg:SetVertexColor(1, 1, 1, 0.03)
    else
        bg:SetVertexColor(0, 0, 0, 0.02)
    end
    slot.bg = bg

    -- Hover highlight
    slot:EnableMouse(true)
    local highlight = slot:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
    highlight:SetVertexColor(1, 1, 1, 0.06)

    -- Role icon
    local roleIcon = slot:CreateTexture(nil, "ARTWORK")
    roleIcon:SetSize(ICON_SIZE, ICON_SIZE)
    roleIcon:SetPoint("LEFT", slot, "LEFT", 4, 0)
    slot.roleIcon = roleIcon

    -- Spec icon
    local specIcon = slot:CreateTexture(nil, "ARTWORK")
    specIcon:SetSize(ICON_SIZE, ICON_SIZE)
    specIcon:SetPoint("LEFT", roleIcon, "RIGHT", 3, 0)
    slot.specIcon = specIcon

    -- Name + spec text
    local nameText = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", specIcon, "RIGHT", 4, 0)
    nameText:SetPoint("RIGHT", slot, "RIGHT", -4, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    slot.nameText = nameText

    -- Tooltip showing spec details on hover
    slot:SetScript("OnEnter", function(frame)
        local member = frame.memberData
        if not member then return end
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        local colorHex = CSD:GetClassColor(member.classFile)
        GameTooltip:SetText(string.format("|cff%s%s|r", colorHex, member.name), 1, 1, 1)
        if member.specInfo then
            GameTooltip:AddLine(member.specInfo.name .. " " .. member.classFile:sub(1,1) .. member.classFile:sub(2):lower(), 0.7, 0.7, 0.7)
        end
        -- List utilities this member provides
        if member.specID then
            local utils = NS.UtilityMatrix:GetUtilities(member.specID)
            local utilList = {}
            for _, key in ipairs(C.UTILITY_ORDER) do
                if utils[key] then
                    table.insert(utilList, C.UTILITY_LABELS[key])
                end
            end
            if #utilList > 0 then
                GameTooltip:AddLine("Utility: " .. table.concat(utilList, ", "), 0.5, 0.8, 0.5)
            end
            -- List raid buffs
            local buffList = {}
            for _, key in ipairs(C.BUFF_ORDER) do
                if utils[key] then
                    table.insert(buffList, C.BUFF_LABELS[key])
                end
            end
            if #buffList > 0 then
                GameTooltip:AddLine("Buffs: " .. table.concat(buffList, ", "), 0.5, 0.7, 0.9)
            end
        elseif member.classFile then
            -- Spec unknown: show class-guaranteed contributions
            local classUtils = NS.UtilityMatrix:GetClassUtilities(member.classFile)
            if classUtils then
                local items = {}
                for _, key in ipairs(C.UTILITY_ORDER) do
                    if classUtils[key] then table.insert(items, C.UTILITY_LABELS[key]) end
                end
                for _, key in ipairs(C.BUFF_ORDER) do
                    if classUtils[key] then table.insert(items, C.BUFF_LABELS[key]) end
                end
                if #items > 0 then
                    GameTooltip:AddLine("Class brings: " .. table.concat(items, ", "), 0.6, 0.6, 0.4)
                end
            end
        end
        GameTooltip:Show()
    end)
    slot:SetScript("OnLeave", GameTooltip_Hide)

    return slot
end

------------------------------------------------------------------------
-- Update all 5 slots from State
------------------------------------------------------------------------
function RS:Update()
    self.header:SetText(string.format(
        "Group  |cffaaaaaa(%d/5)|r",
        State.memberCount
    ))

    -- Sort members into role buckets.
    -- NONE-role members (no group role assigned) use their spec's role,
    -- falling back to DPS if unknown.
    local tank, healer, dps = {}, {}, {}
    for _, member in pairs(State.members) do
        local role = member.role
        if role == C.ROLE_NONE and member.specInfo then
            role = member.specInfo.role
        end
        if role == C.ROLE_TANK then
            table.insert(tank, member)
        elseif role == C.ROLE_HEALER then
            table.insert(healer, member)
        else
            table.insert(dps, member)
        end
    end

    -- Build ordered display: tank, healer, dps x3
    local display = { tank[1], healer[1], dps[1], dps[2], dps[3] }

    for i = 1, 5 do
        self:UpdateSlot(self.slots[i], display[i], i)
    end
end

------------------------------------------------------------------------
-- Update a single slot
------------------------------------------------------------------------
function RS:UpdateSlot(slot, member, index)
    if not slot then return end

    -- Store member ref for tooltip
    slot.memberData = member

    local expectedRole = SLOT_ORDER[index]

    if member and member.classFile then
        local roleAtlas = CSD.ROLE_ICONS[member.role] or CSD.ROLE_ICONS.DAMAGER
        slot.roleIcon:SetAtlas(roleAtlas)
        slot.roleIcon:SetDesaturated(false)
        slot.roleIcon:SetAlpha(1)

        if member.specInfo then
            slot.specIcon:SetTexture(member.specInfo.icon)
            slot.specIcon:Show()
        else
            slot.specIcon:Hide()
        end

        local colorHex = CSD:GetClassColor(member.classFile)
        local displayName = member.name or "Unknown"

        if member.specPending then
            slot.nameText:SetText(string.format("|cff%s%s|r  |cff777777...|r", colorHex, displayName))
        elseif member.specInfo then
            slot.nameText:SetText(string.format("|cff%s%s|r  |cffaaaaaa%s|r", colorHex, displayName, member.specInfo.name))
        else
            slot.nameText:SetText(string.format("|cff%s%s|r", colorHex, displayName))
        end
    else
        local roleAtlas = CSD.ROLE_ICONS[expectedRole] or CSD.ROLE_ICONS.DAMAGER
        slot.roleIcon:SetAtlas(roleAtlas)
        slot.roleIcon:SetDesaturated(true)
        slot.roleIcon:SetAlpha(0.35)
        slot.specIcon:Hide()
        slot.nameText:SetText(string.format("|cff444444%s|r", SLOT_LABELS[index]))
    end
end
