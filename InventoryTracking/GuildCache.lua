BaganatorGuildCacheMixin = {}

function BaganatorGuildCacheMixin:OnLoad()
  self:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")
end

function BaganatorGuildCacheMixin:OnEvent(eventName, ...)
  if eventName == "GUILDBANKBAGSLOTS_CHANGED" then
    self:SetScript("OnUpdate", self.OnUpdate)
  end
end

function BaganatorGuildCacheMixin:OnUpdate()
  self:SetScript("OnUpdate", nil)

  self:ScanBank()
end

local function InitGuild(key, guild, realms)
  if not BAGANATOR_DATA.Guilds[key] then
    BAGANATOR_DATA.Guilds[key] = {
      bank = {},
      money = 0,
      details = {
        guild = guild,
        faction = UnitFactionGroup("player"),
      },
    }
  end
  BAGANATOR_DATA.Guilds[key].details.realms = realms
end

local seenGuilds = {}

local function GetGuildKey()
  local guildName = GetGuildInfo("player")

  if seenGuilds[guildName] then
    return seenGuilds[guildName]
  end

  local realms = Baganator.Utilities.GetConnectedRealms()

  for _, realm in ipairs(realms) do
    local key = guildName .. "-" .. realm
    if BAGANATOR_DATA.Guilds[key] then
      InitGuild(key, guildName, realms)
      seenGuilds[guildName] = key
      return key
    end
  end

  local key = guildName .. "-" .. realms[1]
  -- No guild found cached, create it
  InitGuild(key, guildName, realms)
  seenGuilds[guildName] = key

  return key
end

function BaganatorGuildCacheMixin:ScanBank()
  local start = debugprofilestop()

  local key = GetGuildKey()
  local data = BAGANATOR_DATA.Guilds[key]

  local numTabs = GetNumGuildBankTabs()
  if numTabs == 0 then
    data.bank = {}
    if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
      print("guild clear took", debugprofilestop() - start)
    end
    Baganator.CallbackRegistry:TriggerEvent("GuildCacheUpdate", key)
    return
  end

  for tabIndex = 1, numTabs do
    local name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals = GetGuildBankTabInfo(tabIndex)
    if data.bank[tabIndex] == nil then
      data.bank[tabIndex] = {
        slots = {}
      }
    end
    local tab = data.bank[tabIndex]
    tab.isViewable = isViewable
    tab.name = name
    tab.iconTexture = icon
    -- Used to avoid showing guild bank tab contents in tooltips if you can't
    -- use it
    tab.fullAccess = (numWithdrawals == -1 or numWithdrawals >= Baganator.Constants.GuildBankFullAccessWithdrawalsLimit)
  end

  local tabIndex = GetCurrentGuildBankTab()
  local tab = data.bank[tabIndex]
  tab.slots = {}
  if tab.isViewable then
    for slotIndex = 1, Baganator.Constants.MaxGuildBankTabItemSlots do
      local texture, itemCount, locked, isFiltered, quality = GetGuildBankItemInfo(tabIndex, slotIndex)
      if texture == nil then
        tab.slots[slotIndex] = {}
      else
        local itemLink = GetGuildBankItemLink(tabIndex, slotIndex)
        local itemID = GetItemInfoInstant(itemLink)
        if itemID == Baganator.Constants.BattlePetCageID then
          local tooltipInfo = C_TooltipInfo.GetGuildBankItem(tabIndex, slotIndex)
          itemLink = Baganator.Utilities.RecoverBattlePetLink(tooltipInfo)
        end
        tab.slots[slotIndex] = {
          itemID = itemID,
          iconTexture = texture,
          itemCount = itemCount,
          itemLink = itemLink,
          quality = quality,
        }
      end
    end
  end

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("guild tab " .. tabIndex .. " took", debugprofilestop() - start)
  end

  Baganator.CallbackRegistry:TriggerEvent("GuildCacheUpdate", key)
end
