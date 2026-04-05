------------------------------------------------------------------------
-- Core/State.lua
-- Holds the live group composition state: who is in each slot, their
-- class/spec, role, and aggregated utility + raid buff coverage.
-- Written to by GroupScanner + CompEvaluator. Read by UI renderers.
------------------------------------------------------------------------
local _, NS = ...

local C = NS.CONSTANTS

local State = {}
NS.State = State

------------------------------------------------------------------------
-- The canonical group state table.
--
-- members[i] = {
--     unit, guid, name, classFile, specID, role, specInfo,
--     specPending  -- true if we requested inspect but haven't got data yet
-- }
--
-- utilities[KEY] = {
--     covered      = true/false,
--     contributors = { { name, classFile, specID }, ... }
-- }
-- (covers both utility keys like BREZ and buff keys like ARCANE_INTELLECT)
--
-- roleCounts = { TANK = n, HEALER = n, DAMAGER = n }
-- memberCount = total members scanned
------------------------------------------------------------------------
State.members     = {}
State.utilities   = {}
State.roleCounts  = { TANK = 0, HEALER = 0, DAMAGER = 0 }
State.memberCount = 0
State.dirty       = false

------------------------------------------------------------------------
-- Clear all state (called at the start of each scan)
------------------------------------------------------------------------
function State:Clear()
    wipe(self.members)
    wipe(self.utilities)
    self.roleCounts.TANK    = 0
    self.roleCounts.HEALER  = 0
    self.roleCounts.DAMAGER = 0
    self.memberCount = 0
    self.dirty = true
end

------------------------------------------------------------------------
-- Member management
------------------------------------------------------------------------
function State:SetMember(index, data)
    self.members[index] = data
    self.dirty = true
end

------------------------------------------------------------------------
-- Role counts — called by GroupScanner after all members are scanned
------------------------------------------------------------------------
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

------------------------------------------------------------------------
-- Utility + buff management — unified structure for all tracked keys.
-- Both UTILITY_ORDER and BUFF_ORDER keys are stored here.
------------------------------------------------------------------------
function State:ResetUtilities()
    -- Initialize utility keys
    for _, key in ipairs(C.UTILITY_ORDER) do
        self.utilities[key] = {
            covered = false,
            contributors = {},
        }
    end
    -- Initialize raid buff keys
    for _, key in ipairs(C.BUFF_ORDER) do
        self.utilities[key] = {
            covered = false,
            contributors = {},
        }
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

------------------------------------------------------------------------
-- Convenience accessors for UI
------------------------------------------------------------------------
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
