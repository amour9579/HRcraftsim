local _, ns = ...

ns.MainPanel = nil

local function CreateCheckButton(parent)
  local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  check:SetSize(24, 24)
  check.text = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  check.text:SetPoint("LEFT", check, "RIGHT", 2, 1)
  check.text:SetText("HRcraftsim 비용 시뮬레이션")
  return check
end

function ns:CreateMainPanel(parent)
  if self.MainPanel then
    return self.MainPanel
  end

  local panel = CreateFrame("Frame", "HRcraftsimMainPanel", parent)
  panel:SetSize(self.CONST.PANEL_WIDTH, self.CONST.PANEL_HEIGHT)
  panel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -28)
  panel:Hide()
  ns.Util:CreateBackground(panel)

  panel.toggle = CreateCheckButton(parent)
  panel.toggle:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -14, -6)
  panel.toggle:SetChecked(false)
  panel.toggle:SetScript("OnClick", function(btn)
    local enabled = btn:GetChecked()
    ns.SimulationState:SetEnabled(enabled)
    if enabled then
      panel:Show()
      ns:RefreshSimulation()
    else
      panel:Hide()
    end
  end)

  panel.title = ns.Util:CreateLabel(panel, "HRcraftsim", "TOPLEFT", panel, "TOPLEFT", 10, -10, "GameFontHighlightLarge")
  panel.meta = ns.Util:CreateLabel(panel, "기준: 전량 구매 / 가격 소스: Auctionator", "TOPLEFT", panel.title, "BOTTOMLEFT", 0, -4, "GameFontDisableSmall")

  panel.refreshButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  panel.refreshButton:SetSize(60, 20)
  panel.refreshButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
  panel.refreshButton:SetText("새로고침")
  panel.refreshButton:SetScript("OnClick", function()
    ns:RefreshSimulation()
  end)

  panel.status = ns.Util:CreateLabel(panel, "", "TOPLEFT", panel.meta, "BOTTOMLEFT", 0, -6, "GameFontNormal")
  panel.status:SetTextColor(0.9, 0.82, 0.2)

  panel.reagentList = ns.ReagentList:Create(panel)
  panel.reagentList:SetPoint("TOPLEFT", panel.status, "BOTTOMLEFT", 0, -8)

  panel.optionalPicker = ns.OptionalSlotPicker:Create(panel)
  panel.optionalPicker:SetPoint("TOPLEFT", panel.reagentList, "BOTTOMLEFT", 0, -10)

  panel.summary = ns.SummaryBar:Create(panel)
  panel.summary:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 10, 12)

  function panel:SetStatus(text)
    self.status:SetText(text or "")
  end

  function panel:Render(state)
    self:SetStatus(state.recipeName or "")
    self.reagentList:Render(state)
    self.optionalPicker:Render(state)
    self.summary:Render(state)
  end

  function panel:RenderEmpty()
    self.reagentList:RenderEmpty()
    self.optionalPicker:RenderEmpty()
    self.summary:RenderEmpty()
  end

  ns.MainPanel = panel
  return panel
end
