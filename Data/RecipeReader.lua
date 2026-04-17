local _, ns = ...

ns.RecipeReader = {}

local function GetSelectedCandidateInfo(form, slotIndex, reagentSlot)
  if not form or not form.GetTransaction then
    return nil
  end

  local transaction = form:GetTransaction()
  if not transaction or not transaction.GetAllocations then
    return nil
  end

  local slotAllocations = transaction:GetAllocations(slotIndex)
  if not slotAllocations then
    return nil
  end

  for reagentIndex, reagent in ipairs(reagentSlot.reagents or {}) do
    if reagent.itemID then
      local allocation = slotAllocations:FindAllocationByReagent(reagent)
      if allocation and allocation:GetQuantity() and allocation:GetQuantity() > 0 then
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
    return
  end

  local name, icon = ns.Util:GetItemNameAndIcon(reagent.itemID)
  table.insert(results, {
    slotIndex = slotIndex,
    itemID = reagent.itemID,
    name = name,
    icon = icon,
    quantity = reagentSlot.quantityRequired or reagent.quantityRequired or 1,
  })
end

local function AddOptionalSlot(results, form, slotIndex, reagentSlot)
  local candidates = {}
  for _, reagent in ipairs(reagentSlot.reagents or {}) do
    if reagent.itemID then
      local name, icon = ns.Util:GetItemNameAndIcon(reagent.itemID)
      table.insert(candidates, {
        itemID = reagent.itemID,
        name = name,
        icon = icon,
      })
    end
  end

  if #candidates == 0 then
    return
  end

  local selected = GetSelectedCandidateInfo(form, slotIndex, reagentSlot)

  table.insert(results, {
    slotIndex = slotIndex,
    slotName = reagentSlot.slotText or reagentSlot.name or ("선택 재료 " .. tostring(slotIndex)),
    quantity = reagentSlot.quantityRequired or 1,
    candidates = candidates,
    selectedCandidateIndex = selected and selected.candidateIndex or 0,
  })
end

function ns.RecipeReader:ReadCurrentOrderRecipe()
  local form = ns:GetOrderSchematicForm()
  if not form or not form.GetRecipeInfo then
    return nil
  end

  local recipeInfo = form:GetRecipeInfo()
  if not recipeInfo or not recipeInfo.recipeID then
    return nil
  end

  local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeInfo.recipeID, recipeInfo.isRecraft)
  if not schematic then
    return nil
  end

  local requiredReagents = {}
  local optionalSlots = {}

  for slotIndex, reagentSlot in ipairs(schematic.reagentSlotSchematics or {}) do
    local reagentType = reagentSlot.reagentType

    if reagentType == ns.CONST.REAGENT_TYPE.REQUIRED then
      AddRequiredReagent(requiredReagents, form, slotIndex, reagentSlot)
    elseif reagentType == ns.CONST.REAGENT_TYPE.OPTIONAL
        or reagentType == ns.CONST.REAGENT_TYPE.FINISHING
        or reagentType == ns.CONST.REAGENT_TYPE.AUTOMATIC then
      AddOptionalSlot(optionalSlots, form, slotIndex, reagentSlot)
    end
  end

  return {
    recipeID = recipeInfo.recipeID,
    recipeName = recipeInfo.name or (C_TradeSkillUI.GetRecipeInfo(recipeInfo.recipeID) or {}).name or "Unknown Recipe",
    requiredReagents = requiredReagents,
    optionalSlots = optionalSlots,
  }
end
