\
local addonName, ns = ...

HRcraftsim = ns
ns.addonName = addonName

local defaults = {
  frame = {
    point = "CENTER",
    x = 0,
    y = 0,
    width = 1120,
    height = 720,
  },
  recipeText = "",
  priceText = "",
  qualitySelections = {},
}

local function deepcopy(src)
  if type(src) ~= "table" then return src end
  local out = {}
  for k, v in pairs(src) do
    out[k] = deepcopy(v)
  end
  return out
end

local function mergeDefaults(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" then
      if type(dst[k]) ~= "table" then dst[k] = {} end
      mergeDefaults(dst[k], v)
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
end

local function trim(s)
  if s == nil then return "" end
  return (tostring(s):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalizeName(name)
  name = trim(name)
  name = name:gsub("%s+품질%s+[12]$", "")
  name = name:gsub("%s+", " ")
  return name
end

local function parseCsvLine(line)
  local out = {}
  local current = {}
  local inQuotes = false
  local i = 1
  while i <= #line do
    local ch = line:sub(i, i)
    local nextCh = i < #line and line:sub(i + 1, i + 1) or ""
    if ch == '"' then
      if inQuotes and nextCh == '"' then
        table.insert(current, '"')
        i = i + 1
      else
        inQuotes = not inQuotes
      end
    elseif ch == "," and not inQuotes then
      table.insert(out, table.concat(current))
      current = {}
    else
      table.insert(current, ch)
    end
    i = i + 1
  end
  table.insert(out, table.concat(current))
  return out
end

local function splitLines(text)
  local lines = {}
  text = tostring(text or "")
  text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
  for line in text:gmatch("([^\n]*)\n?") do
    if line == "" and #lines > 0 and lines[#lines] == "__END__" then
      break
    end
    line = trim(line)
    if line ~= "" then
      table.insert(lines, line)
    end
  end
  return lines
end

local function copperToGoldValue(copper)
  if not copper then return 0 end
  return copper / 10000
end

local function formatGoldFromCopper(copper)
  if not copper then return "-" end
  return string.format("%.2f g", copper / 10000)
end

ns.state = {
  recipeNames = {},
  recipeText = "",
  priceText = "",
  materials = {},
  orderedMaterials = {},
  priceMap = {},
  totalCopper = 0,
}

function ns:Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffHRcraftsim|r " .. tostring(msg))
end

function ns:GetDB()
  return HRcraftsimDB
end

function ns:InitDB()
  HRcraftsimDB = HRcraftsimDB or deepcopy(defaults)
  mergeDefaults(HRcraftsimDB, defaults)
  self.db = HRcraftsimDB
end

function ns:ParseRecipeText(text)
  local materials = {}
  local ordered = {}
  local recipeNames = {}

  for _, raw in ipairs(splitLines(text)) do
    local recipeName, rest = raw:match('^(.-)%^"(.*)$')
    recipeName = trim(recipeName)
    if recipeName ~= "" then
      table.insert(recipeNames, recipeName)
    end

    local parts = {}
    if rest then
      table.insert(parts, rest)
      for extra in raw:gmatch('%^"(.-)') do
        -- handled below by generic split; placeholder to keep raw unchanged
      end
    end

    local segments = {}
    for seg in raw:gmatch('%^"(.-)') do
      table.insert(segments, seg)
    end

    local foundAny = false
    for _, segment in ipairs(segments) do
      local endQuote = segment:find('"', 1, true)
      if endQuote then
        local itemName = normalizeName(segment:sub(1, endQuote - 1))
        local qty = tonumber(segment:match("#;;(%d+)"))
        if itemName ~= "" and qty then
          foundAny = true
          if not materials[itemName] then
            materials[itemName] = {
              name = itemName,
              quantity = 0,
            }
            table.insert(ordered, itemName)
          end
          materials[itemName].quantity = materials[itemName].quantity + qty
        end
      end
    end

    if not foundAny and recipeName ~= "" then
      self:Print("레시피 문자열 파싱 실패: " .. recipeName)
    end
  end

  return recipeNames, materials, ordered
end

function ns:ParsePriceText(text)
  local priceMap = {}

  for _, line in ipairs(splitLines(text)) do
    local cols = parseCsvLine(line)
    local first = trim((cols[1] or ""):gsub('^"', ""):gsub('"$', ""))
    local second = trim((cols[2] or ""):gsub('^"', ""):gsub('"$', ""))
    if first == "가격" and second == "이름" then
      -- header
    else
      local copper = tonumber(trim((cols[1] or ""):gsub('"', ""):gsub(",", "")))
      local name = trim((cols[2] or ""):gsub('^"', ""):gsub('"$', ""))
      if copper and name ~= "" then
        local quality = tonumber(name:match("품질%s+([12])$"))
        local baseName = normalizeName(name)

        if not priceMap[baseName] then
          priceMap[baseName] = {
            baseName = baseName,
            q = {},
            raw = {},
          }
        end

        local entry = priceMap[baseName]
        table.insert(entry.raw, { name = name, copper = copper, quality = quality })

        if quality == 1 or quality == 2 then
          entry.q[quality] = copper
        else
          entry.q[0] = copper
        end
      end
    end
  end

  return priceMap
end

function ns:GetSelectedQuality(itemName, priceInfo)
  local saved = self.db.qualitySelections[itemName]
  if saved and priceInfo and priceInfo.q[saved] then
    return saved
  end
  if priceInfo then
    if priceInfo.q[2] then return 2 end
    if priceInfo.q[1] then return 1 end
    if priceInfo.q[0] then return 0 end
  end
  return 0
end

function ns:GetUnitCopper(itemName)
  local priceInfo = self.state.priceMap[itemName]
  if not priceInfo then return nil end

  local selected = self:GetSelectedQuality(itemName, priceInfo)
  if selected == 0 then
    return priceInfo.q[0]
  end
  return priceInfo.q[selected] or priceInfo.q[2] or priceInfo.q[1] or priceInfo.q[0]
end

function ns:HasQualityChoice(itemName)
  local priceInfo = self.state.priceMap[itemName]
  if not priceInfo then return false end
  return priceInfo.q[1] ~= nil and priceInfo.q[2] ~= nil
end

function ns:SetQuality(itemName, quality)
  self.db.qualitySelections[itemName] = quality
  self:RebuildMaterialState()
  if self.UI and self.UI.RefreshAll then
    self.UI:RefreshAll()
  end
end

function ns:RebuildMaterialState()
  self.state.orderedMaterials = {}
  self.state.totalCopper = 0

  for _, itemName in ipairs(self.state.orderedSource or {}) do
    local mat = self.state.materials[itemName]
    if mat then
      local priceInfo = self.state.priceMap[itemName]
      local selected = self:GetSelectedQuality(itemName, priceInfo)
      local unitCopper = self:GetUnitCopper(itemName)
      local totalCopper = unitCopper and (unitCopper * mat.quantity) or nil

      table.insert(self.state.orderedMaterials, {
        name = itemName,
        quantity = mat.quantity,
        selectedQuality = selected,
        hasQualityChoice = self:HasQualityChoice(itemName),
        q1 = priceInfo and priceInfo.q[1] or nil,
        q2 = priceInfo and priceInfo.q[2] or nil,
        generic = priceInfo and priceInfo.q[0] or nil,
        unitCopper = unitCopper,
        totalCopper = totalCopper,
      })

      if totalCopper then
        self.state.totalCopper = self.state.totalCopper + totalCopper
      end
    end
  end
end

function ns:ImportTexts(recipeText, priceText)
  self.state.recipeText = recipeText or ""
  self.state.priceText = priceText or ""

  self.db.recipeText = self.state.recipeText
  self.db.priceText = self.state.priceText

  self.state.recipeNames, self.state.materials, self.state.orderedSource = self:ParseRecipeText(self.state.recipeText)
  self.state.priceMap = self:ParsePriceText(self.state.priceText)

  self:RebuildMaterialState()
end

function ns:GetRecipeLabel()
  local names = self.state.recipeNames or {}
  if #names == 0 then return "레시피 없음" end
  if #names == 1 then return names[1] end
  return string.format("%s 외 %d개", names[1], #names - 1)
end

function ns:GetSummaryText()
  return formatGoldFromCopper(self.state.totalCopper)
end

function ns:GetGoldValue(copper)
  return copperToGoldValue(copper)
end

function ns:FormatGold(copper)
  return formatGoldFromCopper(copper)
end

SLASH_HRCRAFTSIM1 = "/hrcs"
SlashCmdList["HRCRAFTSIM"] = function(msg)
  if ns.UI and ns.UI.ToggleMainFrame then
    ns.UI:ToggleMainFrame()
  end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(_, event, arg1)
  if arg1 ~= addonName then return end
  ns:InitDB()
  if ns.UI and ns.UI.Initialize then
    ns.UI:Initialize()
  end
  ns:ImportTexts(ns.db.recipeText or "", ns.db.priceText or "")
  if ns.UI and ns.UI.RefreshAll then
    ns.UI:RefreshAll()
  end
  ns:Print("/hrcs 로 창을 열 수 있습니다.")
end)
