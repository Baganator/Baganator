local _, addonTable = ...

addonTable.Compatibility.SocketInterfaceOpen = false

if not C_EventUtils.IsEventValid("SOCKET_INFO_UPDATE") then
  return
end

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
