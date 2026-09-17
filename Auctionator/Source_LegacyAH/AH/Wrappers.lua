-- query = {
--   searchString -> string
--   minLevel -> int?
--   maxLevel -> int?
--   itemClassFilters -> itemClassFilter[]
--   isExact -> boolean?
-- }
function Auctionator.AH.QueryAuctionItems(query)
  Auctionator.AH.Internals.scan:StartQuery(query, 0, -1)
end

function Auctionator.AH.QueryAndFocusPage(query, page)
  Auctionator.AH.Internals.scan:StartQuery(query, page, page)
end

function Auctionator.AH.GetCurrentPage()
  return Auctionator.AH.Internals.scan:GetCurrentPage()
end

function Auctionator.AH.AbortQuery()
  Auctionator.AH.Internals.scan:AbortQuery()
end

-- Event ThrottleUpdate will fire whenever the state changes
function Auctionator.AH.IsNotThrottled()
  local t = Auctionator.AH.Internals.throttling
  if t and t.AnyWaiting then return not t:AnyWaiting() end
  return t == nil or t:IsReady()
end

function Auctionator.AH.GetAuctionItemSubClasses(classID)
  return { GetAuctionItemSubClasses(classID) }
end

function Auctionator.AH.PlaceAuctionBid(...)
  Auctionator.AH.Internals.throttling:BidPlaced()
  PlaceAuctionBid("list", ...)
end

function Auctionator.AH.PostAuction(...)
  Auctionator.AH.Internals.throttling:AuctionsPosted()
  PostAuction(...)
end

-- view is a string and must be "list", "owner" or "bidder"
function Auctionator.AH.DumpAuctions(view)
  local auctions = {}
  for index = 1, GetNumAuctionItems(view) do
    local auctionInfo = { GetAuctionItemInfo(view, index) }
    local itemLink = GetAuctionItemLink(view, index)
    auctionInfo[Auctionator.Constants.AuctionItemInfo.ItemID] = C_Item.GetItemInfoInstant(itemLink)
    local timeLeft = GetAuctionItemTimeLeft(view, index)
    local entry = {
      info = auctionInfo,
      itemLink = itemLink,
      -- 3.3.5a exposes the item icon directly as return #2. Keep it outside
      -- the generic info array too so later grouping/cache passes can't lose it.
      iconTexture = auctionInfo[2],
      timeLeft = timeLeft - 1, --Offset to match Retail time parameters
      index = index,
    }
    table.insert(auctions, entry)
  end
  return auctions
end

function Auctionator.AH.CancelAuction(auction)
  local nativeCancelAuction = _G.CancelAuction
  if type(nativeCancelAuction) ~= "function" or type(auction) ~= "table" then
    return false
  end

  local function Matches(index)
    if not index or index < 1 or index > GetNumAuctionItems("owner") then
      return false
    end

    local info = { GetAuctionItemInfo("owner", index) }
    local itemLink = GetAuctionItemLink("owner", index)
    if not itemLink then
      return false
    end

    local stackPrice = info[Auctionator.Constants.AuctionItemInfo.Buyout] or 0
    local stackSize = info[Auctionator.Constants.AuctionItemInfo.Quantity] or 0
    local bidAmount = info[Auctionator.Constants.AuctionItemInfo.BidAmount] or 0
    local saleStatus = info[Auctionator.Constants.AuctionItemInfo.SaleStatus]

    return saleStatus ~= 1 and
      (auction.bidAmount or 0) == bidAmount and
      (auction.stackPrice or 0) == stackPrice and
      (auction.stackSize or 0) == stackSize and
      Auctionator.Search.GetCleanItemLink(itemLink) == Auctionator.Search.GetCleanItemLink(auction.itemLink)
  end

  local function CancelIndex(index)
    -- Keep the protected action as close as possible to the mouse/button
    -- hardware event.  Issue the native action first; only enter Auctionator's
    -- waiting state once the call has actually been made.  This also avoids a
    -- misleading countdown when a private-server client blocks the action.
    nativeCancelAuction(index)
    if Auctionator.AH.Internals.throttling and Auctionator.AH.Internals.throttling.AuctionCancelled then
      Auctionator.AH.Internals.throttling:AuctionCancelled()
    end

    -- Most 3.3.5a cores fire AUCTION_OWNED_LIST_UPDATE on their own. A small
    -- delayed owner refresh covers cores that require an explicit refresh,
    -- without hammering the server every frame.
    if C_Timer and C_Timer.After and GetOwnerAuctionItems then
      C_Timer.After(0.5, function()
        if AuctionFrame == nil or AuctionFrame:IsShown() then
          GetOwnerAuctionItems()
        end
      end)
    end
    return true
  end

  if Matches(auction.ownerIndex) then
    return CancelIndex(auction.ownerIndex)
  end

  -- The owner indices can shift after another auction changes. Fall back to a
  -- fresh identity match rather than cancelling the wrong row.
  for index = 1, GetNumAuctionItems("owner") do
    if Matches(index) then
      auction.ownerIndex = index
      return CancelIndex(index)
    end
  end

  return false
end
