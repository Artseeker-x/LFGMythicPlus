local _, NS = ...

local Layout = {}
NS.Layout = Layout

Layout.initialized = false

local ROLES_HEIGHT = 130

function Layout:Initialize(contentFrame)
    self.contentFrame = contentFrame

    local rolesContainer = CreateFrame("Frame", nil, contentFrame)
    rolesContainer:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, 0)
    rolesContainer:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", 0, 0)
    rolesContainer:SetHeight(ROLES_HEIGHT)
    self.rolesContainer = rolesContainer

    local utilContainer = CreateFrame("Frame", nil, contentFrame)
    utilContainer:SetPoint("TOPLEFT", rolesContainer, "BOTTOMLEFT", 0, -4)
    utilContainer:SetPoint("TOPRIGHT", rolesContainer, "BOTTOMRIGHT", 0, -4)
    utilContainer:SetPoint("BOTTOM", contentFrame, "BOTTOM", 0, 0)
    self.utilContainer = utilContainer

    NS.RoleSlots:Initialize(rolesContainer)
    NS.UtilityRows:Initialize(utilContainer)
    NS.Warnings:Initialize(NS.UtilityRows.utilHeaderLine, NS.UtilityRows.utilHeaderLine)

    self.initialized = true
end

function Layout:Update()
    if not self.initialized then return end
    if not NS.State.dirty then return end

    NS.RoleSlots:Update()
    NS.UtilityRows:Update()
    NS.Warnings:Update()

    NS.State:MarkClean()
end
