local _, ns = ...

ns.OptionalSlotPicker = {}

HRcraftsimContextMenu = HRcraftsimContextMenu or CreateFrame("Frame", "HRcraftsimContextMenu", UIParent, "UIDropDownMenuTemplate")

local function CreateSlotRow(parent)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(parent:GetWidth(), 22)

  row.label = ns.Util:CreateLabel(row, "", "LEFT", row, "LEFT", 0, 0)

  row.button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  row.button:SetSize(148, 20)
  row.button:SetPoint("RIGHT", row, "RIGHT", 0, 0)
  row.button:SetText("없음")

  function row:SetSlotData(slotData)
    self.slotData = slotData
    self.label:SetText(slotData.slotName or ("선택 재료 " .. tostring(slotData.slotIndex)))
    self.button:SetText(slotData.selectedName or "없음")
  end

  function row:OpenMenu()
    if not self.slotData then
      return
    end

    local menu = {}
    table.insert(menu, {
      text = "없음",
      checked = self.slotData.selectedIndex == 0,
      func = function()
        ns.SimulationState:SetOptionalSelection(self.slotData.slotIndex, 0)
        ns.PriceCache:PopulateSimulationPrices(ns.SimulationState.state)
        ns.CostEngine:Calculate(ns.SimulationState.state)
        ns.MainPanel:Render(ns.SimulationState.state)
      end,
    })

    for index, candidate in ipairs(self.slotData.candidates or {}) do
      local label = candidate.name
      table.insert(menu, {
        text = label,
        checked = self.slotData.selectedIndex == index,
        func = function()
          ns.SimulationState:SetOptionalSelection(self.slotData.slotIndex, index)
          ns.PriceCache:PopulateSimulationPrices(ns.SimulationState.state)
          ns.CostEngine:Calculate(ns.SimulationState.state)
          ns.MainPanel:Render(ns.SimulationState.state)
        end,
      })
    end

    EasyMenu(menu, HRcraftsimContextMenu, self.button, 0, 0, "MENU")
  end

  row.button:SetScript("OnClick", function()
    row:OpenMenu()
  end)

  function row:Render(slotData)
    self:Show()
    self:SetSlotData(slotData)
  end

  function row:RenderEmpty()
    self.slotData = nil
    self:Hide()
  end

  return row
end

function ns.OptionalSlotPicker:Create(parent)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetSize(ns.CONST.PANEL_WIDTH - 20, 110)

  frame.title = ns.Util:CreateLabel(frame, "선택 재료 시뮬레이션", "TOPLEFT", frame, "TOPLEFT", 0, 0)
  frame.rows = {}

  local previous = frame.title
  for i = 1, 4 do
    local row = CreateSlotRow(frame)
    row:SetPoint("TOPLEFT", previous, i == 1 and "BOTTOMLEFT" or "BOTTOMLEFT", 0, i == 1 and -6 or -4)
    table.insert(frame.rows, row)
    previous = row
  end

  function frame:Render(state)
    for i, row in ipairs(self.rows) do
      local slotData = state.optionalSlots and state.optionalSlots[i]
      if slotData then
        row:Render(slotData)
      else
        row:RenderEmpty()
      end
    end
  end

  function frame:RenderEmpty()
    for _, row in ipairs(self.rows) do
      row:RenderEmpty()
    end
  end

  return frame
end
