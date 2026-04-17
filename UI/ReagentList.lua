local _, ns = ...

ns.ReagentList = {}

local function CreateRow(parent)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(parent:GetWidth(), ns.CONST.ROW_HEIGHT)

  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(16, 16)
  row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)

  row.name = ns.Util:CreateLabel(row, "", "LEFT", row.icon, "RIGHT", 4, 0)
  row.qty = ns.Util:CreateLabel(row, "", "LEFT", row, "LEFT", 165, 0, "GameFontHighlightSmall")
  row.unit = ns.Util:CreateLabel(row, "", "LEFT", row, "LEFT", 205, 0, "GameFontHighlightSmall")
  row.subtotal = ns.Util:CreateLabel(row, "", "RIGHT", row, "RIGHT", 0, 0, "GameFontHighlightSmall")

  function row:Render(reagent)
    self:Show()
    self.icon:SetTexture(reagent.icon)
    self.name:SetText(reagent.name)
    self.qty:SetText("x" .. tostring(reagent.quantity or 0))
    self.unit:SetText(reagent.unitPrice and ns.Util:FormatMoney(reagent.unitPrice) or "-")
    self.subtotal:SetText(reagent.subtotal and ns.Util:FormatMoney(reagent.subtotal) or "가격 없음")
  end

  function row:RenderEmpty()
    self:Hide()
  end

  return row
end

function ns.ReagentList:Create(parent)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetSize(ns.CONST.PANEL_WIDTH - 20, 165)

  frame.title = ns.Util:CreateLabel(frame, "필수 재료", "TOPLEFT", frame, "TOPLEFT", 0, 0, "GameFontHighlight")
  frame.header = ns.Util:CreateLabel(frame, "수량 / 단가 / 소계", "TOPRIGHT", frame, "TOPRIGHT", 0, 0, "GameFontDisableSmall")
  frame.rows = {}

  local previous = frame.title
  for i = 1, ns.CONST.MAX_ROWS do
    local row = CreateRow(frame)
    row:SetPoint("TOPLEFT", previous, i == 1 and "BOTTOMLEFT" or "BOTTOMLEFT", 0, i == 1 and -6 or -2)
    table.insert(frame.rows, row)
    previous = row
  end

  function frame:Render(state)
    for i, row in ipairs(self.rows) do
      local reagent = state.requiredReagents and state.requiredReagents[i]
      if reagent then
        row:Render(reagent)
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
