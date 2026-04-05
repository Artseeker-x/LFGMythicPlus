------------------------------------------------------------------------
-- Data/ClassSpecData.lua
-- Static mapping of specID -> { class, spec name, role, icon }.
-- Fallback source of truth for retail specs. Init.lua updates icons and
-- discovers new specs (e.g. DH Devourer) from the live game client at
-- load time, so stale entries here are harmless — they get overwritten.
-- UtilityMatrix.lua references specIDs defined here.
------------------------------------------------------------------------
local _, NS = ...

local CSD = {}
NS.ClassSpecData = CSD

------------------------------------------------------------------------
-- Role icons (Blizzard atlas keys)
------------------------------------------------------------------------
CSD.ROLE_ICONS = {
    TANK    = "roleicon-tank",
    HEALER  = "roleicon-healer",
    DAMAGER = "roleicon-dps",
}

------------------------------------------------------------------------
-- specID -> static info
-- Fields: class (file token), name, role, icon (texture ID)
------------------------------------------------------------------------
CSD.Specs = {
    -- Death Knight
    [250]  = { class = "DEATHKNIGHT", name = "Blood",         role = "TANK",    icon = 135770 },
    [251]  = { class = "DEATHKNIGHT", name = "Frost",         role = "DAMAGER", icon = 135773 },
    [252]  = { class = "DEATHKNIGHT", name = "Unholy",        role = "DAMAGER", icon = 135775 },
    -- Demon Hunter
    [577]  = { class = "DEMONHUNTER", name = "Havoc",         role = "DAMAGER", icon = 1247264 },
    [581]  = { class = "DEMONHUNTER", name = "Vengeance",     role = "TANK",    icon = 1247265 },
    -- (Devourer is discovered at runtime by Init.lua's Phase 2 loop or
    --  by EnsureSpec when a player with that spec is first encountered.)
    -- Druid
    [102]  = { class = "DRUID",       name = "Balance",       role = "DAMAGER", icon = 136096 },
    [103]  = { class = "DRUID",       name = "Feral",         role = "DAMAGER", icon = 132115 },
    [104]  = { class = "DRUID",       name = "Guardian",      role = "TANK",    icon = 132276 },
    [105]  = { class = "DRUID",       name = "Restoration",   role = "HEALER",  icon = 136041 },
    -- Evoker
    [1467] = { class = "EVOKER",      name = "Devastation",   role = "DAMAGER", icon = 4511811 },
    [1468] = { class = "EVOKER",      name = "Preservation",  role = "HEALER",  icon = 4511812 },
    [1473] = { class = "EVOKER",      name = "Augmentation",  role = "DAMAGER", icon = 5198700 },
    -- Hunter
    [253]  = { class = "HUNTER",      name = "Beast Mastery", role = "DAMAGER", icon = 461112 },
    [254]  = { class = "HUNTER",      name = "Marksmanship",  role = "DAMAGER", icon = 236179 },
    [255]  = { class = "HUNTER",      name = "Survival",      role = "DAMAGER", icon = 461113 },
    -- Mage
    [62]   = { class = "MAGE",        name = "Arcane",        role = "DAMAGER", icon = 135932 },
    [63]   = { class = "MAGE",        name = "Fire",          role = "DAMAGER", icon = 135810 },
    [64]   = { class = "MAGE",        name = "Frost",         role = "DAMAGER", icon = 135846 },
    -- Monk
    [268]  = { class = "MONK",        name = "Brewmaster",    role = "TANK",    icon = 608951 },
    [270]  = { class = "MONK",        name = "Mistweaver",    role = "HEALER",  icon = 608952 },
    [269]  = { class = "MONK",        name = "Windwalker",    role = "DAMAGER", icon = 608953 },
    -- Paladin
    [65]   = { class = "PALADIN",     name = "Holy",          role = "HEALER",  icon = 135920 },
    [66]   = { class = "PALADIN",     name = "Protection",    role = "TANK",    icon = 236264 },
    [70]   = { class = "PALADIN",     name = "Retribution",   role = "DAMAGER", icon = 135873 },
    -- Priest
    [256]  = { class = "PRIEST",      name = "Discipline",    role = "HEALER",  icon = 135940 },
    [257]  = { class = "PRIEST",      name = "Holy",          role = "HEALER",  icon = 237542 },
    [258]  = { class = "PRIEST",      name = "Shadow",        role = "DAMAGER", icon = 136207 },
    -- Rogue
    [259]  = { class = "ROGUE",       name = "Assassination", role = "DAMAGER", icon = 236270 },
    [260]  = { class = "ROGUE",       name = "Outlaw",        role = "DAMAGER", icon = 236286 },
    [261]  = { class = "ROGUE",       name = "Subtlety",      role = "DAMAGER", icon = 132320 },
    -- Shaman
    [262]  = { class = "SHAMAN",      name = "Elemental",     role = "DAMAGER", icon = 136048 },
    [263]  = { class = "SHAMAN",      name = "Enhancement",   role = "DAMAGER", icon = 136051 },
    [264]  = { class = "SHAMAN",      name = "Restoration",   role = "HEALER",  icon = 136052 },
    -- Warlock
    [265]  = { class = "WARLOCK",     name = "Affliction",    role = "DAMAGER", icon = 136145 },
    [266]  = { class = "WARLOCK",     name = "Demonology",    role = "DAMAGER", icon = 136172 },
    [267]  = { class = "WARLOCK",     name = "Destruction",   role = "DAMAGER", icon = 136186 },
    -- Warrior
    [71]   = { class = "WARRIOR",     name = "Arms",          role = "DAMAGER", icon = 132355 },
    [72]   = { class = "WARRIOR",     name = "Fury",          role = "DAMAGER", icon = 132347 },
    [73]   = { class = "WARRIOR",     name = "Protection",    role = "TANK",    icon = 132341 },
}

------------------------------------------------------------------------
-- Class color table (Blizzard RAID_CLASS_COLORS is available at runtime
-- but we store fallback hex values for tooltip / string use)
------------------------------------------------------------------------
CSD.ClassColors = {
    DEATHKNIGHT = "C41E3A",
    DEMONHUNTER = "A330C9",
    DRUID       = "FF7C0A",
    EVOKER      = "33937F",
    HUNTER      = "AAD372",
    MAGE        = "3FC7EB",
    MONK        = "00FF98",
    PALADIN     = "F48CBA",
    PRIEST      = "FFFFFF",
    ROGUE       = "FFF468",
    SHAMAN      = "0070DD",
    WARLOCK     = "8788EE",
    WARRIOR     = "C69B6D",
}

------------------------------------------------------------------------
-- Class token comparison.
-- Handles the DEMONHUNTER vs DEMON_HUNTER (and similar) edge case
-- where different Blizzard APIs may return different formatting for the
-- same class. Strips underscores before comparing.
------------------------------------------------------------------------
local function ClassMatch(a, b)
    if a == b then return true end
    if not a or not b then return false end
    return a:gsub("_", "") == b:gsub("_", "")
end

CSD.ClassMatch = ClassMatch  -- exposed for tests, not for general use

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------
function CSD:GetSpecInfo(specID)
    return self.Specs[specID]
end

function CSD:GetClassColor(classFile)
    if self.ClassColors[classFile] then
        return self.ClassColors[classFile]
    end
    -- Fallback: try without underscores (DEMON_HUNTER -> DEMONHUNTER)
    local stripped = classFile and classFile:gsub("_", "") or nil
    if stripped and self.ClassColors[stripped] then
        return self.ClassColors[stripped]
    end
    return "CCCCCC"
end

------------------------------------------------------------------------
-- Runtime spec discovery.
-- When the addon encounters a specID not in the static table (e.g. the
-- new DH Devourer spec), this resolves it from the live game API, adds
-- it to CSD.Specs, seeds the UtilityMatrix with class-level guaranteed
-- utilities, and ensures ClassColors has an entry.
--
-- If expectedClassFile is provided, the spec must belong to that class
-- or nil is returned (prevents accepting stale cross-class inspect data).
------------------------------------------------------------------------
function CSD:EnsureSpec(specID, expectedClassFile)
    local info = self.Specs[specID]
    if info then
        -- Existing entry: validate class if requested
        if expectedClassFile and not ClassMatch(info.class, expectedClassFile) then
            return nil
        end
        return info
    end

    -- Not in static data — try to resolve from the game API
    if not GetSpecializationInfoByID then return nil end

    local a, b, _, d, e, f = GetSpecializationInfoByID(specID)
    local sName, sIcon, sRole, sClassFile
    if type(a) == "table" then
        -- Struct return (some 12.0+ API versions)
        sName      = a.name or a.specName
        sIcon      = a.iconID or a.icon
        sRole      = a.role
        sClassFile = a.classFile or a.classFilename
    else
        -- Multi-return: id, name, description, icon, role, classFile
        sName      = b
        sIcon      = d
        sRole      = e
        sClassFile = f
    end

    if not sClassFile then return nil end
    if expectedClassFile and not ClassMatch(sClassFile, expectedClassFile) then
        return nil
    end

    -- Create the spec entry
    self.Specs[specID] = {
        class = sClassFile,
        name  = sName or ("Spec " .. specID),
        role  = sRole or "DAMAGER",
        icon  = (sIcon and sIcon ~= 0) and sIcon or 0,
    }

    -- Ensure ClassColors has an entry for this class token
    if not self.ClassColors[sClassFile] then
        local rc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[sClassFile]
        if rc then
            self.ClassColors[sClassFile] = string.format(
                "%02X%02X%02X",
                math.floor(rc.r * 255),
                math.floor(rc.g * 255),
                math.floor(rc.b * 255)
            )
        end
    end

    -- Seed UtilityMatrix with class-level guaranteed utilities
    local UM = NS.UtilityMatrix
    if UM and not UM.Matrix[specID] then
        local seed = self:BuildClassUtilitySeed(sClassFile, specID)
        if seed then
            UM.Matrix[specID] = seed
            UM.ClassUtilities = nil
        end
    end

    NS.Debug:Log("Discovered spec", specID, sName, sClassFile, "at runtime")
    return self.Specs[specID]
end

------------------------------------------------------------------------
-- Compute the intersection of all UM.Matrix entries for a given class.
-- Returns a table of utility keys that EVERY known spec of the class
-- provides, or nil if empty. Used to seed UM.Matrix for new specs.
------------------------------------------------------------------------
function CSD:BuildClassUtilitySeed(classFile, excludeSpecID)
    local UM = NS.UtilityMatrix
    if not UM or not UM.Matrix then return nil end

    local common, started = {}, false
    for sid, si in pairs(self.Specs) do
        if ClassMatch(si.class, classFile) and sid ~= excludeSpecID and UM.Matrix[sid] then
            if not started then
                for k in pairs(UM.Matrix[sid]) do common[k] = true end
                started = true
            else
                for k in pairs(common) do
                    if not UM.Matrix[sid][k] then common[k] = nil end
                end
            end
        end
    end

    for _ in pairs(common) do return common end
    return nil
end
