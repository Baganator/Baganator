local addonName, addonTable = ...

addonTable.BagTransfers = {}
addonTable.BagTransferShowConditions = {}
addonTable.BagTransferActivationCallback = function() end

local function RegisterBagTransfer(condition, action, confirmOnAll)
  table.insert(addonTable.BagTransfers, { condition = condition, action = action, confirmOnAll = confirmOnAll})
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

local function TransferToBank(matches, characterName, callback)
  local emptyBankSlots = Baganator.Sorting.GetEmptySlots(BAGANATOR_DATA.Characters[characterName].bank, Baganator.Constants.AllBankIndexes)
  local combinedIDs = CopyTable(Baganator.Constants.AllBagIndexes)
  tAppendAll(combinedIDs, Baganator.Constants.AllBankIndexes)

  local status = Baganator.Sorting.Transfer(combinedIDs, matches, emptyBankSlots)
  callback(status)
end

RegisterTransferCondition(function()
  return isBankOpen
end, BAGANATOR_L_TRANSFER_MAIN_VIEW_BANK_TOOLTIP_TEXT)

RegisterBagTransfer(
  function(button) return button == "LeftButton" and isBankOpen end,
  TransferToBank,
  true
)

local function TransferToMail(matches, characterName, callback)
  local status = Baganator.Sorting.TransferToMail(matches)
  callback(status)
end

local sendMailShowing = false
hooksecurefunc("SetSendMailShowing", function(state)
  sendMailShowing = state
  addonTable.BagTransferActivationCallback()
end)

RegisterTransferCondition(function()
  return sendMailShowing and C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.MailInfo)
end, BAGANATOR_L_TRANSFER_MAIN_VIEW_MAIL_TOOLTIP_TEXT)

RegisterBagTransfer(
  function(button) return button == "LeftButton" and C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.MailInfo) and sendMailShowing end,
  TransferToMail,
  true
)

local function AddToScrapper(matches, characterName, callback)
  for _, item in ipairs(matches) do
    local location = ItemLocation:CreateFromBagAndSlot(item.bagID, item.slotID)
    if C_Item.DoesItemExist(location) and C_Item.CanScrapItem(location) then
      C_Container.UseContainerItem(item.bagID, item.slotID)
    end
  end
  callback(Baganator.Constants.SortStatus.Complete)
end

RegisterTransferCondition(function()
  return C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.ScrappingMachine)
end, BAGANATOR_L_TRANSFER_MAIN_VIEW_SCRAPPER_TOOLTIP_TEXT)

RegisterBagTransfer(
  function(button) return button == "LeftButton" and C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.ScrappingMachine) end,
  AddToScrapper,
  false
)
