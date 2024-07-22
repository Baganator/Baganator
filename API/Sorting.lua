local _, addonTable = ...
if addonTable.Constants.IsRetail then
  Baganator.API.RegisterContainerSort(BAGANATOR_L_BLIZZARD, "blizzard", function(isReverse, containerType)
    C_Container.SetSortBagsRightToLeft(not isReverse)
    if containerType == Baganator.API.Constants.ContainerType.Backpack then
      C_Container.SortBags()
    elseif containerType == Baganator.API.Constants.ContainerType.CharacterBank then
      C_Container.SortBankBags()
      C_Timer.After(1, function()
        C_Container.SortReagentBankBags()
      end)
    elseif containerType == Baganator.API.Constants.ContainerType.WarbandBank then
      C_Container.SortAccountBankBags()
    end
  end)
end

addonTable.Utilities.OnAddonLoaded("SortBags", function()
  Baganator.API.RegisterContainerSort(BAGANATOR_L_SORTBAGS, "SortBags", function(isReverse, containerType)
    SetSortBagsRightToLeft(not isReverse)
    if containerType == Baganator.API.Constants.ContainerType.Backpack then
      SortBags()
    elseif containerType == Baganator.API.Constants.ContainerType.CharacterBank then
      SortBankBags()
    end
  end)
end)

addonTable.Utilities.OnAddonLoaded("tdPack2", function()
  local addon = LibStub('AceAddon-3.0'):GetAddon("tdPack2")
  local bagButton = CreateFrame("Button", nil, UIParent)
  local bankButton = CreateFrame("Button", nil, UIParent)
  addon:SetupButton(bagButton, false)
  addon:SetupButton(bankButton, true)
  Baganator.API.RegisterContainerSort("tdPack2", "tdpack2", function(isReverse, containerType)
    local button = isReverse and "RightButton" or "LeftButton"
    if containerType == Baganator.API.Constants.ContainerType.Backpack then
      bagButton:Click(button)
    elseif containerType == Baganator.API.Constants.ContainerType.CharacterBank then
      bankButton:Click(button)
    end
  end)
end)

addonTable.Utilities.OnAddonLoaded("BankStack", function()
  local sortBank, sortBags
  if BankStack.CommandDecorator then
    sortBank = BankStack.CommandDecorator(BankStack.SortBags, "bank")
    sortBags = BankStack.CommandDecorator(BankStack.SortBags, "bags")
  else
    sortBank = function() BankStack.SortBags("bank") end
    sortBags = BankStack.SortBags
  end

  Baganator.API.RegisterContainerSort("BankStack", "bankstack", function(isReverse, containerType)
    if isReverse then
      return
    end

    if containerType == Baganator.API.Constants.ContainerType.Backpack then
      sortBags()
    elseif containerType == Baganator.API.Constants.ContainerType.CharacterBank then
      sortBank()
    end
  end)
end)
