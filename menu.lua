local dui, visible = nil, false
local MENU_URL = "https://xaziz-code.github.io/3yoni/"

local function send(m)
    if dui then
        MachoSendDuiMessage(dui, json.encode(m))
    end
end

-- ============== Super Jump ==============
local superJump = false
CreateThread(function()
    while true do
        if superJump then SetSuperJumpThisFrame(PlayerId()) end
        Wait(0)
    end
end)

-- ============== Fast Run ==============
local fastRun = false
local normalRunMultiplier = 1.0
local fastRunMultiplier = 10.0
local fastWalkMultiplier = 3.0

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if fastRun and DoesEntityExist(ped) then
            SetRunSprintMultiplierForPlayer(PlayerId(), fastRunMultiplier)
            SetPedMoveRateOverride(ped, fastWalkMultiplier)
        else
            SetRunSprintMultiplierForPlayer(PlayerId(), normalRunMultiplier)
            SetPedMoveRateOverride(ped, 1.0)
        end
        Wait(0)
    end
end)

-- ============== Noclip ==============
local noclip = false
local menuNoclipEnabled = false
local noclipSpeedFast = 150.0

local function normalizeHeading(h)
    h = h % 360.0
    if h < 0.0 then h = h + 360.0 end
    return h
end

local function smoothHeading(cur, target, maxStep)
    local diff = ((target - cur + 540.0) % 360.0) - 180.0
    local step = math.max(-maxStep, math.min(maxStep, diff))
    return normalizeHeading(cur + step)
end

local function getCamForward()
    local rot = GetGameplayCamRot(2)
    local radX, radZ = math.rad(rot.x), math.rad(rot.z)
    return vector3(
        -math.sin(radZ) * math.cos(radX),
        math.cos(radZ) * math.cos(radX),
        math.sin(radX)
    )
end

local function getCamRight()
    local rot = GetGameplayCamRot(2)
    local yaw = math.rad(rot.z + 90.0)
    local pitch = math.rad(rot.x)
    return vector3(
        -math.sin(yaw) * math.cos(pitch),
        math.cos(yaw) * math.cos(pitch),
        0.0
    )
end

local function moveNoclip(ped, dt)
    local dir = vector3(0.0, 0.0, 0.0)
    local fwd = getCamForward()
    local right = getCamRight()
    if IsControlPressed(0, 32) then dir = dir + fwd end
    if IsControlPressed(0, 33) then dir = dir - fwd end
    if IsControlPressed(0, 34) then dir = dir + right end
    if IsControlPressed(0, 35) then dir = dir - right end
    if IsControlPressed(0, 22) then dir = dir + vector3(0.0,0.0,1.0) end
    if IsControlPressed(0, 36) then dir = dir - vector3(0.0,0.0,1.0) end

    local mag = math.sqrt(dir.x*dir.x + dir.y*dir.y + dir.z*dir.z)
    if mag > 0.0001 then
        dir = dir / mag
        local speed = noclipSpeedFast
        if IsControlPressed(0, 21) then speed = speed * 3.0 end
        if IsControlPressed(0, 19) then speed = speed * 2.0 end
        local pos = GetEntityCoords(ped)
        local newPos = pos + (dir * (speed * dt))
        SetEntityCoordsNoOffset(ped, newPos.x, newPos.y, newPos.z, true, true, true)
    end
end

CreateThread(function()
    while true do
        if noclip then
            local ped = PlayerPedId()
            local dt = GetFrameTime()
            SetEntityVelocity(ped, 0.0, 0.0, 0.0)
            SetEntityInvincible(ped, true)
            SetPedCanRagdoll(ped, false)
            moveNoclip(ped, dt)
            local camYaw = GetGameplayCamRot(2).z
            local curHeading = GetEntityHeading(ped)
            SetEntityHeading(ped, smoothHeading(curHeading, camYaw, 10.0))
        end
        Wait(0)
    end
end)

-- ============== أدوات مشتركة ==============
local function GetClosestPlayer()
    local players = GetActivePlayers()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closestPlayer, closestDist = -1, 999.0

    for _, i in pairs(players) do
        local target = GetPlayerPed(i)
        if target ~= ped then
            local targetCoords = GetEntityCoords(target)
            local dist = #(coords - targetCoords)
            if dist < closestDist then
                closestDist = dist
                closestPlayer = i
            end
        end
    end

    if closestDist < 70.0 and closestPlayer ~= -1 then
        return GetPlayerPed(closestPlayer)
    else
        return nil
    end
end

local function PlayAnimation(animDict, animName, flag)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Wait(10) end
    TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, -8.0, -1, flag or 1, 0.0, false, false, false)
end

local function ClearDetach()
    ClearPedTasks(PlayerPedId())
    DetachEntity(PlayerPedId(), true, true)
end

-- ============== Right Actions ==============
local ridingA, attachedToA = false, nil
local function ToggleRideOnClosest_A()
    if not ridingA then
        local targetPed = GetClosestPlayer()
        if targetPed then
            AttachEntityToEntity(PlayerPedId(), targetPed, 0, 0.0, -0.35, 0.10, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            PlayAnimation("rcmpaparazzo_2", "shag_loop_poppy", 1)
            ridingA, attachedToA = true, targetPed
        end
    else
        ClearDetach()
        ridingA, attachedToA = false, nil
    end
end

local ridingB, attachedToB = false, nil
local function ToggleRideOnClosest_B()
    if not ridingB then
        local targetPed = GetClosestPlayer()
        if targetPed then
            AttachEntityToEntity(PlayerPedId(), targetPed, 0, 0.0, -0.35, 0.10, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            PlayAnimation("rcmpaparazzo_2", "shag_loop_a", 1)
            ridingB, attachedToB = true, targetPed
        end
    else
        ClearDetach()
        ridingB, attachedToB = false, nil
    end
end

local ridingC, attachedToC = false, nil
local function ToggleRideOnClosest_C()
    if not ridingC then
        local targetPed = GetClosestPlayer()
        if targetPed then
            AttachEntityToEntity(PlayerPedId(), targetPed, 0, 0.0, 0.35, 0.90, 0.0, 0.0, 180.0, false, false, false, false, 2, true)
            PlayAnimation("rcmpaparazzo_2", "shag_loop_a", 1)
            ridingC, attachedToC = true, targetPed
        end
    else
        ClearDetach()
        ridingC, attachedToC = false, nil
    end
end

local ridingD, attachedToD = false, nil
local function ToggleRideOnClosest_D()
    if not ridingD then
        local targetPed = GetClosestPlayer()
        if targetPed then
            AttachEntityToEntity(PlayerPedId(), targetPed, 0, 0.0, 0.35, 0.80, 0.0, 0.0, 180.0, false, false, false, false, 2, true)
            PlayAnimation("misscarsteal2peeping", "peeing_outro", 1)
            ridingD, attachedToD = true, targetPed
        end
    else
        ClearDetach()
        ridingD, attachedToD = false, nil
    end
end

local function openMenu()
    if not dui then
        dui = MachoCreateDui(MENU_URL)
        if not dui then
            print("^1[MachoDUI] DUI létrehozás hiba^0")
            return
        end
        Citizen.Wait(200)
        send({
            type  = "init",
            title = "Discord.gg/D99",
            index = 0,
            items = {
                {label="Player", hasSub=true, hint="›", items={
                    {label="Super Jump", id="superJump"},
                    {label="Fast Run", id="fastRun"},
                    {label="Noclip (F2)", id="noclip"},
                    {label="Remove Weapons", id="removeWeapons"}
                }},
                {label="Vehicle", hasSub=true, hint="›", items={
                    {label="Neek v1", id="neekV1"},
                    {label="Neek v2", id="neekV2"},
                    {label="Sucking", id="sucking"},
                    {label="Pee", id="pee"}
                }},
                {label="Add", hasSub=true, hint="›"},
                {label="Settings", hasSub=true, hint="›"}
            }
        })
    end
    MachoShowDui(dui)
    send({type="show"})
    send({type="focus"})
    visible = true
end

local function closeMenu()
    if not dui then return end
    send({type="hide"})
    MachoHideDui(dui)
    visible = false
end

local function handleMenuAction(action)
    if action == 'superJump' then
        superJump = not superJump
        print("Super Jump: " .. tostring(superJump))
    elseif action == 'fastRun' then
        fastRun = not fastRun
        print("Fast Run: " .. tostring(fastRun))
    elseif action == 'noclip' then
        menuNoclipEnabled = not menuNoclipEnabled
        if not menuNoclipEnabled and noclip then
            noclip = false
            local ped = PlayerPedId()
            SetEntityInvincible(ped, false)
            SetPedCanRagdoll(ped, true)
        end
        print("Noclip Enabled: " .. tostring(menuNoclipEnabled))
    elseif action == 'removeWeapons' then
        RemoveAllPedWeapons(PlayerPedId(), true)
        print("Weapons Removed")
    elseif action == 'neekV1' then
        ToggleRideOnClosest_A()
    elseif action == 'neekV2' then
        ToggleRideOnClosest_B()
    elseif action == 'sucking' then
        ToggleRideOnClosest_C()
    elseif action == 'pee' then
        ToggleRideOnClosest_D()
    end
end

CreateThread(function()
    while true do
        Wait(0)

        -- DELETE gomb (178) nyit/zár
        if IsControlJustPressed(0, 178) then
            if visible then closeMenu() else openMenu() end
        end

        if visible then
            -- egyszerű nyílvezérlés
            if IsControlJustPressed(0, 172) then send({type="move", delta=-1}) end -- ↑
            if IsControlJustPressed(0, 173) then send({type="move", delta=1}) end -- ↓
            if IsControlJustPressed(0, 174) then send({type="closeSub"}) end -- ←
            if IsControlJustPressed(0, 175) then send({type="openSub"}) end -- →
            if IsControlJustPressed(0, 176) then send({type="confirm"}) end -- Enter
            if IsControlJustPressed(0, 177) then send({type="closeSub"}) end -- Back
        end
        
        -- F2 for noclip
        if IsControlJustPressed(0, 289) then
            if menuNoclipEnabled then
                noclip = not noclip
                local ped = PlayerPedId()
                if noclip then
                    SetEntityInvincible(ped, true)
                    SetPedCanRagdoll(ped, false)
                else
                    SetEntityInvincible(ped, false)
                    SetPedCanRagdoll(ped, true)
                end
            end
        end
    end
end)

-- استقبال الأوامر من DUI
RegisterRawNuiCallbackType('menuAction')
AddEventHandler('__cfx_nui:menuAction', function(body, cb)
    if body and body.action then
        handleMenuAction(body.action)
    end
    cb({status = 'ok'})
end)

-- Cleanup
AddEventHandler("onResourceStop", function(resName)
    if GetCurrentResourceName() ~= resName then return end
    ClearDetach()
    if noclip then
        local ped = PlayerPedId()
        SetEntityInvincible(ped, false)
        SetPedCanRagdoll(ped, true)
        noclip = false
    end
end)
