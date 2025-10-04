-- menu.lua (كامل)
local dui, visible = nil, false
local MENU_URL = "https://xaziz-code.github.io/3yoni/" -- غيّره إلى رابط صفحتك إن لزم

-- عناصر القائمة الرئيسية (animation أول عنصر)
local items = {
    {label="animation", hasSub=true, hint="›"},
    {label="Vehicle",  hasSub=true, hint="›"},
    {label="Add",      hasSub=true, hint="›"},
    {label="Settings", hasSub=true, hint="›"},
}

-- تتبّع الفهارس والحالة
local mainIndex   = 0
local submenuOpen = false
local subIndex    = 0

-- عناصر قائمة animation الفرعية
local animSubItems = {
    { label = "Right 1 (A)" },
    { label = "Right 2 (B)" },
    { label = "Right 3 (C)" },
    { label = "Right 4 (D)" },
}

-- إرسال رسالة إلى الصفحة
local function send(m)
    if dui then
        MachoSendDuiMessage(dui, json.encode(m))
    end
end

-- دوال مساعدة
local function PlayAnimation(dict, name, flag)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
    TaskPlayAnim(PlayerPedId(), dict, name, 8.0, -8.0, -1, flag or 1, 0.0, false, false, false)
end

local function ClearDetach()
    DetachEntity(PlayerPedId(), true, true)
    ClearPedTasksImmediately(PlayerPedId())
end

local function GetClosestPlayer()
    local pPed = PlayerPedId()
    local pCoords = GetEntityCoords(pPed)
    local closest, minDist = nil, 70.0
    for _, pid in ipairs(GetActivePlayers()) do
        if pid ~= PlayerId() then
            local ped = GetPlayerPed(pid)
            local dist = #(GetEntityCoords(ped) - pCoords)
            if dist < minDist then closest, minDist = ped, dist end
        end
    end
    return closest
end

-- الحركات التي طلبتها (A/B/C/D)
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

-- فتح/إغلاق القائمة
local function openMenu()
    if not dui then
        dui = MachoCreateDui(MENU_URL)
        if not dui then
            print("^1[MachoDUI] فشل إنشاء DUI^0")
            return
        end
        Citizen.Wait(200)
        send({ type="init", title="Discord.gg/D99", index=mainIndex, items=items })
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
end

-- فتح/إغلاق قائمة animation الفرعية
local function openAnimationSub()
    submenuOpen = true
    subIndex = 0
    send({
        type  = "openSubWith",
        title = "animation",
        items = animSubItems,
        index = subIndex
    })
end

local function closeSub()
    if not submenuOpen then return end
    submenuOpen = false
    send({type="closeSub"})
end

-- تشغيل الحركة المختارة
local function runSelectedAnimation()
    if subIndex == 0 then ToggleRideOnClosest_A()
    elseif subIndex == 1 then ToggleRideOnClosest_B()
    elseif subIndex == 2 then ToggleRideOnClosest_C()
    elseif subIndex == 3 then ToggleRideOnClosest_D()
    end
end

-- الحلقة الرئيسية للمفاتيح
CreateThread(function()
    while true do
        Wait(0)

        -- Delete يفتح/يغلق القائمة
        if IsControlJustPressed(0, 178) then
            if visible then closeMenu() else openMenu() end
        end

        if visible then
            -- ↑
            if IsControlJustPressed(0, 172) then
                if submenuOpen and mainIndex == 0 then
                    subIndex = math.max(0, subIndex - 1)
                    send({type="moveSub", delta=-1})
                else
                    mainIndex = math.max(0, mainIndex - 1)
                    send({type="move", delta=-1})
                end
            end

            -- ↓
            if IsControlJustPressed(0, 173) then
                if submenuOpen and mainIndex == 0 then
                    subIndex = math.min(#animSubItems-1, subIndex + 1)
                    send({type="moveSub", delta=1})
                else
                    mainIndex = math.min(#items-1, mainIndex + 1)
                    send({type="move", delta=1})
                end
            end

            -- ← رجوع
            if IsControlJustPressed(0, 174) then
                if submenuOpen then closeSub() else send({type="closeSub"}) end
            end

            -- → أو Enter
            if IsControlJustPressed(0, 175) or IsControlJustPressed(0, 176) then
                if not submenuOpen then
                    -- إذا المؤشر على animation افتح submenu
                    if mainIndex == 0 then
                        openAnimationSub()
                    else
                        -- لقوائم أخرى مستقبلية
                        send({type="openSub"})
                    end
                else
                    -- داخل animation: نفّذ الحركة المحددة
                    if mainIndex == 0 then runSelectedAnimation() end
                end
            end

            -- Back
            if IsControlJustPressed(0, 177) then
                if submenuOpen then closeSub() else send({type="closeSub"}) end
            end
        end
    end
end)
