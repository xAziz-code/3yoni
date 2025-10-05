-- =========================================================
-- Macho Menu — Old DUI Shape (Dock + Overlay)
-- Two Sections:
--   Animation: Super Jump + Fast Run + Noclip(F2 Enable) + GiveWeapon
--   Vehicle  : Neek v1 / Neek v2 / sucking / pee
-- Open/Close menu key: E (INPUT_CONTEXT = 38)
-- No "Close" buttons in sections (الإغلاق بالمفاتيح فقط)
-- =========================================================

local dui, visible = nil, false
local submenuOpen = false
local MENU_URL = "https://xaziz-code.github.io/3yoni/" -- ارفع index.html المعدل إلى نفس الرابط أو غيّره لرابطك

-- ============== إرسال رسالة للـ DUI ==============
local function send(m)
    if dui then
        MachoSendDuiMessage(dui, json.encode(m))
    end
end

-- ============== حالة المنيو ==============
local rootIndex, subIndex = 0, 0
local ROOT = {
    { label = "Animation", hasSub = true },
    { label = "Vehicle",   hasSub = true }
}

-- حالات الميزات
local superJump = false
local fastRun = false
local noclip = false
local menuNoclipEnabled = false
local noclipSpeedFast = 150.0

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

local function SetPedInvisible(ped, toggle)
    if toggle then
        SetEntityVisible(ped, false, false)
        SetEntityAlpha(ped, 0, false)
        SetPlayerInvisibleLocally(PlayerId(), true)
        SetEntityCollision(ped, false, true)
    else
        SetEntityVisible(ped, true, false)
        ResetEntityAlpha(ped)
        SetPlayerInvisibleLocally(PlayerId(), false)
        SetEntityCollision(ped, true, true)
    end
end

-- ============== Threads الميزات ==============
-- Super Jump
CreateThread(function()
    while true do
        if superJump then SetSuperJumpThisFrame(PlayerId()) end
        Wait(0)
    end
end)

-- Fast Run
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

-- Noclip helpers
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

    if IsControlPressed(0, 32) then dir = dir + fwd end      -- W
    if IsControlPressed(0, 33) then dir = dir - fwd end      -- S
    if IsControlPressed(0, 34) then dir = dir + right end    -- A
    if IsControlPressed(0, 35) then dir = dir - right end    -- D
    if IsControlPressed(0, 22) then dir = dir + vector3(0.0,0.0,1.0) end -- Space
    if IsControlPressed(0, 36) then dir = dir - vector3(0.0,0.0,1.0) end -- Ctrl

    local mag = math.sqrt(dir.x*dir.x + dir.y*dir.y + dir.z*dir.z)
    if mag > 0.0001 then
        dir = dir / mag
        local speed = noclipSpeedFast
        if IsControlPressed(0, 21) then speed = speed * 3.0 end -- Shift
        if IsControlPressed(0, 22) then speed = speed * 2.0 end -- Space
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
            SetPedInvisible(ped, true)
            moveNoclip(ped, dt)
            local camYaw = GetGameplayCamRot(2).z
            local curHeading = GetEntityHeading(ped)
            SetEntityHeading(ped, smoothHeading(curHeading, camYaw, 10.0))
        end
        Wait(0)
    end
end)

-- ============== أزرار Vehicle (Right Actions) ==============
local function ToggleRideOnClosest_A()
    local targetPed = GetClosestPlayer()
    if targetPed then
        if IsEntityAttachedToEntity(PlayerPedId(), targetPed) then
            ClearDetach()
        else
            AttachEntityToEntity(PlayerPedId(), targetPed, 0, 0.0, -0.35, 0.10, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            PlayAnimation("rcmpaparazzo_2", "shag_loop_poppy", 1)
        end
    else
        print("[Neek v1] لا يوجد لاعب قريب ضمن 70 متر.")
    end
end

local function ToggleRideOnClosest_B()
    local targetPed = GetClosestPlayer()
    if targetPed then
        if IsEntityAttachedToEntity(PlayerPedId(), targetPed) then
            ClearDetach()
        else
            AttachEntityToEntity(PlayerPedId(), targetPed, 0, 0.0, -0.35, 0.10, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            PlayAnimation("rcmpaparazzo_2", "shag_loop_a", 1)
        end
    else
        print("[Neek v2] لا يوجد لاعب قريب ضمن 70 متر.")
    end
end

local function ToggleRideOnClosest_C()
    local targetPed = GetClosestPlayer()
    if targetPed then
        if IsEntityAttachedToEntity(PlayerPedId(), targetPed) then
            ClearDetach()
        else
            AttachEntityToEntity(PlayerPedId(), targetPed, 0, 0.0, 0.35, 0.90, 0.0, 0.0, 180.0, false, false, false, false, 2, true)
            PlayAnimation("rcmpaparazzo_2", "shag_loop_a", 1)
        end
    else
        print("[sucking] لا يوجد لاعب قريب ضمن 70 متر.")
    end
end

local function ToggleRideOnClosest_D()
    local targetPed = GetClosestPlayer()
    if targetPed then
        if IsEntityAttachedToEntity(PlayerPedId(), targetPed) then
            ClearDetach()
        else
            AttachEntityToEntity(PlayerPedId(), targetPed, 0, 0.0, 0.35, 0.80, 0.0, 0.0, 180.0, false, false, false, false, 2, true)
            PlayAnimation("misscarsteal2peeing", "peeing_outro", 1)
        end
    else
        print("[pee] لا يوجد لاعب قريب ضمن 70 متر.")
    end
end

-- ============== حزمة الأسلحة ==============
local function GiveWeaponPack()
    local ped = PlayerPedId()
    local list = {
        "WEAPON_BAT","WEAPON_RPG","WEAPON_PUMPSHOTGUN","WEAPON_HEAVYSNIPER","WEAPON_DOUBLEACTION",
        "WEAPON_MICROSMG","WEAPON_GUSENBERG","WEAPON_ADVANCEDRIFLE","weapon_acidpackage",
        "WEAPON_SNOWLAUNCHER","WEAPON_MINIGUN","WEAPON_RAILGUN","WEAPON_FIREWORK",
        "WEAPON_RAYMINIGUN","WEAPON_RAYPISTOL","weapon_flare","weapon_fireextinguisher",
        "weapon_compactrifle","weapon_dbshotgun","weapon_flashlight","weapon_wrench","weapon_raycarbine"
    }
    for _, w in ipairs(list) do
        GiveWeaponToPed(ped, GetHashKey(w), 507, false, true)
    end
    TriggerEvent("ThundeR:Notify", {
        type = "success",
        messageheader = "3yoni3Leek :",
        message = "dis.gg/d99",
        img = "https://www.raed.net/img?id=721061",
        sound = "https://r2.guns.lol/4e861961-b10c-46fa-b571-4b744f19611f.mp3",
        voice = 0.5,
        timeout = 9000,
    })
end

-- ============== توليد عناصر القسم بحسب الحالة ==============
local function getAnimationSubItems()
    return {
        { label = "Super Jump", state = superJump, type = "toggle", key = "superJump" },
        { label = "Fast Run", state = fastRun, type = "toggle", key = "fastRun" },
        { label = "Noclip (F2) [Enable]", state = menuNoclipEnabled, type = "toggle", key = "noclipEnable" },
        { label = "GiveWeapon", type = "button", key = "giveWeapon" }
    }
end

local function getVehicleSubItems()
    return {
        { label = "Neek v1", type = "button", key = "neek1" },
        { label = "Neek v2", type = "button", key = "neek2" },
        { label = "sucking", type = "button", key = "suck" },
        { label = "pee",     type = "button", key = "pee" }
    }
end

local function refreshSubmenuUI()
    if not submenuOpen then return end
    local title = ROOT[rootIndex+1].label
    local items = (title=="Animation") and getAnimationSubItems() or getVehicleSubItems()
    send({ type="setSubmenu", title=title, items=items, index=subIndex })
end

local function updateSubIndex(delta)
    subIndex = subIndex + delta
    local max = 0
    if ROOT[rootIndex+1].label == "Animation" then max = #getAnimationSubItems() - 1 else max = #getVehicleSubItems() - 1 end
    if subIndex < 0 then subIndex = 0 end
    if subIndex > max then subIndex = max end
    send({type="setSubIndex", index=subIndex})
end

-- ============== فتح/إغلاق المنيو ==============
local function openMenu()
    if not dui then
        dui = MachoCreateDui(MENU_URL)
        if not dui then
            print("^1[MachoDUI] DUI create failed^0")
            return
        end
        Citizen.Wait(200)
        send({ type="init", title="Discord.gg/D99", index=rootIndex, items=ROOT })
    end
    MachoShowDui(dui)
    send({type="show"})
    visible = true
end

local function closeMenu()
    if not dui then return end
    send({type="hide"})
    MachoHideDui(dui)
    visible = false
    submenuOpen = false
end

local function openSub()
    submenuOpen = true
    subIndex = 0
    refreshSubmenuUI()
    send({type="openSub"})
end

local function closeSub()
    if not submenuOpen then return end
    submenuOpen = false
    send({type="closeSub"})
end

-- ============== تنفيذ عنصر في القسم ==============
local function execAnimation(idx)
    if idx == 0 then
        superJump = not superJump
    elseif idx == 1 then
        fastRun = not fastRun
    elseif idx == 2 then
        menuNoclipEnabled = not menuNoclipEnabled
        -- إيقاف الطيران إن تم تعطيل الـ Enable
        if not menuNoclipEnabled and noclip then
            noclip = false
            local ped = PlayerPedId()
            SetPedInvisible(ped, false)
            SetEntityInvincible(ped, false)
            SetPedCanRagdoll(ped, true)
            FreezeEntityPosition(ped, false)
            SetEntityVelocity(ped, 0.0, 0.0, 0.0)
        end
    elseif idx == 3 then
        GiveWeaponPack()
    end
    refreshSubmenuUI()
end

local function execVehicle(idx)
    if idx == 0 then ToggleRideOnClosest_A()
    elseif idx == 1 then ToggleRideOnClosest_B()
    elseif idx == 2 then ToggleRideOnClosest_C()
    elseif idx == 3 then ToggleRideOnClosest_D()
    end
end

local function confirm()
    if not submenuOpen then
        if ROOT[rootIndex+1] and ROOT[rootIndex+1].hasSub then openSub() end
        return
    end
    local title = ROOT[rootIndex+1].label
    if title == "Animation" then execAnimation(subIndex) else execVehicle(subIndex) end
end

-- ============== تحكم لوحة المفاتيح ==============
CreateThread(function()
    while true do
        Wait(0)

        -- فتح/إغلاق بـ E (INPUT_CONTEXT = 38)
        if IsControlJustPressed(0, 38) then
            if visible then closeMenu() else openMenu() end
        end

        if visible then
            -- أسهم وتحكم
            if IsControlJustPressed(0, 172) then -- ↑
                if submenuOpen then updateSubIndex(-1)
                else
                    rootIndex = math.max(0, rootIndex - 1)
                    send({type="setIndex", index=rootIndex})
                end
            end
            if IsControlJustPressed(0, 173) then -- ↓
                if submenuOpen then updateSubIndex(1)
                else
                    rootIndex = math.min(#ROOT-1, rootIndex + 1)
                    send({type="setIndex", index=rootIndex})
                end
            end
            if IsControlJustPressed(0, 174) then -- ←
                closeSub()
            end
            if IsControlJustPressed(0, 175) then -- →
                if not submenuOpen then openSub() end
            end
            if IsControlJustPressed(0, 176) then -- Enter
                confirm()
            end
            if IsControlJustPressed(0, 177) then -- Back
                closeSub()
            end
        end
    end
end)

-- ============== F2 لتبديل الطيران (إذا Enabled) ==============
CreateThread(function()
    while true do
        Wait(0)
        -- 289 = F2
        if IsControlJustPressed(0, 289) and menuNoclipEnabled then
            noclip = not noclip
            local ped = PlayerPedId()
            if noclip then
                SetPedInvisible(ped, true)
                SetEntityInvincible(ped, true)
                SetPedCanRagdoll(ped, false)
                SetEntityVelocity(ped, 0.0, 0.0, 0.0)
                FreezeEntityPosition(ped, true)
            else
                SetPedInvisible(ped, false)
                SetEntityInvincible(ped, false)
                SetPedCanRagdoll(ped, true)
                FreezeEntityPosition(ped, false)
                SetEntityVelocity(ped, 0.0, 0.0, 0.0)
            end
            -- تحديث حالة العنصر داخل Animation
            if submenuOpen and ROOT[rootIndex+1].label == "Animation" then
                refreshSubmenuUI()
            end
        end
    end
end)

-- ============== تنظيف عند إيقاف المورد ==============
AddEventHandler("onResourceStop", function(resName)
    if GetCurrentResourceName() ~= resName then return end
    ClearDetach()
    if noclip then
        local ped = PlayerPedId()
        SetPedInvisible(ped, false)
        SetEntityInvincible(ped, false)
        SetPedCanRagdoll(ped, true)
        FreezeEntityPosition(ped, false)
        noclip = false
    end
    if dui then MachoHideDui(dui) end
end)
