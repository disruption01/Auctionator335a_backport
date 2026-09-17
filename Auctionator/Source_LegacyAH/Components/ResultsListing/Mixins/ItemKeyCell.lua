AuctionatorItemKeyCellTemplateMixin = CreateFromMixins(AuctionatorCellMixin, AuctionatorRetailImportTableBuilderCellMixin)

local function Auctionator335_EnsureItemKeyCellRegions(self)
  -- The converted 3.3.5 XML can create the named Icon/IconBorder regions,
  -- but on this client those inherited regions are not reliable for rendering
  -- item textures (we were seeing the empty square/border with no art).
  -- Keep them hidden and use a dedicated ARTWORK texture owned by the cell.
  -- This is independent of XML layer inheritance and mirrors the compact icon
  -- presentation used by Auctionator on TBC Classic.
  if self.Icon then
    self.Icon:Hide()
  end
  if self.IconBorder then
    self.IconBorder:Hide()
  end

  if not self.Auctionator335Icon then
    self.Auctionator335Icon = self:CreateTexture(nil, "ARTWORK")
    self.Auctionator335Icon:SetWidth(14)
    self.Auctionator335Icon:SetHeight(14)
    self.Auctionator335Icon:SetPoint("LEFT", self, "LEFT", 0, 0)
    if self.Auctionator335Icon.SetDrawLayer then
      self.Auctionator335Icon:SetDrawLayer("ARTWORK", 7)
    end
  end

  if not self.Text then
    self.Text = self:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
    self.Text:SetJustifyH("LEFT")
  end
  self.Text:ClearAllPoints()
  self.Text:SetPoint("LEFT", self.Auctionator335Icon, "RIGHT", 4, -1)
  self.Text:SetPoint("RIGHT", self, "RIGHT", 1, 0)
end

local function Auctionator335_ItemID(value)
  if type(value) == "number" then
    return value
  end
  if type(value) ~= "string" then
    return nil
  end
  return tonumber(value:match("item:(%-?%d+)")) or tonumber(value:match("^(%-?%d+)$"))
end

local function Auctionator335_ResolveItemIcon(rowData)
  local itemRef = rowData.itemString or rowData.itemLink
  local itemID = Auctionator335_ItemID(itemRef)

  -- Old clients are most reliable when resolving an icon by item ID through
  -- GetItemIcon(). This also converts file-ID-like values into a texture path
  -- understood by 3.3.5a's Texture:SetTexture().
  if itemID and GetItemIcon then
    local texture = GetItemIcon(itemID)
    if texture then
      return texture
    end
  end

  -- Once the item cache is warm, GetItemInfo is the most dependable icon
  -- source on the Wrath client. Prefer it to any modern/fileID-like value.
  if itemRef then
    local cachedTexture = select(10, GetItemInfo(itemRef))
    if type(cachedTexture) == "string" and cachedTexture ~= "" then
      return cachedTexture
    end
  end

  local icon = rowData.iconTexture
  if type(icon) == "string" and icon ~= "" then
    return icon
  end

  if rowData.entries then
    for _, auction in ipairs(rowData.entries) do
      local candidate = auction.iconTexture or (auction.info and auction.info[2])
      if type(candidate) == "string" and candidate ~= "" then
        return candidate
      end

      local id = Auctionator335_ItemID(auction.itemLink) or Auctionator335_ItemID(auction.info and auction.info[Auctionator.Constants.AuctionItemInfo.ItemID])
      if id and GetItemIcon then
        local texture = GetItemIcon(id)
        if texture then
          return texture
        end
      end
      if id then
        local texture = select(10, GetItemInfo(id))
        if texture then
          return texture
        end
      end
    end
  end

  if rowData.itemLink then
    local texture = select(10, GetItemInfo(rowData.itemLink))
    if texture then
      return texture
    end
  elseif itemID then
    local texture = select(10, GetItemInfo(itemID))
    if texture then
      return texture
    end
  end

  return "Interface\\Icons\\INV_Misc_QuestionMark"
end

function AuctionatorItemKeyCellTemplateMixin:Init()
  Auctionator335_EnsureItemKeyCellRegions(self)
  self.Text:SetJustifyH("LEFT")
end

function AuctionatorItemKeyCellTemplateMixin:Populate(rowData, index)
  Auctionator335_EnsureItemKeyCellRegions(self)
  AuctionatorCellMixin.Populate(self, rowData, index)

  self.Text:SetText(rowData.itemName or "")

  local icon = Auctionator335_ResolveItemIcon(rowData)
  rowData.iconTexture = icon
  self.Auctionator335Icon:SetTexture(icon)
  self.Auctionator335Icon:SetTexCoord(0, 1, 0, 1)
  self.Auctionator335Icon:SetAlpha(rowData.noneAvailable and 0.5 or 1.0)
  self.Auctionator335Icon:Show()
end

function AuctionatorItemKeyCellTemplateMixin:OnEnter()
  if self.rowData.itemLink then
    GameTooltip:SetOwner(self:GetParent(), "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(self.rowData.itemLink)
    GameTooltip:Show()
  end
  AuctionatorCellMixin.OnEnter(self)
end

function AuctionatorItemKeyCellTemplateMixin:OnLeave()
  if self.rowData.itemLink then
    GameTooltip:Hide()
  end
  AuctionatorCellMixin.OnLeave(self)
end
