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

function BaganatorGuildCacheMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, {
    "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
    "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",
    "GUILDBANKBAGSLOTS_CHANGED",
    "GUILDBANK_UPDATE_TABS",
    "GUILDBANK_UPDATE_MONEY",
    "GUILD_ROSTER_UPDATE",
    "PLAYER_GUILD_UPDATE",
  })

  self.currentGuild = GetGuildKey()
  self.firstOpen = true
end

function BaganatorGuildCacheMixin:OnEvent(eventName, ...)
  if eventName == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
    local interactionType = ...
    if interactionType == Enum.PlayerInteractionType.GuildBanker then
      self:ScanGeneralTabInfo()
      if not IsAddOnLoaded("BagSync") then -- BagSync already does this scan
        self:InitFullTabScan()
        if not self.firstOpen then
          self:DoNextFullScanStep()
        end
      end
      self.firstOpen = false
    end
  elseif eventName == "GUILDBANKBAGSLOTS_CHANGED" then
    self:SetScript("OnUpdate", self.OnUpdate)
  elseif eventName == "GUILDBANK_UPDATE_TABS" then
    self:ScanGeneralTabInfo()
  elseif eventName == "GUILDBANK_UPDATE_MONEY" then
    if C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.GuildBanker) then
      local key = GetGuildKey()
      local data = BAGANATOR_DATA.Guilds[key]
      data.money = GetGuildBankMoney()

      Baganator.CallbackRegistry:TriggerEvent("GuildCacheUpdate", key)
    end
  -- Potential change to guild name
  elseif eventName == "GUILD_ROSTER_UPDATE" or eventName == "PLAYER_GUILD_UPDATE" then
    self.currentGuild = GetGuildKey()
    if self.currentGuild then
      Baganator.CallbackRegistry:TriggerEvent("GuildNameSet", self.currentGuild)
    end
  end
end

function BaganatorGuildCacheMixin:InitFullTabScan()
  local bank = BAGANATOR_DATA.Guilds[self.currentGuild].bank
  if GetNumGuildBankTabs() > 0 then
    self.toScan = {}
    local originalTab = GetCurrentGuildBankTab()
    for tabIndex = 1, GetNumGuildBankTabs() do
      if bank[tabIndex].isViewable and tabIndex ~= originalTab then
        table.insert(self.toScan, tabIndex)
      end
    end
    if bank[originalTab].isViewable then
      table.insert(self.toScan, originalTab)
    end
  end

  Baganator.CallbackRegistry:RegisterCallback("GuildCacheUpdate", function(_, guild, tabIndex)
    if tabIndex == nil then
      return
    end
    self:DoNextFullScanStep()
  end, self)
end

function BaganatorGuildCacheMixin:IsFullScanInProgress()
  return self.scanIndex ~= nil
end

function BaganatorGuildCacheMixin:DoNextFullScanStep()
  self.scanIndex = table.remove(self.toScan, 1)
  if self.scanIndex ~= nil then
    QueryGuildBankTab(self.scanIndex)
  else
    Baganator.CallbackRegistry:UnregisterCallback("GuildCacheUpdate", self)
    Baganator.CallbackRegistry:TriggerEvent("GuildFullCacheUpdate")
  end
end

function BaganatorGuildCacheMixin:OnUpdate()
  self:SetScript("OnUpdate", nil)

  if C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.GuildBanker) then
    if self.scanIndex then
      self:ScanBankTab(self.scanIndex)
    else
      self:ScanBankTab(GetCurrentGuildBankTab())
    end
  end
end

function BaganatorGuildCacheMixin:ScanGeneralTabInfo()
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

function BaganatorGuildCacheMixin:ScanBankTab(tabIndex)
  local start = debugprofilestop()

  local numTabs = GetNumGuildBankTabs()
  if numTabs == 0 then
    return
  end

  local data = BAGANATOR_DATA.Guilds[self.currentGuild]

  local tab = data.bank[tabIndex]
  local oldSlots = tab.slots

  local function FireGuildChange()
    if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
      print("guild tab " .. tabIndex .. " took", debugprofilestop() - start)
    end
    Baganator.CallbackRegistry:TriggerEvent("GuildCacheUpdate", self.currentGuild, tabIndex, not tCompare(oldSlots, tab.slots, 15))
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
