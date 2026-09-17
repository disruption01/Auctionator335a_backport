local function Auctionator335AnchorAllItems(frame, parent, x, y, width, height)
  if not frame then return end
  frame:SetParent(parent)
  frame:ClearAllPoints()
  frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
  if width then frame:SetWidth(width) end
  if height then frame:SetHeight(height) end
  frame:Show()
end

local function Auctionator335EnsureRadioLabel(group, radio, index)
  if not radio then return nil end

  if radio.RadioButton then
    radio.RadioButton:ClearAllPoints()
    radio.RadioButton:SetPoint("TOPLEFT", radio, "TOPLEFT", 18, -1)
    radio.RadioButton:Show()
    if radio.RadioButton.Label then
      -- The inherited FontString anchors are unreliable on 3.3.5a. Keep only
      -- the explicit compatibility label below to avoid duplicated/missing text.
      radio.RadioButton.Label:SetText("")
      radio.RadioButton.Label:Hide()
    end
  end

  if not radio.__auctionator335Label then
    radio.__auctionator335Label = group:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  end
  local label = radio.__auctionator335Label
  label:ClearAllPoints()
  label:SetPoint("TOPLEFT", group, "TOPLEFT", 48, -(25 + (index - 1) * 24))
  Auctionator335Config.WrapFontString(label, math.max(220, (group:GetWidth() or 400) - 58), 22)
  label:Show()
  return label
end

local function Auctionator335FixRadioGroup(group, labels, values, heading)
  if not group then return end

  if group.GroupHeading then
    group.GroupHeading:ClearAllPoints()
    group.GroupHeading:SetPoint("TOPLEFT", group, "TOPLEFT", 0, 0)
    group.GroupHeading:SetWidth(group:GetWidth() or 400)
    group.GroupHeading:SetHeight(20)
    group.GroupHeading.subHeadingText = heading
    if group.GroupHeading.HeadingText then
      group.GroupHeading.HeadingText:SetText(heading)
    end
  end

  local radios = {}
  for _, child in ipairs({ group:GetChildren() }) do
    if child ~= group.GroupHeading and (child.isAuctionatorRadio or child.RadioButton) then
      table.insert(radios, child)
    end
  end

  local ordered = {}
  local used = {}
  for _, radio in ipairs(radios) do
    local target
    for i, value in ipairs(values) do
      if not used[i] and radio.value == value then
        target = i
        break
      end
    end
    if not target then
      for i = 1, #values do
        if not used[i] then target = i; break end
      end
    end
    if target then
      used[target] = true
      ordered[target] = radio
    end
  end

  group.radioButtons = {}
  group.radioButtonGroupOnChangeEvent = group.radioButtonGroupOnChangeEvent or function() end
  for i = 1, #values do
    local radio = ordered[i]
    if radio then
      table.insert(group.radioButtons, radio)
      radio.isAuctionatorRadio = true
      radio.labelText = labels[i]
      radio.value = values[i]
      radio:ClearAllPoints()
      radio:SetPoint("TOPLEFT", group, "TOPLEFT", 0, -(22 + (i - 1) * 24))
      radio:SetWidth(group:GetWidth() or 400)
      radio:SetHeight(24)
      radio:Show()

      local label = Auctionator335EnsureRadioLabel(group, radio, i)
      if label then label:SetText(labels[i] or "") end

      local selectedRadio = radio
      radio.onSelectedCallback = function()
        group:RadioSelected(selectedRadio)
      end
    end
  end

  group:SetHeight(28 + #group.radioButtons * 24)
end

local function Auctionator335EnsureFallbackControls(self, content)
  if self.AutoFallbackPrice then return end

  self.AutoFallbackHeading = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  self.AutoFallbackHeading:SetText("No Reference Price")

  self.AutoFallbackPrice = CreateFrame("Frame", "Auctionator335AutoFallbackPrice", content, "AuctionatorConfigurationCheckbox")
  self.AutoFallbackPrice:SetText("Automatically define a price when no similar item is being sold as reference")

  self.FallbackProfitPercent = CreateFrame("Frame", "Auctionator335FallbackProfitPercent", content, "AuctionatorConfigurationNumericInput")
  self.FallbackProfitPercent.labelText = "Percentage of profit based off vendor price"
  if self.FallbackProfitPercent.InputBox and self.FallbackProfitPercent.InputBox.Label then
    self.FallbackProfitPercent.InputBox.Label:SetText(self.FallbackProfitPercent.labelText)
  end

  self.FallbackCoverDeposit = CreateFrame("Frame", "Auctionator335FallbackCoverDeposit", content, "AuctionatorConfigurationCheckbox")
  self.FallbackCoverDeposit:SetText("Cover deposit price")

  if self.AutoFallbackPrice.CheckBox then
    self.AutoFallbackPrice.CheckBox:SetScript("OnClick", function()
      if self.UpdateFallbackControlsEnabled then self:UpdateFallbackControlsEnabled() end
    end)
  end
end

local function Auctionator335LayoutSellingAllItems(self)
  if not self.TitleArea or not self.DurationGroup then return end

  Auctionator335Config.PrepareTitle(self, self.TitleArea)

  if not self.__auctionator335AllItemsContent then
    self.__auctionator335AllItemsContent = CreateFrame("Frame", nil, self)
  end
  local content = self.__auctionator335AllItemsContent
  local width = Auctionator335Config.GetContentWidth(self) - 8
  content:SetWidth(width)

  Auctionator335EnsureFallbackControls(self, content)

  -- A single scrollable column is intentional on 3.3.5a. Long labels get a
  -- real paragraph width rather than spilling past the Interface panel.
  local y = 0

  Auctionator335AnchorAllItems(self.DurationGroup, content, 0, y, width, 102)
  Auctionator335FixRadioGroup(
    self.DurationGroup,
    {AUCTIONATOR_L_AUCTION_DURATION_12 or "12 Hours", AUCTIONATOR_L_AUCTION_DURATION_24 or "24 Hours", AUCTIONATOR_L_AUCTION_DURATION_48 or "48 Hours"},
    {12, 24, 48},
    AUCTIONATOR_L_DEFAULT_AUCTION_DURATION or "Default Auction Duration"
  )
  y = y + 106

  Auctionator335AnchorAllItems(self.SaveLastDurationAsDefault, content, 0, y, width, 50)
  Auctionator335Config.FitCheckbox(self.SaveLastDurationAsDefault, width)
  y = y + 54

  Auctionator335AnchorAllItems(self.StackSizesHeading, content, 18, y, width - 18, 24)
  y = y + 30
  Auctionator335AnchorAllItems(self.DefaultStacks, content, 22, y, math.min(300, width - 22), 58)
  y = y + 66
  Auctionator335AnchorAllItems(self.ResetStackSizeMemory, content, 22, y, 205, 24)
  y = y + 42

  Auctionator335AnchorAllItems(self.SalesPreference, content, 0, y, width, 82)
  Auctionator335FixRadioGroup(
    self.SalesPreference,
    {AUCTIONATOR_L_PERCENTAGE or "Percentage", AUCTIONATOR_L_SET_VALUE or "Set Value"},
    {Auctionator.Config.SalesTypes.PERCENTAGE, Auctionator.Config.SalesTypes.STATIC},
    AUCTIONATOR_L_UNDERCUT_PREFERENCE or "Undercut Preference"
  )
  y = y + 86

  Auctionator335AnchorAllItems(self.UndercutPercentage, content, 12, y, width - 12, 44)
  Auctionator335Config.FitNumeric(self.UndercutPercentage, width - 12)
  Auctionator335AnchorAllItems(self.UndercutValue, content, 12, y, width - 12, 44)
  y = y + 52

  Auctionator335AnchorAllItems(self.GearPriceMultiplierHeading, content, 18, y, width - 18, 24)
  y = y + 30
  Auctionator335AnchorAllItems(self.GearPriceMultiplier, content, 12, y, width - 12, 44)
  Auctionator335Config.FitNumeric(self.GearPriceMultiplier, width - 12)
  y = y + 52

  Auctionator335AnchorAllItems(self.StartingPricePercentageHeading, content, 18, y, width - 18, 24)
  y = y + 30
  Auctionator335AnchorAllItems(self.StartingPricePercentage, content, 12, y, width - 12, 44)
  Auctionator335Config.FitNumeric(self.StartingPricePercentage, width - 12)
  y = y + 58

  -- 3.3.5a backport-only fallback when the current AH search has no usable
  -- reference auction. Child controls are intentionally indented as a cascade.
  self.AutoFallbackHeading:ClearAllPoints()
  self.AutoFallbackHeading:SetPoint("TOPLEFT", content, "TOPLEFT", 18, -y)
  self.AutoFallbackHeading:SetWidth(width - 18)
  self.AutoFallbackHeading:SetHeight(22)
  y = y + 28

  Auctionator335AnchorAllItems(self.AutoFallbackPrice, content, 0, y, width, 62)
  Auctionator335Config.FitCheckbox(self.AutoFallbackPrice, width)
  y = y + 66

  Auctionator335AnchorAllItems(self.FallbackProfitPercent, content, 28, y, width - 28, 54)
  Auctionator335Config.FitNumeric(self.FallbackProfitPercent, width - 28)
  y = y + 58

  Auctionator335AnchorAllItems(self.FallbackCoverDeposit, content, 28, y, width - 28, 46)
  Auctionator335Config.FitCheckbox(self.FallbackCoverDeposit, width - 28)
  y = y + 54

  Auctionator335AnchorAllItems(self.IgnoreItemSuffix, content, 0, y, width, 58)
  Auctionator335Config.FitCheckbox(self.IgnoreItemSuffix, width)
  y = y + 62

  Auctionator335Config.PrepareScroll(self, "__auctionator335AllItemsScroll", 64, y + 8, content)
end

AuctionatorConfigSellingAllItemsFrameMixin = CreateFromMixins(AuctionatorPanelConfigMixin)

function AuctionatorConfigSellingAllItemsFrameMixin:OnLoad()
  Auctionator.Debug.Message("AuctionatorConfigSellingAllItemsFrameMixin:OnLoad()")

  self.name = AUCTIONATOR_L_CONFIG_SELLING_ALL_ITEMS_CATEGORY
  self.parent = "Auctionator"
  self.beenShown = false

  Auctionator335LayoutSellingAllItems(self)
  self:SetupPanel()

  self.SalesPreference:SetOnChange(function(selectedValue)
    self:OnSalesPreferenceChange(selectedValue)
  end)
end

function AuctionatorConfigSellingAllItemsFrameMixin:UpdateFallbackControlsEnabled()
  if not self.AutoFallbackPrice then return end
  local enabled = self.AutoFallbackPrice:GetChecked() and true or false

  if self.FallbackProfitPercent then
    self.FallbackProfitPercent:SetAlpha(enabled and 1 or 0.45)
    if self.FallbackProfitPercent.InputBox then
      self.FallbackProfitPercent.InputBox:EnableMouse(enabled)
      if not enabled then self.FallbackProfitPercent.InputBox:ClearFocus() end
    end
  end

  if self.FallbackCoverDeposit then
    self.FallbackCoverDeposit:SetAlpha(enabled and 1 or 0.45)
    if self.FallbackCoverDeposit.CheckBox then
      if enabled then self.FallbackCoverDeposit.CheckBox:Enable() else self.FallbackCoverDeposit.CheckBox:Disable() end
    end
  end
end

function AuctionatorConfigSellingAllItemsFrameMixin:ShowSettings()
  Auctionator335LayoutSellingAllItems(self)
  self.beenShown = true
  self.currentUndercutPreference = Auctionator.Config.Get(Auctionator.Config.Options.AUCTION_SALES_PREFERENCE)

  self.DurationGroup:SetSelectedValue(Auctionator.Config.Get(Auctionator.Config.Options.AUCTION_DURATION))
  self.SaveLastDurationAsDefault:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.SAVE_LAST_DURATION_AS_DEFAULT))
  self.SalesPreference:SetSelectedValue(self.currentUndercutPreference)

  self:OnSalesPreferenceChange(self.currentUndercutPreference)

  self.UndercutPercentage:SetNumber(Auctionator.Config.Get(Auctionator.Config.Options.UNDERCUT_PERCENTAGE))
  self.UndercutValue:SetAmount(Auctionator.Config.Get(Auctionator.Config.Options.UNDERCUT_STATIC_VALUE))

  self.GearPriceMultiplier:SetNumber(Auctionator.Config.Get(Auctionator.Config.Options.GEAR_PRICE_MULTIPLIER))

  self.StartingPricePercentage:SetNumber(Auctionator.Config.Get(Auctionator.Config.Options.STARTING_PRICE_PERCENTAGE))

  local defaultStacks = Auctionator.Config.Get(Auctionator.Config.Options.DEFAULT_SELLING_STACKS)
  self.DefaultStacks.StackSize:SetNumber(defaultStacks.stackSize)
  self.DefaultStacks.NumStacks:SetNumber(defaultStacks.numStacks)
  self.DefaultStacks.StackSize:Show()
  self.DefaultStacks.NumStacks:Show()
  self.DefaultStacks:SetMaxStackSize(0)
  self.DefaultStacks:SetMaxNumStacks(0)

  self.ResetStackSizeMemory:SetEnabled(next(Auctionator.Config.Get(Auctionator.Config.Options.STACK_SIZE_MEMORY)) ~= nil)

  self.AutoFallbackPrice:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_AUTO_FALLBACK_PRICE))
  self.FallbackProfitPercent:SetNumber(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_FALLBACK_VENDOR_PROFIT_PERCENT))
  self.FallbackCoverDeposit:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_FALLBACK_COVER_DEPOSIT))
  self:UpdateFallbackControlsEnabled()

  self.IgnoreItemSuffix:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_IGNORE_ITEM_SUFFIX))
end

function AuctionatorConfigSellingAllItemsFrameMixin:OnSalesPreferenceChange(selectedValue)
  self.currentUndercutPreference = selectedValue

  if self.currentUndercutPreference == Auctionator.Config.SalesTypes.PERCENTAGE then
    self.UndercutPercentage:Show()
    self.UndercutValue:Hide()
  else
    self.UndercutValue:Show()
    self.UndercutPercentage:Hide()
  end
end

function AuctionatorConfigSellingAllItemsFrameMixin:Save()
  if not self.beenShown then
    return
  end

  Auctionator.Debug.Message("AuctionatorConfigSellingAllItemsFrameMixin:Save()")

  Auctionator.Config.Set(Auctionator.Config.Options.AUCTION_DURATION, self.DurationGroup:GetValue())
  Auctionator.Config.Set(Auctionator.Config.Options.SAVE_LAST_DURATION_AS_DEFAULT, self.SaveLastDurationAsDefault:GetChecked())

  Auctionator.Config.Set(Auctionator.Config.Options.AUCTION_SALES_PREFERENCE, self.SalesPreference:GetValue())
  Auctionator.Config.Set(
    Auctionator.Config.Options.UNDERCUT_PERCENTAGE,
    Auctionator.Utilities.ValidatePercentage(self.UndercutPercentage:GetNumber())
  )
  Auctionator.Config.Set(Auctionator.Config.Options.UNDERCUT_STATIC_VALUE, self.UndercutValue:GetAmount())

  Auctionator.Config.Set(Auctionator.Config.Options.GEAR_PRICE_MULTIPLIER, self.GearPriceMultiplier:GetNumber())

  local newPercentage = Auctionator.Utilities.ValidatePercentage(self.StartingPricePercentage:GetNumber())
  if newPercentage > 0 then
    Auctionator.Config.Set(
      Auctionator.Config.Options.STARTING_PRICE_PERCENTAGE,
      newPercentage
    )
  end

  local defaultStacks = {
    stackSize = self.DefaultStacks.StackSize:GetNumber(),
    numStacks = self.DefaultStacks.NumStacks:GetNumber()
  }
  Auctionator.Config.Set(Auctionator.Config.Options.DEFAULT_SELLING_STACKS, defaultStacks)

  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_AUTO_FALLBACK_PRICE, self.AutoFallbackPrice:GetChecked())
  Auctionator.Config.Set(
    Auctionator.Config.Options.SELLING_FALLBACK_VENDOR_PROFIT_PERCENT,
    math.max(0, self.FallbackProfitPercent:GetNumber())
  )
  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_FALLBACK_COVER_DEPOSIT, self.FallbackCoverDeposit:GetChecked())

  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_IGNORE_ITEM_SUFFIX, self.IgnoreItemSuffix:GetChecked())
end

function AuctionatorConfigSellingAllItemsFrameMixin:ResetStackSizeMemoryClicked()
  Auctionator.Config.Set(Auctionator.Config.Options.STACK_SIZE_MEMORY, {})
  self.ResetStackSizeMemory:Disable()
end

function AuctionatorConfigSellingAllItemsFrameMixin:Cancel()
  Auctionator.Debug.Message("AuctionatorConfigSellingAllItemsFrameMixin:Cancel()")
end
