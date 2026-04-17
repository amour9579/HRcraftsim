local _, ns = ...

ns.PriceCache = {
  cache = {},
}

function ns.PriceCache:InvalidateAll()
  wipe(self.cache)
end

function ns.PriceCache:Get(itemID)
  return self.cache[itemID]
end

function ns.PriceCache:Set(itemID, price, source)
  self.cache[itemID] = {
    price = price,
    source = source,
    ts = GetTime(),
  }
  return self.cache[itemID]
end

function ns.PriceCache:GetOrFetch(itemID)
  if not itemID then
    return nil, "missing"
  end

  local cached = self:Get(itemID)
  if cached then
    return cached.price, cached.source
  end

  local price, source = ns.AuctionatorProvider:GetPriceByItemID(itemID)
  if price then
    self:Set(itemID, price, source)
  end
  return price, source
end

function ns.PriceCache:PopulateSimulationPrices(simulation)
  for _, reagent in ipairs(simulation.requiredReagents or {}) do
    reagent.unitPrice, reagent.priceSource = self:GetOrFetch(reagent.itemID)
  end

  for _, slot in ipairs(simulation.optionalSlots or {}) do
    if slot.selectedItemID then
      slot.unitPrice, slot.priceSource = self:GetOrFetch(slot.selectedItemID)
    end
  end
end
