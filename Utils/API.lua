local _, NS = ...

local API = {}
NS.API = API

function API.GetGroupSize()
    if IsInGroup() then
        return GetNumGroupMembers()
    end
    return 1
end

function API.GetUnitClass(unit)
    if not UnitExists(unit) then return nil end
    local _, classFile = UnitClass(unit)
    return classFile
end

function API.GetUnitSpecID(unit)
    if not UnitExists(unit) then return nil end

    if UnitIsUnit(unit, "player") then
        local specIndex = GetSpecialization()
        if specIndex then
            local specID = GetSpecializationInfo(specIndex)
            return specID
        end
        return nil
    end

    -- GetInspectSpecialization returns 0 when inspect data isn't cached yet.
    local specID = GetInspectSpecialization(unit)
    if specID and specID > 0 then
        return specID
    end
    return nil
end

function API.GetUnitRole(unit)
    if not UnitExists(unit) then return "NONE" end
    return UnitGroupRolesAssigned(unit) or "NONE"
end

function API.GetUnitName(unit)
    if not UnitExists(unit) then return nil end
    return UnitName(unit)
end

function API.RequestInspect(unit)
    if not UnitExists(unit) then return false end
    if UnitIsUnit(unit, "player") then return false end
    if not UnitIsConnected(unit) then return false end
    if not UnitIsVisible(unit) then return false end
    if not CanInspect(unit) then return false end
    NotifyInspect(unit)
    return true
end

function API.GetUnitGUID(unit)
    if not UnitExists(unit) then return nil end
    return UnitGUID(unit)
end
