AuctionatorTabMixin = {}

function AuctionatorTabMixin:Initialize(name, tabTemplate, tabHeader, displayMode)
  Auctionator.Debug.Message("AuctionatorTabMixin:Initialize()")

  self.ahTitle = tabHeader
  self.displayMode = displayMode

  -- On the 3.3.5a XML engine, $parentTitle isn't addressable when the parent
  -- frame is anonymous. Give each wrapper a stable name and still keep a
  -- fallback for clients/cores that don't populate the child reference.
  local index = (AuctionFrame.numTabs or 0) + 1
  local wrapperName = "AuctionatorTabWrapper" .. tostring(index)
  self.wrapperFrame = CreateFrame("FRAME", wrapperName, AuctionFrame, "AuctionatorTabWrapperTemplate")
  self.wrapperFrame.Title = self.wrapperFrame.Title or _G[wrapperName .. "Title"]
  if not self.wrapperFrame.Title then
    local regions = {self.wrapperFrame:GetRegions()}
    for _, region in ipairs(regions) do
      if region and region.GetObjectType and region:GetObjectType() == "FontString" then
        self.wrapperFrame.Title = region
        break
      end
    end
  end
  if not self.wrapperFrame.Title then
    self.wrapperFrame.Title = self.wrapperFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.wrapperFrame.Title:SetPoint("TOP", 0, -18)
  end
  self.wrapperFrame.Title:SetText(self.ahTitle or "")
  -- Create this tab's frame
  self.frameRef = CreateFrame(
    "FRAME",
    displayMode[1],
    self.wrapperFrame,
    tabTemplate
  )
  self.frameRef:Hide()

  self:SetID(index)

  self:SetPoint("LEFT", _G["AuctionFrameTab" .. (index - 1)], "RIGHT", -15, 0)

  PanelTemplates_SetNumTabs(AuctionFrame, index)
  PanelTemplates_EnableTab(AuctionFrame, index)
  --PanelTemplates_DeselectTab(self)
end

function AuctionatorTabMixin:Selected()
  PanelTemplates_SetTab(AuctionFrame, self)
  PanelTemplates_SelectTab(self)
  self.wrapperFrame:Show()
  self.frameRef:Show()

  --AuctionHouseFrame:SetTitle(self.ahTitle)
  AuctionFrameTopLeft:SetTexture("Interface\\AddOns\\Auctionator\\Images_Classic\\topleft");
  AuctionFrameTop:SetTexture("Interface\\AddOns\\Auctionator\\Images_Classic\\top");
  AuctionFrameTopRight:SetTexture("Interface\\AddOns\\Auctionator\\Images_Classic\\topright");
  AuctionFrameBotLeft:SetTexture("Interface\\AddOns\\Auctionator\\Images_Classic\\botleft");
  AuctionFrameBot:SetTexture("Interface\\AddOns\\Auctionator\\Images_Classic\\bot");
  AuctionFrameBotRight:SetTexture("Interface\\AddOns\\Auctionator\\Images_Classic\\botright");
end

function AuctionatorTabMixin:DeselectTab()
  PanelTemplates_DeselectTab(self)
  self.wrapperFrame:Hide()
end
