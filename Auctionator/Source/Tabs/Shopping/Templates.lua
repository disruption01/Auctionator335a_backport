function Auctionator.Shopping.Tab.CreateOptionButton(button, xOffset, width, height)
  local option = CreateFrame("Button", nil, button)
  option:SetPoint("TOPRIGHT", xOffset, 0)
  option:SetSize(width, height)
  option.Icon = option:CreateTexture()
  option.Icon:SetSize(height - 5, height - 5)
  option.Icon:SetPoint("CENTER")
  option:SetScript("OnEnter", function()
    option.Icon:SetAlpha(0.5)
    if option.TooltipText then
      GameTooltip:SetOwner(option, "ANCHOR_RIGHT")
      GameTooltip:SetText(option.TooltipText, 1, 1, 1)
      GameTooltip:Show()
    end
  end)
  option:SetScript("OnLeave", function()
    option.Icon:SetAlpha(1)
    if option.TooltipText then
      GameTooltip:Hide()
    end
  end)
  option:SetScript("OnHide", function()
    option.Icon:SetAlpha(1)
  end)
  return option
end

function Auctionator.Shopping.Tab.SetupContainerRow(button, buttonHeight, buttonSpacing)
  local fontString = button:CreateFontString(nil, nil, "GameFontHighlightSmall")
  fontString:SetJustifyH("LEFT")
  fontString:SetPoint("RIGHT", button, "RIGHT", -buttonSpacing, 0)
  fontString:SetWordWrap(false)
  button.Text = fontString
  -- The retail/TBC atlases used by the modern template do not exist on the
  -- 3.3.5a client. Use native tooltip textures with Classic AH-like dark/gold
  -- tints instead of relying on atlas fallbacks.
  button.Bg = button:CreateTexture(nil, "BACKGROUND")
  button.Bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
  button.Bg:SetVertexColor(0.22, 0.20, 0.16, 0.52)
  button.Bg:SetAllPoints()

  button.Highlight = button:CreateTexture(nil, "ARTWORK")
  button.Highlight:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
  button.Highlight:SetBlendMode("ADD")
  button.Highlight:SetVertexColor(0.72, 0.55, 0.18, 0.18)
  button.Highlight:SetAllPoints()
  button.Highlight:Hide()

  button.Selected = button:CreateTexture(nil, "ARTWORK")
  button.Selected:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
  button.Selected:SetBlendMode("ADD")
  button.Selected:SetVertexColor(0.88, 0.65, 0.12, 0.34)
  button.Selected:SetAllPoints()
  button.Selected:Hide()
end
