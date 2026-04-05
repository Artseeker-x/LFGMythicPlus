------------------------------------------------------------------------
-- Modules/LFGBridge.lua
-- Connects the companion panel to the Blizzard PVEFrame lifecycle.
-- Handles lazy loading of Blizzard_PVEUI and safe post-hooks.
-- The addon window is permanently anchored to PVEFrame.
------------------------------------------------------------------------
local _, NS = ...

local Bridge = {}
NS.LFGBridge = Bridge

------------------------------------------------------------------------
-- Initialize
------------------------------------------------------------------------
function Bridge:Initialize()
    if PVEFrame then
        self:HookPVEFrame()
    else
        local waiter = CreateFrame("Frame")
        waiter:RegisterEvent("ADDON_LOADED")
        waiter:SetScript("OnEvent", function(frame, _, addonName)
            if addonName == "Blizzard_PVEUI" then
                frame:UnregisterEvent("ADDON_LOADED")
                self:HookPVEFrame()
            end
        end)
    end
    NS.Debug:Log("LFGBridge initialized")
end

------------------------------------------------------------------------
-- Hook PVEFrame show/hide (post-hooks only, no taint)
------------------------------------------------------------------------
function Bridge:HookPVEFrame()
    if self.hooked then return end
    self.hooked = true

    PVEFrame:HookScript("OnShow", function()
        Bridge:OnLFGOpened()
    end)

    PVEFrame:HookScript("OnHide", function()
        Bridge:OnLFGClosed()
    end)

    -- Sync if already visible
    if PVEFrame:IsShown() then
        self:OnLFGOpened()
    end

    NS.Debug:Log("PVEFrame hooks installed")
end

------------------------------------------------------------------------
-- Handlers
------------------------------------------------------------------------
function Bridge:OnLFGOpened()
    if not NS.initialized then return end
    NS.GroupScanner:DoScan()
    NS.MainWindow:Show()
    NS.RaiderIOCompat:OnLFGOpened()
end

function Bridge:OnLFGClosed()
    if not NS.initialized then return end
    NS.MainWindow:Hide()
end
