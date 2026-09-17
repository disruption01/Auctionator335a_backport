AuctionatorExportTextFrameMixin = {}

local function Auctionator335StyleExportTextDialog(frame)
  frame:SetSize(520, 360)
  if frame.Bg then
    frame.Bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    frame.Bg:SetVertexColor(0.36, 0.36, 0.36, 1)
  end
  if frame.SetBackdrop then
    frame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 24,
      insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    frame:SetBackdropColor(0.16, 0.16, 0.16, 1)
    frame:SetBackdropBorderColor(1, 1, 1, 1)
  end
  if frame.Inset and frame.Inset.Bg then
    frame.Inset.Bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    frame.Inset.Bg:SetVertexColor(0.16, 0.16, 0.16, 1)
  end
end

local function Auctionator335SetupExportTextScroll(frame)
  local editBox = frame.EditBoxContainer
  local inset = frame.Inset
  if not editBox or not inset then return end

  editBox.GetEditBox = editBox.GetEditBox or function(box) return box end
  if editBox.SetAutoFocus then editBox:SetAutoFocus(false) end
  if editBox.SetMultiLine then editBox:SetMultiLine(true) end

  local scroll = CreateFrame("ScrollFrame", nil, frame)
  scroll:SetPoint("TOPLEFT", inset, "TOPLEFT", 8, -8)
  scroll:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -20, 8)
  scroll:EnableMouseWheel(true)

  editBox:SetParent(scroll)
  editBox:ClearAllPoints()
  editBox:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
  scroll:SetScrollChild(editBox)

  frame.__auctionator335TextScroll = scroll

  local function UpdateRange()
    local viewHeight = math.max(1, scroll:GetHeight())
    local viewWidth = math.max(40, scroll:GetWidth() - 4)
    editBox:SetWidth(viewWidth)

    local text = editBox:GetText() or ""
    local lines = 1
    for _ in string.gmatch(text, "\n") do lines = lines + 1 end
    local contentHeight = math.max(viewHeight, lines * 14 + 10)
    editBox:SetHeight(contentHeight)

    local maxScroll = math.max(0, contentHeight - viewHeight)
    if frame.ScrollBar then
      frame.ScrollBar:Show()
      frame.ScrollBar:SetMinMaxValues(0, maxScroll)
      frame.ScrollBar:SetValueStep(14)
      local current = math.min(frame.ScrollBar:GetValue() or 0, maxScroll)
      frame.ScrollBar:SetValue(current)
      frame.ScrollBar:SetScript("OnValueChanged", function(_, value)
        scroll:SetVerticalScroll(value or 0)
      end)
    end
  end

  scroll:SetScript("OnMouseWheel", function(_, delta)
    local bar = frame.ScrollBar
    if not bar then return end
    local lo, hi = bar:GetMinMaxValues()
    local value = bar:GetValue() or 0
    value = math.max(lo or 0, math.min(hi or 0, value - delta * 42))
    bar:SetValue(value)
  end)

  editBox:SetScript("OnTextChanged", UpdateRange)
  frame.__auctionator335UpdateTextScroll = UpdateRange
  UpdateRange()
end

function AuctionatorExportTextFrameMixin:OnLoad()
  Auctionator335StyleExportTextDialog(self)

  if self.Inset then
    self.Inset:ClearAllPoints()
    self.Inset:SetPoint("TOPLEFT", self, "TOPLEFT", 12, -34)
    self.Inset:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 46)
  end
  if self.Close and self.Inset then
    self.Close:ClearAllPoints()
    self.Close:SetPoint("TOPRIGHT", self.Inset, "BOTTOMRIGHT", 0, -5)
  end

  Auctionator335SetupExportTextScroll(self)
end

function AuctionatorExportTextFrameMixin:SetOpeningEvents(open, close)
  self.openEvent = open
  self.closeEvent = close
end

function AuctionatorExportTextFrameMixin:OnShow()
  Auctionator.Debug.Message("AuctionatorExportTextFrameMixin:OnShow()")

  self.EditBoxContainer:GetEditBox():SetFocus()
  self.EditBoxContainer:GetEditBox():HighlightText()

  if self.openEvent then
    Auctionator.EventBus
      :RegisterSource(self, "lists export text dialog 2")
      :Fire(self, self.openEvent)
      :UnregisterSource(self)
  end
end

function AuctionatorExportTextFrameMixin:OnHide()
  self:Hide()

  if self.closeEvent then
    Auctionator.EventBus
      :RegisterSource(self, "lists export text dialog 2")
      :Fire(self, self.closeEvent)
      :UnregisterSource(self)
  end
end

function AuctionatorExportTextFrameMixin:SetExportString(exportString)
  self.EditBoxContainer:GetEditBox():SetText(exportString)
  if self.__auctionator335UpdateTextScroll then self.__auctionator335UpdateTextScroll() end
  if self.ScrollBar then self.ScrollBar:SetValue(0) end
  self.EditBoxContainer:GetEditBox():HighlightText()
end

function AuctionatorExportTextFrameMixin:OnCloseClicked()
  self.EditBoxContainer:GetEditBox():SetText("")
  self:Hide()
end
