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

local isBankOpen = false
do
  local BankCheck = CreateFrame("Frame")
  FrameUtil.RegisterFrameForEvents(BankCheck, {
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
  })
  BankCheck:SetScript("OnEvent", function(self, event)
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
  local bags, bagIDs = Baganator.Sorting.GetMergedBankBags(self.liveCharacter)
  Baganator.Sorting.CombineStacks(bags, bagIDs, callback)
end

local function ApplyStackLimit(_, characterName, callback)
  local status = Baganator.Sorting.ApplyStackLimit(1)
  callback(status)
end

RegisterTransferCondition(function()
  return isBankOpen
end, BAGANATOR_L_TRANSFER_MAIN_VIEW_BANK_TOOLTIP_TEXT)

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

RegisterBagTransfer(
  function(button) return IsShiftKeyDown() end,
  {
    MergeAllStacks,
    ApplyStackLimit,
  },
  false
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
