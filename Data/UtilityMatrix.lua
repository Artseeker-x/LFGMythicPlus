------------------------------------------------------------------------
-- Data/UtilityMatrix.lua
-- Maps specID -> set of utility + raid buff keys that spec provides.
-- THE central data file for group composition evaluation.
-- When Blizzard changes abilities, update this file only.
--
-- Tracks two categories:
--   1. Utilities: active abilities (brez, lust, kick, stun, dispel, soothe)
--   2. Raid buffs: passive group-wide buffs from classes (matches TierCraft)
------------------------------------------------------------------------
local _, NS = ...

local C = NS.CONSTANTS

local UM = {}
NS.UtilityMatrix = UM

------------------------------------------------------------------------
-- specID -> { [KEY] = true, ... }
--
-- Every spec lists both its utilities (baseline, non-talent) AND its
-- class-wide raid buff. This keeps the data model flat and simple:
-- one lookup per spec gives everything that spec brings to the group.
--
-- Utility key reference:
--   BREZ, BLOODLUST, INTERRUPT, STUN, DISPEL, SOOTHE
--
-- Raid buff key reference (class-wide, every spec of the class has it):
--   ARCANE_INTELLECT (Mage), BATTLE_SHOUT (Warrior),
--   FORTITUDE (Priest), MARK_OF_THE_WILD (Druid),
--   MYSTIC_TOUCH (Monk), CHAOS_BRAND (DH),
--   HUNTERS_MARK (Hunter), DEVOTION_AURA (Paladin),
--   SKYFURY (Shaman), BLESSING_OF_THE_BRONZE (Evoker),
--   ATROPHIC_POISON (Rogue)
------------------------------------------------------------------------

UM.Matrix = {
    -- Death Knight (all specs: interrupt, brez, stun — no raid buff)
    [250]  = { [C.UTIL_BREZ] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true },
    [251]  = { [C.UTIL_BREZ] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true },
    [252]  = { [C.UTIL_BREZ] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true },

    -- Demon Hunter (chaos brand)
    [577]  = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_CHAOS_BRAND] = true },
    [581]  = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_CHAOS_BRAND] = true },

    -- Druid (mark of the wild)
    [102]  = { [C.UTIL_BREZ] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_DISPEL] = true, [C.UTIL_SOOTHE] = true, [C.BUFF_MARK_OF_THE_WILD] = true },
    [103]  = { [C.UTIL_BREZ] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_SOOTHE] = true, [C.BUFF_MARK_OF_THE_WILD] = true },
    [104]  = { [C.UTIL_BREZ] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.UTIL_SOOTHE] = true, [C.BUFF_MARK_OF_THE_WILD] = true },
    [105]  = { [C.UTIL_BREZ] = true, [C.UTIL_DISPEL] = true, [C.UTIL_SOOTHE] = true, [C.BUFF_MARK_OF_THE_WILD] = true },

    -- Evoker (blessing of the bronze)
    [1467] = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_DISPEL] = true, [C.BUFF_BLESSING_OF_THE_BRONZE] = true },
    [1468] = { [C.UTIL_BLOODLUST] = true, [C.UTIL_DISPEL] = true, [C.BUFF_BLESSING_OF_THE_BRONZE] = true },
    [1473] = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_DISPEL] = true, [C.BUFF_BLESSING_OF_THE_BRONZE] = true },

    -- Hunter (hunter's mark, bloodlust via pet, soothe via Tranq Shot)
    [253]  = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_SOOTHE] = true, [C.BUFF_HUNTERS_MARK] = true },
    [254]  = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_SOOTHE] = true, [C.BUFF_HUNTERS_MARK] = true },
    [255]  = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_SOOTHE] = true, [C.BUFF_HUNTERS_MARK] = true },

    -- Mage (arcane intellect)
    [62]   = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_DISPEL] = true, [C.BUFF_ARCANE_INTELLECT] = true },
    [63]   = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_DISPEL] = true, [C.BUFF_ARCANE_INTELLECT] = true },
    [64]   = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_DISPEL] = true, [C.BUFF_ARCANE_INTELLECT] = true },

    -- Monk (mystic touch)
    [268]  = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_MYSTIC_TOUCH] = true },
    [270]  = { [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_MYSTIC_TOUCH] = true },
    [269]  = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_MYSTIC_TOUCH] = true },

    -- Paladin (devotion aura)
    [65]   = { [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_DEVOTION_AURA] = true },
    [66]   = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_DEVOTION_AURA] = true },
    [70]   = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_DEVOTION_AURA] = true },

    -- Priest (power word: fortitude)
    [256]  = { [C.UTIL_DISPEL] = true, [C.BUFF_FORTITUDE] = true },
    [257]  = { [C.UTIL_DISPEL] = true, [C.BUFF_FORTITUDE] = true },
    [258]  = { [C.UTIL_INTERRUPT] = true, [C.UTIL_DISPEL] = true, [C.BUFF_FORTITUDE] = true },

    -- Rogue (atrophic poison)
    [259]  = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.BUFF_ATROPHIC_POISON] = true },
    [260]  = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.BUFF_ATROPHIC_POISON] = true },
    [261]  = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.BUFF_ATROPHIC_POISON] = true },

    -- Shaman (skyfury)
    [262]  = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_SKYFURY] = true },
    [263]  = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_SKYFURY] = true },
    [264]  = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_SKYFURY] = true },

    -- Warlock (brez via Soulstone — no raid buff)
    [265]  = { [C.UTIL_BREZ] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true },
    [266]  = { [C.UTIL_BREZ] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true },
    [267]  = { [C.UTIL_BREZ] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true },

    -- Warrior (battle shout)
    [71]   = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.BUFF_BATTLE_SHOUT] = true },
    [72]   = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.BUFF_BATTLE_SHOUT] = true },
    [73]   = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.BUFF_BATTLE_SHOUT] = true },
}

------------------------------------------------------------------------
-- Lookup helpers
------------------------------------------------------------------------
function UM:GetUtilities(specID)
    return self.Matrix[specID] or {}
end

function UM:HasUtility(specID, utilKey)
    local m = self.Matrix[specID]
    return m and m[utilKey] or false
end

------------------------------------------------------------------------
-- Class-level guaranteed coverage: the intersection of all specs'
-- keys for a given class. Used as fallback when spec is unknown.
-- Computed lazily and cached.
------------------------------------------------------------------------
UM.ClassUtilities = nil -- built on first call

function UM:GetClassUtilities(classFile)
    if not self.ClassUtilities then
        self:BuildClassUtilities()
    end
    return self.ClassUtilities[classFile]
end

function UM:BuildClassUtilities()
    local CSD = NS.ClassSpecData
    -- Group specIDs by class
    local classBuckets = {} -- classFile -> { specID, ... }
    for specID, info in pairs(CSD.Specs) do
        local cls = info.class
        if not classBuckets[cls] then
            classBuckets[cls] = {}
        end
        table.insert(classBuckets[cls], specID)
    end

    -- For each class, intersect coverage sets across all specs
    self.ClassUtilities = {}
    for cls, specIDs in pairs(classBuckets) do
        if #specIDs > 0 then
            -- Start with a copy of the first spec's keys
            local common = {}
            local first = self.Matrix[specIDs[1]] or {}
            for k in pairs(first) do
                common[k] = true
            end
            -- Intersect with remaining specs
            for i = 2, #specIDs do
                local utils = self.Matrix[specIDs[i]] or {}
                for k in pairs(common) do
                    if not utils[k] then
                        common[k] = nil
                    end
                end
            end
            -- Only store if non-empty
            local hasAny = false
            for _ in pairs(common) do hasAny = true; break end
            if hasAny then
                self.ClassUtilities[cls] = common
            end
        end
    end
end
