local ADDON_NAME, NS = ...

LFGMythicPlus = NS
NS.initialized = false

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")

loader:SetScript("OnEvent", function(self, _, loadedAddon)
    if loadedAddon ~= ADDON_NAME then return end
    self:UnregisterEvent("ADDON_LOADED")

    NS.SavedVariables:Initialize()

    -- Resolve raid buff icons from the spell database before MainWindow:Initialize()
    -- so UtilityRows receive correct textures at frame creation time.
    local C = NS.CONSTANTS
    if C.BUFF_SPELL_IDS then
        for key, spellID in pairs(C.BUFF_SPELL_IDS) do
            local texture
            if C_Spell and C_Spell.GetSpellTexture then
                texture = C_Spell.GetSpellTexture(spellID)
            end
            if not texture and GetSpellTexture then
                texture = GetSpellTexture(spellID)
            end
            if texture then
                C.BUFF_ICONS[key] = texture
            end
        end
    end

    local CSD = NS.ClassSpecData
    local UM  = NS.UtilityMatrix

    -- Phase 1: refresh existing static specs with live API data.
    if GetSpecializationInfoByID then
        for specID, info in pairs(CSD.Specs) do
            local a, b, _, d, e, f = GetSpecializationInfoByID(specID)
            local sName, sIcon, sRole, sClassFile
            if type(a) == "table" then
                -- Struct return (WoW 12.0+)
                sName      = a.name or a.specName
                sIcon      = a.iconID or a.icon
                sRole      = a.role
                sClassFile = a.classFile or a.classFilename
            else
                sName      = b
                sIcon      = d
                sRole      = e
                sClassFile = f
            end
            if sClassFile then info.class = sClassFile end
            if sName     then info.name  = sName end
            if sRole     then info.role  = sRole end
            if sIcon and sIcon ~= 0 then info.icon = sIcon end
        end
    end

    -- Phase 2: walk every class/spec in the game to discover specs not in the static table.
    local numClasses = GetNumClasses and GetNumClasses() or 0
    for classID = 1, numClasses do
        local _, classFile = GetClassInfo(classID)
        if classFile then
            local numSpecs = 0
            local nsFn = C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializationsForClassID
            if nsFn then
                local r = nsFn(classID)
                numSpecs = (type(r) == "table") and (r.numSpecializations or 0) or (type(r) == "number" and r or 0)
            end
            if numSpecs == 0 and GetNumSpecializationsForClassID then
                numSpecs = GetNumSpecializationsForClassID(classID) or 0
            end

            for specIndex = 1, numSpecs do
                local fn = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfoForClassID)
                            or GetSpecializationInfoForClassID
                if fn then
                    local a, b, _, d, e = fn(classID, specIndex)
                    local specID, sName, sIcon, sRole
                    if type(a) == "table" then
                        specID = a.specID
                        sName  = a.name or a.specName
                        sIcon  = a.iconID or a.icon
                        sRole  = a.role
                    else
                        specID = a
                        sName  = b
                        sIcon  = d
                        sRole  = e
                    end

                    if specID and not CSD.Specs[specID] then
                        CSD.Specs[specID] = {
                            class = classFile,
                            name  = sName or ("Spec " .. specID),
                            role  = sRole or "DAMAGER",
                            icon  = (sIcon and sIcon ~= 0) and sIcon or 0,
                        }
                        if UM and not UM.Matrix[specID] then
                            local seed = CSD:BuildClassUtilitySeed(classFile, specID)
                            if seed then UM.Matrix[specID] = seed end
                        end
                        if not CSD.ClassColors[classFile] then
                            local rc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
                            if rc then
                                CSD.ClassColors[classFile] = string.format(
                                    "%02X%02X%02X",
                                    math.floor(rc.r * 255),
                                    math.floor(rc.g * 255),
                                    math.floor(rc.b * 255)
                                )
                            end
                        end
                        NS.Debug:Log("Init discovered spec", specID, sName, classFile)
                    end
                end
            end
        end
    end

    UM.ClassUtilities = nil

    NS.Events:Initialize()
    NS.MainWindow:Initialize()
    NS.LFGBridge:Initialize()
    NS.RaiderIOCompat:Initialize()

    NS.initialized = true
    NS.Debug:Log("Loaded v" .. NS.CONSTANTS.ADDON_VERSION)
end)

------------------------------------------------------------------------
-- Slash commands
------------------------------------------------------------------------
SLASH_LFGMYTHICPLUS1 = "/lfgmp"
SLASH_LFGMYTHICPLUS2 = "/lfgmythicplus"

local PREFIX = "|cff66bbff[LFG Mythic+]|r "

SlashCmdList["LFGMYTHICPLUS"] = function(input)
    local cmd = (input or ""):trim():lower()

    if cmd == "warnings" then
        local current = NS.SavedVariables:Get("showWarnings")
        NS.SavedVariables:Set("showWarnings", not current)
        print(PREFIX .. "Warnings " .. (not current and "ON" or "OFF"))
        if NS.MainWindow:IsShown() then
            NS.State.dirty = true
            NS.MainWindow:Refresh()
        end
    elseif cmd == "reset" then
        NS.SavedVariables:Reset()
        print(PREFIX .. "Settings reset to defaults.")
    elseif cmd == "debug" then
        NS.Debug.enabled = not NS.Debug.enabled
        print(PREFIX .. "Debug " .. (NS.Debug.enabled and "ON" or "OFF"))
    else
        print(PREFIX .. "Commands:")
        print("  /lfgmp warnings  - Toggle warning indicators")
        print("  /lfgmp reset     - Reset all settings")
        print("  /lfgmp debug     - Toggle debug output")
    end
end
