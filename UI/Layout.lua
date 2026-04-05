------------------------------------------------------------------------
-- UI/Layout.lua
-- Orchestrates the content area using anchor-based container frames.
-- Two sections stack vertically: RoleSlots (top), UtilityRows (middle).
-- Warning indicators sit on the utility header line (no vertical space).
------------------------------------------------------------------------
local _, NS = ...

local Layout = {}
NS.Layout = Layout

Layout.initialized = false

-- Section heights (used for anchoring)
local ROLES_HEIGHT = 130  -- header + 5 slots

------------------------------------------------------------------------
-- Initialize: create container frames and pass them to sub-modules
------------------------------------------------------------------------
function Layout:Initialize(contentFrame)
    self.contentFrame = contentFrame

    -- Top section: role slots
    local rolesContainer = CreateFrame("Frame", nil, contentFrame)
    rolesContainer:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, 0)
    rolesContainer:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", 0, 0)
    rolesContainer:SetHeight(ROLES_HEIGHT)
    self.rolesContainer = rolesContainer

    -- Middle section: utility + buff rows (anchored below roles, fills remaining space)
    local utilContainer = CreateFrame("Frame", nil, contentFrame)
    utilContainer:SetPoint("TOPLEFT", rolesContainer, "BOTTOMLEFT", 0, -4)
    utilContainer:SetPoint("TOPRIGHT", rolesContainer, "BOTTOMRIGHT", 0, -4)
    utilContainer:SetPoint("BOTTOM", contentFrame, "BOTTOM", 0, 0)
    self.utilContainer = utilContainer

    -- Initialize sub-modules into their containers
    NS.RoleSlots:Initialize(rolesContainer)
    NS.UtilityRows:Initialize(utilContainer)

    -- Initialize warnings: indicators sit right-aligned on the utility header line
    NS.Warnings:Initialize(NS.UtilityRows.utilHeaderLine, NS.UtilityRows.utilHeaderLine)

    self.initialized = true
end

------------------------------------------------------------------------
-- Update: refresh all sections from current State
------------------------------------------------------------------------
function Layout:Update()
    if not self.initialized then return end
    if not NS.State.dirty then return end

    NS.RoleSlots:Update()
    NS.UtilityRows:Update()
    NS.Warnings:Update()

    NS.State:MarkClean()
end
