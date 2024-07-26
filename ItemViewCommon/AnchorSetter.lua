local _, addonTable = ...
function addonTable.ItemViewCommon.GetAnchorSetter(parent, setting)
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetAllPoints()

  local circleAtlas = "common-mask-circle"
  if not C_Texture.GetAtlasInfo(circleAtlas) then
    circleAtlas = "CircleMaskScalable"
  end
  local function GetBox()
    local frame = CreateFrame("Button", nil, holder)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(1000)
    frame:SetSize(50, 50)
    local visual = frame:CreateTexture(nil, "ARTWORK")
    visual:SetAtlas(circleAtlas)
    visual:SetAllPoints()
    frame.visual = visual
    local checked = frame:CreateTexture(nil, "OVERLAY")
    checked:SetAtlas("common-icon-checkmark")
    checked:SetPoint("CENTER")
    checked:SetSize(33, 33)
    frame.checked = checked
    frame.checked:Hide()
    return frame
  end
  
  local points = {
    "TOPLEFT", "TOPRIGHT",
    "BOTTOMLEFT", "BOTTOMRIGHT",
    "RIGHT", "LEFT",
    "TOP", "BOTTOM",
  }

  local boxes = {}

  for _, p in ipairs(points) do
    local box = GetBox()
    local offsetX, offsetY = 0, 0
    if p:find("LEFT") then
      offsetX = addonTable.Constants.ButtonFrameOffset + 10
    end
    if p:find("RIGHT") then
      offsetX = -10
    end
    if p:find("TOP") then
      offsetY = -30
    end
    if p:find("BOTTOM") then
      offsetY = 10
    end
    box:SetPoint(p, offsetX, offsetY)
    box:SetScript("OnClick", function()
      addonTable.Config.Set(setting, {addonTable.Utilities.ConvertAnchorToCorner(p, parent)})
    end)
    boxes[p] = box
  end

  local function ApplySetting()
    for p, box in pairs(boxes) do
      if p ~= addonTable.Config.Get(setting)[1] then
        box:SetAlpha(0.8)
        box.visual:SetVertexColor(108/255, 209/255, 252/255)
        box.checked:Hide()
      else
        box:SetAlpha(1)
        box.visual:SetVertexColor(255/255, 165/255, 0/255)
        box.checked:Show()
      end
    end
  end

  holder:SetScript("OnShow", function()
    holder:Raise()
    ApplySetting()
  end)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if settingName == setting and holder:IsVisible() then
      ApplySetting()
    elseif settingName == addonTable.Config.Options.SETTING_ANCHORS then
      holder:SetShown(addonTable.Config.Get(addonTable.Config.Options.SETTING_ANCHORS))
    end
  end)

  holder:SetShown(addonTable.Config.Get(addonTable.Config.Options.SETTING_ANCHORS))

  return holder
end
