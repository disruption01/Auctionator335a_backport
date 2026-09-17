-- Widget method compatibility for the 3.3.5a FrameXML API.
local function indexOf(obj)
  local mt=getmetatable(obj)
  return mt and mt.__index
end

-- IMPORTANT (3.3.5a): never create a parentless EditBox just to probe its
-- metatable. On this client an anonymous EditBox can default to autoFocus=true
-- and steal the *entire* keyboard (movement, Enter, slash commands, UI binds).
-- This is the same old-client failure mode seen in other backports such as NIT.
-- Keep every probe under a permanently hidden parent, and explicitly neuter
-- the EditBox before it can ever participate in keyboard focus.
local probeParent = CreateFrame('Frame', nil, UIParent)
probeParent:SetWidth(1)
probeParent:SetHeight(1)
if probeParent.EnableMouse then probeParent:EnableMouse(false) end
if probeParent.EnableKeyboard then probeParent:EnableKeyboard(false) end
probeParent:Hide()

local frameProbe = CreateFrame('Frame', nil, probeParent)
local buttonProbe = CreateFrame('Button', nil, probeParent)
local editBoxProbe = CreateFrame('EditBox', nil, probeParent)
local sliderProbe = CreateFrame('Slider', nil, probeParent)

if editBoxProbe.SetAutoFocus then editBoxProbe:SetAutoFocus(false) end
if editBoxProbe.ClearFocus then editBoxProbe:ClearFocus() end
if editBoxProbe.EnableKeyboard then editBoxProbe:EnableKeyboard(false) end
if editBoxProbe.EnableMouse then editBoxProbe:EnableMouse(false) end
editBoxProbe:Hide()
frameProbe:Hide()
buttonProbe:Hide()
sliderProbe:Hide()

local samples={
  frameProbe,
  buttonProbe,
  editBoxProbe,
  sliderProbe,
}
for _,obj in ipairs(samples) do
  local idx=indexOf(obj)
  if type(idx)=='table' then
    if not idx.SetShown then function idx:SetShown(v) if v then self:Show() else self:Hide() end end end
    if not idx.SetSize then function idx:SetSize(w,h) self:SetWidth(w); self:SetHeight(h) end end
    if not idx.SetEnabled then function idx:SetEnabled(v) if v then if self.Enable then self:Enable() end else if self.Disable then self:Disable() end end end end
    if not idx.IsEnabled and idx.Enable then function idx:IsEnabled() return not self:IsMouseEnabled()==false end end
    if not idx.SetPropagateKeyboardInput then function idx:SetPropagateKeyboardInput() end end
    if not idx.SetResizeBounds then function idx:SetResizeBounds() end end
    if not idx.SetClipsChildren then function idx:SetClipsChildren() end end
    if not idx.SetFixedFrameStrata then function idx:SetFixedFrameStrata() end end
    if not idx.SetFixedFrameLevel then function idx:SetFixedFrameLevel() end end
    if not idx.SetupMenu then
      function idx:SetupMenu(fn)
        if Auctionator335_SetupMenuButton then Auctionator335_SetupMenuButton(self, fn); return self:SetupMenu(fn) end
      end
    end
  end
end

local tex=UIParent:CreateTexture()
local tidx=indexOf(tex)
if type(tidx)=='table' then
  if not tidx.SetShown then function tidx:SetShown(v) if v then self:Show() else self:Hide() end end end
  if not tidx.SetSize then function tidx:SetSize(w,h) self:SetWidth(w);self:SetHeight(h) end end
  if not tidx.SetColorTexture then function tidx:SetColorTexture(r,g,b,a) self:SetTexture(r,g,b,a or 1) end end
  if not tidx.SetAtlas then
    function tidx:SetAtlas(atlas)
      -- 3.3.5a has no atlas API. Keep the modern Auctionator layout by mapping
      -- the handful of atlases used on the legacy-AH path to old textures.
      if atlas=='auctionhouse-icon-coin-gold' then
        self:SetTexture('Interface\\MoneyFrame\\UI-MoneyIcons'); self:SetTexCoord(0,0.25,0,1)
      elseif atlas=='auctionhouse-icon-coin-silver' then
        self:SetTexture('Interface\\MoneyFrame\\UI-MoneyIcons'); self:SetTexCoord(0.25,0.5,0,1)
      elseif atlas=='auctionhouse-icon-coin-copper' then
        self:SetTexture('Interface\\MoneyFrame\\UI-MoneyIcons'); self:SetTexCoord(0.5,0.75,0,1)
      elseif atlas=='common-search-magnifyingglass' then
        self:SetTexture('Interface\\Common\\UI-Searchbox-Icon'); self:SetTexCoord(0,1,0,1)
      elseif atlas=='auctionhouse-rowstripe-1' then
        self:SetTexture(0.08, 0.08, 0.08, 0.45); self:SetTexCoord(0,1,0,1)
      elseif atlas=='auctionhouse-ui-row-highlight' then
        self:SetTexture(1.0, 0.82, 0.0, 0.18); self:SetTexCoord(0,1,0,1)
      elseif atlas=='auctionhouse-ui-row-select' then
        self:SetTexture(0.2, 0.45, 0.8, 0.28); self:SetTexCoord(0,1,0,1)
      else
        -- Unknown modern atlas on 3.3.5a: transparent is safer than a missing
        -- texture, which renders as a solid neon-green rectangle.
        self:SetTexture(0, 0, 0, 0); self:SetTexCoord(0,1,0,1)
      end
    end
  end
  if not tidx.SetTexelSnappingBias then function tidx:SetTexelSnappingBias() end end
  if not tidx.SetSnapToPixelGrid then function tidx:SetSnapToPixelGrid() end end
end
tex:Hide()

local fs=UIParent:CreateFontString()
local fidx=indexOf(fs)
if type(fidx)=='table' then
  if not fidx.SetShown then function fidx:SetShown(v) if v then self:Show() else self:Hide() end end end
  if not fidx.SetSize then function fidx:SetSize(w,h) self:SetWidth(w);self:SetHeight(h) end end
  if not fidx.SetMaxLines then function fidx:SetMaxLines() end end
end
fs:Hide()

if not GameTooltip.SetItemByID then
  function GameTooltip:SetItemByID(id) self:SetHyperlink('item:'..tostring(id)) end
end

-- Do NOT synthesize BackdropTemplateMixin on 3.3.5a. Modern addons commonly
-- use its existence as a feature test before inheriting "BackdropTemplate".
-- The actual XML template does not exist on this client, so exposing only the
-- mixin globally breaks otherwise-compatible addons loaded after Auctionator.

-- A few modern convenience methods are looked up on animation groups.
local ag=UIParent:CreateAnimationGroup()
local aidx=indexOf(ag)
if type(aidx)=='table' and not aidx.SetToFinalAlpha then function aidx:SetToFinalAlpha() end end
ag:Stop()
