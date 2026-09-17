AuctionatorConfigurationSubHeadingMixin = {}

local function Auctionator335EnsureSubHeadingText(self)
  if self.HeadingText then return self.HeadingText end
  local name = self.GetName and self:GetName()
  if name then
    self.HeadingText = _G[name .. "HeadingText"]
  end
  if not self.HeadingText and self.CreateFontString then
    self.HeadingText = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.HeadingText:SetPoint("TOPLEFT", self, "TOPLEFT", 20, -6)
  end
  return self.HeadingText
end

function AuctionatorConfigurationSubHeadingMixin:InitializeSubHeading()
  Auctionator.Debug.Message("AuctionatorConfigurationSubHeadingMixin:InitializeSubHeading()")

  local heading = Auctionator335EnsureSubHeadingText(self)
  if self.subHeadingText ~= nil and heading then
    heading:SetText(self.subHeadingText)
  end
end

function AuctionatorConfigurationSubHeadingMixin:SetText(newHeading)
  self.subHeadingText = newHeading
  self:InitializeSubHeading()
end
