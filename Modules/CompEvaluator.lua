------------------------------------------------------------------------
-- Modules/CompEvaluator.lua
-- Reads State.members and computes utility coverage with contributor
-- tracking into State.utilities. Pure logic — no UI, no events.
--
-- When a member's spec is unknown but their class is known, falls back
-- to class-level guaranteed utilities (abilities every spec of that
-- class has). This prevents utility gaps during inspect delays.
------------------------------------------------------------------------
local _, NS = ...

local Eval = {}
NS.CompEvaluator = Eval

local UM = NS.UtilityMatrix

------------------------------------------------------------------------
-- Evaluate current group composition
------------------------------------------------------------------------
function Eval:Evaluate()
    local State = NS.State

    -- Reset all utilities to uncovered with empty contributor lists
    State:ResetUtilities()

    -- Walk each member and record their utility contributions
    for _, member in pairs(State.members) do
        if member.specID then
            -- Spec known: use exact spec utilities
            local utils = UM:GetUtilities(member.specID)
            for utilKey in pairs(utils) do
                State:AddUtilityContributor(utilKey, member)
            end
        elseif member.classFile then
            -- Spec unknown but class known: use class-level guaranteed utilities
            -- (abilities that ALL specs of this class share)
            local classUtils = UM:GetClassUtilities(member.classFile)
            if classUtils then
                for utilKey in pairs(classUtils) do
                    State:AddUtilityContributor(utilKey, member)
                end
            end
        end
    end
end
