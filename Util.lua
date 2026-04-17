local _, ns = ...

ns.Util = {}

function ns.Util:SafeCall(fn, ...)
  local ok, result = pcall(fn, ...)
  if not ok then
    geterrorhandler()("HRcraftsim error: " .. tostring(result))
    return nil
  end
  return result
end

function ns.Util:FormatMoney(copper)
  copper = math.max(0, tonumber(copper) or 0)
  local gold = math.floor(copper / 10000)
  local silver = math.floor((copper % 10000) / 100)
  local copperOnly = copper % 100
  return string.format("%dg %ds %dc", gold, silver, copperOnly)
end

function ns.Util:GetItemNameAndIcon(itemID)
  if not itemID then
    return "Unknown", 134400
  end

  local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
  return name or ("item:" .. tostring(itemID)), icon or 134400
end

function ns.Util:CreateLabel(parent, text, anchorPoint, relativeTo, relativePoint, x, y)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fs:SetPoint(anchorPoint, relativeTo, relativePoint, x or 0, y or 0)
  fs:SetJustifyH("LEFT")
  fs:SetText(text or "")
  return fs
end

function ns.Util:CreateBackground(frame)
  frame.bg = frame:CreateTexture(nil, "BACKGROUND")
  frame.bg:SetAllPoints()
  frame.bg:SetColorTexture(0, 0, 0, 0.45)

  frame.border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  frame.border:SetAllPoints()
  frame.border:SetBackdrop({
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 12,
  })
  frame.border:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.8)
end
