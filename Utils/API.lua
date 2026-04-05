------------------------------------------------------------------------
-- Utils/API.lua
-- Thin wrappers around Blizzard API calls used throughout the addon.
-- Centralizes API access so future Blizzard changes only need one fix.
------------------------------------------------------------------------
local _, NS = ...

local API = {}
NS.API = API

------------------------------------------------------------------------
-- Group queries
------------------------------------------------------------------------

-- Returns number of group members (1 when solo)
function API.GetGroupSize()
    if IsInGroup() then
        return GetNumGroupMembers()
    end
    return 1 -- solo
end

------------------------------------------------------------------------
-- Unit info (safe wrappers — always nil-safe on missing units)
------------------------------------------------------------------------

-- Returns classFilename (English, uppercase) for a unit
function API.GetUnitClass(unit)
    if not UnitExists(unit) then return nil end
    local _, classFile = UnitClass(unit)
    return classFile
end

-- Returns specID for a unit. For the player this is always reliable.
-- For party members, returns nil if inspect data isn't cached yet.
function API.GetUnitSpecID(unit)
    if not UnitExists(unit) then return nil end

    -- Player: use the authoritative local API
    if UnitIsUnit(unit, "player") then
        local specIndex = GetSpecialization()
        if specIndex then
            local specID = GetSpecializationInfo(specIndex)
            return specID
        end
        return nil
    end

    -- Party members: GetInspectSpecialization returns cached spec
    -- from inspect data. Returns 0 if not yet available.
    local specID = GetInspectSpecialization(unit)
    if specID and specID > 0 then
        return specID
    end
    return nil
end

-- Returns assigned role string: TANK, HEALER, DAMAGER, NONE
function API.GetUnitRole(unit)
    if not UnitExists(unit) then return "NONE" end
    return UnitGroupRolesAssigned(unit) or "NONE"
end

-- Returns the unit's display name
function API.GetUnitName(unit)
    if not UnitExists(unit) then return nil end
    return UnitName(unit)
end

------------------------------------------------------------------------
-- Inspect helpers
------------------------------------------------------------------------

-- Request inspect data for a unit. Returns true if the request was sent.
-- Respects CanInspect() to avoid errors.
function API.RequestInspect(unit)
    if not UnitExists(unit) then return false end
    if UnitIsUnit(unit, "player") then return false end -- no need
    if not UnitIsConnected(unit) then return false end
    if not UnitIsVisible(unit) then return false end
    if not CanInspect(unit) then return false end
    NotifyInspect(unit)
    return true
end

-- Returns the GUID for a unit (used to match INSPECT_READY callbacks)
function API.GetUnitGUID(unit)
    if not UnitExists(unit) then return nil end
    return UnitGUID(unit)
end

