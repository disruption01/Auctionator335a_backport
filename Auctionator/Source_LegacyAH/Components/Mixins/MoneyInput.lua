AuctionatorConfigMoneyInputMixin = CreateFromMixins(AuctionatorConfigTooltipMixin)

local function Auctionator335_EnsureMoneyInputLabel(self)
  if self.Label then return self.Label end
  self.Label = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  if self.MoneyInput then
    self.Label:SetPoint("LEFT", self.MoneyInput, "RIGHT", 5, 0)
  else
    self.Label:SetPoint("LEFT", self, "LEFT", 230, 0)
  end
  return self.Label
end

function AuctionatorConfigMoneyInputMixin:OnLoad()
  Auctionator335_EnsureMoneyInputLabel(self)
  if self.labelText ~= nil then
    self.Label:SetText(self.labelText)
  end

  self.MoneyInput.CopperBox:SetScript("OnEnter", function() self:OnEnter() end)
  self.MoneyInput.CopperBox:SetScript("OnLeave", function() self:OnLeave() end)
  self.MoneyInput.SilverBox:SetScript("OnEnter", function() self:OnEnter() end)
  self.MoneyInput.SilverBox:SetScript("OnLeave", function() self:OnLeave() end)
  self.MoneyInput.GoldBox:SetScript("OnEnter", function() self:OnEnter() end)
  self.MoneyInput.GoldBox:SetScript("OnLeave", function() self:OnLeave() end)

  self.MoneyInput.CopperBox:SetScript("OnEnterPressed", function()
    Auctionator.Components.ReportEnterPressed()
  end)
  self.MoneyInput.SilverBox:SetScript("OnEnterPressed", function()
    Auctionator.Components.ReportEnterPressed()
  end)
  self.MoneyInput.GoldBox:SetScript("OnEnterPressed", function()
    Auctionator.Components.ReportEnterPressed()
  end)
end

function AuctionatorConfigMoneyInputMixin:SetAmount(value)
  self.MoneyInput:SetAmount(value)
  self.MoneyInput.GoldBox:SetCursorPosition(0)
  self.MoneyInput.SilverBox:SetCursorPosition(0)
  self.MoneyInput.CopperBox:SetCursorPosition(0)
end

function AuctionatorConfigMoneyInputMixin:Clear()
  self.MoneyInput:Clear()
end

function AuctionatorConfigMoneyInputMixin:GetAmount()
  return self.MoneyInput:GetAmount()
end
