------------------------------------------------------------------------
-- Modules/RaiderIOCompat.lua
--
-- Prevents the Raider.IO profile tooltip from overlapping our panel.
--
-- THE ACTUAL CONFLICT
-- -------------------
-- Raider.IO does NOT have a persistent side panel.  Instead, when
-- PVEFrame opens and "Show Raider.IO Profile" is enabled (the default),
-- Raider.IO hooks PVEFrame:OnShow and positions a floating GameTooltip
-- to the right of PVEFrame via a 16×16 anchor frame:
--
--     RaiderIO_ProfileTooltipAnchor:SetPoint("TOPLEFT", PVEFrame, "TOPRIGHT", -16, 0)
--     RaiderIO_ProfileTooltip:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 0, 0)
--
-- LFGMythicPlusFrame is also anchored at PVEFrame.TOPRIGHT + 4, so the
-- 200-300 px wide Raider.IO tooltip completely overlaps our panel.
--
-- THE FIX
-- -------
-- We install a post-call hook on RaiderIO_ProfileTooltipAnchor:SetPoint
-- using hooksecurefunc.  Whenever Raider.IO positions that anchor
-- relative to PVEFrame (the "idle" profile state — not hover state),
-- we immediately redirect it to our frame's TOPRIGHT instead.
--
-- Because the Raider.IO tooltip uses a live anchor
--   tooltip:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 0, 0)
-- it follows the anchor automatically — no second call needed.
--
-- Guard rails:
--   • relativeTo ~= PVEFrame  → skip (hover state anchors to GameTooltip)
--   • _redirecting flag       → prevents infinite recursion from our own
--                               inner self:SetPoint call inside the hook
--   • myFrame not shown       → skip (LFG not open; no-op is safe)
--
-- When Raider.IO is absent this module is a complete no-op.
------------------------------------------------------------------------
local _, NS = ...

local RIOCompat = {}
NS.RaiderIOCompat = RIOCompat

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

local RAIDERIO_ADDON_NAME     = "RaiderIO"
local RIO_ANCHOR_FRAME_NAME   = "RaiderIO_ProfileTooltipAnchor"

-- The ProfileTooltipAnchor is a 16×16 invisible frame.  The actual
-- GameTooltip is anchored to that frame's TOPRIGHT, so the tooltip
-- begins 16 px to the right of wherever we place the anchor.
-- To match the 4 px frame-coordinate gap on the left side
-- (PVEFrame → our frame = +4), we back up by 12 px so the net
-- tooltip offset equals 4 px:  (-12) + 16 = +4.
local RIO_TOOLTIP_OFFSET = -12

------------------------------------------------------------------------
-- State
------------------------------------------------------------------------

local _hookInstalled = false -- true once hooksecurefunc is in place
local _redirecting   = false -- re-entrancy guard for SetPoint hook

------------------------------------------------------------------------
-- Internal helpers
------------------------------------------------------------------------

local function IsRaiderIOLoaded()
    if C_AddOns then
        return C_AddOns.IsAddOnLoaded(RAIDERIO_ADDON_NAME) == true
    end
    ---@diagnostic disable-next-line: undefined-global
    return IsAddOnLoaded and IsAddOnLoaded(RAIDERIO_ADDON_NAME) == true
end

-- Install a post-call hook on the anchor frame's SetPoint.
-- Returns true on success, false if the frame is not yet available.
local function InstallAnchorHook()
    if _hookInstalled then return true end

    local rioAnchor = _G[RIO_ANCHOR_FRAME_NAME]
    if not rioAnchor then
        -- Raider.IO creates the anchor lazily; will retry next LFG open.
        NS.Debug:Log("RaiderIOCompat: anchor frame not found yet; will retry")
        return false
    end

    -- hooksecurefunc appends our callback after every call to SetPoint on
    -- this specific frame object.  The hook fires after the original call,
    -- so Raider.IO's positioning already took effect — we immediately
    -- override it when the anchor is being set relative to PVEFrame.
    hooksecurefunc(rioAnchor, "SetPoint", function(self, _, relativeTo)
        if _redirecting then return end

        -- Only intercept the "idle profile" state where Raider.IO anchors
        -- to PVEFrame.  In the hover state they anchor to GameTooltip; we
        -- leave that alone so hover profiles appear next to the list entry.
        if relativeTo ~= PVEFrame then return end

        local myFrame = NS.MainWindow and NS.MainWindow.frame
        if not myFrame or not myFrame:IsShown() then return end

        -- Redirect: position anchor immediately to the right of our panel.
        -- The Raider.IO profile tooltip is live-anchored to this anchor's
        -- TOPRIGHT, so it follows without any additional SetPoint call.
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

------------------------------------------------------------------------
-- Public interface
------------------------------------------------------------------------

-- Called by LFGBridge after MainWindow:Show() has positioned our panel.
function RIOCompat:OnLFGOpened()
    if not IsRaiderIOLoaded() then return end
    InstallAnchorHook()
    -- If the hook was just installed this frame, Raider.IO's OnShow hook
    -- may have already fired and positioned the anchor at PVEFrame.TOPRIGHT
    -- before our hook existed.  Schedule a one-shot correction to catch
    -- that case.  Once the hook is in place all future opens are handled
    -- synchronously with zero delay.
    if _hookInstalled then
        C_Timer.After(0, function()
            local rioAnchor = _G[RIO_ANCHOR_FRAME_NAME]
            if not rioAnchor then return end
            local myFrame = NS.MainWindow and NS.MainWindow.frame
            if not myFrame or not myFrame:IsShown() then return end
            -- Check if anchor is still at PVEFrame (hook may have missed it).
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
