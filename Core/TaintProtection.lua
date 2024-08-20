local _, addonTable = ...
-- All credit for this fix goes to Numy https://github.com/Numynum
function addonTable.FixActionBarTaint()
  if not addonTable.Constants.IsRetail then
    return
  end

  local events = {
    ['PLAYER_ENTERING_WORLD'] = true,
    ['ACTIONBAR_SLOT_CHANGED'] = true,
    ['UPDATE_BINDINGS'] = true,
    ['GAME_PAD_ACTIVE_CHANGED'] = true,
    ['UPDATE_SHAPESHIFT_FORM'] = true,
    ['ACTIONBAR_UPDATE_COOLDOWN'] = true,
    ['PET_BAR_UPDATE'] = true,
    ['PLAYER_MOUNT_DISPLAY_CHANGED'] = true,
  };
  local petUnitEvents = {
    ['UNIT_FLAGS'] = true,
    ['UNIT_AURA'] = true,
  }
  for _, actionButton in pairs(ActionBarButtonEventsFrame.frames) do
    for event in pairs(events) do
      actionButton:RegisterEvent(event);
    end
    for petUnitEvent in pairs(petUnitEvents) do
      actionButton:RegisterUnitEvent(petUnitEvent, 'pet');
    end
  end
  for event in pairs(events) do
    ActionBarButtonEventsFrame:UnregisterEvent(event);
  end
  for petUnitEvent in pairs(petUnitEvents) do
    ActionBarButtonEventsFrame:UnregisterEvent(petUnitEvent, 'pet');
  end
end
