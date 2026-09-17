AuctionatorPanelConfigMixin = {}

Auctionator335Config = Auctionator335Config or {}

function Auctionator335Config.GetContentWidth(panel)
  local width = panel and panel.GetWidth and panel:GetWidth() or 0
  if not width or width < 300 then
    width = 500
  end
  return math.max(360, math.min(420, width - 28))
end

function Auctionator335Config.PrepareTitle(panel, titleArea)
  if not titleArea then return end
  local width = Auctionator335Config.GetContentWidth(panel)
  titleArea:ClearAllPoints()
  titleArea:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
  titleArea:SetWidth(width)
  titleArea:SetHeight(60)
  if titleArea.SubTitle then
    titleArea.SubTitle:SetWidth(math.max(320, width - 40))
  end
end

-- The retail/TBC options use a modern ScrollBox that doesn't exist on 3.3.5a.
-- This is a deliberately small legacy replacement used only by long config pages.
function Auctionator335Config.PrepareScroll(panel, key, topOffset, contentHeight, content)
  if not panel or not content then return nil end

  local data = panel[key]
  if not data then
    local scroll = CreateFrame("ScrollFrame", nil, panel)
    scroll:EnableMouseWheel(true)

    content:SetParent(scroll)
    content:ClearAllPoints()
    content:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    scroll:SetScrollChild(content)

    -- Parent the legacy scrollbar to the ScrollFrame itself. The 3.3.5a
    -- UIPanelScrollBarTemplate expects its parent to implement SetVerticalScroll.
    local bar = CreateFrame("Slider", nil, scroll, "UIPanelScrollBarTemplate")
    bar:SetWidth(16)
    bar:SetValueStep(24)

    local function setOffset(value)
      value = tonumber(value) or 0
      if scroll.SetVerticalScroll then
        scroll:SetVerticalScroll(value)
      else
        content:ClearAllPoints()
        content:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, value)
      end
    end

    bar:SetScript("OnValueChanged", function(_, value)
      setOffset(value)
    end)

    scroll:SetScript("OnMouseWheel", function(_, delta)
      local minValue, maxValue = bar:GetMinMaxValues()
      local value = math.max(minValue or 0, math.min(maxValue or 0, bar:GetValue() - delta * 36))
      bar:SetValue(value)
    end)

    data = { scroll = scroll, bar = bar, content = content, height = contentHeight }
    panel[key] = data
  end

  data.height = contentHeight
  local width = Auctionator335Config.GetContentWidth(panel)

  data.scroll:ClearAllPoints()
  data.scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -(topOffset or 64))
  data.scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -22, 2)

  data.bar:ClearAllPoints()
  data.bar:SetPoint("TOPLEFT", data.scroll, "TOPRIGHT", 3, -16)
  data.bar:SetPoint("BOTTOMLEFT", data.scroll, "BOTTOMRIGHT", 3, 16)

  data.content:SetWidth(math.max(360, width - 4))
  data.content:SetHeight(contentHeight)

  local function updateRange()
    local viewHeight = data.scroll:GetHeight() or 0
    if viewHeight <= 1 then viewHeight = 390 end
    local maxValue = math.max(0, contentHeight - viewHeight)
    data.bar:SetMinMaxValues(0, maxValue)
    if maxValue > 0 then
      data.bar:Show()
    else
      data.bar:Hide()
      data.bar:SetValue(0)
    end
    if data.bar:GetValue() > maxValue then
      data.bar:SetValue(maxValue)
    end
  end

  data.scroll:SetScript("OnSizeChanged", updateRange)
  updateRange()
  data.scroll:Show()
  data.content:Show()
  return data
end

function Auctionator335Config.WrapFontString(fontString, width, height)
  if not fontString then return end
  if width then fontString:SetWidth(width) end
  if height then fontString:SetHeight(height) end
  fontString:SetJustifyH("LEFT")
  if fontString.SetJustifyV then fontString:SetJustifyV("TOP") end
  if fontString.SetWordWrap then fontString:SetWordWrap(true) end
  if fontString.SetNonSpaceWrap then fontString:SetNonSpaceWrap(true) end
end

function Auctionator335Config.FitCheckbox(frame, width)
  if not frame then return end
  frame:SetWidth(width)
  if frame.CheckBox and frame.CheckBox.Label then
    Auctionator335Config.WrapFontString(frame.CheckBox.Label, math.max(180, width - 70), math.max(24, (frame:GetHeight() or 40) - 4))
  end
end

function Auctionator335Config.FitNumeric(frame, width)
  if not frame then return end
  frame:SetWidth(width)
  if frame.InputBox and frame.InputBox.Label then
    Auctionator335Config.WrapFontString(frame.InputBox.Label, math.max(175, width - 105), math.max(24, (frame:GetHeight() or 40) - 4))
  end
end

function Auctionator335Config.FitKeyBinding(frame, width)
  if not frame then return end
  frame:SetWidth(width)
  if frame.Description then
    Auctionator335Config.WrapFontString(frame.Description, math.max(170, width - 205), math.max(30, (frame:GetHeight() or 35) - 2))
  end
  if frame.Button then
    frame.Button:SetWidth(170)
    frame.Button:ClearAllPoints()
    frame.Button:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
  end
end

local function Auctionator335StyleOptionsPanel(self)
  if self.SetBackdrop then
    self:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = nil,
      tile = false,
    })
    self:SetBackdropColor(0.015, 0.015, 0.015, 0.98)
  end
  if self.SetFrameLevel and InterfaceOptionsFramePanelContainer and InterfaceOptionsFramePanelContainer.GetFrameLevel then
    self:SetFrameLevel(InterfaceOptionsFramePanelContainer:GetFrameLevel() + 2)
  end
end

function AuctionatorPanelConfigMixin:SetupPanel()
  self.cancel = function() self:Cancel() end
  self.okay = function() if self.shownSettings then self:Save() end end
  self.shownSettings = false
  self.OnCommit = self.okay
  self.OnDefault = function() end
  self.OnRefresh = function() end

  Auctionator335StyleOptionsPanel(self)

  if self.parent == nil then
    local category = Settings.RegisterCanvasLayoutCategory(self, self.name)
    Settings.RegisterAddOnCategory(category)
    Auctionator.State.OptionsCategory = category
  else
    local subcategory = Settings.RegisterCanvasLayoutSubcategory(Auctionator.State.OptionsCategory, self, self.name)
    Settings.RegisterAddOnCategory(subcategory)
  end
end

function AuctionatorPanelConfigMixin:OnShow()
  Auctionator335StyleOptionsPanel(self)
  self:ShowSettings()
  self.shownSettings = true
end

function AuctionatorPanelConfigMixin:Cancel()
  Auctionator.Debug.Message("AuctionatorPanelConfigMixin:Cancel() Unimplemented")
end

function AuctionatorPanelConfigMixin:Save()
  Auctionator.Debug.Message("AuctionatorPanelConfigMixin:Save() Unimplemented")
end
