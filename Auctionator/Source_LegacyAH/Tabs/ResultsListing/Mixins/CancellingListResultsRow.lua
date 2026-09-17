AuctionatorCancellingListResultsRowMixin = CreateFromMixins(AuctionatorResultsRowTemplateMixin)

function AuctionatorCancellingListResultsRowMixin:OnClick(button, ...)
  -- Normal clicks are intercepted by the transparent XML RowCancelButton that
  -- is moved over the hovered pooled row. Keep this handler for modified-click
  -- fallbacks if the overlay is temporarily not attached.
  if IsModifiedClick("DRESSUP") then
    DressUpLink(self.rowData.itemLink)
  elseif IsModifiedClick("CHATLINK") then
    Auctionator.Utilities.InsertLink(self.rowData.itemLink)
  elseif button == "RightButton" then
    Auctionator.API.v1.MultiSearchExact(AUCTIONATOR_L_CANCELLING_TAB, {
      Auctionator.Utilities.GetNameFromLink(self.rowData.itemLink)
    })
  end
end

function AuctionatorCancellingListResultsRowMixin:OnEnter()
  AuctionatorResultsRowTemplateMixin.OnEnter(self)
  if Auctionator.Cancelling.frame then
    Auctionator.Cancelling.frame:ShowRowCancelButton(self)
  end
end

function AuctionatorCancellingListResultsRowMixin:OnLeave()
  AuctionatorResultsRowTemplateMixin.OnLeave(self)
  if Auctionator.Cancelling.frame then
    Auctionator.Cancelling.frame:ScheduleHideRowCancelButton()
  end
end

function AuctionatorCancellingListResultsRowMixin:Populate(rowData, dataIndex)
  AuctionatorResultsRowTemplateMixin.Populate(self, rowData, dataIndex)

  -- Rows are pooled/reused. Never leave the cancel overlay attached to a row
  -- after its data has changed.
  if Auctionator.Cancelling.frame then
    Auctionator.Cancelling.frame:DetachRowCancelButton(self)
  end

  self:ApplyFade()
  self:ApplyUndercutHighlight()
  self:ApplyBidderHighlight()
end

function AuctionatorCancellingListResultsRowMixin:ApplyFade()
  if self.rowData.cancelled then
    self:SetAlpha(0.5)
  else
    self:SetAlpha(1)
  end
end

function AuctionatorCancellingListResultsRowMixin:ApplyUndercutHighlight()
  if self.SelectedHighlight then
    self.SelectedHighlight:SetShown(self.rowData.undercut == AUCTIONATOR_L_UNDERCUT_YES)
  end
end

function AuctionatorCancellingListResultsRowMixin:ApplyBidderHighlight()
  if self.BidderHighlight then
    self.BidderHighlight:SetShown(self.rowData.bidder ~= nil and self.rowData.bidder ~= "")
  end
end
