local _, addonTable = ...

function addonTable.Skins.IsAddOnLoading(name)
  local character = UnitName("player")
  if C_AddOns.GetAddOnEnableState(name, character) ~= Enum.AddOnEnableState.All then
    return false
  end
  for _, dep in ipairs({C_AddOns.GetAddOnDependencies(name)}) do
    if not addonTable.Skins.IsAddOnLoading(dep) then
      return false
    end
  end
  return true
end

local function ToHSL(r, g, b)
  local M = math.max(r, g, b)
  local m = math.min(r, g, b)

  local c = M - m

  local h_dash
  if c == 0 then
    h_dash = 0
  elseif M == r then
    h_dash = ((g - b) / c) % 6
  elseif M == g then
    h_dash = (b - r) / c + 2
  elseif M == b then
    h_dash = (r - g) / c + 4
  end
  local h = h_dash * 60

  local l = 1/2 * (M + m)

  local s
  if l == 1 or l == 0 then
    s = 0
  else
    s = c / (1 - math.abs(2 * l - 1))
  end

  return h, s, l
end

local function FromHSL_Prev(h, s, l)
  c = (1 - math.abs(2 * l - 1)) * s
  h_dash = h / 60
  x = c * ( 1 - math.abs(h_dash % 2 - 1))
  m = l - c / 2
  if h < 1 then
    return c + m, x + m, 0 + m
  elseif h < 2 then
    return x + m, c + m, 0 + m
  elseif h < 3 then
    return 0 + m, c + m, x + m
  elseif h < 4 then
    return 0 + m, x + m, c + m
  elseif h < 5 then
    return x + m, 0 + m, c + m
  else
    return c + m, 0 + m, x + m
  end
end

local function FromHSL(h, s, l)
  local function f(n)
    local k = (n + h/30) % 12
    local a = s * math.min(l, 1-l)
    return l - a * math.max(-1, math.min(k - 3, 9 - k, 1))
  end
  return f(0), f(8), f(4)
end

function addonTable.Skins.Lighten(r, g, b, shift)
  local h, s, l = ToHSL(r, g, b)
  l = math.max(0, math.min(1, l + shift))

  return FromHSL(h, s, l)
end
