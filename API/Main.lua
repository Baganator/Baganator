local _, addonTable = ...

function Baganator.API.GetInventoryInfo(itemLink, sameConnectedRealm, sameFaction)
  return Syndicator.API.GetInventoryInfo(itemLink, sameConnectedRealm, sameFaction)
end

local queuedPlugin = false
local function ReportPluginAdded()
  if not queuedPlugin then
    queuedPlugin = true
    C_Timer.After(0, function()
      Baganator.CallbackRegistry:TriggerEvent("PluginsUpdated")
      queuedPlugin = false
    end)
  end
end

local queuedRefresh = false
function Baganator.API.RequestItemButtonsRefresh()
  if not queuedRefresh then
    queuedRefresh = true
    C_Timer.After(0, function()
      Baganator.CallbackRegistry:TriggerEvent("ContentRefreshRequired")
      queuedRefresh = false
    end)
  end
end

do
  local addonLoaded = false

  local function AutoSet(id)
    if id == "none" then
      return
    end
    local currentOption = Baganator.Config.Get(Baganator.Config.Options.JUNK_PLUGIN)
    local ignored = Baganator.Config.Get(Baganator.Config.Options.JUNK_PLUGINS_IGNORED)
    if addonTable.JunkPlugins[currentOption] == nil and not ignored[id] then
      Baganator.Config.Set(Baganator.Config.Options.JUNK_PLUGIN, id)
    end
  end

  Baganator.Utilities.OnAddonLoaded("Baganator", function()
    addonLoaded = true

    for id in pairs(addonTable.JunkPlugins) do
      AutoSet(id)
    end

    if next(addonTable.JunkPlugins) then
      ReportPluginAdded()
    end
  end)

  -- callback - function(bagID, slotID, itemID, itemLink) returns nil/true/false
  --  Returning true indicates this item is junk and should show a junk coin
  --  Returning false or nil indicates this item isn't junk and shouldn't show a
  --  junk coin
  function Baganator.API.RegisterJunkPlugin(label, id, callback)
    if type(label) ~= "string" or type(id) ~= "string" or type(callback) ~= "function" then
      error("Bad junk plugin arguments")
    end

    addonTable.JunkPlugins[id] = {
      label = label,
      callback = callback,
    }

    if addonLoaded then
      AutoSet(id)
    end

    ReportPluginAdded()
  end

  Baganator.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == Baganator.Config.Options.JUNK_PLUGIN then
      local ignored = Baganator.Config.Get(Baganator.Config.Options.JUNK_PLUGINS_IGNORED)
      for id in pairs(addonTable.JunkPlugins) do
        ignored[id] = true
      end
      ignored[Baganator.Config.Get(Baganator.Config.Options.JUNK_PLUGIN)] = nil
    end
  end)
end

addonTable.IconCornerPlugins = {}

do
  local addonLoaded = false
  local autoAddQueue = {}

  local corners = {
    "icon_top_left_corner_array",
    "icon_top_right_corner_array",
    "icon_bottom_left_corner_array",
    "icon_bottom_right_corner_array",
  }
  local cornersMap = {
    ["top_left"] = 1,
    ["top_right"] = 2,
    ["bottom_left"] = 3,
    ["bottom_right"] = 4,
  }

  local function AutoInsert(id, defaultPosition)
    local alreadyApplied = Baganator.Config.Get(Baganator.Config.Options.ICON_CORNERS_AUTO_INSERT_APPLIED)
    if not alreadyApplied[id] then
      alreadyApplied[id] = true
      if not Baganator.API.IsCornerWidgetActive(id) then
        local cornerArray = Baganator.Config.Get(corners[cornersMap[defaultPosition.corner]])
        if defaultPosition.priority > #cornerArray then
          table.insert(cornerArray, id)
        else
          table.insert(cornerArray, defaultPosition.priority, id)
        end
      end
    end
  end

  Baganator.Utilities.OnAddonLoaded("Baganator", function()
    addonLoaded = true

    for _, entry in ipairs(autoAddQueue) do
      AutoInsert(entry.id, entry.defaultPosition)
    end

    ReportPluginAdded()
  end)

  -- label: User facing text string describing this corner option.
  -- id: unique value to be used internally for the settings
  -- onUpdate: Function to update the frame placed in the corner. Return true to
  --  cause this corner's visual to show.
  --  function(cornerFrame, itemDetails) -> boolean.
  -- onInit: Called once for each item icon to create the frame to show in the
  --  icon corner. Return the frame to be positioned in the corner. This frame
  --  will be hidden/shown/have its parent changed to control visiblity. It may
  --  have the fields padding (number, multiplier for the padding used from the
  --  icon's corner) and sizeFont (boolean sets the font size for a font string to
  --  the user configured size)
  --  function(itemButton) -> Frame
  -- defaultPosition: {corner, priority}, optional
  --  corner: string (top_left, top_right, bottom_left, bottom_right)
  --  priority: number (priority for the corner to be placed at in the corner sort
  --    order)
  function Baganator.API.RegisterCornerWidget(label, id, onUpdate, onInit, defaultPosition)
    assert(id and label and onUpdate and onInit and not addonTable.IconCornerPlugins[id])
    addonTable.IconCornerPlugins[id] = {label = label, onUpdate = onUpdate, onInit = onInit}

    if defaultPosition and cornersMap[defaultPosition.corner] and type(defaultPosition.priority) == "number" then
      if not addonLoaded then
        table.insert(autoAddQueue, {id = id, defaultPosition = defaultPosition})
      else
        AutoInsert(id, defaultPosition)
      end
    end

    ReportPluginAdded()
  end

  function Baganator.API.IsCornerWidgetActive(id)
    for _, key in ipairs(corners) do
      if tIndexOf(Baganator.Config.Get(key), id) ~= nil then
        return true
      end
    end
    return false
  end
end

addonTable.ItemSetSources = {}

function Baganator.API.RegisterItemSetSource(label, id, getter)
  assert(type(label) == "string" and type(id) == "string" and type(getter) == "function")
  table.insert(addonTable.ItemSetSources, {
    label = label,
    id = id,
    getter = getter,
  })
end

addonTable.ExternalContainerSorts = {}

Baganator.API.Constants.ContainerType = {
  Backpack = "backpack",
  Bank = "bank",
}

-- Register a sort function for bags and bank.
-- callback: function(isReverse, containerType)
--  isReverse: boolean
--  containerType: Baganator.API.Constants.ContainerType
function Baganator.API.RegisterContainerSort(label, id, callback)
  assert(type(label) == "string" and type(id) == "string" and type(callback) == "function")
  assert(not Baganator.Sorting.IsModeAvailable(id), "id already exists")
  addonTable.ExternalContainerSorts[id] = {
    label = label,
    callback = callback,
  }
end

addonTable.ExternalGuildBankSorts = {}

local guildSortPriority = 0
-- Register a sort function for guild bank.
-- callback: function()
function Baganator.API.RegisterGuildBankSort(label, id, callback)
  assert(type(label) == "string" and type(id) == "string" and type(callback) == "function")
  assert(not addonTable.ExternalGuildBankSorts[id], "id already exists")
  guildSortPriority = guildSortPriority + 1
  addonTable.ExternalGuildBankSorts[id] = {
    label = label,
    callback = callback,
    priority = guildSortPriority,
  }
end
