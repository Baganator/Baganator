local _, addonTable = ...

local arrayName = "icon_%s_corner_array"

local function SetDataProvider(c)
  c.elements = {}
  local forDataProvider = {}
  for _, widgetValue in ipairs(addonTable.Config.Get(arrayName:format(c.regionName))) do
    if addonTable.API.IconCornerPlugins[widgetValue] then
      table.insert(c.elements, widgetValue)
      table.insert(forDataProvider, { value = widgetValue, label = addonTable.API.IconCornerPlugins[widgetValue].label})
    end
  end
  c.ScrollBox:SetDataProvider(CreateDataProvider(forDataProvider))
end

local function GetCornerContainer(parent, regionName, callback)
  local container = addonTable.CustomiseDialog.GetContainerForDragAndDrop(parent, callback)
  container:SetSize(200, 100)
  container.regionName = regionName

  SetDataProvider(container)

  return container
end

local function SetAddCornerPriorities(dropDown)
  local options = {}
  for key, details in pairs(addonTable.API.IconCornerPlugins) do
    table.insert(options, {label = details.label, value = key})
  end
  table.sort(options, function(a, b) return a.label < b.label end)

  local entries, values = {}, {}

  for _, opt in ipairs(options) do
    table.insert(entries, opt.label)
    table.insert(values, opt.value)
  end

  dropDown:SetupOptions(entries, values)
end

function addonTable.CustomiseDialog.GetCornersEditor(parent)
  local container = CreateFrame("Frame", nil, parent)
  container:SetSize(480, 210)
  container:SetPoint("CENTER")

  local corners = {}
  local highlightContainer = CreateFrame("Frame", nil, container)
  local highlight = highlightContainer:CreateTexture(nil, "OVERLAY", nil, 7)
  highlight:SetSize(200, 20)
  highlight:SetAtlas("128-RedButton-Highlight")
  highlight:Hide()
  local draggable
  draggable = addonTable.CustomiseDialog.GetDraggable(function()
    for _, c in ipairs(corners) do
      if c:IsMouseOver() then
        local f, isTop = addonTable.CustomiseDialog.GetMouseOverInContainer(c)
        if not f then
          table.insert(c.elements, draggable.value)
        else
          local index = tIndexOf(c.elements, f.value)
          if isTop then
            table.insert(c.elements, index, draggable.value)
          else
            table.insert(c.elements, index + 1, draggable.value)
          end
        end
        addonTable.Config.Set(arrayName:format(c.regionName), c.elements)
      end
    end
    highlight:Hide()
  end, function()
    highlight:ClearAllPoints()
    highlight:Hide()
    for _, c in ipairs(corners) do
      if c:IsMouseOver() then
        highlight:Show()
        local f, isTop = addonTable.CustomiseDialog.GetMouseOverInContainer(c)
        if f and isTop then
          highlight:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, -10)
        elseif f then
          highlight:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, 10)
        else
          highlight:SetPoint("BOTTOMLEFT", c, 0, 0)
        end
      end
    end
  end)

  local dropDown = addonTable.CustomiseDialog.GetDropdown(container)
  SetAddCornerPriorities(dropDown)

  local function Pickup(value)
    for _, c in ipairs(corners) do
      local index = tIndexOf(c.elements, value)
      if index ~= nil then
        table.remove(c.elements, index)
        addonTable.Config.Set(arrayName:format(c.regionName), c.elements)
      end
    end

    local label = addonTable.API.IconCornerPlugins[value].label
    dropDown:SetText(label)
    draggable:Show()
    draggable.text:SetText(label)
    draggable.value = value
  end

  dropDown:SetText(BAGANATOR_L_ADD_ITEM)

  hooksecurefunc(dropDown, "OnEntryClicked", function(_, option)
    Pickup(option.value)
  end)
  draggable:SetScript("OnHide", function()
    dropDown:SetText(BAGANATOR_L_ADD_ITEM)
  end)
  dropDown:SetPoint("TOPLEFT", 320, 40)
  dropDown:SetPoint("TOPRIGHT")

  local topLeft = GetCornerContainer(container, "top_left", Pickup)
  topLeft:SetPoint("TOPLEFT", 0, 0)
  table.insert(corners, topLeft)

  local topRight = GetCornerContainer(container, "top_right", Pickup)
  topRight:SetPoint("TOPRIGHT", 0, 0)
  table.insert(corners, topRight)

  local bottomLeft = GetCornerContainer(container, "bottom_left", Pickup)
  bottomLeft:SetPoint("BOTTOMLEFT")
  table.insert(corners, bottomLeft)

  local bottomRight = GetCornerContainer(container, "bottom_right", Pickup)
  bottomRight:SetPoint("BOTTOMRIGHT")
  table.insert(corners, bottomRight)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    local region = settingName:match("^icon_(.*)_corner_array$")
    if region then
      local newElements = addonTable.Config.Get(arrayName:format(region))
      for _, c in ipairs(corners) do
        if c.regionName == region then
          SetDataProvider(c)
        end
      end
    end
  end)

  return container
end
