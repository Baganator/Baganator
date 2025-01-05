local _, addonTable = ...

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
  addonTable.Compatibility.SocketInterfaceOpen = false

  if C_EventUtils.IsEventValid("SOCKET_INFO_UPDATE") then
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("SOCKET_INFO_UPDATE")
    frame:RegisterEvent("SOCKET_INFO_CLOSE")
    frame:SetScript("OnEvent", function(_, eventName)
      local oldState = addonTable.Compatibility.SocketInterfaceOpen
      addonTable.Compatibility.SocketInterfaceOpen = eventName == "SOCKET_INFO_UPDATE"
      if oldState ~= addonTable.Compatibility.SocketInterfaceOpen then
        addonTable.CallbackRegistry:TriggerEvent("ItemContextChanged")
      end
    end)
  end
end
