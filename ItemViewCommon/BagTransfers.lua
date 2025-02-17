local _, addonTable = ...

addonTable.BagTransfers = {}
local activationCallbacks = {}
function addonTable.AddBagTransferActivationCallback(callback)
  table.insert(activationCallbacks, callback)
end
local function CallActivationCallbacks()
  for _, callback in ipairs(activationCallbacks) do
    callback()
  end
end

local function RegisterBagTransfer(condition, action, confirmOnAll, tooltipText)
  table.insert(addonTable.BagTransfers, { condition = condition, action = action, confirmOnAll = confirmOnAll, tooltipText = tooltipText})
end

local playerInteractionManagerChecking = CreateFrame("Frame")
playerInteractionManagerChecking:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
playerInteractionManagerChecking:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
playerInteractionManagerChecking:SetScript("OnEvent", function()
  CallActivationCallbacks()
end)

local isBankOpen = false
do
  local BankCheck = CreateFrame("Frame")
  FrameUtil.RegisterFrameForEvents(BankCheck, {
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
  })
  BankCheck:SetScript("OnEvent", function(_, event)
    warbandPrevEmptySlots = nil
    isBankOpen = event == "BANKFRAME_OPENED"
    CallActivationCallbacks()
  end)
end

local TransferToBank
if Syndicator and Syndicator.Constants.WarbandBankActive then
  local warbandPrevCounts = nil

  TransferToBank = function(matches, characterName, callback)
    local bankSlots
    if BankFrame:GetActiveBankType() == Enum.BankType.Character then
      bankSlots = addonTable.Transfers.GetBagsSlots(Syndicator.API.GetCharacter(characterName).bank, Syndicator.Constants.AllBankIndexes)
    elseif BankFrame:GetActiveBankType() == Enum.BankType.Account then
      local oldCount = #matches
      local missing = 0
      matches = tFilter(matches, function(m)
        local location = ItemLocation:CreateFromBagAndSlot(m.bagID, m.slotID)
        if not C_Item.DoesItemExist(location) then
          missing = missing + 1
          return false
        end
        return C_Bank.IsItemAllowedInBankType(Enum.BankType.Account, location)
      end, true)
      if oldCount ~= #matches + missing then
        UIErrorsFrame:AddMessage(ERR_NO_SOULBOUND_ITEM_IN_ACCOUNT_BANK, 1.0, 0.1, 0.1, 1.0)
      end
      local tabIndex = addonTable.Config.Get(addonTable.Config.Options.WARBAND_CURRENT_TAB)
      if tabIndex > 0 then
        local bagsData = {Syndicator.API.GetWarband(1).bank[tabIndex].slots}
        local indexes = {Syndicator.Constants.AllWarbandIndexes[tabIndex]}
        bankSlots = addonTable.Transfers.GetBagsSlots(bagsData, indexes)
      else
        local bagsData = {}
        local indexes = Syndicator.Constants.AllWarbandIndexes
        for i, tab in ipairs(Syndicator.API.GetWarband(1).bank) do
          table.insert(bagsData, tab.slots)
        end
        bankSlots = addonTable.Transfers.GetBagsSlots(bagsData, indexes)
      end
      local counts = addonTable.Transfers.CountByItemIDs(bankSlots)
      -- Only move more items if the last set moved in, or the last transfer
      -- completed.
      if warbandPrevCounts and tCompare(counts, warbandPrevCounts, 2) then
        callback(addonTable.Constants.SortStatus.WaitingMove)
        return
      else
        -- Limit to the first 5 items (avoids slots locking up)
        local newMatches = {}
        for i = 1, 5 do
          table.insert(newMatches, matches[i])
        end
        matches = newMatches
        warbandPrevCounts = counts
      end
    else
      error("unrecognised bank type")
    end

    local status = addonTable.Transfers.FromBagsToBags(matches, Syndicator.Constants.AllBankIndexes, bankSlots)

    if status == addonTable.Constants.SortStatus.Complete then
      warbandPrevCounts = nil
    end

    callback(status)
  end
else
  TransferToBank = function(matches, characterName, callback)
    local bankSlots = addonTable.Transfers.GetBagsSlots(Syndicator.API.GetCharacter(characterName).bank, Syndicator.Constants.AllBankIndexes)
    local status = addonTable.Transfers.FromBagsToBags(matches, Syndicator.Constants.AllBankIndexes, bankSlots)
    callback(status)
  end
end

RegisterBagTransfer(
  function(button)
    if not isBankOpen then
      return false
    end
    local bankFrame = addonTable.ViewManagement.GetBankFrame()
    return bankFrame.Character:IsShown() or (bankFrame.Warband and bankFrame.Warband:IsShown() and not bankFrame.Warband.isLocked)
  end,
  TransferToBank,
  true, BAGANATOR_L_TRANSFER_MAIN_VIEW_BANK_TOOLTIP_TEXT
)

addonTable.CallbackRegistry:RegisterCallback("BankViewChanged", function()
  CallActivationCallbacks()
end)

local function TransferToMail(matches, characterName, callback)
  local status = addonTable.Transfers.AddToMail(matches)
  callback(status)
end

local sendMailShowing = false
hooksecurefunc("SetSendMailShowing", function(state)
  sendMailShowing = state
  CallActivationCallbacks()
end)

RegisterBagTransfer(
  function() return C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.MailInfo) and sendMailShowing end,
  TransferToMail,
  false, BAGANATOR_L_TRANSFER_MAIN_VIEW_MAIL_TOOLTIP_TEXT
)

local function AddToScrapper(matches, characterName, callback)
  local waiting = #matches
  local loopFinished = false

  for _, item in ipairs(matches) do
    local location = ItemLocation:CreateFromBagAndSlot(item.bagID, item.slotID)
    if C_Item.DoesItemExist(location) then
      addonTable.Utilities.LoadItemData(item.itemID, function()
        waiting = waiting - 1
        if C_Item.CanScrapItem(location) then
          C_Container.UseContainerItem(item.bagID, item.slotID)
        end
        if loopFinished and waiting == 0 then
          callback(addonTable.Constants.SortStatus.Complete)
        end
      end)
    else
      waiting = waiting - 1
    end
  end
  loopFinished = true
  if waiting == 0 then
    callback(addonTable.Constants.SortStatus.Complete)
  end
end

RegisterBagTransfer(
  function() return C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.ScrappingMachine) end,
  AddToScrapper,
  false, BAGANATOR_L_TRANSFER_MAIN_VIEW_SCRAPPER_TOOLTIP_TEXT
)

RegisterBagTransfer(
  function() return C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.Merchant) end,
  function(matches, characterName, callback)
    local status = addonTable.Transfers.VendorItems(matches)
    callback(status)
  end,
  true, BAGANATOR_L_TRANSFER_MAIN_VIEW_VENDOR_TOOLTIP_TEXT
)

RegisterBagTransfer(
  function() return C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.TradePartner) end,
  function(matches, characterName, callback)
    local status = addonTable.Transfers.AddToTrade(matches)
    callback(status)
  end,
  false, BAGANATOR_L_TRANSFER_MAIN_VIEW_TRADE_TOOLTIP_TEXT
)

RegisterBagTransfer(
  -- At a guild bank and allowed to deposit items
  function() return C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.GuildBanker) and (select(4, GetGuildBankTabInfo(GetCurrentGuildBankTab()))) and addonTable.Config.Get(addonTable.Config.Options.GUILD_CURRENT_TAB) ~= 0 end,
  function(matches, characterName, callback)
    local guildTab = addonTable.Config.Get(addonTable.Config.Options.GUILD_CURRENT_TAB)
    local guildSlots = addonTable.Transfers.GetGuildSlots(Syndicator.API.GetGuild(Syndicator.API.GetCurrentGuild()).bank[guildTab], guildTab)
    local status, modes = addonTable.Transfers.FromBagsToGuild(matches, guildSlots)
    callback(status, modes)
  end,
  true, BAGANATOR_L_TRANSFER_MAIN_VIEW_GUILD_TOOLTIP_TEXT
)

if Syndicator then
  Syndicator.CallbackRegistry:RegisterCallback("GuildCacheUpdate", function()
    CallActivationCallbacks()
  end)
end
