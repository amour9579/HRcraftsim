local _, ns = ...

ns.AuctionatorProvider = {}

function ns.AuctionatorProvider:GetPriceByItemID(itemID)
  if not ns:IsAuctionatorAvailable() then
    return nil, "no_auctionator"
  end

  local vendorPrice = Auctionator.API.v1.GetVendorPriceByItemID(ns.CONST.CALLER_ID, itemID)
  if vendorPrice and vendorPrice > 0 then
    return vendorPrice, "vendor"
  end

  local auctionPrice = Auctionator.API.v1.GetAuctionPriceByItemID(ns.CONST.CALLER_ID, itemID)
  if auctionPrice and auctionPrice > 0 then
    return auctionPrice, "auction"
  end

  return nil, "missing"
end
