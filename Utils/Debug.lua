------------------------------------------------------------------------
-- Utils/Debug.lua
-- Development-time print helpers. Gated behind a debug flag so they
-- compile to no-ops in production.
------------------------------------------------------------------------
local _, NS = ...

local Debug = {}
NS.Debug = Debug

-- Toggle via /lfgmp debug
Debug.enabled = false

function Debug:Log(...)
    if not self.enabled then return end
    print("|cff66bbff[LFGMythicPlus]|r", ...)
end

function Debug:Error(...)
    -- Errors always print regardless of debug flag
    print("|cffff3333[LFGMythicPlus ERROR]|r", ...)
end
