local _, ns = ...

ns.MainPanel = nil

local function RaiseAbove(frame, strata, level)
  if not frame then
    return
  end
  frame:SetFrameStrata(strata or 'DIALOG')
  frame:SetFrameLevel(level or 1200)
end

local function IsUsableAnchor(anchorFrame, panel)
  if not anchorFrame or anchorFrame == panel then
    return false
  end
  if type(anchorFrame.IsForbidden) == 'function' and anchorFrame:IsForbidden() then
    return false
  end
  if type(anchorFrame.IsObjectType) == 'function' and not anchorFrame:IsObjectType('Frame') then
    return false
  end
  return true
end

local function PositionPanel(panel, anchorFrame)
  panel.anchorFrame = anchorFrame
  panel:ClearAllPoints()
  panel:SetParent(UIParent)
  panel:SetClampedToScreen(true)
  panel:SetSize(ns.CONST.PANEL_WIDTH, ns.CONST.PANEL_HEIGHT)

  if IsUsableAnchor(anchorFrame, panel) and anchorFrame.GetRight and anchorFrame:IsShown() then
    panel:SetPoint('TOPLEFT', anchorFrame, 'TOPRIGHT', 12, -8)
  else
    panel:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
  end
end

function ns:CreateMainPanel(parent)
  if self.MainPanel then
    PositionPanel(self.MainPanel, parent)
    return self.MainPanel
  end

  local panel = CreateFrame('Frame', 'HRcraftsimMainPanel', UIParent, 'BackdropTemplate')
  RaiseAbove(panel, 'DIALOG', 1900)
  panel:SetMovable(true)
  panel:EnableMouse(true)
  panel:RegisterForDrag('LeftButton')
  panel:SetClampedToScreen(true)
  panel:SetScript('OnDragStart', panel.StartMoving)
  panel:SetScript('OnDragStop', function(self)
    self:StopMovingOrSizing()
  end)

  ns.Util:CreateBackground(panel)
  PositionPanel(panel, parent)
  panel:Hide()

  panel.title = ns.Util:CreateLabel(panel, 'HRcraftsim', 'TOPLEFT', panel, 'TOPLEFT', 10, -10, 'GameFontHighlightLarge')
  panel.meta = ns.Util:CreateLabel(panel, '기준: 전량 구매 / 가격 소스: Auctionator', 'TOPLEFT', panel.title, 'BOTTOMLEFT', 0, -4, 'GameFontDisableSmall')

  panel.closeButton = CreateFrame('Button', nil, panel, 'UIPanelCloseButton')
  panel.closeButton:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', -3, -3)
  panel.closeButton:SetScript('OnClick', function()
    panel:Hide()
    ns.SimulationState:SetEnabled(false)
  end)

  panel.refreshButton = CreateFrame('Button', nil, panel, 'UIPanelButtonTemplate')
  panel.refreshButton:SetSize(60, 20)
  panel.refreshButton:SetPoint('TOPRIGHT', panel.closeButton, 'TOPLEFT', -6, -2)
  panel.refreshButton:SetText('새로고침')
  panel.refreshButton:SetScript('OnClick', function()
    ns:RefreshSimulation()
  end)

  panel.centerButton = CreateFrame('Button', nil, panel, 'UIPanelButtonTemplate')
  panel.centerButton:SetSize(50, 20)
  panel.centerButton:SetPoint('RIGHT', panel.refreshButton, 'LEFT', -6, 0)
  panel.centerButton:SetText('중앙')
  panel.centerButton:SetScript('OnClick', function()
    panel:ClearAllPoints()
    panel:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
    panel.anchorFrame = nil
  end)

  panel.status = ns.Util:CreateLabel(panel, '', 'TOPLEFT', panel.meta, 'BOTTOMLEFT', 0, -6, 'GameFontNormal')
  panel.status:SetTextColor(0.9, 0.82, 0.2)
  panel.status:SetWidth(ns.CONST.PANEL_WIDTH - 20)

  panel.reagentList = ns.ReagentList:Create(panel)
  panel.reagentList:SetPoint('TOPLEFT', panel.status, 'BOTTOMLEFT', 0, -8)

  panel.optionalPicker = ns.OptionalSlotPicker:Create(panel)
  panel.optionalPicker:SetPoint('TOPLEFT', panel.reagentList, 'BOTTOMLEFT', 0, -10)

  panel.summary = ns.SummaryBar:Create(panel)
  panel.summary:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', 10, 12)

  function panel:SetStatus(text)
    self.status:SetText(text or '')
  end

  function panel:Render(state)
    local status = state.recipeName or ''
    if state.recipeID then
      status = string.format('%s  (recipeID: %s)', status, tostring(state.recipeID))
    end
    self:SetStatus(status)
    self.reagentList:Render(state)
    self.optionalPicker:Render(state)
    self.summary:Render(state)
  end

  function panel:RenderEmpty()
    self.reagentList:RenderEmpty()
    self.optionalPicker:RenderEmpty()
    self.summary:RenderEmpty()
  end

  function panel:Dock(anchorFrame)
    PositionPanel(self, anchorFrame)
  end

  function panel:CenterOnScreen()
    self:ClearAllPoints()
    self:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
    self.anchorFrame = nil
  end

  ns.MainPanel = panel
  return panel
end
