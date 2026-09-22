import sys
from pathlib import Path
import json
import re
ROOT = Path(__file__).resolve().parents[1]
from lupa.lua51 import LuaRuntime

source = (ROOT / 'TransmogSeller.lua').read_text(encoding='utf-8')
mock = r'''
now=0; bags={}; sales={}; messages={}; combat=false; shift=false; cursor=false
SlashCmdList={}; NUM_BAG_SLOTS=4
DEFAULT_CHAT_FRAME={AddMessage=function(_,s) table.insert(messages,s) end}
widgets={}; UISpecialFrames={}; UIParent={}
local methods={}
local noop=function() end
for _,k in ipairs({'SetPoint','SetSize','SetWidth','SetHeight','SetJustifyH','SetFontObject','SetAutoFocus','SetNumeric','SetMaxLetters','ClearFocus','SetFrameStrata','SetClampedToScreen','EnableMouse','SetMovable','RegisterForDrag','StartMoving','StopMovingOrSizing','SetBackdrop','SetBackdropColor','SetBackdropBorderColor','RegisterEvent'}) do methods[k]=noop end
function methods:SetText(s) self.text=s end
function methods:GetText() return self.text or '' end
function methods:SetChecked(b) self.checked=b end
function methods:GetChecked() return self.checked end
function methods:IsShown() return self.visible end
function methods:Show() self.visible=true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:Hide() self.visible=false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:SetScript(k,fn) self.scripts[k]=fn; if k=='OnEvent' then event=fn end end
function methods:CreateFontString() return CreateFrame('FontString') end
function CreateFrame(kind,name,parent,template)
 local w=setmetatable({scripts={},visible=true},{__index=methods})
 if name then _G[name]=w end
 table.insert(widgets,w); return w
end
function click(text)
 for _,w in ipairs(widgets) do if w.text==text and w.scripts.OnClick then w.scripts.OnClick(w); return end end
 error('button not found: '..text)
end
function GetTime() return now end
function InCombatLockdown() return combat end
function IsShiftKeyDown() return shift end
function CursorHasItem() return cursor end
MerchantFrame={IsShown=function() return shown end}
ItemLocation={CreateFromBagAndSlot=function(_,b,s) return {b=b,s=s} end}
C_Timer={NewTicker=function(_,fn) timer={fn=fn,Cancel=function(self) self.cancelled=true end}; return timer end}
function get(b,s) return bags[b] and bags[b][s] end
C_Container={
 GetContainerNumSlots=function(b) return b==0 and 160 or 0 end,
 GetContainerItemInfo=get,
 GetContainerItemQuestInfo=function(b,s) return {isQuestItem=get(b,s).quest} end,
 GetContainerItemEquipmentSetInfo=function(b,s) return get(b,s).set or false end,
 UseContainerItem=function(b,s)
  assert(shown and not combat, 'use outside merchant')
  table.insert(sales,get(b,s).itemID)
  if not blocked then bags[b][s]=nil end
  if closeAfterSale then shown=false; event(nil,'MERCHANT_CLOSED') end
 end,
}
C_Item={
 GetItemGUID=function(loc) return get(loc.b,loc.s).guid end,
 RequestLoadItemDataByID=function() end,
 GetItemInfo=function(link)
  local i=items[link]; if i.uncached then return nil end
  return 'Item',link,i.quality or 4,999,1,'','',1,i.equip or 'INVTYPE_CHEST',1,i.price or 100,i.class or 4
 end,
 GetDetailedItemLevelInfo=function(link) return items[link].level end,
}
items={}
function add(s,opts)
 local i=opts or {}; i.itemID=i.itemID or s; i.guid=i.guid or ('g'..s)
 i.hyperlink='item:'..i.itemID; if i.level==nil and not i.noLevel then i.level=100 end
 bags[0]=bags[0] or {}; bags[0][s]=i; items[i.hyperlink]=i; return i
end
function cmd(s) SlashCmdList.TRANSMOGSELLER(s) end
function open() shown=true; event(nil,'MERCHANT_SHOW') end
function advance(n) for i=1,n do now=now+0.1; if timer and not timer.cancelled then timer.fn() end end end
'''

def run(name, code, locale='deDE'):
    lua = LuaRuntime()
    lua.execute(mock)
    lua.globals().GetLocale = lambda: locale
    namespace = lua.table()
    lua.execute((ROOT / 'Locales.lua').read_text(encoding='utf-8'), 'TransmogSeller', namespace)
    lua.globals().L = namespace.L
    lua.execute(source, 'TransmogSeller', namespace)
    lua.execute((ROOT / 'Settings.lua').read_text(encoding='utf-8'), 'TransmogSeller', namespace)
    lua.execute("event(nil,'ADDON_LOADED','TransmogSeller')")
    lua.execute(code)
    return lua, namespace

cases = {
 'unconfigured never sells': 'add(1); open(); advance(20); assert(#sales==0)',
 'inclusive actual item level': 'add(1,{level=100}); add(2,{level=101}); cmd("ilvl 100"); open(); advance(5); assert(#sales==1 and sales[1]==1)',
 'bound and BoE, armor weapons rings trinkets': 'for i,e in ipairs({"INVTYPE_CHEST","INVTYPE_WEAPON","INVTYPE_FINGER","INVTYPE_TRINKET"}) do add(i,{equip=e,isBound=i%2==0,class=i==2 and 2 or 4}) end; cmd("ilvl 100"); open(); advance(5); assert(#sales==4)',
 'protect special sets exceptions quests bags zero price': 'add(1,{quality=5});add(2,{quality=6});add(3,{quality=7});add(4,{set=true});add(5,{quest=true});add(6,{equip="INVTYPE_BAG"});add(7,{price=0});add(8,{hasNoValue=true});add(9);cmd("keep 9");cmd("ilvl 100");open();advance(10);assert(#sales==0)',
 'non gear and unopened loot': 'add(1,{class=15});add(2,{hasLoot=true});cmd("ilvl 100");open();advance(10);assert(#sales==0)',
 'explicit protection override': 'add(1,{quality=5,set=true});cmd("special off");cmd("sets off");cmd("ilvl 100");open();advance(5);assert(#sales==1)',
 'unknown item data never sold': 'add(1,{uncached=true});add(2,{noLevel=true});cmd("ilvl 100");open();advance(140);assert(#sales==0 and timer.cancelled)',
 'deferred cache load and unlock': 'local a=add(1,{uncached=true});local b=add(2,{isLocked=true});cmd("ilvl 100");open();advance(2);a.uncached=false;b.isLocked=false;advance(5);assert(#sales==2)',
 'preview has no side effects': 'add(1);cmd("ilvl 100");cmd("preview");assert(#sales==0)',
 'batch bounded and whole inventory drained': 'for i=1,150 do add(i) end;cmd("ilvl 100");open();advance(1);assert(#sales==8);advance(25);assert(#sales==150 and timer.cancelled)',
 'merchant closure cancels pending work': 'add(1);cmd("ilvl 100");open();shown=false;event(nil,"MERCHANT_CLOSED");advance(5);assert(#sales==0)',
 'merchant closure inside batch': 'for i=1,20 do add(i) end;closeAfterSale=true;cmd("ilvl 100");open();advance(5);assert(#sales==1)',
 'combat abort': 'add(1);cmd("ilvl 100");open();combat=true;event(nil,"PLAYER_REGEN_DISABLED");advance(5);assert(#sales==0)',
 'shift skips entire visit': 'add(1);cmd("ilvl 100");shift=true;open();shift=false;advance(5);assert(#sales==0)',
 'shift stops ongoing sale': 'for i=1,20 do add(i) end;cmd("ilvl 100");open();advance(1);shift=true;advance(2);assert(#sales==8)',
 'cursor abort': 'add(1);cmd("ilvl 100");open();cursor=true;advance(2);assert(#sales==0)',
 'slot replacement never sold': 'add(1);cmd("ilvl 100");open();add(1,{guid="replacement"});advance(5);assert(#sales==0)',
 'failed sales bounded retries': 'add(1);blocked=true;cmd("ilvl 100");open();advance(140);assert(#sales==3 and timer.cancelled)',
 'stop and off cancel': 'add(1);cmd("ilvl 100");open();cmd("stop");advance(5);assert(#sales==0);cmd("off");open();advance(5);assert(#sales==0)',
 'limit change cancels active queue': 'add(1);cmd("ilvl 100");open();cmd("ilvl 50");advance(5);assert(#sales==0)',
 'invalid settings ignored': 'cmd("ilvl -1");cmd("ilvl 1.5");cmd("batch 500");assert(TransmogSellerDB.maxLevel==nil and TransmogSellerDB.batch==8)',
 'keep link and remove': 'add(1);cmd("keep |cff00ff00|Hitem:1:0|h[Test]|h|r");assert(TransmogSellerDB.keep[1]);cmd("unkeep 1");cmd("ilvl 100");open();advance(5);assert(#sales==1)',
 'settings toggle and load values': 'cmd("ilvl 123");cmd("");assert(TransmogSellerSettings:IsShown());assert(TransmogSellerSettings.level:GetText()=="123");cmd("");assert(not TransmogSellerSettings:IsShown());assert(#UISpecialFrames==1)',
 'settings save all controls': 'cmd("");local w=TransmogSellerSettings;w.level:SetText("155");w.batch:SetText("4");w.enabled:SetChecked(false);w.sets:SetChecked(false);w.special:SetChecked(false);click("Speichern");assert(TransmogSellerDB.maxLevel==155 and TransmogSellerDB.batch==4 and not TransmogSellerDB.enabled and not TransmogSellerDB.protectSets and not TransmogSellerDB.protectSpecial)',
 'settings validation atomic': 'cmd("ilvl 100");cmd("");local w=TransmogSellerSettings;w.level:SetText("50");w.batch:SetText("13");click("Speichern");assert(TransmogSellerDB.maxLevel==100 and TransmogSellerDB.batch==8);w.batch:SetText("4");w.level:SetText("0");click("Speichern");assert(TransmogSellerDB.batch==8)',
 'settings blank limit disarms': 'add(1);cmd("ilvl 100");cmd("");TransmogSellerSettings.level:SetText("");click("Speichern");open();advance(5);assert(TransmogSellerDB.maxLevel==nil and #sales==0)',
 'settings preview saves without sale': 'add(1);cmd("");TransmogSellerSettings.level:SetText("100");click("Vorschau");assert(#sales==0 and TransmogSellerDB.maxLevel==100)',
 'settings exceptions': 'cmd("");local w=TransmogSellerSettings;w.item:SetText("item:77:0");click("Schützen");assert(TransmogSellerDB.keep[77]);click("Freigeben");assert(not TransmogSellerDB.keep[77]);w.item:SetText("invalid");click("Schützen");assert(next(TransmogSellerDB.keep)==nil)',
 'settings close discards unsaved edits': 'cmd("ilvl 100");cmd("");TransmogSellerSettings.level:SetText("200");cmd("");cmd("");assert(TransmogSellerSettings.level:GetText()=="100")',
 'settings stop cancels active sale': 'add(1);cmd("ilvl 100");open();cmd("");click("Verkauf stoppen");advance(5);assert(#sales==0)',
 'settings save cancels active sale': 'add(1);cmd("ilvl 100");open();cmd("");click("Speichern");advance(5);assert(#sales==0)',
}
cases['localized chat commands and formatting'] = '''
cmd('help');cmd('sell');cmd('ilvl invalid');cmd('ilvl 100');cmd('preview');
cmd('off');open();cmd('sell');cmd('on');cmd('keep invalid');cmd('keep 77');cmd('list');
cmd('unkeep 77');cmd('sets invalid');cmd('sets on');cmd('special off');cmd('batch 0');
cmd('batch 3');cmd('help');cmd('stop');assert(#messages>15)
'''
for name, code in list(cases.items()):
    for german, key in {'Speichern':'SAVE_BUTTON', 'Schützen':'KEEP_BUTTON',
                        'Freigeben':'RELEASE_BUTTON', 'Vorschau':'PREVIEW_BUTTON',
                        'Verkauf stoppen':'STOP_BUTTON'}.items():
        code = code.replace('click("'+german+'")', 'click(L.'+key+')')
    cases[name] = code

data = json.loads((ROOT / 'tests' / 'expected_locales.json').read_text(encoding='utf-8'))
aliases = {'enGB':'enUS', 'esMX':'esES', 'ptPT':'ptBR', 'xxXX':'enUS'}
count = 0
for locale in list(data)+list(aliases):
    for name, code in cases.items():
        lua, namespace = run(name, code, locale)
        count += 1
    target = aliases.get(locale,locale)
    assert namespace.locale == target
    for key, expected in data[target].items():
        assert namespace.L[key] == expected, (locale,key)
        # Exercise the Lua 5.1 formatter, not just Python placeholder matching.
        args = [7 if token=='%d' else 'test' for token in re.findall(r'%[ds]',expected)]
        lua.eval('string.format')(namespace.L[key], *args)
    lua.execute('cmd("");')
    texts = [widget.text for widget in lua.globals().widgets.values() if widget.text]
    for key in ('AUTO_LABEL','LEVEL_LABEL','SETS_LABEL','SPECIAL_LABEL','SAVE_BUTTON','STOP_BUTTON'):
        assert data[target][key] in texts, (locale,key)
    print('PASS',locale,':',len(cases),'behavior tests; 55 strings, formatting and visible labels')

# Missing individual translations fall back independently to English.
locale_source = (ROOT / 'Locales.lua').read_text(encoding='utf-8')
locale_source = locale_source.replace('        STOPPED = "Verkauf gestoppt.",','',1)
lua = LuaRuntime(); lua.globals().GetLocale = lambda: 'deDE'; ns=lua.table()
lua.execute(locale_source,'TransmogSeller',ns)
assert ns.L.STOPPED == data['enUS']['STOPPED']
assert ns.L.SAVE_BUTTON == data['deDE']['SAVE_BUTTON']
print('PASS missing-key English fallback')

# A language change must not reset character settings or the ignore list.
lua = LuaRuntime(); lua.execute(mock); lua.globals().GetLocale=lambda: 'frFR'
lua.execute('TransmogSellerDB={maxLevel=155,batch=4,enabled=false,protectSets=false,protectSpecial=false,keep={[77]=true}}')
ns=lua.table()
for file in ('Locales.lua','TransmogSeller.lua','Settings.lua'):
    lua.execute((ROOT / file).read_text(encoding='utf-8'),'TransmogSeller',ns)
lua.execute("event(nil,'ADDON_LOADED','TransmogSeller');assert(TransmogSellerDB.maxLevel==155 and TransmogSellerDB.batch==4 and not TransmogSellerDB.enabled and not TransmogSellerDB.protectSets and not TransmogSellerDB.protectSpecial and TransmogSellerDB.keep[77])")
print('PASS existing settings preserved with different client language')
print(f'{count} Lua 5.1 mocked behavior tests + 2 fallback/persistence tests passed. No live WoW UI test.')
