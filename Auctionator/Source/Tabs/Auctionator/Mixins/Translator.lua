AuctionatorTranslatorMixin = {}

function AuctionatorTranslatorMixin:Refresh()
  if self.FlagTexture and self.textureLocation then
    self.FlagTexture:SetTexture(self.textureLocation)
  end
  if self.TranslatorsText then
    self.TranslatorsText:SetText(self.translators or "")
  end
end

function AuctionatorTranslatorMixin:OnLoad()
  self:Refresh()
end

function AuctionatorTranslatorMixin:OnShow()
  self:Refresh()
end
