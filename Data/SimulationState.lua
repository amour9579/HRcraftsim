local _, ns = ...

ns.SimulationState = {
  state = {
    enabled = false,
    recipeID = nil,
    recipeName = nil,
    requiredReagents = {},
    optionalSlots = {},
    totalCost = 0,
    missingPriceCount = 0,
  },
}

local function BuildOptionalSelectionMap(previousState)
  local map = {}
  if not previousState or not previousState.optionalSlots then
    return map
  end

  for _, slot in ipairs(previousState.optionalSlots) do
    map[slot.slotIndex] = {
      selectedItemID = slot.selectedItemID,
      selectedIndex = slot.selectedIndex,
    }
  end
  return map
end

local function ResolveSelectedCandidate(slot, previousSelection)
  if previousSelection and previousSelection.selectedItemID then
    for index, candidate in ipairs(slot.candidates or {}) do
      if candidate.itemID == previousSelection.selectedItemID then
        return index, candidate
      end
    end
  end

  local selectedIndex = slot.selectedCandidateIndex or 0
  local selectedCandidate = selectedIndex > 0 and slot.candidates[selectedIndex] or nil
  return selectedIndex, selectedCandidate
end

function ns.SimulationState:ResetFromRecipeData(recipeData, preserveSelections)
  local previousState = preserveSelections and self.state or nil
  local previousSelections = BuildOptionalSelectionMap(previousState)
  local sameRecipe = previousState and previousState.recipeID == recipeData.recipeID

  self.state.recipeID = recipeData.recipeID
  self.state.recipeName = recipeData.recipeName
  self.state.requiredReagents = {}
  self.state.optionalSlots = {}
  self.state.totalCost = 0
  self.state.missingPriceCount = 0

  for _, reagent in ipairs(recipeData.requiredReagents or {}) do
    table.insert(self.state.requiredReagents, {
      slotIndex = reagent.slotIndex,
      itemID = reagent.itemID,
      name = reagent.name,
      icon = reagent.icon,
      quantity = reagent.quantity,
      unitPrice = nil,
      subtotal = nil,
      priceSource = nil,
    })
  end

  for _, slot in ipairs(recipeData.optionalSlots or {}) do
    local previousSelection = sameRecipe and previousSelections[slot.slotIndex] or nil
    local selectedIndex, selectedCandidate = ResolveSelectedCandidate(slot, previousSelection)

    table.insert(self.state.optionalSlots, {
      slotIndex = slot.slotIndex,
      slotName = slot.slotName,
      quantity = slot.quantity,
      candidates = slot.candidates,
      selectedIndex = selectedIndex,
      selectedItemID = selectedCandidate and selectedCandidate.itemID or nil,
      selectedName = selectedCandidate and selectedCandidate.name or nil,
      unitPrice = nil,
      subtotal = nil,
      priceSource = nil,
    })
  end
end

function ns.SimulationState:SetEnabled(enabled)
  self.state.enabled = enabled and true or false
end

function ns.SimulationState:SetOptionalSelection(slotIndex, candidateIndex)
  for _, slot in ipairs(self.state.optionalSlots) do
    if slot.slotIndex == slotIndex then
      slot.selectedIndex = candidateIndex or 0
      local candidate = slot.candidates and slot.candidates[candidateIndex]
      if candidate then
        slot.selectedItemID = candidate.itemID
        slot.selectedName = candidate.name
      else
        slot.selectedItemID = nil
        slot.selectedName = nil
      end
      slot.unitPrice = nil
      slot.subtotal = nil
      slot.priceSource = nil
      return slot
    end
  end
  return nil
end
