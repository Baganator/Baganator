local classicBorderFrames = {
  "BotLeftCorner", "BotRightCorner", "BottomBorder", "LeftBorder", "RightBorder",
  "TopRightCorner", "TopLeftCorner", "TopBorder"
}

function Baganator.Utilities.ApplyVisuals(frame)
  local alpha = Baganator.Config.Get(Baganator.Config.Options.VIEW_ALPHA)
  local noFrameBorders = Baganator.Config.Get(Baganator.Config.Options.NO_FRAME_BORDERS)

  frame.Bg:SetAlpha(alpha)
  frame.TopTileStreaks:SetAlpha(alpha)

  if frame.NineSlice then -- retail
    frame.NineSlice:SetAlpha(alpha)
    frame.NineSlice:SetShown(not noFrameBorders)
    if noFrameBorders then
      frame.Bg:SetPoint("TOPLEFT", 6, 0)
      frame.TopTileStreaks:SetPoint("TOPLEFT", 6, 0)
    else
      frame.Bg:SetPoint("TOPLEFT", 6, -21)
      frame.TopTileStreaks:SetPoint("TOPLEFT", 6, -21)
    end
  elseif frame.TitleBg then -- classic
    frame.TitleBg:SetAlpha(alpha)
    for _, key in ipairs(classicBorderFrames) do
      frame[key]:SetAlpha(alpha)
      frame[key]:SetShown(not noFrameBorders)
    end
    if noFrameBorders then
      frame.Bg:SetPoint("TOPLEFT", 2, 0)
      frame.TopTileStreaks:SetPoint("TOPLEFT", 2, 0)
      frame.Bg:SetPoint("BOTTOMRIGHT", -2, 0)
    else
      frame.Bg:SetPoint("TOPLEFT", 2, -21)
      frame.Bg:SetPoint("BOTTOMRIGHT", -2, 2)
      frame.TopTileStreaks:SetPoint("TOPLEFT", 2, -21)
    end
  end
end
