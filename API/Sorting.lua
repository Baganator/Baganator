---@class addonTableBaganator
local addonTable = select(2, ...)
if addonTable.Constants.IsRetail then
  Baganator.API.RegisterContainerSort(addonTable.Locales.BLIZZARD, "blizzard", function(isReverse, containerType)
    C_Container.SetSortBagsRightToLeft(not isReverse)
    if containerType == Baganator.API.Constants.ContainerType.Backpack then
      C_Container.SortBags()
    elseif containerType == Baganator.API.Constants.ContainerType.CharacterBank then
      C_Container.SortBank(Enum.BankType.Character)
    elseif containerType == Baganator.API.Constants.ContainerType.WarbandBank then
      C_Container.SortBank(Enum.BankType.Account)
    end
  end)
end

addonTable.Utilities.OnAddonLoaded("SortBags", function()
  Baganator.API.RegisterContainerSort(addonTable.Locales.SORTBAGS, "SortBags", function(isReverse, containerType)
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
  ---@diagnostic disable-next-line: undefined-field
  addon:SetupButton(bagButton, false)
  ---@diagnostic disable-next-line: undefined-field
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

  Baganator.API.RegisterContainerSort("BankStack", "bankstack", function(isReverse, containerType, tabIndex)
    if isReverse then
      return
    end

    if containerType == Baganator.API.Constants.ContainerType.Backpack then
      sortBags()
    elseif containerType == Baganator.API.Constants.ContainerType.CharacterBank then
      if tabIndex then
        sortBank(tostring(Syndicator.Constants.AllBankIndexes[tabIndex]))
      else
        sortBank("bank")
      end
    elseif containerType == Baganator.API.Constants.ContainerType.WarbandBank then
      if tabIndex then
        sortBank(tostring(Syndicator.Constants.AllWarbandIndexes[tabIndex]))
      else
        sortBank("account")
      end
    end
  end)
end)
