Baganator.CallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
Baganator.CallbackRegistry:OnLoad()
Baganator.CallbackRegistry:GenerateCallbackEvents(Baganator.Constants.Events)

local function AddToTooltip(tooltip, summaries, itemLink)
  if itemLink == nil then
    return
  end

  local key = Baganator.Utilities.GetItemKey(itemLink)

  local tooltipInfo = summaries:GetTooltipInfo(key)

  table.sort(tooltipInfo, function(a, b)
    return a.character < b.character
  end)

  if #tooltipInfo > 0 then
    tooltip:AddLine("Sources:")
    for _, s in ipairs(tooltipInfo) do
      tooltip:AddDoubleLine(s.character, "bank: " .. s.bank .. " bag: " .. s.bags)
    end
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

  hooksecurefunc("ToggleAllBags", function()
    mainView:SetShown(not mainView:IsShown())
    if mainView:IsVisible() then
      mainView:UpdateForCharacter(cache.currentCharacter, true)
    end
  end)

  hooksecurefunc("OpenAllBags", function()
    mainView:Show()
    mainView:UpdateForCharacter(cache.currentCharacter, true)
  end)

  hooksecurefunc("CloseAllBags", function()
    mainView:Hide()
  end)

  if Baganator.Constants.IsEra then
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
