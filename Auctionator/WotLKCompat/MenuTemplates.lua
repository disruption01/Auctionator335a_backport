-- Menus and lightweight layout helpers for 3.3.5a.

local menuCounter=0
local function newDropdown(owner)
  menuCounter=menuCounter+1
  local f=CreateFrame('Frame','AuctionatorCompatDropDown'..menuCounter,UIParent,'UIDropDownMenuTemplate')
  f.owner=owner
  return f
end

MenuUtil=MenuUtil or {}
function MenuUtil.CreateRadioMenu(button,isSelected,setSelected,...)
  local entries={...}
  button.__auctionatorEntries=entries
  button.__auctionatorIsSelected=isSelected
  button.__auctionatorSetSelected=setSelected
  button.GenerateMenu=function(self)
    for _,entry in ipairs(self.__auctionatorEntries or {}) do
      if self.__auctionatorIsSelected and self.__auctionatorIsSelected(entry[2]) then
        if self.SetText then self:SetText(entry[1]) elseif self.Text then self.Text:SetText(entry[1]) end
        return
      end
    end
  end
  button:SetScript('OnClick',function(self)
    local dd=self.__auctionatorDD or newDropdown(self); self.__auctionatorDD=dd
    UIDropDownMenu_Initialize(dd,function()
      for _,entry in ipairs(self.__auctionatorEntries or {}) do
        local info=UIDropDownMenu_CreateInfo(); info.text=entry[1]; info.checked=self.__auctionatorIsSelected and self.__auctionatorIsSelected(entry[2]);
        info.func=function() if self.__auctionatorSetSelected then self.__auctionatorSetSelected(entry[2]) end self:GenerateMenu() end
        UIDropDownMenu_AddButton(info)
      end
    end,'MENU')
    ToggleDropDownMenu(1,nil,dd,self,0,0)
  end)
  button:GenerateMenu()
end

local function showContext(owner,build)
  local dd=newDropdown(owner)
  local desc={entries={}}
  function desc:CreateButton(text,fn) self.entries[#self.entries+1]={text=text,fn=fn} end
  function desc:CreateTitle(text) self.entries[#self.entries+1]={text=text,title=true} end
  build(owner,desc)
  UIDropDownMenu_Initialize(dd,function()
    for _,e in ipairs(desc.entries) do
      local info=UIDropDownMenu_CreateInfo(); info.text=e.text; info.isTitle=e.title; info.notCheckable=true; info.disabled=e.title
      if e.fn then info.func=e.fn end
      UIDropDownMenu_AddButton(info)
    end
  end,'MENU')
  ToggleDropDownMenu(1,nil,dd,'cursor',0,0)
  return {Close=function() CloseDropDownMenus() end}
end
function MenuUtil.CreateContextMenu(owner,build) return showContext(owner,build) end
function MenuUtil.CreateCheckboxContextMenu(owner,isChecked,setChecked,...)
  local entries={...}; local menuObj
  local dd=newDropdown(owner)
  UIDropDownMenu_Initialize(dd,function()
    for _,e in ipairs(entries) do
      local info=UIDropDownMenu_CreateInfo(); info.text=e[1]; info.checked=isChecked(e[2]); info.keepShownOnClick=true
      info.func=function() setChecked(e[2]) end
      UIDropDownMenu_AddButton(info)
    end
  end,'MENU')
  ToggleDropDownMenu(1,nil,dd,'cursor',0,0)
  menuObj={Close=function() CloseDropDownMenus() end}
  return dd,menuObj
end

-- Generic dynamic resize button mixin. -------------------------------------
AuctionatorCompatDynamicButtonMixin=AuctionatorCompatDynamicButtonMixin or {}
function AuctionatorCompatDynamicButtonMixin:OnLoad()
  local text=self:GetText() or ''
  local fs=self:GetFontString()
  if fs then self:SetWidth(math.max(70,fs:GetStringWidth()+26)) end
end

-- Resize-layout frames in Auctionator mostly use explicit anchors on 3.3.5a.
ResizeLayoutFrameMixin=ResizeLayoutFrameMixin or {}
function ResizeLayoutFrameMixin:MarkDirty() end
function ResizeLayoutFrameMixin:Layout() end

-- Button frame helpers expected by configuration dialogs.
ButtonFrameMixin=ButtonFrameMixin or {}
function ButtonFrameMixin:SetTitle(text) if self.TitleText then self.TitleText:SetText(text) end end

-- PanelTemplates does not like anonymous buttons in old FrameXML; guard calls.
local oldSetTab=PanelTemplates_SetTab
if oldSetTab then
  function PanelTemplates_SetTab(frame,id)
    if frame and frame.GetName and frame:GetName() then return oldSetTab(frame,id) end
    frame.selectedTab=id
  end
end

-- ScrollingEditBox helpers --------------------------------------------------
ScrollingEditBoxMixin=ScrollingEditBoxMixin or {}
function ScrollingEditBoxMixin:OnTextChanged() if self:GetParent() and self:GetParent().UpdateScrollChildRect then self:GetParent():UpdateScrollChildRect() end end


-- DropdownButton/SetupMenu compatibility ------------------------------------
-- Modern Auctionator builds hierarchical menus using DropdownButton:SetupMenu.
-- 3.3.5a only has UIDropDownMenu, so expose the small API surface Auctionator
-- needs on ordinary Buttons.
local function compatMenuDescription(entries, parentEntry)
  local desc = {entries = entries, parentEntry = parentEntry}
  function desc:CreateRadio(text, isSelected, onSelect)
    local e = {text=text, isSelected=isSelected, onSelect=onSelect, children={}}
    table.insert(self.entries, e)
    return compatMenuDescription(e.children, e)
  end
  function desc:CreateButton(text, onSelect)
    local e = {text=text, onSelect=onSelect, children={}}
    table.insert(self.entries, e)
    return compatMenuDescription(e.children, e)
  end
  return desc
end

local function addCompatMenuEntries(owner, entries, level)
  for _,e in ipairs(entries or {}) do
    local info = UIDropDownMenu_CreateInfo()
    info.text = e.text or ''
    info.checked = e.isSelected and e.isSelected() or false
    info.hasArrow = e.children and #e.children > 0
    info.notCheckable = false
    if info.hasArrow then
      info.value = e
      info.menuList = e
    else
      info.func = function()
        if e.onSelect then e.onSelect() end
        CloseDropDownMenus()
        if owner.GenerateMenu then owner:GenerateMenu() end
      end
    end
    UIDropDownMenu_AddButton(info, level)
  end
end

function Auctionator335_SetupMenuButton(button, generator)
  button.__auctionatorMenuGenerator = generator
  button.__auctionatorMenuEntries = {}
  function button:GenerateMenu()
    self.__auctionatorMenuEntries = {}
    local root = compatMenuDescription(self.__auctionatorMenuEntries)
    if self.__auctionatorMenuGenerator then self.__auctionatorMenuGenerator(self, root) end
  end
  function button:SetupMenu(fn)
    self.__auctionatorMenuGenerator = fn
    self:GenerateMenu()
    self:SetScript('OnClick', function(owner)
      owner:GenerateMenu()
      owner.__auctionatorDD = owner.__auctionatorDD or newDropdown(owner)
      local dd = owner.__auctionatorDD
      UIDropDownMenu_Initialize(dd, function(_, level, menuList)
        if level == 1 then
          addCompatMenuEntries(owner, owner.__auctionatorMenuEntries, level)
        elseif menuList and menuList.children then
          addCompatMenuEntries(owner, menuList.children, level)
        end
      end, 'MENU')
      ToggleDropDownMenu(1, nil, dd, owner, 0, 0)
    end)
  end
  function button:CloseMenu() CloseDropDownMenus() end
end
