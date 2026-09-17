local CategoryLookup = {}

-- 3.3.5a exposes the auction filter hierarchy through the old Auction UI APIs:
--   GetAuctionItemClasses()                  -> localized class names
--   GetAuctionItemSubClasses(classIndex)     -> localized subclass names
--   GetAuctionInvTypes(classIndex, subIndex) -> INVTYPE_* global names
--
-- IMPORTANT: these APIs use 1-based AUCTION FILTER INDICES, not modern item
-- class/subclass IDs. Keep those indices on the filter records so the legacy
-- QueryAuctionItems() call can use them directly. We also attach modern-ish
-- classID/subClassID values when they can be resolved, because other Auctionator
-- code occasionally inspects them.
local function MakeCompatCategory(name, filters)
  local category = {
    name = name,
    filters = filters or {},
    implicitFilter = false,
  }

  function category:HasFlag()
    return false
  end

  return category
end

local function ResolveItemClassID(className)
  local valid = Auctionator.Groups and Auctionator.Groups.Constants and Auctionator.Groups.Constants.ValidItemClassIDs or {}
  for _, classID in ipairs(valid) do
    local candidate = C_Item and C_Item.GetItemClassInfo and C_Item.GetItemClassInfo(classID)
    if candidate == className then
      return classID
    end
  end
  return nil
end

local function ResolveItemSubClassID(classID, subClassName)
  if classID == nil or not (C_Item and C_Item.GetItemSubClassInfo) then
    return nil
  end

  -- WotLK class subclass IDs are small. Scanning a bounded range is safer than
  -- assuming GetAuctionItemSubClasses() returns IDs on this old client (it
  -- returns DISPLAY NAMES here).
  for subClassID = 0, 40 do
    local candidate = C_Item.GetItemSubClassInfo(classID, subClassID)
    if candidate == subClassName then
      return subClassID
    end
  end
  return nil
end

local INVENTORY_ENUM_BY_TOKEN = {
  INVTYPE_HEAD = Enum and Enum.InventoryType and Enum.InventoryType.IndexHeadType,
  INVTYPE_NECK = Enum and Enum.InventoryType and Enum.InventoryType.IndexNeckType,
  INVTYPE_SHOULDER = Enum and Enum.InventoryType and Enum.InventoryType.IndexShoulderType,
  INVTYPE_BODY = Enum and Enum.InventoryType and Enum.InventoryType.IndexBodyType,
  INVTYPE_CHEST = Enum and Enum.InventoryType and Enum.InventoryType.IndexChestType,
  INVTYPE_WAIST = Enum and Enum.InventoryType and Enum.InventoryType.IndexWaistType,
  INVTYPE_LEGS = Enum and Enum.InventoryType and Enum.InventoryType.IndexLegsType,
  INVTYPE_FEET = Enum and Enum.InventoryType and Enum.InventoryType.IndexFeetType,
  INVTYPE_WRIST = Enum and Enum.InventoryType and Enum.InventoryType.IndexWristType,
  INVTYPE_HAND = Enum and Enum.InventoryType and Enum.InventoryType.IndexHandType,
  INVTYPE_FINGER = Enum and Enum.InventoryType and Enum.InventoryType.IndexFingerType,
  INVTYPE_TRINKET = Enum and Enum.InventoryType and Enum.InventoryType.IndexTrinketType,
  INVTYPE_CLOAK = Enum and Enum.InventoryType and Enum.InventoryType.IndexCloakType,
  INVTYPE_WEAPON = Enum and Enum.InventoryType and Enum.InventoryType.IndexWeaponType,
  INVTYPE_SHIELD = Enum and Enum.InventoryType and Enum.InventoryType.IndexShieldType,
  INVTYPE_2HWEAPON = Enum and Enum.InventoryType and Enum.InventoryType.Index2HweaponType,
  INVTYPE_WEAPONMAINHAND = Enum and Enum.InventoryType and Enum.InventoryType.IndexWeaponmainhandType,
  INVTYPE_WEAPONOFFHAND = Enum and Enum.InventoryType and Enum.InventoryType.IndexWeaponoffhandType,
  INVTYPE_HOLDABLE = Enum and Enum.InventoryType and Enum.InventoryType.IndexHoldableType,
  INVTYPE_RANGED = Enum and Enum.InventoryType and Enum.InventoryType.IndexRangedType,
  INVTYPE_THROWN = Enum and Enum.InventoryType and Enum.InventoryType.IndexThrownType,
  INVTYPE_RANGEDRIGHT = Enum and Enum.InventoryType and Enum.InventoryType.IndexRangedrightType,
  INVTYPE_RELIC = Enum and Enum.InventoryType and Enum.InventoryType.IndexRelicType,
}

local function LocalizeInvType(token)
  if type(token) ~= "string" then
    return tostring(token or "")
  end
  return _G[token] or token
end

local function BuildCompatAuctionCategories()
  local result = {}
  local classNames = {}
  if type(GetAuctionItemClasses) == "function" then
    classNames = { GetAuctionItemClasses() }
  end

  for classIndex, className in ipairs(classNames) do
    if className and className ~= "" then
      local classID = ResolveItemClassID(className)
      local category = MakeCompatCategory(className, {{
        classIndex = classIndex,
        classID = classID,
      }})
      category.subCategories = {}

      local subClassNames = {}
      if type(GetAuctionItemSubClasses) == "function" then
        subClassNames = { GetAuctionItemSubClasses(classIndex) }
      end

      for subClassIndex, subClassName in ipairs(subClassNames) do
        if subClassName and subClassName ~= "" then
          local subClassID = ResolveItemSubClassID(classID, subClassName)
          local subCategory = MakeCompatCategory(subClassName, {{
            classIndex = classIndex,
            subClassIndex = subClassIndex,
            classID = classID,
            subClassID = subClassID,
          }})
          subCategory.subCategories = {}

          -- The stock 3.3.5 auction UI exposes at most one more level here:
          -- inventory type / slot. This is exactly the third menu column seen in
          -- Blizzard's own auction filter and in Auctionator on Classic.
          if type(GetAuctionInvTypes) == "function" then
            -- IMPORTANT: on the 3.3.5 client this API does NOT return a flat
            -- list of slot tokens. It returns alternating pairs:
            --   token1, canDisplay1, token2, canDisplay2, ...
            --
            -- Capturing the results in a table and iterating with ipairs() is
            -- wrong for two reasons:
            --   1) the display flags get treated as inventory types (the stray
            --      "1" that appeared in the dropdown), and
            --   2) a nil display flag punches a hole in the table, so ipairs()
            --      stops early (why Armor -> Cloth only showed Head/Neck).
            --
            -- Blizzard's legacy auction UI counts inventoryTypeIndex by PAIR
            -- ordinal, including hidden pairs. Preserve that exact index for
            -- QueryAuctionItems().
            local numReturns = select("#", GetAuctionInvTypes(classIndex, subClassIndex))
            for returnIndex = 1, numReturns, 2 do
              local invTypeToken, canDisplay = select(returnIndex, GetAuctionInvTypes(classIndex, subClassIndex))
              if invTypeToken and canDisplay then
                local label = LocalizeInvType(invTypeToken)
                if label and label ~= "" then
                  local invTypeIndex = math.ceil(returnIndex / 2)
                  table.insert(subCategory.subCategories, MakeCompatCategory(label, {{
                    classIndex = classIndex,
                    subClassIndex = subClassIndex,
                    inventoryTypeIndex = invTypeIndex,
                    classID = classID,
                    subClassID = subClassID,
                    inventoryType = INVENTORY_ENUM_BY_TOKEN[invTypeToken],
                  }}))
                end
              end
            end
          end

          if #subCategory.subCategories == 0 then
            subCategory.subCategories = nil
          end
          table.insert(category.subCategories, subCategory)
        end
      end

      if #category.subCategories == 0 then
        category.subCategories = nil
      end
      table.insert(result, category)
    end
  end

  return result
end

local function SaveCategory(categories, prefix)
  prefix = prefix or ""

  for _, c in ipairs(categories or {}) do
    local currentName = prefix .. c.name
    CategoryLookup[currentName] = c.filters

    if c.subCategories ~= nil then
      SaveCategory(c.subCategories, currentName .. "/")
    end
  end
end

function Auctionator.Search.InitializeCategories()
  Auctionator.Search.InitializeOldCategories()

  -- Always rebuild this tree on 3.3.5a from the native legacy auction filter
  -- APIs. A partially defined AuctionCategories table from another shim/addon
  -- is not useful here and was the reason selecting Armor did not expose any
  -- lower-level choices.
  AuctionCategories = BuildCompatAuctionCategories()
  SaveCategory(AuctionCategories)
end

function Auctionator.Search.GetItemClassCategories(categoryKey)
  local lookup = CategoryLookup[categoryKey]
  if lookup ~= nil then
    return lookup
  elseif categoryKey ~= "" then
    -- Compatibility with shopping-list strings created by older Auctionator
    -- versions. The old lookup is kept as a fallback only.
    return Auctionator.Search.GetItemClassOldCategories(categoryKey)
  end
end
