local _, ns = ...

local IsAddOnLoadedCompat = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded

ns.Hooks = {
  attached = false,
  callbacksRegistered = false,
  ticker = nil,
  frameHooksRegistered = false,
}

local function RefreshIfEnabled()
  if ns.SimulationState.state.enabled then
    ns:RefreshSimulation()
  end
end

local function StopTicker()
  if ns.Hooks.ticker then
    ns.Hooks.ticker:Cancel()
    ns.Hooks.ticker = nil
  end
end

function ns.Hooks:Attach()
  local orderDetails = ns:GetOrderDetailsFrame()
  local schematicForm = ns:GetOrderSchematicForm()

  if not orderDetails or not schematicForm then
    ns.Util:Debug('Attach pending: orderDetails or schematicForm missing', tostring(orderDetails), tostring(schematicForm))
    return false
  end

  ns.Util:Debug('Attach target parent', orderDetails:GetDebugName())
  ns.Util:Debug('Attach target form', schematicForm:GetDebugName())

  ns:CreateMainPanel(orderDetails)

  if not self.callbacksRegistered and schematicForm.RegisterCallback and ProfessionsRecipeSchematicFormMixin and ProfessionsRecipeSchematicFormMixin.Event then
    schematicForm:RegisterCallback(ProfessionsRecipeSchematicFormMixin.Event.AllocationsModified, RefreshIfEnabled)
    schematicForm:RegisterCallback(ProfessionsRecipeSchematicFormMixin.Event.UseBestQualityModified, RefreshIfEnabled)
    self.callbacksRegistered = true
    ns.Util:Debug('Schematic callbacks registered')
  end

  if not self.frameHooksRegistered then
    orderDetails:HookScript('OnShow', function()
      ns.Util:Debug('OrderDetails/Form OnShow')
      if ns.MainPanel then
        ns.MainPanel:Dock(orderDetails)
      end
      RefreshIfEnabled()
    end)

    orderDetails:HookScript('OnHide', function()
      if ns.MainPanel then
        ns.MainPanel:Hide()
      end
    end)

    local professionsFrame = _G.ProfessionsFrame
    if professionsFrame then
      professionsFrame:HookScript('OnShow', function()
        ns.Util:Debug('ProfessionsFrame OnShow')
        ns.Hooks:StartWatch()
      end)
    end

    local customerOrdersFrame = ns:GetCustomerOrdersFrame()
    if customerOrdersFrame then
      customerOrdersFrame:HookScript('OnShow', function()
        ns.Util:Debug('ProfessionsCustomerOrdersFrame OnShow')
        ns.Hooks:StartWatch()
      end)
    end

    self.frameHooksRegistered = true
  end

  if ns:IsAuctionatorAvailable() and Auctionator.API and Auctionator.API.v1 and Auctionator.API.v1.RegisterForDBUpdate and not self.auctionatorRegistered then
    Auctionator.API.v1.RegisterForDBUpdate(ns.CONST.CALLER_ID, function()
      ns.PriceCache:InvalidateAll()
      RefreshIfEnabled()
    end)
    self.auctionatorRegistered = true
  end

  self.attached = true
  StopTicker()
  ns.Util:Debug('Attach success')
  return true
end

function ns.Hooks:StartWatch()
  if self.attached then
    if ns.MainPanel then
      ns.MainPanel:Dock(ns:GetOrderDetailsFrame())
    end
    return
  end

  if self:Attach() then
    return
  end

  if self.ticker then
    return
  end

  ns.Util:Debug('Starting attach watch ticker')
  self.ticker = C_Timer.NewTicker(0.5, function()
    if ns.Hooks:Attach() then
      StopTicker()
    end
  end, 20)
end

local eventFrame = CreateFrame('Frame')
eventFrame:RegisterEvent('PLAYER_LOGIN')
eventFrame:SetScript('OnEvent', function(_, event)
  if event ~= 'PLAYER_LOGIN' then
    return
  end

  HRcraftsimDB = HRcraftsimDB or {
    version = ns.version,
    debug = ns.CONST.DEBUG_DEFAULT,
  }
  ns.db = HRcraftsimDB

  local function onProfessionsReady()
    ns.Util:Debug('Blizzard_Professions ready')
    ns.Hooks:StartWatch()

    if _G.ProfessionsFrame then
      _G.ProfessionsFrame:HookScript('OnShow', function()
        ns.Hooks:StartWatch()
      end)
    end

    if ns:GetCustomerOrdersFrame() then
      ns:GetCustomerOrdersFrame():HookScript('OnShow', function()
        ns.Hooks:StartWatch()
      end)
    end
  end

  if IsAddOnLoadedCompat and IsAddOnLoadedCompat('Blizzard_Professions') then
    onProfessionsReady()
  else
    local waitFrame = CreateFrame('Frame')
    waitFrame:RegisterEvent('ADDON_LOADED')
    waitFrame:SetScript('OnEvent', function(_, _, addonName)
      if addonName == 'Blizzard_Professions' then
        onProfessionsReady()
      end
    end)
  end
end)
