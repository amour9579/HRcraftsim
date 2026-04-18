local addonName, ns = ...

ns.UI = ns.UI or {}
local UI = ns.UI

local rowHeight = 26
local rowSpacing = 4
local rows = {}

local function setBackdrop(frame)
  if frame.SetBackdrop then
    frame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
    frame:SetBackdropBorderColor(0.35, 0.35, 0.45, 1)
  end
end

local function createLabel(parent, text, template)
  local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
  fs:SetText(text or "")
  fs:SetJustifyH("LEFT")
  return fs
end

local function createButton(parent, text, width, height, onClick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width or 90, height or 22)
  b:SetText(text or "")
  if onClick then
    b:SetScript("OnClick", onClick)
  end
  return b
end

local function createScrollEdit(parent, width, height)
  local holder = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  setBackdrop(holder)
  holder:SetSize(width, height)

  local scroll = CreateFrame("ScrollFrame", nil, holder, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 8, -8)
  scroll:SetPoint("BOTTOMRIGHT", -28, 8)

  local edit = CreateFrame("EditBox", nil, scroll)
edit:SetMultiLine(true)
edit:SetAutoFocus(false)
edit:SetFontObject(ChatFontNormal)
edit:SetWidth(width - 42)
edit:EnableMouse(true)
edit:SetCursorPosition(0)
edit:SetScript("OnEscapePressed", edit.ClearFocus)
holder:EnableMouse(true)
holder:SetScript("OnMouseDown", function()
  edit:SetFocus()
end)
edit:SetScript("OnEditFocusGained", function()
  if holder.SetBackdropBorderColor then
    holder:SetBackdropBorderColor(1, 0.82, 0, 1)
  end
end)
edit:SetScript("OnEditFocusLost", function()
  if holder.SetBackdropBorderColor then
    holder:SetBackdropBorderColor(0.35, 0.35, 0.45, 1)
  end
end)
  edit:SetScript("OnTextChanged", function(self)
    local text = self:GetText() or ""
    local lines = 1
    for _ in string.gmatch(text, "\n") do
      lines = lines + 1
    end
    local lineHeight = 14
    self:SetHeight(math.max(height - 22, lines * lineHeight + 20))
    if scroll.UpdateScrollChildRect then
      scroll:UpdateScrollChildRect()
    end
  end)
  scroll:SetScrollChild(edit)

  holder.scroll = scroll
  holder.edit = edit
  return holder
end

local function formatCopper(copper)
  if not copper then return "-" end
  return BreakUpLargeNumbers(copper)
end

local function clearRows()
  for _, row in ipairs(rows) do
    row:Hide()
  end
end

local function ensureRow(index)
  if rows[index] then return rows[index] end

  local parent = UI.scrollChild
  local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  row:SetHeight(rowHeight)
  row:SetPoint("LEFT", parent, "LEFT", 2, 0)
  row:SetPoint("RIGHT", parent, "RIGHT", -2, 0)
  setBackdrop(row)
  row:SetBackdropColor(0.08, 0.08, 0.11, 0.65)

  row.name = createLabel(row, "", "GameFontNormal")
  row.name:SetPoint("LEFT", 8, 0)
  row.name:SetWidth(220)

  row.qty = createLabel(row, "", "GameFontNormal")
  row.qty:SetPoint("LEFT", 235, 0)
  row.qty:SetWidth(40)
  row.qty:SetJustifyH("CENTER")

  row.q1 = createButton(row, "Q1", 36, 20, function()
    if row.itemName then
      ns:SetQuality(row.itemName, 1)
    end
  end)
  row.q1:SetPoint("LEFT", 290, 0)

  row.q2 = createButton(row, "Q2", 36, 20, function()
    if row.itemName then
      ns:SetQuality(row.itemName, 2)
    end
  end)
  row.q2:SetPoint("LEFT", 332, 0)

  row.qtxt = createLabel(row, "-", "GameFontNormalSmall")
  row.qtxt:SetPoint("LEFT", 290, 0)
  row.qtxt:SetWidth(78)
  row.qtxt:SetJustifyH("CENTER")

  row.unit = createLabel(row, "", "GameFontNormal")
  row.unit:SetPoint("LEFT", 388, 0)
  row.unit:SetWidth(120)
  row.unit:SetJustifyH("RIGHT")

  row.total = createLabel(row, "", "GameFontNormal")
  row.total:SetPoint("LEFT", 518, 0)
  row.total:SetWidth(120)
  row.total:SetJustifyH("RIGHT")

  rows[index] = row
  return row
end

function UI:LayoutRows(count)
  local prev
  for i = 1, count do
    local row = rows[i]
    row:ClearAllPoints()
    if not prev then
      row:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, 0)
    else
      row:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -rowSpacing)
    end
    prev = row
  end

  local contentHeight = math.max(count * (rowHeight + rowSpacing), 1)
  self.scrollChild:SetHeight(contentHeight)
end

function UI:RefreshResults()
  clearRows()

  local materials = ns.state.orderedMaterials or {}
  for i, mat in ipairs(materials) do
    local row = ensureRow(i)
    row.itemName = mat.name
    row:Show()

    row.name:SetText(mat.name)
    row.qty:SetText(tostring(mat.quantity))
    row.unit:SetText(formatCopper(mat.unitCopper))
    row.total:SetText(formatCopper(mat.totalCopper))

    if mat.hasQualityChoice then
      row.q1:Show()
      row.q2:Show()
      row.qtxt:Hide()

      if mat.selectedQuality == 1 then
        row.q1:Disable()
        row.q2:Enable()
      elseif mat.selectedQuality == 2 then
        row.q1:Enable()
        row.q2:Disable()
      else
        row.q1:Enable()
        row.q2:Enable()
      end
    else
      row.q1:Hide()
      row.q2:Hide()
      row.qtxt:Show()
      if mat.generic then
        row.qtxt:SetText("일반")
      elseif mat.q1 and not mat.q2 then
        row.qtxt:SetText("Q1")
      elseif mat.q2 and not mat.q1 then
        row.qtxt:SetText("Q2")
      else
        row.qtxt:SetText("-")
      end
    end
  end

  self:LayoutRows(#materials)
end

function UI:RefreshSummary()
  self.recipeValue:SetText(ns:GetRecipeLabel())
  self.materialCountValue:SetText(tostring(#(ns.state.orderedMaterials or {})))
  self.totalValue:SetText(ns:GetSummaryText())
end

function UI:RefreshAll()
  if not self.frame then return end
  self:RefreshSummary()
  self:RefreshResults()
end

function UI:ParseNow()
  local recipeText = self.recipeBox.edit:GetText() or ""
  local priceText = self.priceBox.edit:GetText() or ""
  ns:ImportTexts(recipeText, priceText)
  self:RefreshAll()
end

function UI:Initialize()
  if self.frame then return end

  local f = CreateFrame("Frame", "HRcraftsimMainFrame", UIParent, "BackdropTemplate")
  setBackdrop(f)
  f:SetFrameStrata("DIALOG")
  f:SetToplevel(true)
  f:EnableKeyboard(false)
  f:SetSize(ns.db.frame.width, ns.db.frame.height)
  f:SetPoint(ns.db.frame.point, UIParent, ns.db.frame.point, ns.db.frame.x, ns.db.frame.y)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetClampedToScreen(true)
  f:SetScript("OnMouseDown", function(self) self:Raise() end)
  f:SetScript("OnDragStart", function(self)
    self:Raise()
    self:StartMoving()
  end)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint(1)
    ns.db.frame.point = point or "CENTER"
    ns.db.frame.x = x or 0
    ns.db.frame.y = y or 0
  end)
  f:Hide()

  self.frame = f

  local title = createLabel(f, "HRcraftsim", "GameFontHighlightLarge")
  title:SetPoint("TOPLEFT", 14, -12)

  local subtitle = createLabel(f, "레시피 문자열 + 가격 CSV 파서", "GameFontNormalSmall")
  subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)

  local leftPanel = CreateFrame("Frame", nil, f)
  leftPanel:SetPoint("TOPLEFT", 12, -44)
  leftPanel:SetPoint("BOTTOMLEFT", 12, 12)
  leftPanel:SetWidth(420)
  self.leftPanel = leftPanel

  local rightPanel = CreateFrame("Frame", nil, f)
  rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 12, 0)
  rightPanel:SetPoint("BOTTOMRIGHT", -12, 12)
  self.rightPanel = rightPanel

  local recipeLabel = createLabel(leftPanel, "레시피 문자열", "GameFontHighlight")
  recipeLabel:SetPoint("TOPLEFT", 0, 0)

  self.recipeBox = createScrollEdit(leftPanel, 410, 220)
  self.recipeBox:SetPoint("TOPLEFT", recipeLabel, "BOTTOMLEFT", 0, -6)

  local priceLabel = createLabel(leftPanel, "가격 CSV", "GameFontHighlight")
  priceLabel:SetPoint("TOPLEFT", self.recipeBox, "BOTTOMLEFT", 0, -10)

  self.priceBox = createScrollEdit(leftPanel, 410, 260)
  self.priceBox:SetPoint("TOPLEFT", priceLabel, "BOTTOMLEFT", 0, -6)

  local parseBtn = createButton(leftPanel, "파싱 / 계산", 120, 24, function()
    UI:ParseNow()
  end)
  parseBtn:SetPoint("TOPLEFT", self.priceBox, "BOTTOMLEFT", 0, -10)

  local clearBtn = createButton(leftPanel, "입력 초기화", 120, 24, function()
    self.recipeBox.edit:SetText("")
    self.priceBox.edit:SetText("")
    ns:ImportTexts("", "")
    UI:RefreshAll()
  end)
  clearBtn:SetPoint("LEFT", parseBtn, "RIGHT", 8, 0)

  local saveBtn = createButton(leftPanel, "저장", 80, 24, function()
    ns.db.recipeText = self.recipeBox.edit:GetText() or ""
    ns.db.priceText = self.priceBox.edit:GetText() or ""
    ns:Print("입력을 저장했습니다.")
  end)
  saveBtn:SetPoint("LEFT", clearBtn, "RIGHT", 8, 0)

  local recipeKey = createLabel(rightPanel, "레시피", "GameFontHighlight")
  recipeKey:SetPoint("TOPLEFT", 0, 0)
  self.recipeValue = createLabel(rightPanel, "-", "GameFontNormal")
  self.recipeValue:SetPoint("LEFT", recipeKey, "RIGHT", 12, 0)
  self.recipeValue:SetWidth(280)

  local materialCountKey = createLabel(rightPanel, "항목 수", "GameFontHighlight")
  materialCountKey:SetPoint("TOPLEFT", recipeKey, "BOTTOMLEFT", 0, -8)
  self.materialCountValue = createLabel(rightPanel, "0", "GameFontNormal")
  self.materialCountValue:SetPoint("LEFT", materialCountKey, "RIGHT", 12, 0)

  local totalKey = createLabel(rightPanel, "총합", "GameFontHighlight")
  totalKey:SetPoint("TOPLEFT", materialCountKey, "BOTTOMLEFT", 0, -8)
  self.totalValue = createLabel(rightPanel, "-", "GameFontHighlightLarge")
  self.totalValue:SetPoint("LEFT", totalKey, "RIGHT", 12, 0)

  local header = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
  setBackdrop(header)
  header:SetPoint("TOPLEFT", totalKey, "BOTTOMLEFT", 0, -12)
  header:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", 0, -12)
  header:SetHeight(24)

  local h1 = createLabel(header, "아이템명", "GameFontHighlightSmall")
  h1:SetPoint("LEFT", 8, 0)
  h1:SetWidth(220)

  local h2 = createLabel(header, "수량", "GameFontHighlightSmall")
  h2:SetPoint("LEFT", 235, 0)
  h2:SetWidth(40)
  h2:SetJustifyH("CENTER")

  local h3 = createLabel(header, "품질", "GameFontHighlightSmall")
  h3:SetPoint("LEFT", 290, 0)
  h3:SetWidth(78)
  h3:SetJustifyH("CENTER")

  local h4 = createLabel(header, "개당", "GameFontHighlightSmall")
  h4:SetPoint("LEFT", 388, 0)
  h4:SetWidth(120)
  h4:SetJustifyH("RIGHT")

  local h5 = createLabel(header, "총액", "GameFontHighlightSmall")
  h5:SetPoint("LEFT", 518, 0)
  h5:SetWidth(120)
  h5:SetJustifyH("RIGHT")

  local scroll = CreateFrame("ScrollFrame", nil, rightPanel, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
  scroll:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", -28, 0)

  local scrollChild = CreateFrame("Frame", nil, scroll)
  scrollChild:SetSize(620, 1)
  scroll:SetScrollChild(scrollChild)

  self.scroll = scroll
  self.scrollChild = scrollChild

  self.recipeBox.edit:SetText(ns.db.recipeText or "")
  self.priceBox.edit:SetText(ns.db.priceText or "")
end

function UI:ToggleMainFrame()
  if not self.frame then return end
  if self.frame:IsShown() then
    self.frame:Hide()
  else
    self.frame:Show()
    self.frame:SetFrameStrata("DIALOG")
    self.frame:Raise()
    self:RefreshAll()
  end
end
