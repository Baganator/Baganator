BaganatorMailCacheMixin = {}

local PENDING_OUTGOING_EVENTS = {
  "MAIL_SEND_SUCCESS",
  "MAIL_FAILED",
}

-- Assumed to run after PLAYER_LOGIN
function BaganatorMailCacheMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, {
    "MAIL_INBOX_UPDATE"
  })

  self.currentCharacter = Baganator.Utilities.GetCharacterFullName()

  -- Track outgoing mail to alts
  hooksecurefunc("SendMail", function(recipient, subject, body)
    if not recipient:find("-", nil, true) then
      recipient = recipient .. "-" .. GetNormalizedRealmName()
    end

    local mail = {
      recipient = recipient,
      items = {},
    }

    if not BAGANATOR_DATA.Characters[mail.recipient] then
      return
    end

    for index = 1, ATTACHMENTS_MAX_SEND do
      local itemLink = GetSendMailItemLink(index)
      if itemLink ~= nil then
        local name, itemID, texture, itemCount = GetSendMailItem(index)
        table.insert(mail.items, {
          itemLink = itemLink,
          itemID = itemID,
          iconTexture = iconTexture,
          itemCount = itemCount,
        })
      end
    end

    if #mail.items == 0 then
      return
    end

    self.pendingOutgoingMail = mail
    FrameUtil.RegisterFrameForEvents(self, PENDING_OUTGOING_EVENTS)
  end)
end

function BaganatorMailCacheMixin:OnEvent(eventName, ...)
  -- General mailbox scan
  if eventName == "MAIL_INBOX_UPDATE" then
    self:SetScript("OnUpdate", self.OnUpdate)
  -- Sending to an another character failed
  elseif eventName == "MAIL_FAILED" then
    FrameUtil.UnregisterFrameForEvents(self, PENDING_OUTGOING_EVENTS)
    self.pendingOutgoingMail = nil
  -- Sending to an another character was successful
  elseif eventName == "MAIL_SEND_SUCCESS" then
    local characterData = BAGANATOR_DATA.Characters[self.pendingOutgoingMail.recipient]
    characterData.mail = characterData.mail or {}
    for _, item in ipairs(self.pendingOutgoingMail.items) do
      table.insert(characterData.mail, item)
    end
    Baganator.CallbackRegistry:TriggerEvent("MailCacheUpdate", self.pendingOutgoingMail.recipient)

    FrameUtil.UnregisterFrameForEvents(self, PENDING_OUTGOING_EVENTS)
    self.pendingOutgoingMail = nil
  end
end

-- Convert an attachment to a battle pet link as by default only the cage item
-- is supplied on the attachment link, missing all the battle pet stats (retail
-- only)
local function ExtractBattlePetLink(mailIndex, attachmentIndex)
  local tooltipInfo = C_TooltipInfo.GetInboxItem(mailIndex, attachmentIndex)
  return Baganator.Utilities.RecoverBattlePetLink(tooltipInfo)
end

function BaganatorMailCacheMixin:OnUpdate()
  self:SetScript("OnUpdate", nil)

  local start = debugprofilestop()

  local attachments = {}

  for mailIndex = 1, (GetInboxNumItems()) do
    for attachmentIndex = 1, ATTACHMENTS_MAX do
      local link = GetInboxItemLink(mailIndex, attachmentIndex)
      if link ~= nil then
        local name, itemID, texture, count, quality, canUse = GetInboxItem(mailIndex, attachmentIndex)
        if itemID == Baganator.Constants.BattlePetCageID then
          link = ExtractBattlePetLink(mailIndex, attachmentIndex) or link
        end
        table.insert(attachments, {
          itemLink = link,
          itemID = itemID,
          iconTexture = texture,
          itemCount = count,
        })
      end
    end
  end

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("mail finish", debugprofilestop() - start)
  end
  BAGANATOR_DATA.Characters[self.currentCharacter].mail = attachments
  Baganator.CallbackRegistry:TriggerEvent("MailCacheUpdate", self.currentCharacter)
end
