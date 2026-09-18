-- ItemLocation / Item objects and C_* API bridge for WoW 3.3.5a

local function itemIDFromLink(value)
  if type(value)=='number' then return value end
  if type(value)~='string' then return nil end
  return tonumber(value:match('item:(%-?%d+)')) or tonumber(value)
end

local classIDs = {
  ['Consumable']=0,['Container']=1,['Weapon']=2,['Gem']=3,['Armor']=4,['Reagent']=5,['Projectile']=6,
  ['Trade Goods']=7,['Recipe']=9,['Quiver']=11,['Quest']=12,['Key']=13,['Miscellaneous']=15,['Glyph']=16,
}
local equipIDs = {
  INVTYPE_HEAD=1,INVTYPE_NECK=2,INVTYPE_SHOULDER=3,INVTYPE_BODY=4,INVTYPE_CHEST=5,
  INVTYPE_WAIST=6,INVTYPE_LEGS=7,INVTYPE_FEET=8,INVTYPE_WRIST=9,INVTYPE_HAND=10,
  INVTYPE_FINGER=11,INVTYPE_TRINKET=12,INVTYPE_WEAPON=13,INVTYPE_SHIELD=14,INVTYPE_RANGED=15,
  INVTYPE_CLOAK=16,INVTYPE_2HWEAPON=17,INVTYPE_BAG=18,INVTYPE_TABARD=19,INVTYPE_ROBE=20,
  INVTYPE_WEAPONMAINHAND=21,INVTYPE_WEAPONOFFHAND=22,INVTYPE_HOLDABLE=23,INVTYPE_AMMO=24,
  INVTYPE_THROWN=25,INVTYPE_RANGEDRIGHT=26,INVTYPE_QUIVER=27,INVTYPE_RELIC=28,
}

if not GetItemInfoInstant then
  function GetItemInfoInstant(item)
    -- Native GetItemInfo throws a usage error for nil. Modern C_Item simply
    -- returns nil for an invalid/empty item reference, which Auctionator relies on.
    if item == nil then return nil end
    local id=itemIDFromLink(item)
    local query=id or item
    if query == nil then return nil end
    local name,link,quality,ilevel,minlevel,itemType,itemSubType,stack,equipLoc,icon=GetItemInfo(query)
    if not id and link then id=itemIDFromLink(link) end
    if not id then return nil end
    return id, itemType, itemSubType, equipLoc, icon, classIDs[itemType] or 15, 0
  end
end

ItemLocationMixin = ItemLocationMixin or {}
function ItemLocationMixin:IsBagAndSlot() return self.bag~=nil and self.slot~=nil end
function ItemLocationMixin:GetBagAndSlot() return self.bag,self.slot end
function ItemLocationMixin:IsEquipmentSlot() return self.equipmentSlot~=nil end
function ItemLocationMixin:GetEquipmentSlot() return self.equipmentSlot end
function ItemLocationMixin:HasAnyLocation() return self:IsBagAndSlot() or self:IsEquipmentSlot() end
function ItemLocationMixin:Clear() self.bag=nil; self.slot=nil; self.equipmentSlot=nil end
ItemLocation = ItemLocation or {}
function ItemLocation:CreateFromBagAndSlot(bag,slot) local o=CreateFromMixins(ItemLocationMixin); o.bag=bag;o.slot=slot;return o end
function ItemLocation:CreateFromEquipmentSlot(slot) local o=CreateFromMixins(ItemLocationMixin);o.equipmentSlot=slot;return o end

-- ItemLocation is a global compatibility object, so another 3.3.5a addon may
-- provide the implementation that Auctionator receives. Syndicator, for
-- example, stores bag locations as bagID/slotIndex and exposes IsBagAndSlot()
-- but not GetBagAndSlot(). Never assume one concrete ItemLocation layout.
function Auctionator_GetBagAndSlotFromLocation(loc)
  if not loc then return nil, nil end

  if type(loc.GetBagAndSlot) == 'function' then
    local bag, slot = loc:GetBagAndSlot()
    if bag ~= nil and slot ~= nil then
      return bag, slot
    end
  end

  if type(loc.GetBagID) == 'function' and type(loc.GetSlotIndex) == 'function' then
    local bag, slot = loc:GetBagID(), loc:GetSlotIndex()
    if bag ~= nil and slot ~= nil then
      return bag, slot
    end
  end

  local bag = loc.bag
  local slot = loc.slot
  if bag ~= nil and slot ~= nil then
    return bag, slot
  end

  bag = loc.bagID or loc.bagIndex
  slot = loc.slotIndex or loc.slotID
  if bag ~= nil and slot ~= nil then
    return bag, slot
  end

  return nil, nil
end

function Auctionator_GetEquipmentSlotFromLocation(loc)
  if not loc then return nil end
  if type(loc.GetEquipmentSlot) == 'function' then
    local slot = loc:GetEquipmentSlot()
    if slot ~= nil then return slot end
  end
  return loc.equipmentSlot or loc.equipmentSlotIndex
end

function Auctionator_GetLinkFromLocation(loc)
  if not loc then return nil end
  local bag, slot = Auctionator_GetBagAndSlotFromLocation(loc)
  if bag ~= nil and slot ~= nil then
    return GetContainerItemLink(bag, slot)
  end
  local equipmentSlot = Auctionator_GetEquipmentSlotFromLocation(loc)
  if equipmentSlot ~= nil then
    return GetInventoryItemLink('player', equipmentSlot)
  end
end

ItemMixin = ItemMixin or {}
function ItemMixin:GetItemID() return self.itemID or itemIDFromLink(self.itemLink) end
function ItemMixin:GetItemLink() return self.itemLink or (self.itemID and select(2,GetItemInfo(self.itemID))) end
function ItemMixin:GetItemName() return (GetItemInfo(self.itemLink or self.itemID)) end
function ItemMixin:GetItemQuality() return select(3,GetItemInfo(self.itemLink or self.itemID)) end
function ItemMixin:GetItemIcon() return select(10,GetItemInfo(self.itemLink or self.itemID)) end
function ItemMixin:IsItemEmpty() return self:GetItemID()==nil end
local function itemReady(obj) return GetItemInfo(obj.itemLink or obj.itemID) ~= nil end
function ItemMixin:ContinueOnItemLoad(callback)
  if itemReady(self) then callback(); return end
  local ticks=0
  local ticker
  ticker=C_Timer.NewTicker(.1,function()
    ticks=ticks+1
    if itemReady(self) or ticks>50 then ticker:Cancel(); callback() end
  end)
end
function ItemMixin:ContinueWithCancelOnItemLoad(callback)
  local cancelled=false
  if itemReady(self) then callback(); return function() end end
  local ticks=0; local ticker
  ticker=C_Timer.NewTicker(.1,function()
    if cancelled then ticker:Cancel(); return end
    ticks=ticks+1
    if itemReady(self) or ticks>50 then ticker:Cancel(); if not cancelled then callback() end end
  end)
  return function() cancelled=true; if ticker then ticker:Cancel() end end
end
Item = Item or {}
function Item:CreateFromItemID(id) local o=CreateFromMixins(ItemMixin);o.itemID=id;return o end
function Item:CreateFromItemLink(link) local o=CreateFromMixins(ItemMixin);o.itemLink=link;o.itemID=itemIDFromLink(link);return o end
function Item:CreateFromItemLocation(loc) local link=Auctionator_GetLinkFromLocation(loc);local o=self:CreateFromItemLink(link);o.itemLocation=loc;return o end

-- Containers ---------------------------------------------------------------
C_Container=C_Container or {}
C_Container.GetContainerNumSlots=C_Container.GetContainerNumSlots or GetContainerNumSlots
C_Container.PickupContainerItem=C_Container.PickupContainerItem or PickupContainerItem
C_Container.GetContainerItemLink=C_Container.GetContainerItemLink or GetContainerItemLink
function C_Container.GetContainerItemInfo(bag,slot)
  local texture,count,locked,quality,readable,lootable,link=GetContainerItemInfo(bag,slot)
  -- Some 3.3.5a cores do not return itemLink from GetContainerItemInfo even
  -- though GetContainerItemLink works. Auctionator's bag cache requires a
  -- hyperlink/itemID, so always fall back to the dedicated legacy API.
  if (not link or link == '') and GetContainerItemLink then
    link = GetContainerItemLink(bag, slot)
  end
  if not texture and not link then return nil end
  if quality == nil and link then
    quality = select(3, GetItemInfo(link))
  end
  return {iconFileID=texture,stackCount=count or 0,isLocked=locked,quality=quality,isReadable=readable,hasLoot=lootable,hyperlink=link,itemID=itemIDFromLink(link)}
end
function C_Container.GetContainerItemDurability(bag,slot) if GetContainerItemDurability then return GetContainerItemDurability(bag,slot) end end

-- Items --------------------------------------------------------------------
C_Item=C_Item or {}
C_Item.GetItemInfoInstant=C_Item.GetItemInfoInstant or GetItemInfoInstant
C_Item.GetItemSpell=C_Item.GetItemSpell or GetItemSpell
C_Item.GetItemCount=C_Item.GetItemCount or GetItemCount
-- 3.3.5a GetItemInfo returns 11 values; modern Classic returns extra numeric
-- class/bind/expansion fields.  Reconstruct the shape Auctionator 336 expects.
local bindCache={}
local function scanBindType(item)
  local id=itemIDFromLink(item) or item
  if id and bindCache[id]~=nil then return bindCache[id] end
  local bind=Enum and Enum.ItemBind and Enum.ItemBind.None or 0
  if not AuctionatorCompatItemTip then
    CreateFrame('GameTooltip','AuctionatorCompatItemTip',UIParent,'GameTooltipTemplate')
    AuctionatorCompatItemTip:SetOwner(UIParent,'ANCHOR_NONE')
  end
  local tip=AuctionatorCompatItemTip
  tip:ClearLines()
  local link=type(item)=='string' and item or select(2,GetItemInfo(item))
  if link then
    tip:SetHyperlink(link)
    for i=2,tip:NumLines() do
      local fs=_G['AuctionatorCompatItemTipTextLeft'..i]
      local text=fs and fs:GetText()
      if text then
        local lower = string.lower(text)
        local accountBound =
          (ITEM_ACCOUNTBOUND and text == ITEM_ACCOUNTBOUND) or
          (ITEM_BNETACCOUNTBOUND and text == ITEM_BNETACCOUNTBOUND) or
          lower == 'binds to account' or
          lower == 'binds to battle.net account' or
          lower == 'battle.net account bound' or
          lower == 'account bound' or
          string.find(lower, 'binds to account', 1, true) ~= nil or
          string.find(lower, 'account bound', 1, true) ~= nil

        if (ITEM_BIND_ON_PICKUP and text==ITEM_BIND_ON_PICKUP) or
           (ITEM_SOULBOUND and text==ITEM_SOULBOUND) or accountBound then
          -- Auctionator only needs account-bound items to behave as
          -- non-auctionable here. OnAcquire is the closest legacy enum.
          bind=Enum.ItemBind.OnAcquire
          break
        elseif ITEM_BIND_ON_EQUIP and text==ITEM_BIND_ON_EQUIP then
          bind=Enum.ItemBind.OnEquip
          break
        elseif ITEM_BIND_ON_USE and text==ITEM_BIND_ON_USE then
          bind=Enum.ItemBind.OnUse
          break
        elseif (ITEM_BIND_QUEST and text==ITEM_BIND_QUEST) then
          bind=Enum.ItemBind.Quest
          break
        end
      end
    end
  end
  if id then bindCache[id]=bind end
  return bind
end
function C_Item.GetItemInfo(item)
  local name,link,quality,ilevel,minlevel,itemType,itemSubType,stack,equipLoc,icon,sellPrice=GetItemInfo(item)
  if not name then return nil end
  local classID=classIDs[itemType] or 15
  -- subclassID is only required for category metadata; 0 is a safe fallback
  -- for item records on the 3.3.5 client.
  local subClassID=0
  local bindType=scanBindType(link or item)
  local expansionID=2 -- Wrath client content ceiling; exact per-item expansion is not needed here
  local setID=nil
  local isCraftingReagent=(classID==7 or classID==5)
  return name,link,quality,ilevel,minlevel,itemType,itemSubType,stack,equipLoc,icon,sellPrice,classID,subClassID,bindType,expansionID,setID,isCraftingReagent
end
function C_Item.GetItemNameByID(item) return (C_Item.GetItemInfo(item)) end
function C_Item.DoesItemExist(loc) return loc ~= nil and Auctionator_GetLinkFromLocation(loc) ~= nil end
function C_Item.GetItemLink(loc) return Auctionator_GetLinkFromLocation(loc) end
function C_Item.GetItemLinkByGUID() return nil end
function C_Item.IsItemDataCached(item)
  if type(item)=='table' then local link=Auctionator_GetLinkFromLocation(item); return link and GetItemInfo(link)~=nil end
  return GetItemInfo(item)~=nil
end
C_Item.IsItemDataCachedByID=C_Item.IsItemDataCached
function C_Item.IsBound(loc)
  local bag, slot = Auctionator_GetBagAndSlotFromLocation(loc)
  if bag == nil or slot == nil then return false end
  local link = GetContainerItemLink and GetContainerItemLink(bag, slot) or nil

  if not AuctionatorCompatScanTooltip then
    CreateFrame('GameTooltip','AuctionatorCompatScanTooltip',UIParent,'GameTooltipTemplate')
    AuctionatorCompatScanTooltip:SetOwner(UIParent,'ANCHOR_NONE')
  end
  local tip=AuctionatorCompatScanTooltip
  tip:ClearLines()
  tip:SetBagItem(bag, slot)

  -- Current binding is slot-specific. Scan both tooltip columns and accept the
  -- native localized strings. The English text fallback is intentional for
  -- private 3.3.5a cores that omit some global string constants.
  local function isBoundText(text)
    if not text or text == '' then return false end
    if (ITEM_SOULBOUND and text == ITEM_SOULBOUND) or
       (ITEM_ACCOUNTBOUND and text == ITEM_ACCOUNTBOUND) or
       (ITEM_BNETACCOUNTBOUND and text == ITEM_BNETACCOUNTBOUND) or
       (ITEM_BIND_ON_PICKUP and text == ITEM_BIND_ON_PICKUP) or
       (ITEM_BIND_QUEST and text == ITEM_BIND_QUEST) then
      return true
    end

    -- Private 3.3.5a cores often expose account-bound items even though the
    -- corresponding modern global strings do not exist in FrameXML.  Match the
    -- tooltip wording itself as a final slot-specific source of truth.
    local lower = string.lower(text)
    return lower == 'soulbound' or
           lower == 'binds when picked up' or
           lower == 'quest item' or
           lower == 'binds to account' or
           lower == 'binds to battle.net account' or
           lower == 'battle.net account bound' or
           lower == 'account bound' or
           string.find(lower, 'binds to account', 1, true) ~= nil or
           string.find(lower, 'account bound', 1, true) ~= nil
  end

  for i=1,tip:NumLines() do
    local left=_G['AuctionatorCompatScanTooltipTextLeft'..i]
    local right=_G['AuctionatorCompatScanTooltipTextRight'..i]
    if (left and isBoundText(left:GetText())) or (right and isBoundText(right:GetText())) then
      return true
    end
  end

  -- Bind-on-pickup/quest items are never auctionable even if a private core
  -- renders the tooltip unusually. Do not reject BoE/BoU items here.
  if link then
    local bindType = scanBindType(link)
    if bindType == Enum.ItemBind.OnAcquire or bindType == Enum.ItemBind.Quest then
      return true
    end
  end
  return false
end
function C_Item.IsItemBindToAccountUntilEquip() return false end
function C_Item.GetDetailedItemLevelInfo(item) local il=select(4,GetItemInfo(item)); return il,false,il end
if not GetDetailedItemLevelInfo then function GetDetailedItemLevelInfo(item) return C_Item.GetDetailedItemLevelInfo(item) end end
function C_Item.GetCurrentItemLevel(loc) local link=Auctionator_GetLinkFromLocation(loc); return link and select(4,GetItemInfo(link)) end
local classNames={[0]='Consumable',[1]='Container',[2]='Weapon',[3]='Gem',[4]='Armor',[5]='Reagent',[6]='Projectile',[7]='Trade Goods',[9]='Recipe',[11]='Quiver',[12]='Quest',[13]='Key',[15]='Miscellaneous',[16]='Glyph'}
function C_Item.GetItemClassInfo(id) return classNames[id] or ('Class '..tostring(id)) end
function C_Item.GetItemSubClassInfo(classID, subID)
  -- The legacy auction API returns localized subclass NAMES, while some
  -- 3.3.5a-derived clients (notably Whitemane) also expose a modern-ish
  -- GetItemSubClassInfo() that accepts numeric IDs only.  OldCategories feeds
  -- values from GetAuctionItemSubClasses() through here, so a string is already
  -- the display name we need and must not be passed to the native function.
  if type(subID) == "string" then
    return subID
  end

  if type(GetItemSubClassInfo) == "function" and type(subID) == "number" then
    local ok, name = pcall(GetItemSubClassInfo, classID, subID)
    if ok then
      return name
    end
  end

  return ''
end
function C_Item.GetStackCount(loc) local bag,slot=Auctionator_GetBagAndSlotFromLocation(loc); if bag~=nil and slot~=nil then local i=C_Container.GetContainerItemInfo(bag,slot);return i and i.stackCount or 1 end return 1 end
local inventoryTypeTokens={
  [0]='INVTYPE_NON_EQUIP',[1]='INVTYPE_HEAD',[2]='INVTYPE_NECK',[3]='INVTYPE_SHOULDER',[4]='INVTYPE_BODY',
  [5]='INVTYPE_CHEST',[6]='INVTYPE_WAIST',[7]='INVTYPE_LEGS',[8]='INVTYPE_FEET',[9]='INVTYPE_WRIST',[10]='INVTYPE_HAND',
  [11]='INVTYPE_FINGER',[12]='INVTYPE_TRINKET',[13]='INVTYPE_WEAPON',[14]='INVTYPE_SHIELD',[15]='INVTYPE_RANGED',
  [16]='INVTYPE_CLOAK',[17]='INVTYPE_2HWEAPON',[18]='INVTYPE_BAG',[19]='INVTYPE_TABARD',[20]='INVTYPE_ROBE',
  [21]='INVTYPE_WEAPONMAINHAND',[22]='INVTYPE_WEAPONOFFHAND',[23]='INVTYPE_HOLDABLE',[24]='INVTYPE_AMMO',
  [25]='INVTYPE_THROWN',[26]='INVTYPE_RANGEDRIGHT',[27]='INVTYPE_QUIVER',[28]='INVTYPE_RELIC',
}
function C_Item.GetItemInventorySlotInfo(inventoryType)
  local token=inventoryTypeTokens[inventoryType]
  return token and (_G[token] or token) or tostring(inventoryType or '')
end
function C_Item.LockItem() end; function C_Item.UnlockItem() end

-- Chat/addons ---------------------------------------------------------------
C_ChatInfo=C_ChatInfo or {}
C_ChatInfo.SendAddonMessage=C_ChatInfo.SendAddonMessage or SendAddonMessage
function C_ChatInfo.RegisterAddonMessagePrefix(prefix) if RegisterAddonMessagePrefix then return RegisterAddonMessagePrefix(prefix) end return true end
function C_ChatInfo.InChatMessagingLockdown() return false end
C_AddOns=C_AddOns or {}
C_AddOns.GetAddOnMetadata=C_AddOns.GetAddOnMetadata or GetAddOnMetadata
C_AddOns.IsAddOnLoaded=C_AddOns.IsAddOnLoaded or IsAddOnLoaded
C_AddOns.LoadAddOn=C_AddOns.LoadAddOn or LoadAddOn


C_PetJournal=C_PetJournal or {}
function C_PetJournal.GetPetInfoBySpeciesID() return nil end

-- Cursor -------------------------------------------------------------------
C_Cursor=C_Cursor or {}
function C_Cursor.GetCursorItem()
  local kind,id,link=GetCursorInfo()
  if kind=='item' then return {itemID=id,itemLink=link} end
end

-- Merchant -----------------------------------------------------------------
C_MerchantFrame=C_MerchantFrame or {}
function C_MerchantFrame.GetItemInfo(index)
  local name,texture,price,quantity,numAvailable,isPurchasable,isUsable,extendedCost=GetMerchantItemInfo(index)
  if not name then return nil end
  return {name=name,texture=texture,price=price,stackCount=quantity,numAvailable=numAvailable,isPurchasable=isPurchasable,isUsable=isUsable,hasExtendedCost=extendedCost}
end
if not GetMerchantItemID then function GetMerchantItemID(index) return itemIDFromLink(GetMerchantItemLink(index)) end end

-- Spells/tradeskills --------------------------------------------------------
C_Spell=C_Spell or {}
function C_Spell.IsSpellDataCached() return true end
C_TradeSkillUI=C_TradeSkillUI or {}
function C_TradeSkillUI.GetItemReagentQualityByItemInfo() return 0 end
function C_TradeSkillUI.GetItemReagentQualityInfo() return nil end
function C_TradeSkillUI.GetRecipeOutputItemData() return nil end
function C_TradeSkillUI.GetRecipeSchematic() return nil end

-- Link helpers --------------------------------------------------------------
if not ExtractHyperlinkString then
  function ExtractHyperlinkString(text)
    if type(text)~='string' then return false,'','','' end
    local pre,link,post=text:match('^(.-)|H(.-)|h.-|h(.*)$')
    if link then return true,pre,link,post end
    return false,'',text,''
  end
end

-- No TooltipDataProcessor/C_TooltipInfo on 3.3.5a: callers have legacy fallbacks.
