local _, ns = ...

ns.CostEngine = {}

function ns.CostEngine:Calculate(state)
  local total = 0
  local missing = 0

  for _, reagent in ipairs(state.requiredReagents or {}) do
    if reagent.unitPrice and reagent.quantity then
      reagent.subtotal = reagent.unitPrice * reagent.quantity
      total = total + reagent.subtotal
    else
      reagent.subtotal = nil
      missing = missing + 1
    end
  end

  for _, slot in ipairs(state.optionalSlots or {}) do
    if slot.selectedItemID then
      if slot.unitPrice and slot.quantity then
        slot.subtotal = slot.unitPrice * slot.quantity
        total = total + slot.subtotal
      else
        slot.subtotal = nil
        missing = missing + 1
      end
    else
      slot.subtotal = nil
    end
  end

  state.totalCost = total
  state.missingPriceCount = missing
  state.isPartial = missing > 0
  return total, missing
end
