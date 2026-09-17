AuctionatorConfigRadioButtonMixin = {}

function AuctionatorConfigRadioButtonMixin:OnLoad()
  -- This field is used by the RadioButtonGroup to ensure that the UI child it is positioning
  -- is an auctionator radio button
  self.isAuctionatorRadio = true

  -- 3.3.5a XML inheritance may assign value/labelText in the child OnLoad
  -- after the template OnLoad runs. Do not abort startup if they are not set yet.
  if self.labelText ~= nil and self.RadioButton and self.RadioButton.Label then
    self.RadioButton.Label:SetText(self.labelText)
  end
end

function AuctionatorConfigRadioButtonMixin:OnMouseUp()
  self.RadioButton:Click()
end

function AuctionatorConfigRadioButtonMixin:OnEnter()
  self.RadioButton:LockHighlight()
end

function AuctionatorConfigRadioButtonMixin:OnLeave()
  self.RadioButton:UnlockHighlight()
end

function AuctionatorConfigRadioButtonMixin:SetChecked(value)
  self.RadioButton:SetChecked(value)
end

function AuctionatorConfigRadioButtonMixin:GetChecked()
  return self.RadioButton:GetChecked()
end

function AuctionatorConfigRadioButtonMixin:GetValue()
  return self.value
end

function AuctionatorConfigRadioButtonMixin:OnClick()
  if self.onSelectedCallback ~= nil then
    self.onSelectedCallback()
  end
end
