AuctionatorConfigMinMaxMixin = CreateFromMixins(AuctionatorConfigTooltipMixin)

local function Auctionator335_EnsureMinMaxTitle(self)
  if self.Title then return self.Title end
  self.Title = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  self.Title:SetJustifyH("CENTER")
  self.Title:SetWidth(115)
  self.Title:SetHeight(20)
  self.Title:SetPoint("TOPLEFT", self, "TOPLEFT", 25, 0)
  return self.Title
end

function AuctionatorConfigMinMaxMixin:OnLoad()
  -- 3.3.5a does not reliably inherit Layer regions from virtual templates.
  Auctionator335_EnsureMinMaxTitle(self)
  self.onTabOut = function() end
  self.onEnter = function() end

  if self.titleText ~= nil then
    self.Title:SetText(self.titleText)
  end

  self.ResetButton:SetClickCallback(function()
    self:Reset()
  end)
end

function AuctionatorConfigMinMaxMixin:SetFocus()
  self.MinBox:SetFocus()
end

function AuctionatorConfigMinMaxMixin:SetCallbacks(callbacks)
  self.onTabOut = callbacks.OnTab or function() end
  self.onEnter = callbacks.OnEnter or function() end
end

function AuctionatorConfigMinMaxMixin:OnEnterPressed()
  self.onEnter()
end

function AuctionatorConfigMinMaxMixin:MinTabPressed()
  self.MaxBox:SetFocus()
end

function AuctionatorConfigMinMaxMixin:MaxTabPressed()
  self.onTabOut()
end

function AuctionatorConfigMinMaxMixin:GetMin()
  return self.MinBox:GetNumber()
end

function AuctionatorConfigMinMaxMixin:GetMax()
  return self.MaxBox:GetNumber()
end

function AuctionatorConfigMinMaxMixin:SetMin(value)
  if value == nil then
    self.MinBox:SetText("")
  else
    self.MinBox:SetNumber(value)
  end
end

function AuctionatorConfigMinMaxMixin:SetMax(value)
  if value == nil then
    self.MaxBox:SetText("")
  else
    self.MaxBox:SetNumber(value)
  end
end

function AuctionatorConfigMinMaxMixin:Reset()
  self.MinBox:SetText("")
  self.MaxBox:SetText("")
end
