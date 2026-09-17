function Auctionator.Selling.ShowCannotSellReason(location)
  local currentDurability, maxDurability
  local bagID, slotID = Auctionator_GetBagAndSlotFromLocation(location)
  if bagID ~= nil and slotID ~= nil then
    if C_Container then
      currentDurability, maxDurability = C_Container.GetContainerItemDurability(bagID, slotID)
    else
      currentDurability, maxDurability = GetContainerItemDurability(bagID, slotID)
    end
  else
    local equipmentSlot = Auctionator_GetEquipmentSlotFromLocation(location)
    if equipmentSlot ~= nil then
      currentDurability, maxDurability = GetInventoryItemDurability(equipmentSlot)
    end
  end

  if currentDurability ~= maxDurability then
    UIErrorsFrame:AddMessage(ERR_AUCTION_REPAIR_ITEM, 1.0, 0.1, 0.1, 1.0)
  elseif not Auctionator.Utilities.IsAtMaxCharges(location) then
    UIErrorsFrame:AddMessage(ERR_AUCTION_USED_CHARGES, 1.0, 0.1, 0.1, 1.0)
  elseif C_Item.IsBound(location) then
    UIErrorsFrame:AddMessage(ERR_AUCTION_BOUND_ITEM, 1.0, 0.1, 0.1, 1.0)
  end
end
