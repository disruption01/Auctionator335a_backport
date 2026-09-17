AuctionatorShoppingItemMixin = CreateFromMixins(AuctionatorEscapeToCloseMixin)

local NO_QUALITY = ""

local function InitializeQualityDropDown(dropDown)
  local qualityStrings = {}
  local qualityIDs = {}

  table.insert(qualityStrings, AUCTIONATOR_L_ANY_UPPER)
  table.insert(qualityIDs, NO_QUALITY)

  for _, quality in ipairs(Auctionator.Constants.QualityIDs) do
    table.insert(qualityStrings, Auctionator.Utilities.CreateColoredQuality(quality))
    table.insert(qualityIDs, tostring(quality))
  end

  dropDown:InitAgain(qualityStrings, qualityIDs)
end

local function InitializeTierDropDown(dropDown)
  local tierStrings = {}
  local tierIDs = {}

  table.insert(tierStrings, AUCTIONATOR_L_ANY_UPPER)
  table.insert(tierIDs, NO_QUALITY)

  if Auctionator.Constants.IsRetail then
    for tier = 1, 2 do
      table.insert(tierStrings, CreateAtlasMarkup("Professions-ChatIcon-Quality-12-Tier" .. tier) .. "/" .. CreateAtlasMarkup("Professions-Icon-Quality-Tier" .. tier .. "-Small", 17, 17))
      table.insert(tierIDs, tostring(tier))
    end
    do
      table.insert(tierStrings, CreateAtlasMarkup("Professions-Icon-Quality-Tier" .. 3 .. "-Small", 17, 17))
      table.insert(tierIDs, tostring(3))
    end
  end

  dropDown:InitAgain(tierStrings, tierIDs)
end

local function InitializeExpansionDropDown(dropDown)
  local expansionStrings = {}
  local expansionIDs = {}

  table.insert(expansionStrings, AUCTIONATOR_L_ANY_UPPER)
  table.insert(expansionIDs, NO_QUALITY)

  for i = 0, LE_EXPANSION_LEVEL_CURRENT do
    local name = _G["EXPANSION_NAME" .. i]

    table.insert(expansionStrings, name)
    table.insert(expansionIDs, tostring(i))
  end

  dropDown:InitAgain(expansionStrings, expansionIDs)
end

function AuctionatorShoppingItemMixin:OnLoad()
  -- 3.3.5a does not inherit the modern ButtonFrameTemplate backdrop. Give the
  -- Extended Search Options dialog a real classic dialog background/border so
  -- it behaves visually like the TBC Classic version instead of floating over
  -- the Shopping tab.
  if self.SetBackdrop then
    self:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    self:SetBackdropColor(1, 1, 1, 1)
    self:SetBackdropBorderColor(1, 1, 1, 1)
  end
  -- 3.3.5a XML does not chain inherited <OnLoad> scripts. The derived
  -- AuctionatorShoppingItemTemplate therefore misses ButtonFrameMixin and
  -- the parentKey-style fields supplied by modern ButtonFrameTemplate.
  if not self.SetTitle and ButtonFrameMixin then Mixin(self, ButtonFrameMixin) end
  if not self.TitleText and self.GetName then
    local name = self:GetName()
    if name then self.TitleText = _G[name .. 'TitleText'] end
  end
  if not self.CloseButton and self.GetName then
    local name = self:GetName()
    if name then self.CloseButton = _G[name .. 'CloseButton'] end
  end
  if ButtonFrameTemplate_HidePortrait then ButtonFrameTemplate_HidePortrait(self) end

  -- Retail ButtonFrameTemplate provides .Inset. Our 3.3.5a template is much
  -- smaller, so make the region explicitly when the old XML engine doesn't.
  if not self.Inset then
    self.Inset = CreateFrame("Frame", nil, self, "InsetFrameTemplate4")
  end
  self.Inset:ClearAllPoints()
  self.Inset:SetPoint("TOPLEFT", self, "TOPLEFT", 4, -25)
  self.Inset:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 30)

  self.onFinishedClicked = function() end

  self.SearchContainer.ResetSearchStringButton:SetClickCallback(function()
    self.SearchContainer.SearchString:SetText("")
  end)

  self.QualityContainer.ResetQualityButton:SetClickCallback(function()
    self.QualityContainer.DropDown:SetValue(NO_QUALITY)
  end)

  self.TierContainer.ResetTierButton:SetClickCallback(function()
    self.TierContainer.DropDown:SetValue(NO_QUALITY)
  end)

  self.ExpansionContainer.ResetExpansionButton:SetClickCallback(function()
    self.ExpansionContainer.DropDown:SetValue(NO_QUALITY)
  end)

  local onEnterCallback = function()
    self:OnFinishedClicked()
  end

  self.LevelRange:SetCallbacks({
    OnEnter = onEnterCallback,
    OnTab = function()
      self.ItemLevelRange:SetFocus()
    end
  })

  self.ItemLevelRange:SetCallbacks({
    OnEnter = onEnterCallback,
    OnTab = function()
      self.PriceRange:SetFocus()
    end
  })

  self.PriceRange:SetCallbacks({
    OnEnter = onEnterCallback,
    OnTab = function()
      self.CraftedLevelRange:SetFocus()
    end
  })

  self.CraftedLevelRange:SetCallbacks({
    OnEnter = onEnterCallback,
    OnTab = function()
      self.SearchContainer.SearchString:SetFocus()
    end
  })

  InitializeExpansionDropDown(self.ExpansionContainer.DropDown)
  InitializeQualityDropDown(self.QualityContainer.DropDown)
  InitializeTierDropDown(self.TierContainer.DropDown)

  if Auctionator.Constants.IsRetail then
    self:SetHeight(470)
    self.TierContainer:Show()
    self.ExpansionContainer:Show()
  else
    self:SetHeight(414)
    self.TierContainer:Hide()
    self.ExpansionContainer:Hide()
  end

  Auctionator.EventBus:Register(self, {
    Auctionator.Shopping.Tab.Events.ListSearchStarted,
    Auctionator.Shopping.Tab.Events.ListSearchEnded
  })
end

function AuctionatorShoppingItemMixin:Init(title, finishedButtonText)
  if self.SetTitle then
    self:SetTitle(title)
  elseif self.TitleText and self.TitleText.SetText then
    self.TitleText:SetText(title)
  end
  self.Finished:SetText(finishedButtonText)
  if DynamicResizeButton_Resize then DynamicResizeButton_Resize(self.Finished) end
end

function AuctionatorShoppingItemMixin:OnShow()
  self:ResetAll()
  -- 3.3.5a: do not force keyboard focus just by showing this dialog.
  if self.SearchContainer and self.SearchContainer.SearchString and self.SearchContainer.SearchString.ClearFocus then
    self.SearchContainer.SearchString:ClearFocus()
  end

  Auctionator.EventBus
    :RegisterSource(self, "add item dialog")
    :Fire(self, Auctionator.Shopping.Tab.Events.DialogOpened)
    :UnregisterSource(self)
end

function AuctionatorShoppingItemMixin:OnHide()
  self:Hide()

  Auctionator.EventBus
    :RegisterSource(self, "add item dialog")
    :Fire(self, Auctionator.Shopping.Tab.Events.DialogClosed)
    :UnregisterSource(self)
end

function AuctionatorShoppingItemMixin:OnCancelClicked()
  self:Hide()
end

function AuctionatorShoppingItemMixin:SetOnFinishedClicked(callback)
  self.onFinishedClicked = callback
end

function AuctionatorShoppingItemMixin:OnFinishedClicked()
  if not self.Finished:IsEnabled() then
    return
  end

  self:Hide()

  if self:HasItemInfo() then
    self.onFinishedClicked(self:GetItemString())
  else
    Auctionator.Utilities.Message(AUCTIONATOR_L_NO_ITEM_INFO_SPECIFIED)
  end
end

function AuctionatorShoppingItemMixin:HasItemInfo()
  return
    self:GetItemString()
      :gsub(Auctionator.Constants.AdvancedSearchDivider, "")
      :gsub("\"", "")
      :len() > 0
end

function AuctionatorShoppingItemMixin:GetItemString()
  local search = {
    searchString = self.SearchContainer.SearchString:GetText(),
    isExact = self.SearchContainer.IsExact:GetChecked(),
    categoryKey = self.FilterKeySelector:GetValue(),
    minLevel = self.LevelRange:GetMin(),
    maxLevel = self.LevelRange:GetMax(),
    minItemLevel = self.ItemLevelRange:GetMin(),
    maxItemLevel = self.ItemLevelRange:GetMax(),
    minCraftedLevel = self.CraftedLevelRange:GetMin(),
    maxCraftedLevel = self.CraftedLevelRange:GetMax(),
    minPrice = self.PriceRange:GetMin() * 10000,
    maxPrice = self.PriceRange:GetMax() * 10000,
    expansion = tonumber(self.ExpansionContainer.DropDown:GetValue()),
    quality = tonumber(self.QualityContainer.DropDown:GetValue()),
    tier = tonumber(self.TierContainer.DropDown:GetValue()),
    quantity = tonumber(self.PurchaseQuantity:GetNumber()),
  }
  
  return Auctionator.Search.ReconstituteAdvancedSearch(search)
end

function AuctionatorShoppingItemMixin:SetItemString(itemString)
  local search = Auctionator.Search.SplitAdvancedSearch(itemString)

  self.SearchContainer.IsExact:SetChecked(search.isExact)
  self.SearchContainer.SearchString:SetText(search.searchString)

  self.FilterKeySelector:SetValue(search.categoryKey)

  self.ItemLevelRange:SetMin(search.minItemLevel)
  self.ItemLevelRange:SetMax(search.maxItemLevel)

  self.LevelRange:SetMin(search.minLevel)
  self.LevelRange:SetMax(search.maxLevel)

  self.CraftedLevelRange:SetMin(search.minCraftedLevel)
  self.CraftedLevelRange:SetMax(search.maxCraftedLevel)

  if search.minPrice ~= nil then
    self.PriceRange:SetMin(search.minPrice/10000)
  else
    self.PriceRange:SetMin(nil)
  end

  if search.maxPrice ~= nil then
    self.PriceRange:SetMax(search.maxPrice/10000)
  else
    self.PriceRange:SetMax(nil)
  end

  if search.quantity == nil then
    self.PurchaseQuantity:SetNumber(0)
  else
    self.PurchaseQuantity:SetNumber(search.quantity)
  end

  if search.quality == nil then
    self.QualityContainer.DropDown:SetValue(NO_QUALITY)
  else
    self.QualityContainer.DropDown:SetValue(tostring(search.quality))
  end

  if not Auctionator.Constants.IsRetail or search.tier == nil then
    self.TierContainer.DropDown:SetValue(NO_QUALITY)
  else
    self.TierContainer.DropDown:SetValue(tostring(search.tier))
  end

  if not Auctionator.Constants.IsRetail or search.expansion == nil then
    self.ExpansionContainer.DropDown:SetValue(NO_QUALITY)
  else
    self.ExpansionContainer.DropDown:SetValue(tostring(search.expansion))
  end
end

function AuctionatorShoppingItemMixin:ResetAll()
  Auctionator.Debug.Message("AuctionatorShoppingItemMixin:ResetAll()")

  self.SearchContainer.SearchString:SetText("")
  self.SearchContainer.IsExact:SetChecked(false)

  self.FilterKeySelector:Reset()

  self.ItemLevelRange:Reset()
  self.LevelRange:Reset()
  self.PriceRange:Reset()
  self.CraftedLevelRange:Reset()
  -- 3.3.5a backport: Reset All should also clear the purchase quantity,
  -- matching the TBC Classic dialog.
  if self.PurchaseQuantity then
    self.PurchaseQuantity:SetNumber(0)
  end
  self.QualityContainer.DropDown:SetValue(NO_QUALITY)
end

function AuctionatorShoppingItemMixin:ReceiveEvent(eventName)
  if eventName == Auctionator.Shopping.Tab.Events.ListSearchStarted then
    self.Finished:Disable()
  elseif eventName == Auctionator.Shopping.Tab.Events.ListSearchEnded then
    self.Finished:Enable()
  end
end
