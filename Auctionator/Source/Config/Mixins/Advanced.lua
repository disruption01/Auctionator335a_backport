local function Auctionator335Layout_AuctionatorConfigAdvancedFrameMixin(self)
  if self.__legacyLayoutDone then return end
  if not self.TitleArea then return end
  self.__legacyLayoutDone = true
  if self.TitleArea then self.TitleArea:ClearAllPoints(); self.TitleArea:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0); self.TitleArea:SetWidth(460); self.TitleArea:SetHeight(60) end
  if self.ReplicateScan then self.ReplicateScan:ClearAllPoints(); self.ReplicateScan:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -78); self.ReplicateScan:SetWidth(460); self.ReplicateScan:SetHeight(40) end
  if self.DebugHeading then self.DebugHeading:ClearAllPoints(); self.DebugHeading:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -128); self.DebugHeading:SetWidth(460); self.DebugHeading:SetHeight(30) end
  if self.Debug then self.Debug:ClearAllPoints(); self.Debug:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -160); self.Debug:SetWidth(460); self.Debug:SetHeight(40) end
end

AuctionatorConfigAdvancedFrameMixin = CreateFromMixins(AuctionatorPanelConfigMixin)

function AuctionatorConfigAdvancedFrameMixin:OnLoad()
  Auctionator335Layout_AuctionatorConfigAdvancedFrameMixin(self)
  Auctionator.Debug.Message("AuctionatorConfigAdvancedFrameMixin:OnLoad()")

  self.name = AUCTIONATOR_L_CONFIG_ADVANCED_CATEGORY
  self.parent = "Auctionator"

  self:SetupPanel()
end

function AuctionatorConfigAdvancedFrameMixin:ShowSettings()
  Auctionator335Layout_AuctionatorConfigAdvancedFrameMixin(self)
  self.ReplicateScan:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.REPLICATE_SCAN))
  self.Debug:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.DEBUG))
end

function AuctionatorConfigAdvancedFrameMixin:Save()
  Auctionator.Debug.Message("AuctionatorConfigAdvancedFrameMixin:Save()")

  Auctionator.Config.Set(Auctionator.Config.Options.REPLICATE_SCAN, self.ReplicateScan:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.DEBUG, self.Debug:GetChecked())
end

function AuctionatorConfigAdvancedFrameMixin:Cancel()
  Auctionator.Debug.Message("AuctionatorConfigAdvancedFrameMixin:Cancel()")
end
