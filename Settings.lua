local _, ns = ...
local L = ns.L
local window

local function Label(parent, text, x, y, width)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width or 490)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end
local function Button(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 26)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", callback)
    return button
end
local function Input(parent, x, y, width, numeric)
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetSize(width, 26)
    edit:SetPoint("TOPLEFT", x, y)
    edit:SetAutoFocus(false)
    if numeric then edit:SetNumeric(true); edit:SetMaxLetters(4) end
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return edit
end
local function Check(parent, text, y)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(26, 26)
    check:SetPoint("TOPLEFT", 20, y)
    -- Explicit label avoids dependence on template-generated global names.
    Label(parent, text, 52, y - 6, 465)
    return check
end
local function Refresh()
    local db = ns.GetDB()
    window.level:SetText(db.maxLevel and tostring(db.maxLevel) or "")
    window.batch:SetText(tostring(db.batch))
    window.enabled:SetChecked(db.enabled)
    window.sets:SetChecked(db.protectSets)
    window.special:SetChecked(db.protectSpecial)
    window.status:SetText(L.SAVE_HINT)
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
    window:SetSize(540, 530)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:SetMovable(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(self) self:StartMoving() end)
    window:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    window:SetBackdrop({
        bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=16,
        insets={left=4, right=4, top=4, bottom=4},
    })
    window:SetBackdropColor(0.055, 0.065, 0.08, 0.98)
    window:SetBackdropBorderColor(0.20, 0.75, 0.65, 1)
    local title = Label(window, "TransmogSeller", 24, -20)
    title:SetFontObject("GameFontNormalLarge")
    Label(window, L.SUBTITLE, 24, -45)
    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3)
    close:SetScript("OnClick", function() window:Hide() end)
    table.insert(UISpecialFrames, "TransmogSellerSettings")

    window.enabled = Check(window, L.AUTO_LABEL, -77)
    Label(window, L.LEVEL_LABEL, 24, -123, 375)
    window.level = Input(window, 415, -115, 95, true)
    Label(window, L.LEVEL_HINT, 24, -150)
    Label(window, L.BATCH_LABEL, 24, -190, 375)
    window.batch = Input(window, 415, -182, 95, true)
    window.sets = Check(window, L.SETS_LABEL, -228)
    window.special = Check(window, L.SPECIAL_LABEL, -263)

    Label(window, L.EXCEPTIONS_LABEL, 24, -312)
    window.item = Input(window, 28, -334, 482, false)
    Button(window, L.KEEP_BUTTON, 24, -368, 152, function() Exception(false) end)
    Button(window, L.RELEASE_BUTTON, 192, -368, 152, function() Exception(true) end)
    Button(window, L.LIST_BUTTON, 360, -368, 152, function() SlashCmdList.TRANSMOGSELLER("list") end)
    window.status = Label(window, "", 24, -408, 488)
    window.status:SetHeight(38)

    Button(window, L.SAVE_BUTTON, 24, -453, 152, Save)
    Button(window, L.PREVIEW_BUTTON, 192, -453, 152, function()
        if Save() then ns.Preview() end
    end)
    Button(window, L.STOP_BUTTON, 360, -453, 152, function()
        ns.Stop(L.STOP_VISIT)
        window.status:SetText(L.CURRENT_STOPPED)
    end)
    Label(window, L.SHIFT_HINT, 24, -496, 492)
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
