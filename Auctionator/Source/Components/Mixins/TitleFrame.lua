AuctionatorConfigurationTitleFrameMixin = {}

local function Auctionator335_EnsureTitleFrameRegions(self)
  if not self.Title then
    self.Title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    self.Title:SetPoint("TOPLEFT", self, "TOPLEFT", 20, -15)
  end
  if not self.SubTitle then
    self.SubTitle = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    self.SubTitle:SetJustifyH("LEFT")
    self.SubTitle:SetJustifyV("TOP")
    self.SubTitle:SetPoint("TOPLEFT", self, "TOPLEFT", 20, -40)
    self.SubTitle:SetPoint("TOPRIGHT", self, "TOPRIGHT", -20, -40)
  end
end

function AuctionatorConfigurationTitleFrameMixin:OnLoad()
  Auctionator335_EnsureTitleFrameRegions(self)
  if self.titleText ~= nil then
    self.Title:SetText(self.titleText)
  end

  if self.subTitleText then
    self.SubTitle:SetText(self.subTitleText)

    -- Width value doesn't matter, but setting this makes the word wrap work
    -- The anchors in the frame xml set the actual width.
    self.SubTitle:SetWidth(200)
  end
end
