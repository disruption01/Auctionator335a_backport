local function Auctionator335Layout_AuctionatorConfigBasicOptionsFrameMixin(self)
  if self.__legacyLayoutDone then return end
  if not self.TitleArea then return end
  self.__legacyLayoutDone = true
  if self.TitleArea then self.TitleArea:ClearAllPoints(); self.TitleArea:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0); self.TitleArea:SetWidth(460); self.TitleArea:SetHeight(60) end
  if self.DefaultTabHeading then self.DefaultTabHeading:ClearAllPoints(); self.DefaultTabHeading:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -68); self.DefaultTabHeading:SetWidth(460); self.DefaultTabHeading:SetHeight(30) end
  if self.DefaultTab then self.DefaultTab:ClearAllPoints(); self.DefaultTab:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -100); self.DefaultTab:SetWidth(460); self.DefaultTab:SetHeight(40) end
  if self.CraftingInfoHeading then self.CraftingInfoHeading:ClearAllPoints(); self.CraftingInfoHeading:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -148); self.CraftingInfoHeading:SetWidth(460); self.CraftingInfoHeading:SetHeight(30) end
  -- Keep the Crafting Info labels inside the 3.3.5a Interface Options panel.
  -- The legacy UICheckButton template does not constrain the inherited FontString,
  -- so long labels can otherwise continue drawing past the right edge.
  local function FitCraftingCheckbox(frame, y, height)
    if not frame then return end
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, y)
    frame:SetWidth(440)
    frame:SetHeight(height or 34)

    if Auctionator335Config and Auctionator335Config.FitCheckbox then
      Auctionator335Config.FitCheckbox(frame, 440)
    elseif frame.CheckBox and frame.CheckBox.Label then
      frame.CheckBox.Label:SetWidth(365)
      frame.CheckBox.Label:SetJustifyH("LEFT")
      if frame.CheckBox.Label.SetJustifyV then frame.CheckBox.Label:SetJustifyV("TOP") end
      if frame.CheckBox.Label.SetWordWrap then frame.CheckBox.Label:SetWordWrap(true) end
    end
  end

  FitCraftingCheckbox(self.ShowCraftingInfo, -180, 34)
  FitCraftingCheckbox(self.ShowCraftingCost, -214, 34)
  -- This is the longest Basic Options label; give it two lines when required.
  FitCraftingCheckbox(self.ShowCraftingProfit, -248, 50)
end

AuctionatorConfigBasicOptionsFrameMixin = CreateFromMixins(AuctionatorPanelConfigMixin)

function AuctionatorConfigBasicOptionsFrameMixin:OnLoad()
  Auctionator335Layout_AuctionatorConfigBasicOptionsFrameMixin(self)
  Auctionator.Debug.Message("AuctionatorConfigBasicOptionsFrameMixin:OnLoad()")

  self.name = AUCTIONATOR_L_CONFIG_BASIC_OPTIONS_CATEGORY
  self.parent = "Auctionator"

  self:SetupPanel()
end

function AuctionatorConfigBasicOptionsFrameMixin:ShowSettings()
  Auctionator335Layout_AuctionatorConfigBasicOptionsFrameMixin(self)
  self.DefaultTab:SetValue(tostring(Auctionator.Config.Get(Auctionator.Config.Options.DEFAULT_TAB)))
  self.ShowCraftingInfo:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.CRAFTING_INFO_SHOW))
  self.ShowCraftingCost:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.CRAFTING_INFO_SHOW_COST))
  self.ShowCraftingProfit:SetChecked(Auctionator.Config.Get(Auctionator.Config.Options.CRAFTING_INFO_SHOW_PROFIT))
end

function AuctionatorConfigBasicOptionsFrameMixin:Save()
  Auctionator.Debug.Message("AuctionatorConfigBasicOptionsFrameMixin:Save()")

  Auctionator.Config.Set(Auctionator.Config.Options.DEFAULT_TAB, tonumber(self.DefaultTab:GetValue()))
  Auctionator.Config.Set(Auctionator.Config.Options.CRAFTING_INFO_SHOW, self.ShowCraftingInfo:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.CRAFTING_INFO_SHOW_COST, self.ShowCraftingCost:GetChecked())
  Auctionator.Config.Set(Auctionator.Config.Options.CRAFTING_INFO_SHOW_PROFIT, self.ShowCraftingProfit:GetChecked())
end

function AuctionatorConfigBasicOptionsFrameMixin:Cancel()
  Auctionator.Debug.Message("AuctionatorConfigBasicOptionsFrameMixin:Cancel()")
end
