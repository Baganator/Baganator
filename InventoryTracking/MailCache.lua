-- TODO Track sent mail to alts
BaganatorMailCacheMixin = {}

-- Assumed to run after PLAYER_LOGIN
function BaganatorMailCacheMixin:OnLoad()
  self:RegisterEvent("MAIL_INBOX_UPDATE")

  local characterName, realm = UnitFullName("player")
  self.currentCharacter = characterName .. "-" .. realm
end

function BaganatorMailCacheMixin:OnEvent(eventName, ...)
  if eventName == "MAIL_INBOX_UPDATE" then
    self:SetScript("OnUpdate", self.OnUpdate)
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
