local function SplitLink(linkString)
  return linkString:match("^(.*)|H(.-)|h(.*)$")
end
-- Assumes itemLink is in the format found at
-- https://wowpedia.fandom.com/wiki/ItemLink
-- itemID : enchantID : gemID1 : gemID2 : gemID3 : gemID4
-- : suffixID : uniqueID : linkLevel : specializationID : modifiersMask : itemContext
-- : numBonusIDs[:bonusID1:bonusID2:...] : numModifiers[:modifierType1:modifierValue1:...]
-- : relic1NumBonusIDs[:relicBonusID1:relicBonusID2:...] : relic2NumBonusIDs[...] : relic3NumBonusIDs[...]
-- : crafterGUID : extraEnchantID
local function KeyPartsItemLink(itemLink)
  local pre, hyperlink, post = SplitLink(itemLink)

  local parts = { strsplit(":", hyperlink) }

  -- offset by 1 because the first item in "item", not the id
  for i = 3, 7 do
    parts[i] = ""
  end

  -- Remove uniqueID, linkLevel, specializationID, modifiersMask and itemContext
  for i = 9, 13 do
    parts[i] = ""
  end

  local numBonusIDs = tonumber(parts[14] or "") or 0

  for i = 14 + numBonusIDs + 1, #parts do
    parts[i] = nil
  end

  return strjoin(":", unpack(parts))
end

local function KeyPartsPetLink(itemLink)
  local pre, hyperlink, post = SplitLink(itemLink)

  local parts = { strsplit(":", hyperlink) }

  for i = 6, #parts do
    parts[i] = nil
  end

  return strjoin(":", unpack(parts))
end

function Baganator.Utilities.IsEquipment(itemLink)
  local classID = select(6, GetItemInfoInstant(itemLink))
  return classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon or (C_AuctionHouse and classID == Enum.ItemClass.Profession)
end

local IsEquipment = Baganator.Utilities.IsEquipment

-- Assumes the item link has been refreshed since the last patch
function Baganator.Utilities.GetItemKey(itemLink)
  -- Battle pets
  if itemLink:match("battlepet:") then
    return "p:" .. KeyPartsPetLink(itemLink)
  -- Keystone
  elseif itemLink:match("keystone:") then
    return (select(2, SplitLink(itemLink)))
  -- Equipment
  elseif IsEquipment(itemLink) then
    return "g:" .. KeyPartsItemLink(itemLink)
  -- Everything else
  else
    return "i:" .. GetItemInfoInstant(itemLink)
  end
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

function Baganator.Utilities.GetConnectedRealms()
  local realms = GetAutoCompleteRealms()
  if #realms == 0 then
    realms = {GetNormalizedRealmName()}
  end

  return realms
end
