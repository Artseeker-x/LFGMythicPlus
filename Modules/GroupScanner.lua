------------------------------------------------------------------------
-- Modules/GroupScanner.lua
--
-- Hardened party roster + specialization pipeline.
--
-- Design principles:
--   1. ONE entry point: QueueScan(). Every event funnels here.
--   2. ONE authoritative snapshot: DoScan() always reads the full
--      current roster from scratch. No inline partial mutations.
--   3. GUID-keyed spec cache: resolvedSpecs[guid] stores confirmed
--      specIDs, immune to unit-token reassignment after roster shuffles.
--      GetInspectSpecialization(unit) is only used as a fallback with
--      class validation, never blindly trusted.
--   4. Serialized inspect queue: WoW supports only one in-flight
--      NotifyInspect at a time. We queue requests and process them
--      one by one, with a timeout for dropped responses.
--   5. Staged retry: if any member's spec is unavailable, schedule
--      follow-up scans at increasing intervals.
--   6. Generation counter: every DoScan increments a generation.
--      Timers check the generation before firing and become no-ops
--      if a newer scan already ran. Prevents stale timer cascades.
--   7. INSPECT_READY stores the confirmed spec in resolvedSpecs
--      before triggering a rescan, so the next DoScan picks it up
--      without re-reading the (potentially stale) inspect cache.
--   8. Safety-net timer: low-frequency periodic revalidation while
--      the window is visible and a party exists, as last-resort
--      recovery for any missed events. Also re-inspects all members
--      to catch remote spec changes.
--   9. State-diff: skip UI refresh when scan results are identical
--      to current state, avoiding unnecessary redraws.
--  10. Anti-collapse: refuse to overwrite full party state with
--      player-only data when we believe we're still in a group.
--  11. Roster invalidation: detect GUID changes per unit slot and
--      clear stale cache entries so stale specs can never persist.
------------------------------------------------------------------------
local _, NS = ...

local Scanner = {}
NS.GroupScanner = Scanner

local API   = NS.API
local State = NS.State
local CSD   = NS.ClassSpecData

------------------------------------------------------------------------
-- Scan generation — incremented on every DoScan. Used to expire
-- stale retry timers so they don't overwrite newer state.
------------------------------------------------------------------------
local scanGeneration = 0

------------------------------------------------------------------------
-- Throttle: coalesce rapid events into a single scan next frame.
-- Multiple events in the same frame produce exactly one DoScan.
------------------------------------------------------------------------
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

------------------------------------------------------------------------
-- GUID-keyed spec cache.
-- Unlike GetInspectSpecialization (which is keyed by unit token and can
-- return stale data after roster shuffles), this cache is keyed by GUID
-- and is only populated from confirmed inspect results or class-
-- validated GetInspectSpecialization reads.
------------------------------------------------------------------------
local resolvedSpecs = {} -- [guid] = specID

------------------------------------------------------------------------
-- Track previous unit -> GUID mapping to detect roster shuffles.
-- When a unit token's GUID changes, we know the old cached data is
-- stale and must be discarded.
------------------------------------------------------------------------
local prevUnitGUIDs = {} -- [unit] = guid

------------------------------------------------------------------------
-- Serialized inspect queue.
-- WoW only supports one in-flight NotifyInspect at a time. Sending
-- a second before INSPECT_READY arrives silently cancels the first.
-- This queue ensures each party member actually gets inspected.
------------------------------------------------------------------------
local inspectQueue = {}      -- array of {unit=, guid=}
local inspectBusy = false    -- true while waiting for INSPECT_READY
local inspectBusyGUID = nil  -- GUID of current in-flight inspect
local inspectTimeoutTimer = nil
local INSPECT_TIMEOUT = 5    -- seconds before giving up on an inspect

local awaitingInspectGUIDs = {} -- [guid] = true, GUIDs queued or in-flight

------------------------------------------------------------------------
-- EnqueueInspect: add a unit to the serialized inspect queue.
-- Safe to call multiple times — skips if the GUID is already tracked.
------------------------------------------------------------------------
function Scanner:EnqueueInspect(unit, guid)
    if not guid then return end
    if awaitingInspectGUIDs[guid] then return end

    awaitingInspectGUIDs[guid] = true
    table.insert(inspectQueue, { unit = unit, guid = guid })

    if not inspectBusy then
        self:ProcessInspectQueue()
    end
end

------------------------------------------------------------------------
-- ProcessInspectQueue: send the next NotifyInspect.
-- Processes entries one at a time, advancing on success or skip.
------------------------------------------------------------------------
function Scanner:ProcessInspectQueue()
    if inspectBusy then return end

    while #inspectQueue > 0 do
        local entry = table.remove(inspectQueue, 1)
        local unit = entry.unit
        local guid = entry.guid

        -- Validate unit still exists with the expected GUID
        if UnitExists(unit) and API.GetUnitGUID(unit) == guid then
            ClearInspectPlayer()
            local sent = API.RequestInspect(unit)
            if sent then
                inspectBusy = true
                inspectBusyGUID = guid
                -- Timeout: if INSPECT_READY never arrives, move on
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
                return -- wait for INSPECT_READY
            end
        end

        -- Couldn't inspect (unit gone, not visible, etc.) — skip
        awaitingInspectGUIDs[guid] = nil
    end
end

------------------------------------------------------------------------
-- FlushInspectQueue: cancel all pending inspects.
-- Called at the start of each DoScan to rebuild from scratch.
------------------------------------------------------------------------
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

------------------------------------------------------------------------
-- GUIDToUnit: find which unit token a GUID currently maps to.
------------------------------------------------------------------------
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

------------------------------------------------------------------------
-- INSPECT_READY handler.
-- Reads the fresh spec from the inspect cache, stores it in our
-- GUID-keyed cache, advances the queue, and triggers a rescan.
------------------------------------------------------------------------
function Scanner:OnInspectDataAvailable(guid)
    if not guid then return end

    -- Cancel timeout if this was our in-flight inspect
    local wasOurInspect = (inspectBusyGUID == guid)
    if wasOurInspect then
        if inspectTimeoutTimer then
            inspectTimeoutTimer:Cancel()
            inspectTimeoutTimer = nil
        end
        inspectBusy = false
        inspectBusyGUID = nil
    end

    -- Read the spec while inspect data is fresh
    local unit = GUIDToUnit(guid)
    if unit and not UnitIsUnit(unit, "player") then
        local specID = GetInspectSpecialization(unit)
        if specID and specID > 0 then
            -- EnsureSpec validates class match (handles token variants)
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

    -- Process next queued inspect
    if wasOurInspect then
        self:ProcessInspectQueue()
    end

    -- Rescan to update UI with new spec data
    self:QueueScan()
end

------------------------------------------------------------------------
-- Retry schedule for missing specs.
-- After a scan with incomplete data, we schedule follow-up scans.
-- Each retry is a full DoScan (cheap for ≤5 units).
-- Intervals: 0.5s, 1.5s, 4s, 8s — covers the common latency windows
-- for inspect data and party member data propagation.
------------------------------------------------------------------------
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
            -- Only fire if no newer scan has happened since we were scheduled
            if scanGeneration == forGeneration then
                NS.Debug:Log("Retry scan #" .. i .. " (gen " .. forGeneration .. ")")
                Scanner:DoScan()
            end
        end)
    end
end

------------------------------------------------------------------------
-- Safety-net timer: periodic revalidation as last-resort recovery.
-- Runs every 10s while the main window is shown and we're in a party.
-- Each tick re-inspects all party members (catches remote spec changes)
-- and triggers a rescan.
------------------------------------------------------------------------
local SAFETY_NET_INTERVAL = 10
local safetyNetTimer = nil

function Scanner:StartSafetyNet()
    if safetyNetTimer then return end
    safetyNetTimer = C_Timer.NewTicker(SAFETY_NET_INTERVAL, function()
        if not NS.initialized then return end
        -- Only revalidate if window is visible and we're in a group
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

------------------------------------------------------------------------
-- RevalidateAll: re-inspect all party members to catch spec changes
-- that happened without a corresponding event (e.g., remote player
-- swapped spec). Called by the safety-net timer every 10s.
------------------------------------------------------------------------
function Scanner:RevalidateAll()
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local guid = API.GetUnitGUID(unit)
            if guid then
                -- Allow re-inspect even if we have cached data
                awaitingInspectGUIDs[guid] = nil
                self:EnqueueInspect(unit, guid)
            end
        end
    end
end

------------------------------------------------------------------------
-- State-diff: compare new scan results against current state.
-- Returns true if anything changed (member count, names, specs, roles).
------------------------------------------------------------------------
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

------------------------------------------------------------------------
-- InvalidateRoster: detect GUID changes per unit slot and clean up
-- stale cache entries. Called at the start of each DoScan.
--
-- When a player leaves or slots shuffle, the GUID at a unit token
-- changes. We must discard cached specs for old GUIDs (they belonged
-- to different players) and for GUIDs no longer in the party.
------------------------------------------------------------------------
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

    -- Detect GUID changes per unit slot (roster shuffle)
    for unit, oldGUID in pairs(prevUnitGUIDs) do
        local newGUID = currentGUIDs[unit]
        if oldGUID and newGUID ~= oldGUID then
            -- Different player now occupies this unit slot
            resolvedSpecs[oldGUID] = nil
            awaitingInspectGUIDs[oldGUID] = nil
        end
    end

    -- Remove cache entries for GUIDs no longer in the party
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

    -- Update tracking for next comparison
    wipe(prevUnitGUIDs)
    for unit, guid in pairs(currentGUIDs) do
        prevUnitGUIDs[unit] = guid
    end
end

------------------------------------------------------------------------
-- DoScan: the single authoritative roster snapshot.
--
-- Flow:
--   1. Increment generation (invalidates all pending retries)
--   2. Flush inspect queue (rebuilt by ReadUnit calls below)
--   3. Invalidate stale GUID entries from roster changes
--   4. Read every current party unit from scratch
--   5. For each unit: read class, name, role, spec from GUID cache
--   6. If spec unavailable: enqueue for serialized inspect
--   7. Anti-collapse: if only player found while in group, retry
--   8. Compare with current state — skip UI refresh if identical
--   9. Replace State atomically
--  10. Evaluate utilities + buffs
--  11. Refresh UI
--  12. Start processing inspect queue
--  13. If any specs missing: schedule staged retries
------------------------------------------------------------------------
function Scanner:DoScan()
    scanGeneration = scanGeneration + 1
    local thisGen = scanGeneration

    -- Cancel retries from previous generation
    CancelAllRetries()

    -- Flush inspect queue — ReadUnit calls below will rebuild it
    FlushInspectQueue()

    -- Detect roster changes and invalidate stale cache entries
    InvalidateRoster()

    -- Gather current roster
    local members = {}
    local memberCount = 0
    local hasIncomplete = false

    -- Always include the player as first member
    local playerData = self:ReadUnit("player")
    if playerData then
        memberCount = memberCount + 1
        members[memberCount] = playerData
    end

    -- Party members (5-man only, not raid)
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

    -- Anti-collapse protection:
    -- If we found only the player but we're supposed to be in a group,
    -- the party unit data is temporarily unavailable (loading screen,
    -- transient state). Do NOT overwrite a richer state with a degraded
    -- one. Instead, schedule retries and let a future scan pick up the
    -- real roster.
    if memberCount <= 1 and State.memberCount > 1 and IsInGroup() then
        NS.Debug:Log("Anti-collapse: found only player while in group (gen", thisGen, "), scheduling retries")
        ScheduleRetries(thisGen)
        return
    end

    -- State-diff: skip expensive UI work if nothing changed
    local changed = StateChanged(members, memberCount)

    if changed then
        -- Atomic state replacement — wipe old state, write new
        State:Clear()
        for i = 1, memberCount do
            State:SetMember(i, members[i])
        end
        State.memberCount = memberCount

        -- Compute derived state
        State:ComputeRoleCounts()
        NS.CompEvaluator:Evaluate()

        -- Refresh UI
        State.dirty = true
        if NS.MainWindow and NS.MainWindow:IsShown() then
            NS.MainWindow:Refresh()
        end
    end

    -- Start processing the inspect queue built by ReadUnit calls
    self:ProcessInspectQueue()

    -- If any members are missing spec data, schedule retry scans
    if hasIncomplete then
        ScheduleRetries(thisGen)
    end

    NS.Debug:Log("Scan gen", thisGen, ":", memberCount, "members,",
        hasIncomplete and "retries scheduled" or "all specs resolved",
        changed and "(state changed)" or "(no change)")
end

------------------------------------------------------------------------
-- ReadUnit: read all available data for a single unit.
-- Returns a member table, or nil if the unit is invalid.
-- Does NOT mutate shared state — only reads and enqueues inspects.
------------------------------------------------------------------------
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
        -- Player: authoritative local API, always reliable
        specID = API.GetUnitSpecID(unit)
        specInfo = specID and CSD:EnsureSpec(specID) or nil
        -- Also store in GUID cache for consistency
        if specID and guid then
            resolvedSpecs[guid] = specID
        end
    else
        -- Party member: check our GUID-keyed cache first.
        -- This cache is immune to unit-token reassignment after roster shuffles.
        if guid and resolvedSpecs[guid] then
            specID = resolvedSpecs[guid]
            specInfo = CSD:EnsureSpec(specID)
        end

        -- Fallback: try GetInspectSpecialization, but only accept it if
        -- the returned spec's class matches the unit's actual class.
        -- This catches cross-class stale data (e.g., Mage spec on a Paladin).
        if not specInfo then
            local rawSpec = GetInspectSpecialization(unit)
            if rawSpec and rawSpec > 0 then
                local rawInfo = CSD:EnsureSpec(rawSpec, classFile)
                if rawInfo then
                    specID = rawSpec
                    specInfo = rawInfo
                    -- Store in our GUID-keyed cache
                    if guid then
                        resolvedSpecs[guid] = specID
                    end
                end
                -- Class mismatch: stale data from a previous player, ignore it
            end
        end

        -- Still no spec: queue for serialized inspect
        if not specInfo then
            specPending = true
            if guid then
                self:EnqueueInspect(unit, guid)
            end
        end
    end

    -- Authoritative role from spec data (overrides group role assignment
    -- which can lag behind or be "NONE" for freshly-invited members)
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

------------------------------------------------------------------------
-- Cleanup: remove stale GUIDs from tracking tables that no longer
-- match any current party member. Called periodically by the safety net.
------------------------------------------------------------------------
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
