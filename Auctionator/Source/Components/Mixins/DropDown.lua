AuctionatorDropDownMixin = {}

local function EnsureCompatDropDown(self)
  if self.DropDown then
    return self.DropDown
  end

  if self.GetName and self:GetName() then
    self.DropDown = _G[self:GetName() .. "DropDown"]
  end

  if not self.DropDown and self.GetChildren then
    local children = {self:GetChildren()}
    for _, child in ipairs(children) do
      if child and child.GetObjectType and child:GetObjectType() == "Button" then
        self.DropDown = child
        break
      end
    end
  end

  if not self.DropDown then
    self.DropDown = CreateFrame("Button", nil, self, "WowStyle1DropdownTemplate")
    self.DropDown:SetPoint("TOPLEFT", self, "TOPLEFT", 20, -3)
  end

  return self.DropDown
end

local ARRAY_DELIMITER = ";"
local function splitStrArray(arrayString)
  return {strsplit(ARRAY_DELIMITER, arrayString)}
end

local function localizeArray(array)
  for index, itm in ipairs(array) do
    array[index] = Auctionator.Locales.Apply(itm)
  end

  return array
end

local function EnsureCompatLabel(self)
  if self.Label then
    return self.Label
  end

  self.Label = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  self.Label:SetJustifyH("LEFT")
  local dropdown = EnsureCompatDropDown(self)
  if dropdown then
    self.Label:SetPoint("LEFT", dropdown, "RIGHT", 15, 0)
  else
    self.Label:SetPoint("LEFT", self, "LEFT", 215, -8)
  end
  return self.Label
end

function AuctionatorDropDownMixin:OnLoad()
  EnsureCompatDropDown(self)
  EnsureCompatLabel(self)
  if self.textString ~= nil and self.valuesString ~= nil then
    self:InitAgain(
      localizeArray(splitStrArray(self.textString)),
      splitStrArray(self.valuesString)
    )
  end
  EnsureCompatDropDown(self):SetWidth(180)
  if EnsureCompatDropDown(self).SetHeight then EnsureCompatDropDown(self):SetHeight(22) end

  if self.labelText ~= nil then
    EnsureCompatLabel(self):SetText(self.labelText)
  end
end

function AuctionatorDropDownMixin:InitAgain(labels, values)
  local entries = {}
  for index = 1, #labels do
    table.insert(entries, {labels[index], values[index]})
  end
  self.value = values[1]
  MenuUtil.CreateRadioMenu(EnsureCompatDropDown(self), function(value)
    return value == self.value
  end, function(value)
    self.value = value
  end, unpack(entries))
end

function AuctionatorDropDownMixin:SetValue(...)
  self.value = ...
  local dropdown = EnsureCompatDropDown(self)
  if dropdown.GenerateMenu then dropdown:GenerateMenu() end
end

function AuctionatorDropDownMixin:GetValue(...)
  return self.value
end
