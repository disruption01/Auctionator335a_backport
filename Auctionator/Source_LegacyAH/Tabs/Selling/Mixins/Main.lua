AuctionatorSellingTabMixin = {}

-- The modern GroupsView is built around Retail/Classic ScrollBox inheritance.
-- On the original 3.3.5a FrameXML the bag cache is now valid, but the generated
-- group/title/icon frames can still sit underneath the sibling BagInset (and its
-- NineSlice child), leaving a completely blank left pane.  Use a small native
-- ScrollFrame renderer for the Selling bag pane on Wrath.  It consumes the same
-- BagCache records and fires the same Selling event, so posting logic stays the
-- Auctionator logic rather than a separate implementation.
local function Auctionator335CollectBagItems(cache)
  local items = (cache and cache.GetAllContents and cache:GetAllContents()) or {}
  if #items > 0 then
    return items
  end

  -- Defensive direct scan.  This should only be needed on private cores that
  -- report a BAG_UPDATE before GetItemInfo has populated the normal cache.
  local byKey = {}
  for _, bagID in ipairs(Auctionator.Groups.Constants.BagIDs or {0, 1, 2, 3, 4}) do
    local slots = (GetContainerNumSlots and GetContainerNumSlots(bagID)) or 0
    for slotID = 1, slots do
      local itemLink = GetContainerItemLink and GetContainerItemLink(bagID, slotID) or nil
      if itemLink then
        local texture, count, _, bagQuality = GetContainerItemInfo(bagID, slotID)
        local itemName, normalizedLink, quality, itemLevel, _, itemType, _, _, _, icon = GetItemInfo(itemLink)
        normalizedLink = normalizedLink or itemLink
        itemName = itemName or itemLink:match("%[(.-)%]")
        local itemID = C_Item.GetItemInfoInstant(normalizedLink)
        local classID = select(6, C_Item.GetItemInfoInstant(normalizedLink))
        quality = quality or bagQuality or Enum.ItemQuality.Standard
        if itemID and itemName and classID ~= nil then
          local location = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
          local curDur, maxDur = C_Container.GetContainerItemDurability(bagID, slotID)
          local durabilityOK = maxDur == nil or maxDur == 0 or curDur == maxDur
          local auctionable = not C_Item.IsBound(location) and durabilityOK
          if auctionable then
            local key = tostring(itemID) .. "_" .. itemName .. "_" .. tostring(itemLevel or 0) .. "_" .. tostring(quality) .. "_true"
            local entry = byKey[key]
            if not entry then
              entry = {
                locations = {},
                itemCount = 0,
                auctionable = true,
                itemName = itemName,
                itemLink = normalizedLink,
                itemID = itemID,
                itemLevel = itemLevel or 0,
                quality = quality,
                iconTexture = texture or icon,
                classID = classID,
                sortKey = key,
              }
              byKey[key] = entry
            end
            entry.itemCount = entry.itemCount + (count or 1)
            table.insert(entry.locations, location)
          end
        end
      end
    end
  end

  items = {}
  for _, item in pairs(byKey) do
    table.insert(items, item)
  end
  return items
end

local function Auctionator335EnsureLegacyBagPane(self)
  local bag = self and self.BagListing
  if not bag then return nil end

  -- The BagInset is a later sibling in the 3.3.5a XML and therefore paints on
  -- top unless we explicitly lift the interactive bag content above it.
  if self.BagInset and bag.GetFrameLevel and self.BagInset.GetFrameLevel then
    bag:SetFrameLevel(self.BagInset:GetFrameLevel() + 3)
  end

  if bag.Auctionator335LegacyScroll then
    return bag
  end

  -- Keep the modern view alive for state/callback compatibility but don't let
  -- its non-clipping children fight the native Wrath renderer.
  if bag.View then
    bag.View:Hide()
  end

  local scroll = CreateFrame("ScrollFrame", nil, bag)
  scroll:SetPoint("TOPLEFT", bag, "TOPLEFT", 4, -4)
  scroll:SetPoint("BOTTOMRIGHT", bag, "BOTTOMRIGHT", -18, 4)
  scroll:SetFrameLevel(bag:GetFrameLevel() + 1)
  scroll:EnableMouseWheel(true)

  local content = CreateFrame("Frame", nil, scroll)
  content:SetWidth(math.max(1, scroll:GetWidth()))
  content:SetHeight(1)
  scroll:SetScrollChild(content)

  local bar = CreateFrame("Slider", nil, bag, "UIPanelScrollBarTemplate")
  bar:SetPoint("TOPRIGHT", bag, "TOPRIGHT", -1, -16)
  bar:SetPoint("BOTTOMRIGHT", bag, "BOTTOMRIGHT", -1, 16)
  bar:SetFrameLevel(bag:GetFrameLevel() + 2)

  -- UIPanelScrollBarTemplate ships with an inherited OnValueChanged that calls
  -- parent:SetVerticalScroll().  Our parent is BagListing, not a ScrollFrame,
  -- so installing our handler MUST happen before the first SetValue().
  bar:SetScript("OnValueChanged", function(_, value)
    value = value or 0
    -- Some 3.3.5a FrameXML variants create the ScrollFrame object without
    -- exposing SetVerticalScroll. Move the scroll child directly as a legacy
    -- fallback instead of throwing and aborting the Selling tab bootstrap.
    if scroll.SetVerticalScroll then
      scroll:SetVerticalScroll(value)
    else
      content:ClearAllPoints()
      content:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, value)
    end
  end)
  bar:SetMinMaxValues(0, 0)
  bar:SetValueStep(20)
  bar:SetValue(0)
  scroll:SetScript("OnMouseWheel", function(_, delta)
    local minValue, maxValue = bar:GetMinMaxValues()
    local value = math.max(minValue or 0, math.min(maxValue or 0, bar:GetValue() - delta * 42))
    bar:SetValue(value)
  end)

  bag.Auctionator335LegacyScroll = scroll
  bag.Auctionator335LegacyContent = content
  bag.Auctionator335LegacyScrollBar = bar
  bag.Auctionator335LegacyHeaders = {}
  bag.Auctionator335LegacyButtons = {}
  bag.Auctionator335LegacySelected = nil

  function bag:Auctionator335SetLegacySelection(sortKey)
    self.Auctionator335LegacySelected = sortKey
    for _, button in ipairs(self.Auctionator335LegacyButtons or {}) do
      if button.itemInfo and button.itemInfo.sortKey == sortKey then
        button.Selected:Show()
        button.Icon:SetAlpha(0.8)
      else
        button.Selected:Hide()
        button.Icon:SetAlpha(1)
      end
    end
  end

  return bag
end

local function Auctionator335AcquireBagHeader(bag, index)
  local header = bag.Auctionator335LegacyHeaders[index]
  if header then
    header:Show()
    return header
  end
  header = CreateFrame("Button", nil, bag.Auctionator335LegacyContent)
  header:SetHeight(20)
  header.Text = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  header.Text:SetPoint("LEFT", header, "LEFT", 5, 0)
  header.Text:SetJustifyH("LEFT")
  header.Line = header:CreateTexture(nil, "BACKGROUND")
  header.Line:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
  header.Line:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
  header.Line:SetHeight(1)
  header.Line:SetTexture(1, 1, 1, 0.12)
  bag.Auctionator335LegacyHeaders[index] = header
  return header
end

local function Auctionator335AcquireBagButton(bag, index)
  local button = bag.Auctionator335LegacyButtons[index]
  if button then
    button:Show()
    return button
  end

  button = CreateFrame("Button", nil, bag.Auctionator335LegacyContent)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button.Background = button:CreateTexture(nil, "BACKGROUND")
  button.Background:SetPoint("TOPLEFT", 2, -2)
  button.Background:SetPoint("BOTTOMRIGHT", -2, 2)
  button.Background:SetTexture(0.03, 0.03, 0.03, 0.95)

  button.Icon = button:CreateTexture(nil, "ARTWORK")
  button.Icon:SetPoint("TOPLEFT", 3, -3)
  button.Icon:SetPoint("BOTTOMRIGHT", -3, 3)
  button.Icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)

  -- Wrath's UI-ActionButton-Border is a glow texture rather than a true
  -- rectangular icon border.  Scaling it to the bag icon either makes the
  -- glow spill over neighbouring items or makes it look smaller than the
  -- icon.  Draw a real square quality border around the icon instead.
  button.Border = CreateFrame("Frame", nil, button)
  button.Border:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
  button.Border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
  button.Border:SetFrameLevel(button:GetFrameLevel() + 2)
  button.Border.Lines = {}
  local function MakeHorizontalBorder(anchor, y)
    local line = button.Border:CreateTexture(nil, "OVERLAY")
    line:SetTexture(1, 1, 1, 1)
    line:SetHeight(1)
    line:SetPoint(anchor .. "LEFT", button.Border, anchor .. "LEFT", 0, y)
    line:SetPoint(anchor .. "RIGHT", button.Border, anchor .. "RIGHT", 0, y)
    table.insert(button.Border.Lines, line)
  end
  local function MakeVerticalBorder(anchor, x)
    local line = button.Border:CreateTexture(nil, "OVERLAY")
    line:SetTexture(1, 1, 1, 1)
    line:SetWidth(1)
    line:SetPoint("TOP" .. anchor, button.Border, "TOP" .. anchor, x, 0)
    line:SetPoint("BOTTOM" .. anchor, button.Border, "BOTTOM" .. anchor, x, 0)
    table.insert(button.Border.Lines, line)
  end
  -- One-pixel strips, immediately outside the icon. In 3.3.5a a texture
  -- anchored by two diagonal corners can expand to fill the whole frame,
  -- which was why the 0.55 quality colour became a solid square.
  MakeHorizontalBorder("TOP", 0)
  MakeHorizontalBorder("BOTTOM", 0)
  MakeVerticalBorder("LEFT", 0)
  MakeVerticalBorder("RIGHT", 0)
  function button.Border:SetVertexColor(r, g, b, a)
    for _, line in ipairs(self.Lines or {}) do
      line:SetVertexColor(r, g, b, a or 1)
    end
  end

  -- Selection uses the same geometry, just one pixel further out, so both
  -- effects remain tied to the icon itself instead of becoming an oversized
  -- action-button glow.
  button.Selected = CreateFrame("Frame", nil, button)
  button.Selected:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
  button.Selected:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
  button.Selected:SetFrameLevel(button:GetFrameLevel() + 3)
  button.Selected.Lines = {}
  local function MakeSelectedHorizontal(anchor)
    local line = button.Selected:CreateTexture(nil, "OVERLAY")
    line:SetTexture(1, 0.65, 0.1, 1)
    line:SetHeight(1)
    line:SetPoint(anchor .. "LEFT", button.Selected, anchor .. "LEFT", 0, 0)
    line:SetPoint(anchor .. "RIGHT", button.Selected, anchor .. "RIGHT", 0, 0)
    table.insert(button.Selected.Lines, line)
  end
  local function MakeSelectedVertical(anchor)
    local line = button.Selected:CreateTexture(nil, "OVERLAY")
    line:SetTexture(1, 0.65, 0.1, 1)
    line:SetWidth(1)
    line:SetPoint("TOP" .. anchor, button.Selected, "TOP" .. anchor, 0, 0)
    line:SetPoint("BOTTOM" .. anchor, button.Selected, "BOTTOM" .. anchor, 0, 0)
    table.insert(button.Selected.Lines, line)
  end
  MakeSelectedHorizontal("TOP")
  MakeSelectedHorizontal("BOTTOM")
  MakeSelectedVertical("LEFT")
  MakeSelectedVertical("RIGHT")
  button.Selected:Hide()

  button.Count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)
  button.Count:SetJustifyH("RIGHT")

  button:SetScript("OnEnter", function(b)
    if b.itemInfo and b.itemInfo.itemLink then
      GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
      GameTooltip:SetHyperlink(b.itemInfo.itemLink)
      GameTooltip:Show()
    end
  end)
  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  button:SetScript("OnClick", function(b, mouseButton)
    if mouseButton ~= "LeftButton" or not b.itemInfo then
      return
    end
    local postingInfo = Auctionator.Groups.Utilities.ToPostingItem(b.itemInfo)
    postingInfo.key = b.key
    postingInfo.sortKey = b.itemInfo.sortKey
    postingInfo.nextItem = b.nextItem
    postingInfo.prevItem = b.prevItem
    bag:Auctionator335SetLegacySelection(b.itemInfo.sortKey)
    if not Auctionator.EventBus:IsSourceRegistered(bag) then
      Auctionator.EventBus:RegisterSource(bag, "Auctionator335SellingBag")
    end
    Auctionator.EventBus:Fire(bag, Auctionator.Selling.Events.BagItemClicked, postingInfo)
  end)

  bag.Auctionator335LegacyButtons[index] = button
  return button
end

local function Auctionator335RenderLegacyBag(self, cache)
  local bag = Auctionator335EnsureLegacyBagPane(self)
  if not bag then return end

  local items = Auctionator335CollectBagItems(cache)
  table.sort(items, function(a, b)
    if a.classID ~= b.classID then
      return (a.classID or 999) < (b.classID or 999)
    end
    return (a.sortKey or a.itemName or "") < (b.sortKey or b.itemName or "")
  end)

  local grouped = {}
  for _, item in ipairs(items) do
    -- Do not trust a stale auctionable bit on Wrath. Bound state belongs to the
    -- concrete bag slot (a BoE can become soulbound after equipping), so verify
    -- at least one location is currently sellable before rendering it.
    local hasUnboundLocation = false
    if item.locations and #item.locations > 0 then
      for _, location in ipairs(item.locations) do
        if location and not C_Item.IsBound(location) then
          hasUnboundLocation = true
          break
        end
      end
    elseif item.location then
      hasUnboundLocation = not C_Item.IsBound(item.location)
    else
      hasUnboundLocation = item.auctionable == true
    end

    local allowed = item.auctionable and hasUnboundLocation and
      (item.quality ~= Enum.ItemQuality.Poor or Auctionator.Utilities.IsEquipment(item.classID))
    local hidden = bag.View and bag.View.hiddenItems and bag.View.hiddenItems[item.sortKey]
    if allowed and not hidden then
      grouped[item.classID] = grouped[item.classID] or {}
      table.insert(grouped[item.classID], item)
    end
  end

  for _, header in ipairs(bag.Auctionator335LegacyHeaders) do header:Hide() end
  for _, button in ipairs(bag.Auctionator335LegacyButtons) do button:Hide() end

  local iconSize = Auctionator.Config.Get(Auctionator.Config.Options.SELLING_ICON_SIZE) or 42
  -- The quality border now lives on the icon, so only keep a small visual gap
  -- between neighbouring cells instead of reserving room for an oversized glow.
  local iconGap = 4
  local iconStride = iconSize + iconGap
  local paneWidth = math.max(100, bag.Auctionator335LegacyScroll:GetWidth())
  local columns = math.max(1, math.floor((paneWidth - 8) / iconStride))
  local y = 0
  local headerIndex = 0
  local buttonIndex = 0
  local linearButtons = {}

  local orderedClasses = Auctionator.Groups.Constants.ValidItemClassIDs or {}
  local seenClasses = {}
  local function renderClass(classID)
    local classItems = grouped[classID]
    if not classItems or #classItems == 0 then return end
    seenClasses[classID] = true

    headerIndex = headerIndex + 1
    local header = Auctionator335AcquireBagHeader(bag, headerIndex)
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT", bag.Auctionator335LegacyContent, "TOPLEFT", 0, -y)
    header:SetWidth(paneWidth - 2)
    header.Text:SetText(C_Item.GetItemClassInfo(classID) or tostring(classID))
    y = y + 21

    local rows = math.ceil(#classItems / columns)
    for i, item in ipairs(classItems) do
      buttonIndex = buttonIndex + 1
      local button = Auctionator335AcquireBagButton(bag, buttonIndex)
      local col = (i - 1) % columns
      local row = math.floor((i - 1) / columns)
      button:ClearAllPoints()
      button:SetPoint("TOPLEFT", bag.Auctionator335LegacyContent, "TOPLEFT",
        4 + col * iconStride,
        -(y + row * iconStride))
      button:SetSize(iconSize, iconSize)
      button.itemInfo = item
      button.key = {keyName = "k_" .. (C_Item.GetItemClassInfo(classID) or tostring(classID)), sortKey = item.sortKey}
      local texture = item.iconTexture or (item.itemID and GetItemIcon and GetItemIcon(item.itemID)) or select(10, GetItemInfo(item.itemLink))
      button.Icon:SetTexture(texture)
      button.Count:SetText(item.itemCount and item.itemCount > 1 and item.itemCount or "")
      local qualityColor = ITEM_QUALITY_COLORS[item.quality or 1] or ITEM_QUALITY_COLORS[1]
      if qualityColor then
        button.Border:SetVertexColor(qualityColor.r, qualityColor.g, qualityColor.b, 1)
      end
      table.insert(linearButtons, button)
    end
    y = y + rows * iconStride + 4
  end

  for _, classID in ipairs(orderedClasses) do
    renderClass(classID)
  end
  for classID in pairs(grouped) do
    if not seenClasses[classID] then
      renderClass(classID)
    end
  end

  for i, button in ipairs(linearButtons) do
    local prev = linearButtons[i - 1]
    local nxt = linearButtons[i + 1]
    button.prevItem = prev and prev.key or nil
    button.nextItem = nxt and nxt.key or nil
  end

  bag.Auctionator335LegacyContent:SetWidth(paneWidth)
  local viewHeight = math.max(1, bag.Auctionator335LegacyScroll:GetHeight())
  local contentHeight = math.max(viewHeight, y)
  bag.Auctionator335LegacyContent:SetHeight(contentHeight)
  local maxScroll = math.max(0, contentHeight - viewHeight)
  bag.Auctionator335LegacyScrollBar:SetMinMaxValues(0, maxScroll)
  bag.Auctionator335LegacyScrollBar:SetValue(math.min(bag.Auctionator335LegacyScrollBar:GetValue() or 0, maxScroll))
  bag.Auctionator335LegacyScrollBar:SetShown(maxScroll > 0)
  bag:Auctionator335SetLegacySelection(bag.Auctionator335LegacySelected)
end

local function Auctionator335SellingEnsureBagView(self, refreshBag)
  if not self or not self.BagListing or not self.BagListing.View then return end

  local view = self.BagListing.View
  -- 3.3.5a can create the inherited child frame without executing all of the
  -- modern template lifecycle. Reapply the view mixin/identity explicitly.
  Mixin(view, AuctionatorGroupsViewMixin)
  view.itemTemplate = "AuctionatorGroupsViewItemTemplate"
  view.groupTemplate = "AuctionatorSellingViewGroupTemplate"
  view.groupInsetX = 0
  view.clickEventName = "BagUse.BagItemClicked"
  view.completeEventName = "ViewComplete"
  view.hideHiddenItems = true
  view.applyVisibility = true
  view.collapsing = view.collapsing or {}
  view.groups = view.groups or {}
  view.rawItems = view.rawItems or {}
  view.hiddenItems = view.hiddenItems or {}
  if view.originalOpen == nil then view.originalOpen = true end
  view:EnsurePools()

  -- Keep callback registration deterministic. Our compatibility registry now
  -- de-duplicates, but unregistering here also cleans up old 0.33 registrations
  -- after /reload during development.
  Auctionator.Groups.CallbackRegistry:UnregisterCallback("BagCacheUpdated", view)
  Auctionator.Groups.CallbackRegistry:UnregisterCallback("ViewGroupToggled", view)
  Auctionator.Groups.CallbackRegistry:UnregisterCallback("Customise.EditMade", view)
  Auctionator.Groups.CallbackRegistry:RegisterCallback("BagCacheUpdated", view.Update, view)
  Auctionator.Groups.CallbackRegistry:RegisterCallback("ViewGroupToggled", view.UpdateGroupHeights, view)
  Auctionator.Groups.CallbackRegistry:RegisterCallback("Customise.EditMade", view.UpdateCustomGroups, view)

  view:UpdateCustomGroups()

  local cache = AuctionatorBagCacheFrame
  if cache then
    -- Render anything already cached immediately, then force a real legacy-bag
    -- scan. This avoids relying on inherited OnShow -> BagCacheOn, which is the
    -- part that was getting lost on 3.3.5a and left the left pane empty.
    view:Update(cache)
    if refreshBag and cache.DoBagRefresh then
      cache:DoBagRefresh()
      -- The Wrath compatibility scan above is synchronous. Repaint directly as
      -- well as through BagCacheUpdated so the left pane cannot depend on a
      -- callback/lifecycle handler that may have been lost through XML
      -- inheritance on 3.3.5a.
      view:Update(cache)
    end
    Auctionator335RenderLegacyBag(self, cache)
  else
    -- The native renderer has its own direct bag fallback and can still build
    -- the pane if the global cache frame has not been created yet.
    Auctionator335RenderLegacyBag(self, nil)
  end
end

function AuctionatorSellingTabMixin:OnLoad()
  self:ApplyHiding()

  Auctionator.Groups.OnAHOpen()
  self:RegisterEvent("BAG_UPDATE")
  local defaultIconSize = Auctionator.Config.Defaults[Auctionator.Config.Options.SELLING_ICON_SIZE]
  local currentIconSize = Auctionator.Config.Get(Auctionator.Config.Options.SELLING_ICON_SIZE)
  local defaultIconsPerRow = 6
  local scrollBarWidth = (self.BagListing.View and self.BagListing.View.ScrollBar and self.BagListing.View.ScrollBar:GetWidth()) or 14
  self.BagListing:SetWidth(math.ceil(defaultIconsPerRow * defaultIconSize / currentIconSize ) * currentIconSize + scrollBarWidth + 4 * 2)

  -- Child <Scripts> blocks replace inherited lifecycle handlers on 3.3.5a.
  -- Prime the view now; OnShow performs the real bag scan.
  Auctionator335SellingEnsureBagView(self, false)

  self.BuyFrame:Init()
end

function AuctionatorSellingTabMixin:OnShow()
  Auctionator335SellingEnsureBagView(self, true)
end

function AuctionatorSellingTabMixin:OnEvent(eventName, ...)
  if eventName == "BAG_UPDATE" and self:IsShown() then
    Auctionator335SellingEnsureBagView(self, true)
  end
end

function AuctionatorSellingTabMixin:ApplyHiding()
  if not Auctionator.Config.Get(Auctionator.Config.Options.SHOW_SELLING_BAG) then
    self.BagListing:Hide()
    self.BagInset:Hide()
    self.BuyFrame:SetPoint("TOPLEFT", self.BagListing, "TOPLEFT", 10, 10)
    self.BuyFrame.HistoryButton:SetPoint("LEFT", AuctionFrameMoneyFrame, "RIGHT")
  end
end

function AuctionatorSellingTabMixin:OnHide()
  self:Hide()
end
