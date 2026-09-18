-- Auctionator 336 -> WoW 3.3.5a compatibility layer
-- Original compatibility implementation for this private backport.

-- Client identity ----------------------------------------------------------
-- IMPORTANT: do not synthesize WOW_PROJECT_* globals or
-- IsUsingLegacyAuctionClient on 3.3.5a. Other addons use those globals for
-- feature detection and may incorrectly enter modern-Classic code paths.
-- Auctionator's backport uses explicit constants in its own namespace instead.

-- Lua/Blizzard utility helpers ---------------------------------------------
if not wipe then
  function wipe(t) for k in pairs(t) do t[k] = nil end return t end
end
if not Mixin then
  function Mixin(object, ...)
    for i = 1, select('#', ...) do
      local mixin = select(i, ...)
      if mixin then for k,v in pairs(mixin) do object[k] = v end end
    end
    return object
  end
end
if not CreateFromMixins then
  function CreateFromMixins(...) return Mixin({}, ...) end
end
if not CreateAndInitFromMixin then
  function CreateAndInitFromMixin(mixin, ...)
    local o = CreateFromMixins(mixin)
    if o.Init then o:Init(...) end
    return o
  end
end
if not GenerateClosure then
  function GenerateClosure(fn, ...)
    local bound = {...}
    return function(...)
      local args = {}
      for i=1,#bound do args[#args+1] = bound[i] end
      for i=1,select('#', ...) do args[#args+1] = select(i, ...) end
      return fn(unpack(args))
    end
  end
end
GenerateFlatClosure = GenerateFlatClosure or GenerateClosure
nop = nop or function() end
if not Round then function Round(v) return math.floor((v or 0) + 0.5) end end
if not Clamp then function Clamp(v,lo,hi) if v<lo then return lo elseif v>hi then return hi else return v end end end
if not Saturate then function Saturate(v) return Clamp(v,0,1) end end
if not Lerp then function Lerp(a,b,t) return a + (b-a)*t end end
if not tInvert then function tInvert(t) local r={} for k,v in pairs(t) do r[v]=k end return r end end
if not tIndexOf then function tIndexOf(t, x)
  if type(t) ~= "table" then return nil end
  for i,v in ipairs(t) do if v==x then return i end end
end end
if not tContains then function tContains(t,x) return tIndexOf(t,x) ~= nil end end
if not GetKeysArray then
  function GetKeysArray(t)
    local keys = {}
    if type(t) ~= 'table' then return keys end
    for k in pairs(t) do keys[#keys + 1] = k end
    return keys
  end
end
if not CopyTable then
  function CopyTable(t, shallow)
    local r = {}
    for k,v in pairs(t) do
      if type(v)=='table' and not shallow then r[k]=CopyTable(v) else r[k]=v end
    end
    return r
  end
end
if not tAppendAll then function tAppendAll(dst,src) for _,v in ipairs(src) do dst[#dst+1]=v end return dst end end
if not BreakUpLargeNumbers then
  function BreakUpLargeNumbers(v)
    local s = tostring(math.floor(tonumber(v) or 0))
    local sign = ''
    if s:sub(1,1)=='-' then sign='-'; s=s:sub(2) end
    local rev=s:reverse():gsub('(%d%d%d)','%1,'):reverse():gsub('^,','')
    return sign..rev
  end
end
FormatLargeNumber = FormatLargeNumber or BreakUpLargeNumbers
if not SafePack then function SafePack(...) return {n=select('#',...), ...} end end
if not SafeUnpack then function SafeUnpack(t) return unpack(t,1,t.n or #t) end end


-- 3.3.5a UI compatibility helpers -------------------------------------------
if not ButtonFrameTemplate_HidePortrait then
  function ButtonFrameTemplate_HidePortrait(frame)
    if not frame then return end
    local portrait = frame.Portrait or frame.portrait or (frame.GetName and frame:GetName() and _G[frame:GetName() .. "Portrait"] or nil)
    if portrait and portrait.Hide then portrait:Hide() end
    if frame.PortraitContainer and frame.PortraitContainer.Hide then frame.PortraitContainer:Hide() end
  end
end

if not DynamicResizeButton_Resize then
  function DynamicResizeButton_Resize(button, padding)
    if not button or not button.SetWidth then return end
    padding = tonumber(padding) or 30
    local textWidth = 0
    if button.GetFontString then
      local fs = button:GetFontString()
      if fs and fs.GetStringWidth then textWidth = fs:GetStringWidth() or 0 end
    elseif button.GetTextWidth then
      textWidth = button:GetTextWidth() or 0
    end
    button:SetWidth(math.max(40, math.ceil(textWidth + padding)))
  end
end

-- Expansion constants -------------------------------------------------------
LE_EXPANSION_CLASSIC = LE_EXPANSION_CLASSIC or 0
LE_EXPANSION_BURNING_CRUSADE = LE_EXPANSION_BURNING_CRUSADE or 1
LE_EXPANSION_WRATH_OF_THE_LICH_KING = LE_EXPANSION_WRATH_OF_THE_LICH_KING or 2
LE_EXPANSION_LEVEL_CURRENT = LE_EXPANSION_LEVEL_CURRENT or 2
EXPANSION_NAME0 = EXPANSION_NAME0 or 'Classic'
EXPANSION_NAME1 = EXPANSION_NAME1 or 'The Burning Crusade'
EXPANSION_NAME2 = EXPANSION_NAME2 or 'Wrath of the Lich King'
AUCTION_CANCEL_COST = AUCTION_CANCEL_COST or 5

-- Enum ---------------------------------------------------------------------
-- Some 3.3.5a-derived clients expose partial modern Enum tables.  Do not
-- replace those tables wholesale, but also do not assume that a table being
-- present means every modern key Auctionator needs exists.  Fill only missing
-- values so stock 3.3.5a keeps the exact same compatibility values while
-- clients such as Whitemane can safely coexist with their native extensions.
Enum = Enum or {}
Enum.ItemQuality = Enum.ItemQuality or {}
local compatItemQualities = {Poor=0,Standard=1,Common=1,Good=2,Uncommon=2,Rare=3,Epic=4,Legendary=5,Artifact=6,Heirloom=7,WoWToken=8}
for key, value in pairs(compatItemQualities) do
  if Enum.ItemQuality[key] == nil then
    Enum.ItemQuality[key] = value
  end
end

Enum.ItemClass = Enum.ItemClass or {}
local compatItemClasses = {Consumable=0,Container=1,Weapon=2,Gem=3,Armor=4,Reagent=5,Projectile=6,Tradegoods=7,ItemEnhancement=8,Recipe=9,CurrencyTokenObsolete=10,Quiver=11,Questitem=12,Key=13,PermanentObsolete=14,Miscellaneous=15,Glyph=16,Battlepet=17,WoWToken=18,Profession=19,Housing=20,Amor=4}
for key, value in pairs(compatItemClasses) do
  if Enum.ItemClass[key] == nil then
    Enum.ItemClass[key] = value
  end
end
Enum.InventoryType = Enum.InventoryType or {
  IndexNonEquipType=0,IndexHeadType=1,IndexNeckType=2,IndexShoulderType=3,IndexBodyType=4,
  IndexChestType=5,IndexWaistType=6,IndexLegsType=7,IndexFeetType=8,IndexWristType=9,
  IndexHandType=10,IndexFingerType=11,IndexTrinketType=12,IndexWeaponType=13,IndexShieldType=14,
  IndexRangedType=15,IndexCloakType=16,Index2HweaponType=17,IndexBagType=18,IndexTabardType=19,
  IndexRobeType=20,IndexWeaponmainhandType=21,IndexWeaponoffhandType=22,IndexHoldableType=23,
  IndexAmmoType=24,IndexThrownType=25,IndexRangedrightType=26,IndexQuiverType=27,IndexRelicType=28,
}
Enum.AuctionHouseTimeLeftBand = Enum.AuctionHouseTimeLeftBand or {Short=0,Medium=1,Long=2,VeryLong=3}
Enum.ItemBind = Enum.ItemBind or {None=0,OnAcquire=1,OnEquip=2,OnUse=3,Quest=4}
Enum.PlayerInteractionType = Enum.PlayerInteractionType or {Auctioneer=21,MailInfo=17,Merchant=5}
Enum.TooltipDataType = Enum.TooltipDataType or {Unit=2,Item=10,Spell=11}

-- Colors -------------------------------------------------------------------
-- Some 3.3.5a-derived clients (notably Whitemane) expose a partial modern
-- ColorMixin/CreateColor implementation.  Do not use one method (SetRGBA) as
-- proof that the whole modern color API exists: Whitemane can provide SetRGBA
-- while omitting WrapTextInColorCode.  Fill each missing method independently
-- so stock 3.3.5a keeps the same compatibility behaviour and partial clients
-- only receive the pieces they actually lack.
ColorMixin = ColorMixin or {}
if not ColorMixin.SetRGBA then
  function ColorMixin:SetRGBA(r,g,b,a) self.r,self.g,self.b,self.a=r,g,b,a or 1 end
end
if not ColorMixin.GetRGB then
  function ColorMixin:GetRGB() return self.r,self.g,self.b end
end
if not ColorMixin.GetRGBA then
  function ColorMixin:GetRGBA() return self.r,self.g,self.b,self.a or 1 end
end
if not ColorMixin.GenerateHexColor then
  function ColorMixin:GenerateHexColor()
    return string.format('ff%02x%02x%02x', Clamp(Round((self.r or 0)*255),0,255), Clamp(Round((self.g or 0)*255),0,255), Clamp(Round((self.b or 0)*255),0,255))
  end
end
if not ColorMixin.GenerateHexColorMarkup then
  function ColorMixin:GenerateHexColorMarkup() return '|c'..self:GenerateHexColor() end
end
if not ColorMixin.WrapTextInColorCode then
  function ColorMixin:WrapTextInColorCode(text) return self:GenerateHexColorMarkup()..tostring(text)..'|r' end
end

local function auctionatorCompatColor(r,g,b,a)
  local c={r=r or 1,g=g or 1,b=b or 1,a=a or 1}
  for k,v in pairs(ColorMixin) do
    if type(v)=='function' and c[k]==nil then c[k]=v end
  end
  return c
end

if not CreateColor then
  function CreateColor(r,g,b,a) return auctionatorCompatColor(r,g,b,a) end
end

local function ensureColorMethods(c, r, g, b)
  if type(c)~='table' then
    return auctionatorCompatColor(r,g,b,1)
  end
  for k,v in pairs(ColorMixin) do
    if type(v)=='function' and c[k]==nil then c[k]=v end
  end
  if c.r==nil then c.r,c.g,c.b=r or 1,g or 1,b or 1 end
  if c.a==nil then c.a=1 end
  return c
end

local function ensureColor(name,r,g,b)
  _G[name]=ensureColorMethods(_G[name],r,g,b)
end
ensureColor('WHITE_FONT_COLOR',1,1,1); ensureColor('NORMAL_FONT_COLOR',1,.82,0)
ensureColor('HIGHLIGHT_FONT_COLOR',1,1,1); ensureColor('RED_FONT_COLOR',1,.1,.1)
ensureColor('GREEN_FONT_COLOR',.1,1,.1); ensureColor('GRAY_FONT_COLOR',.5,.5,.5)
ensureColor('LIGHTGRAY_FONT_COLOR',.7,.7,.7); ensureColor('BLUE_FONT_COLOR',.3,.4,1)
ensureColor('LIGHTBLUE_FONT_COLOR',.6,.8,1); ensureColor('ORANGE_FONT_COLOR',1,.5,.25)
ensureColor('DISABLED_FONT_COLOR',.5,.5,.5)
if type(ITEM_QUALITY_COLORS)=='table' then
  for _,q in pairs(ITEM_QUALITY_COLORS) do
    if type(q)=='table' and q.r then
      q.color=ensureColorMethods(q.color,q.r,q.g,q.b)
    end
  end
end

-- Sounds -------------------------------------------------------------------
SOUNDKIT = SOUNDKIT or {}
SOUNDKIT.IG_CHARACTER_INFO_TAB = 'igCharacterInfoTab'
SOUNDKIT.IG_MAINMENU_OPEN = 'igMainMenuOpen'
SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON = 'igMainMenuOptionCheckBoxOn'
SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF = 'igMainMenuOptionCheckBoxOff'
SOUNDKIT.IG_MAINMENU_CLOSE = 'igMainMenuClose'
SOUNDKIT.IG_MAINMENU_OPTION = 'igMainMenuOption'

-- Interface Options ---------------------------------------------------------
-- IMPORTANT: do not create or extend the modern Blizzard `_G.Settings` API on
-- 3.3.5a. Other addons use the existence of that global for feature detection
-- and may enter modern code paths that the legacy client cannot support.
-- Auctionator registers its panels directly through the native 3.3.5a
-- InterfaceOptions_* API instead (see Source/Config/Mixins/PanelConfig.lua).

-- NineSlice is cosmetic on 3.3.5a ------------------------------------------
NineSliceUtil = NineSliceUtil or {}
NineSliceUtil.ApplyLayoutByName = NineSliceUtil.ApplyLayoutByName or function(frame)
  if frame and frame.SetBackdrop and not frame.__auctionatorCompatBackdrop then
    frame:SetBackdrop({bgFile='Interface\\Tooltips\\UI-Tooltip-Background', edgeFile='Interface\\Tooltips\\UI-Tooltip-Border', tile=false, edgeSize=10, insets={left=2,right=2,top=2,bottom=2}})
    frame:SetBackdropColor(.04,.04,.04,.96)
    frame.__auctionatorCompatBackdrop=true
  end
end

-- Seconds formatter ---------------------------------------------------------
SecondsFormatter = SecondsFormatter or {}
SecondsFormatter.Interval = SecondsFormatter.Interval or {Seconds=1,Minutes=60,Hours=3600,Days=86400}
SecondsFormatter.Abbreviation = SecondsFormatter.Abbreviation or {None=0,OneLetter=1}
if not SecondsFormatterMixin then SecondsFormatterMixin={} end

-- Minimal Blizzard SecondsFormatterMixin backport for 3.3.5a. Auctionator uses
-- this for auction time-left labels (30m, 2h, etc.). The old client has no
-- SecondsFormatter implementation at all, so providing only the table was not
-- enough: formatter:Init() was nil during addon load.
if not SecondsFormatterMixin.Init then
  function SecondsFormatterMixin:Init(minSeconds, abbreviation, roundUp)
    self.minSeconds = tonumber(minSeconds) or 0
    self.abbreviation = abbreviation
    self.roundUp = roundUp and true or false
    self.stripIntervalWhitespace = false
  end
end
if not SecondsFormatterMixin.SetStripIntervalWhitespace then
  function SecondsFormatterMixin:SetStripIntervalWhitespace(value)
    self.stripIntervalWhitespace = value and true or false
  end
end
if not SecondsFormatterMixin.Format then
  function SecondsFormatterMixin:Format(seconds)
    seconds = math.max(tonumber(seconds) or 0, self.minSeconds or 0)
    local minInterval = self.GetMinInterval and self:GetMinInterval(seconds) or SecondsFormatter.Interval.Seconds
    local maxInterval = self.GetMaxInterval and self:GetMaxInterval(seconds) or SecondsFormatter.Interval.Days
    local interval
    if seconds >= SecondsFormatter.Interval.Days and maxInterval >= SecondsFormatter.Interval.Days then
      interval = SecondsFormatter.Interval.Days
    elseif seconds >= SecondsFormatter.Interval.Hours and maxInterval >= SecondsFormatter.Interval.Hours then
      interval = SecondsFormatter.Interval.Hours
    elseif seconds >= SecondsFormatter.Interval.Minutes and maxInterval >= SecondsFormatter.Interval.Minutes then
      interval = SecondsFormatter.Interval.Minutes
    else
      interval = SecondsFormatter.Interval.Seconds
    end
    if interval < minInterval then interval = minInterval end
    if interval > maxInterval then interval = maxInterval end

    local value = seconds / interval
    if self.roundUp then
      value = math.ceil(value)
    else
      value = math.floor(value)
    end

    local oneLetter = self.abbreviation == SecondsFormatter.Abbreviation.OneLetter
    local suffix
    if interval == SecondsFormatter.Interval.Days then
      suffix = oneLetter and 'd' or (value == 1 and ' day' or ' days')
    elseif interval == SecondsFormatter.Interval.Hours then
      suffix = oneLetter and 'h' or (value == 1 and ' hour' or ' hours')
    elseif interval == SecondsFormatter.Interval.Minutes then
      suffix = oneLetter and 'm' or (value == 1 and ' minute' or ' minutes')
    else
      suffix = oneLetter and 's' or (value == 1 and ' second' or ' seconds')
    end
    if oneLetter or self.stripIntervalWhitespace then
      return tostring(value) .. suffix
    end
    return tostring(value) .. suffix
  end
end

-- Misc modern globals used by Auctionator ----------------------------------
if not CreateCounter then function CreateCounter(start) local n=start or 0; return function() n=n+1 return n end end end
if not CreateAtlasMarkup then function CreateAtlasMarkup() return '' end end
if not GetTimePreciseSec then GetTimePreciseSec=GetTime end
if not GetServerTime then GetServerTime=time end
if not GetNormalizedRealmName then function GetNormalizedRealmName() return (GetRealmName() or ''):gsub('[%s%-]','') end end
if not UnitFullName then function UnitFullName(unit) return UnitName(unit), GetRealmName() end end
if not GetUnitName then function GetUnitName(unit, showServerName) return UnitName(unit) end end
if not GetSpecialization then function GetSpecialization() return nil end end
if not IsPlayerSpell then IsPlayerSpell=IsSpellKnown or function() return false end end
if not strjoin then function strjoin(sep, ...) local t={...}; for i=1,#t do t[i]=tostring(t[i]) end return table.concat(t,sep) end end
if not GetAddOnMetadata and C_AddOns and C_AddOns.GetAddOnMetadata then GetAddOnMetadata=C_AddOns.GetAddOnMetadata end

-- 3.3.5a keyboard-focus guard ---------------------------------------------
-- Some old-client EditBox templates default to autoFocus=true. A hidden
-- Auctionator input could therefore own the keyboard immediately after login,
-- swallowing movement/Enter until clicked elsewhere. Modern clients don't do
-- this with the templates Auctionator expects. Clear only Auctionator-owned
-- focus once at PLAYER_LOGIN; intentional focus later is untouched.
local function Auctionator335_IsOwnFrame(frame)
  local current = frame
  for _ = 1, 10 do
    if not current then break end
    local name = current.GetName and current:GetName()
    if type(name) == 'string' and string.find(name, '^Auctionator') then
      return true
    end
    current = current.GetParent and current:GetParent() or nil
  end
  return false
end
local function Auctionator335_ClearAccidentalFocus()
  if type(GetCurrentKeyBoardFocus) == 'function' then
    local focus = GetCurrentKeyBoardFocus()
    if focus and focus.ClearFocus then
      local hidden = focus.IsVisible and not focus:IsVisible()
      if Auctionator335_IsOwnFrame(focus) or hidden then
        focus:ClearFocus()
      end
    end
  end
end


local function Auctionator335_ProcessKeyboardFrame(frame, optionsVisible)
  if not frame or not Auctionator335_IsOwnFrame(frame) then return end

  local okType, objectType = pcall(function()
    if frame.GetObjectType then
      return frame:GetObjectType()
    end
  end)
  if not okType or not objectType then return end

  -- EditBoxes legitimately need the keyboard while they own focus. They are
  -- handled by the focus guard below instead of EnableKeyboard().
  if objectType == 'EditBox' then return end

  local listening = false
  pcall(function() listening = frame.isListening and true or false end)

  -- Key-binding widgets are the only Auctionator Frames that ever need direct
  -- keyboard capture on 3.3.5a, and only while the Interface Options window is
  -- actually visible. A hidden/stale listener is enough to swallow *every* key
  -- on this client, including WASD, Enter and the Blizzard UI shortcuts.
  local allowed = false
  pcall(function()
    allowed = listening and frame.Auctionator335AllowKeyboardCapture and optionsVisible and
      (not frame.IsShown or frame:IsShown())
  end)

  if listening and not allowed and frame.StopListening then
    pcall(function() frame:StopListening() end)
    listening = false
  end

  if not allowed then
    pcall(function()
      if frame.EnableKeyboard then
        frame:EnableKeyboard(false)
      end
    end)
    -- On old FrameXML an OnKeyDown handler can remain dangerous even after a
    -- parent is hidden. Do not remove scripts from a widget that is actively
    -- listening; all passive handlers must otherwise be disabled.
    if not listening and frame.GetScript and frame.SetScript then
      local hasKeyDown = false
      pcall(function() hasKeyDown = frame:GetScript('OnKeyDown') ~= nil end)
      if hasKeyDown and not frame.Auctionator335KeepKeyScript then
        pcall(function() frame:SetScript('OnKeyDown', nil) end)
        pcall(function() frame:SetScript('OnKeyUp', nil) end)
      end
    end
  end
end

local function Auctionator335_DisablePassiveKeyboardCapture()
  -- Scan every frame, not just named globals. Several converted templates create
  -- anonymous children; one anonymous frame with keyboard enabled can block the
  -- entire 3.3.5a keyboard.
  local optionsVisible = InterfaceOptionsFrame and InterfaceOptionsFrame.IsShown and InterfaceOptionsFrame:IsShown()

  if type(EnumerateFrames) == 'function' then
    local frame = EnumerateFrames()
    local safety = 0
    while frame and safety < 10000 do
      Auctionator335_ProcessKeyboardFrame(frame, optionsVisible)
      frame = EnumerateFrames(frame)
      safety = safety + 1
    end
  else
    -- Fallback for unusual 3.3.5a cores without EnumerateFrames().
    for name, frame in pairs(_G) do
      if type(name) == 'string' and string.find(name, '^Auctionator') then
        local valueType = type(frame)
        if valueType == 'table' or valueType == 'userdata' then
          Auctionator335_ProcessKeyboardFrame(frame, optionsVisible)
        end
      end
    end
  end
end

local function Auctionator335_ClearStaleOverrideBindings()
  local auctionVisible = AuctionFrame and AuctionFrame.IsShown and AuctionFrame:IsShown()
  if auctionVisible then return end
  if type(ClearOverrideBindings) ~= 'function' then return end

  if type(EnumerateFrames) == 'function' then
    local frame = EnumerateFrames()
    local safety = 0
    while frame and safety < 10000 do
      if Auctionator335_IsOwnFrame(frame) then
        pcall(function() ClearOverrideBindings(frame) end)
      end
      frame = EnumerateFrames(frame)
      safety = safety + 1
    end
  end
end

local Auctionator335FocusGuard = CreateFrame('Frame')
Auctionator335FocusGuard:RegisterEvent('PLAYER_LOGIN')
Auctionator335FocusGuard:RegisterEvent('PLAYER_ENTERING_WORLD')
Auctionator335FocusGuard:RegisterEvent('AUCTION_HOUSE_CLOSED')
Auctionator335FocusGuard:SetScript('OnEvent', function()
  Auctionator335_ClearAccidentalFocus()
  Auctionator335_DisablePassiveKeyboardCapture()
  Auctionator335_ClearStaleOverrideBindings()
  -- XML-created controls and late initialization can claim focus after the
  -- normal login events on 3.3.5a. Re-check several times during startup.
  if C_Timer and C_Timer.After then
    C_Timer.After(0, Auctionator335_ClearAccidentalFocus)
    C_Timer.After(0.25, Auctionator335_ClearAccidentalFocus)
    C_Timer.After(1.0, function() Auctionator335_ClearAccidentalFocus(); Auctionator335_DisablePassiveKeyboardCapture() end)
    C_Timer.After(2.0, Auctionator335_ClearAccidentalFocus)
    C_Timer.After(5.0, function() Auctionator335_ClearAccidentalFocus(); Auctionator335_DisablePassiveKeyboardCapture() end)
  end
end)

-- Persistent safety net: a hidden Auctionator EditBox must never keep keyboard
-- focus. This is what causes WASD/Enter to stop working on the old client.
-- Intentional typing is preserved while the Auction House or Auctionator
-- options UI is actually visible.
local focusElapsed = 0
local Auctionator335WasAuctionVisible = false
Auctionator335FocusGuard:SetScript('OnUpdate', function(self, elapsed)
  focusElapsed = focusElapsed + (elapsed or 0)
  if focusElapsed < 0.35 then return end
  focusElapsed = 0

  -- Keep non-editbox Auctionator frames from passively swallowing movement
  -- keys, including anonymous frames created only after the AH is first opened.
  Auctionator335_DisablePassiveKeyboardCapture()

  local auctionVisible = AuctionFrame and AuctionFrame.IsShown and AuctionFrame:IsShown()
  local optionsVisible = InterfaceOptionsFrame and InterfaceOptionsFrame.IsShown and InterfaceOptionsFrame:IsShown()

  -- Clear override bindings once when leaving the AH, rather than continuously.
  if Auctionator335WasAuctionVisible and not auctionVisible then
    Auctionator335_ClearStaleOverrideBindings()
  end
  Auctionator335WasAuctionVisible = auctionVisible and true or false

  if not auctionVisible and not optionsVisible then
    Auctionator335_ClearAccidentalFocus()
  end
end)

if AuctionFrame and AuctionFrame.HookScript then
  AuctionFrame:HookScript('OnHide', Auctionator335_ClearAccidentalFocus)
end

-- Keyboard diagnostics for the 3.3.5a backport.
SLASH_AUCTIONATOR335KEY1 = "/atrkey"
SlashCmdList["AUCTIONATOR335KEY"] = function()
  local focus = type(GetCurrentKeyBoardFocus) == "function" and GetCurrentKeyBoardFocus() or nil
  local name = focus and focus.GetName and focus:GetName() or nil
  local objectType = focus and focus.GetObjectType and focus:GetObjectType() or nil
  DEFAULT_CHAT_FRAME:AddMessage("Auctionator keyboard focus: " .. tostring(name or focus) .. " [" .. tostring(objectType) .. "]")
end

SLASH_AUCTIONATOR335FIXKEYS1 = "/atrfixkeys"
SlashCmdList["AUCTIONATOR335FIXKEYS"] = function()
  Auctionator335_ClearAccidentalFocus()
  Auctionator335_DisablePassiveKeyboardCapture()
  Auctionator335_ClearStaleOverrideBindings()
  local focus = type(GetCurrentKeyBoardFocus) == "function" and GetCurrentKeyBoardFocus() or nil
  if focus and focus.ClearFocus then pcall(function() focus:ClearFocus() end) end
  DEFAULT_CHAT_FRAME:AddMessage("Auctionator: keyboard focus released.")
end

-- Do not replace protected Blizzard globals such as PlaySound on 3.3.5a.
-- Replacing them from addon code taints Blizzard's secure execution path and can
-- make unrelated protected actions (for example action-bar spell clicks) fail.
-- Auctionator's SOUNDKIT compatibility above already uses legacy string sound
-- names accepted by the native PlaySound implementation.
