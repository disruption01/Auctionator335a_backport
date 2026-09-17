AuctionatorShoppingTabContainerTabsMixin = {}

function AuctionatorShoppingTabContainerTabsMixin:OnLoad()
  self.Tabs = {self.ListsTab, self.RecentsTab}
  self.numTabs = #self.Tabs
  -- 3.3.5a PanelTemplates_SetTab looks up <frameName>Tab1/Tab2 globals.
  -- Our XML uses descriptive names, so provide the aliases it expects.
  local name = self.GetName and self:GetName()
  if name then
    _G[name .. "Tab1"] = self.ListsTab
    _G[name .. "Tab2"] = self.RecentsTab
  end
end

function AuctionatorShoppingTabContainerTabsMixin:SetView(viewIndex)
  self.Tabs = {self.ListsTab, self.RecentsTab}
  self.numTabs = 2
  local name = self.GetName and self:GetName()
  if name then
    _G[name .. "Tab1"] = self.ListsTab
    _G[name .. "Tab2"] = self.RecentsTab
  end
  viewIndex = tonumber(viewIndex) or 1
  if viewIndex < 1 or viewIndex > self.numTabs then viewIndex = 1 end
  if PanelTemplates_SetTab and self.ListsTab and self.RecentsTab then
    PanelTemplates_SetTab(self, viewIndex)
  else
    self.selectedTab = viewIndex
  end
  Auctionator.Config.Set(Auctionator.Config.Options.SHOPPING_LAST_CONTAINER_VIEW, viewIndex)

  self:GetParent().NewListButton:Hide()
  self:GetParent().ImportButton:Hide()
  self:GetParent().ExportButton:Hide()

  if viewIndex == Auctionator.Constants.ShoppingListViews.Recents then
    self:GetParent().ListsContainer:Hide()
    self:GetParent().RecentsContainer:Show()

  elseif viewIndex == Auctionator.Constants.ShoppingListViews.Lists then
    self:GetParent().RecentsContainer:Hide()
    self:GetParent().ListsContainer:Show()
    self:GetParent().NewListButton:Show()
    self:GetParent().ImportButton:Show()
    self:GetParent().ExportButton:Show()
  end
end
