------------------------------------------------------------------------
-- Utils/Constants.lua
-- Addon-wide constants: sizing, colors, enums, string keys.
-- No dependencies. Loaded first so every other file can reference these.
------------------------------------------------------------------------
local ADDON_NAME, NS = ...

NS.CONSTANTS = {
    -- Addon identity
    ADDON_NAME     = ADDON_NAME,
    ADDON_VERSION  = "1.0.2",

    -- Role keys (match Blizzard role strings)
    ROLE_TANK    = "TANK",
    ROLE_HEALER  = "HEALER",
    ROLE_DAMAGER = "DAMAGER",
    ROLE_NONE    = "NONE",

    --------------------------------------------------------------------
    -- Utility category keys (active abilities the player uses)
    --------------------------------------------------------------------
    UTIL_BREZ       = "BREZ",
    UTIL_BLOODLUST  = "BLOODLUST",
    UTIL_INTERRUPT   = "INTERRUPT",
    UTIL_STUN        = "STUN",
    UTIL_DISPEL      = "DISPEL",
    UTIL_SOOTHE      = "SOOTHE",

    -- Display order for utility rows
    UTILITY_ORDER = {
        "BREZ",
        "BLOODLUST",
        "INTERRUPT",
        "STUN",
        "DISPEL",
        "SOOTHE",
    },

    -- Human-readable labels
    UTILITY_LABELS = {
        BREZ       = "Battle Res",
        BLOODLUST  = "Bloodlust",
        INTERRUPT  = "Interrupt",
        STUN       = "Stun",
        DISPEL     = "Dispel",
        SOOTHE     = "Soothe",
    },

    -- Representative icon textures (Blizzard file data IDs)
    UTILITY_ICONS = {
        BREZ       = 136080,  -- Spell_Nature_Reincarnation
        BLOODLUST  = 135791,  -- Spell_Nature_BloodLust
        INTERRUPT  = 132938,  -- ability_kick
        STUN       = 132357,  -- Spell_Holy_SealOfMight
        DISPEL     = 135894,  -- Spell_Nature_NullifyDisease
        SOOTHE     = 132163,  -- ability_druid_cower
    },

    --------------------------------------------------------------------
    -- Raid buff category keys (passive group-wide buffs from classes)
    -- Matches TierCraft's tracked buff set for M+ compositions.
    --------------------------------------------------------------------
    BUFF_ARCANE_INTELLECT       = "ARCANE_INTELLECT",
    BUFF_BATTLE_SHOUT           = "BATTLE_SHOUT",
    BUFF_FORTITUDE              = "FORTITUDE",
    BUFF_MARK_OF_THE_WILD       = "MARK_OF_THE_WILD",
    BUFF_MYSTIC_TOUCH           = "MYSTIC_TOUCH",
    BUFF_CHAOS_BRAND            = "CHAOS_BRAND",
    BUFF_HUNTERS_MARK           = "HUNTERS_MARK",
    BUFF_DEVOTION_AURA          = "DEVOTION_AURA",
    BUFF_SKYFURY                = "SKYFURY",
    BUFF_BLESSING_OF_THE_BRONZE = "BLESSING_OF_THE_BRONZE",
    BUFF_ATROPHIC_POISON        = "ATROPHIC_POISON",

    BUFF_ORDER = {
        "ARCANE_INTELLECT",
        "BATTLE_SHOUT",
        "FORTITUDE",
        "MARK_OF_THE_WILD",
        "MYSTIC_TOUCH",
        "CHAOS_BRAND",
        "HUNTERS_MARK",
        "DEVOTION_AURA",
        "SKYFURY",
        "BLESSING_OF_THE_BRONZE",
        "ATROPHIC_POISON",
    },

    BUFF_LABELS = {
        ARCANE_INTELLECT       = "Arcane Intellect",
        BATTLE_SHOUT           = "Battle Shout",
        FORTITUDE              = "Power Word: Fortitude",
        MARK_OF_THE_WILD       = "Mark of the Wild",
        MYSTIC_TOUCH           = "Mystic Touch",
        CHAOS_BRAND            = "Chaos Brand",
        HUNTERS_MARK           = "Hunter's Mark",
        DEVOTION_AURA          = "Devotion Aura",
        SKYFURY                = "Skyfury",
        BLESSING_OF_THE_BRONZE = "Blessing of the Bronze",
        ATROPHIC_POISON        = "Atrophic Poison",
    },

    -- Tooltip descriptions: what each buff actually does
    BUFF_DESCRIPTIONS = {
        ARCANE_INTELLECT       = "Increases Intellect for all party members",
        BATTLE_SHOUT           = "Increases Attack Power for all party members",
        FORTITUDE              = "Increases Stamina for all party members",
        MARK_OF_THE_WILD       = "Increases Versatility for all party members",
        MYSTIC_TOUCH           = "Increases Physical damage taken by enemies",
        CHAOS_BRAND            = "Increases Magic damage taken by enemies",
        HUNTERS_MARK           = "Increases all damage taken by marked target",
        DEVOTION_AURA          = "Reduces damage taken by nearby party members",
        SKYFURY                = "Increases Mastery for nearby party members",
        BLESSING_OF_THE_BRONZE = "Increases Movement Speed for all party members",
        ATROPHIC_POISON        = "Reduces damage dealt by poisoned enemies",
    },

    -- Which class provides each raid buff (for "missing" tooltip guidance)
    BUFF_SOURCES = {
        ARCANE_INTELLECT       = "Mage",
        BATTLE_SHOUT           = "Warrior",
        FORTITUDE              = "Priest",
        MARK_OF_THE_WILD       = "Druid",
        MYSTIC_TOUCH           = "Monk",
        CHAOS_BRAND            = "Demon Hunter",
        HUNTERS_MARK           = "Hunter",
        DEVOTION_AURA          = "Paladin",
        SKYFURY                = "Shaman",
        BLESSING_OF_THE_BRONZE = "Evoker",
        ATROPHIC_POISON        = "Rogue",
    },

    -- Static fallback icons (used only if runtime spell resolution fails)
    BUFF_ICONS = {
        ARCANE_INTELLECT       = 135932,  -- Spell_Holy_MagicalSentry
        BATTLE_SHOUT           = 132333,  -- Ability_Warrior_BattleShout
        FORTITUDE              = 135987,  -- Spell_Holy_WordFortitude
        MARK_OF_THE_WILD       = 136078,  -- Spell_Nature_Regeneration
        MYSTIC_TOUCH           = 606551,  -- fallback; resolved at load
        CHAOS_BRAND            = 1247264, -- fallback; resolved at load
        HUNTERS_MARK           = 132212,  -- fallback; resolved at load
        DEVOTION_AURA          = 135893,  -- Spell_Holy_DevotionAura
        SKYFURY                = 135990,  -- fallback; resolved at load
        BLESSING_OF_THE_BRONZE = 4630478, -- fallback; resolved at load
        ATROPHIC_POISON        = 132290,  -- fallback; resolved at load
    },

    -- Actual WoW spell IDs for each raid buff. Used at load time to
    -- resolve the correct icon texture from the game's spell database
    -- via C_Spell.GetSpellTexture(). This is self-correcting across
    -- patches — if Blizzard changes an icon, the addon picks it up.
    BUFF_SPELL_IDS = {
        ARCANE_INTELLECT       = 1459,
        BATTLE_SHOUT           = 6673,
        FORTITUDE              = 21562,
        MARK_OF_THE_WILD       = 1126,
        MYSTIC_TOUCH           = 113746,
        CHAOS_BRAND            = 1490,
        HUNTERS_MARK           = 257284,
        DEVOTION_AURA          = 465,
        SKYFURY                = 462854,
        BLESSING_OF_THE_BRONZE = 381748,
        ATROPHIC_POISON        = 381637,
    },

    --------------------------------------------------------------------
    -- Window sizing
    --------------------------------------------------------------------
    FRAME_DEFAULT_WIDTH  = 260,
    FRAME_DEFAULT_HEIGHT = 429,

    -- Colors
    COLOR_MISSING    = { r = 0.85, g = 0.25, b = 0.25 },  -- red
    COLOR_HEADER     = { r = 1.00, g = 0.82, b = 0.00 },  -- gold
    COLOR_TEXT        = { r = 0.90, g = 0.90, b = 0.90 },
    COLOR_DIM         = { r = 0.50, g = 0.50, b = 0.50 },
}
