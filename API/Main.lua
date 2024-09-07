local _, addonTable = ...

function Baganator.API.GetInventoryInfo(itemLink, sameConnectedRealm, sameFaction)
  return Syndicator.API.GetInventoryInfo(itemLink, sameConnectedRealm, sameFaction)
end

local queuedPlugin = false
local function ReportPluginAdded()
  if not queuedPlugin then
    queuedPlugin = true
    C_Timer.After(0, function()
      addonTable.CallbackRegistry:TriggerEvent("PluginsUpdated")
      queuedPlugin = false
    end)
  end
end

local queuedRefresh = false
function Baganator.API.RequestItemButtonsRefresh()
  if not queuedRefresh then
    queuedRefresh = true
    C_Timer.After(0, function()
      addonTable.CallbackRegistry:TriggerEvent("ContentRefreshRequired")
      queuedRefresh = false
    end)
  end
end

addonTable.API.JunkPlugins = {}

do
  local addonLoaded = false

  local function AutoSet(id)
    if id == "none" then
      return
    end
    local currentOption = addonTable.Config.Get(addonTable.Config.Options.JUNK_PLUGIN)
    local ignored = addonTable.Config.Get(addonTable.Config.Options.JUNK_PLUGINS_IGNORED)
    if addonTable.API.JunkPlugins[currentOption] == nil and not ignored[id] then
      addonTable.Config.Set(addonTable.Config.Options.JUNK_PLUGIN, id)
    end
  end

  addonTable.Utilities.OnAddonLoaded("Baganator", function()
    addonLoaded = true

    for id in pairs(addonTable.API.JunkPlugins) do
      AutoSet(id)
    end

    if next(addonTable.API.JunkPlugins) then
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

    addonTable.API.JunkPlugins[id] = {
      label = label,
      callback = callback,
    }

    if addonLoaded then
      AutoSet(id)
    end

    ReportPluginAdded()
  end

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.JUNK_PLUGIN then
      local ignored = addonTable.Config.Get(addonTable.Config.Options.JUNK_PLUGINS_IGNORED)
      for id in pairs(addonTable.API.JunkPlugins) do
        ignored[id] = true
      end
      ignored[addonTable.Config.Get(addonTable.Config.Options.JUNK_PLUGIN)] = nil
    end
  end)
end

addonTable.API.UpgradePlugins = {}

do
  local addonLoaded = false

  local function AutoSet(id)
    if id == "none" then
      return
    end
    local currentOption = addonTable.Config.Get(addonTable.Config.Options.UPGRADE_PLUGIN)
    local ignored = addonTable.Config.Get(addonTable.Config.Options.UPGRADE_PLUGINS_IGNORED)
    if addonTable.API.UpgradePlugins[currentOption] == nil and not ignored[id] then
      addonTable.Config.Set(addonTable.Config.Options.UPGRADE_PLUGIN, id)
    end
  end

  addonTable.Utilities.OnAddonLoaded("Baganator", function()
    addonLoaded = true

    for id in pairs(addonTable.API.UpgradePlugins) do
      AutoSet(id)
    end

    if next(addonTable.API.UpgradePlugins) then
      ReportPluginAdded()
    end
  end)

  -- callback - function(itemLink) returns nil/true/false
  --  Returning true indicates this item is an upgrade
  --  Returning false indicates that item isn't an upgrade.
  function Baganator.API.RegisterUpgradePlugin(label, id, callback)
    if type(label) ~= "string" or type(id) ~= "string" or type(callback) ~= "function" then
      error("Bad upgrade provider plugin arguments")
    end

    addonTable.API.UpgradePlugins[id] = {
      label = label,
      callback = callback,
    }

    if addonLoaded then
      AutoSet(id)
    end

    ReportPluginAdded()
  end

  function Baganator.API.IsUpgradePluginActive(id)
    return addonTable.Config.Get(addonTable.Config.Options.UPGRADE_PLUGIN) == id
  end

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.UPGRADE_PLUGIN then
      local ignored = addonTable.Config.Get(addonTable.Config.Options.UPGRADE_PLUGINS_IGNORED)
      for id in pairs(addonTable.API.UpgradePlugins) do
        ignored[id] = true
      end
      ignored[addonTable.Config.Get(addonTable.Config.Options.UPGRADE_PLUGIN)] = nil
    end
  end)
end

addonTable.API.IconCornerPlugins = {}

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
    local alreadyApplied = addonTable.Config.Get(addonTable.Config.Options.ICON_CORNERS_AUTO_INSERT_APPLIED)
    if not alreadyApplied[id] then
      alreadyApplied[id] = true
      if not Baganator.API.IsCornerWidgetActive(id) then
        local cornerArray = addonTable.Config.Get(corners[cornersMap[defaultPosition.corner]])
        if defaultPosition.priority > #cornerArray then
          table.insert(cornerArray, id)
        else
          table.insert(cornerArray, defaultPosition.priority, id)
        end
      end
    end
  end

  addonTable.Utilities.OnAddonLoaded("Baganator", function()
    addonLoaded = true

    for _, entry in ipairs(autoAddQueue) do
      AutoInsert(entry.id, entry.defaultPosition)
    end

    ReportPluginAdded()
  end)

  -- label: User facing text string describing this corner option.
  -- id: unique value to be used internally for the settings
  -- onUpdate: Function to update the frame placed in the corner. Return true to
  --  cause this corner's visual to show.  Return false to indicate no
  --  visual will be shown. Return nil to indicate the item information
  --  needed to make the display determination isn't available yet
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
    assert(id and label and onUpdate and onInit and not addonTable.API.IconCornerPlugins[id])
    addonTable.API.IconCornerPlugins[id] = {label = label, onUpdate = onUpdate, onInit = onInit}

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
      if tIndexOf(addonTable.Config.Get(key), id) ~= nil then
        return true
      end
    end
    return false
  end
end

addonTable.API.ItemSetSources = {}

function Baganator.API.RegisterItemSetSource(label, id, getItemSetInfo, getAllSetNames)
  assert(type(label) == "string" and type(id) == "string" and type(getItemSetInfo) == "function" and (getAllSetNames == nil or type(getAllSetNames) == "function"))
  table.insert(addonTable.API.ItemSetSources, {
    label = label,
    id = id,
    getItemSetInfo = getItemSetInfo,
    getAllSetNames = getAllSetNames,
  })
end

addonTable.API.ExternalContainerSorts = {}

Baganator.API.Constants.ContainerType = {
  Backpack = "backpack",
  Bank = "character_bank", -- same as CharacterBank, kept for compatibility
  CharacterBank = "character_bank",
  WarbandBank = "warband_bank",
}

-- Register a sort function for bags and bank.
-- callback: function(isReverse, containerType)
--  isReverse: boolean
--  containerType: Baganator.API.Constants.ContainerType
function Baganator.API.RegisterContainerSort(label, id, callback)
  assert(type(label) == "string" and type(id) == "string" and type(callback) == "function")
  assert(not addonTable.Sorting.IsModeAvailable(id), "id already exists")
  addonTable.API.ExternalContainerSorts[id] = {
    label = label,
    callback = callback,
  }
end

Baganator.API.Skins = {}

function Baganator.API.Skins.GetAllFrames()
  return addonTable.Skins.allFrames
end

function Baganator.API.Skins.RegisterListener(callback)
  if not addonTable.Skins.skinListeners then
    addonTable.Skins.skinListeners = {}
  end
  table.insert(addonTable.Skins.skinListeners, callback)
  if addonTable.WagoAnalytics then
    addonTable.WagoAnalytics:Switch("UsingSkin", true)
  end
end
