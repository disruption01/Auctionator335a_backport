local function Auctionator335Layout_AuctionatorConfigCancellingFrameMixin(self)
  if not self.TitleArea then return end

  Auctionator335Config.PrepareTitle(self, self.TitleArea)
  local width = Auctionator335Config.GetContentWidth(self) - 8

  if self.UndercutItemsAhead then
    self.UndercutItemsAhead:ClearAllPoints()
    self.UndercutItemsAhead:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -78)
    self.UndercutItemsAhead:SetWidth(width)
    self.UndercutItemsAhead:SetHeight(58)
    Auctionator335Config.FitNumeric(self.UndercutItemsAhead, width)
    if self.UndercutItemsAhead.InputBox and self.UndercutItemsAhead.InputBox.Label then
      Auctionator335Config.WrapFontString(self.UndercutItemsAhead.InputBox.Label, width - 100, 52)
    end
  end

  if self.CancelUndercutShortcut then
    self.CancelUndercutShortcut:ClearAllPoints()
    self.CancelUndercutShortcut:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -150)
    self.CancelUndercutShortcut:SetWidth(width)
    self.CancelUndercutShortcut:SetHeight(64)
    if self.CancelUndercutShortcut.Description then
      self.CancelUndercutShortcut.Description:ClearAllPoints()
      self.CancelUndercutShortcut.Description:SetPoint("TOPLEFT", self.CancelUndercutShortcut, "TOPLEFT", 8, -4)
      Auctionator335Config.WrapFontString(self.CancelUndercutShortcut.Description, width - 190, 54)
    end
    if self.CancelUndercutShortcut.Button then
      self.CancelUndercutShortcut.Button:SetWidth(165)
      self.CancelUndercutShortcut.Button:ClearAllPoints()
      self.CancelUndercutShortcut.Button:SetPoint("RIGHT", self.CancelUndercutShortcut, "RIGHT", -4, 0)
    end
  end
end

AuctionatorConfigCancellingFrameMixin = CreateFromMixins(AuctionatorPanelConfigMixin)

function AuctionatorConfigCancellingFrameMixin:OnLoad()
  Auctionator335Layout_AuctionatorConfigCancellingFrameMixin(self)
  Auctionator.Debug.Message("AuctionatorConfigCancellingFrameMixin:OnLoad()")

  self.name = AUCTIONATOR_L_CONFIG_CANCELLING_CATEGORY
  self.parent = "Auctionator"

  self:SetupPanel()
end

function AuctionatorConfigCancellingFrameMixin:ShowSettings()
  Auctionator335Layout_AuctionatorConfigCancellingFrameMixin(self)
  self.UndercutItemsAhead:SetNumber(Auctionator.Config.Get(Auctionator.Config.Options.UNDERCUT_ITEMS_AHEAD))

  self.CancelUndercutShortcut:SetShortcut(Auctionator.Config.Get(Auctionator.Config.Options.CANCEL_UNDERCUT_SHORTCUT))
end

function AuctionatorConfigCancellingFrameMixin:Save()
  Auctionator.Debug.Message("AuctionatorConfigCancellingFrameMixin:Save()")

  Auctionator.Config.Set(Auctionator.Config.Options.UNDERCUT_ITEMS_AHEAD, math.min(self.UndercutItemsAhead:GetNumber(), 50))

  Auctionator.Config.Set(Auctionator.Config.Options.CANCEL_UNDERCUT_SHORTCUT, self.CancelUndercutShortcut:GetShortcut())
end

function AuctionatorConfigCancellingFrameMixin:Cancel()
  Auctionator.Debug.Message("AuctionatorConfigCancellingFrameMixin:Cancel()")
end
