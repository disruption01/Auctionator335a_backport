AuctionatorConfigurationHeadingMixin = {}

local function Auctionator335_EnsureHeadingText(self)
  if self.HeadingText then return self.HeadingText end
  self.HeadingText = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  self.HeadingText:SetJustifyH("LEFT")
  self.HeadingText:SetPoint("TOPLEFT", self, "TOPLEFT", 20, -10)
  return self.HeadingText
end

function AuctionatorConfigurationHeadingMixin:OnLoad()
  Auctionator335_EnsureHeadingText(self)
  if self.headingText ~= nil then
    self.HeadingText:SetText(self.headingText)
  end
end