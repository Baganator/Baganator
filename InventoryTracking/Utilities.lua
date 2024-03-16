local function SplitLink(linkString)
  return linkString:match("^(.*)|H(.-)|h(.*)$")
end

-- Get a key to group items in inventory summaries
function Baganator.Utilities.GetItemKey(itemLink)
  local pre, hyperlink, post = SplitLink(itemLink)

  local parts = { strsplit(":", hyperlink) }

  return parts[1] .. ":" .. parts[2]
end

function Baganator.Utilities.IsEquipment(itemLink)
  local classID = select(6, GetItemInfoInstant(itemLink))
  return classID ~= nil and (
    -- Regular equipment
    classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon
    -- Profession equipment (retail only)
    or classID == Enum.ItemClass.Profession
  )
end

-- Order of parameters for the battle pet hyperlink string
local battlePetTooltip = {
  "battlePetSpeciesID",
  "battlePetLevel",
  "battlePetBreedQuality",
  "battlePetMaxHealth",
  "battlePetPower",
  "battlePetSpeed",
}

function Baganator.Utilities.RecoverBattlePetLink(tooltipInfo)
  if not tooltipInfo then
    print("miss")
    return
  end

  local itemString = "battlepet"
  for _, key in ipairs(battlePetTooltip) do
    itemString = itemString .. ":" .. tooltipInfo[key]
  end

  -- Add a nil GUID and displayID so that DressUpLink will preview the battle
  -- pet
  local speciesID = tonumber(tooltipInfo.battlePetSpeciesID)
  local displayID = select(12, C_PetJournal.GetPetInfoBySpeciesID(speciesID))
  itemString = itemString .. ":0000000000000000:" .. displayID

  local name = C_PetJournal.GetPetInfoBySpeciesID(tooltipInfo.battlePetSpeciesID)
  local quality = ITEM_QUALITY_COLORS[tooltipInfo.battlePetBreedQuality].color
  return quality:WrapTextInColorCode("|H" .. itemString .. "|h[" .. name .. "]|h"), tooltipInfo.battlePetBreedQuality
end

local cachedConnectedRealms
function Baganator.Utilities.CacheConnectedRealms()
  cachedConnectedRealms = GetAutoCompleteRealms()
  if #cachedConnectedRealms == 0 then
    cachedConnectedRealms = {GetNormalizedRealmName()}
  end
end

function Baganator.Utilities.GetConnectedRealms()
  return cachedConnectedRealms
end

function Baganator.Utilities.RemoveCharacter(characterName)
  local characterData = BAGANATOR_DATA.Characters[characterName or ""]
  assert(characterData, "Unrecognised character")

  BAGANATOR_DATA.Characters[characterName] = nil
  local realmSummary = BAGANATOR_SUMMARIES.Characters.ByRealm[characterData.details.realmNormalized]
  if realmSummary and realmSummary[characterData.details.character] then
    realmSummary[characterData.details.character] = nil
  end
  Baganator.CallbackRegistry:TriggerEvent("CharacterDeleted", characterName)
end

local genders = {"unknown", "male", "female"}
local raceCorrections = {
  ["scourge"] = "undead",
  ["zandalaritroll"] = "zandalari",
  ["highmountaintauren"] = "highmountain",
  ["lightforgeddraenei"] = "lightforged",
}
local prefix
if Baganator.Constants.IsRetail then
  prefix = "raceicon128"
else
  prefix = "raceicon"
end
function Baganator.Utilities.GetCharacterIcon(race, sex)
  race = race:lower()
  return "|A:"..prefix.."-" .. (raceCorrections[race] or race) .. "-" .. genders[sex] .. ":13:13|a"
end
function Baganator.Utilities.GetGuildIcon()
  return "|A:communities-guildbanner-background:13:13|a"
end
