local _, ns = ...

ns.Hooks = {
  attached = false,
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

  if schematicForm.RegisterCallback then
    schematicForm:RegisterCallback(ProfessionsRecipeSchematicFormMixin.Event.AllocationsModified, RefreshIfEnabled)
    schematicForm:RegisterCallback(ProfessionsRecipeSchematicFormMixin.Event.UseBestQualityModified, RefreshIfEnabled)
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

  if ns:IsAuctionatorAvailable() then
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
    }
    ns.db = HRcraftsimDB

    local function tryAttach()
      if ns.Hooks:Attach() then
        return
      end
      C_Timer.After(1, tryAttach)
    end

    if IsAddOnLoaded("Blizzard_Professions") then
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
