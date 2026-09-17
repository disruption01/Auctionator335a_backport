local function Auctionator335Layout_AuctionatorConfigTooltipsFrameMixin(self)
  if not self.TitleArea then return end

  Auctionator335Config.PrepareTitle(self, self.TitleArea)
  local width = Auctionator335Config.GetContentWidth(self) - 8
  local y = 72

  local function place(frame, height)
    if not frame then return end
    height = height or 40
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -y)
    frame:SetWidth(width)
    frame:SetHeight(height)
    Auctionator335Config.FitCheckbox(frame, width)
    y = y + height
  end

  place(self.AuctionTooltips, 40)
  place(self.MailboxTooltips, 40)
  place(self.VendorTooltips, 40)
  place(self.EnchantTooltips, 42)
  place(self.ProspectTooltips, 42)
  place(self.MillTooltips, 42)
  -- This is the longest description on the page. Give it a real paragraph
  -- instead of letting the 3.3.5a FontString run past the panel edge.
  place(self.AuctionAgeTooltips, 54)
  place(self.ShiftStackTooltips, 42)
end

AuctionatorConfigTooltipsFrameMixin = CreateFromMixins(AuctionatorPanelConfigMixin)

function AuctionatorConfigTooltipsFrameMixin:OnLoad()
  Auctionator335Layout_AuctionatorConfigTooltipsFrameMixin(self)
  Auctionator.Debug.Message("AuctionatorConfigTooltipsFrameMixin:OnLoad()")

  self.name = AUCTIONATOR_L_CONFIG_TOOLTIPS_CATEGORY
  self.parent = "Auctionator"

  self:SetupPanel()
end

function AuctionatorConfigTooltipsFrameMixin:ShowSettings()
  Auctionator335Layout_AuctionatorConfigTooltipsFrameMixin(self)
  self.MailboxTooltips:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.MAILBOX_TOOLTIPS))
  self.VendorTooltips:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.VENDOR_TOOLTIPS))
  self.AuctionTooltips:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.AUCTION_TOOLTIPS))
  self.EnchantTooltips:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.ENCHANT_TOOLTIPS))
  self.ProspectTooltips:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.PROSPECT_TOOLTIPS))
  self.MillTooltips:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.MILL_TOOLTIPS))
  self.ShiftStackTooltips:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.SHIFT_STACK_TOOLTIPS))
  self.AuctionAgeTooltips:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.AUCTION_AGE_TOOLTIPS))
end

function AuctionatorConfigTooltipsFrameMixin:Save()
  Auctionator.Debug.Message("AuctionatorConfigTooltipsFrameMixin:Save()")

  Auctionator.Config.Set(Auctionator.Config.Options.MAILBOX_TOOLTIPS, self.MailboxTooltips:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.VENDOR_TOOLTIPS, self.VendorTooltips:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.AUCTION_TOOLTIPS, self.AuctionTooltips:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.ENCHANT_TOOLTIPS, self.EnchantTooltips:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.PROSPECT_TOOLTIPS, self.ProspectTooltips:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.MILL_TOOLTIPS, self.MillTooltips:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.SHIFT_STACK_TOOLTIPS, self.ShiftStackTooltips:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.AUCTION_AGE_TOOLTIPS, self.AuctionAgeTooltips:GetChecked())
end

function AuctionatorConfigTooltipsFrameMixin:Cancel()
  Auctionator.Debug.Message("AuctionatorConfigTooltipsFrameMixin:Cancel()")
end
