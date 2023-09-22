Baganator.CallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
Baganator.CallbackRegistry:OnLoad()
Baganator.CallbackRegistry:GenerateCallbackEvents(Baganator.Constants.Events)

local function AddToTooltip(tooltip, summaries, itemLink)
  if Baganator.Config.Get(Baganator.Config.Options.SHOW_INVENTORY_TOOLTIPS) then
    Baganator.Tooltips.AddLines(tooltip, summaries, itemLink)
  end
end

local cache, summaries

local function SetupDataProcessing()
  cache = CreateFrame("Frame")
  Mixin(cache, BaganatorCacheMixin)
  cache:OnLoad()
  cache:SetScript("OnEvent", cache.OnEvent)
  cache:SetScript("OnUpdate", cache.OnUpdate)

  summaries = CreateFrame("Frame")
  Mixin(summaries, BaganatorSummariesMixin)
  summaries:OnLoad()
end

local function SetupView()
  local mainView = CreateFrame("Frame", "BaganatorMainViewFrame", UIParent, "BaganatorMainViewTemplate")
  mainView:SetClampedToScreen(true)

  local bankOnlyView = CreateFrame("Frame", "BaganatorBankOnlyViewFrame", UIParent, "BaganatorBankOnlyViewTemplate")
  bankOnlyView:SetClampedToScreen(true)

  local function SetPositions()
    mainView:ClearAllPoints()
    mainView:SetPoint("RIGHT", -20, -20)
    bankOnlyView:ClearAllPoints()
    bankOnlyView:SetPoint("LEFT", 20, -20)
  end

  SetPositions()

  local customiseDialog = CreateFrame("Frame", "BaganatorCustomiseDialogFrame", UIParent, "BaganatorCustomiseDialogTemplate")
  customiseDialog:SetPoint("CENTER")

  table.insert(UISpecialFrames, mainView:GetName())
  table.insert(UISpecialFrames, bankOnlyView:GetName())
  table.insert(UISpecialFrames, customiseDialog:GetName())

  Baganator.CallbackRegistry:RegisterCallback("ResetFramePositions", function()
    SetPositions()
  end)

  Baganator.CallbackRegistry:RegisterCallback("ShowCustomise", function()
    customiseDialog:RefreshOptions()
    customiseDialog:Show()
    customiseDialog:Raise()
  end)

  local function ToggleMainView()
      mainView:SetShown(not mainView:IsShown())
      if mainView:IsVisible() then
        mainView:UpdateForCharacter(cache.currentCharacter, true)
      end
  end

  if not Baganator.Config.Get(Baganator.Config.Options.INVERTED_BAG_SHORTCUTS) then
    hooksecurefunc("ToggleAllBags", ToggleMainView)
  end

  hooksecurefunc("OpenAllBags", function()
    mainView:Show()
    mainView:UpdateForCharacter(cache.currentCharacter, true)
  end)

  hooksecurefunc("CloseAllBags", function()
    mainView:Hide()
  end)

  -- Backpack button
  MainMenuBarBackpackButton:SetScript("OnClick", ToggleMainView)
  -- Bags 1-4, hookscript so that changing bags remains
  for i = 0, 3 do
    _G["CharacterBag" .. i .. "Slot"]:HookScript("OnClick", ToggleMainView)
  end
  -- Reagent bas
  if CharacterReagentBag0Slot then
    CharacterReagentBag0Slot:HookScript("OnClick", ToggleMainView)
  end

  if Baganator.Constants.IsEra or Baganator.Config.Get(Baganator.Config.Options.INVERTED_BAG_SHORTCUTS) then
    hooksecurefunc("ToggleBackpack", function()
      mainView:SetShown(not mainView:IsShown())
      if mainView:IsVisible() then
        mainView:UpdateForCharacter(cache.currentCharacter, true)
      end
    end)
  end
end

local function HideDefaultBags()
  local hidden = CreateFrame("Frame")
  hidden:Hide()

  if Baganator.Constants.IsRetail then
    ContainerFrameCombinedBags:SetParent(hidden)

    for i = 1, 6 do
      _G["ContainerFrame" .. i]:SetParent(hidden)
    end
  else
    for i = 1, 5 do
      _G["ContainerFrame" .. i]:SetParent(hidden)
    end
  end

  BankFrame:SetParent(hidden)
  BankFrame:SetScript("OnHide", nil)
  BankFrame:SetScript("OnShow", nil)
  BankFrame:SetScript("OnEvent", nil)
end

EventUtil.ContinueOnAddOnLoaded("Baganator", function()
  Baganator.Config.InitializeData()
  Baganator.SlashCmd.Initialize()

  SetupDataProcessing()
  SetupView()
  HideDefaultBags()

  if TooltipDataProcessor then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
      if tooltip == GameTooltip or tooltip == ItemRefTooltip then
        local itemName, itemLink = TooltipUtil.GetDisplayedItem(tooltip)
        AddToTooltip(tooltip, summaries, itemLink)
      end
    end)
  else
    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
      local _, itemLink = tooltip:GetItem()
      AddToTooltip(tooltip, summaries, itemLink)
    end)
    ItemRefTooltip:HookScript("OnTooltipSetItem", function(tooltip)
      local _, itemLink = tooltip:GetItem()
      AddToTooltip(tooltip, summaries, itemLink)
    end)
  end
end)
