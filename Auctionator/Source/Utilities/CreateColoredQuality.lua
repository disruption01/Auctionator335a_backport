function Auctionator.Utilities.CreateColoredQuality(quality)
  local qualityInfo = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
  local color = qualityInfo and qualityInfo.color or WHITE_FONT_COLOR
  local text = _G["ITEM_QUALITY" .. tostring(quality) .. "_DESC"] or tostring(quality)

  if color and color.WrapTextInColorCode then
    return color:WrapTextInColorCode(text)
  end

  -- Last-resort compatibility path for private-server clients exposing a
  -- non-standard color object.  Avoid changing the stock path above.
  local r = (qualityInfo and qualityInfo.r) or 1
  local g = (qualityInfo and qualityInfo.g) or 1
  local b = (qualityInfo and qualityInfo.b) or 1
  return string.format("|cFF%02X%02X%02X%s|r", math.floor(r*255+.5), math.floor(g*255+.5), math.floor(b*255+.5), tostring(text))
end
