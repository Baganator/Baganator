local function SplitLink(linkString)
  return linkString:match("^(.*)|H(.-)|h(.*)$")
end

-- Assumes the item link has been refreshed since the last patch
function Baganator.Utilities.GetItemKey(itemLink)
  local pre, hyperlink, post = SplitLink(itemLink)

  local parts = { strsplit(":", hyperlink) }

  return parts[1] .. ":" .. parts[2]
end

function Baganator.Utilities.IsEquipment(itemLink)
  local classID = select(6, GetItemInfoInstant(itemLink))
  return classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon or (C_AuctionHouse and classID == Enum.ItemClass.Profession)
end

function Baganator.Utilities.HasItemLevel(itemLink)
  local classID, subClassID = select(6, GetItemInfoInstant(itemLink))
  return classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon
    -- Profession equipment
    or (C_AuctionHouse and classID == Enum.ItemClass.Profession)
    -- Artifact relics and special effect stones
    or (classID == Enum.ItemClass.Gem and (subClassID == 9 or subClassID == 11))
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

  local name = C_PetJournal.GetPetInfoBySpeciesID(tooltipInfo.battlePetSpeciesID)
  local quality = ITEM_QUALITY_COLORS[tooltipInfo.battlePetBreedQuality].color
  return quality:WrapTextInColorCode("|H" .. itemString .. "|h[" .. name .. "]|h")
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
