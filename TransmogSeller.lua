local addonName, ns = ...
local L = ns.L
local frame = CreateFrame("Frame")
local db, ticker, queue, started, merchantOpen
local attempts, unresolved = 0, 0
local BAG_LAST = NUM_BAG_SLOTS or 4
local slots = {
    INVTYPE_HEAD=true, INVTYPE_NECK=true, INVTYPE_SHOULDER=true,
    INVTYPE_BODY=true, INVTYPE_CHEST=true, INVTYPE_ROBE=true,
    INVTYPE_WAIST=true, INVTYPE_LEGS=true, INVTYPE_FEET=true,
    INVTYPE_WRIST=true, INVTYPE_HAND=true, INVTYPE_FINGER=true,
    INVTYPE_TRINKET=true, INVTYPE_CLOAK=true, INVTYPE_WEAPON=true,
    INVTYPE_SHIELD=true, INVTYPE_2HWEAPON=true, INVTYPE_WEAPONMAINHAND=true,
    INVTYPE_WEAPONOFFHAND=true, INVTYPE_HOLDABLE=true, INVTYPE_RANGED=true,
    INVTYPE_RANGEDRIGHT=true, INVTYPE_THROWN=true, INVTYPE_TABARD=true,
}
ns.FilterKeys = {"armor", "weapons", "rings", "trinkets", "neck", "cloaks", "offhands", "cosmetics", "bound", "unbound"}
local function Category(classID, equipLoc)
    if equipLoc == "INVTYPE_FINGER" then return "rings" end
    if equipLoc == "INVTYPE_TRINKET" then return "trinkets" end
    if equipLoc == "INVTYPE_NECK" then return "neck" end
    if equipLoc == "INVTYPE_CLOAK" then return "cloaks" end
    if equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_HOLDABLE" then return "offhands" end
    if equipLoc == "INVTYPE_BODY" or equipLoc == "INVTYPE_TABARD" then return "cosmetics" end
    return classID == 2 and "weapons" or "armor"
end
local function Say(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ddbbTransmogSeller:|r " .. text)
end
local function EachBag(callback)
    for bag=0,BAG_LAST do
        for slot=1,C_Container.GetContainerNumSlots(bag) do callback(bag, slot) end
    end
end
local function GUID(bag, slot)
    return C_Item.GetItemGUID(ItemLocation:CreateFromBagAndSlot(bag, slot))
end
-- No binding check: both soulbound and unbound BoE gear are eligible.
-- Unknown item data is never treated as item level zero.
local function Eligible(bag, slot)
    local item = C_Container.GetContainerItemInfo(bag, slot)
    if not item then return false end
    if db.keep[item.itemID] or item.hasNoValue or item.hasLoot then return false end
    if item.isLocked then return nil end
    local quest = C_Container.GetContainerItemQuestInfo(bag, slot)
    if quest and (quest.isQuestItem or quest.questID) then return false end
    if db.protectSets and C_Container.GetContainerItemEquipmentSetInfo(bag, slot) then
        return false
    end
    local name, _, quality, _, _, _, _, _, equipLoc, _, price, classID =
        C_Item.GetItemInfo(item.hyperlink or item.itemID)
    if not name then
        C_Item.RequestLoadItemDataByID(item.itemID)
        return nil
    end
    if (classID ~= 2 and classID ~= 4) or not slots[equipLoc] then return false end
    if not db.filters[Category(classID, equipLoc)] then return false end
    if not db.filters[item.isBound and "bound" or "unbound"] then return false end
    if not price or price <= 0 then return false end
    -- Legendary / artifact / heirloom protection can explicitly be disabled.
    if db.protectSpecial and (not quality or quality >= 5) then return false end
    local level = C_Item.GetDetailedItemLevelInfo(item.hyperlink)
    if not level then return nil end
    return db.maxLevel ~= nil and level <= db.maxLevel, item.hyperlink, level
end
local function Stop(message)
    if ticker then ticker:Cancel(); ticker = nil end
    queue = nil
    if message then Say(message) end
end
local function Tick()
    if not merchantOpen or not MerchantFrame or not MerchantFrame:IsShown()
        or InCombatLockdown() or not db.enabled or IsShiftKeyDown() then
        Stop(L.STOPPED)
        return
    end
    if CursorHasItem() then Stop(L.CURSOR_STOP); return end
    local now, sent, remaining = GetTime(), 0, 0
    for _,entry in ipairs(queue) do
        if not entry.done then
            local current = C_Container.GetContainerItemInfo(entry.bag, entry.slot)
            -- A queued slot is never trusted after its actual item changed.
            if not current or GUID(entry.bag, entry.slot) ~= entry.guid then
                entry.done = true
            elseif now - started > 60 then
                unresolved = unresolved + 1; entry.done = true
            elseif not entry.lastTry or now - entry.lastTry >= 1 then
                local eligible = Eligible(entry.bag, entry.slot)
                if eligible == false then
                    entry.done = true
                elseif eligible == nil and now - started > 5 and not entry.lastTry then
                    unresolved = unresolved + 1; entry.done = true
                elseif eligible and (entry.tries or 0) >= 3 then
                    unresolved = unresolved + 1; entry.done = true
                elseif eligible and sent < db.batch then
                    -- Recheck the merchant immediately before every use call.
                    if not merchantOpen or not MerchantFrame:IsShown() or InCombatLockdown() then
                        Stop(L.STOPPED); return
                    end
                    entry.lastTry, entry.tries = now, (entry.tries or 0) + 1
                    sent, attempts = sent + 1, attempts + 1
                    C_Container.UseContainerItem(entry.bag, entry.slot)
                end
            end
            if not entry.done then remaining = remaining + 1 end
        end
    end
    if remaining == 0 then
        if attempts > 0 or unresolved > 0 then
            Stop(L.FINISHED:format(unresolved))
        else Stop() end
    end
end
local function Start()
    Stop()
    if not db.enabled or not merchantOpen or IsShiftKeyDown() then return end
    if not db.maxLevel then
        Say(L.SET_LIMIT)
        return
    end
    if InCombatLockdown() or CursorHasItem() then return end
    queue, attempts, unresolved, started = {}, 0, 0, GetTime()
    EachBag(function(bag, slot)
        if C_Container.GetContainerItemInfo(bag, slot) then
            local guid = GUID(bag, slot)
            if guid and guid ~= "" then
                queue[#queue+1] = {bag=bag, slot=slot, guid=guid}
            end
        end
    end)
    ticker = C_Timer.NewTicker(0.10, Tick)
end
local function Preview()
    if not db.maxLevel then Say(L.NEED_LIMIT); return end
    local count, pending = 0, 0
    EachBag(function(bag, slot)
        local eligible, link, level = Eligible(bag, slot)
        if eligible then
            count = count + 1
            Say(L.PREVIEW_ITEM:format(link, tostring(level)))
        elseif eligible == nil then pending = pending + 1 end
    end)
    Say(L.PREVIEW_TOTAL:format(count, pending))
end
local function Help()
    Say(L.STATUS:format(tostring(db.maxLevel or L.UNSET), db.enabled and L.ON or L.OFF))
    Say(L.HELP_LEVEL)
    Say("/ts on | off | preview | sell | stop")
    Say(L.HELP_KEEP)
    Say(L.HELP_BATCH)
    Say(L.HELP_PROTECTION)
    Say(L.HELP_SHIFT)
end
SLASH_TRANSMOGSELLER1 = "/ts"
SlashCmdList.TRANSMOGSELLER = function(text)
    if not db then return end
    local cmd, arg = text:match("^%s*(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()
    if cmd == "" or cmd == "config" then ns.ToggleSettings(); return
    elseif cmd == "ilvl" then
        local n = tonumber(arg)
        if not n or n < 1 or n > 9999 or n ~= math.floor(n) then Say(L.EXAMPLE); return end
        Stop(); db.maxLevel = n
        Say(L.LIMIT_SAVED:format(n))
    elseif cmd == "on" or cmd == "off" then
        Stop(); db.enabled = cmd == "on"
        Say(L.AUTO_STATE:format(db.enabled and L.ON or L.OFF))
    elseif cmd == "preview" then Preview()
    elseif cmd == "stop" then Stop(L.STOP_VISIT)
    elseif cmd == "sell" then
        if not merchantOpen then Say(L.OPEN_MERCHANT)
        elseif not db.enabled then Say(L.AUTO_DISABLED)
        else Start() end
    elseif cmd == "keep" or cmd == "unkeep" then
        local id = tonumber(arg:match("item:(%d+)")) or tonumber(arg)
        if not id or id < 1 or id ~= math.floor(id) then Say(L.NEED_ITEM); return end
        Stop(); db.keep[id] = cmd == "keep" and true or nil
        Say(L.ITEM_STATE:format(id, cmd == "keep" and L.PROTECTED or L.RELEASED))
    elseif cmd == "list" then
        local count = 0
        for id in pairs(db.keep) do Say(L.PROTECTED_ITEM:format(id)); count = count + 1 end
        Say(L.EXCEPTION_COUNT:format(count))
    elseif cmd == "sets" or cmd == "special" then
        if arg ~= "on" and arg ~= "off" then Say(L.NEED_TOGGLE); return end
        Stop(); db[cmd == "sets" and "protectSets" or "protectSpecial"] = arg == "on"
        Say(L.PROTECTION_STATE:format(cmd == "sets" and L.SETS_LABEL or L.SPECIAL_LABEL, arg == "on" and L.ON or L.OFF))
    elseif cmd == "batch" then
        local n = tonumber(arg)
        if not n or n < 1 or n > 12 or n ~= math.floor(n) then Say(L.BAD_BATCH); return end
        Stop(); db.batch = n; Say(L.BATCH_SAVED:format(n))
    else Help() end
end
ns.GetDB = function() return db end
ns.Stop = Stop
ns.Preview = Preview
ns.Say = Say
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("MERCHANT_SHOW")
frame:RegisterEvent("MERCHANT_CLOSED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_LEAVING_WORLD")
frame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        TransmogSellerDB = TransmogSellerDB or {}
        db = TransmogSellerDB
        if db.enabled == nil then db.enabled = true end
        if db.protectSets == nil then db.protectSets = true end
        if db.protectSpecial == nil then db.protectSpecial = true end
        db.keep = type(db.keep) == "table" and db.keep or {}
        db.filters = type(db.filters) == "table" and db.filters or {}
        -- Preserve explicit exclusions; new installations/upgrades retain prior behavior.
        for _, key in ipairs(ns.FilterKeys) do
            if type(db.filters[key]) ~= "boolean" then db.filters[key] = true end
        end
        if type(db.batch) ~= "number" or db.batch < 1 or db.batch > 12 then db.batch = 8 end
        if type(db.maxLevel) ~= "number" or db.maxLevel < 1 or db.maxLevel > 9999 then db.maxLevel = nil end
        if not db.maxLevel then Say(L.READY) end
    elseif event == "MERCHANT_SHOW" and db then
        merchantOpen = true; Start()
    elseif event == "MERCHANT_CLOSED" or event == "PLAYER_LEAVING_WORLD" then
        merchantOpen = false; Stop()
    elseif event == "PLAYER_REGEN_DISABLED" then Stop() end
end)
