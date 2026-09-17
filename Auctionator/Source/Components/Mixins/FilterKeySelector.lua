AuctionatorFilterKeySelectorMixin = {}

local ANY_VALUE = ""

local function GetAnyLabel()
  return AUCTIONATOR_L_ANY_UPPER or ANY or "Any"
end

local function FindRootCategory(name)
  for _, category in ipairs(AuctionCategories or {}) do
    if category.name == name then
      return category
    end
  end
end

local function FindChildCategory(category, name)
  if not category or not category.subCategories then
    return nil
  end

  for _, child in ipairs(category.subCategories) do
    if child.name == name then
      return child
    end
  end
end

local function HasChildren(category)
  return category and category.subCategories and #category.subCategories > 0
end

local function SetupRadioMenu(button, labels, values, selectedValue, onChanged)
  local entries = {}
  for index = 1, #labels do
    table.insert(entries, { labels[index], values[index] })
  end

  MenuUtil.CreateRadioMenu(button, function(value)
    return value == selectedValue()
  end, function(value)
    onChanged(value)
  end, unpack(entries))
end

local function EnableDropDown(button, enabled)
  if not button then
    return
  end

  if enabled then
    if button.Enable then button:Enable() end
    if button.SetAlpha then button:SetAlpha(1) end
  else
    if button.Disable then button:Disable() end
    if button.SetAlpha then button:SetAlpha(0.45) end
  end
end

local function SetVisible(button, visible)
  if not button then return end
  if visible then button:Show() else button:Hide() end
end

function AuctionatorFilterKeySelectorMixin:OnLoad()
  self.displayText = ""
  self.selectedRoot = ""
  self.selectedSubClass = ""
  self.selectedDetail = ""
  self.onEntrySelected = function() end

  if self.ResetButton and self.ResetButton.SetClickCallback then
    self.ResetButton:SetClickCallback(function()
      self:Reset()
    end)
  end

  -- 3.3.5a cannot reproduce the modern cascading menu reliably. Represent the
  -- same hierarchy as up to three compact dropdowns. The legacy auction API is
  -- itself only three levels deep: class -> subclass -> inventory slot/type.
  --
  -- Keep them inset from the dialog edge and noticeably narrower than the
  -- previous 274px control; the old full-width button looked glued to the left
  -- border and dominated the whole dialog.
  self.ClassDropDown = CreateFrame("Button", nil, self, "WowStyle1DropdownTemplate")
  self.ClassDropDown:SetPoint("TOPLEFT", self, "TOPLEFT", 18, -2)
  self.ClassDropDown:SetWidth(220)
  self.ClassDropDown:SetHeight(22)

  self.SubClassDropDown = CreateFrame("Button", nil, self, "WowStyle1DropdownTemplate")
  self.SubClassDropDown:SetPoint("TOPLEFT", self.ClassDropDown, "BOTTOMLEFT", 0, -4)
  self.SubClassDropDown:SetWidth(220)
  self.SubClassDropDown:SetHeight(22)

  self.DetailDropDown = CreateFrame("Button", nil, self, "WowStyle1DropdownTemplate")
  self.DetailDropDown:SetPoint("LEFT", self.SubClassDropDown, "RIGHT", 6, 0)
  self.DetailDropDown:SetWidth(107)
  self.DetailDropDown:SetHeight(22)

  if self.ResetButton then
    self.ResetButton:ClearAllPoints()
    self.ResetButton:SetPoint("LEFT", self.ClassDropDown, "RIGHT", 6, 0)
  end

  self:RefreshAllDropDowns()
end

function AuctionatorFilterKeySelectorMixin:RefreshClassDropDown()
  local labels = { GetAnyLabel() }
  local values = { ANY_VALUE }

  for _, category in ipairs(AuctionCategories or {}) do
    if not category:HasFlag("WOW_TOKEN_FLAG") and not category.implicitFilter then
      table.insert(labels, category.name)
      table.insert(values, category.name)
    end
  end

  SetupRadioMenu(self.ClassDropDown, labels, values, function()
    return self.selectedRoot
  end, function(value)
    self.selectedRoot = value or ""
    self.selectedSubClass = ""
    self.selectedDetail = ""
    self:RefreshSubClassDropDown()
    self:RefreshDetailDropDown()
    self:NotifySelectionChanged()
  end)
end

function AuctionatorFilterKeySelectorMixin:RefreshSubClassDropDown()
  local labels = { GetAnyLabel() }
  local values = { ANY_VALUE }
  local root = FindRootCategory(self.selectedRoot)
  local hasSubClasses = self.selectedRoot ~= "" and HasChildren(root)

  if hasSubClasses then
    for _, child in ipairs(root.subCategories) do
      table.insert(labels, child.name)
      table.insert(values, child.name)
    end
  end

  SetupRadioMenu(self.SubClassDropDown, labels, values, function()
    return self.selectedSubClass
  end, function(value)
    self.selectedSubClass = value or ""
    self.selectedDetail = ""
    self:RefreshDetailDropDown()
    self:NotifySelectionChanged()
  end)

  EnableDropDown(self.SubClassDropDown, hasSubClasses)
  SetVisible(self.SubClassDropDown, hasSubClasses)
end

function AuctionatorFilterKeySelectorMixin:RefreshDetailDropDown()
  local labels = { GetAnyLabel() }
  local values = { ANY_VALUE }
  local root = FindRootCategory(self.selectedRoot)
  local subCategory = FindChildCategory(root, self.selectedSubClass)
  local hasDetails = self.selectedSubClass ~= "" and HasChildren(subCategory)

  if hasDetails then
    for _, child in ipairs(subCategory.subCategories) do
      table.insert(labels, child.name)
      table.insert(values, child.name)
    end
  end

  SetupRadioMenu(self.DetailDropDown, labels, values, function()
    return self.selectedDetail
  end, function(value)
    self.selectedDetail = value or ""
    self:NotifySelectionChanged()
  end)

  EnableDropDown(self.DetailDropDown, hasDetails)
  SetVisible(self.DetailDropDown, hasDetails)

  -- When a genuine third level exists split the second row into two balanced
  -- selectors. Otherwise the subclass selector gets the same compact width as
  -- the class selector instead of stretching across the dialog.
  if hasDetails then
    self.SubClassDropDown:SetWidth(107)
    self.DetailDropDown:ClearAllPoints()
    self.DetailDropDown:SetPoint("LEFT", self.SubClassDropDown, "RIGHT", 6, 0)
  else
    self.SubClassDropDown:SetWidth(220)
  end
end

function AuctionatorFilterKeySelectorMixin:RefreshAllDropDowns()
  self:RefreshClassDropDown()
  self:RefreshSubClassDropDown()
  self:RefreshDetailDropDown()
end

function AuctionatorFilterKeySelectorMixin:GetValue()
  if self.selectedRoot == "" then
    return ""
  end

  local value = self.selectedRoot
  if self.selectedSubClass ~= "" then
    value = value .. "/" .. self.selectedSubClass
  end
  if self.selectedDetail ~= "" then
    value = value .. "/" .. self.selectedDetail
  end
  return value
end

function AuctionatorFilterKeySelectorMixin:NotifySelectionChanged()
  self.displayText = self:GetValue()
  self.onEntrySelected(self.displayText)
end

function AuctionatorFilterKeySelectorMixin:SetValue(value)
  value = value or ""

  self.selectedRoot = ""
  self.selectedSubClass = ""
  self.selectedDetail = ""

  if value ~= "" then
    local terms = { strsplit("/", value) }
    self.selectedRoot = terms[1] or ""
    self.selectedSubClass = terms[2] or ""
    self.selectedDetail = terms[3] or ""
  end

  self.displayText = value
  self:RefreshAllDropDowns()
  self.onEntrySelected(value)
end

function AuctionatorFilterKeySelectorMixin:Reset()
  self.selectedRoot = ""
  self.selectedSubClass = ""
  self.selectedDetail = ""
  self.displayText = ""
  self:RefreshAllDropDowns()
  self.onEntrySelected("")
end

function AuctionatorFilterKeySelectorMixin:SetOnEntrySelected(callback)
  self.onEntrySelected = callback or function() end
end

function AuctionatorFilterKeySelectorMixin:EntrySelected(displayText)
  self:SetValue(displayText)
end

function AuctionatorFilterKeySelectorMixin:InitializeLevels()
  -- Hierarchy is represented by the three legacy dropdowns above.
end
