---@class addonTableBaganator
local addonTable = select(2, ...)

local currentFrameGroup

local function GetViewType(view)
  if view == "bag" then
    return addonTable.Config.Get(addonTable.Config.Options.BAG_VIEW_TYPE)
  elseif view == "bank" then
    return addonTable.Config.Get(addonTable.Config.Options.BANK_VIEW_TYPE)
  end
end

local function RegisterForScaling(frame)
  addonTable.Utilities.OnAddonLoaded("BlizzMove", function()
    BlizzMoveAPI:RegisterAddOnFrames({
        ['Baganator'] = {
           [frame:GetName()] = {
             NonDraggable = true,
             IgnoreClamping = true,
           },
        },
    });
  end)
end

local backpackView, UpdateBackpackButtons
local bankView

function addonTable.ViewManagement.GetBackpackFrame()
  return backpackView
end

function addonTable.ViewManagement.GetBankFrame()
  return bankView
end

local function SetupBackpackHooks()
  local bagButtons = {}

  if addonTable.Constants.IsClassic then
    UpdateBackpackButtons = function()
      for _, b in ipairs(bagButtons) do
        b:SetChecked(backpackView:IsVisible())
      end
    end
  else
    UpdateBackpackButtons = function()
      for _, b in ipairs(bagButtons) do
        b.SlotHighlightTexture:SetShown(backpackView:IsVisible())
      end
    end
  end

  local lastToggleTime = 0
  local function ToggleBackpackView()
    if GetTime() == lastToggleTime or not Syndicator.API.GetCurrentCharacter() then
      return
    end
    backpackView:SetShown(not backpackView:IsShown())
    if backpackView:IsVisible() then
      backpackView:UpdateForCharacter(Syndicator.API.GetCurrentCharacter(), true)
    end
    lastToggleTime = GetTime()
    UpdateBackpackButtons()
  end

  addonTable.CallbackRegistry:RegisterCallback("BagShow",  function(_, characterName, _)
    characterName = characterName or Syndicator.API.GetCurrentCharacter()
    if not characterName then
      return
    end
    backpackView:Show()
    backpackView:UpdateForCharacter(characterName, characterName == Syndicator.API.GetCurrentCharacter())
    UpdateBackpackButtons()
  end)

  addonTable.CallbackRegistry:RegisterCallback("BagHide",  function(_)
    backpackView:Hide()
    UpdateBackpackButtons()
  end)

  addonTable.CallbackRegistry:RegisterCallback("QuickSearch",  function(_)
    if not backpackView:IsShown() then
      addonTable.CallbackRegistry:TriggerEvent("BagShow")
    end
    -- Delay so that triggering from a keyboard shortcut won't type the shortcut
    -- in the search box
    C_Timer.After(0, function()
      backpackView.SearchWidget.SearchBox:SetFocus()
    end)
  end)

  -- Backpack button
  table.insert(bagButtons, MainMenuBarBackpackButton)
  -- Bags 1-4, hookscript so that changing bags remains
  for i = 0, 3 do
    table.insert(bagButtons, _G["CharacterBag" .. i .. "Slot"])
  end
  -- Reagent bag
  if CharacterReagentBag0Slot then
    table.insert(bagButtons, CharacterReagentBag0Slot)
  end
  -- Keyring bag
  if KeyRingButton then
    table.insert(bagButtons, KeyRingButton)
  end
  for _, b in ipairs(bagButtons) do
    b:HookScript("OnClick", ToggleBackpackView)
  end

  local function DirectToggleOnly()
    local stack = debugstack()
    -- Check to ensure we're not opening when OpenClose.lua will handle the
    -- auto-open and auto-close
    if stack:match("OpenAllBags") or stack:match("CloseAllBags") then
      return
    end
    ToggleBackpackView()
  end

  hooksecurefunc("ToggleBackpack", DirectToggleOnly)

  hooksecurefunc("ToggleBag", DirectToggleOnly)

  ToggleAllBags = ToggleBackpackView

  -- Used to open the bags when a loot toast is clicked
  hooksecurefunc("OpenBag", function()
    local stack = debugstack()
    -- This hook is only for toasts
    if stack:match("AlertFrameSystems.lua") then
      addonTable.CallbackRegistry:TriggerEvent("BagShow")
    end
  end)
end

local function SetupBackpackView(frameGroup)
  local allBackpackViews = {
    single = CreateFrame("Frame", "Baganator_SingleViewBackpackViewFrame" .. frameGroup, UIParent, "BaganatorSingleViewBackpackViewTemplate"),
    category = CreateFrame("Frame", "Baganator_CategoryViewBackpackViewFrame" .. frameGroup, UIParent, "BaganatorCategoryViewBackpackViewTemplate"),
  }

  backpackView = allBackpackViews[GetViewType("bag")]

  local function SetPositions()
    for _, view in pairs(allBackpackViews) do
      view:ClearAllPoints()
      view:SetPoint(unpack(addonTable.Config.Get(addonTable.Config.Options.MAIN_VIEW_POSITION)))
    end
  end

  local function ResetPositions()
    addonTable.Config.ResetOne(addonTable.Config.Options.MAIN_VIEW_POSITION)
    SetPositions()
  end

  local success = pcall(SetPositions) -- work around broken values
  if not success then
    ResetPositions()
  end

  for _, view in pairs(allBackpackViews) do
    RegisterForScaling(view)
    table.insert(UISpecialFrames, view:GetName())

    view:HookScript("OnHide", function()
      UpdateBackpackButtons()
    end)
  end

  addonTable.CallbackRegistry:RegisterCallback("ResetFramePositions", function()
    ResetPositions()
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.BAG_VIEW_TYPE then
      if currentFrameGroup == frameGroup then
        local isShown = backpackView:IsShown()
        backpackView:Hide()
        backpackView = allBackpackViews[GetViewType("bag")] or backpackView
        if isShown and frameGroup == currentFrameGroup then
          addonTable.CallbackRegistry:TriggerEvent("BagShow")
        end
        addonTable.CallbackRegistry:TriggerEvent("BackpackFrameChanged", backpackView)
      end
    elseif settingName == addonTable.Config.Options.MAIN_VIEW_POSITION then
      SetPositions()
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("FrameGroupSwapped", function()
    if currentFrameGroup == frameGroup then
      backpackView = allBackpackViews[GetViewType("bag")]
      addonTable.CallbackRegistry:TriggerEvent("BackpackFrameChanged", backpackView)
    else
      for _, oldView in pairs(allBackpackViews) do
        oldView:Hide()
      end
    end
  end)

  --Handled by OpenClose.lua
  --[[hooksecurefunc("OpenAllBags", function()
    backpackView:Show()
    backpackView:UpdateForCharacter(Syndicator.API.GetCurrentCharacter(), true)
  end)

  hooksecurefunc("CloseAllBags", function()
    backpackView:Hide()
  end)]]
end

local function SetupBankView(frameGroup)
  local allBankViews = {
    single = CreateFrame("Frame", "Baganator_SingleViewBankViewFrame" .. frameGroup, UIParent, "BaganatorSingleViewBankViewTemplate"),
    category = CreateFrame("Frame", "Baganator_CategoryViewBankViewFrame" .. frameGroup, UIParent, "BaganatorCategoryViewBankViewTemplate"),
  }

  bankView = allBankViews[GetViewType("bank")]

  FrameUtil.RegisterFrameForEvents(bankView, {
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
  })

  for _, view in pairs(allBankViews) do
    RegisterForScaling(view)
    table.insert(UISpecialFrames, view:GetName())
  end

  local function SetPositions()
    for _, view in pairs(allBankViews) do
      view:ClearAllPoints()
      view:SetPoint(unpack(addonTable.Config.Get(addonTable.Config.Options.BANK_ONLY_VIEW_POSITION)))
    end
  end

  local function ResetPositions()
    addonTable.Config.ResetOne(addonTable.Config.Options.BANK_ONLY_VIEW_POSITION)
    SetPositions()
  end

  local success = pcall(SetPositions) -- work around broken values
  if not success then
    ResetPositions()
  end

  local function GetSelectedBankTab(entity)
    if type(entity) == "string" then -- Character bank
      return addonTable.Constants.BankTabType.Character
    elseif type(entity) == "number" then -- Warband bank
      return addonTable.Constants.BankTabType.Warband
    end
  end

  addonTable.CallbackRegistry:RegisterCallback("ResetFramePositions", function()
    ResetPositions()
  end)

  addonTable.CallbackRegistry:RegisterCallback("BankToggle", function(_, entity, subView)
    if frameGroup ~= currentFrameGroup then
      return
    end

    local selectedTab = GetSelectedBankTab(entity)
    if selectedTab == addonTable.Constants.BankTabType.Character then -- Character bank
      bankView:SetShown(entity ~= bankView.Character.lastCharacter or not bankView:IsShown())
      bankView:UpdateViewToCharacter(entity)
    elseif selectedTab == addonTable.Constants.BankTabType.Warband then -- Warband bank
      subView = subView or addonTable.Config.Get(addonTable.Config.Options.WARBAND_CURRENT_TAB)
      bankView:SetShown(addonTable.Config.Get(addonTable.Config.Options.BANK_CURRENT_TAB) ~= addonTable.Constants.BankTabType.Warband or not bankView:IsShown())
      bankView:UpdateViewToWarband(entity, subView)
    else -- Keep current tab
      bankView:SetShown(not bankView:IsShown())
      if bankView:IsShown() then
        bankView:UpdateView()
      end
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("BankShow", function(_, entity, subView)
    if frameGroup ~= currentFrameGroup then
      return
    end

    local selectedTab = GetSelectedBankTab(entity)
    if selectedTab == addonTable.Constants.BankTabType.Character then -- Character bank
      local characterName = entity or Syndicator.API.GetCurrentCharacter()
      bankView:Show()
      bankView:UpdateViewToCharacter(characterName)
    elseif selectedTab == addonTable.Constants.BankTabType.Warband then -- Warband bank
      subView = subView or addonTable.Config.Get(addonTable.Config.Options.WARBAND_CURRENT_TAB)
      bankView:Show()
      bankView:UpdateViewToWarband(entity, subView)
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("BankHide", function(_, _)
    if frameGroup ~= currentFrameGroup then
      return
    end

    bankView:Hide()
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.BANK_VIEW_TYPE then
      for _, oldView in pairs(allBankViews) do
        oldView:Hide()
        FrameUtil.UnregisterFrameForEvents(oldView, {
          "BANKFRAME_OPENED",
          "BANKFRAME_CLOSED",
        })
      end
      if frameGroup == currentFrameGroup then
        bankView = allBankViews[GetViewType("bank")] or bankView
        FrameUtil.RegisterFrameForEvents(bankView, {
          "BANKFRAME_OPENED",
          "BANKFRAME_CLOSED",
        })
      end
    elseif settingName == addonTable.Config.Options.BANK_ONLY_VIEW_POSITION then
      SetPositions()
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("FrameGroupSwapped", function()
    if currentFrameGroup == frameGroup then
      bankView = allBankViews[GetViewType("bank")] or bankView
      FrameUtil.RegisterFrameForEvents(bankView, {
        "BANKFRAME_OPENED",
        "BANKFRAME_CLOSED",
      })
    else
      for _, oldView in pairs(allBankViews) do
        oldView:Hide()
        FrameUtil.UnregisterFrameForEvents(oldView, {
          "BANKFRAME_OPENED",
          "BANKFRAME_CLOSED",
        })
      end
    end
  end)
end

local function SetupGuildView(frameGroup)
  local guildView = CreateFrame("Frame", "Baganator_SingleViewGuildViewFrame" .. frameGroup, UIParent, "BaganatorSingleViewGuildViewTemplate")
  guildView:SetClampedToScreen(true)
  guildView:SetUserPlaced(false)
  RegisterForScaling(guildView)

  table.insert(UISpecialFrames, guildView:GetName())

  local function SetPositions()
    guildView:HideInfoDialogs()
    guildView:ClearAllPoints()
    guildView:SetPoint(unpack(addonTable.Config.Get(addonTable.Config.Options.GUILD_VIEW_POSITION)))
  end

  local function ResetPositions()
    addonTable.Config.ResetOne(addonTable.Config.Options.GUILD_VIEW_POSITION)
    addonTable.Config.ResetOne(addonTable.Config.Options.GUILD_VIEW_DIALOG_POSITION)
    SetPositions()
  end

  local success = pcall(SetPositions) -- work around broken values
  if not success then
    ResetPositions()
  end

  addonTable.CallbackRegistry:RegisterCallback("ResetFramePositions", function()
    ResetPositions()
  end)

  addonTable.CallbackRegistry:RegisterCallback("GuildToggle", function(_, guildName)
    if frameGroup ~= currentFrameGroup then
      return
    end

    guildName = guildName or Syndicator.API.GetCurrentGuild()
    guildView:SetShown(guildName ~= guildView.lastGuild or not guildView:IsShown())
    guildView:UpdateForGuild(guildName, Syndicator.API.GetCurrentGuild() == guildName and C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.GuildBanker))
  end)

  addonTable.CallbackRegistry:RegisterCallback("GuildShow",  function(_, guildName, tabIndex)
    if frameGroup ~= currentFrameGroup then
      return
    end

    guildName = guildName or Syndicator.API.GetCurrentGuild()
    guildView:Show()
    if tabIndex ~= nil then
      guildView:SetCurrentTab(tabIndex)
    end
    guildView:UpdateForGuild(
      guildName,
      guildName == Syndicator.API.GetCurrentGuild() and C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.GuildBanker)
    )
  end)

  addonTable.CallbackRegistry:RegisterCallback("GuildHide",  function()
    guildView:Hide()
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == addonTable.Config.Options.GUILD_VIEW_POSITION then
      SetPositions()
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("FrameGroupSwapped", function()
    if currentFrameGroup == frameGroup then
      FrameUtil.RegisterFrameForEvents(guildView, {
        "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
        "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",
      })
    else
      guildView:Hide()
      FrameUtil.UnregisterFrameForEvents(guildView, {
        "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
        "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",
      })
    end
  end)
end

local hidden = CreateFrame("Frame")
hidden:Hide()

local function HideDefaultBackpack()
  --Retail: 1-6 are regular bags
  --Wrath: 1-5 are regular bags, 6 is keyring
  --Era: Doing 1-6 gets the right result even if it hides more frames than
  --needed
  for i = 1, 6 do
    _G["ContainerFrame" .. i]:SetParent(hidden)
  end

  if addonTable.Constants.IsRetail then
    ContainerFrameCombinedBags:SetParent(hidden)

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("VARIABLES_LOADED")
    frame:SetScript("OnEvent", function()
      -- Prevent glitchy tutorial popups that cannot be closed from showing
      -- These would ordinarily be attached to the Blizzard bag frames
      SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_HUD_REVAMP_BAG_CHANGES, true)
      SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_BAG_SLOTS_AUTHENTICATOR, true)
      SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_MOUNT_EQUIPMENT_SLOT_FRAME, true)
      SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_UPGRADEABLE_ITEM_IN_SLOT, true)
      SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_EQUIP_REAGENT_BAG, true)
      SetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_REAGENT_BANK_UNLOCK, true)
    end)
  end
end

local function HideDefaultBank()
  -- 7 to 13 are bank bags
  for i = 7, 13 do
    if _G["ContainerFrame" .. i] then
      _G["ContainerFrame" .. i]:SetParent(hidden)
    end
  end

  BankFrame:SetParent(hidden)
  BankFrame:SetScript("OnHide", nil)
  BankFrame:SetScript("OnEvent", nil)
  BankFrame:SetScript("OnShow", nil)
end

local function SetupCharacterSelect(frameGroup)
  local characterSelect = CreateFrame("Frame", "Baganator_CharacterSelectFrame" .. frameGroup, UIParent, "BaganatorCharacterSelectTemplate")

  table.insert(UISpecialFrames, characterSelect:GetName())

  local function SetPositions()
    characterSelect:ClearAllPoints()
    -- Fix for setting storing frame instead of just the frame name in previous
    -- versions, also makes the frame snap to the backpack when it is
    -- enabled/disabled
    local setting = addonTable.Config.Get(addonTable.Config.Options.CHARACTER_SELECT_POSITION)
    if type(setting[2]) == "table" or type(setting[2]) == "string" then
      setting[2] = nil
    end
    local anchor = CopyTable(setting)
    if setting[2] == nil then -- Accommodate renamed backpack frames
      anchor[2] = addonTable.ViewManagement.GetBackpackFrame() or UIParent
      setting[2] = anchor[2]:GetName()
    end
    characterSelect:SetPoint(unpack(anchor))
  end

  local function ResetPositions()
    addonTable.Config.ResetOne(addonTable.Config.Options.CHARACTER_SELECT_POSITION)
    SetPositions()
  end

  local success = pcall(SetPositions) -- work around broken values
  if not success then
    ResetPositions()
  end

  addonTable.CallbackRegistry:RegisterCallback("ResetFramePositions", function()
    ResetPositions()
  end)

  addonTable.CallbackRegistry:RegisterCallback("BackpackFrameChanged", function()
    SetPositions()
  end)

  addonTable.CallbackRegistry:RegisterCallback("CharacterSelectToggle", function()
    if frameGroup ~= currentFrameGroup then
      return
    end

    if frameGroup == currentFrameGroup then
      characterSelect:SetShown(not characterSelect:IsShown())
    end

  end)
  addonTable.CallbackRegistry:RegisterCallback("FrameGroupSwapped", function()
    if currentFrameGroup ~= frameGroup then
      characterSelect:Hide()
    end
  end)
end

local function SetupCurrencyPanel(frameGroup)
  local currencyPanel = addonTable.ItemViewCommon.GetCurrencyPanel("Baganator_CurrencyPanelFrame" .. frameGroup)

  table.insert(UISpecialFrames, currencyPanel:GetName())

  local function SetPositions()
    currencyPanel:ClearAllPoints()
    local setting = addonTable.Config.Get(addonTable.Config.Options.CURRENCY_PANEL_POSITION)
    if type(setting[2]) == "string" then
      setting[2] = nil
    end
    local anchor = CopyTable(setting)
    if setting[2] == nil then -- Accommodate renamed backpack frames
      anchor[2] = addonTable.ViewManagement.GetBackpackFrame() or UIParent
      setting[2] = anchor[2]:GetName()
    end
    currencyPanel:SetPoint(unpack(anchor))
  end

  local function ResetPositions()
    addonTable.Config.ResetOne(addonTable.Config.Options.CURRENCY_PANEL_POSITION)
    SetPositions()
  end

  local success = pcall(SetPositions) -- work around broken values
  if not success then
    ResetPositions()
  end

  addonTable.CallbackRegistry:RegisterCallback("ResetFramePositions", function()
    ResetPositions()
  end)

  addonTable.CallbackRegistry:RegisterCallback("BackpackFrameChanged", function()
    SetPositions()
  end)

  addonTable.CallbackRegistry:RegisterCallback("CurrencyPanelToggle", function()
    if frameGroup == currentFrameGroup then
      currencyPanel:SetShown(not currencyPanel:IsShown())
    end
  end)

  addonTable.CallbackRegistry:RegisterCallback("FrameGroupSwapped", function()
    if currentFrameGroup ~= frameGroup then
      currencyPanel:Hide()
    end
  end)
end

function addonTable.ViewManagement.Initialize()
  -- Use xpcall to so that if Blizzard reworks a component the rest of the
  -- other component initialisations won't fail

  xpcall(function()
    SetupBackpackHooks()
    HideDefaultBackpack()
  end, CallErrorHandler)

  xpcall(function()
    HideDefaultBank()
  end, CallErrorHandler)

  xpcall(function()
    local info = C_XMLUtil.GetTemplateInfo("BackpackTokenTemplate")
    local tokenWidth = info and info.width or 50
    BackpackTokenFrame:SetWidth(tokenWidth * 7 + 1)
  end, CallErrorHandler)
end

local generatedGroups = {}

function addonTable.ViewManagement.GenerateFrameGroup(frameGroup)
  currentFrameGroup = frameGroup
  addonTable.CallbackRegistry:TriggerEvent("FrameGroupSwapped")
  if generatedGroups[frameGroup] then
    return
  end
  generatedGroups[frameGroup] = true

  xpcall(function()
    SetupBackpackView(frameGroup)
  end, CallErrorHandler)

  xpcall(function()
    SetupBankView(frameGroup)
  end, CallErrorHandler)

  xpcall(function()
    SetupGuildView(frameGroup)
  end, CallErrorHandler)

  SetupCharacterSelect(frameGroup)
  SetupCurrencyPanel(frameGroup)
end
