AuctionatorListImportFrameMixin = {}

local function Auctionator335StyleTextDialog(frame, width, height)
  frame:SetSize(width, height)
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

local function Auctionator335SetupTextScroll(frame)
  local editBox = frame.EditBoxContainer
  local inset = frame.Inset
  if not editBox or not inset then return end

  editBox.GetEditBox = editBox.GetEditBox or function(box) return box end
  if editBox.SetAutoFocus then editBox:SetAutoFocus(false) end
  if editBox.SetMultiLine then editBox:SetMultiLine(true) end

  if not frame.__auctionator335TextScroll then
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
  end

  if frame.__auctionator335UpdateTextScroll then
    frame.__auctionator335UpdateTextScroll()
  end
end

function AuctionatorListImportFrameMixin:OnLoad()
  Auctionator.Debug.Message("AuctionatorListImportFrameMixin:OnLoad()")

  Auctionator335StyleTextDialog(self, 430, 330)

  if self.Inset then
    self.Inset:ClearAllPoints()
    self.Inset:SetPoint("TOPLEFT", self, "TOPLEFT", 12, -34)
    self.Inset:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 46)
  end
  if self.Import and self.Inset then
    self.Import:ClearAllPoints()
    self.Import:SetPoint("TOPRIGHT", self.Inset, "BOTTOMRIGHT", 0, -5)
  end

  Auctionator335SetupTextScroll(self)
end

function AuctionatorListImportFrameMixin:OnShow()
  Auctionator.Debug.Message("AuctionatorListImportFrameMixin:OnShow()")

  if self.__auctionator335UpdateTextScroll then self.__auctionator335UpdateTextScroll() end
  self.EditBoxContainer:GetEditBox():SetFocus()

  Auctionator.EventBus
    :RegisterSource(self, "lists import dialog")
    :Fire(self, Auctionator.Shopping.Tab.Events.DialogOpened)
    :UnregisterSource(self)
end

function AuctionatorListImportFrameMixin:OnHide()
  self.EditBoxContainer:GetEditBox():SetText("")
  self:Hide()
  Auctionator.EventBus
    :RegisterSource(self, "lists import dialog")
    :Fire(self, Auctionator.Shopping.Tab.Events.DialogClosed)
    :UnregisterSource(self)
end

function AuctionatorListImportFrameMixin:ReceiveEvent(eventName, eventData)
  if eventName == Auctionator.Shopping.Events.ListImportFinished then
    Auctionator.EventBus:Unregister(self, { Auctionator.Shopping.Events.ListImportFinished })
    Auctionator.EventBus
      :RegisterSource(self, "lists import dialog")
      :Fire(self, Auctionator.Shopping.Tab.Events.ListCreated, Auctionator.Shopping.ListManager:GetByName(eventData))
      :UnregisterSource(self)
  end
end

function AuctionatorListImportFrameMixin:OnCloseDialogClicked()
  self:Hide()
end

function AuctionatorListImportFrameMixin:OnImportClicked()
  -- register finished event early as sometimes it fires immediately
  Auctionator.EventBus:Register(self, { Auctionator.Shopping.Events.ListImportFinished })

  local importString = self.EditBoxContainer:GetEditBox():GetText()

  local waiting = true
  if string.match(importString, "%^") then
    Auctionator.Debug.Message("Import shopping list with 8.3+ format")
    Auctionator.Shopping.Lists.BatchImportFromString(importString)
  elseif string.match(importString, "%*") then
    Auctionator.Debug.Message("Import shopping list from old format")
    Auctionator.Shopping.Lists.OldBatchImportFromString(importString)
  elseif string.match(importString, "%,") then
    Auctionator.Debug.Message("Import shopping list from TSM group")
    Auctionator.Shopping.Lists.TSMImportFromString(importString)
  else
    waiting = false
  end

  -- Only listen for the import finished event if a valid format was detected
  if not waiting then
    Auctionator.EventBus:Unregister(self, { Auctionator.Shopping.Events.ListImportFinished })
  end

  self:Hide()
end
