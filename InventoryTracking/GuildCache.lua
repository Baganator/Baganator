BaganatorGuildCacheMixin = {}

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
  if not IsInGuild() then
    return
  end

  local guildName = GetGuildInfo("player")

  if not guildName then
    return
  end

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

local GUILD_OPEN_EVENTS = {
  "GUILDBANKBAGSLOTS_CHANGED",
  "GUILDBANK_UPDATE_TABS",
  "GUILDBANK_UPDATE_MONEY",
}

function BaganatorGuildCacheMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, {
    "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
    "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",
    "GUILD_ROSTER_UPDATE",
    "PLAYER_GUILD_UPDATE",
  })

  self.currentGuild = GetGuildKey()
end

function BaganatorGuildCacheMixin:OnEvent(eventName, ...)
  if eventName == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
    local interactionType = ...
    if interactionType == Enum.PlayerInteractionType.GuildBanker then
      FrameUtil.RegisterFrameForEvents(self, GUILD_OPEN_EVENTS)
      self:ExamineGeneralTabInfo()
      self:StartFullBankScan()
    end
  elseif eventName == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
    local interactionType = ...
    if interactionType == Enum.PlayerInteractionType.GuildBanker then
      FrameUtil.UnregisterFrameForEvents(self, GUILD_OPEN_EVENTS)
    end
  elseif eventName == "GUILDBANKBAGSLOTS_CHANGED" then
    self:ExamineAllBankTabs()
  elseif eventName == "GUILDBANK_UPDATE_TABS" then
    self:ExamineGeneralTabInfo()
  elseif eventName == "GUILDBANK_UPDATE_MONEY" then
    local key = GetGuildKey()
    local data = BAGANATOR_DATA.Guilds[key]
    data.money = GetGuildBankMoney()

    Baganator.CallbackRegistry:TriggerEvent("GuildCacheUpdate", key)
  -- Potential change to guild name
  elseif eventName == "GUILD_ROSTER_UPDATE" or eventName == "PLAYER_GUILD_UPDATE" then
    self.currentGuild = GetGuildKey()
    if self.currentGuild then
      Baganator.CallbackRegistry:TriggerEvent("GuildNameSet", self.currentGuild)
    end
  end
end

function BaganatorGuildCacheMixin:StartFullBankScan()
  local bank = BAGANATOR_DATA.Guilds[self.currentGuild].bank

  if GetNumGuildBankTabs() > 0 then
    self.toScan = {}
    local originalTab = GetCurrentGuildBankTab()
    for tabIndex = 1, GetNumGuildBankTabs() do
      if bank[tabIndex].isViewable and tabIndex ~= originalTab then
        QueryGuildBankTab(tabIndex)
      end
    end
    if bank[originalTab].isViewable then
      QueryGuildBankTab(originalTab)
    end
  end
end

function BaganatorGuildCacheMixin:OnUpdate()
  self:SetScript("OnUpdate", nil)
end

function BaganatorGuildCacheMixin:ExamineGeneralTabInfo()
  local start = debugprofilestop()

  local data = BAGANATOR_DATA.Guilds[self.currentGuild]

  data.money = GetGuildBankMoney()

  local numTabs = GetNumGuildBankTabs()

  if numTabs == 0 then
    data.bank = {}
    if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
      print("guild clear took", debugprofilestop() - start)
    end
    Baganator.CallbackRegistry:TriggerEvent("GuildCacheUpdate", self.currentGuild)
    return
  end

  for tabIndex = 1, numTabs do
    local name, icon, isViewable = GetGuildBankTabInfo(tabIndex)
    if data.bank[tabIndex] == nil then
      data.bank[tabIndex] = {
        slots = {}
      }
    end
    local tab = data.bank[tabIndex]
    tab.isViewable = isViewable
    tab.name = name
    tab.iconTexture = icon
  end

  if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
    print("guild general", debugprofilestop() - start)
  end
  Baganator.CallbackRegistry:TriggerEvent("GuildCacheUpdate", self.currentGuild)
end

function BaganatorGuildCacheMixin:ExamineAllBankTabs()
  local start = debugprofilestop()
  local waiting = GetNumGuildBankTabs()
  if waiting == 0 then
    return
  end
  local finished = false
  local changed = {}
  local anythingChanged = false
  for tabIndex = 1, GetNumGuildBankTabs() do
    self:ExamineBankTab(tabIndex, function(tabIndex, anyChanges)
      changed[tabIndex] = anyChanges
      waiting = waiting - 1
      if waiting == 0 then
        if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
          print("guild full scan", debugprofilestop() - start)
        end
        Baganator.CallbackRegistry:TriggerEvent("GuildCacheUpdate", self.currentGuild, changed)
      end
    end)
  end
end

function BaganatorGuildCacheMixin:ExamineBankTab(tabIndex, callback)
  local start = debugprofilestop()

  local data = BAGANATOR_DATA.Guilds[self.currentGuild]

  local tab = data.bank[tabIndex]
  local oldSlots = tab.slots

  local function FireGuildChange()
    if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
      print("guild tab " .. tabIndex .. " took", debugprofilestop() - start)
    end
    callback(tabIndex, not tCompare(oldSlots, tab.slots, 15))
  end

  tab.slots = {}
  local waiting = 0
  if tab.isViewable then
    local function DoSlot(slotIndex, itemID)
      local itemLink = GetGuildBankItemLink(tabIndex, slotIndex)

      if itemLink == nil then
        return
      end

      if itemID == Baganator.Constants.BattlePetCageID then
        local tooltipInfo = C_TooltipInfo.GetGuildBankItem(tabIndex, slotIndex)
        itemLink = Baganator.Utilities.RecoverBattlePetLink(tooltipInfo)
      end

      local texture, itemCount, locked, isFiltered, quality = GetGuildBankItemInfo(tabIndex, slotIndex)
      tab.slots[slotIndex] = {
        itemID = itemID,
        iconTexture = texture,
        itemCount = itemCount,
        itemLink = itemLink,
        quality = quality,
      }
    end

    local loopComplete = false
    for slotIndex = 1, Baganator.Constants.MaxGuildBankTabItemSlots do
      local itemLink = GetGuildBankItemLink(tabIndex, slotIndex)
      tab.slots[slotIndex] = {}
      if itemLink ~= nil then
        local itemID = GetItemInfoInstant(itemLink)
        if C_Item.IsItemDataCachedByID(itemID) then
          DoSlot(slotIndex, itemID)
        else
          waiting = waiting + 1
          local item = Item:CreateFromItemID(itemID)
          item:ContinueOnItemLoad(function()
            DoSlot(slotIndex, itemID)
            waiting = waiting - 1
            if loopComplete and waiting == 0 then
              FireGuildChange()
            end
          end)
        end
      end
    end
    loopComplete = true
  end
  if waiting == 0 then
    FireGuildChange()
  end
end
