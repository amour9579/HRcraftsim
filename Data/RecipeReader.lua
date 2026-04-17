
local _, ns = ...

ns.RecipeReader = {}

local CraftingReagentType = Enum and Enum.CraftingReagentType or {}

local function GetSlotIndex(slotIndex, reagentSlot)
  return reagentSlot.slotIndex or slotIndex
end

local function GetSlotLabel(slotIndex, reagentSlot)
  return reagentSlot.slotText or reagentSlot.name or reagentSlot.localizedName or ("선택 재료 " .. tostring(GetSlotIndex(slotIndex, reagentSlot)))
end

local function CountCandidates(reagentSlot)
  return #(reagentSlot.reagents or {})
end

local function ResolveReagentTypeName(reagentType)
  if reagentType == nil then
    return 'nil'
  end

  for key, value in pairs(CraftingReagentType) do
    if value == reagentType then
      return tostring(key)
    end
  end

  return tostring(reagentType)
end

local function ResolveCurrentRecipeContext(form)
  local order = ns:GetCurrentOrderData()
  local transaction = form and form.GetTransaction and form:GetTransaction() or nil
  local recipeInfo = form and form.GetRecipeInfo and form:GetRecipeInfo() or nil
  local recipeID = recipeInfo and recipeInfo.recipeID or nil
  local isRecraft = recipeInfo and recipeInfo.isRecraft or nil

  if order and order.spellID then
    recipeID = recipeID or order.spellID
    if isRecraft == nil then
      isRecraft = order.isRecraft
    end
  end

  if transaction and transaction.GetRecraftAllocation and isRecraft == nil then
    isRecraft = transaction:GetRecraftAllocation() ~= nil
  end

  if (not recipeInfo or not recipeInfo.recipeID) and recipeID and C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
    recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID)
  end

  if recipeInfo and not recipeInfo.recipeID and recipeID then
    recipeInfo.recipeID = recipeID
  end

  if recipeInfo and isRecraft ~= nil then
    recipeInfo.isRecraft = isRecraft
  end

  if not recipeInfo and recipeID then
    recipeInfo = {
      recipeID = recipeID,
      isRecraft = isRecraft,
      name = order and (order.outputItemName or order.spellName) or nil,
    }
  end

  return recipeInfo, order, transaction
end

local function IsRequiredSlot(reagentSlot)
  local reagentType = reagentSlot.reagentType

  if reagentType == CraftingReagentType.Basic
      or reagentType == CraftingReagentType.Reagent
      or reagentType == CraftingReagentType.Required
      or reagentType == CraftingReagentType.ModifyingReagent then
    return true
  end

  if reagentType == CraftingReagentType.Optional
      or reagentType == CraftingReagentType.Finishing
      or reagentType == CraftingReagentType.Automatic then
    return false
  end

  if reagentSlot.required or reagentSlot.isRequired == true then
    return true
  end

  local candidateCount = CountCandidates(reagentSlot)
  if candidateCount <= 1 then
    return true
  end

  if reagentSlot.isModification or reagentSlot.isOptional or reagentSlot.slotText or reagentSlot.name or reagentSlot.localizedName then
    return false
  end

  return true
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
    ns.Util:Debug('required reagent skipped, no itemID for slot', resolvedSlotIndex)
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
      ns.Util:Debug('optional reagent candidate skipped, no itemID for slot', resolvedSlotIndex)
    end
  end

  candidates = DedupeCandidates(candidates)

  if #candidates == 0 then
    ns.Util:Debug('optional slot skipped, no item candidates for slot', resolvedSlotIndex)
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
  if not form then
    ns.Util:Debug('RecipeReader failed: no schematic form')
    return nil
  end

  local recipeInfo, order, transaction = ResolveCurrentRecipeContext(form)
  if not recipeInfo or not recipeInfo.recipeID then
    ns.Util:Debug('RecipeReader failed: no recipe info', 'order=', order and tostring(order.spellID) or 'nil', 'tx=', transaction and 'yes' or 'no')
    return nil
  end

  local schematic = C_TradeSkillUI and C_TradeSkillUI.GetRecipeSchematic and C_TradeSkillUI.GetRecipeSchematic(recipeInfo.recipeID, recipeInfo.isRecraft)
  if not schematic then
    ns.Util:Debug('RecipeReader failed: no schematic for recipe', recipeInfo.recipeID, 'isRecraft=', tostring(recipeInfo.isRecraft))
    return nil
  end

  local requiredReagents = {}
  local optionalSlots = {}

  ns.Util:Debug('Reading recipe', recipeInfo.recipeID, recipeInfo.name or '', 'orderSpell=', order and tostring(order.spellID) or 'nil', 'isRecraft=', tostring(recipeInfo.isRecraft))

  for slotIndex, reagentSlot in ipairs(schematic.reagentSlotSchematics or {}) do
    local resolvedSlotIndex = GetSlotIndex(slotIndex, reagentSlot)
    local reagentType = reagentSlot.reagentType
    local candidateCount = CountCandidates(reagentSlot)
    local required = IsRequiredSlot(reagentSlot)
    local slotClass = required and 'required' or 'optional'

    ns.Util:Debug('slot', resolvedSlotIndex,
      'class', slotClass,
      'reagentType', ResolveReagentTypeName(reagentType),
      'qty', reagentSlot.quantityRequired or 1,
      'candidates', candidateCount,
      'label', GetSlotLabel(slotIndex, reagentSlot))

    if required then
      AddRequiredReagent(requiredReagents, form, slotIndex, reagentSlot)
    else
      AddOptionalSlot(optionalSlots, form, slotIndex, reagentSlot)
    end
  end

  local recipeName = recipeInfo.name
  if not recipeName and C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
    local latest = C_TradeSkillUI.GetRecipeInfo(recipeInfo.recipeID)
    recipeName = latest and latest.name or nil
  end

  return {
    recipeID = recipeInfo.recipeID,
    recipeName = recipeName or 'Unknown Recipe',
    requiredReagents = requiredReagents,
    optionalSlots = optionalSlots,
  }
end

function ns.RecipeReader:DumpCurrentRecipeToChat()
  local form = ns:GetOrderSchematicForm()
  local recipeInfo, order, transaction = ResolveCurrentRecipeContext(form)
  ns:Print('dump recipe form=' .. tostring(form and form:GetDebugName() or 'nil'))
  ns:Print('dump recipe orderSpell=' .. tostring(order and order.spellID or 'nil') .. ' isRecraft=' .. tostring(order and order.isRecraft or 'nil'))
  ns:Print('dump recipe tx=' .. tostring(transaction and 'yes' or 'no'))
  ns:Print('dump recipe recipeID=' .. tostring(recipeInfo and recipeInfo.recipeID or 'nil') .. ' name=' .. tostring(recipeInfo and recipeInfo.name or 'nil'))

  local recipeData = self:ReadCurrentOrderRecipe()
  if not recipeData then
    ns:Print('현재 주문 레시피를 읽지 못했습니다.')
    return
  end

  ns:Print('recipeID=' .. tostring(recipeData.recipeID) .. ' name=' .. tostring(recipeData.recipeName))
  ns:Print('필수 재료 수=' .. tostring(#(recipeData.requiredReagents or {})) .. ' 선택 슬롯 수=' .. tostring(#(recipeData.optionalSlots or {})))

  for i, reagent in ipairs(recipeData.requiredReagents or {}) do
    ns:Print(string.format('필수[%d] slot=%s itemID=%s qty=%s name=%s',
      i,
      tostring(reagent.slotIndex),
      tostring(reagent.itemID),
      tostring(reagent.quantity),
      tostring(reagent.name)))
  end

  for i, slot in ipairs(recipeData.optionalSlots or {}) do
    ns:Print(string.format('선택[%d] slot=%s name=%s candidates=%d',
      i,
      tostring(slot.slotIndex),
      tostring(slot.slotName),
      #(slot.candidates or {})))
  end
end
