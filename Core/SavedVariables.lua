local _, NS = ...

local SV = {}
NS.SavedVariables = SV

local DB_VERSION = 1

local DEFAULTS = {
    dbVersion    = DB_VERSION,
    showWarnings = true,
}

local function MergeDefaults(saved, defaults)
    for k, v in pairs(defaults) do
        if saved[k] == nil then
            saved[k] = v
        end
    end
end

local function Migrate(db)
    db.windowPoint    = nil
    db.windowRelPoint = nil
    db.windowX        = nil
    db.windowY        = nil
    db.windowWidth    = nil
    db.windowHeight   = nil
    db.locked         = nil
    db.dbVersion = DB_VERSION
end

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
