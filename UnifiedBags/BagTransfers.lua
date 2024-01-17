local addonName, addonTable = ...

addonTable.BagTransfers = {}
addonTable.BagTransferShowConditions = {}
addonTable.BagTransferActivationCallback = function() end

local function RegisterBagTransfer(condition, actions, confirmOnAll)
  table.insert(addonTable.BagTransfers, { condition = condition, actions = actions, confirmOnAll = confirmOnAll})
end

local function RegisterTransferCondition(condition, tooltipText)
  table.insert(addonTable.BagTransferShowConditions, { condition = condition, tooltipText = tooltipText })
end

local playerInteractionManagerChecking = CreateFrame("Frame")
playerInteractionManagerChecking:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
playerInteractionManagerChecking:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
playerInteractionManagerChecking:SetScript("OnEvent", function()
  addonTable.BagTransferActivationCallback()
end)

local isBankOpen = false
do
  local BankCheck = CreateFrame("Frame")
  FrameUtil.RegisterFrameForEvents(BankCheck, {
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
  })
  BankCheck:SetScript("OnEvent", function(_, event)
    isBankOpen = event == "BANKFRAME_OPENED"
    addonTable.BagTransferActivationCallback()
  end)
end

local function SaveBank(getMatches, characterName, callback)
  local characterData = BAGANATOR_DATA.Characters[characterName]
  local status = Baganator.Sorting.SaveToView(characterData.bags, Baganator.Constants.AllBagIndexes, characterData.bank, Baganator.Constants.AllBankIndexes)
  callback(status)
end

local function MergeBankStacks(_, characterName, callback)
  local characterData = BAGANATOR_DATA.Characters[characterName]
  Baganator.Sorting.CombineStacks(characterData.bank, Baganator.Constants.AllBankIndexes, callback)
end

local function TransferToBank(getMatches, characterName, callback)
  local matches = getMatches()
  local emptyBankSlots = Baganator.Sorting.GetEmptySlots(BAGANATOR_DATA.Characters[characterName].bank, Baganator.Constants.AllBankIndexes)
  local combinedIDs = CopyTable(Baganator.Constants.AllBagIndexes)
  tAppendAll(combinedIDs, Baganator.Constants.AllBankIndexes)

  local status = Baganator.Sorting.Transfer(combinedIDs, matches, emptyBankSlots, {})
  callback(status)
end

local function MergeAllStacks(_, characterName, callback)
  local bags, bagIDs = Baganator.Sorting.GetMergedBankBags(characterName)
  Baganator.Sorting.CombineStacks(bags, bagIDs, callback)
end

local function ApplyStackLimit(_, characterName, callback)
  local status = Baganator.Sorting.ApplyStackLimit(1)
  callback(status)
end

RegisterTransferCondition(function()
  return isBankOpen
end, BAGANATOR_L_TRANSFER_MAIN_VIEW_BANK_TOOLTIP_TEXT_SHORT)

RegisterBagTransfer(
  function(button) return IsShiftKeyDown() and isBankOpen and button == "LeftButton" end,
  {
    MergeAllStacks,
    ApplyStackLimit,
  },
  false
)

RegisterBagTransfer(
  function(button) return button == "RightButton" and isBankOpen end,
  {
    SaveBank,
    MergeBankStacks,
  },
  false
)

RegisterBagTransfer(
  function(button) return button == "LeftButton" and isBankOpen end,
  {
    TransferToBank,
    MergeBankStacks,
  },
  true
)

local function TransferToMail(getMatches, characterName, callback)
  local matches = getMatches()
  local status = Baganator.Sorting.TransferToMail(matches)
  callback(status)
end

local sendMailShowing = false
hooksecurefunc("SetSendMailShowing", function(state)
  sendMailShowing = state
  addonTable.BagTransferActivationCallback()
end)
RegisterBagTransfer(
  function(button) return button == "LeftButton" and C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.MailInfo) and sendMailShowing end,
  {
    TransferToMail,
  },
  true
)

local function ClearMailAttachments(_, _, callback)
  for i = 1, ATTACHMENTS_MAX_SEND do
    local _, itemID = ClickSendMailItemButton(i, true)
  end
  callback(Baganator.Constants.SortStatus.Complete)
end

RegisterTransferCondition(function()
  return sendMailShowing and C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.MailInfo)
end, BAGANATOR_L_TRANSFER_MAIN_VIEW_MAIL_TOOLTIP_TEXT)

RegisterBagTransfer(
  function(button) return button == "RightButton" and sendMailShowing and C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.MailInfo) end,
  {
    ClearMailAttachments,
  },
  false
)

local function AddToScrapper(getMatches, characterName, callback)
  local matches = getMatches()
  for _, item in ipairs(matches) do
    local location = ItemLocation:CreateFromBagAndSlot(item.bagID, item.slotID)
    if C_Item.DoesItemExist(location) and C_Item.CanScrapItem(location) then
      C_Container.UseContainerItem(item.bagID, item.slotID)
    end
  end
  callback(Baganator.Constants.SortStatus.Complete)
end

local function ClearScrapper(_, _, callback)
  C_ScrappingMachineUI.RemoveAllScrapItems()
  callback(Baganator.Constants.SortStatus.Complete)
end

RegisterTransferCondition(function()
  return C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.ScrappingMachine)
end, BAGANATOR_L_TRANSFER_MAIN_VIEW_SCRAPPER_TOOLTIP_TEXT)

RegisterBagTransfer(
  function(button) return button == "LeftButton" and C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.ScrappingMachine) end,
  {
    AddToScrapper,
  },
  false
)

RegisterBagTransfer(
  function(button) return button == "RightButton" and C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.ScrappingMachine) end,
  {
    ClearScrapper,
  },
  false
)
