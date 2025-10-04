local dui, visible = nil, false
local MENU_URL = "https://xaziz-code.github.io/3yoni/"

local function send(m)
    if dui then
        MachoSendDuiMessage(dui, json.encode(m))
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

        -- init الأساسيات
        send({
            type  = "init",
            title = "Discord.gg/D99",
            index = 0,
            items = {
                {label="Player",   hasSub=true, hint="›"},
                {label="Vehicle",  hasSub=true, hint="›"},
                {label="Add",      hasSub=true, hint="›"},
                {label="Settings", hasSub=true, hint="›"}
            }
        })

        -- جديد: حقن عناصر Player (index = 0)
        send({
            type = "setSub",
            index = 0,
            sub = {
                { type="toggle", label="Super Jump",       action="player:superJump",        state=false },
                { type="toggle", label="Fast Run",         action="player:fastRun",          state=false },
                { type="toggle", label="Noclip Key (F2)",  action="player:menuNoclipEnabled",state=false },
                { type="button", label="Remove Weapons",   action="player:removeWeapons" }
            }
        })

        -- جديد: حقن عناصر Vehicle (index = 1)
        send({
            type = "setSub",
            index = 1,
            sub = {
                { type="button", label="Infos",  action="vehicle:info" },
                { type="button", label="Repair", action="vehicle:repair" },
            }
        })

        -- جديد: حقن عناصر Add (index = 2) – عناصر “SEX” عندك
        send({
            type = "setSub",
            index = 2,
            sub = {
                { type="button", label="Neek v1", action="player:rideA" },
                { type="button", label="Neek v2", action="player:rideB" },
                { type="button", label="sucking", action="player:rideC" },
                { type="button", label="pee",     action="player:rideD" },
            }
        })

        -- جديد: حقن عناصر Settings (index = 3)
        send({
            type = "setSub",
            index = 3,
            sub = {
                { type="button", label="Language: AR", action="settings:lang", value="ar" },
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

CreateThread(function()
    while true do
        Wait(0)

        -- DELETE (178) فتح/إغلاق المنيو
        if IsControlJustPressed(0, 178) then
            if visible then closeMenu() else openMenu() end
        end

        if visible then
            -- أسهم وتحكمات بسيطة
            if IsControlJustPressed(0, 172) then send({type="move",  delta=-1}) end -- ↑
            if IsControlJustPressed(0, 173) then send({type="move",  delta=1})  end -- ↓
            if IsControlJustPressed(0, 174) then send({type="closeSub"}) end        -- ←
            if IsControlJustPressed(0, 175) then send({type="openSub"})  end        -- →
            if IsControlJustPressed(0, 176) then send({type="confirm"})  end        -- Enter
            if IsControlJustPressed(0, 177) then send({type="closeSub"}) end        -- Back
        end
    end
end)
