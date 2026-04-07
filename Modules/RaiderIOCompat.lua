-- Prevents the Raider.IO profile tooltip from overlapping our panel.
--
-- When PVEFrame opens, Raider.IO positions a floating GameTooltip to the right
-- of PVEFrame via a 16x16 anchor frame (RaiderIO_ProfileTooltipAnchor). Our
-- panel occupies that same space. We hook SetPoint on the anchor frame and
-- redirect it to our frame's TOPRIGHT whenever Raider.IO anchors to PVEFrame.
-- The tooltip live-follows the anchor, so no second call is needed.
--
-- Two anchor states exist: "idle profile" (anchor -> PVEFrame, intercepted here)
-- and "hover" (anchor -> GameTooltip, left alone so hover profiles work normally).
local _, NS = ...

local RIOCompat = {}
NS.RaiderIOCompat = RIOCompat

local RAIDERIO_ADDON_NAME   = "RaiderIO"
local RIO_ANCHOR_FRAME_NAME = "RaiderIO_ProfileTooltipAnchor"

-- Anchor is 16px wide; tooltip attaches at anchor TOPRIGHT.
-- Back up 12px so the net gap from our frame equals 4px: (-12) + 16 = +4.
local RIO_TOOLTIP_OFFSET = -12

local _hookInstalled = false
local _redirecting   = false

local function IsRaiderIOLoaded()
    if C_AddOns then
        return C_AddOns.IsAddOnLoaded(RAIDERIO_ADDON_NAME) == true
    end
    ---@diagnostic disable-next-line: undefined-global
    return IsAddOnLoaded and IsAddOnLoaded(RAIDERIO_ADDON_NAME) == true
end

local function InstallAnchorHook()
    if _hookInstalled then return true end

    local rioAnchor = _G[RIO_ANCHOR_FRAME_NAME]
    if not rioAnchor then
        -- Raider.IO creates this frame lazily; retry on next LFG open.
        NS.Debug:Log("RaiderIOCompat: anchor frame not found yet; will retry")
        return false
    end

    hooksecurefunc(rioAnchor, "SetPoint", function(self, _, relativeTo)
        if _redirecting then return end
        -- Only intercept the idle-profile anchor (PVEFrame); leave hover anchors alone.
        if relativeTo ~= PVEFrame then return end

        local myFrame = NS.MainWindow and NS.MainWindow.frame
        if not myFrame or not myFrame:IsShown() then return end

        _redirecting = true
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", myFrame, "TOPRIGHT", RIO_TOOLTIP_OFFSET, 0)
        _redirecting = false

        NS.Debug:Log("RaiderIOCompat: redirected tooltip anchor to LFGMythicPlusFrame TOPRIGHT")
    end)

    _hookInstalled = true
    NS.Debug:Log("RaiderIOCompat: SetPoint hook installed on " .. RIO_ANCHOR_FRAME_NAME)
    return true
end

function RIOCompat:OnLFGOpened()
    if not IsRaiderIOLoaded() then return end
    InstallAnchorHook()
    -- Raider.IO's OnShow may have fired before our hook existed on the first open.
    -- Deferred check corrects the anchor position in that case; subsequent opens
    -- are handled synchronously by the hook.
    if _hookInstalled then
        C_Timer.After(0, function()
            local rioAnchor = _G[RIO_ANCHOR_FRAME_NAME]
            if not rioAnchor then return end
            local myFrame = NS.MainWindow and NS.MainWindow.frame
            if not myFrame or not myFrame:IsShown() then return end
            local numPoints = rioAnchor:GetNumPoints()
            if numPoints > 0 then
                local _, relativeTo = rioAnchor:GetPoint(1)
                if relativeTo == PVEFrame then
                    _redirecting = true
                    rioAnchor:ClearAllPoints()
                    rioAnchor:SetPoint("TOPLEFT", myFrame, "TOPRIGHT", RIO_TOOLTIP_OFFSET, 0)
                    _redirecting = false
                    NS.Debug:Log("RaiderIOCompat: corrected anchor via deferred check")
                end
            end
        end)
    end
end

function RIOCompat:Initialize()
    NS.Debug:Log("RaiderIOCompat initialized (Raider.IO present: " ..
        tostring(IsRaiderIOLoaded()) .. ")")
end
