AuctionatorGroupsViewItemMixin = {}

local function Auctionator335EnsureViewItemRegions(self)
  local frameName = self.GetName and self:GetName()
  if frameName then
    -- Resolve the regions that already came from the inherited XML before
    -- creating fallbacks. On 3.3.5a they often exist globally but are not
    -- exposed as self.Icon/self.EmptySlot/etc.
    self.Icon = self.Icon or _G[frameName .. 'Icon']
    self.EmptySlot = self.EmptySlot or _G[frameName .. 'EmptySlot']
    self.IconBorder = self.IconBorder or _G[frameName .. 'IconBorder']
    self.IconSelectedHighlight = self.IconSelectedHighlight or _G[frameName .. 'IconSelectedHighlight']
    self.Text = self.Text or _G[frameName .. 'Text']
  end

  if not self.Icon and self.CreateTexture then
    self.Icon = self:CreateTexture(nil, 'ARTWORK')
    self.Icon:SetTexture(nil)
    self.Icon:Hide()
  end

  -- UI-Slot-Background from newer Classic is the pale/white square visible in
  -- the empty large Selling slot on Wrath. Hide the inherited texture entirely
  -- and keep a simple dark background underneath the actual item icon.
  if self.EmptySlot then
    self.EmptySlot:Hide()
  end
  if not self.Auctionator335SlotBackground and self.CreateTexture then
    self.Auctionator335SlotBackground = self:CreateTexture(nil, 'BACKGROUND')
    self.Auctionator335SlotBackground:SetAllPoints(self)
    self.Auctionator335SlotBackground:SetTexture(0.035, 0.035, 0.035, 0.95)
  end

  if self.Icon then
    self.Icon:ClearAllPoints()
    local inset = (self.GetWidth and self:GetWidth() >= 55) and 4 or 1
    self.Icon:SetPoint('TOPLEFT', self, 'TOPLEFT', inset, -inset)
    self.Icon:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -inset, inset)
    -- The inherited icon is a BACKGROUND texture in the modern template. Our
    -- Wrath fallback slot background is also BACKGROUND and can cover it.
    self.Icon:SetDrawLayer('ARTWORK')
  end

  if not self.IconBorder and self.CreateTexture then
    self.IconBorder = self:CreateTexture(nil, 'OVERLAY')
  end
  if self.IconBorder then
    self.IconBorder:SetTexture('Interface\\Buttons\\UI-ActionButton-Border')
    self.IconBorder:SetBlendMode('ADD')
    self.IconBorder:ClearAllPoints()
    self.IconBorder:SetPoint('TOPLEFT', self, 'TOPLEFT', -4, 4)
    self.IconBorder:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', 4, -4)
  end

  if not self.IconSelectedHighlight and self.CreateTexture then
    self.IconSelectedHighlight = self:CreateTexture(nil, 'OVERLAY')
  end
  if self.IconSelectedHighlight then
    self.IconSelectedHighlight:SetTexture('Interface\\Buttons\\UI-ActionButton-Border')
    self.IconSelectedHighlight:SetBlendMode('ADD')
    self.IconSelectedHighlight:ClearAllPoints()
    self.IconSelectedHighlight:SetPoint('TOPLEFT', self, 'TOPLEFT', -4, 4)
    self.IconSelectedHighlight:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', 4, -4)
  end

  if not self.Text and self.CreateFontString then
    self.Text = self:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    self.Text:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -1, 1)
  end
end

function AuctionatorGroupsViewItemMixin:SetClickEvent(eventName)
  self.clickEventName = eventName
end

function AuctionatorGroupsViewItemMixin:SetItemInfo(info)
  Auctionator335EnsureViewItemRegions(self)
  self.itemInfo = info

  if info ~= nil then

    local iconTexture = info.iconTexture
    if not iconTexture and info.itemLink then
      iconTexture = select(10, GetItemInfo(info.itemLink))
    end
    if not iconTexture and info.itemID and GetItemIcon then
      iconTexture = GetItemIcon(info.itemID)
    end
    self.Icon:SetTexture(iconTexture)
    self.Icon:SetShown(iconTexture ~= nil)

    if info.selected then
      self.Icon:SetAlpha(0.8)
    else
      self.Icon:SetAlpha(1)
    end
    local selectedColor = {r=0.977, g=0.592, b=0.086}

    self.IconSelectedHighlight:SetVertexColor(selectedColor.r, selectedColor.g, selectedColor.b)
    self.IconSelectedHighlight:SetShown(info.selected)

    local qualityColor = ITEM_QUALITY_COLORS[self.itemInfo.quality or 1] or ITEM_QUALITY_COLORS[1] or {r=1,g=1,b=1}
    self.IconBorder:SetVertexColor(qualityColor.r, qualityColor.g, qualityColor.b, 1)
    self.IconBorder:SetShown(not info.selected)

    self.Text:SetText(info.itemCount)

    self:ApplyQualityIcon(info.itemLink)

  else
    self.IconBorder:Hide()
    self.Icon:Hide()
    self.Text:SetText("")
    self:SetAlpha(1)

    self:HideQualityIcon()
  end

  self.initializationTime = GetTime()
end

function AuctionatorGroupsViewItemMixin:OnEnter()
  if GetTime() - self.initializationTime > 0 then
    self:UpdateTooltip()
  end
end

function AuctionatorGroupsViewItemMixin:UpdateTooltip()
  if self.itemInfo ~= nil then
    if IsModifiedClick("DRESSUP") then
      ShowInspectCursor();
    else
      ResetCursor()
    end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if Auctionator.Utilities.IsPetLink(self.itemInfo.itemLink) then
      BattlePetToolTip_ShowLink(self.itemInfo.itemLink)
    else
      GameTooltip:SetHyperlink(self.itemInfo.itemLink)
      GameTooltip:Show()
    end
  end
end

function AuctionatorGroupsViewItemMixin:OnLeave()
  ResetCursor()
  if BattlePetTooltip then
    BattlePetTooltip:Hide()
  end
  GameTooltip:Hide()
end

function AuctionatorGroupsViewItemMixin:OnClick(button)
  if self.itemInfo ~= nil then
    if IsModifiedClick("DRESSUP") then
      -- Retail vs Classic functions
      (DressUpLink or DressUpItemLink)(self.itemInfo.itemLink)

    elseif IsModifiedClick("CHATLINK") then
      Auctionator.Utilities.InsertLink(self.itemInfo.itemLink)

    else
      Auctionator.Groups.CallbackRegistry:TriggerEvent(self.clickEventName, self, button)
    end
  end
end

-- Adds Dragonflight (10.0) crafting quality icon for reagents on retail only
function AuctionatorGroupsViewItemMixin:ApplyQualityIcon(itemLink)
  if Auctionator.Constants.IsRetail then
    local info = C_TradeSkillUI.GetItemReagentQualityInfo(itemLink)
    if info ~= nil then
      if not self.ProfessionQualityOverlay then
        self.ProfessionQualityOverlay = self:CreateTexture(nil, "OVERLAY");
        self.ProfessionQualityOverlay:SetPoint("TOPLEFT", -2, 2);
        self.ProfessionQualityOverlay:SetDrawLayer("OVERLAY", 7);
      end
      self.ProfessionQualityOverlay:Show()

      self.ProfessionQualityOverlay:SetAtlas(info.iconInventory, TextureKitConstants.UseAtlasSize);
    else
      self:HideQualityIcon()
    end
  end
end

function AuctionatorGroupsViewItemMixin:HideQualityIcon()
  if self.ProfessionQualityOverlay then
    self.ProfessionQualityOverlay:Hide()
  end
end
