local addonName, ns = ...

HRcraftsim = ns
ns.name = addonName
ns.version = "0.1.3"
ns.db = nil
ns.initialized = false

function ns:Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffHRcraftsim|r " .. tostring(msg))
end

function ns:IsAuctionatorAvailable()
  return Auctionator and Auctionator.API and Auctionator.API.v1
end

function ns:GetCustomerOrdersFrame()
  return _G.ProfessionsCustomerOrdersFrame
end

function ns:GetOrderDetailsFrame()
  local retailOrderDetails = _G.ProfessionsFrame
    and _G.ProfessionsFrame.OrdersPage
    and _G.ProfessionsFrame.OrdersPage.OrderView
    and _G.ProfessionsFrame.OrdersPage.OrderView.OrderDetails

  if retailOrderDetails then
    return retailOrderDetails
  end

  local customerOrdersFrame = self:GetCustomerOrdersFrame()
  if customerOrdersFrame and customerOrdersFrame.Form then
    return customerOrdersFrame.Form
  end

  return nil
end

function ns:GetOrderSchematicForm()
  local orderDetails = self:GetOrderDetailsFrame()
  if not orderDetails then
    return nil
  end

  if orderDetails.SchematicForm then
    return orderDetails.SchematicForm
  end

  if orderDetails.GetTransaction or orderDetails.GetRecipeInfo then
    return orderDetails
  end

  return nil
end

function ns:GetCurrentOrderData()
  local retailOrder = _G.ProfessionsFrame
    and _G.ProfessionsFrame.OrdersPage
    and _G.ProfessionsFrame.OrdersPage.OrderView
    and _G.ProfessionsFrame.OrdersPage.OrderView.order

  if retailOrder then
    return retailOrder
  end

  local customerOrdersFrame = self:GetCustomerOrdersFrame()
  if customerOrdersFrame and customerOrdersFrame.order then
    return customerOrdersFrame.order
  end

  return nil
end

function ns:GetCurrentOrderRecipeInfo()
  local form = self:GetOrderSchematicForm()
  if form and form.GetRecipeInfo then
    local info = form:GetRecipeInfo()
    if info and info.recipeID then
      return info
    end
  end

  local order = self:GetCurrentOrderData()
  if order and order.spellID and C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
    local info = C_TradeSkillUI.GetRecipeInfo(order.spellID)
    if info then
      info.isRecraft = order.isRecraft or info.isRecraft
      return info
    end
    return { recipeID = order.spellID, isRecraft = order.isRecraft, name = order.outputItemName }
  end

  return nil
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

  if msg == 'refresh' then
    ns:RefreshSimulation()
    ns:Print('시뮬레이션 새로고침')
    return
  end

  if msg == 'show' then
    ns.Hooks:StartWatch()
    local parent = ns:GetOrderDetailsFrame()
    local panel = ns:CreateMainPanel(parent)
    panel:Dock(parent)
    panel:Show()
    ns.SimulationState:SetEnabled(true)
    ns:RefreshSimulation()
    ns:Print('패널 표시')
    return
  end

  if msg == 'dock' then
    local parent = ns:GetOrderDetailsFrame()
    local panel = ns:CreateMainPanel(parent)
    panel:Dock(parent)
    ns:Print('패널을 주문 제작 창 오른쪽에 배치')
    return
  end

  if msg == 'center' then
    local panel = ns:CreateMainPanel(ns:GetOrderDetailsFrame())
    panel:CenterOnScreen()
    panel:Show()
    ns:Print('패널을 화면 중앙에 배치')
    return
  end

  if msg == 'parent' then
    local parent = ns:GetOrderDetailsFrame()
    local form = ns:GetOrderSchematicForm()
    ns:Print('parent=' .. tostring(parent and parent:GetDebugName() or 'nil'))
    ns:Print('form=' .. tostring(form and form:GetDebugName() or 'nil'))
    return
  end

  if msg == 'dumprecipe' then
    ns.RecipeReader:DumpCurrentRecipeToChat()
    return
  end

  ns:Print('명령어: /hrcs debug, /hrcs refresh, /hrcs show, /hrcs dock, /hrcs center, /hrcs parent, /hrcs dumprecipe')
end
