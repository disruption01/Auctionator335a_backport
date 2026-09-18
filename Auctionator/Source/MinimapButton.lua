-- Auctionator 3.3.5a minimap button
-- Kept deliberately legacy/local: no modern Blizzard globals, LibDBIcon, Settings,
-- BackdropTemplate, or other feature-detection shims are created here.

Auctionator.MinimapButton = Auctionator.MinimapButton or {}

local MinimapButton = Auctionator.MinimapButton

local DEFAULT_ANGLE = 225
local BUTTON_SIZE = 32
local LINKS = {
  github = "https://github.com/disruption01/Auctionator335a_backport",
  discord = "https://discord.gg/eJ5MaVNnBm",
  support = "https://linktr.ee/disruption01",
  issues = "https://github.com/disruption01/Auctionator335a_backport/issues",
  curseforge = "https://www.curseforge.com/wow/addons/auctionator",
  upstream = "https://github.com/TheMouseNest/Auctionator",
}

local function GetVersion()
  local getter = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
  if getter then
    return getter("Auctionator", "Version") or "1.0.2"
  end
  return "1.0.2"
end

local function GetSavedState()
  if type(Auctionator.SavedState) == "table" then
    Auctionator.SavedState.MinimapButton = Auctionator.SavedState.MinimapButton or {}
    return Auctionator.SavedState.MinimapButton
  end

  AUCTIONATOR_SAVEDVARS = AUCTIONATOR_SAVEDVARS or {}
  AUCTIONATOR_SAVEDVARS.MinimapButton = AUCTIONATOR_SAVEDVARS.MinimapButton or {}
  return AUCTIONATOR_SAVEDVARS.MinimapButton
end

local function Atan2(y, x)
  if math.atan2 then
    return math.atan2(y, x)
  end
  if x > 0 then
    return math.atan(y / x)
  elseif x < 0 and y >= 0 then
    return math.atan(y / x) + math.pi
  elseif x < 0 and y < 0 then
    return math.atan(y / x) - math.pi
  elseif x == 0 and y > 0 then
    return math.pi / 2
  elseif x == 0 and y < 0 then
    return -math.pi / 2
  end
  return 0
end

local function PositionButton(button, angle)
  if not Minimap or not button then
    return
  end

  angle = tonumber(angle) or DEFAULT_ANGLE
  local radius = ((Minimap.GetWidth and Minimap:GetWidth()) or 140) / 2 + 8
  local radians = math.rad(angle)
  local x = math.cos(radians) * radius
  local y = math.sin(radians) * radius

  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function GetCursorAngle()
  if not Minimap or not Minimap.GetCenter then
    return DEFAULT_ANGLE
  end

  local mx, my = Minimap:GetCenter()
  local cx, cy = GetCursorPosition()
  local scale = Minimap.GetEffectiveScale and Minimap:GetEffectiveScale() or 1
  if not scale or scale == 0 then
    scale = 1
  end
  cx, cy = cx / scale, cy / scale

  return math.deg(Atan2(cy - my, cx - mx))
end

local function OpenSettings()
  -- If the Auction House Info tab exists, reuse its 3.3.5a-safe OpenOptions
  -- path so the AH is hidden behind the translucent Interface Options frame.
  local infoFrame = _G.AuctionatorConfigFrame
  if infoFrame and type(infoFrame.OpenOptions) == "function" and
     _G.AuctionFrame and _G.AuctionFrame.IsShown and _G.AuctionFrame:IsShown() then
    infoFrame:OpenOptions()
    return
  end

  if type(InterfaceOptionsFrame_OpenToCategory) ~= "function" then
    if DEFAULT_CHAT_FRAME then
      DEFAULT_CHAT_FRAME:AddMessage("|cffffd200Auctionator:|r Interface Options are unavailable on this client.")
    end
    return
  end

  local panel = _G.AuctionatorConfigBasicOptionsFrame or Auctionator.State.OptionsCategory
  if panel then
    -- 3.3.5a commonly needs this twice to select the requested child panel.
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)
  end
end

local function PresentLink(label, url)
  if type(ChatFrame_OpenChat) == "function" then
    ChatFrame_OpenChat(url)
  elseif DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd200Auctionator - " .. label .. ":|r " .. url)
  end
end

local menuFrame
local function ShowMenu()
  if type(EasyMenu) ~= "function" then
    OpenSettings()
    return
  end

  if not menuFrame then
    -- UIDropDownMenuTemplate is native to 3.3.5a. Do not substitute a modern
    -- template or publish a fake Blizzard feature-detection global.
    menuFrame = CreateFrame("Frame", "Auctionator335MinimapMenu", UIParent, "UIDropDownMenuTemplate")
  end

  local version = GetVersion()
  local menu = {
    { text = "Auctionator |cff00ff00v" .. version .. "|r", isTitle = true, notCheckable = true },
    { text = "Original addon: Borj(amacare), plusmouse", disabled = true, notCheckable = true },
    { text = "3.3.5a backport: Disruption01", disabled = true, notCheckable = true },
    { text = " ", disabled = true, notCheckable = true },
    { text = "Open Settings", notCheckable = true, func = OpenSettings },
    { text = "GitHub - 3.3.5a Backport", notCheckable = true, func = function() PresentLink("GitHub", LINKS.github) end },
    { text = "Discord", notCheckable = true, func = function() PresentLink("Discord", LINKS.discord) end },
    { text = "Support / Linktree", notCheckable = true, func = function() PresentLink("Support", LINKS.support) end },
    { text = "Report a Bug", notCheckable = true, func = function() PresentLink("Bug Reports", LINKS.issues) end },
    { text = "Original Project - CurseForge", notCheckable = true, func = function() PresentLink("Original Project", LINKS.curseforge) end },
    { text = "Upstream GitHub", notCheckable = true, func = function() PresentLink("Upstream GitHub", LINKS.upstream) end },
    { text = "Close", notCheckable = true, func = function() CloseDropDownMenus() end },
  }

  EasyMenu(menu, menuFrame, "cursor", 0, 0, "MENU", 2)
end

local function ShowTooltip(button)
  GameTooltip:SetOwner(button, "ANCHOR_LEFT")
  GameTooltip:AddLine("Auctionator |cff00ff00v" .. GetVersion() .. "|r", 1, 0.82, 0)
  GameTooltip:AddLine("Original addon by Borj(amacare) and plusmouse", 1, 1, 1)
  GameTooltip:AddLine("WoW 3.3.5a backport by |cff00ff00Disruption01|r", 1, 1, 1)
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("Left-click: Open settings", 0.8, 0.8, 0.8)
  GameTooltip:AddLine("Right-click: Credits and links", 0.8, 0.8, 0.8)
  GameTooltip:AddLine("Drag: Move button", 0.8, 0.8, 0.8)
  GameTooltip:Show()
end

function MinimapButton.Create()
  if MinimapButton.Button or not Minimap then
    return
  end

  local button = CreateFrame("Button", "AuctionatorMinimapButton", Minimap)
  MinimapButton.Button = button

  button:SetWidth(BUTTON_SIZE)
  button:SetHeight(BUTTON_SIZE)
  button:SetFrameStrata("MEDIUM")
  if button.SetFrameLevel and Minimap.GetFrameLevel then
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
  end
  button:SetMovable(true)
  button:EnableMouse(true)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")

  -- Native legacy minimap-button artwork. This keeps the button round on
  -- stock 3.3.5a and derived 3.3.5a clients without using modern texture masks.
  local background = button:CreateTexture(nil, "BACKGROUND")
  background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  background:SetWidth(20)
  background:SetHeight(20)
  background:SetPoint("CENTER", button, "CENTER", 0, 0)
  button.Background = background

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetTexture("Interface\\AddOns\\Auctionator\\Images\\Logo")
  icon:SetWidth(18)
  icon:SetHeight(18)
  icon:SetPoint("CENTER", button, "CENTER", 0, 0)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  button.Icon = icon

  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetWidth(52)
  border:SetHeight(52)
  border:SetPoint("CENTER", button, "CENTER", 0, 0)
  button.Border = border

  local highlight = button:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  highlight:SetBlendMode("ADD")
  highlight:SetWidth(24)
  highlight:SetHeight(24)
  highlight:SetPoint("CENTER", button, "CENTER", 0, 0)

  PositionButton(button, GetSavedState().angle)

  button:SetScript("OnEnter", function(self)
    ShowTooltip(self)
  end)

  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  button:SetScript("OnClick", function(self, mouseButton)
    if self.__auctionatorDragEndedAt and GetTime() - self.__auctionatorDragEndedAt < 0.20 then
      return
    end

    if mouseButton == "RightButton" then
      ShowMenu()
    else
      OpenSettings()
    end
  end)

  button:SetScript("OnDragStart", function(self)
    self.__auctionatorDragging = true
    GameTooltip:Hide()
  end)

  button:SetScript("OnDragStop", function(self)
    if not self.__auctionatorDragging then
      return
    end
    self.__auctionatorDragging = false
    local angle = GetCursorAngle()
    GetSavedState().angle = angle
    PositionButton(self, angle)
    self.__auctionatorDragEndedAt = GetTime()
  end)

  button:SetScript("OnUpdate", function(self)
    if self.__auctionatorDragging then
      PositionButton(self, GetCursorAngle())
    end
  end)
end

local loader = CreateFrame("Frame", "Auctionator335MinimapButtonLoader", UIParent)
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
  MinimapButton.Create()
  self:UnregisterEvent("PLAYER_LOGIN")
end)
