local _, NS = ...

local Bridge = {}
NS.LFGBridge = Bridge

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

-- Post-hooks only; HookScript never taints protected frames.
function Bridge:HookPVEFrame()
    if self.hooked then return end
    self.hooked = true

    PVEFrame:HookScript("OnShow", function()
        Bridge:OnLFGOpened()
    end)

    PVEFrame:HookScript("OnHide", function()
        Bridge:OnLFGClosed()
    end)

    if PVEFrame:IsShown() then -- sync if already visible
        self:OnLFGOpened()
    end

    NS.Debug:Log("PVEFrame hooks installed")
end

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
