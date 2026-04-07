local _, NS = ...

local Eval = {}
NS.CompEvaluator = Eval

local UM = NS.UtilityMatrix

function Eval:Evaluate()
    local State = NS.State

    State:ResetUtilities()

    for _, member in pairs(State.members) do
        if member.specID then
            local utils = UM:GetUtilities(member.specID)
            for utilKey in pairs(utils) do
                State:AddUtilityContributor(utilKey, member)
            end
        elseif member.classFile then
            local classUtils = UM:GetClassUtilities(member.classFile)
            if classUtils then
                for utilKey in pairs(classUtils) do
                    State:AddUtilityContributor(utilKey, member)
                end
            end
        end
    end
end
