---@class addonTableBaganator
local addonTable = select(2, ...)

addonTable.Compatibility.Context = {}

addonTable.Compatibility.Context.Mail = false
hooksecurefunc("SetSendMailShowing", function(state)
  addonTable.Compatibility.Context.SendMail = state
  addonTable.CallbackRegistry:TriggerEvent("ItemContextChanged")
end)

local frame = CreateFrame("Frame")
local contexts = {
  [Enum.PlayerInteractionType.Auctioneer] = "Auctioneer",
  [Enum.PlayerInteractionType.Merchant] = "Merchant",
  [Enum.PlayerInteractionType.MailInfo] = "MailInfo",
  [Enum.PlayerInteractionType.GuildBanker] = "GuildBanker",
}
frame:SetScript("OnEvent", function(_, eventName, details)
  if not contexts[details] then
    return
  end

  if eventName == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
    addonTable.Compatibility.Context[contexts[details]] = true
  else
    addonTable.Compatibility.Context[contexts[details]] = false
  end
  addonTable.CallbackRegistry:TriggerEvent("ItemContextChanged")
end)
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
frame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")

do
  addonTable.Compatibility.Context.Socket = false

  if C_EventUtils.IsEventValid("SOCKET_INFO_UPDATE") then
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("SOCKET_INFO_UPDATE")
    frame:RegisterEvent("SOCKET_INFO_CLOSE")
    frame:SetScript("OnEvent", function(_, eventName)
      local oldState = addonTable.Compatibility.Context.Socket
      addonTable.Compatibility.Context.Socket = eventName == "SOCKET_INFO_UPDATE"
      if oldState ~= addonTable.Compatibility.Context.Socket then
        addonTable.CallbackRegistry:TriggerEvent("ItemContextChanged")
      end
    end)
  end
end
