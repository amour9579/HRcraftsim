local _, ns = ...

ns.SummaryBar = {}

function ns.SummaryBar:Create(parent)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetSize(ns.CONST.PANEL_WIDTH - 20, 50)

  frame.totalLabel = ns.Util:CreateLabel(frame, "총 제작비(전량 구매)", "TOPLEFT", frame, "TOPLEFT", 0, 0)
  frame.totalValue = ns.Util:CreateLabel(frame, "-", "TOPRIGHT", frame, "TOPRIGHT", 0, 0)
  frame.totalValue:SetFontObject("GameFontHighlightLarge")

  frame.missingLabel = ns.Util:CreateLabel(frame, "가격 미확인", "TOPLEFT", frame.totalLabel, "BOTTOMLEFT", 0, -8)
  frame.missingValue = ns.Util:CreateLabel(frame, "0", "TOPRIGHT", frame.totalValue, "BOTTOMRIGHT", 0, -8)

  function frame:Render(state)
    self.totalValue:SetText(ns.Util:FormatMoney(state.totalCost or 0))
    self.missingValue:SetText(tostring(state.missingPriceCount or 0))
  end

  function frame:RenderEmpty()
    self.totalValue:SetText("-")
    self.missingValue:SetText("0")
  end

  return frame
end
