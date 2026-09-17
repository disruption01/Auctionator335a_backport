AuctionatorCancellingFrameMixin = {}

function AuctionatorCancellingFrameMixin:OnLoad()
  Auctionator.Debug.Message("AuctionatorCancellingFrameMixin:OnLoad()")

  -- The modern FrameXML anchors used by the TBC client don't all survive on
  -- 3.3.5a.  Rebuild the Cancelling header/table/footer explicitly so the
  -- search and total sit above the table and both undercut buttons live in a
  -- dedicated footer, matching the Classic layout.
  if self.SearchFilter then
    self.SearchFilter:ClearAllPoints()
    self.SearchFilter:SetPoint("TOPLEFT", self, "TOPLEFT", 65, -46)
    self.SearchFilter:SetSize(250, 22)
  end

  if self.Total and self.SearchFilter then
    self.Total:ClearAllPoints()
    self.Total:SetPoint("LEFT", self.SearchFilter, "RIGHT", 15, 0)
    if self.Total.SetDrawLayer then
      self.Total:SetDrawLayer("OVERLAY", 7)
    end
  end

  if self.ResultsListing then
    self.ResultsListing:ClearAllPoints()
    self.ResultsListing:SetPoint("TOPLEFT", self, "TOPLEFT", 4, -79)
    self.ResultsListing:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -20, 32)
  end

  if self.HistoricalPriceInset and self.ResultsListing then
    self.HistoricalPriceInset:ClearAllPoints()
    self.HistoricalPriceInset:SetPoint("TOPLEFT", self.ResultsListing, "TOPLEFT", -5, -25)
    self.HistoricalPriceInset:SetPoint("BOTTOMRIGHT", self.ResultsListing, "BOTTOMRIGHT", 0, 2)
  end

  if self.UndercutScanContainer then
    local container = self.UndercutScanContainer
    container:ClearAllPoints()
    container:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -8, 3)
    container:SetSize(300, 24)
    if container.CancelNextButton then
      container.CancelNextButton:ClearAllPoints()
      container.CancelNextButton:SetPoint("RIGHT", container, "RIGHT", 0, 0)
      container.CancelNextButton:SetSize(130, 22)
    end
    if container.StartScanButton then
      container.StartScanButton:ClearAllPoints()
      if container.CancelNextButton then
        container.StartScanButton:SetPoint("RIGHT", container.CancelNextButton, "LEFT", -4, 0)
      else
        container.StartScanButton:SetPoint("RIGHT", container, "RIGHT", -134, 0)
      end
      container.StartScanButton:SetSize(126, 22)
    end
  end

  self.ResultsListing:Init(self.DataProvider)

  Auctionator.EventBus:Register(self, {
    Auctionator.Cancelling.Events.RequestCancel,
    Auctionator.Cancelling.Events.TotalUpdated,
  })

  self.SearchFilter:HookScript("OnTextChanged", function()
    self.DataProvider:NoQueryRefresh()
  end)

  -- Stock/private 3.3.5a can reject CancelAuction when it is invoked from a
  -- dynamically pooled result row (ADDON_ACTION_BLOCKED). Keep one real XML
  -- button owned by the tab and move it over the hovered row. It has no visual
  -- regions, so the UI still behaves like "click the row to cancel", while
  -- the protected call originates from a button created by FrameXML.
  Auctionator.Cancelling.frame = self
  if self.RowCancelButton then
    self.RowCancelButton:SetFrameStrata("HIGH")
    self.RowCancelButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    self.RowCancelButton:Hide()
  end

end

function AuctionatorCancellingFrameMixin:ShowRowCancelButton(row)
  local button = self.RowCancelButton
  if not button or not row or not row.rowData then
    return
  end

  button.auction = row.rowData
  button.attachedRow = row
  button:ClearAllPoints()
  button:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
  button:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
  if button.SetFrameLevel and row.GetFrameLevel then
    button:SetFrameLevel(row:GetFrameLevel() + 20)
  end
  button:Show()
end

function AuctionatorCancellingFrameMixin:ScheduleHideRowCancelButton()
  local button = self.RowCancelButton
  if not button then
    return
  end

  local function HideIfLeft()
    local buttonOver = button.IsMouseOver and button:IsMouseOver()
    local rowOver = button.attachedRow and button.attachedRow.IsMouseOver and button.attachedRow:IsMouseOver()
    if button:IsShown() and not buttonOver and not rowOver then
      button:Hide()
      button.auction = nil
      button.attachedRow = nil
      if GameTooltip and GameTooltip:IsOwned(button) then
        GameTooltip:Hide()
      end
    end
  end

  if C_Timer and C_Timer.After then
    C_Timer.After(0.08, HideIfLeft)
  else
    HideIfLeft()
  end
end

function AuctionatorCancellingFrameMixin:DetachRowCancelButton(row)
  local button = self.RowCancelButton
  if button and button.attachedRow == row then
    button:Hide()
    button.auction = nil
    button.attachedRow = nil
    if GameTooltip and GameTooltip:IsOwned(button) then
      GameTooltip:Hide()
    end
  end
end

function AuctionatorCancellingFrameMixin:OnRowCancelButtonEnter()
  local button = self.RowCancelButton
  local auctionData = button and button.auction
  if auctionData and auctionData.itemLink and GameTooltip then
    GameTooltip:SetOwner(button, "ANCHOR_CURSOR")
    GameTooltip:SetHyperlink(auctionData.itemLink)
    GameTooltip:Show()
  end
end

function AuctionatorCancellingFrameMixin:OnRowCancelButtonLeave()
  local button = self.RowCancelButton
  if GameTooltip and button and GameTooltip:IsOwned(button) then
    GameTooltip:Hide()
  end
  self:ScheduleHideRowCancelButton()
end

function AuctionatorCancellingFrameMixin:OnRowCancelButtonClick(mouseButton)
  local button = self.RowCancelButton
  local auctionData = button and button.auction
  if not auctionData then
    return
  end

  if IsModifiedClick("DRESSUP") then
    DressUpLink(auctionData.itemLink)
    return
  elseif IsModifiedClick("CHATLINK") then
    Auctionator.Utilities.InsertLink(auctionData.itemLink)
    return
  elseif mouseButton == "RightButton" then
    Auctionator.API.v1.MultiSearchExact(AUCTIONATOR_L_CANCELLING_TAB, {
      Auctionator.Utilities.GetNameFromLink(auctionData.itemLink)
    })
    return
  end

  if mouseButton == nil or mouseButton == "LeftButton" then
    self:CancelHoveredAuction()
  end
end

function AuctionatorCancellingFrameMixin:CancelHoveredAuction()
  local button = self.RowCancelButton
  local auctionData = button and button.auction
  if not auctionData or not Auctionator.AH.IsNotThrottled() then
    return
  end

  local cancelCost = math.floor(((auctionData.bidAmount or 0) * (AUCTION_CANCEL_COST or 0)) / 100)
  if cancelCost > 0 then
    local dialog = StaticPopup_Show("AuctionatorConfirmBidPricePopupDialog")
    if dialog then
      dialog.data = auctionData
      MoneyFrame_Update(dialog.moneyFrame, cancelCost)
    end
    return
  end

  local nativeCancelAuction = _G.CancelAuction
  if type(nativeCancelAuction) ~= "function" then
    return
  end

  local AII = Auctionator.Constants.AuctionItemInfo
  local wantCleanLink = Auctionator.Search.GetCleanItemLink(auctionData.itemLink)
  local wantCount = auctionData.numStacks or 1
  local cancelled = 0

  -- The row can represent several identical owner auctions. Cancel only the
  -- exact group represented by the row (item, quantity, prices and time band).
  -- On this client the owned list does not reshuffle until the server responds,
  -- so a single forward pass is safe inside this one hardware click.
  for index = 1, GetNumAuctionItems("owner") do
    if cancelled >= wantCount then
      break
    end

    local info = { GetAuctionItemInfo("owner", index) }
    local link = GetAuctionItemLink("owner", index)
    local timeLeft = GetAuctionItemTimeLeft("owner", index)
    local cleanLink = link and Auctionator.Search.GetCleanItemLink(link) or nil

    if info[AII.SaleStatus] ~= 1
        and (info[AII.BidAmount] or 0) == 0
        and (info[AII.Quantity] or 0) == (auctionData.stackSize or 0)
        and (info[AII.Buyout] or 0) == (auctionData.stackPrice or 0)
        and (info[AII.MinBid] or 0) == (auctionData.minBid or 0)
        and cleanLink == wantCleanLink
        and (timeLeft == nil or auctionData.timeLeft == nil or (timeLeft - 1) == auctionData.timeLeft) then
      nativeCancelAuction(index)
      cancelled = cancelled + 1
    end
  end

  if cancelled > 0 then
    auctionData.cancelled = true
    if button then
      button:Hide()
      button.auction = nil
      button.attachedRow = nil
    end
    if GameTooltip then
      GameTooltip:Hide()
    end

    Auctionator.EventBus
      :RegisterSource(self, "CancellingFrameRowCancel")
      :Fire(self, Auctionator.Cancelling.Events.CancelConfirmed, auctionData)
      :UnregisterSource(self)

    -- Do not start Auctionator's 10s throttle countdown for this path. The
    -- protected action has already been issued from the hardware click. Ask
    -- for the owner list shortly afterwards so the row disappears when the
    -- server has processed the cancellation.
    if GetOwnerAuctionItems then
      local function RefreshOwned()
        if not AuctionFrame or AuctionFrame:IsShown() then
          GetOwnerAuctionItems()
        end
      end
      if C_Timer and C_Timer.After then
        C_Timer.After(0.35, RefreshOwned)
        C_Timer.After(1.00, RefreshOwned)
      else
        RefreshOwned()
      end
    end
  end
end

function AuctionatorCancellingFrameMixin:OnShow()
  -- On stock 3.3.5a GetOwnerAuctionItems() is a server request. The upstream
  -- legacy client called it from OnUpdate, which means dozens of requests per
  -- second here and can starve/taint the actual CancelAuction request on some
  -- private-server cores. One refresh when the tab is shown is sufficient;
  -- subsequent changes arrive through AUCTION_OWNED_LIST_UPDATE.
  if GetOwnerAuctionItems then
    GetOwnerAuctionItems()
  end
end

local ConfirmBidPricePopup = "AuctionatorConfirmBidPricePopupDialog"

StaticPopupDialogs[ConfirmBidPricePopup] = {
  text = AUCTIONATOR_L_BID_EXISTING_ON_OWNED_AUCTION,
  button1 = ACCEPT,
  button2 = CANCEL,
  OnAccept = function(self)
    if Auctionator.AH.CancelAuction(self.data) then
      Auctionator.EventBus:RegisterSource(self, "CancellingFramePopupDialog")
        :Fire(self, Auctionator.Cancelling.Events.CancelConfirmed, self.data)
        :UnregisterSource(self)
    end
  end,
  hasMoneyFrame = 1,
  showAlert = 1,
  timeout = 0,
  exclusive = 1,
  hideOnEscape = 1
}

function AuctionatorCancellingFrameMixin:IsAuctionShown(auctionInfo)
  local searchString = self.SearchFilter:GetText()
  if searchString ~= "" then
    local exact = searchString:match("^\"(.*)\"$")
    local name = string.lower(Auctionator.Utilities.GetNameFromLink(auctionInfo.itemLink))
    if exact then
      return name == exact
    else
      return string.find(name, string.lower(searchString), 1, true)
    end
  else
    return true
  end
end

function AuctionatorCancellingFrameMixin:ReceiveEvent(eventName, ...)
  if eventName == Auctionator.Cancelling.Events.RequestCancel then
    local auctionData = ...
    Auctionator.Debug.Message("Executing cancel request", auctionData)

    -- Prevent cancelling auctions which someone has bid on
    local cancelCost = math.floor((auctionData.bidAmount * AUCTION_CANCEL_COST) / 100)
    if cancelCost > 0 then
      local dialog = StaticPopup_Show(ConfirmBidPricePopup)
      if dialog then
        dialog.data = auctionData
        MoneyFrame_Update(dialog.moneyFrame, cancelCost);
      end
    else
      if Auctionator.AH.CancelAuction(auctionData) then
        Auctionator.EventBus:RegisterSource(self, "CancellingFrame")
          :Fire(self, Auctionator.Cancelling.Events.CancelConfirmed, auctionData)
      end
    end

    PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)

  elseif eventName == Auctionator.Cancelling.Events.TotalUpdated then
    local totalOnSale, totalPending = ...

    local text = AUCTIONATOR_L_TOTAL_ON_SALE:format(
        GetMoneyString(totalOnSale, true)
      )
    if totalPending > 0 then
      text = text .. " " ..
      AUCTIONATOR_L_TOTAL_PENDING:format(
        GetMoneyString(totalPending, true)
      )
    end

    self.Total:SetText(text)
  end
end
