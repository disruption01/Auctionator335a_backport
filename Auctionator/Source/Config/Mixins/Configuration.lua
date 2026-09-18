AuctionatorConfigFrameMixin = CreateFromMixins(AuctionatorPanelConfigMixin)

local function Auctionator335SetupRootOptionsLanding(self)
  if self.__auctionator335LandingReady then return end
  self.__auctionator335LandingReady = true

  local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", self, "TOPLEFT", 20, -18)
  title:SetText("Auctionator")
  self.Auctionator335LandingTitle = title

  local text = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
  text:SetWidth(460)
  text:SetJustifyH("LEFT")
  text:SetJustifyV("TOP")
  text:SetText("Select a category on the left to configure Auctionator.")
  self.Auctionator335LandingText = text
end

function AuctionatorConfigFrameMixin:OnLoad()
  Auctionator.Debug.Message("AuctionatorConfigFrameMixin:OnLoad()")

  self.name = "Auctionator"
  self:SetParent(InterfaceOptionsFramePanelContainer or UIParent)

  Auctionator335SetupRootOptionsLanding(self)
  self:SetupPanel()
end

function AuctionatorConfigFrameMixin:Show()

end

function AuctionatorConfigFrameMixin:Save()
  Auctionator.Debug.Message("AuctionatorConfigFrameMixin:Save()")
end

function AuctionatorConfigFrameMixin:Cancel()
  Auctionator.Debug.Message("AuctionatorConfigFrameMixin:Cancel()")
end
