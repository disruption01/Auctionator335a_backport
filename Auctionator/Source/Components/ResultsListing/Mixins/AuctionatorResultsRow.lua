AuctionatorResultsRowTemplateMixin = {}

-- 3.3.5a does not chain an inherited template's OnLoad when the child
-- supplies its own OnLoad. Auctionator's specialised result rows therefore
-- inherit the textures from AuctionatorResultsRowTemplate, but the Lua fields
-- (SelectedHighlight/HighlightTexture/NormalTexture) are never assigned.
-- Recover them lazily so every result-row subtype gets the same fix.
local function Auctionator335EnsureResultRowRegions(self)
  local name = self.GetName and self:GetName()
  if name then
    self.SelectedHighlight = self.SelectedHighlight or _G[name .. "SelectedHighlight"]
    self.HighlightTexture = self.HighlightTexture or _G[name .. "HighlightTexture"]
    self.NormalTexture = self.NormalTexture or _G[name .. "NormalTexture"]
  end

  -- Stay defensive for private-server XML quirks where the inherited region
  -- itself was not instantiated. These are visual fallbacks only.
  if not self.SelectedHighlight and self.CreateTexture then
    self.SelectedHighlight = self:CreateTexture(nil, "OVERLAY")
    self.SelectedHighlight:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    self.SelectedHighlight:SetBlendMode("ADD")
    self.SelectedHighlight:SetAllPoints(self)
    self.SelectedHighlight:SetVertexColor(1, 1, 1, 0.25)
    self.SelectedHighlight:Hide()
  end
  if not self.HighlightTexture and self.CreateTexture then
    self.HighlightTexture = self:CreateTexture(nil, "OVERLAY")
    self.HighlightTexture:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    self.HighlightTexture:SetBlendMode("ADD")
    self.HighlightTexture:SetAllPoints(self)
    self.HighlightTexture:Hide()
  end
  if not self.NormalTexture and self.CreateTexture then
    self.NormalTexture = self:CreateTexture(nil, "BACKGROUND")
    self.NormalTexture:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    self.NormalTexture:SetAllPoints(self)
  end

  -- TBC Classic uses a much darker, warm AH table than the grey fallback we
  -- got from the retail texture conversion. Keep selection/hover gold-toned
  -- and subtle, matching the reference UI more closely.
  if self.SelectedHighlight then
    self.SelectedHighlight:SetVertexColor(0.85, 0.64, 0.16, 0.34)
  end
  if self.HighlightTexture then
    self.HighlightTexture:SetVertexColor(0.72, 0.55, 0.18, 0.18)
  end
end

function AuctionatorResultsRowTemplateMixin:OnClick(...)
  Auctionator.Debug.Message("AuctionatorResultsRowTemplateMixin:OnClick()", ...)
end

function AuctionatorResultsRowTemplateMixin:OnEnter(...)
  Auctionator335EnsureResultRowRegions(self)
  if self.HighlightTexture then
    self.HighlightTexture:Show()
  end
end

function AuctionatorResultsRowTemplateMixin:OnLeave(...)
  Auctionator335EnsureResultRowRegions(self)
  if self.HighlightTexture then
    self.HighlightTexture:Hide()
  end
end

function AuctionatorResultsRowTemplateMixin:Populate(rowData, dataIndex)
  Auctionator335EnsureResultRowRegions(self)
  self.rowData = rowData
  self.dataIndex = dataIndex

  if self.NormalTexture then
    -- Alternate two very close dark brown/black tones like the Classic AH.
    if (dataIndex or 1) % 2 == 0 then
      self.NormalTexture:SetVertexColor(0.32, 0.29, 0.22, 0.62)
    else
      self.NormalTexture:SetVertexColor(0.24, 0.22, 0.18, 0.62)
    end
    self.NormalTexture:Show()
  end
end
