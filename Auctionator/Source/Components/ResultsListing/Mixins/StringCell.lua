AuctionatorStringCellTemplateMixin = CreateFromMixins(AuctionatorCellMixin, AuctionatorRetailImportTableBuilderCellMixin)

-- 3.3.5a does not reliably materialize FontString regions inherited by
-- virtual templates. TableBuilder cells can therefore exist without the
-- expected lowercase `text` region. Resolve an inherited region if one is
-- present, otherwise create the equivalent region at runtime.
local function EnsureStringCellText(self)
  if self.text then
    return self.text
  end

  if self.GetName and self:GetName() then
    self.text = _G[self:GetName() .. "text"] or _G[self:GetName() .. "Text"]
    if self.text then
      return self.text
    end
  end

  if self.GetRegions then
    local regions = { self:GetRegions() }
    for _, region in ipairs(regions) do
      if region and region.GetObjectType and region:GetObjectType() == "FontString" then
        self.text = region
        return self.text
      end
    end
  end

  if self.CreateFontString then
    self.text = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.text:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
    self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
    self.text:SetJustifyV("MIDDLE")
  end

  return self.text
end

function AuctionatorStringCellTemplateMixin:Init(columnName)
  self.columnName = columnName

  local text = EnsureStringCellText(self)
  if text then
    text:SetJustifyH("LEFT")
  end
end

function AuctionatorStringCellTemplateMixin:Populate(rowData, index)
  AuctionatorCellMixin.Populate(self, rowData, index)

  local text = EnsureStringCellText(self)
  if text then
    text:SetText(rowData[self.columnName] or "")
  end
end

function AuctionatorStringCellTemplateMixin:OnHide()
  local text = EnsureStringCellText(self)
  if text then
    text:Hide()
  end
end

function AuctionatorStringCellTemplateMixin:OnShow()
  local text = EnsureStringCellText(self)
  if text then
    text:Show()
  end
end
