------------------------------------------------------------------------
-- Core/SavedVariables.lua
-- Manages persistent settings in LFGMythicPlusDB.
-- Merges defaults on load. Includes a DB version for safe migration.
------------------------------------------------------------------------
local _, NS = ...

local SV = {}
NS.SavedVariables = SV

local DB_VERSION = 1

local DEFAULTS = {
    dbVersion       = DB_VERSION,

    -- Behavior
    showWarnings    = true,
}

------------------------------------------------------------------------
-- Merge defaults (one level deep)
------------------------------------------------------------------------
local function MergeDefaults(saved, defaults)
    for k, v in pairs(defaults) do
        if saved[k] == nil then
            saved[k] = v
        end
    end
end

------------------------------------------------------------------------
-- Migration: run once per version bump
------------------------------------------------------------------------
local function Migrate(db)
    -- Clean up legacy keys from earlier versions
    db.windowPoint    = nil
    db.windowRelPoint = nil
    db.windowX        = nil
    db.windowY        = nil
    db.windowWidth    = nil
    db.windowHeight   = nil
    db.locked         = nil

    db.dbVersion = DB_VERSION
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------
function SV:Initialize()
    if not LFGMythicPlusDB then
        LFGMythicPlusDB = {}
    end
    Migrate(LFGMythicPlusDB)
    MergeDefaults(LFGMythicPlusDB, DEFAULTS)
    NS.Debug:Log("SavedVariables initialized (v" .. DB_VERSION .. ")")
end

function SV:Get(key)
    return LFGMythicPlusDB and LFGMythicPlusDB[key]
end

function SV:Set(key, value)
    if LFGMythicPlusDB then
        LFGMythicPlusDB[key] = value
    end
end

function SV:Reset()
    LFGMythicPlusDB = {}
    MergeDefaults(LFGMythicPlusDB, DEFAULTS)
end
