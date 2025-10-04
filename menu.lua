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
        send({
            type  = "init",
            title = "3yoni3Leek",
            index = 0,
            items = {
                {label="Player", hasSub=true, hint="›"},
                {label="Vehicle", hasSub=true, hint="›"},
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

CreateThread(function()
    while true do
        Wait(0)

        -- DELETE gomb (178) nyit/zár
        if IsControlJustPressed(0, 178) then
            if visible then closeMenu() else openMenu() end
        end

        if visible then
            -- egyszerű nyílvezérlés, nincs input tiltás
            if IsControlJustPressed(0, 172) then send({type="move",  delta=-1}) end -- ↑
            if IsControlJustPressed(0, 173) then send({type="move",  delta=1})  end -- ↓
            if IsControlJustPressed(0, 174) then send({type="closeSub"}) end        -- ←
            if IsControlJustPressed(0, 175) then send({type="openSub"})  end        -- →
            if IsControlJustPressed(0, 176) then send({type="confirm"})  end        -- Enter
            if IsControlJustPressed(0, 177) then send({type="closeSub"}) end        -- Back
        end
    end
end)
