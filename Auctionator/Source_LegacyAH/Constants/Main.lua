Auctionator.Constants.MaxResultsPerPage = 50
Auctionator.Constants.ITEM_LEVEL_THRESHOLD = 0

Auctionator.Constants.AuctionItemInfo = {
  Buyout = 9,
  Quantity = 3,
  Owner = 12,
  ItemID = 14, -- injected from GetAuctionItemLink by the 3.3.5a wrapper
  Level = 6,
  MinBid = 7,
  BidAmount = 10,
  Bidder = 11,
  SaleStatus = 13,
}

Auctionator.Constants.PriceIncreaseWarningDuration = 5
Auctionator.Constants.PriceIncreaseWarningThreshold = 40

--FIXME: Added to correct Blizzard error
if CASTING_BAR_ALPHA_STEP == nil then
  CASTING_BAR_ALPHA_STEP = 0.05
end
