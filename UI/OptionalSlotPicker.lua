
local _, ns = ...

ns.OptionalSlotPicker = {}

HRcraftsimContextMenu = HRcraftsimContextMenu or CreateFrame('Frame', 'HRcraftsimContextMenu', UIParent, 'UIDropDownMenuTemplate')

local function ApplySelection(slotIndex, candidateIndex)
  ns.SimulationState:SetOptionalSelection(slotIndex, candidateIndex)
  ns:RecalculateAndRender()
end

local function CreateSlotRow(parent)
  local row = CreateFrame('Frame', nil, parent)
  row:SetSize(parent:GetWidth(), 38)

  row.label = ns.Util:CreateLabel(row, '', 'TOPLEFT', row, 'TOPLEFT', 0, 0, 'GameFontHighlightSmall')
  row.meta = ns.Util:CreateLabel(row, '', 'TOPLEFT', row.label, 'BOTTOMLEFT', 0, -2, 'GameFontDisableSmall')

  row.button = CreateFrame('Button', nil, row, 'UIPanelButtonTemplate')
  row.button:SetSize(150, 20)
  row.button:SetPoint('RIGHT', row, 'RIGHT', 0, 8)
  row.button:SetText('없음')

  row.cost = ns.Util:CreateLabel(row, '', 'RIGHT', row, 'BOTTOMRIGHT', 0, 0, 'GameFontHighlightSmall')

  function row:SetSlotData(slotData)
    self.slotData = slotData
    self.label:SetText(slotData.slotName or ('선택 재료 ' .. tostring(slotData.slotIndex)))
    self.meta:SetText(string.format('후보 %d개 / 수량 x%d', #(slotData.candidates or {}), slotData.quantity or 1))
    self.button:SetText(slotData.selectedName or '없음')
    if slotData.selectedItemID then
      if slotData.subtotal then
        self.cost:SetText(ns.Util:FormatMoney(slotData.subtotal))
      else
        self.cost:SetText('가격 없음')
      end
    else
      self.cost:SetText('미선택')
    end
  end

  function row:OpenMenu()
    if not self.slotData or not self.slotData.candidates or #self.slotData.candidates == 0 then
      return
    end

    local menu = {}
    table.insert(menu, {
      text = '없음',
      checked = self.slotData.selectedIndex == 0,
      func = function()
        ApplySelection(self.slotData.slotIndex, 0)
      end,
    })

    for index, candidate in ipairs(self.slotData.candidates or {}) do
      local cachedPrice = ns.PriceCache:Get(candidate.itemID)
      local suffix = cachedPrice and (' - ' .. ns.Util:FormatMoney(cachedPrice.price)) or ''
      table.insert(menu, {
        text = (candidate.name or ('item:' .. tostring(candidate.itemID))) .. suffix,
        checked = self.slotData.selectedIndex == index,
        func = function()
          ApplySelection(self.slotData.slotIndex, index)
        end,
      })
    end

    EasyMenu(menu, HRcraftsimContextMenu, self.button, 0, 0, 'MENU')
  end

  row.button:SetScript('OnClick', function()
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
  local frame = CreateFrame('Frame', nil, parent)
  frame:SetSize(ns.CONST.PANEL_WIDTH - 20, 145)

  frame.title = ns.Util:CreateLabel(frame, '선택 재료 시뮬레이션', 'TOPLEFT', frame, 'TOPLEFT', 0, 0, 'GameFontHighlight')
  frame.emptyText = ns.Util:CreateLabel(frame, '선택 재료 없음', 'TOPLEFT', frame.title, 'BOTTOMLEFT', 0, -8, 'GameFontDisableSmall')
  frame.rows = {}

  local previous = frame.title
  for i = 1, ns.CONST.MAX_OPTIONAL_ROWS do
    local row = CreateSlotRow(frame)
    row:SetPoint('TOPLEFT', previous, i == 1 and 'BOTTOMLEFT' or 'BOTTOMLEFT', 0, i == 1 and -6 or -4)
    table.insert(frame.rows, row)
    previous = row
  end

  function frame:Render(state)
    local visibleCount = 0
    for i, row in ipairs(self.rows) do
      local slotData = state.optionalSlots and state.optionalSlots[i]
      if slotData and slotData.candidates and #slotData.candidates > 0 then
        row:Render(slotData)
        visibleCount = visibleCount + 1
      else
        row:RenderEmpty()
      end
    end

    if visibleCount == 0 then
      self.emptyText:Show()
    else
      self.emptyText:Hide()
    end
  end

  function frame:RenderEmpty()
    for _, row in ipairs(self.rows) do
      row:RenderEmpty()
    end
    self.emptyText:Show()
  end

  return frame
end
