AuctionatorConfigTabMixin = {}

local function Auctionator335FixInfoLayout(self)
  if not self then return end

  if self.AuthorHeading and self.AuthorHeading.HeadingText then self.AuthorHeading.HeadingText:SetText("Original Authors") end
  if self.ContributorsHeading and self.ContributorsHeading.HeadingText then self.ContributorsHeading.HeadingText:SetText("Backport") end
  if self.VersionHeading and self.VersionHeading.HeadingText then self.VersionHeading.HeadingText:SetText(AUCTIONATOR_L_VERSION_HEADER) end
  if self.Author and self.Author.SetText then self.Author:SetText("Borj(amacare), plusmouse") end
  if self.Contributors and self.Contributors.SetText then self.Contributors:SetText("Disruption01") end
  if self.Version and self.Version.SetText then self.Version:SetText("|cff00ff00v1.0.2|r") end

  if self.ScanButton then
    self.ScanButton:SetWidth(96)
    self.ScanButton:SetHeight(22)
    self.ScanButton:ClearAllPoints()
    self.ScanButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -4, 42)
  end
  if self.OptionsButton and self.ScanButton then
    self.OptionsButton:SetWidth(176)
    self.OptionsButton:SetHeight(22)
    self.OptionsButton:ClearAllPoints()
    self.OptionsButton:SetPoint("RIGHT", self.ScanButton, "LEFT", -8, 0)
  end
  if self.ScanStatus and self.ScanButton then
    self.ScanStatus:ClearAllPoints()
    self.ScanStatus:SetPoint("TOP", self.ScanButton, "BOTTOM", 0, -1)
  end
end

local function Auctionator335RestoreAuctionHouseBehindOptions(infoFrame)
  if not infoFrame then return end

  local ahFrame = infoFrame.__auctionatorOptionsAHFrame
  if ahFrame then
    if ahFrame.SetAlpha then
      ahFrame:SetAlpha(infoFrame.__auctionatorOptionsAHAlpha or 1)
    end
    if ahFrame.EnableMouse and infoFrame.__auctionatorOptionsAHMouseEnabled ~= nil then
      ahFrame:EnableMouse(infoFrame.__auctionatorOptionsAHMouseEnabled)
    end
  end

  infoFrame.__auctionatorOptionsAHFrame = nil
  infoFrame.__auctionatorOptionsAHAlpha = nil
  infoFrame.__auctionatorOptionsAHMouseEnabled = nil

  if infoFrame.SetAlpha then infoFrame:SetAlpha(1) end
  if infoFrame.EnableMouse then infoFrame:EnableMouse(true) end
  Auctionator335FixInfoLayout(infoFrame)
end

function AuctionatorConfigTabMixin:OnLoad()
  Auctionator.Debug.Message("AuctionatorConfigTabMixin:OnLoad()")
  Auctionator335FixInfoLayout(self)
end

function AuctionatorConfigTabMixin:OpenOptions()
  Auctionator335FixInfoLayout(self)

  -- The 3.3.5a Interface Options frame is translucent. Hide the whole auction
  -- house while options are open, not just the Info child, otherwise the empty
  -- Auctionator frame/tabs remain visible behind the options window.
  local ahFrame = _G.AuctionFrame or _G.AuctionHouseFrame
  if ahFrame then
    self.__auctionatorOptionsAHFrame = ahFrame
    self.__auctionatorOptionsAHAlpha = ahFrame.GetAlpha and ahFrame:GetAlpha() or 1
    self.__auctionatorOptionsAHMouseEnabled = ahFrame.IsMouseEnabled and ahFrame:IsMouseEnabled() or true
    if ahFrame.SetAlpha then ahFrame:SetAlpha(0) end
    if ahFrame.EnableMouse then ahFrame:EnableMouse(false) end
  else
    if self.SetAlpha then self:SetAlpha(0) end
    if self.EnableMouse then self:EnableMouse(false) end
  end

  -- On 3.3.5a opening the parent category gives a completely blank page. Open
  -- Basic Options directly, matching the useful first page of the TBC UI.
  if InterfaceOptionsFrame_OpenToCategory and _G.AuctionatorConfigBasicOptionsFrame then
    InterfaceOptionsFrame_OpenToCategory(_G.AuctionatorConfigBasicOptionsFrame)
    if C_Timer and C_Timer.After then
      C_Timer.After(0, function()
        if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() and _G.AuctionatorConfigBasicOptionsFrame then
          InterfaceOptionsFrame_OpenToCategory(_G.AuctionatorConfigBasicOptionsFrame)
        end
      end)
    end
  elseif InterfaceOptionsFrame_OpenToCategory and Auctionator.State.OptionsCategory then
    InterfaceOptionsFrame_OpenToCategory(Auctionator.State.OptionsCategory)
  end

  if InterfaceOptionsFrame and InterfaceOptionsFrame.HookScript and not self.__auctionatorOptionsRestoreHook then
    self.__auctionatorOptionsRestoreHook = true
    local infoFrame = self
    InterfaceOptionsFrame:HookScript("OnHide", function()
      Auctionator335RestoreAuctionHouseBehindOptions(infoFrame)
    end)
  elseif not InterfaceOptionsFrame then
    Auctionator335RestoreAuctionHouseBehindOptions(self)
  end
end
