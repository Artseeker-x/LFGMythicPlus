local _, NS = ...

local C = NS.CONSTANTS

local UM = {}
NS.UtilityMatrix = UM

UM.Matrix = {
    -- Death Knight
    [250]  = { [C.UTIL_BREZ] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true },
    [251]  = { [C.UTIL_BREZ] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true },
    [252]  = { [C.UTIL_BREZ] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true },

    -- Demon Hunter
    [577]  = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_CHAOS_BRAND] = true },
    [581]  = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_CHAOS_BRAND] = true },

    -- Druid
    [102]  = { [C.UTIL_BREZ] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_DISPEL] = true, [C.UTIL_SOOTHE] = true, [C.BUFF_MARK_OF_THE_WILD] = true },
    [103]  = { [C.UTIL_BREZ] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_SOOTHE] = true, [C.BUFF_MARK_OF_THE_WILD] = true },
    [104]  = { [C.UTIL_BREZ] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.UTIL_SOOTHE] = true, [C.BUFF_MARK_OF_THE_WILD] = true },
    [105]  = { [C.UTIL_BREZ] = true, [C.UTIL_DISPEL] = true, [C.UTIL_SOOTHE] = true, [C.BUFF_MARK_OF_THE_WILD] = true },

    -- Evoker
    [1467] = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_DISPEL] = true, [C.BUFF_BLESSING_OF_THE_BRONZE] = true },
    [1468] = { [C.UTIL_BLOODLUST] = true, [C.UTIL_DISPEL] = true, [C.BUFF_BLESSING_OF_THE_BRONZE] = true },
    [1473] = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_DISPEL] = true, [C.BUFF_BLESSING_OF_THE_BRONZE] = true },

    -- Hunter
    [253]  = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_SOOTHE] = true, [C.BUFF_HUNTERS_MARK] = true },
    [254]  = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_SOOTHE] = true, [C.BUFF_HUNTERS_MARK] = true },
    [255]  = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_SOOTHE] = true, [C.BUFF_HUNTERS_MARK] = true },

    -- Mage
    [62]   = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_DISPEL] = true, [C.BUFF_ARCANE_INTELLECT] = true },
    [63]   = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_DISPEL] = true, [C.BUFF_ARCANE_INTELLECT] = true },
    [64]   = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_DISPEL] = true, [C.BUFF_ARCANE_INTELLECT] = true },

    -- Monk
    [268]  = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_MYSTIC_TOUCH] = true },
    [270]  = { [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_MYSTIC_TOUCH] = true },
    [269]  = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_MYSTIC_TOUCH] = true },

    -- Paladin
    [65]   = { [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_DEVOTION_AURA] = true },
    [66]   = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_DEVOTION_AURA] = true },
    [70]   = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_DEVOTION_AURA] = true },

    -- Priest
    [256]  = { [C.UTIL_DISPEL] = true, [C.BUFF_FORTITUDE] = true },
    [257]  = { [C.UTIL_DISPEL] = true, [C.BUFF_FORTITUDE] = true },
    [258]  = { [C.UTIL_INTERRUPT] = true, [C.UTIL_DISPEL] = true, [C.BUFF_FORTITUDE] = true },

    -- Rogue
    [259]  = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.BUFF_ATROPHIC_POISON] = true },
    [260]  = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.BUFF_ATROPHIC_POISON] = true },
    [261]  = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.BUFF_ATROPHIC_POISON] = true },

    -- Shaman
    [262]  = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_SKYFURY] = true },
    [263]  = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_SKYFURY] = true },
    [264]  = { [C.UTIL_BLOODLUST] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.UTIL_DISPEL] = true, [C.BUFF_SKYFURY] = true },

    -- Warlock
    [265]  = { [C.UTIL_BREZ] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true },
    [266]  = { [C.UTIL_BREZ] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true },
    [267]  = { [C.UTIL_BREZ] = true, [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true },

    -- Warrior
    [71]   = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.BUFF_BATTLE_SHOUT] = true },
    [72]   = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.BUFF_BATTLE_SHOUT] = true },
    [73]   = { [C.UTIL_INTERRUPT] = true, [C.UTIL_STUN] = true, [C.BUFF_BATTLE_SHOUT] = true },
}

function UM:GetUtilities(specID)
    return self.Matrix[specID] or {}
end

function UM:HasUtility(specID, utilKey)
    local m = self.Matrix[specID]
    return m and m[utilKey] or false
end

UM.ClassUtilities = nil -- built on first call

function UM:GetClassUtilities(classFile)
    if not self.ClassUtilities then
        self:BuildClassUtilities()
    end
    return self.ClassUtilities[classFile]
end

function UM:BuildClassUtilities()
    local CSD = NS.ClassSpecData
    local classBuckets = {}
    for specID, info in pairs(CSD.Specs) do
        local cls = info.class
        if not classBuckets[cls] then
            classBuckets[cls] = {}
        end
        table.insert(classBuckets[cls], specID)
    end

    self.ClassUtilities = {}
    for cls, specIDs in pairs(classBuckets) do
        if #specIDs > 0 then
            local common = {}
            local first = self.Matrix[specIDs[1]] or {}
            for k in pairs(first) do
                common[k] = true
            end
            for i = 2, #specIDs do
                local utils = self.Matrix[specIDs[i]] or {}
                for k in pairs(common) do
                    if not utils[k] then
                        common[k] = nil
                    end
                end
            end
            local hasAny = false
            for _ in pairs(common) do hasAny = true; break end
            if hasAny then
                self.ClassUtilities[cls] = common
            end
        end
    end
end
