-- Legacy Auction House bridges for stock 3.3.5a.
if not PostAuction then
  function PostAuction(bid,buyout,duration,stackSize,numStacks)
    local runtime=duration
    if duration==12 then runtime=1 elseif duration==24 then runtime=2 elseif duration==48 then runtime=3 end
    return StartAuction(bid or 0,buyout or 0,runtime or 3,stackSize or 1,numStacks or 1)
  end
end
if not GetAuctionDeposit then
  -- Auctionator's LegacyAH code calls the Classic-era compatibility signature:
  --   GetAuctionDeposit(duration, bid, buyout, stackSize, numStacks)
  -- The native 3.3.5a API is CalculateAuctionDeposit(runTime, stackSize, numStacks)
  -- (some cores only consume runTime).  The old bridge accepted only three
  -- arguments, so the bid/buyout copper values were accidentally interpreted as
  -- stack sizes and produced gigantic deposits, which in turn disabled Post.
  function GetAuctionDeposit(duration, bid, buyout, stackSize, numStacks)
    local runtime=duration
    if duration==12 then runtime=1 elseif duration==24 then runtime=2 elseif duration==48 then runtime=3 end

    if CalculateAuctionDeposit then
      local ok, deposit = pcall(CalculateAuctionDeposit, runtime or 3, stackSize or 1, numStacks or 1)
      if ok and type(deposit) == "number" then
        return deposit
      end

      -- A few 3.3.5a cores expose the older one-argument form.
      ok, deposit = pcall(CalculateAuctionDeposit, runtime or 3)
      if ok and type(deposit) == "number" then
        return deposit
      end
    end
    return 0
  end
end
SortAuctionSetSort=SortAuctionSetSort or function() end
SortAuctionApplySort=SortAuctionApplySort or function() end
ApplySort=ApplySort or function() end
