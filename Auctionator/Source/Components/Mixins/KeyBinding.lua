AuctionatorKeyBindingConfigMixin = CreateFromMixins(AuctionatorConfigTooltipMixin)

function AuctionatorKeyBindingConfigMixin:OnLoad()
  self.isListening = false
  self.Auctionator335AllowKeyboardCapture = false
  if not self.Description and self.CreateFontString then
    self.Description = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.Description:SetPoint("LEFT", self, "LEFT", 25, 0)
    self.Description:SetWidth(280)
    self.Description:SetJustifyH("LEFT")
  end
  if self.Description then self.Description:SetText(self.labelText or "") end
  self.shortcut = self.shortcut or ""
  if self.EnableKeyboard then self:EnableKeyboard(false) end
end

function AuctionatorKeyBindingConfigMixin:SetShortcut(shortcut)
  self.shortcut = shortcut
  if self.shortcut == "" then
    self.Button:SetText(GRAY_FONT_COLOR:WrapTextInColorCode(NOT_BOUND))
  else
    self.Button:SetText(GetBindingText(self.shortcut))
  end
end

function AuctionatorKeyBindingConfigMixin:GetShortcut(shortcut)
  return self.shortcut
end

function AuctionatorKeyBindingConfigMixin:OnHide()
  self:StopListening()
end

function AuctionatorKeyBindingConfigMixin:StartListening()
  -- Direct keyboard capture is hazardous on 3.3.5a. Only allow it while this
  -- visible control is deliberately listening inside Interface Options.
  self.isListening = true
  self.Auctionator335AllowKeyboardCapture = true
  if self.EnableKeyboard then self:EnableKeyboard(true) end
  self:SetScript("OnMouseWheel", self.OnMouseWheel)
  self:SetScript("OnKeyDown", self.OnKeyDown)
  self.Button:SetScript("OnMouseWheel", function(button, ...)
    self:OnMouseWheel(...)
  end)
  if self.Button and self.Button.selectedHighlight then self.Button.selectedHighlight:Show() end
end
function AuctionatorKeyBindingConfigMixin:StopListening()
  self.isListening = false
  self.Auctionator335AllowKeyboardCapture = false
  if self.EnableKeyboard then self:EnableKeyboard(false) end
  self:SetScript("OnMouseWheel", nil)
  self:SetScript("OnKeyDown", nil)
  self.Button:SetScript("OnMouseWheel", nil)
  if self.Button and self.Button.selectedHighlight then self.Button.selectedHighlight:Hide() end
end

function AuctionatorKeyBindingConfigMixin:OnClick(button)
  if button == "LeftButton" or button == "RightButton" then
    if self.isListening then
      self:StopListening()
    else
      self:StartListening()
    end
  else
    self:OnKeyDown(button)
  end
end

function AuctionatorKeyBindingConfigMixin:OnEnter()
  AuctionatorConfigTooltipMixin.OnEnter(self)
  self.Button:LockHighlight()
end
function AuctionatorKeyBindingConfigMixin:OnLeave()
  AuctionatorConfigTooltipMixin.OnLeave(self)
  self.Button:UnlockHighlight()
end

function AuctionatorKeyBindingConfigMixin:OnMouseWheel(delta)
  if delta > 0 then
    self:OnKeyDown("MOUSEWHEELUP")
  else
    self:OnKeyDown("MOUSEWHEELDOWN")
  end
end

function AuctionatorKeyBindingConfigMixin:OnKeyDown(keyOrButton)
  if GetBindingFromClick(keyOrButton) == "SCREENSHOT" then
    self:SetPropagateKeyboardInput(true)
    return
  elseif keyOrButton == "ESCAPE" then
    self:SetShortcut("")
    self:StopListening()
    return
  end

  local keyPressed = GetConvertedKeyOrButton(keyOrButton)
  self:SetPropagateKeyboardInput(false)
  if not IsKeyPressIgnoredForBinding(keyPressed) then
    if CreateKeyChordStringUsingMetaKeyState then
      keyPressed = CreateKeyChordStringUsingMetaKeyState(keyPressed)
    else --if Auctionator.Constants.IsClassic
      keyPressed = CreateKeyChordString(keyPressed)
    end
    self:SetShortcut(keyPressed)
    self:StopListening()
  end
end
