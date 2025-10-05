-- =========================================================
-- Macho Menu — Two Sections
-- Section One (Animation): Super Jump + Fast Run + Noclip(F2) + GiveWeapon
-- Section Two (Vehicle): Right Actions (Neek v1/v2/sucking/pee)
-- Open menu key: E (0x45)
-- No "Close" buttons in sections
-- =========================================================

-- ============== أدوات صغيرة ==============
local function vec2(x, y) return {x = x, y = y} end

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

-- ============== أدوات رؤية/تصادم اللاعب ==============
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

-- ============== Right Actions ==============
local ridingA, attachedToA = false, nil
local function ToggleRideOnClosest_A()
    if not ridingA then
        local targetPed = GetClosestPlayer()
        if targetPed then
            AttachEntityToEntity(PlayerPedId(), targetPed, 0, 0.0, -0.35, 0.10, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            PlayAnimation("rcmpaparazzo_2", "shag_loop_poppy", 1)
            ridingA, attachedToA = true, targetPed
        else
            print("[Right 1] لا يوجد لاعب قريب ضمن 70 متر.")
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
        else
            print("[Right 2] لا يوجد لاعب قريب ضمن 70 متر.")
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
        else
            print("[Right 3] لا يوجد لاعب قريب ضمن 70 متر.")
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
            PlayAnimation("misscarsteal2peeing", "peeing_outro", 1)
            ridingD, attachedToD = true, targetPed
        else
            print("[Right 4] لا يوجد لاعب قريب ضمن 70 متر.")
        end
    else
        ClearDetach()
        ridingD, attachedToD = false, nil
    end
end

-- ============== إعداد تخطيط المنيو (قسمين) ==============
local MenuSize = vec2(500, 300)
local MenuStartCoords = vec2(500, 500)

local TabsBarWidth = 0
local SectionsCount = 3
local SectionsPadding = 10
local MachoPaneGap = 10
local SectionChildWidth = MenuSize.x - TabsBarWidth
local EachSectionWidth = (SectionChildWidth - (SectionsPadding * (SectionsCount + 1))) / SectionsCount

local SectionOneStart = vec2(TabsBarWidth + (SectionsPadding * 1) + (EachSectionWidth * 0), SectionsPadding + MachoPaneGap)
local SectionOneEnd   = vec2(SectionOneStart.x + EachSectionWidth, MenuSize.y - SectionsPadding)

local SectionTwoStart = vec2(TabsBarWidth + (SectionsPadding * 2) + (EachSectionWidth * 1), SectionsPadding + MachoPaneGap)
local SectionTwoEnd   = vec2(SectionTwoStart.x + EachSectionWidth, MenuSize.y - SectionsPadding)

-- ============== إنشاء نافذة المنيو ==============
MenuWindow = MachoMenuWindow(MenuStartCoords.x, MenuStartCoords.y, MenuSize.x, MenuSize.y)
MachoMenuSetAccent(MenuWindow, 137, 52, 235)
MachoMenuSetKeybind(MenuWindow, 0x45) -- E (فتح/إظهار المنيو)

-- ============== Section One (Animation) ==============
FirstSection = MachoMenuGroup(MenuWindow, "Animation", SectionOneStart.x, SectionOneStart.y, SectionOneEnd.x, SectionOneEnd.y)

-- Super Jump
MachoMenuCheckbox(FirstSection, "Super Jump",
    function() superJump = true end,
    function() superJump = false end
)

-- Fast Run
MachoMenuCheckbox(FirstSection, "Fast Run",
    function() fastRun = true end,
    function() fastRun = false end
)

-- Noclip Toggle via F2 (زر تفعيل من المنيو + تبديل بالفزر)
local NoclipBtn
local function UpdateNoclipText()
    if NoclipBtn then
        local label = menuNoclipEnabled and "Noclip (F2): ON" or "Noclip (F2): OFF"
        MachoMenuSetText(NoclipBtn, label)
    end
end

NoclipBtn = MachoMenuCheckbox(FirstSection, "Noclip (F2): OFF",
    function()
        menuNoclipEnabled = true
        UpdateNoclipText()
    end,
    function()
        menuNoclipEnabled = false
        if noclip then
            noclip = false
            local ped = PlayerPedId()
            SetPedInvisible(ped, false)
            SetEntityInvincible(ped, false)
            SetPedCanRagdoll(ped, true)
            FreezeEntityPosition(ped, false)
            SetEntityVelocity(ped, 0.0, 0.0, 0.0)
        end
        UpdateNoclipText()
    end
)

-- GiveWeapon Button
MachoMenuButton(FirstSection, "GiveWeapon", function()
    local ped = PlayerPedId()

    GiveWeaponToPed(ped, GetHashKey("WEAPON_BAT"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("WEAPON_RPG"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("WEAPON_PUMPSHOTGUN"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("WEAPON_HEAVYSNIPER"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("WEAPON_DOUBLEACTION"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("WEAPON_MICROSMG"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("WEAPON_GUSENBERG"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("WEAPON_ADVANCEDRIFLE"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("weapon_acidpackage"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("WEAPON_SNOWLAUNCHER"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("WEAPON_MINIGUN"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("WEAPON_RAILGUN"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("WEAPON_FIREWORK"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("WEAPON_RAYMINIGUN"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("WEAPON_RAYPISTOL"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("weapon_flare"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("weapon_fireextinguisher"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("weapon_compactrifle"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("weapon_dbshotgun"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("weapon_flashlight"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("weapon_wrench"), 507, false, true)
    GiveWeaponToPed(ped, GetHashKey("weapon_raycarbine"), 507, false, true)

    TriggerEvent("ThundeR:Notify", {
        type = "success",
        messageheader = "3yoni3Leek :",
        message = "dis.gg/d99",
        img = "https://www.raed.net/img?id=721061",
        sound = "https://r2.guns.lol/4e861961-b10c-46fa-b571-4b744f19611f.mp3",
        voice = 0.5,
        timeout = 9000,
    })
end)

-- ============== Section Two (Vehicle) ==============
SecondSection = MachoMenuGroup(MenuWindow, "Vehicle", SectionTwoStart.x, SectionTwoStart.y, SectionTwoEnd.x, SectionTwoEnd.y)

MachoMenuButton(SecondSection, "Neek v1", function() ToggleRideOnClosest_A() end)
MachoMenuButton(SecondSection, "Neek v2", function() ToggleRideOnClosest_B() end)
MachoMenuButton(SecondSection, "sucking", function() ToggleRideOnClosest_C() end)
MachoMenuButton(SecondSection, "pee", function() ToggleRideOnClosest_D() end)

-- لا يوجد قسم ثالث

-- ============== F2 لتبديل الطيران (عند تفعيل زر المنيو) ==============
CreateThread(function()
    while true do
        Wait(0)
        -- 289 = F2 في FiveM
        if IsControlJustPressed(0, 289) then
            if menuNoclipEnabled then
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
                UpdateNoclipText()
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
    if MenuWindow then MachoMenuDestroy(MenuWindow) end
end)
