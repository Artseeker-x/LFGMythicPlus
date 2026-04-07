local _, NS = ...

local Scanner = {}
NS.GroupScanner = Scanner

local API   = NS.API
local State = NS.State
local CSD   = NS.ClassSpecData

local scanGeneration = 0

local pendingScan = false
local scanFrame = CreateFrame("Frame")
scanFrame:Hide()

scanFrame:SetScript("OnUpdate", function(self)
    self:Hide()
    pendingScan = false
    Scanner:DoScan()
end)

function Scanner:QueueScan()
    if not NS.initialized then return end
    if not pendingScan then
        pendingScan = true
        scanFrame:Show()
    end
end

-- GUID-keyed spec cache: immune to unit-token reassignment after roster shuffles.
-- Only populated from confirmed inspect results or class-validated reads.
local resolvedSpecs = {} -- [guid] = specID

-- Track previous unit -> GUID to detect roster shuffles and discard stale cache entries.
local prevUnitGUIDs = {} -- [unit] = guid

-- WoW supports only one in-flight NotifyInspect at a time; a second call silently
-- cancels the first. This queue serializes requests so each member gets inspected.
local inspectQueue = {}
local inspectBusy = false
local inspectBusyGUID = nil
local inspectTimeoutTimer = nil
local INSPECT_TIMEOUT = 5

local awaitingInspectGUIDs = {}

function Scanner:EnqueueInspect(unit, guid)
    if not guid then return end
    if awaitingInspectGUIDs[guid] then return end

    awaitingInspectGUIDs[guid] = true
    table.insert(inspectQueue, { unit = unit, guid = guid })

    if not inspectBusy then
        self:ProcessInspectQueue()
    end
end

function Scanner:ProcessInspectQueue()
    if inspectBusy then return end

    while #inspectQueue > 0 do
        local entry = table.remove(inspectQueue, 1)
        local unit = entry.unit
        local guid = entry.guid

        if UnitExists(unit) and API.GetUnitGUID(unit) == guid then
            ClearInspectPlayer()
            local sent = API.RequestInspect(unit)
            if sent then
                inspectBusy = true
                inspectBusyGUID = guid
                if inspectTimeoutTimer then inspectTimeoutTimer:Cancel() end
                inspectTimeoutTimer = C_Timer.NewTimer(INSPECT_TIMEOUT, function()
                    inspectTimeoutTimer = nil
                    if inspectBusy and inspectBusyGUID == guid then
                        NS.Debug:Log("Inspect timeout for GUID", guid)
                        inspectBusy = false
                        inspectBusyGUID = nil
                        awaitingInspectGUIDs[guid] = nil
                        Scanner:ProcessInspectQueue()
                    end
                end)
                return
            end
        end

        awaitingInspectGUIDs[guid] = nil
    end
end

local function FlushInspectQueue()
    wipe(inspectQueue)
    wipe(awaitingInspectGUIDs)
    if inspectTimeoutTimer then
        inspectTimeoutTimer:Cancel()
        inspectTimeoutTimer = nil
    end
    inspectBusy = false
    inspectBusyGUID = nil
end

local function GUIDToUnit(guid)
    if not guid then return nil end
    if UnitGUID("player") == guid then return "player" end
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and UnitGUID(unit) == guid then
            return unit
        end
    end
    return nil
end

function Scanner:OnInspectDataAvailable(guid)
    if not guid then return end

    local wasOurInspect = (inspectBusyGUID == guid)
    if wasOurInspect then
        if inspectTimeoutTimer then
            inspectTimeoutTimer:Cancel()
            inspectTimeoutTimer = nil
        end
        inspectBusy = false
        inspectBusyGUID = nil
    end

    local unit = GUIDToUnit(guid)
    if unit and not UnitIsUnit(unit, "player") then
        local specID = GetInspectSpecialization(unit)
        if specID and specID > 0 then
            local _, classFile = UnitClass(unit)
            local specInfo = CSD:EnsureSpec(specID, classFile)
            if specInfo then
                resolvedSpecs[guid] = specID
                NS.Debug:Log("INSPECT_READY: resolved", unit, "-> specID", specID)
            else
                NS.Debug:Log("INSPECT_READY: class mismatch for", unit, "- discarding stale data")
            end
        end
    end

    awaitingInspectGUIDs[guid] = nil

    if wasOurInspect then
        self:ProcessInspectQueue()
    end

    self:QueueScan()
end

local RETRY_INTERVALS = { 0.5, 1.5, 4.0, 8.0 }
local retryTimers = {}

local function CancelAllRetries()
    for i = 1, #retryTimers do
        if retryTimers[i] then
            retryTimers[i]:Cancel()
            retryTimers[i] = nil
        end
    end
end

local function ScheduleRetries(forGeneration)
    CancelAllRetries()
    for i, delay in ipairs(RETRY_INTERVALS) do
        retryTimers[i] = C_Timer.NewTimer(delay, function()
            retryTimers[i] = nil
            if scanGeneration == forGeneration then -- no-op if a newer scan already ran
                NS.Debug:Log("Retry scan #" .. i .. " (gen " .. forGeneration .. ")")
                Scanner:DoScan()
            end
        end)
    end
end

local SAFETY_NET_INTERVAL = 10
local safetyNetTimer = nil

function Scanner:StartSafetyNet()
    if safetyNetTimer then return end
    safetyNetTimer = C_Timer.NewTicker(SAFETY_NET_INTERVAL, function()
        if not NS.initialized then return end
        if NS.MainWindow and NS.MainWindow:IsShown() and IsInGroup() then
            Scanner:PruneStaleGUIDs()
            Scanner:RevalidateAll()
            NS.Debug:Log("Safety-net revalidation tick")
            Scanner:QueueScan()
        end
    end)
    NS.Debug:Log("Safety-net timer started")
end

function Scanner:StopSafetyNet()
    if safetyNetTimer then
        safetyNetTimer:Cancel()
        safetyNetTimer = nil
        NS.Debug:Log("Safety-net timer stopped")
    end
end

function Scanner:RevalidateAll()
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local guid = API.GetUnitGUID(unit)
            if guid then
                awaitingInspectGUIDs[guid] = nil
                self:EnqueueInspect(unit, guid)
            end
        end
    end
end

local function StateChanged(newMembers, newCount)
    if newCount ~= State.memberCount then return true end
    for i = 1, newCount do
        local new = newMembers[i]
        local old = State.members[i]
        if not old then return true end
        if new.name ~= old.name then return true end
        if new.classFile ~= old.classFile then return true end
        if new.specID ~= old.specID then return true end
        if new.role ~= old.role then return true end
        if new.specPending ~= old.specPending then return true end
    end
    return false
end

local function InvalidateRoster()
    local currentGUIDs = {}
    if UnitExists("player") then
        currentGUIDs["player"] = UnitGUID("player")
    end
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            currentGUIDs[unit] = UnitGUID(unit)
        end
    end

    for unit, oldGUID in pairs(prevUnitGUIDs) do
        local newGUID = currentGUIDs[unit]
        if oldGUID and newGUID ~= oldGUID then
            resolvedSpecs[oldGUID] = nil
            awaitingInspectGUIDs[oldGUID] = nil
        end
    end

    local activeGUIDs = {}
    for _, guid in pairs(currentGUIDs) do
        if guid then activeGUIDs[guid] = true end
    end
    for guid in pairs(resolvedSpecs) do
        if not activeGUIDs[guid] then
            resolvedSpecs[guid] = nil
        end
    end
    for guid in pairs(awaitingInspectGUIDs) do
        if not activeGUIDs[guid] then
            awaitingInspectGUIDs[guid] = nil
        end
    end

    wipe(prevUnitGUIDs)
    for unit, guid in pairs(currentGUIDs) do
        prevUnitGUIDs[unit] = guid
    end
end

function Scanner:DoScan()
    scanGeneration = scanGeneration + 1
    local thisGen = scanGeneration

    CancelAllRetries()
    FlushInspectQueue()
    InvalidateRoster()

    local members = {}
    local memberCount = 0
    local hasIncomplete = false

    local playerData = self:ReadUnit("player")
    if playerData then
        memberCount = memberCount + 1
        members[memberCount] = playerData
    end

    -- 5-man only; not raid
    local groupSize = API.GetGroupSize()
    if groupSize > 1 and not IsInRaid() then
        for i = 1, math.min(groupSize - 1, 4) do
            local unit = "party" .. i
            if UnitExists(unit) then
                local data = self:ReadUnit(unit)
                if data then
                    memberCount = memberCount + 1
                    members[memberCount] = data
                    if not data.specID then
                        hasIncomplete = true
                    end
                end
            end
        end
    end

    -- Anti-collapse: party unit data is transiently unavailable during loading screens.
    -- Don't overwrite a full group state with a player-only snapshot.
    if memberCount <= 1 and State.memberCount > 1 and IsInGroup() then
        NS.Debug:Log("Anti-collapse: found only player while in group (gen", thisGen, "), scheduling retries")
        ScheduleRetries(thisGen)
        return
    end

    local changed = StateChanged(members, memberCount)

    if changed then
        State:Clear()
        for i = 1, memberCount do
            State:SetMember(i, members[i])
        end
        State.memberCount = memberCount

        State:ComputeRoleCounts()
        NS.CompEvaluator:Evaluate()

        State.dirty = true
        if NS.MainWindow and NS.MainWindow:IsShown() then
            NS.MainWindow:Refresh()
        end
    end

    self:ProcessInspectQueue()

    if hasIncomplete then
        ScheduleRetries(thisGen)
    end

    NS.Debug:Log("Scan gen", thisGen, ":", memberCount, "members,",
        hasIncomplete and "retries scheduled" or "all specs resolved",
        changed and "(state changed)" or "(no change)")
end

function Scanner:ReadUnit(unit)
    local classFile = API.GetUnitClass(unit)
    if not classFile then return nil end
    local name = API.GetUnitName(unit) or "Unknown"
    local role = API.GetUnitRole(unit)
    local specPending = false
    local guid = API.GetUnitGUID(unit)

    local specID = nil
    local specInfo = nil

    if UnitIsUnit(unit, "player") then
        specID = API.GetUnitSpecID(unit)
        specInfo = specID and CSD:EnsureSpec(specID) or nil
        if specID and guid then
            resolvedSpecs[guid] = specID
        end
    else
        if guid and resolvedSpecs[guid] then
            specID = resolvedSpecs[guid]
            specInfo = CSD:EnsureSpec(specID)
        end

        -- GetInspectSpecialization can return stale cross-class data after roster shuffles;
        -- validate the spec's class against the unit's actual class before trusting it.
        if not specInfo then
            local rawSpec = GetInspectSpecialization(unit)
            if rawSpec and rawSpec > 0 then
                local rawInfo = CSD:EnsureSpec(rawSpec, classFile)
                if rawInfo then
                    specID = rawSpec
                    specInfo = rawInfo
                    if guid then
                        resolvedSpecs[guid] = specID
                    end
                end
            end
        end

        if not specInfo then
            specPending = true
            if guid then
                self:EnqueueInspect(unit, guid)
            end
        end
    end

    -- Spec role is authoritative; group role assignment can lag or show "NONE"
    -- for freshly-invited members.
    if specInfo then
        role = specInfo.role
    end

    return {
        unit        = unit,
        guid        = guid,
        name        = name,
        classFile   = classFile,
        specID      = specID,
        role        = role or "NONE",
        specInfo    = specInfo,
        specPending = specPending,
    }
end

function Scanner:PruneStaleGUIDs()
    local activeGUIDs = {}
    activeGUIDs[API.GetUnitGUID("player") or ""] = true
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            activeGUIDs[API.GetUnitGUID(unit) or ""] = true
        end
    end

    for guid in pairs(awaitingInspectGUIDs) do
        if not activeGUIDs[guid] then
            awaitingInspectGUIDs[guid] = nil
        end
    end

    for guid in pairs(resolvedSpecs) do
        if not activeGUIDs[guid] then
            resolvedSpecs[guid] = nil
        end
    end
end
