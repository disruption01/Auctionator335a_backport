Auctionator.Groups.Constants = {
  -- Explicit client identity for the private 3.3.5a backport. Keep this local
  -- to Auctionator instead of fabricating Blizzard WOW_PROJECT_* globals.
  IsWrath = true,
  IsMists = false,
  IsCata = false,
  IsBC = false,
  IsVanilla = false,
  IsRetail = false,
}

Auctionator.Groups.Constants.Events = {
  "BagCacheUpdated",
  "ViewGroupToggled",
  "ViewComplete",

  "BagCacheOff",
  "BagCacheOn",

  "BagUse.BagItemClicked",
  "BagUse.AddToDefaultGroup",

  "Customise.EditMade",
}

if Auctionator.Groups.Constants.IsVanilla or Auctionator.Groups.Constants.IsBC then
  -- Note that -2 is the keyring bag, which only exists in classic era
  Auctionator.Groups.Constants.BagIDs = {-2, 0, 1, 2, 3, 4}
elseif not Auctionator.Groups.Constants.IsRetail then
  Auctionator.Groups.Constants.BagIDs = {0, 1, 2, 3, 4}
elseif Auctionator.Groups.Constants.IsRetail then
  Auctionator.Groups.Constants.BagIDs = {0, 1, 2, 3, 4, 5}
end

if Auctionator.Groups.Constants.IsRetail then
  Auctionator.Groups.Constants.ValidItemClassIDs = {
    Enum.ItemClass.Weapon,
    Enum.ItemClass.Armor,
    Enum.ItemClass.Container,
    Enum.ItemClass.Gem,
    Enum.ItemClass.ItemEnhancement,
    Enum.ItemClass.Consumable,
    Enum.ItemClass.Glyph,
    Enum.ItemClass.Tradegoods,
    Enum.ItemClass.Recipe,
    Enum.ItemClass.Profession,
    Enum.ItemClass.Battlepet,
    Enum.ItemClass.Questitem,
    Enum.ItemClass.Housing,
    Enum.ItemClass.Miscellaneous,
    Enum.ItemClass.Key,
  }
elseif Auctionator.Groups.Constants.IsMists then
  Auctionator.Groups.Constants.ValidItemClassIDs = {
    Enum.ItemClass.Weapon,
    Enum.ItemClass.Armor,
    Enum.ItemClass.Container,
    Enum.ItemClass.ItemEnhancement,
    Enum.ItemClass.Consumable,
    Enum.ItemClass.Glyph,
    Enum.ItemClass.Tradegoods,
    Enum.ItemClass.Projectile,
    Enum.ItemClass.Reagent,
    Enum.ItemClass.Quiver,
    Enum.ItemClass.Recipe,
    Enum.ItemClass.Gem,
    Enum.ItemClass.Miscellaneous,
    Enum.ItemClass.Battlepet,
    Enum.ItemClass.Questitem,
    Enum.ItemClass.Key,
  }
elseif Auctionator.Groups.Constants.IsCata then
  Auctionator.Groups.Constants.ValidItemClassIDs = {
    Enum.ItemClass.Weapon,
    Enum.ItemClass.Armor,
    Enum.ItemClass.Container,
    Enum.ItemClass.ItemEnhancement,
    Enum.ItemClass.Consumable,
    Enum.ItemClass.Glyph,
    Enum.ItemClass.Tradegoods,
    Enum.ItemClass.Projectile,
    Enum.ItemClass.Reagent,
    Enum.ItemClass.Quiver,
    Enum.ItemClass.Recipe,
    Enum.ItemClass.Gem,
    Enum.ItemClass.Miscellaneous,
    Enum.ItemClass.Questitem,
    Enum.ItemClass.Key,
  }
elseif Auctionator.Groups.Constants.IsWrath then
  Auctionator.Groups.Constants.ValidItemClassIDs = {
    Enum.ItemClass.Weapon,
    Enum.ItemClass.Armor,
    Enum.ItemClass.Container,
    Enum.ItemClass.Consumable,
    Enum.ItemClass.Glyph,
    Enum.ItemClass.Tradegoods,
    Enum.ItemClass.Projectile,
    Enum.ItemClass.Quiver,
    Enum.ItemClass.Recipe,
    Enum.ItemClass.Gem,
    Enum.ItemClass.Miscellaneous,
    Enum.ItemClass.Questitem,
    Enum.ItemClass.Key,
  }
elseif Auctionator.Groups.Constants.IsBC then
  Auctionator.Groups.Constants.ValidItemClassIDs = {
    Enum.ItemClass.Weapon,
    Enum.ItemClass.Armor,
    Enum.ItemClass.Container,
    Enum.ItemClass.Consumable,
    Enum.ItemClass.Tradegoods,
    Enum.ItemClass.Projectile,
    Enum.ItemClass.Quiver,
    Enum.ItemClass.Recipe,
    Enum.ItemClass.Gem,
    Enum.ItemClass.Miscellaneous,
    Enum.ItemClass.Questitem,
    Enum.ItemClass.Key,
  }
elseif Auctionator.Groups.Constants.IsVanilla then
  Auctionator.Groups.Constants.ValidItemClassIDs = {
    Enum.ItemClass.Weapon,
    Enum.ItemClass.Armor,
    Enum.ItemClass.Container,
    Enum.ItemClass.Consumable,
    Enum.ItemClass.Tradegoods,
    Enum.ItemClass.Projectile,
    Enum.ItemClass.Quiver,
    Enum.ItemClass.Recipe,
    Enum.ItemClass.Reagent,
    Enum.ItemClass.Miscellaneous,
    Enum.ItemClass.Questitem,
    Enum.ItemClass.Key,
  }
end

Auctionator.Groups.Constants.GroupType = {
  List = 1,
  ClassID = 2,
}

Auctionator.Groups.Constants.DefaultGroups = {
}

local seenNames = {}
for _, classID in ipairs(Auctionator.Groups.Constants.ValidItemClassIDs) do
  local name = C_Item.GetItemClassInfo(classID)
  if seenNames[name] then
    seenNames[name] = seenNames[name] + 1
    name = name .. (seenNames[name] + 1)
  else
    seenNames[name] = 1
  end
  table.insert(Auctionator.Groups.Constants.DefaultGroups, {
    name = name,
    type = Auctionator.Groups.Constants.GroupType.ClassID,
    classID = classID,
  })
end
