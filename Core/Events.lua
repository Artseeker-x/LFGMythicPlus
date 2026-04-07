local _, NS = ...

local Events = {}
NS.Events = Events

local frame = CreateFrame("Frame")
local handlers = {} -- event -> { func1, func2, ... }

function Events:Register(event, handler)
    if not handlers[event] then
        handlers[event] = {}
        frame:RegisterEvent(event)
    end
    table.insert(handlers[event], handler)
end

function Events:Unregister(event, handler)
    local list = handlers[event]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i] == handler then
            table.remove(list, i)
        end
    end
    if #list == 0 then
        handlers[event] = nil
        frame:UnregisterEvent(event)
    end
end

frame:SetScript("OnEvent", function(_, event, ...)
    local list = handlers[event]
    if not list then return end
    for i = 1, #list do
        list[i](event, ...)
    end
end)

function Events:Initialize()
    local Scanner = NS.GroupScanner

    local function OnRosterChange()
        Scanner:QueueScan()
    end

    self:Register("GROUP_ROSTER_UPDATE",           OnRosterChange)
    self:Register("PLAYER_ENTERING_WORLD",         OnRosterChange)
    self:Register("PLAYER_SPECIALIZATION_CHANGED", OnRosterChange)
    self:Register("ACTIVE_TALENT_GROUP_CHANGED",   OnRosterChange)
    self:Register("PARTY_MEMBER_ENABLE",           OnRosterChange)
    self:Register("PARTY_MEMBER_DISABLE",          OnRosterChange)
    self:Register("ZONE_CHANGED_NEW_AREA",         OnRosterChange)

    self:Register("UNIT_NAME_UPDATE", function(_, unit)
        if unit and (unit == "player" or unit:match("^party%d$")) then
            Scanner:QueueScan()
        end
    end)

    self:Register("UNIT_CONNECTION", function(_, unit)
        if unit and (unit == "player" or unit:match("^party%d$")) then
            Scanner:QueueScan()
        end
    end)

    self:Register("INSPECT_READY", function(_, guid)
        Scanner:OnInspectDataAvailable(guid)
    end)

    self:Register("ROLE_CHANGED_INFORM", OnRosterChange)

    NS.Debug:Log("Events initialized")
end
