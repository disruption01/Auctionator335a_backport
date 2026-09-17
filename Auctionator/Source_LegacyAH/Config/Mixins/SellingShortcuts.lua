local function Auctionator335Layout_AuctionatorConfigSellingShortcutsFrameMixin(self)
  if not self.TitleArea then return end

  Auctionator335Config.PrepareTitle(self, self.TitleArea)
  local width = Auctionator335Config.GetContentWidth(self) - 8

  if self.BagSelectShortcut then
    self.BagSelectShortcut:ClearAllPoints()
    self.BagSelectShortcut:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -72)
    self.BagSelectShortcut:SetWidth(width)
    self.BagSelectShortcut:SetHeight(58)

    if self.BagSelectShortcut.DropDown then
      self.BagSelectShortcut.DropDown:ClearAllPoints()
      self.BagSelectShortcut.DropDown:SetPoint("TOPLEFT", self.BagSelectShortcut, "TOPLEFT", 10, -4)
      self.BagSelectShortcut.DropDown:SetWidth(170)
    end
    if self.BagSelectShortcut.Label then
      self.BagSelectShortcut.Label:ClearAllPoints()
      self.BagSelectShortcut.Label:SetPoint("TOPLEFT", self.BagSelectShortcut, "TOPLEFT", 194, -5)
      Auctionator335Config.WrapFontString(self.BagSelectShortcut.Label, width - 202, 48)
    end
  end

  local function keyRow(frame, y)
    if not frame then return end
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -y)
    frame:SetWidth(width)
    frame:SetHeight(56)
    Auctionator335Config.FitKeyBinding(frame, width)
    if frame.Description then
      frame.Description:ClearAllPoints()
      frame.Description:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -5)
      Auctionator335Config.WrapFontString(frame.Description, width - 190, 48)
    end
    if frame.Button then
      frame.Button:SetWidth(165)
      frame.Button:ClearAllPoints()
      frame.Button:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
    end
  end

  keyRow(self.PostShortcut, 140)
  keyRow(self.SkipShortcut, 202)
  keyRow(self.PrevShortcut, 264)
end

AuctionatorConfigSellingShortcutsFrameMixin = CreateFromMixins(AuctionatorPanelConfigMixin)

function AuctionatorConfigSellingShortcutsFrameMixin:OnLoad()
  Auctionator335Layout_AuctionatorConfigSellingShortcutsFrameMixin(self)
  Auctionator.Debug.Message("AuctionatorConfigSellingShortcutsFrameMixin:OnLoad()")

  self.name = AUCTIONATOR_L_CONFIG_SELLING_SHORTCUTS_CATEGORY
  self.parent = "Auctionator"

  self:SetupPanel()
end

function AuctionatorConfigSellingShortcutsFrameMixin:ShowSettings()
  Auctionator335Layout_AuctionatorConfigSellingShortcutsFrameMixin(self)
  self.BagSelectShortcut:SetValue(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_BAG_SELECT_SHORTCUT))

  self.PostShortcut:SetShortcut(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_POST_SHORTCUT))
  self.SkipShortcut:SetShortcut(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_SKIP_SHORTCUT))
  self.PrevShortcut:SetShortcut(Auctionator.Config.Get(Auctionator.Config.Options.SELLING_PREV_SHORTCUT))
end

function AuctionatorConfigSellingShortcutsFrameMixin:Save()
  Auctionator.Debug.Message("AuctionatorConfigSellingShortcutsFrameMixin:Save()")

  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_BAG_SELECT_SHORTCUT, self.BagSelectShortcut:GetValue())

  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_POST_SHORTCUT, self.PostShortcut:GetShortcut())
  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_SKIP_SHORTCUT, self.SkipShortcut:GetShortcut())
  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_PREV_SHORTCUT, self.PrevShortcut:GetShortcut())
end

function AuctionatorConfigSellingShortcutsFrameMixin:UnhideAllClicked()
  Auctionator.Config.Set(Auctionator.Config.Options.SELLING_IGNORED_KEYS, {})
  self.UnhideAll:Disable()
end

function AuctionatorConfigSellingShortcutsFrameMixin:Cancel()
  Auctionator.Debug.Message("AuctionatorConfigSellingShortcutsFrameMixin:Cancel()")
end
