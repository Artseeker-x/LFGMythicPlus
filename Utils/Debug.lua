local _, NS = ...

local Debug = {}
NS.Debug = Debug

Debug.enabled = false

function Debug:Log(...)
    if not self.enabled then return end
    print("|cff66bbff[LFGMythicPlus]|r", ...)
end

function Debug:Error(...)
    print("|cffff3333[LFGMythicPlus ERROR]|r", ...)
end
