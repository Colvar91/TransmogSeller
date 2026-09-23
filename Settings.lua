local _, ns = ...
local L = ns.L
local window
local GOLD = {0.94, 0.77, 0.36}
local function Skin(frame, active)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    frame:SetBackdropColor(active and 0.29 or 0.12, active and 0.11 or 0.055, active and 0.43 or 0.20, 1)
    frame:SetBackdropBorderColor(0.65, 0.45, 0.17, 1)
end

local function Label(parent, text, x, y, width)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width or 490)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    label:SetTextColor(unpack(GOLD))
    return label
end
local function Button(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, 30)
    button:SetPoint("TOPLEFT", x, y)
    Skin(button)
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER")
    label:SetWidth(width - 12)
    label:SetTextColor(unpack(GOLD))
    button:SetFontString(label)
    button:SetText(text)
    button:SetScript("OnClick", callback)
    button:SetScript("OnEnter", function(self) Skin(self, true) end)
    button:SetScript("OnLeave", function(self) Skin(self, self.active) end)
    return button
end
local function Input(parent, x, y, width, numeric)
    local edit = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    edit:SetSize(width, 28)
    edit:SetPoint("TOPLEFT", x, y)
    Skin(edit)
    edit:SetFontObject("GameFontHighlight")
    edit:SetTextColor(unpack(GOLD))
    edit:SetTextInsets(8, 8, 0, 0)
    edit:SetAutoFocus(false)
    if numeric then edit:SetNumeric(true); edit:SetMaxLetters(4) end
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return edit
end
local function Check(parent, text, y, x, width)
    local check = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
    x = x or 24
    check:SetSize(22, 22)
    check:SetPoint("TOPLEFT", x, y)
    Skin(check)
    check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    Label(parent, text, x + 32, y - 3, width or 480)
    return check
end
local function SelectTab(key)
    window.activeTab = key
    for name, panel in pairs(window.panels) do
        if name == key then panel:Show() else panel:Hide() end
        window.tabs[name].active = name == key
        Skin(window.tabs[name], name == key)
    end
    window.level:ClearFocus(); window.batch:ClearFocus(); window.item:ClearFocus()
end
local function Refresh()
    local db = ns.GetDB()
    window.level:SetText(db.maxLevel and tostring(db.maxLevel) or "")
    window.batch:SetText(tostring(db.batch))
    window.enabled:SetChecked(db.enabled)
    window.sets:SetChecked(db.protectSets)
    window.special:SetChecked(db.protectSpecial)
    for _, key in ipairs(ns.FilterKeys) do window.filters[key]:SetChecked(db.filters[key]) end
    window.status:SetText(L.SAVE_HINT)
    SelectTab(window.activeTab or "general")
end
local function Save()
    local levelText = window.level:GetText()
    local level, batch = tonumber(levelText), tonumber(window.batch:GetText())
    if levelText ~= "" and (not level or level < 1 or level > 9999 or level ~= math.floor(level)) then
        window.status:SetText(L.BAD_LEVEL_UI)
        return false
    end
    if not batch or batch < 1 or batch > 12 or batch ~= math.floor(batch) then
        window.status:SetText(L.BAD_BATCH_UI)
        return false
    end
    ns.Stop()
    local db = ns.GetDB()
    db.maxLevel, db.batch = level, batch
    db.enabled = not not window.enabled:GetChecked()
    db.protectSets = not not window.sets:GetChecked()
    db.protectSpecial = not not window.special:GetChecked()
    for _, key in ipairs(ns.FilterKeys) do db.filters[key] = not not window.filters[key]:GetChecked() end
    window.level:ClearFocus(); window.batch:ClearFocus()
    window.status:SetText(level and L.SAVED_UI
        or L.SAVED_NO_LIMIT)
    return true
end
local function Exception(remove)
    local text = window.item:GetText()
    local id = tonumber(text:match("item:(%d+)")) or tonumber(text)
    if not id or id < 1 or id ~= math.floor(id) then
        window.status:SetText(L.BAD_ITEM_UI)
        return
    end
    ns.Stop()
    ns.GetDB().keep[id] = not remove and true or nil
    window.item:ClearFocus()
    window.status:SetText(L.ITEM_STATE:format(id, remove and L.RELEASED or L.PROTECTED))
end
local function CreateSettings()
    window = CreateFrame("Frame", "TransmogSellerSettings", UIParent, "BackdropTemplate")
    window:Hide()
    window:SetSize(600, 610)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:SetMovable(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(self) self:StartMoving() end)
    window:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    Skin(window)
    window:SetBackdropColor(0.055, 0.018, 0.095, 0.98)
    local title = Label(window, "TRANSMOGSELLER", 24, -20, 510)
    title:SetFontObject("GameFontNormalLarge")
    Label(window, L.SUBTITLE, 24, -48, 540)
    Button(window, "X", 548, -16, 28, function() window:Hide() end)
    table.insert(UISpecialFrames, "TransmogSellerSettings")
    window.panels, window.tabs, window.filters = {}, {}, {}
    for _, key in ipairs({"general", "filters"}) do
        local panel = CreateFrame("Frame", nil, window)
        panel:SetPoint("TOPLEFT", 0, -118)
        panel:SetSize(600, 370)
        window.panels[key] = panel
    end
    window.tabs.general = Button(window, L.TAB_GENERAL, 24, -78, 270, function() SelectTab("general") end)
    window.tabs.filters = Button(window, L.TAB_FILTERS, 306, -78, 270, function() SelectTab("filters") end)
    local general, filters = window.panels.general, window.panels.filters
    window.enabled = Check(general, L.AUTO_LABEL, -12)
    Label(general, L.LEVEL_LABEL, 24, -64, 400)
    window.level = Input(general, 456, -55, 120, true)
    Label(general, L.LEVEL_HINT, 24, -94, 540)
    Label(general, L.BATCH_LABEL, 24, -144, 400)
    window.batch = Input(general, 456, -135, 120, true)
    window.sets = Check(general, L.SETS_LABEL, -194)
    window.special = Check(general, L.SPECIAL_LABEL, -235)
    Label(general, L.SHIFT_HINT, 24, -297, 540)
    Label(filters, L.FILTER_HINT, 24, -5, 552)
    for index, key in ipairs(ns.FilterKeys) do
        local col, row = (index - 1) % 2, math.floor((index - 1) / 2)
        local y = -58 - row * 38
        if index >= 9 then y = y - 12 end
        window.filters[key] = Check(filters, L["FILTER_" .. key:upper()], y, 24 + col * 282, 242)
    end
    Label(filters, L.EXCEPTIONS_LABEL, 24, -266, 552)
    window.item = Input(filters, 24, -292, 552, false)
    Button(filters, L.KEEP_BUTTON, 24, -330, 176, function() Exception(false) end)
    Button(filters, L.RELEASE_BUTTON, 212, -330, 176, function() Exception(true) end)
    Button(filters, L.LIST_BUTTON, 400, -330, 176, function() SlashCmdList.TRANSMOGSELLER("list") end)
    window.status = Label(window, "", 24, -496, 552)
    window.status:SetHeight(42)
    Button(window, L.SAVE_BUTTON, 24, -555, 176, Save)
    Button(window, L.PREVIEW_BUTTON, 212, -555, 176, function()
        if Save() then ns.Preview() end
    end)
    Button(window, L.STOP_BUTTON, 400, -555, 176, function()
        ns.Stop(L.STOP_VISIT)
        window.status:SetText(L.CURRENT_STOPPED)
    end)
    window:SetScript("OnShow", Refresh)
    window:SetScript("OnHide", function(self)
        self:StopMovingOrSizing()
        self.level:ClearFocus(); self.batch:ClearFocus(); self.item:ClearFocus()
    end)
end
function ns.ToggleSettings()
    if not ns.GetDB() then return end
    if not window then CreateSettings() end
    if window:IsShown() then window:Hide() else window:Show() end
end
