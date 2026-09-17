AuctionatorListExportFrameMixin = {}

function AuctionatorListExportFrameMixin:OnLoad()
  Auctionator.Debug.Message("AuctionatorListExportFrameMixin:OnLoad()")

  -- 3.3.5a: the modern SimplePanel background texture renders bright green.
  -- Use a compact classic dialog for the shopping-list selector.
  self:SetSize(390, 330)
  if self.Bg then
    self.Bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    self.Bg:SetVertexColor(0.36, 0.36, 0.36, 1)
  end
  if self.SetBackdrop then
    self:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 24,
      insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    self:SetBackdropColor(0.16, 0.16, 0.16, 1)
    self:SetBackdropBorderColor(1, 1, 1, 1)
  end
  if self.Inset then
    if self.Inset.Bg then
      self.Inset.Bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
      self.Inset.Bg:SetVertexColor(0.16, 0.16, 0.16, 1)
    end
    self.Inset:ClearAllPoints()
    self.Inset:SetPoint("TOPLEFT", self, "TOPLEFT", 12, -34)
    self.Inset:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 52)
  end
  if self.SelectAll and self.Inset then
    self.SelectAll:ClearAllPoints()
    self.SelectAll:SetPoint("TOPLEFT", self.Inset, "BOTTOMLEFT", 0, -5)
  end
  if self.UnselectAll and self.SelectAll then
    self.UnselectAll:ClearAllPoints()
    self.UnselectAll:SetPoint("LEFT", self.SelectAll, "RIGHT", 4, 0)
  end
  if self.Export and self.Inset then
    self.Export:ClearAllPoints()
    self.Export:SetPoint("TOPRIGHT", self.Inset, "BOTTOMRIGHT", 0, -5)
  end

  -- Setup scrolling region. The upstream dialog puts manually pooled
  -- checkboxes inside a ResizeLayoutFrame. On 3.3.5a that modern layout
  -- frame has no usable layout/scroll behaviour, leaving the list invisible.
  -- Feed the list directly through our ScrollBox compatibility layer instead.
  local view = CreateScrollBoxLinearView()
  view:SetPadding(5, 5, 0, 0, 0)
  view:SetElementExtent(25)

  local exportFrame = self
  view:SetElementInitializer("AuctionatorConfigurationCheckbox", function(checkBox, listName)
    checkBox:SetText(listName)
    checkBox:SetChecked(false)
    exportFrame.exportCheckBoxes[#exportFrame.exportCheckBoxes + 1] = checkBox
  end)

  ScrollUtil.InitScrollBoxWithScrollBar(self.ScrollBox, self.ScrollBar, view)

  -- This child only exists for the modern ResizeLayoutFrame implementation.
  -- Keeping it visible on 3.3.5a can cover the compatibility ScrollBox rows.
  if self.ScrollBox.ListListingFrame then
    self.ScrollBox.ListListingFrame:Hide()
  end

  self.exportCheckBoxes = {}

  self.copyTextDialog = CreateFrame("Frame", nil, self:GetParent(), "AuctionatorExportTextFrame")
  self.copyTextDialog:SetPoint("CENTER")

  if self:GetParent().dialogs then
    table.insert(self:GetParent().dialogs, self.copyTextDialog)
  end

  -- self.ExportOption:SetOnChange(function(selectedValue)
  --   if selectedValue == Auctionator.Constants.EXPORT_TYPES.WHISPER then
  --     self.Recipient:Show()
  --     self.Recipient:SetFocus()
  --   else
  --     self.Recipient:Hide()
  --   end
  -- end)
  -- self.ExportOption:SetSelectedValue(Auctionator.Constants.EXPORT_TYPES.STRING)

end

function AuctionatorListExportFrameMixin:OnShow()
  Auctionator.Debug.Message("AuctionatorListExportFrameMixin:OnShow()")

  Auctionator.EventBus:Register(self, { Auctionator.Shopping.Events.ListMetaChange })

  self:RefreshLists()

  Auctionator.EventBus
    :RegisterSource(self, "lists export dialog 1")
    :Fire(self, Auctionator.Shopping.Tab.Events.DialogOpened)
    :UnregisterSource(self)
end

function AuctionatorListExportFrameMixin:OnHide()
  self:Hide()

  Auctionator.EventBus:Unregister(self, { Auctionator.Shopping.Events.ListMetaChange })

  Auctionator.EventBus
    :RegisterSource(self, "lists export dialog 1")
    :Fire(self, Auctionator.Shopping.Tab.Events.DialogClosed)
    :UnregisterSource(self)
end

function AuctionatorListExportFrameMixin:ReceiveEvent(eventName, listName)
  if eventName == Auctionator.Shopping.Events.ListMetaChange then
    if self:IsShown() then
      self:RefreshLists()
    end
  end
end

function AuctionatorListExportFrameMixin:RefreshLists()
  Auctionator.Debug.Message("AuctionatorListExportFrameMixin:RefreshLists()")

  self.exportCheckBoxes = {}

  local listNames = {}
  local listCount = Auctionator.Shopping.ListManager:GetCount()
  for index = 1, listCount do
    local list = Auctionator.Shopping.ListManager:GetByIndex(index)
    listNames[#listNames + 1] = list:GetName()
  end

  self.ScrollBox:SetDataProvider(CreateDataProvider(listNames))
end

function AuctionatorListExportFrameMixin:OnCloseDialogClicked()
  self:Hide()
end

function AuctionatorListExportFrameMixin:OnSelectAllClicked()
  for _, checkbox in ipairs(self.exportCheckBoxes or {}) do
    checkbox:SetChecked(true)
  end
end

function AuctionatorListExportFrameMixin:OnUnselectAllClicked()
  for _, checkbox in ipairs(self.exportCheckBoxes or {}) do
    checkbox:SetChecked(false)
  end
end

function AuctionatorListExportFrameMixin:OnExportClicked()
  local exportString = ""

  for _, checkbox in ipairs(self.exportCheckBoxes or {}) do
    if checkbox:GetChecked() then
      exportString = exportString .. Auctionator.Shopping.Lists.GetBatchExportString(checkbox:GetText()) .. "\n"
    end
  end

  -- if self.ExportOption:GetValue() == 0 then
    self:Hide()
    self.copyTextDialog:SetExportString(exportString)
    self.copyTextDialog:Show()
  -- else
    -- Addon messages can not exceed 254 characters, so do lists one by one?
    -- for checkbox in self.checkBoxPool:EnumerateActive() do
    --   if checkbox:IsVisible() and checkbox:GetChecked() then
    --     C_ChatInfo.SendAddonMessage( "Auctionator", Auctionator.Shopping.Lists.GetBatchExportString(checkbox:GetText()), "WHISPER", self.Recipient:GetText())
    --   end
    -- end
    -- C_ChatInfo.SendAddonMessage( "Auctionator", exportString, "WHISPER", self.Recipient:GetText())
  -- end

end
