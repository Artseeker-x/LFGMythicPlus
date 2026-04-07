local _, NS = ...

local C = NS.CONSTANTS

local State = {}
NS.State = State

-- members[i] = { unit, guid, name, classFile, specID, role, specInfo, specPending }
-- utilities[KEY] = { covered, contributors = { { name, classFile, specID }, ... } }
-- roleCounts = { TANK, HEALER, DAMAGER }
State.members     = {}
State.utilities   = {}
State.roleCounts  = { TANK = 0, HEALER = 0, DAMAGER = 0 }
State.memberCount = 0
State.dirty       = false

function State:Clear()
    wipe(self.members)
    wipe(self.utilities)
    self.roleCounts.TANK    = 0
    self.roleCounts.HEALER  = 0
    self.roleCounts.DAMAGER = 0
    self.memberCount = 0
    self.dirty = true
end

function State:SetMember(index, data)
    self.members[index] = data
    self.dirty = true
end

function State:ComputeRoleCounts()
    self.roleCounts.TANK    = 0
    self.roleCounts.HEALER  = 0
    self.roleCounts.DAMAGER = 0

    for _, member in pairs(self.members) do
        local role = member.role
        if role == C.ROLE_TANK then
            self.roleCounts.TANK = self.roleCounts.TANK + 1
        elseif role == C.ROLE_HEALER then
            self.roleCounts.HEALER = self.roleCounts.HEALER + 1
        elseif role == C.ROLE_DAMAGER then
            self.roleCounts.DAMAGER = self.roleCounts.DAMAGER + 1
        end
    end
end

function State:ResetUtilities()
    for _, key in ipairs(C.UTILITY_ORDER) do
        self.utilities[key] = { covered = false, contributors = {} }
    end
    for _, key in ipairs(C.BUFF_ORDER) do
        self.utilities[key] = { covered = false, contributors = {} }
    end
    self.dirty = true
end

function State:AddUtilityContributor(key, member)
    if not self.utilities[key] then
        self.utilities[key] = { covered = false, contributors = {} }
    end
    table.insert(self.utilities[key].contributors, {
        name      = member.name,
        classFile = member.classFile,
        specID    = member.specID,
    })
    self.utilities[key].covered = true
    self.dirty = true
end

function State:IsUtilityCovered(key)
    local u = self.utilities[key]
    return u and u.covered or false
end

function State:GetUtilityContributors(key)
    local u = self.utilities[key]
    return u and u.contributors or {}
end

function State:HasPendingInspects()
    for _, member in pairs(self.members) do
        if member.specPending then
            return true
        end
    end
    return false
end

function State:MarkClean()
    self.dirty = false
end
