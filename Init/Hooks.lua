local _, ns = ...

local IsAddOnLoadedCompat = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded

ns.Hooks = {
  attached = false,
  callbacksRegistered = false,
}

local function RefreshIfEnabled()
  if ns.SimulationState.state.enabled then
    ns:RefreshSimulation()
  end
end

function ns.Hooks:Attach()
  if self.attached then
    return true
  end

  local orderDetails = ns:GetOrderDetailsFrame()
  local schematicForm = ns:GetOrderSchematicForm()
  if not orderDetails or not schematicForm then
    return false
  end

  ns:CreateMainPanel(orderDetails)

  if not self.callbacksRegistered and schematicForm.RegisterCallback and ProfessionsRecipeSchematicFormMixin and ProfessionsRecipeSchematicFormMixin.Event then
    schematicForm:RegisterCallback(ProfessionsRecipeSchematicFormMixin.Event.AllocationsModified, RefreshIfEnabled)
    schematicForm:RegisterCallback(ProfessionsRecipeSchematicFormMixin.Event.UseBestQualityModified, RefreshIfEnabled)
    self.callbacksRegistered = true
  end

  orderDetails:HookScript("OnShow", function()
    if ns.MainPanel and ns.MainPanel.toggle then
      ns.MainPanel.toggle:Show()
    end
    RefreshIfEnabled()
  end)

  orderDetails:HookScript("OnHide", function()
    if ns.MainPanel then
      ns.MainPanel:Hide()
    end
  end)

  if ns:IsAuctionatorAvailable() and Auctionator.API.v1.RegisterForDBUpdate then
    Auctionator.API.v1.RegisterForDBUpdate(ns.CONST.CALLER_ID, function()
      ns.PriceCache:InvalidateAll()
      RefreshIfEnabled()
    end)
  end

  self.attached = true
  return true
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    HRcraftsimDB = HRcraftsimDB or {
      version = ns.version,
      debug = ns.CONST.DEBUG_DEFAULT,
    }
    ns.db = HRcraftsimDB

    local function tryAttach()
      if ns.Hooks:Attach() then
        return
      end
      C_Timer.After(1, tryAttach)
    end

    if IsAddOnLoadedCompat and IsAddOnLoadedCompat("Blizzard_Professions") then
      tryAttach()
    else
      local waitFrame = CreateFrame("Frame")
      waitFrame:RegisterEvent("ADDON_LOADED")
      waitFrame:SetScript("OnEvent", function(_, _, addonName)
        if addonName == "Blizzard_Professions" then
          tryAttach()
        end
      end)
    end
  end
end)
