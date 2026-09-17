AuctionatorFullScanStatusMixin = {}

function AuctionatorFullScanStatusMixin:OnLoad()
  Auctionator.EventBus:Register(self, {
    Auctionator.FullScan.Events.ScanStart,
    Auctionator.FullScan.Events.ScanProgress,
    Auctionator.FullScan.Events.ScanComplete,
    Auctionator.FullScan.Events.ScanFailed,
  })
  if self.Hide then self:Hide() end
end

local function EnsureScanStatusText(self)
  if self.Text then return self.Text end
  local name = self.GetName and self:GetName()
  if name then self.Text = _G[name .. "Text"] end
  if not self.Text and self.CreateFontString then
    self.Text = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.Text:SetJustifyH("CENTER")
    self.Text:SetPoint("CENTER", self, "CENTER", 0, 0)
    self.Text:SetWidth(80)
  end
  return self.Text
end

function AuctionatorFullScanStatusMixin:OnShow()
  EnsureScanStatusText(self)
end

function AuctionatorFullScanStatusMixin:ReceiveEvent(event, eventData)
  local text = EnsureScanStatusText(self)
  if not text then return end
  if event == Auctionator.FullScan.Events.ScanStart then
    text:SetText("0%")
    self:Show()
  elseif event == Auctionator.FullScan.Events.ScanProgress then
    text:SetText(tostring(math.floor((eventData or 0)*100)) .. "%")
    self:Show()
  elseif event == Auctionator.FullScan.Events.ScanComplete then
    text:SetText("100%")
    self:Show()
    if C_Timer and C_Timer.After then C_Timer.After(1.5, function() if self then self:Hide() end end) end
  else
    text:SetText("")
    self:Hide()
  end
end
