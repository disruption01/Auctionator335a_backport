AuctionatorBagCacheMixin = {}
function AuctionatorBagCacheMixin:OnLoad()
  self.cache = {}
  self.loaders = {}
  self.contents = {}

  self.cacheOn = 0
  Auctionator.Groups.CallbackRegistry:RegisterCallback("BagCacheOn", function()
    self.cacheOn = self.cacheOn + 1
    if self.cacheOn > 0 then
      self:SetScript("OnUpdate", self.DoBagRefresh)
    end
  end)
  Auctionator.Groups.CallbackRegistry:RegisterCallback("BagCacheOff", function()
    self.cacheOn = self.cacheOn - 1
    if self.cacheOn <= 0 then
      self:SetScript("OnUpdate", self.DoBagRefresh)
    end
  end)
  self:RegisterEvent("BAG_UPDATE")
end

function AuctionatorBagCacheMixin:OnEvent(eventName, ...)
  if self.cacheOn > 0 and eventName == "BAG_UPDATE" then
    self:SetScript("OnUpdate", self.DoBagRefresh)
  end
end

local function GetItemKey(entry)
  local itemLevel = entry.itemLevel or 0
  if entry.classID == Enum.ItemClass.Battlepet then
    itemLevel = Auctionator.Utilities.GetPetLevelFromLink(entry.itemLink)
  end
  return entry.itemID .. "_" ..  entry.itemName .. "_" .. itemLevel .. "_" .. entry.quality .. "_" ..  tostring(entry.auctionable)
end

function AuctionatorBagCacheMixin:PostUpdate(bagContents)
  local byKey = {}
  for _, item in ipairs(bagContents) do
    if byKey[item.key] == nil then
      byKey[item.key] = {
        count = 0,
        entries = {}
      }
    end
    local existingEntry = byKey[item.key]
    existingEntry.count = existingEntry.count + item.itemCount
    table.insert(existingEntry.entries, item)
  end
  self.contents = byKey
  Auctionator.Groups.CallbackRegistry:TriggerEvent("BagCacheUpdated", self)
end

local linkInstantCache = {}
function AuctionatorBagCacheMixin:GetByLinkInstant(suppliedItemLink, auctionable)
  local entry = linkInstantCache[suppliedItemLink]

  if entry == nil then
    return
  end

  entry.auctionable = auctionable

  local key = GetItemKey(entry)
  local realEntry = self.contents[key]
  local itemLink = entry.itemLink

  local itemCount = 0
  local locations = {}

  if realEntry ~= nil then
    for _, e in ipairs(realEntry.entries) do
      table.insert(locations, e.location)
    end
    itemCount = realEntry.count
    itemLink = realEntry.entries[1].itemLink
  end

  return {
    locations = locations,
    itemCount = itemCount,
    auctionable = auctionable,
    itemName = entry.itemName,
    itemLink = itemLink,
    itemID = entry.itemID,
    itemLevel = entry.itemLevel,
    quality = entry.quality,
    iconTexture = entry.iconTexture,
    classID = entry.classID,
    sortKey = key,
  }
end

function AuctionatorBagCacheMixin:GetByKey(key)
  local value = self.contents[key]
  if value ~= nil then
    local entry = value.entries[1]
    local locations = {}
    for _, e in ipairs(value.entries) do
      table.insert(locations, e.location)
    end

    return {
      locations = locations,
      itemCount = value.count,
      itemName = entry.itemName,
      itemID = entry.itemID,
      itemLevel = entry.itemLevel,
      auctionable = entry.auctionable,
      itemLink = entry.itemLink,
      quality = entry.quality,
      iconTexture = entry.iconTexture,
      classID = entry.classID,
      sortKey = key,
    }
  end
end

function AuctionatorBagCacheMixin:CacheLinkInfo(suppliedItemLink, callback)
  local existingEntry = linkInstantCache[suppliedItemLink]
  if existingEntry then
    callback()
    return
  end

  callback = callback or function() end

  local realEntry

  if suppliedItemLink:match("battlepet") then
    local itemName, iconTexture = C_PetJournal.GetPetInfoBySpeciesID(tonumber(suppliedItemLink:match("battlepet:(%d+)")))

    local entry = {
      itemLink = suppliedItemLink,
      itemID = Auctionator.Constants.PET_CAGE_ID,
      itemName = itemName,
      iconTexture = iconTexture,
      itemCount = 0,
      classID = Enum.ItemClass.Battlepet,
      quality = tonumber(suppliedItemLink:match("battlepet:%d*:%d*:(%d+)") or "3")
    }
    entry.key = GetItemKey(entry)
    linkInstantCache[suppliedItemLink] = entry

    callback()
  else
    -- Ignore mythic keystones, etc.
    local itemID = C_Item.GetItemInfoInstant(suppliedItemLink)
    if itemID == nil then
      return
    end

    local item = Item:CreateFromItemLink(suppliedItemLink)
    item:ContinueOnItemLoad(function()
      local itemName, itemLink = C_Item.GetItemInfo(suppliedItemLink)

      local entry = {
        itemLink = suppliedItemLink,
        iconTexture = item:GetItemIcon(),
        itemName = itemName,
        itemID = itemID,
        itemLink = itemLink,
        itemCount = 0,
        classID = select(6, C_Item.GetItemInfoInstant(itemLink)),
        quality = item:GetItemQuality(),
      }
      if Auctionator.Utilities.IsEquipment(entry.classID) then
        if Auctionator.Constants.IsRetail then
          entry.itemLevel = Auctionator.Groups.Utilities.ExtractItemLevel(entry.itemLink)
        else
          entry.itemLevel = C_Item.GetDetailedItemLevelInfo(entry.itemLink)
        end
      end
      linkInstantCache[suppliedItemLink] = entry
      callback()
    end)
  end
end

function AuctionatorBagCacheMixin:GetAllContents()
  local result = {}
  for key in pairs(self.contents) do
    table.insert(result, self:GetByKey(key))
  end
  return result
end

-- The 3.3.5a client has no real async Item API. Build the Selling bag
-- cache directly from the native container functions. This intentionally does
-- not depend on modern slotInfo/Item loading semantics: several 3.3.5a cores
-- omit itemLink from GetContainerItemInfo while GetContainerItemLink is valid.
local function Auctionator335BuildLegacyBagEntry(bagID, slotID)
  local link = GetContainerItemLink and GetContainerItemLink(bagID, slotID) or nil
  local texture, count, locked, bagQuality = GetContainerItemInfo(bagID, slotID)
  if not link then
    local wrapped = C_Container.GetContainerItemInfo(bagID, slotID)
    link = wrapped and wrapped.hyperlink or nil
    texture = texture or (wrapped and wrapped.iconFileID)
    count = count or (wrapped and wrapped.stackCount)
    bagQuality = bagQuality or (wrapped and wrapped.quality)
  end
  if not link then return nil end

  local itemID = C_Item.GetItemInfoInstant(link)
  if not itemID then
    itemID = tonumber(link:match('item:(%-?%d+)'))
  end
  if not itemID then return nil end

  local itemName, normalizedLink, quality, itemLevel, _, _, _, maxStack, _, icon = GetItemInfo(link)
  -- Bag items should already be cached, but keep a harmless name fallback so a
  -- slow/private core cannot make the whole Selling pane disappear.
  itemName = itemName or link:match('%[(.-)%]') or tostring(itemID)
  normalizedLink = normalizedLink or link
  quality = quality or bagQuality or Enum.ItemQuality.Standard

  local classID = select(6, C_Item.GetItemInfoInstant(normalizedLink))
  if classID == nil then
    classID = select(12, C_Item.GetItemInfo(normalizedLink))
  end
  if classID == nil then return nil end

  local location = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
  local currentDurability, maxDurability = C_Container.GetContainerItemDurability(bagID, slotID)
  local durabilityOK = maxDurability == nil or maxDurability == 0 or currentDurability == maxDurability
  local auctionable = not C_Item.IsBound(location) and durabilityOK

  local entry = {
    itemID = itemID,
    location = location,
    iconTexture = texture or icon,
    itemCount = count or 1,
    quality = quality,
    itemLink = normalizedLink,
    classID = classID,
    itemName = itemName,
    stackCount = maxStack or 1,
    auctionable = auctionable,
  }

  if Auctionator.Utilities.IsEquipment(classID) then
    entry.itemLevel = itemLevel or 0
  end
  entry.key = GetItemKey(entry)

  -- On the real 3.3.5a client every item in the bags is already synchronously
  -- addressable through GetItemInfo/GetContainerItemLink. Seed the same instant
  -- cache used by favourites and drag/drop here instead of asking the modern
  -- asynchronous Item API to discover the very same item again.
  local instant = {
    itemLink = normalizedLink,
    iconTexture = entry.iconTexture,
    itemName = itemName,
    itemID = itemID,
    itemCount = 0,
    classID = classID,
    quality = quality,
    itemLevel = entry.itemLevel,
  }
  linkInstantCache[normalizedLink] = instant
  if link ~= normalizedLink then
    linkInstantCache[link] = instant
  end

  return entry
end

local function Auctionator335DoLegacyBagRefresh(self)
  local entireBag = {}

  self.loaders = {}
  self.waiting = false

  for _, bagID in ipairs(Auctionator.Groups.Constants.BagIDs or {0, 1, 2, 3, 4}) do
    local slots = (GetContainerNumSlots and GetContainerNumSlots(bagID)) or C_Container.GetContainerNumSlots(bagID) or 0
    for slotID = 1, slots do
      local entry = Auctionator335BuildLegacyBagEntry(bagID, slotID)
      if entry then
        table.insert(entireBag, entry)
      end
    end
  end

  self:PostUpdate(entireBag)
end

function AuctionatorBagCacheMixin:DoBagRefresh()
  self:SetScript("OnUpdate", nil)

  -- This private build runs on the original 3.3.5a client. It always has the
  -- legacy container API, even though Auctionator.Constants.IsLegacyAH is an
  -- upstream project/client detector and can be false on our compatibility
  -- project id. Do not let that detector send Wrath into the modern async bag
  -- pipeline: that was why the Selling bag pane stayed empty in 0.33-0.36.
  if Auctionator.Groups.Constants.IsWrath then
    Auctionator335DoLegacyBagRefresh(self)
    return
  end
  if self.waiting then
    for _, l in pairs(self.loaders) do
      l()
    end
  end
  self.loaders = {}

  self.waiting = true

  local entireBag = {}
  local waitingCount = 0

  local loopFinished = false
  local loaderIndex = 0
  for _, bagID in ipairs(Auctionator.Groups.Constants.BagIDs) do
    for slotID = 1, C_Container.GetContainerNumSlots(bagID) do
      local location = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
      local slotInfo = C_Container.GetContainerItemInfo(bagID, slotID)

      if slotInfo then
        waitingCount = waitingCount + 1
        local item = Item:CreateFromItemID(slotInfo.itemID)

        local function FinishSlot()
          local entry = self:AddToCache(location, slotInfo)
          if entry then
            table.insert(entireBag, entry)
          end
          waitingCount = waitingCount - 1
          if loopFinished and waitingCount == 0 then
            self.loaders = {}
            self.waiting = false
            self:PostUpdate(entireBag)
          end
        end
        loaderIndex = loaderIndex + 1
        local li = loaderIndex

        -- Load item data to determine whether it can be auctioned, its quality,
        -- item level, etc.
        if Auctionator.Groups.Constants.IsVanilla then
          local classID = select(6, C_Item.GetItemInfoInstant(slotInfo.itemID))
          local _, spellID = C_Item.GetItemSpell(slotInfo.itemID)
          -- Classic: Special case to load spell data for item charge info for
          -- auctionable check
          if classID == Enum.ItemClass.Consumable and spellID then
            local function LocalFinish()
              if not C_Item.IsItemDataCached(location) then
                local item = Item:CreateFromItemID(slotInfo.itemID)
                self.loaders[li] = item:ContinueWithCancelOnItemLoad(FinishSlot)
              elseif not C_Spell.IsSpellDataCached(spellID) then
                local spell = Spell:CreateFromSpellID(spellID)
                self.loaders[li] = spell:ContinueWithCancelOnSpellLoad(LocalFinish)
              else
                self.loaders[li] = nil
                FinishSlot()
              end
            end
            LocalFinish()
          elseif C_Item.IsItemDataCached(location) then
            FinishSlot()
          else
            self.loaders[li] = item:ContinueWithCancelOnItemLoad(FinishSlot)
          end
        -- We check for the item data being cached as its a significant time
        -- saving over waiting for the mixin to call back in that case.
        elseif C_Item.IsItemDataCached(location) then
          FinishSlot()
        else
          self.loaders[li] = item:ContinueWithCancelOnItemLoad(FinishSlot)
        end
      end
    end
  end
  loopFinished = true

  if waitingCount == 0 then
    self.loaders = {}
    self.waiting = false
    self:PostUpdate(entireBag)
  end
end

local detailsCache = {}

function AuctionatorBagCacheMixin:AddToCache(location, slotInfo)
  local entry = {}

  entry.itemID = slotInfo.itemID

  entry.location = location

  entry.iconTexture, entry.itemCount, entry.quality, entry.itemLink = slotInfo.iconFileID, slotInfo.stackCount, slotInfo.quality, slotInfo.hyperlink

  local savedDetails = detailsCache[entry.itemLink]
  if savedDetails ~= nil then
    entry.classID = savedDetails.classID
    entry.itemName = savedDetails.itemName
    entry.stackCount = savedDetails.stackCount
    entry.itemLevel = savedDetails.itemLevel
    entry.quality = savedDetails.quality
  else
    if entry.itemLink:match("battlepet:") then
      entry.classID = Enum.ItemClass.Battlepet
      entry.itemName = C_PetJournal.GetPetInfoBySpeciesID(tonumber(entry.itemLink:match("battlepet:(%d+)")))
      entry.stackCount = 1
    else
      local itemName, itemLink, quality, _, _, _, _, stackCount, _, _, _, classID, _ = C_Item.GetItemInfo(entry.itemLink)
      if itemName == nil then --mythic keystones don't have a normal item link
        return nil
      end
      entry.classID = classID
      entry.itemName = itemName
      entry.itemLink = itemLink
      entry.stackCount = stackCount
      entry.quality = quality
    end
    if Auctionator.Utilities.IsEquipment(entry.classID) then
      if Auctionator.Constants.IsRetail then
        entry.itemLevel = Auctionator.Groups.Utilities.ExtractItemLevel(entry.itemLink)
      else
        entry.itemLevel = C_Item.GetDetailedItemLevelInfo(entry.itemLink)
      end
    end
    detailsCache[entry.itemLink] = entry
  end

  if C_AuctionHouse == nil then -- Classic, check if the item can be auctioned
    local currentDurability, maxDurability
    local bagID, slotID = Auctionator_GetBagAndSlotFromLocation(location)
    if bagID ~= nil and slotID ~= nil then
      currentDurability, maxDurability = C_Container.GetContainerItemDurability(bagID, slotID)
    else
      local slot = Auctionator_GetEquipmentSlotFromLocation(location)
      currentDurability, maxDurability = GetInventoryItemDurability(slot)
    end

    local durabilityOK = maxDurability == nil or maxDurability == 0 or currentDurability == maxDurability
    entry.auctionable = not C_Item.IsBound(location) and durabilityOK

    if entry.auctionable and entry.classID == Enum.ItemClass.Consumable and select(1, Auctionator_GetBagAndSlotFromLocation(location)) ~= nil then
      entry.auctionable = Auctionator.Utilities.IsAtMaxCharges(location)
    end
  else
    entry.auctionable = C_AuctionHouse.IsSellItemValid(location, false)
  end

  entry.key = GetItemKey(entry)

  return entry
end
