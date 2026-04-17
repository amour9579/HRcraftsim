local _, ns = ...

ns.AuctionatorProvider = {}

local function SafeAuctionatorCall(fn, ...)
  if type(fn) ~= "function" then
    return nil
  end

  local ok, value = pcall(fn, ...)
  if ok then
    return value
  end

  ns.Util:Debug("Auctionator API call failed:", value)
  return nil
end

function ns.AuctionatorProvider:GetPriceByItemID(itemID)
  if not ns:IsAuctionatorAvailable() then
    return nil, "no_auctionator"
  end

  local api = Auctionator.API.v1

  local vendorPrice = SafeAuctionatorCall(api.GetVendorPriceByItemID, ns.CONST.CALLER_ID, itemID)
  if vendorPrice and vendorPrice > 0 then
    return vendorPrice, "vendor"
  end

  local auctionPrice = SafeAuctionatorCall(api.GetAuctionPriceByItemID, ns.CONST.CALLER_ID, itemID)
  if auctionPrice and auctionPrice > 0 then
    return auctionPrice, "auction"
  end

  return nil, "missing"
end
