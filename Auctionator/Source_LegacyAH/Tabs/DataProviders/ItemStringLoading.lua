AuctionatorItemStringLoadingMixin = {}

-- Some 3.3.5a-derived clients (notably Whitemane) can return a valid auction
-- hyperlink/icon before GetItemInfo() has populated the local item cache.  The
-- stock 3.3.5a client normally fills that cache quickly, but relying solely on
-- it can leave the Shopping Name column blank on those clients.  Use the
-- auction hyperlink itself as a conservative display-name fallback; the normal
-- GetItemInfo path below still replaces it with the full/coloured name once
-- available.
local function Auctionator335_EnsureBasicItemDisplay(entry)
  if entry.itemName ~= nil and entry.itemName ~= "" then
    return
  end

  local link = entry.itemLink
  local quality

  if (not link or link == "") and entry.entries and entry.entries[1] then
    local first = entry.entries[1]
    link = first.itemLink
    if first.info then
      quality = first.info[4] -- native 3.3.5a GetAuctionItemInfo quality
    end
  end

  if link and link ~= "" then
    entry.itemLink = link
    local name = link:match("%[(.-)%]")
    if name and name ~= "" then
      entry.name = entry.name or name
      local r, g, b, hex
      if quality ~= nil and GetItemQualityColor then
        r, g, b, hex = GetItemQualityColor(quality)
      end
      if hex and hex ~= "" then
        hex = tostring(hex):gsub("^|c", ""):gsub("^#", "")
        entry.itemName = "|c" .. hex .. name .. "|r"
      else
        entry.itemName = name
      end
    end
  end
end

function AuctionatorItemStringLoadingMixin:OnLoad()
  self:SetOnEntryProcessedCallback(function(entry)
    Auctionator335_EnsureBasicItemDisplay(entry)

    local itemID = C_Item.GetItemInfoInstant(entry.itemString)
    if itemID == nil then
      -- The auction link is still enough for display on legacy/private cores.
      -- Do not manufacture an Item object with a nil ID.
      self:SetDirty()
      return
    end

    local item = Item:CreateFromItemID(itemID)
    local complete = false
    item:ContinueOnItemLoad(function()
      local itemInfo = { C_Item.GetItemInfo(entry.itemString) }
      if itemInfo[1] ~= nil then
        self:ProcessItemString(entry, itemInfo)
      else
        -- Whitemane can keep GetItemInfo uncached while GetAuctionItemLink is
        -- already valid. Keep the hyperlink-derived name instead of blanking
        -- the Name column.
        Auctionator335_EnsureBasicItemDisplay(entry)
        self:SetDirty()
      end
      complete = true
    end)
    if complete then
      self:NotifyCacheUsed()
    end
  end)
end

function AuctionatorItemStringLoadingMixin:ProcessItemString(rowEntry, itemInfo)
  local name = itemInfo[Auctionator.Constants.ITEM_INFO.NAME]
  local qualityColor = ITEM_QUALITY_COLORS[itemInfo[Auctionator.Constants.ITEM_INFO.RARITY]].color
  local class = itemInfo[Auctionator.Constants.ITEM_INFO.CLASS]

  rowEntry.itemLink = itemInfo[Auctionator.Constants.ITEM_INFO.LINK]

  rowEntry.name = name
  if class == Enum.ItemClass.Weapon or class == Enum.ItemClass.Armor then
    local itemLevel = GetDetailedItemLevelInfo(rowEntry.itemLink)
    rowEntry.name = rowEntry.name .. " (" .. itemLevel .. ")"
  end
  rowEntry.itemName = qualityColor:WrapTextInColorCode(rowEntry.name)

  -- Keep the texture obtained from GetAuctionItemInfo if GetItemInfo has not
  -- populated its cache yet. Recipes/gems are common examples on 3.3.5a.
  rowEntry.iconTexture = itemInfo[Auctionator.Constants.ITEM_INFO.TEXTURE] or rowEntry.iconTexture
  if GetItemIcon then
    local itemID = tonumber((rowEntry.itemString or rowEntry.itemLink or ""):match("item:(%d+)"))
    local legacyTexture = itemID and GetItemIcon(itemID)
    if legacyTexture then
      rowEntry.iconTexture = legacyTexture
    end
  end

  rowEntry.noneAvailable = rowEntry.totalQuantity == 0

  self:SetDirty()
end
