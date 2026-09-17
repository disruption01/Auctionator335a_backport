AuctionatorBagItemSelectedMixin = CreateFromMixins(AuctionatorGroupsViewItemMixin)

function AuctionatorBagItemSelectedMixin:SetItemInfo(info, ...)
  AuctionatorGroupsViewItemMixin.SetItemInfo(self, info, ...)

  -- The inherited modern icon texture is unreliable on the 3.3.5a FrameXML
  -- (it can exist as a region but still render as an empty/black slot). Use a
  -- dedicated runtime texture for the large selected item, exactly as we do
  -- for Shopping result icons.
  if not self.Auctionator335SelectedIcon and self.CreateTexture then
    self.Auctionator335SelectedIcon = self:CreateTexture(nil, "ARTWORK")
    self.Auctionator335SelectedIcon:SetPoint("TOPLEFT", self, "TOPLEFT", 4, -4)
    self.Auctionator335SelectedIcon:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 4)
    self.Auctionator335SelectedIcon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
  end
  if self.Auctionator335SelectedIcon then
    local iconTexture = info and info.iconTexture
    if not iconTexture and info and info.itemLink then
      iconTexture = select(10, GetItemInfo(info.itemLink))
    end
    if not iconTexture and info and info.itemID and GetItemIcon then
      iconTexture = GetItemIcon(info.itemID)
    end
    self.Auctionator335SelectedIcon:SetTexture(iconTexture)
    self.Auctionator335SelectedIcon:SetShown(info ~= nil and iconTexture ~= nil)
  end
  if self.Icon then
    -- Avoid the inherited texture fighting with the runtime one.
    self.Icon:Hide()
  end

  -- The generic bag icon deliberately oversizes its action-button border.
  -- That looks fine in the icon grid but makes the large selected Selling item
  -- look as if the artwork is spilling outside its box. Give this one a real
  -- inset icon/slot and a contained border like the TBC Classic reference.
  if not self.Auctionator335SlotBackground and self.CreateTexture then
    self.Auctionator335SlotBackground = self:CreateTexture(nil, "BACKGROUND")
    self.Auctionator335SlotBackground:SetPoint("TOPLEFT", self, "TOPLEFT", 3, -3)
    self.Auctionator335SlotBackground:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -3, 3)
    self.Auctionator335SlotBackground:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    self.Auctionator335SlotBackground:SetVertexColor(0.04, 0.04, 0.04, 1)
  end
  if self.Auctionator335SlotBackground then
    self.Auctionator335SlotBackground:Show()
  end

  if self.Icon then
    self.Icon:ClearAllPoints()
    self.Icon:SetPoint("TOPLEFT", self, "TOPLEFT", 4, -4)
    self.Icon:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 4)
    self.Icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
    self.Icon:SetDrawLayer("ARTWORK")
    self.Icon:SetAlpha(1)
  end
  -- UI-Slot-Background from the inherited modern template renders as a bright
  -- white inner square on this Wrath client. The dedicated dark background
  -- above replaces it for the large Selling slot.
  if self.EmptySlot then
    self.EmptySlot:Hide()
  end
  if self.IconBorder then
    self.IconBorder:ClearAllPoints()
    self.IconBorder:SetPoint("TOPLEFT", self, "TOPLEFT", -2, 2)
    self.IconBorder:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 2, -2)
    self.IconBorder:SetShown(info ~= nil)
  end
  if self.IconSelectedHighlight then
    self.IconSelectedHighlight:ClearAllPoints()
    self.IconSelectedHighlight:SetPoint("TOPLEFT", self, "TOPLEFT", -2, 2)
    self.IconSelectedHighlight:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 2, -2)
    self.IconSelectedHighlight:Hide()
  end

  self.clickEventName = "BagUse.BagItemClicked"
end

local seenBag, seenSlot

local function Auctionator335ClearSelectedSellItem(self)
  if self.itemInfo == nil then
    return
  end

  -- Keep Blizzard's native sell slot in sync with Auctionator. Clicking an
  -- occupied sell slot picks the item back up; ClearCursor returns it to its
  -- original bag slot on the legacy client.
  if GetAuctionSellItemInfo and GetAuctionSellItemInfo() ~= nil and ClickAuctionSellItemButton then
    ClickAuctionSellItemButton()
    ClearCursor()
  end

  local owner = self:GetParent()
  if owner and Auctionator.EventBus:IsSourceRegistered(owner) then
    Auctionator.EventBus:Fire(owner, Auctionator.Selling.Events.ClearBagItem)
  elseif owner and owner.Reset then
    owner:Reset()
  end
end

function AuctionatorBagItemSelectedMixin:OnClick(button)
  -- TBC Classic behaviour: right-clicking the currently selected sale item
  -- removes it from focus and returns Selling to its empty initial state.
  if button == "RightButton" and self.itemInfo ~= nil then
    Auctionator335ClearSelectedSellItem(self)
    return
  end

  local wasCursorItem = C_Cursor.GetCursorItem()
  self:ProcessCursor(function(check)
    if not check then
      if button == "LeftButton" and not wasCursorItem and self.itemInfo ~= nil and not IsModifiedClick("DRESSUP") and not IsModifiedClick("CHATLINK") then
        self:SearchInShoppingTab()
      else
        AuctionatorGroupsViewItemMixin.OnClick(self, button)
      end
    end
  end)
end

function AuctionatorBagItemSelectedMixin:SearchInShoppingTab()
  Auctionator.API.v1.MultiSearchExact(AUCTIONATOR_L_SELLING_TAB, { self.itemInfo.itemName })
end

function AuctionatorBagItemSelectedMixin:OnReceiveDrag()
  self:ProcessCursor(function() end)
end

-- On the legacy auction house the selected item is also placed in Blizzard's
-- sell slot.  The modern Auctionator frame relies on drag behaviour supplied by
-- newer FrameXML, which does not exist on 3.3.5a.  Allow dragging the large
-- selected icon out to mean "stop selling this item": clear Blizzard's sell
-- slot, discard the temporary cursor copy and reset Auctionator's selection.
function AuctionatorBagItemSelectedMixin:OnDragStart()
  Auctionator335ClearSelectedSellItem(self)
end

local function Auctionator335CursorMatchesLocation(cursorData, location)
  if not location or not C_Item.DoesItemExist(location) then
    return false
  end

  local locationLink = C_Item.GetItemLink(location)
  if cursorData and cursorData.itemLink and locationLink == cursorData.itemLink then
    return true
  end

  local cursorID = cursorData and cursorData.itemID
  local locationID = locationLink and C_Item.GetItemInfoInstant(locationLink)
  return cursorID ~= nil and locationID == cursorID
end

local function Auctionator335ResolveCursorLocation(cursorData)
  -- Modern clients return an ItemLocation-like object from C_Cursor. The
  -- 3.3.5a compatibility bridge can only recover the item id/link, so do not
  -- assume HasAnyLocation exists on the returned table.
  if cursorData and type(cursorData.HasAnyLocation) == "function" and cursorData:HasAnyLocation() then
    return cursorData
  end

  -- First use the last bag/slot recorded by the bag pickup hook. This keeps
  -- exact suffix/random-enchant items attached to the slot the player dragged.
  if seenBag ~= nil and seenSlot ~= nil then
    local hooked = ItemLocation:CreateFromBagAndSlot(seenBag, seenSlot)
    if Auctionator335CursorMatchesLocation(cursorData, hooked) then
      return hooked
    end
  end

  -- Fallback for clients/UI code paths that call the legacy global
  -- PickupContainerItem and therefore don't expose a modern cursor location:
  -- locate a matching bag slot by exact link first, then by item id.
  local fallbackByID
  for _, bagID in ipairs(Auctionator.Groups.Constants.BagIDs or {0, 1, 2, 3, 4}) do
    local slots = C_Container.GetContainerNumSlots(bagID) or 0
    for slotID = 1, slots do
      local link = C_Container.GetContainerItemLink(bagID, slotID)
      if link then
        local loc = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
        if cursorData and cursorData.itemLink and link == cursorData.itemLink then
          return loc
        end
        if not fallbackByID and cursorData and cursorData.itemID and C_Item.GetItemInfoInstant(link) == cursorData.itemID then
          fallbackByID = loc
        end
      end
    end
  end

  return fallbackByID
end

function AuctionatorBagItemSelectedMixin:ProcessCursor(callback)
  local cursorData = C_Cursor.GetCursorItem()
  ClearCursor()

  if not cursorData then
    Auctionator.Debug.Message("nothing on cursor")
    callback(false)
    return
  end

  local location = Auctionator335ResolveCursorLocation(cursorData)
  if not location or not C_Item.DoesItemExist(location) then
    Auctionator.Debug.Message("AuctionatorBagItemSelected", "unable to resolve cursor location")
    callback(false)
    return
  end

  local itemLink = C_Item.GetItemLink(location) or cursorData.itemLink

  Auctionator.EventBus:RegisterSource(self, "BagItemSelected")
  Auctionator.Groups.CallbackRegistry:RegisterCallback("BagCacheUpdated", function(_, cache)
    Auctionator.Groups.CallbackRegistry:UnregisterCallback("BagCacheUpdated", self)
    Auctionator.Groups.CallbackRegistry:TriggerEvent("BagCacheOff")
    cache:CacheLinkInfo(itemLink, function()
      local info = Auctionator.Groups.Utilities.ToPostingItem(AuctionatorBagCacheFrame:GetByLinkInstant(itemLink, true))
      if info.location then
        callback(true)
        info.location = location
        Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.BagItemClicked, info)
      else
        Auctionator.Selling.ShowCannotSellReason(location)
        callback(false)
      end
    end)
  end, self)
  Auctionator.Groups.CallbackRegistry:TriggerEvent("BagCacheOn")
end

local function HookForPickup(bag, slot)
  seenBag = bag
  seenSlot = slot
end

-- For classic record clicks on bag items so that we can make keyring items
-- being picked up and placed in the Selling tab work.
if C_Container and C_Container.PickupContainerItem then
  hooksecurefunc(C_Container, "PickupContainerItem", HookForPickup)
end
-- The stock 3.3.5a bag UI calls the legacy global directly. Hook that path as
-- well; hooking only the compatibility table does not observe those clicks.
if PickupContainerItem then
  hooksecurefunc("PickupContainerItem", HookForPickup)
end
