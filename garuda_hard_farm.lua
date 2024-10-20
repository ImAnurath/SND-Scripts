skill1 = "\"Riddle of Fire\""
skill2 = "\"Fire's Reply\""
buff   = "\"Brotherhood\""
loop = 0
--[[
    ''''''WIP 
    - Needs better inventory management
    - Can have better logic for movement
    - Desyn and coffer opening can be tied to in game state (It feels buggy tho)
    - Needs to check if it is the first time starting or the Duty Finder is set properly
    - Can use the skill better, doesn't have to wait to move to boss to start casting feels clunky
]]
function checkInventory()
    return GetInventoryFreeSlotCount()
end

function getTargetPos()
    x = GetTargetRawXPos()
    y = GetTargetRawYPos()
    z = GetTargetRawZPos()
    return x,y,z
end

function selectTarget() -- Target enemy, if untarget, gotta call the function again
        local current_target = GetTargetName()
        if not current_target or current_target == "" then
            yield("/targetenemy")
            current_target = GetTargetName()
            if current_target == "" then
                yield("/wait "..rate)
            end
        end
end


function MoveTo(valuex, valuey, valuez, stopdistance, FlyOrWalk)
    function MeshCheck()
        function Truncate1Dp(num)
            return truncate and ("%.1f"):format(num) or num
        end
        local was_ready = NavIsReady()
        if not NavIsReady() then
            while not NavIsReady() do
                LogInfo("[Debug]Building navmesh, currently at " .. Truncate1Dp(NavBuildProgress() * 100) .. "%")
                yield("/wait 1")
                local was_ready = NavIsReady()
                if was_ready then
                    LogInfo("[Debug]Navmesh ready!")
                end
            end
        else
            LogInfo("[Debug]Navmesh ready!")
        end
    end
    MeshCheck()
    if FlyOrWalk then
        if TerritorySupportsMounting() then
            while GetCharacterCondition(4, false) do
                yield("/wait 0.1")
                if GetCharacterCondition(27) then
                    yield("/wait 2")
                else
                    yield('/gaction "mount roulette"')
                end
            end
            if HasFlightUnlocked(GetZoneID()) then
                PathfindAndMoveTo(valuex, valuey, valuez, true) -- flying
            else
                LogInfo("[MoveTo] Can't fly trying to walk.")
                PathfindAndMoveTo(valuex, valuey, valuez, false) -- walking
            end
        else
            LogInfo("[MoveTo] Can't mount trying to walk.")
            PathfindAndMoveTo(valuex, valuey, valuez, false) -- walking
        end
    else
        PathfindAndMoveTo(valuex, valuey, valuez, false) -- walking
    end
    while ((PathIsRunning() or PathfindInProgress()) and GetDistanceToPoint(valuex, valuey, valuez) > stopdistance) do
        yield("/wait 0.3")
    end
    PathStop()
    LogInfo("[MoveTo] Completed")
end

function PlayerTest()
    repeat
        yield("/wait 0.5")
    until IsPlayerAvailable()
end

function GoInDuty()
    -- Open Duty Finder if not already
    if not IsAddonReady("ContentsFinder") then
        yield("/dutyfinder")
        while not IsAddonReady("ContentsFinder") do
            yield("/wait 0.5")
        end
    end
    SetDFUnrestricted(true) -- Set Unsync
    yield("/pcall ContentsFinder true 1 4") -- Page in Duty Finder - 4 = Trials 1 => Its just a fucking list
    if GetNodeText("ContentsFinder", 14) == "The Howling Eye (Hard)" then
    else
        yield("/pcall ContentsFinder true 12 3")
        for i = 1, 501 do
            if IsAddonReady("ContentsFinder") then
                yield("/pcall ContentsFinder true 3 "..i)
                yield("/wait 0.1")
                if GetNodeText("ContentsFinder", 14) == "The Howling Eye (Hard)" then
                    FoundTheDuty = true
                    break 
                end
            end
        end
    end
    yield("/pcall ContentsFinder true 12 0") -- Commence Duty
    yield("/wait 1.0")
    if IsAddonVisible("ContentsFinderConfirm") then
        yield("/pcall ContentsFinderConfirm true 8") -- Accept the Duty
    end
end

function checkInv()
    local loot_items = {
        Garudas_Gaze    = 1674,
        Garudas_Scream  = 1814,
        Garudas_Pain    = 10445,
        Garudas_Beak    = 1883,
        Garudas_Blood   = 20360,
        Garudas_Plumes  = 9228,
        Garudas_Spine   = 1952,
        Garudas_Abandon = 10507,
        Garudas_Van     = 2138,
        Garudas_Will    = 2205,
        Garudas_Honor   = 20361,
        Garudas_Tail    = 14889,
        Garudas_Embrace = 2206,
        Garudas_Lift    = 10569,
        Garudas_Talons  = 1744,
    }
    local total_count = 0
    for name, id in pairs(loot_items) do
        local item_count = GetItemCount(id)
        total_count = total_count + item_count
    end
    return total_count
end

function desyn(item_count)
    yield("/generalaction Desynthesis")
    yield("/waitaddon SalvageItemSelector")
    yield("/wait 1.0")
    for i = 1, item_count do
        yield("/pcall SalvageItemSelector false 12 0")
        -- while GetCharacterCondition(39) do yield("/wait 1") end
        yield("/wait 4.0")
        yield("/pcall SalvageResult true 0")
    end
    yield("/pcall SalvageItemSelector true -1")
end

function executeSkill(skill)
    yield("/ac "..skill)
    yield("/wait 1")
end

function openCoffer()
    yield("/target Treasure Coffer")
    yield("/interact Treasure Coffer")
    yield("/wait 1")
end

function openCoffer_Inventory()
    yield("/item " .. "Vortex Weapon Coffer (IL 70)")
    yield("/wait 1.0")
    haveCoffer = false
end

local repeat_amount = 5
local repeat_counter = 0
while repeat_counter < repeat_amount do
    space = checkInventory()
    PlayerTest()
    GoInDuty()
    PlayerTest()
    yield("/wait 0.5")
    while GetCharacterCondition(25) or GetCharacterCondition(45) or GetCharacterCondition(51) do
        yield("/wait 0.5")
    end
    selectTarget()
    while not NavIsReady() do
        yield("/wait 0.5")
    end
    x, y, z = getTargetPos()
    MoveTo(x, y, z, 1, false)
    executeSkill(buff)
    executeSkill(skill1)
    executeSkill(skill2)
    yield("/wait 1.5")
    if not GetCharacterCondition(26) then
        openCoffer()
    end
    new_space = checkInventory()
    if new_space < space then
        LeaveDuty()
    else
        yield("/target Treasure Coffer")
        x_c, y_c, z_c = getTargetPos()
        MoveTo(x_c, y_c, z_c, 1, false)
        LeaveDuty()
    end
    PlayerTest()
    yield("/wait 1")
    item_count = checkInv()
    haveCoffer = true
    while item_count ~= 0 and haveCoffer do
        desyn(item_count)
        openCoffer_Inventory()
        yield("/wait 2.5")
        desyn(item_count)
        while GetCharacterCondition(39) do
            yield("/wait 0.5")
        end
    end
    repeat_counter = repeat_counter + 1
end