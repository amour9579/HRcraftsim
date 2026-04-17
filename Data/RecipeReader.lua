local _, ns = ...

ns.RecipeReader = {}

local function GetSlotIndex(slotIndex, reagentSlot)
  return reagentSlot.slotIndex or slotIndex
end

local function GetSlotLabel(slotIndex, reagentSlot)
  return reagentSlot.slotText or reagentSlot.name or reagentSlot.localizedName or ("선택 재료 " .. tostring(GetSlotIndex(slotIndex, reagentSlot)))
end

local function BuildCandidateFromReagent(reagent, fallbackQuantity)
  if not reagent or not reagent.itemID then
    return nil
  end

  local name, icon = ns.Util:GetItemNameAndIcon(reagent.itemID)
  return {
    itemID = reagent.itemID,
    name = name,
    icon = icon,
    quantity = reagent.quantityRequired or fallbackQuantity or 1,
  }
end

local function DedupeCandidates(candidates)
  local result = {}
  local seen = {}

  for _, candidate in ipairs(candidates) do
    if candidate and candidate.itemID and not seen[candidate.itemID] then
      seen[candidate.itemID] = true
      table.insert(result, candidate)
    end
  end

  return result
end

local function GetSlotAllocations(form, slotIndex)
  if not form or not form.GetTransaction then
    return nil
  end

  local transaction = form:GetTransaction()
  if not transaction or not transaction.GetAllocations then
    return nil
  end

  return transaction:GetAllocations(slotIndex)
end

local function GetSelectedCandidateInfo(form, slotIndex, reagentSlot)
  local resolvedSlotIndex = GetSlotIndex(slotIndex, reagentSlot)
  local slotAllocations = GetSlotAllocations(form, resolvedSlotIndex)
  if not slotAllocations then
    return nil
  end

  for reagentIndex, reagent in ipairs(reagentSlot.reagents or {}) do
    if reagent.itemID and slotAllocations.FindAllocationByReagent then
      local allocation = slotAllocations:FindAllocationByReagent(reagent)
      if allocation and allocation.GetQuantity and allocation:GetQuantity() and allocation:GetQuantity() > 0 then
        local name, icon = ns.Util:GetItemNameAndIcon(reagent.itemID)
        return {
          candidateIndex = reagentIndex,
          itemID = reagent.itemID,
          name = name,
          icon = icon,
        }
      end
    end
  end

  return nil
end

local function AddRequiredReagent(results, form, slotIndex, reagentSlot)
  local selected = GetSelectedCandidateInfo(form, slotIndex, reagentSlot)
  local resolvedSlotIndex = GetSlotIndex(slotIndex, reagentSlot)
  local reagent = nil

  if selected then
    for _, candidate in ipairs(reagentSlot.reagents or {}) do
      if candidate.itemID == selected.itemID then
        reagent = candidate
        break
      end
    end
  else
    reagent = reagentSlot.reagents and reagentSlot.reagents[1]
  end

  if not reagent or not reagent.itemID then
    ns.Util:Debug("required reagent skipped, no itemID for slot", resolvedSlotIndex)
    return
  end

  local name, icon = ns.Util:GetItemNameAndIcon(reagent.itemID)
  table.insert(results, {
    slotIndex = resolvedSlotIndex,
    itemID = reagent.itemID,
    name = name,
    icon = icon,
    quantity = reagentSlot.quantityRequired or reagent.quantityRequired or 1,
  })
end

local function AddOptionalSlot(results, form, slotIndex, reagentSlot)
  local candidates = {}
  local resolvedSlotIndex = GetSlotIndex(slotIndex, reagentSlot)

  for _, reagent in ipairs(reagentSlot.reagents or {}) do
    local candidate = BuildCandidateFromReagent(reagent, reagentSlot.quantityRequired)
    if candidate then
      table.insert(candidates, candidate)
    else
      ns.Util:Debug("optional reagent candidate skipped, no itemID for slot", resolvedSlotIndex)
    end
  end

  candidates = DedupeCandidates(candidates)

  if #candidates == 0 then
    ns.Util:Debug("optional slot skipped, no item candidates for slot", resolvedSlotIndex)
    return
  end

  local selected = GetSelectedCandidateInfo(form, slotIndex, reagentSlot)

  table.insert(results, {
    slotIndex = resolvedSlotIndex,
    slotName = GetSlotLabel(slotIndex, reagentSlot),
    quantity = reagentSlot.quantityRequired or 1,
    candidates = candidates,
    selectedCandidateIndex = selected and selected.candidateIndex or 0,
  })
end

function ns.RecipeReader:ReadCurrentOrderRecipe()
  local form = ns:GetOrderSchematicForm()
  if not form or not form.GetRecipeInfo then
    ns.Util:Debug("RecipeReader failed: no schematic form")
    return nil
  end

  local recipeInfo = form:GetRecipeInfo()
  if not recipeInfo or not recipeInfo.recipeID then
    ns.Util:Debug("RecipeReader failed: no recipe info")
    return nil
  end

  local schematic = C_TradeSkillUI and C_TradeSkillUI.GetRecipeSchematic and C_TradeSkillUI.GetRecipeSchematic(recipeInfo.recipeID, recipeInfo.isRecraft)
  if not schematic then
    ns.Util:Debug("RecipeReader failed: no schematic for recipe", recipeInfo.recipeID)
    return nil
  end

  local requiredReagents = {}
  local optionalSlots = {}

  ns.Util:Debug("Reading recipe", recipeInfo.recipeID, recipeInfo.name or "")

  for slotIndex, reagentSlot in ipairs(schematic.reagentSlotSchematics or {}) do
    local reagentType = reagentSlot.reagentType
    local resolvedSlotIndex = GetSlotIndex(slotIndex, reagentSlot)
    ns.Util:Debug("slot", resolvedSlotIndex, "type", reagentType, "qty", reagentSlot.quantityRequired or 1)

    if reagentType == ns.CONST.REAGENT_TYPE.REQUIRED then
      AddRequiredReagent(requiredReagents, form, slotIndex, reagentSlot)
    elseif reagentType == ns.CONST.REAGENT_TYPE.OPTIONAL
        or reagentType == ns.CONST.REAGENT_TYPE.FINISHING
        or reagentType == ns.CONST.REAGENT_TYPE.AUTOMATIC then
      AddOptionalSlot(optionalSlots, form, slotIndex, reagentSlot)
    else
      ns.Util:Debug("slot ignored, unknown reagentType", reagentType)
    end
  end

  return {
    recipeID = recipeInfo.recipeID,
    recipeName = recipeInfo.name or (C_TradeSkillUI.GetRecipeInfo(recipeInfo.recipeID) or {}).name or "Unknown Recipe",
    requiredReagents = requiredReagents,
    optionalSlots = optionalSlots,
  }
end
