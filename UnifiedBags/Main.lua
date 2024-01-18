local function SetupView()
  local mainView = CreateFrame("Frame", "Baganator_MainViewFrame", UIParent, "BaganatorMainViewTemplate")
  mainView:SetClampedToScreen(true)
  mainView:SetUserPlaced(false)

  local bankOnlyView = CreateFrame("Frame", "Baganator_BankOnlyViewFrame", UIParent, "BaganatorBankOnlyViewTemplate")
  bankOnlyView:SetClampedToScreen(true)
  bankOnlyView:SetUserPlaced(false)

  local bagButtons = {}

  local UpdateButtons
  if Baganator.Constants.IsClassic then
    UpdateButtons = function()
      for _, b in ipairs(bagButtons) do
        b:SetChecked(mainView:IsVisible())
      end
    end
  else
    UpdateButtons = function()
      for _, b in ipairs(bagButtons) do
        b.SlotHighlightTexture:SetShown(mainView:IsVisible())
      end
    end
  end

  local function SetPositions()
    mainView:ClearAllPoints()
    mainView:SetPoint(unpack(Baganator.Config.Get(Baganator.Config.Options.MAIN_VIEW_POSITION)))
    bankOnlyView:ClearAllPoints()
    bankOnlyView:SetPoint(unpack(Baganator.Config.Get(Baganator.Config.Options.BANK_ONLY_VIEW_POSITION)))
  end

  local function ResetPositions()
    Baganator.Config.ResetOne(Baganator.Config.Options.MAIN_VIEW_POSITION)
    Baganator.Config.ResetOne(Baganator.Config.Options.BANK_ONLY_VIEW_POSITION)
    SetPositions()
  end

  local success = pcall(SetPositions) -- work around broken values
  if not success then
    ResetPositions()
  end

  table.insert(UISpecialFrames, mainView:GetName())
  table.insert(UISpecialFrames, bankOnlyView:GetName())

  Baganator.CallbackRegistry:RegisterCallback("ResetFramePositions", function()
    ResetPositions()
  end)

  local lastToggleTime = 0
  local function ToggleMainView()
    if GetTime() == lastToggleTime then
      return
    end
    mainView:SetShown(not mainView:IsShown())
    if mainView:IsVisible() then
      mainView:UpdateForCharacter(Baganator.BagCache.currentCharacter, true)
    end
    lastToggleTime = GetTime()
    UpdateButtons()
  end

  if not Baganator.Config.Get(Baganator.Config.Options.INVERTED_BAG_SHORTCUTS) then
    hooksecurefunc("ToggleAllBags", ToggleMainView)
  end

  Baganator.CallbackRegistry:RegisterCallback("BagShow",  function(_, ...)
    mainView:Show()
    mainView:UpdateForCharacter(Baganator.BagCache.currentCharacter, true)
    UpdateButtons()
  end)

  Baganator.CallbackRegistry:RegisterCallback("BagHide",  function(_, ...)
    mainView:Hide()
    UpdateButtons()
  end)

  mainView:HookScript("OnHide", function()
    UpdateButtons()
  end)

  --Handled by OpenClose.lua
  --[[hooksecurefunc("OpenAllBags", function()
    mainView:Show()
    mainView:UpdateForCharacter(Baganator.BagCache.currentCharacter, true)
  end)

  hooksecurefunc("CloseAllBags", function()
    mainView:Hide()
  end)]]

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
    b:HookScript("OnClick", ToggleMainView)
  end

  hooksecurefunc("ToggleBackpack", function()
    local stack = debugstack()
    -- Check to ensure we're not opening when OpenClose.lua will handle the
    -- auto-open and auto-close
    if stack:match("OpenAllBags") or stack:match("CloseAllBags") then
      return
    end
    ToggleMainView()
  end)
end

local function HideDefaultBags()
  local hidden = CreateFrame("Frame")
  hidden:Hide()

  --Retail: 1-6 are regular bags and 7-13 are bank bags
  --Wrath: 1-5 are regular bags, 6 is keyring and 7-13 are bank bags
  --Era: Doing 1-13 gets the right result even if it hides more frames than
  --needed
  for i = 1, 13 do
    _G["ContainerFrame" .. i]:SetParent(hidden)
  end

  if Baganator.Constants.IsRetail then
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
    end)
  end

  BankFrame:SetParent(hidden)
  BankFrame:SetScript("OnHide", nil)
  BankFrame:SetScript("OnShow", nil)
  BankFrame:SetScript("OnEvent", nil)
end

local function SetupEquipmentSetTracker()
  Baganator.UnifiedBags.EquipmentSetTracker = CreateFrame("Frame", nil, UIParent, "BaganatorEquipmentSetTrackerTemplate")
end

function Baganator.UnifiedBags.Initialize()
  Baganator.UnifiedBags.Search.Initialize()

  SetupView()
  HideDefaultBags()

  Baganator.InitializeOpenClose()

  --Baganator.ItemButtonUtil.ImportOrInjectSettings()
  Baganator.ItemButtonUtil.UpdateSettings()

  if BackpackTokenFrame then
    local info = C_XMLUtil.GetTemplateInfo("BackpackTokenTemplate")
    local tokenWidth = info and info.width or 50
    BackpackTokenFrame:SetWidth(tokenWidth * 3) -- Support tracking up to 3 currencies
  end

  SetupEquipmentSetTracker()
end
