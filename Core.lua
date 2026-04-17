local addonName, ns = ...

HRcraftsim = ns
ns.name = addonName
ns.version = "0.1.1"
ns.db = nil
ns.initialized = false

function ns:Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffHRcraftsim|r " .. tostring(msg))
end

function ns:IsAuctionatorAvailable()
  return Auctionator and Auctionator.API and Auctionator.API.v1
end

function ns:GetOrderDetailsFrame()
  return ProfessionsFrame
    and ProfessionsFrame.OrdersPage
    and ProfessionsFrame.OrdersPage.OrderView
    and ProfessionsFrame.OrdersPage.OrderView.OrderDetails
end

function ns:GetOrderSchematicForm()
  local orderDetails = self:GetOrderDetailsFrame()
  return orderDetails and orderDetails.SchematicForm or nil
end

function ns:GetCurrentOrderRecipeInfo()
  local form = self:GetOrderSchematicForm()
  if not form or not form.GetRecipeInfo then
    return nil
  end
  return form:GetRecipeInfo()
end

function ns:RefreshSimulation()
  if not self.MainPanel or not self.MainPanel:IsShown() then
    return
  end

  local recipeData = self.RecipeReader:ReadCurrentOrderRecipe()
  if not recipeData then
    self.MainPanel:SetStatus("주문 제작 레시피를 읽을 수 없습니다.")
    self.MainPanel:RenderEmpty()
    return
  end

  self.SimulationState:ResetFromRecipeData(recipeData, true)
  self.PriceCache:PopulateSimulationPrices(self.SimulationState.state)
  self.CostEngine:Calculate(self.SimulationState.state)
  self.MainPanel:Render(self.SimulationState.state)
end

function ns:RecalculateAndRender()
  self.PriceCache:PopulateSimulationPrices(self.SimulationState.state)
  self.CostEngine:Calculate(self.SimulationState.state)
  if self.MainPanel and self.MainPanel:IsShown() then
    self.MainPanel:Render(self.SimulationState.state)
  end
end

SLASH_HRCRAFTSIM1 = "/hrcs"
SlashCmdList.HRCRAFTSIM = function(msg)
  msg = strtrim((msg or ""):lower())

  if msg == "debug" then
    ns.db.debug = not ns.db.debug
    ns:Print("디버그 모드: " .. (ns.db.debug and "ON" or "OFF"))
    return
  end

  if msg == "refresh" then
    ns:RefreshSimulation()
    ns:Print("시뮬레이션 새로고침")
    return
  end

  ns:Print("명령어: /hrcs debug, /hrcs refresh")
end
