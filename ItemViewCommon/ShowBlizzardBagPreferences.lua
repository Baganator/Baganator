-- Copy-and-pasted from -- Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua
local _, addonTable = ...

local function ContainerFrame_IsMainBank(id)
  return id == Enum.BagIndex.Bank;
end

local function ContainerFrame_IsBackpack(id)
  return id == Enum.BagIndex.Backpack;
end

local function AddButtons_BagFilters(description, bagID)
  if not ContainerFrame_CanContainerUseFilterMenu(bagID) then
    return;
  end

  description:CreateTitle(BAG_FILTER_ASSIGN_TO);

  local function IsSelected(flag)
    return C_Container.GetBagSlotFlag(bagID, flag);
  end

  local function SetSelected(flag)
    local value = not IsSelected(flag);
    C_Container.SetBagSlotFlag(bagID, flag, value);
    ContainerFrameSettingsManager:SetFilterFlag(bagID, flag, value);
  end

  for i, flag in ContainerFrameUtil_EnumerateBagGearFilters() do
    local checkbox = description:CreateCheckbox(BAG_FILTER_LABELS[flag], IsSelected, SetSelected, flag);
    checkbox:SetResponse(MenuResponse.Close);
  end
end

local function AddButtons_BagCleanup(description, bagID)
  description:CreateTitle(BAG_FILTER_IGNORE);

  do
    local function IsSelected()
      if ContainerFrame_IsMainBank(bagID) then
        return C_Container.GetBankAutosortDisabled();
      elseif ContainerFrame_IsBackpack(bagID) then
        return C_Container.GetBackpackAutosortDisabled();
      end
      return C_Container.GetBagSlotFlag(bagID, Enum.BagSlotFlags.DisableAutoSort);
    end

    local function SetSelected()
      local value = not IsSelected();
      if ContainerFrame_IsMainBank(bagID) then
        C_Container.SetBankAutosortDisabled(value);
      elseif ContainerFrame_IsBackpack(bagID) then
        C_Container.SetBackpackAutosortDisabled(value);
      else
        C_Container.SetBagSlotFlag(bagID, Enum.BagSlotFlags.DisableAutoSort, value);
      end
    end

    local checkbox = description:CreateCheckbox(BAG_FILTER_CLEANUP, IsSelected, SetSelected);
    checkbox:SetResponse(MenuResponse.Close);
  end

  -- ignore junk selling from this bag or backpack
  if not ContainerFrame_IsMainBank(bagID) then
    local function IsSelected()
      if ContainerFrame_IsBackpack(bagID) then
        return C_Container.GetBackpackSellJunkDisabled();
      end
      return C_Container.GetBagSlotFlag(bagID, Enum.BagSlotFlags.ExcludeJunkSell);
    end

    local function SetSelected()
      local value = not IsSelected();
      if ContainerFrame_IsBackpack(bagID) then
        C_Container.SetBackpackSellJunkDisabled(value);
      else
        C_Container.SetBagSlotFlag(bagID, Enum.BagSlotFlags.ExcludeJunkSell, value);
      end
    end

    local checkbox = description:CreateCheckbox(SELL_ALL_JUNK_ITEMS_EXCLUDE_FLAG, IsSelected, SetSelected);
    checkbox:SetResponse(MenuResponse.Close);
  end
end

function addonTable.ItemViewCommon.AddBlizzardBagContextMenu(originBagID)
  local rootName
  local showReagents = false
  local bagIndexes
  if tIndexOf(Syndicator.Constants.AllBagIndexes, originBagID) ~= nil then
    rootName = BAG_NAME_BACKPACK
    bagIndexes = Syndicator.Constants.AllBagIndexes
    showReagents = true
  else
    rootName = BAGANATOR_L_BANK
    bagIndexes = Syndicator.Constants.AllBankIndexes
  end

  MenuUtil.CreateContextMenu(UIParent, function(ownerRegion, rootDescription)
    rootDescription:SetTag("MENU_CONTAINER_FRAME_COMBINED");

    rootDescription:CreateTitle(BAG_FILTER_TITLE_SORTING);

    for index, bagID in ipairs(bagIndexes) do
      if addonTable.Utilities.GetBagType(bagID) ~= "reagentBag" then
        local name
        if index == 1 then
          name = rootName
        else
          name = BAG_NAME_BAG_1:gsub("1", tostring(index - 1))
        end
        local submenu = rootDescription:CreateButton(name);
        if addonTable.Config.Get(addonTable.Config.Options.SORT_METHOD) == "blizzard" then
          AddButtons_BagFilters(submenu, bagID);
        end
        AddButtons_BagCleanup(submenu, bagID);
      end
    end
    if showReagents and addonTable.Utilities.GetBagType(bagIndexes[#bagIndexes]) == "reagentBag" then
        local submenu = rootDescription:CreateButton(BAGANATOR_L_REAGENTS);
        AddButtons_BagCleanup(submenu, bagIndexes[#bagIndexes]);
    end
  end)
end
