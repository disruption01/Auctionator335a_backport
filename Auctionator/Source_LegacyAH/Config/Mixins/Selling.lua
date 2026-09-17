AuctionatorConfigSellingFrameMixin = CreateFromMixins(AuctionatorPanelConfigMixin)

local function AnchorControl(frame, parent, x, y, width, height)
  if not frame then return end
  frame:ClearAllPoints()
  frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
  if width then frame:SetWidth(width) end
  if height then frame:SetHeight(height) end
  frame:Show()
end

local function LayoutSellingOptions(self)
  local content = self.ScrollBox and self.ScrollBox.Content
  if not content then return end

  Auctionator335Config.PrepareTitle(self, self.TitleArea)

  -- Never use the converted modern ScrollBox here. Keep its content frame and
  -- put that inside a real 3.3.5a ScrollFrame instead.
  if self.ScrollBar then self.ScrollBar:Hide() end
  if self.ScrollBox then self.ScrollBox:Hide() end

  local width = Auctionator335Config.GetContentWidth(self) - 8
  local y = 0

  local function checkbox(frame, height, gap)
    height = height or 38
    AnchorControl(frame, content, 0, y, width, height)
    Auctionator335Config.FitCheckbox(frame, width)
    y = y + height + (gap or 2)
  end

  local function numeric(frame, height, gap)
    height = height or 38
    AnchorControl(frame, content, 0, y, width, height)
    Auctionator335Config.FitNumeric(frame, width)
    y = y + height + (gap or 2)
  end

  checkbox(content.AuctionChatLog)
  checkbox(content.ShowBidPrice)
  checkbox(content.ConfirmPostLowPrice)
  checkbox(content.AlwaysLoadMore)
  checkbox(content.GreyPostButton, 42, 8)

  AnchorControl(content.BagHeading, content, 18, y, width - 18, 24)
  y = y + 30
  checkbox(content.BagShown)
  checkbox(content.BagCollapsed)
  numeric(content.IconSize, 38, 8)

  checkbox(content.AutoSelectNext)
  checkbox(content.AutoSelectStackRemainder, 44)
  checkbox(content.ReselectItem, 44)
  checkbox(content.MissingFavourites, 48)
  checkbox(content.PossessedFavouritesFirst, 48, 8)

  AnchorControl(content.UnhideAll, content, 20, y, 220, 24)
  content.UnhideAll:SetScript("OnClick", function() self:UnhideAllClicked() end)
  y = y + 38

  Auctionator335Config.PrepareScroll(self, "__auctionator335SellingScroll", 64, y + 10, content)
end

function AuctionatorConfigSellingFrameMixin:OnLoad()
  Auctionator.Debug.Message("AuctionatorConfigSellingFrameMixin:OnLoad()")
  self.name = AUCTIONATOR_L_CONFIG_SELLING_CATEGORY
  self.parent = "Auctionator"
  LayoutSellingOptions(self)
  self:SetupPanel()
end

function AuctionatorConfigSellingFrameMixin:ShowSettings()
  LayoutSellingOptions(self)
  local c = self.ScrollBox.Content
  c.AuctionChatLog:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.AUCTION_CHAT_LOG))
  c.ShowBidPrice:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.SHOW_SELLING_BID_PRICE))
  c.BagCollapsed:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_BAG_COLLAPSED))
  c.ConfirmPostLowPrice:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_CONFIRM_LOW_PRICE))
  c.AlwaysLoadMore:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_ALWAYS_LOAD_MORE))
  c.GreyPostButton:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_GREY_POST_BUTTON))
  c.BagShown:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.SHOW_SELLING_BAG))
  c.IconSize:SetNumber(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_ICON_SIZE))
  c.AutoSelectNext:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_AUTO_SELECT_NEXT))
  c.AutoSelectStackRemainder:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_POST_STACK_REMAINDER))
  c.ReselectItem:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_SHOULD_RESELECT_ITEM))
  c.MissingFavourites:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_MISSING_FAVOURITES))
  c.PossessedFavouritesFirst:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_FAVOURITES_SORT_OWNED))
  c.UnhideAll:SetEnabled(#AUCTIONATOR_SELLING_GROUPS.HiddenItems ~= 0)
end

function AuctionatorConfigSellingFrameMixin:Save()
  Auctionator.Debug.Message("AuctionatorConfigSellingFrameMixin:Save()")
  local c = self.ScrollBox.Content
  Auctionator.Config.Set(Auctionator.Config.Options.AUCTION_CHAT_LOG, c.AuctionChatLog:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.SHOW_SELLING_BID_PRICE, c.ShowBidPrice:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_BAG_COLLAPSED, c.BagCollapsed:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_CONFIRM_LOW_PRICE, c.ConfirmPostLowPrice:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_ALWAYS_LOAD_MORE, c.AlwaysLoadMore:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_GREY_POST_BUTTON, c.GreyPostButton:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.SHOW_SELLING_BAG, c.BagShown:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_ICON_SIZE, math.min(50, math.max(10, c.IconSize:GetNumber())))
  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_AUTO_SELECT_NEXT, c.AutoSelectNext:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_POST_STACK_REMAINDER, c.AutoSelectStackRemainder:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_SHOULD_RESELECT_ITEM, c.ReselectItem:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_MISSING_FAVOURITES, c.MissingFavourites:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_FAVOURITES_SORT_OWNED, c.PossessedFavouritesFirst:GetChecked())
end

function AuctionatorConfigSellingFrameMixin:UnhideAllClicked()
  Auctionator.Groups.UnhideAll()
  Auctionator.Groups.CallbackRegistry:TriggerEvent("Customise.EditMade")
  self.ScrollBox.Content.UnhideAll:Disable()
end

function AuctionatorConfigSellingFrameMixin:Cancel()
  Auctionator.Debug.Message("AuctionatorConfigSellingFrameMixin:Cancel()")
end
