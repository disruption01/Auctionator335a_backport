local function Auctionator335Layout_AuctionatorConfigProfileFrameMixin(self)
  if self.__legacyLayoutDone then return end
  if not self.TitleArea then return end
  self.__legacyLayoutDone = true
  if self.TitleArea then self.TitleArea:ClearAllPoints(); self.TitleArea:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0); self.TitleArea:SetWidth(460); self.TitleArea:SetHeight(60) end
  if self.ProfileToggle then self.ProfileToggle:ClearAllPoints(); self.ProfileToggle:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -78); self.ProfileToggle:SetWidth(460); self.ProfileToggle:SetHeight(40) end
end

AuctionatorConfigProfileFrameMixin = CreateFromMixins(AuctionatorPanelConfigMixin)

function AuctionatorConfigProfileFrameMixin:OnLoad()
  Auctionator335Layout_AuctionatorConfigProfileFrameMixin(self)
  Auctionator.Debug.Message("AuctionatorConfigProfileFrameMixin:OnLoad()")

  self.name = AUCTIONATOR_L_CONFIG_PROFILE_CATEGORY
  self.parent = "Auctionator"

  self:SetupPanel()
end

function AuctionatorConfigProfileFrameMixin:ShowSettings()
  Auctionator335Layout_AuctionatorConfigProfileFrameMixin(self)
  self.ProfileToggle:SetChecked(Auctionator.Config.IsCharacterConfig())
end

function AuctionatorConfigProfileFrameMixin:Save()
  Auctionator.Debug.Message("AuctionatorConfigProfileFrameMixin:Save()")

  Auctionator.Config.SetCharacterConfig(self.ProfileToggle:GetChecked())
end

function AuctionatorConfigProfileFrameMixin:Cancel()
  Auctionator.Debug.Message("AuctionatorConfigProfileFrameMixin:Cancel()")
end
