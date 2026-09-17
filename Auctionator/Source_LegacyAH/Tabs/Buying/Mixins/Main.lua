AuctionatorBuyFrameMixin = {}

function AuctionatorBuyFrameMixin:Init()
  Auctionator.EventBus:RegisterSource(self, "AuctionatorBuyFrameMixin")
  self.CurrentPrices:Init()
  self.HistoryPrices:Init()
end

function AuctionatorBuyFrameMixin:Reset()
  if self.HistoryPrices:IsShown() then
    self:ToggleHistory()
  end

  self.HistoryPrices:Reset()
  self.CurrentPrices:Reset()
end

function AuctionatorBuyFrameMixin:ToggleHistory()
  self.HistoryPrices:SetShown(not self.HistoryPrices:IsShown())
  self.CurrentPrices:SetShown(not self.CurrentPrices:IsShown())

  if self.HistoryPrices:IsShown() then
    self.HistoryButton:SetText(AUCTIONATOR_L_CURRENT)
  else
    self.HistoryButton:SetText(AUCTIONATOR_L_HISTORY)
  end
end

AuctionatorBuyFrameMixinForShopping = CreateFromMixins(AuctionatorBuyFrameMixin)

function AuctionatorBuyFrameMixinForShopping:Init()
  AuctionatorBuyFrameMixin.Init(self)

  -- 3.3.5a does not resolve the authored $parentSearchResultsListing anchor
  -- from the BuyFrame to the nested CurrentPrices listing. The History button
  -- therefore floated in the middle of the table, and the table itself used
  -- the whole frame height so the footer controls overlaid the last rows.
  -- Rebuild the TBC-style layout explicitly: table above, action row below.
  local prices = self.CurrentPrices
  if prices and prices.SearchResultsListing then
    local listing = prices.SearchResultsListing

    -- The authored $parentSearchResultsListing anchor for ReturnButton cannot
    -- resolve through the nested CurrentPrices frame on 3.3.5a. Recreate the
    -- TBC Classic header explicitly: Back button immediately to the left of the
    -- selected item's icon/name, both sitting above the price table.
    if self.ReturnButton then
      self.ReturnButton:ClearAllPoints()
      self.ReturnButton:SetPoint("BOTTOMLEFT", listing, "TOPLEFT", 0, 10)
      self.ReturnButton:SetWidth(62)
      self.ReturnButton:SetHeight(22)
      self.ReturnButton:SetText(BACK or "Back")
      self.ReturnButton:Show()
    end
    if self.ItemTooltip then
      self.ItemTooltip:ClearAllPoints()
      if self.ReturnButton then
        self.ItemTooltip:SetPoint("BOTTOMLEFT", self.ReturnButton, "BOTTOMRIGHT", 6, -9)
      else
        self.ItemTooltip:SetPoint("BOTTOMLEFT", listing, "TOPLEFT", 68, 1)
      end
      self.ItemTooltip:SetPoint("RIGHT", self, "RIGHT", -8, 0)
      self.ItemTooltip:SetHeight(50)
    end
    listing:ClearAllPoints()
    listing:SetPoint("TOPLEFT", prices, "TOPLEFT", 0, 0)
    listing:SetPoint("BOTTOMRIGHT", prices, "BOTTOMRIGHT", -20, 34)

    if prices.Inset then
      prices.Inset:ClearAllPoints()
      prices.Inset:SetPoint("TOPLEFT", listing, "TOPLEFT", -10, -25)
      prices.Inset:SetPoint("BOTTOMRIGHT", listing, "BOTTOMRIGHT", 0, 2)
    end

    if self.HistoryButton then
      self.HistoryButton:ClearAllPoints()
      self.HistoryButton:SetPoint("BOTTOMLEFT", prices, "BOTTOMLEFT", 0, 0)
    end
    if prices.CancelButton then
      prices.CancelButton:ClearAllPoints()
      prices.CancelButton:SetPoint("BOTTOMRIGHT", prices, "BOTTOMRIGHT", -8, 0)
      -- Prevent the 3.3.5 button font from clipping "Cancel Auction".
      prices.CancelButton:SetWidth(118)
    end
    if prices.BuyButton and prices.CancelButton then
      prices.BuyButton:ClearAllPoints()
      prices.BuyButton:SetPoint("BOTTOMRIGHT", prices.CancelButton, "BOTTOMLEFT", 0, 0)
    end
    if prices.RefreshButton and prices.BuyButton then
      prices.RefreshButton:ClearAllPoints()
      prices.RefreshButton:SetPoint("BOTTOMRIGHT", prices.BuyButton, "BOTTOMLEFT", 0, 0)
    end
  end

  Auctionator.EventBus:Register(self, {
    Auctionator.Buying.Events.ShowForShopping,
    Auctionator.Shopping.Tab.Events.SearchStart,
  })
end

function AuctionatorBuyFrameMixinForShopping:OnShow()
  self:GetParent().ResultsListing:Hide()
  self:GetParent().ExportCSV:Hide()
  self:GetParent().ShoppingResultsInset:Hide()
  self.wasParentLoadAllPagesVisible = self:GetParent().LoadAllPagesButton:IsShown()
  self:GetParent().LoadAllPagesButton:Hide()
end

function AuctionatorBuyFrameMixinForShopping:OnHide()
  self:Hide()

  self:GetParent().ResultsListing:Show()
  self:GetParent().ExportCSV:Show()
  self:GetParent().ShoppingResultsInset:Show()
  self:GetParent().LoadAllPagesButton:SetShown(self.wasParentLoadAllPagesVisible)
end

function AuctionatorBuyFrameMixinForShopping:ReceiveEvent(eventName, eventData, ...)
  if eventName == Auctionator.Buying.Events.ShowForShopping then
    self:Show()

    self:Reset()

    if #eventData.entries > 0 then
      self.CurrentPrices.SearchDataProvider:SetQuery(eventData.entries[1].itemLink, function() 
        self.HistoryPrices.RealmHistoryDataProvider:SetItemLink(eventData.entries[1].itemLink)
        self.HistoryPrices.PostingHistoryDataProvider:SetItemLink(eventData.entries[1].itemLink)
      end)
    else
      self.CurrentPrices.SearchDataProvider:SetQuery(nil, function() end)
      self.HistoryPrices.RealmHistoryDataProvider:SetItemLink(nil)
      self.HistoryPrices.PostingHistoryDataProvider:SetItemLink(nil)
    end
    self.CurrentPrices.SearchDataProvider:SetAuctions(eventData.entries)

    self.CurrentPrices.SearchDataProvider:SetRequestAllResults(false)
    if not eventData.complete and #eventData.entries < Auctionator.Constants.MaxResultsPerPage then
      self.CurrentPrices.SearchDataProvider:RefreshQuery()
    else
      self.CurrentPrices.gotCompleteResults = eventData.complete
      self.CurrentPrices:UpdateButtons()
    end
  elseif eventName == Auctionator.Shopping.Tab.Events.SearchStart then
    self:Hide()
  end
end

AuctionatorBuyFrameMixinForSelling = CreateFromMixins(AuctionatorBuyFrameMixin)
local AUCTION_EVENTS = {
  "AUCTION_OWNED_LIST_UPDATE",
}

function AuctionatorBuyFrameMixinForSelling:Init()
  AuctionatorBuyFrameMixin.Init(self)

  -- The Selling tab uses the same price table as Shopping, but its inherited
  -- $parent anchors also get lost on 3.3.5a. Reserve a real footer and keep
  -- History / Refresh / Buy / Cancel Auction out of the result rows.
  local prices = self.CurrentPrices
  if prices and prices.SearchResultsListing then
    local listing = prices.SearchResultsListing
    listing:ClearAllPoints()
    listing:SetPoint("TOPLEFT", prices, "TOPLEFT", 0, 0)
    listing:SetPoint("BOTTOMRIGHT", prices, "BOTTOMRIGHT", -20, 34)

    if prices.Inset then
      prices.Inset:ClearAllPoints()
      prices.Inset:SetPoint("TOPLEFT", listing, "TOPLEFT", -10, -25)
      prices.Inset:SetPoint("BOTTOMRIGHT", listing, "BOTTOMRIGHT", 0, 2)
    end
    if self.HistoryButton then
      self.HistoryButton:ClearAllPoints()
      self.HistoryButton:SetPoint("BOTTOMLEFT", prices, "BOTTOMLEFT", 0, 0)
    end
    if prices.CancelButton then
      prices.CancelButton:ClearAllPoints()
      prices.CancelButton:SetPoint("BOTTOMRIGHT", prices, "BOTTOMRIGHT", -8, 0)
      prices.CancelButton:SetWidth(118)
    end
    if prices.BuyButton and prices.CancelButton then
      prices.BuyButton:ClearAllPoints()
      prices.BuyButton:SetPoint("BOTTOMRIGHT", prices.CancelButton, "BOTTOMLEFT", 0, 0)
    end
    if prices.RefreshButton and prices.BuyButton then
      prices.RefreshButton:ClearAllPoints()
      prices.RefreshButton:SetPoint("BOTTOMRIGHT", prices.BuyButton, "BOTTOMLEFT", 0, 0)
    end
  end

  Auctionator.EventBus:Register(self, {
    Auctionator.Selling.Events.RefreshBuying,
    Auctionator.Selling.Events.RefreshHistoryOnly,
    Auctionator.Selling.Events.StartFakeBuyLoading,
    Auctionator.Selling.Events.StopFakeBuyLoading,
    Auctionator.Selling.Events.AuctionCreated,
  })
end

function AuctionatorBuyFrameMixinForSelling:Reset()
  AuctionatorBuyFrameMixin.Reset(self)

  self.CurrentPrices.SearchDataProvider:SetIgnoreItemSuffix(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_IGNORE_ITEM_SUFFIX))
  self.waitingOnNewAuction = false
end

function AuctionatorBuyFrameMixinForSelling:OnShow()
  FrameUtil.RegisterFrameForEvents(self, AUCTION_EVENTS)
  self:Reset()
end

function AuctionatorBuyFrameMixinForSelling:OnHide()
  FrameUtil.UnregisterFrameForEvents(self, AUCTION_EVENTS)
end

function AuctionatorBuyFrameMixinForSelling:ReceiveEvent(eventName, eventData, ...)
  if eventName == Auctionator.Selling.Events.RefreshBuying then
    self:Reset()

    self.HistoryPrices.RealmHistoryDataProvider:SetItemLink(eventData.itemLink)
    self.HistoryPrices.PostingHistoryDataProvider:SetItemLink(eventData.itemLink)
    self.CurrentPrices.SearchDataProvider:SetQuery(eventData.itemLink, function()
      self.CurrentPrices.SearchDataProvider:SetRequestAllResults(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_ALWAYS_LOAD_MORE))
      self.CurrentPrices.SearchDataProvider:RefreshQuery()
    end)

    self.CurrentPrices.RefreshButton:Enable()
    self.HistoryButton:Enable()
  elseif eventName == Auctionator.Selling.Events.RefreshHistoryOnly then
    self.HistoryPrices.RealmHistoryDataProvider:SetItemLink(eventData.itemLink)
    self.HistoryPrices.PostingHistoryDataProvider:SetItemLink(eventData.itemLink)
  elseif eventName == Auctionator.Selling.Events.StartFakeBuyLoading then
    -- Used so that it is clear something is loading, even if the search can't
    -- be sent yet.
    self.HistoryPrices.RealmHistoryDataProvider:SetItemLink(eventData.itemLink)
    self.HistoryPrices.PostingHistoryDataProvider:SetItemLink(eventData.itemLink)
    self.CurrentPrices.SearchDataProvider:SetQuery(eventData.itemLink, function() end)
    self.CurrentPrices.SearchDataProvider.onSearchStarted()
  elseif eventName == Auctionator.Selling.Events.StopFakeBuyLoading then
    self.CurrentPrices.SearchDataProvider.onSearchEnded()
    self:Reset()
    self.CurrentPrices.RefreshButton:Disable()
    self.HistoryButton:Disable()
  elseif eventName == Auctionator.Selling.Events.AuctionCreated then
    self.waitingOnNewAuction = true
  end
end

function AuctionatorBuyFrameMixinForSelling:OnEvent(eventName, ...)
  if eventName == "AUCTION_OWNED_LIST_UPDATE" and self.waitingOnNewAuction then
    self.waitingOnNewAuction = false
    self.CurrentPrices.SearchDataProvider:PurgeAndReplaceOwnedAuctions(Auctionator.AH.DumpAuctions("owner"))
  end
end
