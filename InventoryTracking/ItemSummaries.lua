BaganatorItemSummariesMixin = {}

function BaganatorItemSummariesMixin:OnLoad()
  if BAGANATOR_SUMMARIES == nil then
    BAGANATOR_SUMMARIES = {
      Version = 2,
      Characters = {
        ByRealm = {},
        Pending = {},
      },
      Guilds = {
        ByRealm = {},
        Pending = {},
      },
    }
  end
  if BAGANATOR_SUMMARIES.Version == 1 then
    BAGANATOR_SUMMARIES.Characters = {
      ByRealm = BAGANATOR_SUMMARIES.ByRealm,
      Pending = BAGANATOR_SUMMARIES.Pending,
    }
    BAGANATOR_SUMMARIES.Guilds = {
      ByRealm = {},
      Pending = {},
    }
    BAGANATOR_SUMMARIES.Version = 2
  end
  self.SV = BAGANATOR_SUMMARIES
  Baganator.CallbackRegistry:RegisterCallback("BagCacheUpdate", self.CharacterCacheUpdate, self)
  Baganator.CallbackRegistry:RegisterCallback("MailCacheUpdate", self.CharacterCacheUpdate, self)
  Baganator.CallbackRegistry:RegisterCallback("GuildCacheUpdate", self.GuildCacheUpdate, self)
  Baganator.CallbackRegistry:RegisterCallback("EquippedCacheUpdate", self.CharacterCacheUpdate, self)
end

function BaganatorItemSummariesMixin:CharacterCacheUpdate(characterName)
  self.SV.Characters.Pending[characterName] = true
end

function BaganatorItemSummariesMixin:GuildCacheUpdate(guildName)
  self.SV.Guilds.Pending[guildName] = true
end

function BaganatorItemSummariesMixin:GenerateCharacterSummary(characterName)
  local summary = {}
  local details = BAGANATOR_DATA.Characters[characterName]

  -- Edge case sometimes removed characters are leftover in the queue, so check
  -- details exist
  if details == nil then
    return
  end

  for _, bag in pairs(details.bags) do
    for _, item in pairs(bag) do
      if item.itemLink then
        local key = Baganator.Utilities.GetItemKey(item.itemLink)
        if not summary[key] then
          summary[key] = {
            bags = 0,
            bank = 0,
            mail = 0,
            equipped = 0,
          }
        end
        summary[key].bags = summary[key].bags + item.itemCount
      end
    end
  end

  for _, bag in pairs(details.bank) do
    for _, item in pairs(bag) do
      if item.itemLink then
        local key = Baganator.Utilities.GetItemKey(item.itemLink)
        if not summary[key] then
          summary[key] = {
            bags = 0,
            bank = 0,
            mail = 0,
            equipped = 0,
          }
        end
        summary[key].bank = summary[key].bank + item.itemCount
      end
    end
  end

  for _, item in pairs(details.mail) do
    if item.itemLink then
      local key = Baganator.Utilities.GetItemKey(item.itemLink)
      if not summary[key] then
        summary[key] = {
          bags = 0,
          bank = 0,
          mail = 0,
          equipped = 0,
        }
      end
      summary[key].mail = summary[key].mail + item.itemCount
    end
  end

  for _, item in pairs(details.equipped) do
    if item.itemLink then
      local key = Baganator.Utilities.GetItemKey(item.itemLink)
      if not summary[key] then
        summary[key] = {
          bags = 0,
          bank = 0,
          mail = 0,
          equipped = 0,
        }
      end
      summary[key].equipped = summary[key].equipped + item.itemCount
    end
  end

  if not self.SV.Characters.ByRealm[details.details.realmNormalized] then
    self.SV.Characters.ByRealm[details.details.realmNormalized] = {}
  end
  self.SV.Characters.ByRealm[details.details.realmNormalized][details.details.character] = summary
end

function BaganatorItemSummariesMixin:GenerateGuildSummary(guildName)
  local summary = {}
  local details = BAGANATOR_DATA.Guilds[guildName]

  -- Edge case sometimes removed guilds are leftover in the queue, so check
  -- details exist
  if details == nil then
    return
  end

  for _, tab in pairs(details.bank) do
    if tab.fullAccess then
      for _, item in pairs(tab.slots) do
        if item.itemLink then
          local key = Baganator.Utilities.GetItemKey(item.itemLink)
          if not summary[key] then
            summary[key] = {
              bank = 0,
            }
          end
          summary[key].bank = summary[key].bank + item.itemCount
        end
      end
    end
  end

  if not self.SV.Guilds.ByRealm[details.details.realms[1]] then
    self.SV.Guilds.ByRealm[details.details.realms[1]] = {}
  end
  self.SV.Guilds.ByRealm[details.details.realms[1]][details.details.guild] = summary
end

function BaganatorItemSummariesMixin:GetTooltipInfo(key, sameConnectedRealm, sameFaction)
  if next(self.SV.Characters.Pending) then
    local start = debugprofilestop()
    for character in pairs(self.SV.Characters.Pending) do
      self.SV.Characters.Pending[character] = nil
      self:GenerateCharacterSummary(character)
    end
    if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
      print("summaries char", debugprofilestop() - start)
    end
  end
  if next(self.SV.Guilds.Pending) then
    local start = debugprofilestop()
    for guild in pairs(self.SV.Guilds.Pending) do
      self.SV.Guilds.Pending[guild] = nil
      self:GenerateGuildSummary(guild)
    end
    if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
      print("summaries guild", debugprofilestop() - start)
    end
  end

  local realms
  if sameConnectedRealm then
    realms = Baganator.Utilities.GetConnectedRealms()
  else
    realms = {}
    for realm in pairs(self.SV.Characters.ByRealm) do
      table.insert(realms, realm)
    end
  end

  local result = {
    characters = {},
    guilds = {},
  }

  local currentFaction = UnitFactionGroup("player")

  for _, r in ipairs(realms) do
    local charactersByRealm = self.SV.Characters.ByRealm[r]
    if charactersByRealm then
      for char, summary in pairs(charactersByRealm) do
        local byKey = summary[key]
        local characterDetails = BAGANATOR_DATA.Characters[char .. "-" .. r].details
        if byKey ~= nil and not characterDetails.hidden and (not sameFaction or characterDetails.faction == currentFaction) then
          table.insert(result.characters, {
            character = char,
            realmNormalized = r,
            className = characterDetails.className,
            bags = byKey.bags or 0, 
            bank = byKey.bank or 0, 
            mail = byKey.mail or 0, 
            equipped = byKey.equipped or 0,
          })
        end
      end
    end
    local guildsByRealm = self.SV.Guilds.ByRealm[r]
    if guildsByRealm then
      for guild, summary in pairs(guildsByRealm) do
        local byKey = summary[key]
        local guildDetails = BAGANATOR_DATA.Guilds[guild .. "-" .. r].details
        if byKey ~= nil and (not sameFaction or guildDetails.faction == currentFaction) then
          table.insert(result.guilds, {
            guild = guild,
            realmNormalized = r,
            bank = byKey.bank or 0
          })
        end
      end
    end
  end

  return result
end
