local function IsEquipment(itemInfo)
  return Auctionator.Utilities.IsEquipment(itemInfo.classId)
end

local function IsValidItem(item)
  return item ~= nil and
    -- May be a favourite with no items available, ignore it.
    item.location ~= nil and
    -- Location may be invalid because of items being moved in the bag
    C_Item.DoesItemExist(item.location)
end

local function GetAmountWithUndercut(amount)
  local salesPreference = Auctionator.Config.Get(Auctionator.Config.Options.AUCTION_SALES_PREFERENCE)
  local undercutAmount = 0
  if salesPreference == Auctionator.Config.SalesTypes.STATIC then
    undercutAmount = Auctionator.Config.Get(Auctionator.Config.Options.UNDERCUT_STATIC_VALUE)
  else
    undercutAmount = math.ceil(amount * Auctionator.Config.Get(Auctionator.Config.Options.UNDERCUT_PERCENTAGE) / 100)
  end

  return math.max(0, amount - undercutAmount)
end

AuctionatorSaleItemMixin = {}

-- 3.3.5a does not reliably expose $parent-named FontStrings from virtual
-- templates as fields on the owning frame. Re-resolve them and create simple
-- fallbacks so Selling can reset/update with no item selected.
local function Auctionator335EnsureSaleItemPriceLabels(self)
  if not self then return end
  local name = self.GetName and self:GetName()
  if name then
    self.Deposit = self.Deposit or _G[name .. "Deposit"]
    self.DepositPrice = self.DepositPrice or _G[name .. "DepositPrice"]
    self.Total = self.Total or _G[name .. "Total"]
    self.TotalPrice = self.TotalPrice or _G[name .. "TotalPrice"]
  end

  if not self.Deposit then
    self.Deposit = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    self.Deposit:SetText(AUCTIONATOR_L_DEPOSIT or "Deposit:")
    if self.Duration then
      self.Deposit:SetPoint("TOPLEFT", self.Duration, "TOPRIGHT", 20, 0)
    else
      self.Deposit:SetPoint("TOPLEFT", self, "TOPLEFT", 360, -35)
    end
  end
  if not self.DepositPrice then
    self.DepositPrice = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.DepositPrice:SetHeight(25)
    self.DepositPrice:SetPoint("TOPLEFT", self.Deposit, "BOTTOMLEFT", 0, 0)
  end
  if not self.Total then
    self.Total = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    self.Total:SetText(AUCTIONATOR_L_TOTAL_PRICE or "Total Price:")
    self.Total:SetPoint("TOPLEFT", self.DepositPrice, "BOTTOMLEFT", 0, 0)
  end
  if not self.TotalPrice then
    self.TotalPrice = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.TotalPrice:SetHeight(25)
    self.TotalPrice:SetPoint("TOPLEFT", self.Total, "BOTTOMLEFT", 0, 0)
  end
end

-- Rebuild the Selling header explicitly. Modern relativeKey/$parent anchors
-- do not survive 3.3.5a XML inheritance reliably, leaving the price labels on
-- the wrong side, stack controls overlapping and Duration collapsed into a
-- pile of radio buttons. Keep the original controls/logic; only repair their
-- geometry.
local function Auctionator335LayoutSellingSaleItem(self)
  if not self then return end

  self:SetSize(820, 125)

  if self.TitleArea then
    self.TitleArea:ClearAllPoints()
    self.TitleArea:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
    self.TitleArea:SetPoint("RIGHT", self, "RIGHT", 0, 0)
    self.TitleArea:SetHeight(24)
    if self.TitleArea.Text then
      self.TitleArea.Text:ClearAllPoints()
      self.TitleArea.Text:SetPoint("TOPLEFT", self.TitleArea, "TOPLEFT", 15, -5)
    end
  end

  if self.Icon then
    self.Icon:ClearAllPoints()
    self.Icon:SetPoint("TOPLEFT", self, "TOPLEFT", -20, -28)
    self.Icon:SetSize(60, 60)
  end

  local function LayoutMoneyControl(control, x, y)
    if not control then return end
    control:ClearAllPoints()
    control:SetPoint("TOPLEFT", self, "TOPLEFT", x, y)
    control:SetSize(300, 22)
    if control.Label then
      control.Label:ClearAllPoints()
      control.Label:SetPoint("LEFT", control, "LEFT", 0, 0)
    end
    if control.MoneyInput then
      control.MoneyInput:ClearAllPoints()
      control.MoneyInput:SetPoint("LEFT", control, "LEFT", 78, 0)
      control.MoneyInput:SetSize(200, 20)
    end
  end

  LayoutMoneyControl(self.UnitPrice, 82, -28)
  LayoutMoneyControl(self.StackPrice, 82, -60)

  if self.Stacks then
    self.Stacks:ClearAllPoints()
    self.Stacks:SetPoint("TOPLEFT", self, "TOPLEFT", 157, -88)
    self.Stacks:SetSize(250, 40)

    -- The inherited $parentLabel exists on 3.3.5a but is not always exposed as
    -- self.Stacks.Label. Resolve it first; otherwise creating a fallback gives
    -- the visible double "stack of" seen in 0.35.
    local stacksName = self.Stacks.GetName and self.Stacks:GetName()
    if stacksName then
      self.Stacks.Label = self.Stacks.Label or _G[stacksName .. 'Label']
    end
    if not self.Stacks.Label and self.Stacks.CreateFontString then
      self.Stacks.Label = self.Stacks:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    end

    -- If an inherited label escaped the field lookup, hide any duplicate text
    -- region and keep exactly one canonical label.
    local stackOfText = AUCTIONATOR_L_STACK_OF or "stack of"
    local regions = {self.Stacks:GetRegions()}
    for _, region in ipairs(regions) do
      if region ~= self.Stacks.Label and region.GetText and region:GetText() == stackOfText then
        region:Hide()
      end
    end

    if self.Stacks.NumStacks then
      self.Stacks.NumStacks:ClearAllPoints()
      self.Stacks.NumStacks:SetPoint("TOPLEFT", self.Stacks, "TOPLEFT", 0, 0)
      self.Stacks.NumStacks:SetSize(70, 20)
      self.Stacks.NumStacks:Show()
    end
    if self.Stacks.Label then
      self.Stacks.Label:ClearAllPoints()
      -- Explicit coordinates are intentional: relativeKey/$parent anchors from
      -- modern FrameXML are not reliable on 3.3.5a.
      self.Stacks.Label:SetPoint("LEFT", self.Stacks, "LEFT", 80, 10)
      self.Stacks.Label:SetText(stackOfText)
      self.Stacks.Label:Show()
    end
    if self.Stacks.StackSize then
      self.Stacks.StackSize:ClearAllPoints()
      self.Stacks.StackSize:SetPoint("TOPLEFT", self.Stacks, "TOPLEFT", 145, 0)
      self.Stacks.StackSize:SetSize(70, 20)
      self.Stacks.StackSize:Show()
    end
    if self.Stacks.MaxNumStacks then
      self.Stacks.MaxNumStacks:ClearAllPoints()
      self.Stacks.MaxNumStacks:SetPoint("TOPLEFT", self.Stacks, "TOPLEFT", 10, -23)
    end
    if self.Stacks.MaxStackSize then
      self.Stacks.MaxStackSize:ClearAllPoints()
      self.Stacks.MaxStackSize:SetPoint("TOPLEFT", self.Stacks, "TOPLEFT", 155, -23)
    end
  end

  if self.Duration then
    -- The child XML has already applied the mixin, but keep this self-healing
    -- for old SavedVariables/UI reload paths.
    if not self.Duration.SetSelectedValue then
      Mixin(self.Duration, AuctionatorConfigHorizontalRadioButtonGroupMixin)
      self.Duration.groupHeadingText = AUCTIONATOR_L_DURATION
      if self.Duration.InitializeRadioButtonGroup then
        self.Duration:InitializeRadioButtonGroup()
      end
    end

    self.Duration:ClearAllPoints()
    self.Duration:SetPoint("TOPLEFT", self, "TOPLEFT", 385, -22)
    self.Duration:SetSize(180, 48)

    if self.Duration.GroupHeading then
      self.Duration.GroupHeading:ClearAllPoints()
      self.Duration.GroupHeading:SetPoint("TOPLEFT", self.Duration, "TOPLEFT", 0, 0)
      self.Duration.GroupHeading:SetSize(180, 20)
      if self.Duration.GroupHeading.HeadingText then
        self.Duration.GroupHeading.HeadingText:ClearAllPoints()
        self.Duration.GroupHeading.HeadingText:SetPoint("TOPLEFT", self.Duration.GroupHeading, "TOPLEFT", 0, -4)
        self.Duration.GroupHeading.HeadingText:SetText(AUCTIONATOR_L_DURATION or "Duration")
      end
    end

    local radios = {}
    for _, child in ipairs({self.Duration:GetChildren()}) do
      if child.isAuctionatorRadio then
        table.insert(radios, child)
      end
    end
    table.sort(radios, function(a, b)
      return (tonumber(a.value) or 0) < (tonumber(b.value) or 0)
    end)

    for radioIndex, child in ipairs(radios) do
      child:ClearAllPoints()
      child:SetPoint("TOPLEFT", self.Duration, "TOPLEFT", (radioIndex - 1) * 55, -20)
      child:SetSize(55, 20)
      if child.RadioButton then
        child.RadioButton:ClearAllPoints()
        child.RadioButton:SetPoint("LEFT", child, "LEFT", 0, 0)

        -- Do not rely on inherited $parentLabel fields here. Give each duration
        -- radio one explicit Wrath-safe label so 12/24/48 can never collapse or
        -- disappear independently.
        if child.RadioButton.Label then
          child.RadioButton.Label:Hide()
        end
        if not child.Auctionator335DurationLabel then
          child.Auctionator335DurationLabel = child:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        end
        local durationValue = tonumber(child.value) or ({12, 24, 48})[radioIndex]
        child.value = durationValue
        child.labelText = durationValue
        child.Auctionator335DurationLabel:ClearAllPoints()
        child.Auctionator335DurationLabel:SetPoint("LEFT", child.RadioButton, "RIGHT", 2, 0)
        child.Auctionator335DurationLabel:SetText(tostring(durationValue))
        child.Auctionator335DurationLabel:Show()
      end
    end
  end

  Auctionator335EnsureSaleItemPriceLabels(self)
  if self.Deposit then
    self.Deposit:ClearAllPoints()
    self.Deposit:SetPoint("TOPLEFT", self, "TOPLEFT", 590, -24)
  end
  if self.DepositPrice then
    self.DepositPrice:ClearAllPoints()
    self.DepositPrice:SetPoint("TOPLEFT", self, "TOPLEFT", 590, -42)
  end
  if self.Total then
    self.Total:ClearAllPoints()
    self.Total:SetPoint("TOPLEFT", self, "TOPLEFT", 590, -66)
  end
  if self.TotalPrice then
    self.TotalPrice:ClearAllPoints()
    self.TotalPrice:SetPoint("TOPLEFT", self, "TOPLEFT", 590, -84)
  end

  if self.PostButton then
    self.PostButton:ClearAllPoints()
    self.PostButton:SetPoint("TOPLEFT", self, "TOPLEFT", 397, -80)
    self.PostButton:SetSize(180, 22)
  end
  if self.PrevButton then
    self.PrevButton:ClearAllPoints()
    self.PrevButton:SetPoint("RIGHT", self.PostButton, "LEFT", 0, 0)
  end
  if self.SkipButton then
    self.SkipButton:ClearAllPoints()
    self.SkipButton:SetPoint("LEFT", self.PostButton, "RIGHT", 0, 0)
  end

  if self.BidPrice and self.BidPrice:IsShown() then
    LayoutMoneyControl(self.BidPrice, 75, -88)
  end
end

function AuctionatorSaleItemMixin:OnLoad()
  if Auctionator.Config.Get(Auctionator.Config.Options.SHOW_SELLING_BID_PRICE) then
    self.BidPrice:Show()
  end

  Auctionator335LayoutSellingSaleItem(self)
  self:SetupTabbing()
  self.clickedSellItem = true
end

-- Make pressing tab work to jump between edit boxes in the SaleItemFrame
function AuctionatorSaleItemMixin:SetupTabbing()
  self.UnitPrice.MoneyInput:SetNextEditBox(self.StackPrice.MoneyInput.GoldBox)
  self.StackPrice.MoneyInput:SetNextEditBox(self.Stacks.NumStacks)
  self.Stacks.NumStacks.nextEditBox = self.Stacks.StackSize
  self.Stacks.StackSize.previousEditBox = self.Stacks.NumStacks

  if Auctionator.Config.Get(Auctionator.Config.Options.SHOW_SELLING_BID_PRICE) then
    self.Stacks.StackSize.nextEditBox = self.BidPrice.MoneyInput.GoldBox
    self.BidPrice.MoneyInput.GoldBox.previousEditBox = self.Stacks.StackSize
  end
end

function AuctionatorSaleItemMixin:OnShow()
  Auctionator.EventBus:Register(self, {
    Auctionator.Selling.Events.BagItemClicked,
    Auctionator.Selling.Events.ClearBagItem,
    Auctionator.Selling.Events.RequestPost,
    Auctionator.Selling.Events.SkipItem,
    Auctionator.Selling.Events.ConfirmPost,
    Auctionator.Selling.Events.PostSuccessful,
    Auctionator.Selling.Events.PostFailed,
    Auctionator.Buying.Events.ViewSetup,
    Auctionator.AH.Events.ThrottleUpdate,
    Auctionator.Buying.Events.AuctionFocussed,
    Auctionator.Buying.Events.HistoricalPrice,
    Auctionator.Components.Events.EnterPressed,
  })
  Auctionator.EventBus:RegisterSource(self, "AuctionatorSaleItemMixin")

  local function SetupBindings()
    if self:IsVisible() then
      SetOverrideBinding(self, false, Auctionator.Config.Get(Auctionator.Config.Options.SELLING_POST_SHORTCUT), "CLICK AuctionatorPostButton:LeftButton")
      SetOverrideBinding(self, false, Auctionator.Config.Get(Auctionator.Config.Options.SELLING_SKIP_SHORTCUT), "CLICK AuctionatorSkipPostingButton:LeftButton")
      SetOverrideBinding(self, false, Auctionator.Config.Get(Auctionator.Config.Options.SELLING_PREV_SHORTCUT), "CLICK AuctionatorPrevPostingButton:LeftButton")
    end
  end
  if InCombatLockdown() then
    EventUtil.ContinueAfterAllEvents(SetupBindings, "PLAYER_REGEN_ENABLED")
  else
    SetupBindings()
  end

  self:UpdateSkipButton()
  self:Reset()

  if Auctionator.Config.Get(Auctionator.Config.Options.SELLING_SHOULD_RESELECT_ITEM) then
    local key = Auctionator.Config.Get(Auctionator.Config.Options.SELLING_RESELECT_ITEM)
    if key ~= nil then
      self.lastKey = key
      Auctionator.EventBus:Fire(
        self, Auctionator.Selling.Events.BagItemRequest, key
      )
    end
  end
end

function AuctionatorSaleItemMixin:OnHide()
  Auctionator.EventBus:Unregister(self, {
    Auctionator.Selling.Events.BagItemClicked,
    Auctionator.Selling.Events.ClearBagItem,
    Auctionator.Selling.Events.RequestPost,
    Auctionator.Selling.Events.ConfirmPost,
    Auctionator.Selling.Events.SkipItem,
    Auctionator.Selling.Events.PostSuccessful,
    Auctionator.Selling.Events.PostFailed,
    Auctionator.Buying.Events.ViewSetup,
    Auctionator.AH.Events.ThrottleUpdate,
    Auctionator.Buying.Events.AuctionFocussed,
    Auctionator.Buying.Events.HistoricalPrice,
    Auctionator.Components.Events.EnterPressed,
  })
  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_RESELECT_ITEM, self.lastKey)
  Auctionator.EventBus:UnregisterSource(self)
  self:UnlockItem()

  if InCombatLockdown() then
    EventUtil.ContinueAfterAllEvents(function() ClearOverrideBindings(self) end, "PLAYER_REGEN_ENABLED")
  else
    ClearOverrideBindings(self)
  end
end

function AuctionatorSaleItemMixin:UpdateSkipButton()
  if Auctionator.Config.Get(Auctionator.Config.Options.SELLING_AUTO_SELECT_NEXT) then
    self.PostButton:SetSize(104, 22)
    self.SkipButton:Show()
  else
    self.PostButton:SetSize(184, 22)
    self.SkipButton:Hide()
  end
end

function AuctionatorSaleItemMixin:UnlockItem()
  if self.itemInfo ~= nil then
    --Existence check added because of a bug report from a user where (for an
    --unknown reason) the item no longer existed.
    if self.itemInfo.count > 0 and C_Item.DoesItemExist(self.itemInfo.location) then
      C_Item.UnlockItem(self.itemInfo.location)
    end
    self.itemInfo = nil
  end
end

function AuctionatorSaleItemMixin:LockItem()
  if self.itemInfo.count > 0 then
    C_Item.LockItem(self.itemInfo.location)
  end
end

function AuctionatorSaleItemMixin:UpdatePrices()
  Auctionator335EnsureSaleItemPriceLabels(self)
  if self.UnitPrice:GetAmount() ~= self.prevUnitPrice then
    self.prevUnitPrice = self.UnitPrice:GetAmount()
    self.prevStackPrice = self.prevUnitPrice * self.prevStackSize
    self.StackPrice:SetAmount(self.prevStackPrice)
    self.BidPrice:SetAmount(self:GetAutoBidAmount())

  elseif self.StackPrice:GetAmount() ~= self.prevStackPrice then
    self.prevStackPrice = self.StackPrice:GetAmount()
    if self.prevStackSize ~= 0 then
      self.prevUnitPrice = math.ceil(self.prevStackPrice / self.prevStackSize)
      self.UnitPrice:SetAmount(self.prevUnitPrice)
      self.BidPrice:SetAmount(self:GetAutoBidAmount())
    end

  elseif self:GetStackSize() ~= self.prevStackSize then
    self.prevStackSize = self:GetStackSize()
    self.prevStackPrice = self:GetStackSize() * self.UnitPrice:GetAmount()
    self.StackPrice:SetAmount(self.prevStackPrice)
    self.BidPrice:SetAmount(self:GetAutoBidAmount())
    self:DisplayMaxNumStacks()
  end
end

function AuctionatorSaleItemMixin:OnUpdate()
  GetOwnerAuctionItems(0)
  if self.itemInfo == nil then
    return

  elseif self.itemInfo.count == 0 and self.clickedSellItem then
    return

  elseif self.itemInfo.location ~= nil and not C_Item.DoesItemExist(self.itemInfo.location) then
    local itemInfo = Auctionator.Groups.Utilities.QueryItem(self.itemInfo.sortKey)
    self.itemInfo.location = itemInfo and itemInfo.locations[1]
    -- Bag position changes (race condition or posting reattempt)
    if not self.itemInfo.location then
      self.itemInfo = nil
      self:Reset()
      return
    else
      self.clickedSellItem = false
    end
  end

  if not self.clickedSellItem then
    self:SellItemClick()
    return
  end


  self:UpdatePrices()
  self:RefreshNoReferenceFallbackPrice()

  self.TotalPrice:SetText(
    GetMoneyString(
      self:GetNumStacks() * self:GetStackSize() * self.UnitPrice:GetAmount(),
      true
    )
  )

  self.DepositPrice:SetText(GetMoneyString(self:GetDeposit(), true))
  self:UpdatePostButtonState()
  self:UpdateSkipButtonState()
end

function AuctionatorSaleItemMixin:GetAutoBidAmount()
  local startingPricePercentage = Auctionator.Config.Get(Auctionator.Config.Options.STARTING_PRICE_PERCENTAGE) / 100
  return math.ceil(startingPricePercentage * self.StackPrice:GetAmount())
end

function AuctionatorSaleItemMixin:GetBidAmount()
  if Auctionator.Config.Get(Auctionator.Config.Options.SHOW_SELLING_BID_PRICE) then
    return self.BidPrice:GetAmount()
  else
    return self:GetAutoBidAmount()
  end
end

function AuctionatorSaleItemMixin:GetStackSize()
  return math.min(self.Stacks.StackSize:GetNumber(), math.min(self.itemInfo.count, self.itemInfo.stackSize))
end

function AuctionatorSaleItemMixin:GetNumStacks()
  return math.min(self.Stacks.NumStacks:GetNumber(), self.itemInfo.count)
end

function AuctionatorSaleItemMixin:GetDeposit()
  return GetAuctionDeposit(
    self:GetDuration(),
    math.min(self:GetBidAmount(), MAXIMUM_BID_PRICE),
    math.min(self.StackPrice:GetAmount(), MAXIMUM_BID_PRICE),
    self:GetStackSize(),
    self:GetNumStacks()
  )
end

-- We need to wait for whatever item is being posted to finish posting
-- before accepting the new item, hence the throttle check and this extra
-- function.
-- Also, when using right-click as a shortcut to select the item or reselecting
-- the same item this fails on the first couple of attempts.
function AuctionatorSaleItemMixin:SellItemClick()
  self.clickedSellItem = true

  ClearCursor()

  -- Remove any item already selected in the Auctions frame, as if it is the
  -- same as the item we're trying to add it will cause the add to fail.
  ClickAuctionSellItemButton()
  ClearCursor()

  if IsValidItem(self.itemInfo) then
    local bagID, slotID = Auctionator_GetBagAndSlotFromLocation(self.itemInfo.location)
    if bagID ~= nil and slotID ~= nil then
      if C_Container and C_Container.PickupContainerItem then
        C_Container.PickupContainerItem(bagID, slotID)
      else
        PickupContainerItem(bagID, slotID)
      end
    else
      local equipmentSlot = Auctionator_GetEquipmentSlotFromLocation(self.itemInfo.location)
      if equipmentSlot ~= nil then
        PickupInventoryItem(equipmentSlot)
      end
    end

    ClickAuctionSellItemButton()
    ClearCursor()

    -- Check we didn't fail
    if (GetAuctionSellItemInfo()) ~= nil then
      Auctionator.Debug.Message("Valid sell item", GetAuctionSellItemInfo())
      self:LockItem()
      if not self.retryingItem then
        Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.RefreshBuying, self.itemInfo)
      end
    -- Failed; this item can't be auctioned
    else
      Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.StopFakeBuyLoading)
      Auctionator.Debug.Message("Invalid sell item")
      self.itemInfo = nil
      self:Update()
    end
  else
    if self.itemInfo ~= nil then
      Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.RefreshBuying, self.itemInfo)
    else
      Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.StopFakeBuyLoading)
    end
    self.itemInfo = nil
  end
end

function AuctionatorSaleItemMixin:ReceiveEvent(event, ...)
  if event == Auctionator.Selling.Events.BagItemClicked then
    local itemInfo = ...
    self.retryingItem = false

    self:UnlockItem()
    self.clickedSellItem = false

    self.itemInfo = itemInfo
    self.nextItem = self.itemInfo and self.itemInfo.nextItem
    self.prevItem = self.itemInfo and self.itemInfo.prevItem
    self.lastKey = self.itemInfo and self.itemInfo.key

    if self.itemInfo ~= nil and self.itemInfo.stackSize == nil then
      self.itemInfo = nil

      local item
      if IsValidItem(itemInfo) then
        item = Item:CreateFromItemLocation(itemInfo.location)
      else
        item = Item:CreateFromItemLink(itemInfo.itemLink)
      end

      item:ContinueOnItemLoad(function()
        itemInfo.stackSize = select(8, C_Item.GetItemInfo(itemInfo.itemLink))
        self.itemInfo = itemInfo

        self:Update()
      end)
    end
    self:Update()

  elseif event == Auctionator.Selling.Events.ClearBagItem then
    self.nextItem = nil
    self.prevItem = nil
    self.lastKey = nil
    self:Reset()
    Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.StopFakeBuyLoading)

  elseif event == Auctionator.AH.Events.ThrottleUpdate then
    self:UpdatePostButtonState()

  elseif event == Auctionator.Buying.Events.ViewSetup then
    self.buyViewSetup = true
    -- Once the current-AH search is complete we know whether there is a real
    -- reference listing. On 3.3.5a use the configured vendor-price fallback
    -- only when no usable current auction exists.
    self:ApplyNoReferenceFallbackPrice()
    self:UpdatePostButtonState()

  elseif event == Auctionator.Selling.Events.RequestPost then
    self:PostItem()

  elseif event == Auctionator.Selling.Events.ConfirmPost then
    self:PostItem(true)

  elseif event == Auctionator.Selling.Events.SkipItem then
    self:SkipItem()

  elseif event == Auctionator.Components.Events.EnterPressed then
    self:PostItem()

  elseif event == Auctionator.Buying.Events.AuctionFocussed and
         self.itemInfo ~= nil then
    local info = ...
    if info ~= nil then
      self:UpdateForHistoryPrice(info.unitPrice)
      local unitPrice
      if not info.isOwned then
        unitPrice = GetAmountWithUndercut(info.unitPrice)
      else
        unitPrice = info.unitPrice
      end
      self.noReferenceFallbackActive = false
      self.lastFallbackUnitPrice = nil
      self.lastFallbackSignature = nil
      self:SetUnitPrice(unitPrice)
      -- Used to check if the undercut is more than 50% below configured setting
      self.priceCutThreshold = unitPrice * 0.5
    end
  elseif event == Auctionator.Buying.Events.HistoricalPrice and
         self.itemInfo ~= nil then
    local price = ...
    -- A completed current-AH search with no reference takes precedence over
    -- stale historical data when the 3.3.5a fallback pricing option is active.
    if not self.noReferenceFallbackActive then
      self:SetUnitPrice(price)
    end
  elseif event == Auctionator.Selling.Events.PostSuccessful then
    local details = ...
    self:SuccessfulPost(details)
    if Auctionator.Config.Get(Auctionator.Config.Options.SELLING_POST_STACK_REMAINDER) and (details.itemInfo.count - details.numStacks * details.stackSize) < details.stackSize then
      self:ReselectItem(details)
    else
      self:DoNextItem(details)
    end
  elseif event == Auctionator.Selling.Events.PostFailed then
    local details = ...
    if details.numStacksReached > 0 then
      self:SuccessfulPost(details)
    end
    UIErrorsFrame:AddMessage(AUCTIONATOR_L_POST_ATTEMPT_FAILED, 1.0, 0.1, 0.1, 1.0)
    Auctionator.Utilities.Message(AUCTIONATOR_L_POST_ATTEMPT_FAILED)
    self:ReselectItem(details)
  end
end

function AuctionatorSaleItemMixin:Update()
  Auctionator335EnsureSaleItemPriceLabels(self)
  self:UpdateVisuals()

  if self.itemInfo ~= nil then
    self:UpdateForNewItem()
  else
    self:UpdateForNoItem()
  end

  self:UpdatePostButtonState()
  self:UpdateSkipButtonState()
end

function AuctionatorSaleItemMixin:UpdateVisuals()
  self.Icon:SetItemInfo(self.itemInfo)

  if self.itemInfo ~= nil then
    self:SetItemName()

  else
    -- No item, reset all the visuals
    self.TitleArea.Text:SetText("")
  end
end

-- The exact item name is only loaded when needed as it slows down loading the
-- bag items too much to do in BagDataProvider.
function AuctionatorSaleItemMixin:SetItemName()
  if self.itemInfo then
    local nativeName, _, nativeQuality = GetItemInfo(self.itemInfo.itemLink)
    local name = Auctionator.Utilities.GetNameFromLink(self.itemInfo.itemLink) or nativeName or self.itemInfo.itemName or ""

    -- Legacy bag/cursor paths can briefly omit the modern quality field. Avoid
    -- indexing ITEM_QUALITY_COLORS with nil and recover the real quality from
    -- the 3.3.5a GetItemInfo result instead.
    local defaultQuality = (Enum and Enum.ItemQuality and Enum.ItemQuality.Standard) or 1
    local quality = tonumber(self.itemInfo.quality) or nativeQuality or defaultQuality
    self.itemInfo.quality = quality
    local qualityInfo = ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[defaultQuality] or ITEM_QUALITY_COLORS[1]
    local color = qualityInfo and qualityInfo.color
    if not color and qualityInfo and qualityInfo.r then
      color = CreateColor(qualityInfo.r, qualityInfo.g, qualityInfo.b, 1)
    end
    color = color or WHITE_FONT_COLOR

    self.TitleArea.Text:SetText(color:WrapTextInColorCode(name))

    if IsEquipment(self.itemInfo) then
      local item = Item:CreateFromItemLink(self.itemInfo.itemLink)
      item:ContinueOnItemLoad(function()
        if not self.itemInfo then return end
        local itemLevel = GetDetailedItemLevelInfo(self.itemInfo.itemLink)
        if itemLevel then
          self.TitleArea.Text:SetText(color:WrapTextInColorCode(name .. " (" .. itemLevel .. ")"))
        end
      end)
    end
  end
end

function AuctionatorSaleItemMixin:UpdateForHistoryPrice(newPrice)
  if self.minPriceSeen == 0 then
    self.minPriceSeen = newPrice
  else
    self.minPriceSeen = math.min(self.minPriceSeen, newPrice)
  end
end

function AuctionatorSaleItemMixin:UpdateForNewItem()
  self.noReferenceFallbackActive = false
  self.lastFallbackUnitPrice = nil
  self.lastFallbackSignature = nil
  self:SetDuration()

  self.Stacks:SetMaxStackSize(math.min(self.itemInfo.stackSize, self.itemInfo.count))

  self:SetQuantity()

  self.priceCutThreshold = nil

  if not self.retryingItem then
    self.buyViewSetup = false

    Auctionator.Utilities.DBKeyFromLink(self.itemInfo.itemLink, function(dbKeys)
      local price = Auctionator.Database:GetFirstPrice(dbKeys)

      if price ~= nil then
        self:SetUnitPrice(price)
      elseif IsEquipment(self.itemInfo) then
        self:SetEquipmentMultiplier(self.itemInfo.itemLink)
      else
        self:SetUnitPrice(0)
      end
    end)

    -- Used because it can take a while for the throttle to clear on a megaserver,
    -- this makes it clear that something is loading rather than leaving the
    -- prices frozen on the previous item.
    Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.StartFakeBuyLoading, {itemLink = self.itemInfo.itemLink})

    self.minPriceSeen = 0
  end
end

function AuctionatorSaleItemMixin:UpdateForNoItem()
  self.noReferenceFallbackActive = false
  self.lastFallbackUnitPrice = nil
  self.lastFallbackSignature = nil
  Auctionator335EnsureSaleItemPriceLabels(self)
  self.Stacks.NumStacks:SetNumber(0)
  self.Stacks.StackSize:SetNumber(0)
  self.Stacks:SetMaxStackSize(0)
  self.Stacks:SetMaxNumStacks(0)
  self:SetUnitPrice(0)

  self.DepositPrice:SetText(GetMoneyString(0))
  self.TotalPrice:SetText(GetMoneyString(0))
end

local groupDurationToRadioDuration = {
  [1] = 12,
  [2] = 24,
  [3] = 48,
}
function AuctionatorSaleItemMixin:SetDuration()
  self.Duration:SetSelectedValue(
    Auctionator.Config.Get(Auctionator.Config.Options.AUCTION_DURATION)
  )
end

function AuctionatorSaleItemMixin:SetQuantity()
  local defaultStacks = CopyTable(Auctionator.Config.Get(Auctionator.Config.Options.DEFAULT_SELLING_STACKS))

  local preferredStackSize = Auctionator.Config.Get(Auctionator.Config.Options.STACK_SIZE_MEMORY)[Auctionator.Utilities.BasicDBKeyFromLink(self.itemInfo.itemLink)]

  -- Determine what the stack size would be without using stack size memory.
  -- This is used to clear stack size memory when the max/min is used
  if defaultStacks.stackSize == 0 then
    self.normalStackSize = math.min(self.itemInfo.count, self.itemInfo.stackSize)
  else
    self.normalStackSize = math.min(defaultStacks.stackSize, self.itemInfo.stackSize)
  end

  if preferredStackSize ~= nil then
    self.Stacks.StackSize:SetNumber(math.min(self.itemInfo.count, preferredStackSize))
  else
    self.Stacks.StackSize:SetNumber(math.min(self.normalStackSize, self.itemInfo.count))
  end

  local numStacks = math.floor(self.itemInfo.count/self.Stacks.StackSize:GetNumber())
  if preferredStackSize ~= nil then
    numStacks = math.floor(self.itemInfo.count/preferredStackSize)
  end

  if numStacks == 0 then
    numStacks = 1
  end

  if self.itemInfo.count == 0 then
    self.Stacks.NumStacks:SetNumber(0)
  elseif defaultStacks.numStacks == 0 then
    self.Stacks.NumStacks:SetNumber(numStacks)
  else
    self.Stacks.NumStacks:SetNumber(math.min(numStacks, defaultStacks.numStacks))
  end

  self:DisplayMaxNumStacks()
end

function AuctionatorSaleItemMixin:DisplayMaxNumStacks()
  local numStacks = math.floor(self.itemInfo.count / self:GetStackSize())
  if self:GetStackSize() == 0 then
    numStacks = 0
  elseif numStacks == 0 then
    numStacks = 1
  end

  self.Stacks:SetMaxNumStacks(numStacks)
end

function AuctionatorSaleItemMixin:Reset()
  self:UnlockItem()

  self:Update()
end

function AuctionatorSaleItemMixin:SetUnitPrice(salesPrice)
  if salesPrice == 0 then
    self.UnitPrice:SetAmount(0)
  else
    self.UnitPrice:SetAmount(salesPrice)
  end

  self.StackPrice:SetAmount(self.UnitPrice:GetAmount() * self.Stacks.StackSize:GetNumber())
  self.BidPrice:SetAmount(self:GetAutoBidAmount())

  self.priceCutThreshold = nil

  self.prevStackSize = self.Stacks.StackSize:GetNumber()
  self.prevUnitPrice = self.UnitPrice:GetAmount()
  self.prevStackPrice = self.StackPrice:GetAmount()
end

function AuctionatorSaleItemMixin:SetEquipmentMultiplier(itemLink)
  self:SetUnitPrice(0)

  local item = Item:CreateFromItemLink(itemLink)
  item:ContinueOnItemLoad(function()
    local multiplier = Auctionator.Config.Get(Auctionator.Config.Options.GEAR_PRICE_MULTIPLIER)
    local vendorPrice = select(11, C_Item.GetItemInfo(itemLink))
    if multiplier ~= 0 and vendorPrice ~= 0 then
      -- Check for a vendor price multiplier being set (and a vendor price)
      self:SetUnitPrice(
        vendorPrice * multiplier + self:GetDeposit()
      )
    end
  end)
end

function AuctionatorSaleItemMixin:HasCurrentReferencePrice()
  local parent = self:GetParent()
  local provider = parent and parent.BuyFrame and parent.BuyFrame.CurrentPrices and parent.BuyFrame.CurrentPrices.SearchDataProvider

  -- ViewSetup is emitted by the provider after the current query completes. If
  -- the provider is unexpectedly unavailable, do not guess and overwrite the
  -- current price.
  if not provider or type(provider.allAuctions) ~= "table" then
    return nil
  end

  for _, auction in ipairs(provider.allAuctions) do
    local unitPrice = Auctionator.Utilities.ToUnitPrice(auction) or 0
    if unitPrice > 0 then
      return true
    end
  end
  return false
end

function AuctionatorSaleItemMixin:GetNoReferenceFallbackUnitPrice()
  if not self.itemInfo or not self.itemInfo.itemLink then return nil end
  if not Auctionator.Config.Get(Auctionator.Config.Options.SELLING_AUTO_FALLBACK_PRICE) then return nil end

  local itemData = { C_Item.GetItemInfo(self.itemInfo.itemLink) }
  local vendorIndex = Auctionator.Constants.ITEM_INFO and Auctionator.Constants.ITEM_INFO.SELL_PRICE or 11
  local vendorPrice = tonumber(itemData[vendorIndex]) or tonumber(select(11, GetItemInfo(self.itemInfo.itemLink))) or 0
  if vendorPrice <= 0 then return nil end

  local profitPercent = tonumber(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_FALLBACK_VENDOR_PROFIT_PERCENT)) or 20
  profitPercent = math.max(0, profitPercent)

  -- Base formula requested for the backport:
  -- vendor price + configured vendor-profit percentage + deposit coverage.
  local unitPrice = vendorPrice + math.ceil(vendorPrice * profitPercent / 100)

  if Auctionator.Config.Get(Auctionator.Config.Options.SELLING_FALLBACK_COVER_DEPOSIT) then
    local stackSize = math.max(1, self:GetStackSize())
    local numStacks = math.max(1, self:GetNumStacks())
    local totalQuantity = math.max(1, stackSize * numStacks)
    local deposit = tonumber(self:GetDeposit()) or 0

    -- GetDeposit() is the deposit for the full posting. Spread it across the
    -- units being posted so the total fallback sale price covers that deposit
    -- exactly once, rather than adding the full deposit to every unit.
    unitPrice = unitPrice + math.ceil(deposit / totalQuantity)
  end

  return math.max(1, math.floor(unitPrice))
end

function AuctionatorSaleItemMixin:GetNoReferenceFallbackSignature()
  if not self.itemInfo then return nil end
  return table.concat({
    tostring(self.Duration:GetValue() or 0),
    tostring(self:GetStackSize() or 0),
    tostring(self:GetNumStacks() or 0),
  }, ":")
end

function AuctionatorSaleItemMixin:RefreshNoReferenceFallbackPrice()
  if not self.noReferenceFallbackActive or not self.itemInfo then return end

  -- If the user manually edited the automatically proposed price, stop
  -- managing it. From that point the user's value is authoritative.
  if self.lastFallbackUnitPrice and self.UnitPrice:GetAmount() ~= self.lastFallbackUnitPrice then
    self.noReferenceFallbackActive = false
    return
  end

  local signature = self:GetNoReferenceFallbackSignature()
  if signature ~= self.lastFallbackSignature then
    local fallback = self:GetNoReferenceFallbackUnitPrice()
    if fallback and fallback > 0 then
      self:SetUnitPrice(fallback)
      self.lastFallbackUnitPrice = fallback
      self.lastFallbackSignature = signature
    end
  end
end

function AuctionatorSaleItemMixin:ApplyNoReferenceFallbackPrice()
  if not self.itemInfo then return end

  local hasReference = self:HasCurrentReferencePrice()
  if hasReference == nil or hasReference then return end

  local fallback = self:GetNoReferenceFallbackUnitPrice()
  if fallback and fallback > 0 then
    self:SetUnitPrice(fallback)
    self.noReferenceFallbackActive = true
    self.lastFallbackUnitPrice = fallback
    self.lastFallbackSignature = self:GetNoReferenceFallbackSignature()
    self.priceCutThreshold = nil
  end
end

function AuctionatorSaleItemMixin:GetPostButtonState()
  return
    self.itemInfo ~= nil and
    self.itemInfo.count > 0 and
    self.clickedSellItem and
    self.buyViewSetup and

    C_Item.DoesItemExist(self.itemInfo.location) and

    self.StackPrice:GetAmount() <= MAXIMUM_BID_PRICE and

    -- Sufficient money to cover deposit
    GetMoney() >= self:GetDeposit() and

    -- Valid quantity
    self.Stacks.NumStacks:GetNumber() > 0 and
    self.Stacks.StackSize:GetNumber() > 0 and
    self.Stacks.StackSize:GetNumber() <= self.itemInfo.stackSize and
    self.Stacks.NumStacks:GetNumber() * self.Stacks.StackSize:GetNumber() <= self.itemInfo.count and

    -- Positive price
    (
      self.UnitPrice:GetAmount() > 0 or
      self.BidPrice:GetAmount() > 0
    ) and

    -- Have opted to ignore the throttle or searches on the client aren't throttled
    (not Auctionator.Config.Get(Auctionator.Config.Options.SELLING_GREY_POST_BUTTON) or Auctionator.AH.IsNotThrottled())
end

function AuctionatorSaleItemMixin:GetStackableWarningThreshold()
  -- Limit warning to stackable items only (like the retail warning on
  -- commodities)
  if self.itemInfo.stackSize <= 1 then
    return 0
  end

  -- Identifies when an auction is skewing the current price down and is
  -- probably not meant to be so low.
  local allAuctions = self:GetParent().BuyFrame.CurrentPrices.SearchDataProvider.allAuctions
  local midPoint = math.min(5, math.ceil(#allAuctions / 2))
  local watchPoint = allAuctions[midPoint]
  if watchPoint ~= nil then
    local watchPointPrice = Auctionator.Utilities.ToUnitPrice(watchPoint) or 0
    return Auctionator.Utilities.PriceWarningThreshold(watchPointPrice)
  end
  return 0
end

function AuctionatorSaleItemMixin:GetConfirmationMessage()
  local effectiveUnitPrice = self.UnitPrice:GetAmount()
  if Auctionator.Config.Get(Auctionator.Config.Options.SHOW_SELLING_BID_PRICE) and effectiveUnitPrice == 0 then
    effectiveUnitPrice = math.ceil(self.BidPrice:GetAmount() / self:GetStackSize())
  end
  -- Check if the price may have had the unit and stack price entered in the
  -- wrong box with the item being underpriced compared to the on sale items
  if self.priceCutThreshold ~= nil and effectiveUnitPrice < self.priceCutThreshold then
    return AUCTIONATOR_L_CONFIRM_POST_PRICE_DROP:format(GetMoneyString(self.UnitPrice:GetAmount(), true))
  end

  -- Determine if the item is worth more to sell to a vendor than to post on the
  -- AH.
  local itemInfo = { C_Item.GetItemInfo(self.itemInfo.itemLink) }
  local vendorPrice = itemInfo[Auctionator.Constants.ITEM_INFO.SELL_PRICE]
  if Auctionator.Utilities.IsVendorable(itemInfo) and
     vendorPrice * self:GetStackSize() * self:GetNumStacks()
       > math.floor(effectiveUnitPrice * self:GetStackSize() * self:GetNumStacks() * Auctionator.Constants.AfterAHCut) then
    return AUCTIONATOR_L_CONFIRM_POST_BELOW_VENDOR
  end

  -- Check if the item was underpriced compared to the currently on sale items
  if effectiveUnitPrice < self:GetStackableWarningThreshold() then
    return AUCTIONATOR_L_CONFIRM_POST_LOW_PRICE:format(GetMoneyString(self.UnitPrice:GetAmount(), true))
  end
end

function AuctionatorSaleItemMixin:RequiresConfirmationState()
  return
    Auctionator.Config.Get(Auctionator.Config.Options.SELLING_CONFIRM_LOW_PRICE) and
    self:GetConfirmationMessage() ~= nil
end

function AuctionatorSaleItemMixin:UpdatePostButtonState()
  self.PostButton:SetEnabled(self:GetPostButtonState())
end

function AuctionatorSaleItemMixin:UpdateSkipButtonState()
  self.SkipButton:SetEnabled(self.SkipButton:IsShown() and self.nextItem)
  self.PrevButton:SetEnabled(self.SkipButton:IsShown() and self.prevItem)
end

local AUCTION_DURATIONS = {
  [12] = 1,
  [24] = 2,
  [48] = 3,
}

function AuctionatorSaleItemMixin:GetDuration()
  return AUCTION_DURATIONS[self.Duration:GetValue()]
end

function AuctionatorSaleItemMixin:PostItem(confirmed)
  if not self:GetPostButtonState() then
    Auctionator.Debug.Message("Trying to post when we can't. Returning")
    return
  elseif not confirmed and self:RequiresConfirmationState() then
    if self.SkipButton:IsEnabled() then
      StaticPopupDialogs[Auctionator.Constants.DialogNames.SellingConfirmPostSkip].text = self:GetConfirmationMessage()
      StaticPopup_Show(Auctionator.Constants.DialogNames.SellingConfirmPostSkip)
    else
      StaticPopupDialogs[Auctionator.Constants.DialogNames.SellingConfirmPost].text = self:GetConfirmationMessage()
      StaticPopup_Show(Auctionator.Constants.DialogNames.SellingConfirmPost)
    end
    return
  end

  local numStacks = self.Stacks.NumStacks:GetNumber()
  local stackSize = self.Stacks.StackSize:GetNumber()
  local duration = self:GetDuration()
  local startingBid = self:GetBidAmount()
  local buyoutPrice = self.StackPrice:GetAmount()
  local deposit = self:GetDeposit()

  local stackSizeMemory = Auctionator.Config.Get(Auctionator.Config.Options.STACK_SIZE_MEMORY)
  local basicDBKey = Auctionator.Utilities.BasicDBKeyFromLink(self.itemInfo.itemLink)
  -- Only save stack size if its different to the global default
  if stackSize ~= self.normalStackSize then
    stackSizeMemory[basicDBKey] = stackSize
  else
    stackSizeMemory[basicDBKey] = nil
  end

  Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.PostAttempt, {
    numStacks = numStacks,
    stackSize = stackSize,
    duration = duration,
    unitPrice = self.UnitPrice:GetAmount(),
    startingBid = startingBid,
    buyoutPrice = buyoutPrice,
    deposit = deposit,
    itemInfo = self.itemInfo,
    minPriceSeen = self.minPriceSeen,
  })

  if StaticPopupDialogs["AUCTION_HOUSE_POST_WARNING"] then
    Auctionator.AH.PostAuction(startingBid, buyoutPrice, duration, stackSize, numStacks, true)
  else
    Auctionator.AH.PostAuction(startingBid, buyoutPrice, duration, stackSize, numStacks)
  end

  if Auctionator.Config.Get(Auctionator.Config.Options.SAVE_LAST_DURATION_AS_DEFAULT) then
    Auctionator.Config.Set(Auctionator.Config.Options.AUCTION_DURATION, self.Duration:GetValue())
  end

  self:Reset()
end

function AuctionatorSaleItemMixin:SuccessfulPost(details)
  --Print auction to chat
  if Auctionator.Config.Get(Auctionator.Config.Options.AUCTION_CHAT_LOG) then
    Auctionator.Utilities.Message(Auctionator.Selling.ComposeAuctionPostedMessage({
      itemLink = details.itemInfo.itemLink,
      numStacks = details.numStacksReached,
      stackSize = details.stackSize,
      stackBuyout = details.buyoutPrice,
    }))
  end

  Auctionator.EventBus:Fire(self,
    Auctionator.Selling.Events.AuctionCreated,
    {
      itemLink = details.itemInfo.itemLink,
      quantity = details.numStacksReached * details.stackSize,
      buyoutAmount = details.unitPrice,
      bidAmount = details.startingBid,
      deposit = details.deposit,
    }
  )

  -- If not seen in any queries before this, then this price is the first one
  -- listed. Update the database to include this price.
  if details.minPriceSeen == 0 or details.minPriceSeen > details.unitPrice then
    local minPrice = details.unitPrice
    Auctionator.Utilities.DBKeyFromLink(details.itemInfo.itemLink, function(dbKeys)
      for _, key in ipairs(dbKeys) do
        Auctionator.Database:SetPrice(key, minPrice)
      end
      Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.RefreshHistoryOnly, details.itemInfo)
    end)
  else
    Auctionator.EventBus:Fire(self, Auctionator.Selling.Events.RefreshHistoryOnly, details.itemInfo)
  end
end

function AuctionatorSaleItemMixin:DoNextItem(details)
  if Auctionator.Config.Get(Auctionator.Config.Options.SELLING_AUTO_SELECT_NEXT) and self.nextItem then
    -- Option to automatically select the next item in the bag view
    Auctionator.EventBus:Fire(
      self, Auctionator.Selling.Events.BagItemRequest, self.nextItem
    )
  end
end

function AuctionatorSaleItemMixin:ReselectItem(details)
  -- estimate count as the bag may not have updated to remove the posted items
  -- yet
  local count = details.itemInfo.count - details.stackSize * details.numStacksReached
  if count > 0 then
    local itemInfo = Auctionator.Groups.Utilities.QueryItem(details.itemInfo.sortKey)
    if itemInfo then
      Auctionator.Debug.Message("found again, trying")
      self:UnlockItem()
      self.retryingItem = true
      self.itemInfo = CopyTable(details.itemInfo, true)
      self.itemInfo.location = itemInfo.locations[1]
      self.itemInfo.count = count
      self.clickedSellItem = false
      self.minPriceSeen = details.minPriceSeen
      self:Update()
      self:SetUnitPrice(details.unitPrice)
      self.Stacks.NumStacks:SetNumber(math.max(1, details.numStacks - details.numStacksReached))
      return
    end
  end

  Auctionator.Debug.Message("item missing, won't retry")
  self:DoNextItem(details)
end

function AuctionatorSaleItemMixin:SkipItem()
  if self.SkipButton:IsEnabled() then
    Auctionator.EventBus:Fire(
      self, Auctionator.Selling.Events.BagItemRequest, self.nextItem
    )
  end
end

function AuctionatorSaleItemMixin:PrevItem()
  if self.PrevButton:IsEnabled() then
    Auctionator.EventBus:Fire(
      self, Auctionator.Selling.Events.BagItemRequest, self.prevItem
    )
  end
end
