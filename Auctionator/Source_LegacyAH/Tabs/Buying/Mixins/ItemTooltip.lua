AuctionatorBuyingItemTooltipMixin = {}

local function Auctionator335_EnsureBuyingTooltipRegions(self)
  -- This frame is anonymous in the Legacy shopping template. On 3.3.5a the
  -- inherited Layer regions render, but $parentIcon/$parentText cannot be
  -- resolved because the parent has no global name. Reuse those regions
  -- before creating fallbacks, otherwise the literal "Item text" remains
  -- visible under the real item name.
  if not self.Icon or not self.Text then
    local regions = { self:GetRegions() }
    for _, region in ipairs(regions) do
      if region and region.GetObjectType then
        local ok, objectType = pcall(region.GetObjectType, region)
        if ok and objectType == "Texture" and not self.Icon then
          self.Icon = region
        elseif ok and objectType == "FontString" and not self.Text then
          self.Text = region
        end
      end
    end
  end

  if not self.Icon then
    self.Icon = self:CreateTexture(nil, "ARTWORK")
  end
  self.Icon:ClearAllPoints()
  self.Icon:SetWidth(40)
  self.Icon:SetHeight(40)
  self.Icon:SetPoint("TOPLEFT", self, "TOPLEFT", 15, -10)

  if not self.Text then
    self.Text = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  end
  self.Text:ClearAllPoints()
  self.Text:SetJustifyH("LEFT")
  self.Text:SetJustifyV("TOP")
  self.Text:SetPoint("TOPLEFT", self.Icon, "TOPRIGHT", 10, 5)
  self.Text:SetPoint("RIGHT", self, "RIGHT", -5, 0)
end

function AuctionatorBuyingItemTooltipMixin:OnLoad()
  Auctionator335_EnsureBuyingTooltipRegions(self)
  Auctionator.EventBus:Register(self, {
    Auctionator.Buying.Events.ShowForShopping
  })
end

function AuctionatorBuyingItemTooltipMixin:OnEnter()
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:SetHyperlink(self.itemLink)
  GameTooltip:Show()
end

function AuctionatorBuyingItemTooltipMixin:OnLeave()
  GameTooltip:Hide()
end

function AuctionatorBuyingItemTooltipMixin:OnMouseUp()
  if IsModifiedClick("CHATLINK") then
    Auctionator.Utilities.InsertLink(self.itemLink)
  else
    if self.itemLink ~= nil then
      -- Search for item in the browse tab (so that someone can check the bid
      -- prices)
      if BrowseResetButton then
        -- BrowseResetButton doesn't exist on classic era
        BrowseResetButton:Click()
      end
      BrowseName:SetText(Auctionator.Utilities.GetNameFromLink(self.itemLink))
      AuctionFrameTab1:Click()
      AuctionFrameBrowse_Search()
    end
  end
end

function AuctionatorBuyingItemTooltipMixin:ReceiveEvent(eventName, eventData)
  Auctionator335_EnsureBuyingTooltipRegions(self)
  self.itemLink = eventData.itemLink
  local icon = eventData.iconTexture
  if not icon and eventData.itemLink then
    icon = select(10, C_Item.GetItemInfo(eventData.itemLink))
  end
  self.Icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
  self.Text:SetText(eventData.itemName or "")
end
