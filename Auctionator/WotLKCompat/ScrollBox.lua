-- Minimal modern ScrollBox/DataProvider compatibility for 3.3.5a.
-- Auctionator's Classic UI only needs linear vertical lists.

DataProviderMixin = DataProviderMixin or {}
function DataProviderMixin:Init(collection) self.collection=collection or {} end
function DataProviderMixin:GetSize() return #self.collection end
function DataProviderMixin:IsEmpty() return #self.collection==0 end
function DataProviderMixin:GetCollection() return self.collection end
function DataProviderMixin:GetAtIndex(i) return self.collection[i] end
function DataProviderMixin:Enumerate(indexBegin,indexEnd)
  local i=(indexBegin or 1)-1; local last=indexEnd or #self.collection
  return function() i=i+1; if i<=last then return i,self.collection[i] end end
end
function DataProviderMixin:Insert(v,index) if index then table.insert(self.collection,index,v) else table.insert(self.collection,v) end self:TriggerEvent('OnSizeChanged') end
function DataProviderMixin:InsertTable(t) for _,v in ipairs(t or {}) do table.insert(self.collection,v) end self:TriggerEvent('OnSizeChanged') end
function DataProviderMixin:Remove(v)
  for i,x in ipairs(self.collection) do if x==v then table.remove(self.collection,i); self:TriggerEvent('OnSizeChanged'); return true end end
end
function DataProviderMixin:Flush() wipe(self.collection); self:TriggerEvent('OnSizeChanged') end
function DataProviderMixin:FindElementDataIndexByPredicate(pred)
  for i,v in ipairs(self.collection) do if pred(v) then return i end end
end
function DataProviderMixin:SetSortComparator(fn) self.comparator=fn end
function DataProviderMixin:Sort() if self.comparator then table.sort(self.collection,self.comparator); self:TriggerEvent('OnSort') end end
function DataProviderMixin:RegisterCallback(event,fn,owner)
  self.callbacks=self.callbacks or {}; self.callbacks[event]=self.callbacks[event] or {}; table.insert(self.callbacks[event],{fn=fn,owner=owner})
end
function DataProviderMixin:TriggerEvent(event,...)
  local t=self.callbacks and self.callbacks[event]; if not t then return end
  for _,e in ipairs(t) do if e.owner then e.fn(e.owner,self,...) else e.fn(self,...) end end
end
function CreateDataProvider(collection) local d=CreateFromMixins(DataProviderMixin); d:Init(collection); return d end
function CreateIndexRangeDataProvider(count)
  local t={}; for i=1,(count or 0) do t[i]=i end; return CreateDataProvider(t)
end

local __auctionatorScrollRowID=0

ScrollBoxListMixin = ScrollBoxListMixin or {Event={OnDataRangeChanged='OnDataRangeChanged',OnScroll='OnScroll'}}
ScrollBoxListMixin.Event = ScrollBoxListMixin.Event or {OnDataRangeChanged='OnDataRangeChanged',OnScroll='OnScroll'}

local ViewMixin={}
function ViewMixin:SetElementExtent(v) self.extent=v end
function ViewMixin:SetPanExtent(v) self.panExtent=v end
function ViewMixin:SetPadding(top,bottom,left,right,spacing)
  if type(top)=='table' then
    local t=top; self.padTop=t.top or 0; self.padBottom=t.bottom or 0; self.padLeft=t.left or 0; self.padRight=t.right or 0; self.spacing=t.spacing or t.elementSpacing or 0
  else
    self.padTop=top or 0; self.padBottom=bottom or 0; self.padLeft=left or 0; self.padRight=right or 0; self.spacing=spacing or 0
  end
end
function ViewMixin:SetElementInitializer(template, initializer) self.template=template; self.initializer=initializer end
function ViewMixin:SetElementFactory(factory) self.factory=factory end
function ViewMixin:SetElementResetter(resetter) self.resetter=resetter end
local function newView() local v=CreateFromMixins(ViewMixin); v.extent=20; v.padTop=0;v.padBottom=0;v.padLeft=0;v.padRight=0;v.spacing=0; return v end
function CreateScrollBoxListLinearView(...) local v=newView(); if select('#',...)>0 then v:SetPadding(...) end; return v end
function CreateScrollBoxLinearView(...) return CreateScrollBoxListLinearView(...) end

AuctionatorCompatScrollBoxMixin = AuctionatorCompatScrollBoxMixin or {}

-- 3.3.5a Frames don't clip children like the modern ScrollBox implementation.
-- Keep the compat scroll offset aligned to whole rows so partially visible rows
-- never paint over the table header/footer.
local function Auctionator335ScrollStep(box)
  local view = box and box.view or nil
  return math.max(1, ((view and view.extent) or 20) + ((view and view.spacing) or 0))
end

local function Auctionator335AlignOffset(box, offset)
  local step = Auctionator335ScrollStep(box)
  return math.floor(((offset or 0) / step) + 0.5) * step
end

function AuctionatorCompatScrollBoxMixin:OnLoad()
  if self.__auctionatorCompatScrollBoxLoaded then return end
  self.__auctionatorCompatScrollBoxLoaded = true
  self.frames=self.frames or {}; self.freeFrames=self.freeFrames or {}; self.callbacks=self.callbacks or {}; self.offset=self.offset or 0
  if not self.ScrollTarget then
    self.ScrollTarget=CreateFrame('Frame',nil,self)
    self.ScrollTarget:SetPoint('TOPLEFT',self,'TOPLEFT',0,0)
    self.ScrollTarget:SetWidth(math.max(1,self:GetWidth()))
    self.ScrollTarget:SetHeight(1)
  end
  self:EnableMouseWheel(true)
  self:SetScript('OnMouseWheel', function(frame,delta)
    local range=frame:GetDerivedScrollRange()
    if range<=0 then return end
    -- One wheel notch == one complete row. Using panExtent here produced
    -- half-rows (for example 50px on a 20px row), which then drew over the
    -- header because plain 3.3.5a Frames do not clip their children.
    local step=Auctionator335ScrollStep(frame)
    frame.offset=Clamp(Auctionator335AlignOffset(frame,(frame.offset or 0)-delta*step),0,range)
    frame:LayoutFrames()
    frame:TriggerCallback(ScrollBoxListMixin.Event.OnScroll)
  end)
end
function AuctionatorCompatScrollBoxMixin:RegisterCallback(event,fn,owner)
  self.callbacks[event]=self.callbacks[event] or {}; table.insert(self.callbacks[event],{fn=fn,owner=owner})
end
function AuctionatorCompatScrollBoxMixin:TriggerCallback(event,...)
  local t=self.callbacks and self.callbacks[event]; if not t then return end
  for _,e in ipairs(t) do if e.owner then e.fn(e.owner,self,...) else e.fn(self,...) end end
end
function AuctionatorCompatScrollBoxMixin:SetView(view) self.view=view end
function AuctionatorCompatScrollBoxMixin:GetView() return self.view end
function AuctionatorCompatScrollBoxMixin:GetDataProvider() return self.dataProvider end
function AuctionatorCompatScrollBoxMixin:SetDataProvider(provider,preserve)
  if not preserve then self.offset=0 end
  self.dataProvider=provider
  self:FullUpdate()
end
function AuctionatorCompatScrollBoxMixin:ReleaseFrames()
  if self.tableBuilder then
    for _,f in ipairs(self.frames) do pcall(self.tableBuilder.RemoveRow,self.tableBuilder,f) end
  end
  for _,f in ipairs(self.frames) do
    if self.view and self.view.resetter then pcall(self.view.resetter,f) end
    f:Hide(); f:ClearAllPoints()

    -- The first compat implementation discarded each row reference here.
    -- A provider that refreshes every frame then created Row1, Row2, Row3...
    -- forever. Recycle template-backed rows like the real ScrollBox pool does.
    local key=f.__auctionatorCompatPoolKey
    if key then
      self.freeFrames=self.freeFrames or {}
      self.freeFrames[key]=self.freeFrames[key] or {}
      table.insert(self.freeFrames[key],f)
    end
  end
  wipe(self.frames)
end
function AuctionatorCompatScrollBoxMixin:AcquireElement(index,data)
  local view=self.view or newView(); local frame
  if view.factory then
    frame=view.factory(self,index)
  else
    local objectType = 'Button'
    local inheritTemplate = view.template
    -- Modern ScrollBox accepts bare widget types such as "Button" here.
    -- 3.3.5a CreateFrame treats the 4th argument strictly as an XML template,
    -- so CreateFrame(..., "Button") tries to inherit a non-existent node.
    if view.template == 'Button' or view.template == 'Frame' or view.template == 'CheckButton' or
       view.template == 'EditBox' or view.template == 'Slider' or view.template == 'ScrollFrame' then
      objectType = view.template
      inheritTemplate = nil
    end

    local poolKey=objectType .. "\031" .. tostring(inheritTemplate or "")
    self.freeFrames=self.freeFrames or {}
    local pool=self.freeFrames[poolKey]
    if pool and #pool>0 then
      frame=table.remove(pool)
    else
      __auctionatorScrollRowID=__auctionatorScrollRowID+1
      frame=CreateFrame(objectType,'AuctionatorCompatScrollRow'..__auctionatorScrollRowID,self.ScrollTarget,inheritTemplate)
      frame.__auctionatorCompatPoolKey=poolKey
    end
  end
  frame:SetParent(self.ScrollTarget)
  frame:SetHeight(view.extent or 20)
  frame:SetWidth(math.max(1,self:GetWidth()-(view.padLeft or 0)-(view.padRight or 0)-16))
  if view.initializer then view.initializer(frame,data) end
  if self.tableBuilder then pcall(self.tableBuilder.AddRow,self.tableBuilder,frame,data) end
  frame:Show(); return frame
end
function AuctionatorCompatScrollBoxMixin:FullUpdate()
  self:ReleaseFrames()
  if not self.dataProvider or not self.view then return end
  local coll=self.dataProvider.GetCollection and self.dataProvider:GetCollection() or {}
  for i,data in ipairs(coll) do self.frames[i]=self:AcquireElement(i,data) end
  self:LayoutFrames()
  self:TriggerCallback(ScrollBoxListMixin.Event.OnDataRangeChanged)
end
function AuctionatorCompatScrollBoxMixin:LayoutFrames()
  local view=self.view or newView()
  local width=math.max(1,self:GetWidth()-(view.padLeft or 0)-(view.padRight or 0)-16)
  local visibleHeight=math.max(1,self:GetHeight())
  local extent=view.extent or 20
  local spacing=view.spacing or 0
  local total=(view.padTop or 0)+(view.padBottom or 0)+#self.frames*extent+math.max(0,#self.frames-1)*spacing
  self.ScrollTarget:SetHeight(math.max(1,total))
  self.ScrollTarget:SetWidth(width)

  -- Align the maximum range upwards to a whole row. This can leave a tiny
  -- strip of empty space at the very bottom, but guarantees the final row is
  -- fully visible and no partially-scrolled row can overlap the header.
  local rawRange=math.max(0,total-visibleHeight)
  local step=Auctionator335ScrollStep(self)
  local range=rawRange>0 and (math.ceil(rawRange/step)*step) or 0
  self.offset=Clamp(Auctionator335AlignOffset(self,self.offset or 0),0,range)

  local y=(view.padTop or 0)-(self.offset or 0)
  for i,f in ipairs(self.frames) do
    f:ClearAllPoints()
    f:SetPoint('TOPLEFT',self,'TOPLEFT',view.padLeft or 0,-y)
    f:SetWidth(width)
    f:SetHeight(extent)

    -- 3.3.5a has no clipping region for a plain Frame ScrollBox. Only show
    -- complete rows inside the viewport. Because offsets are row-aligned this
    -- behaves like the Classic ScrollBox without leaking into the header.
    if y >= 0 and (y + extent) <= visibleHeight then
      f:Show()
    else
      f:Hide()
    end
    y=y+extent+spacing
  end

  if self.ScrollBar and self.ScrollBar.SetValue then
    local value=range>0 and ((self.offset or 0)/range) or 0
    self.ScrollBar.__sync=true
    self.ScrollBar:SetValue(value)
    self.ScrollBar.__sync=false
  end
end
function AuctionatorCompatScrollBoxMixin:GetDerivedScrollRange()
  local total=self.ScrollTarget and self.ScrollTarget:GetHeight() or 0
  local raw=math.max(0,total-self:GetHeight())
  if raw<=0 then return 0 end
  local step=Auctionator335ScrollStep(self)
  return math.ceil(raw/step)*step
end
function AuctionatorCompatScrollBoxMixin:GetDerivedScrollOffset() return self.offset or 0 end
function AuctionatorCompatScrollBoxMixin:GetVisibleExtent() return self:GetHeight() end
function AuctionatorCompatScrollBoxMixin:GetExtentUntil(index) local v=self.view or newView(); return math.max(0,index-1)*((v.extent or 20)+(v.spacing or 0)) end
function AuctionatorCompatScrollBoxMixin:GetScrollPercentage() local r=self:GetDerivedScrollRange(); if r<=0 then return 0 end return (self.offset or 0)/r end
function AuctionatorCompatScrollBoxMixin:SetScrollPercentage(p)
  local range=self:GetDerivedScrollRange()
  self.offset=Clamp(Auctionator335AlignOffset(self,(p or 0)*range),0,range)
  self:LayoutFrames()
end
function AuctionatorCompatScrollBoxMixin:ScrollToOffset(o)
  local range=self:GetDerivedScrollRange()
  self.offset=Clamp(Auctionator335AlignOffset(self,o or 0),0,range)
  self:LayoutFrames()
end
function AuctionatorCompatScrollBoxMixin:ScrollToElementDataIndex(index) self:ScrollToOffset(self:GetExtentUntil(index)) end
function AuctionatorCompatScrollBoxMixin:ScrollToNearest(index) self:ScrollToElementDataIndex(index) end
function AuctionatorCompatScrollBoxMixin:FindElementDataIndexByPredicate(pred)
  local c=self.dataProvider and self.dataProvider:GetCollection() or {}; for i,v in ipairs(c) do if pred(v) then return i end end
end
function AuctionatorCompatScrollBoxMixin:ForEachFrame(fn) for _,f in ipairs(self.frames) do fn(f) end end
function AuctionatorCompatScrollBoxMixin:EnumerateElementFrames() return ipairs(self.frames) end
function AuctionatorCompatScrollBoxMixin:GetDataProviderData(index) return self.dataProvider and self.dataProvider:GetAtIndex(index) end

ScrollUtil=ScrollUtil or {}

-- On the 3.3.5a XML engine a child <OnLoad> replaces the inherited template
-- <OnLoad> instead of chaining it. Several Auctionator ScrollBoxes therefore
-- exist as plain Frames even though they inherit WowScrollBoxList. Repair the
-- mixin lazily at the point where Auctionator first uses the box.
local function Auctionator335EnsureScrollBox(box)
  if not box then return nil end
  if not box.SetView then
    Mixin(box, AuctionatorCompatScrollBoxMixin)
  end
  if not box.__auctionatorCompatScrollBoxLoaded and box.OnLoad then
    box:OnLoad()
  elseif not box.__auctionatorCompatScrollBoxLoaded and AuctionatorCompatScrollBoxMixin.OnLoad then
    AuctionatorCompatScrollBoxMixin.OnLoad(box)
  end
  return box
end

local function Auctionator335EnsureScrollBar(bar)
  if not bar then return nil end
  if not bar.__auctionatorCompatScrollBarLoaded then
    if not bar.ScrollBox then
      -- The scrollbar mixin is tiny and safe to apply more than once.
      Mixin(bar, AuctionatorCompatScrollBarMixin)
    end
    if AuctionatorCompatScrollBarMixin.OnLoad then
      AuctionatorCompatScrollBarMixin.OnLoad(bar)
    end
    bar.__auctionatorCompatScrollBarLoaded = true
  end
  return bar
end

function ScrollUtil.InitScrollBoxListWithScrollBar(box,bar,view)
  box = Auctionator335EnsureScrollBox(box)
  bar = Auctionator335EnsureScrollBar(bar)
  if not box then return end
  box:SetView(view)
  if bar then
    bar.ScrollBox=box
    box.ScrollBar=bar
  end
end
function ScrollUtil.InitScrollBoxWithScrollBar(box,bar,view) return ScrollUtil.InitScrollBoxListWithScrollBar(box,bar,view) end
function ScrollUtil.RegisterScrollBoxWithScrollBar(box,bar)
  box = Auctionator335EnsureScrollBox(box)
  bar = Auctionator335EnsureScrollBar(bar)
  if bar then
    bar.ScrollBox=box
    if box then box.ScrollBar=bar end
  end
end
function ScrollUtil.RegisterTableBuilder(box,builder)
  box = Auctionator335EnsureScrollBox(box)
  if not box then return end
  box.tableBuilder=builder
  if box.dataProvider then box:FullUpdate() end
end

AuctionatorCompatScrollBarMixin=AuctionatorCompatScrollBarMixin or {}
function AuctionatorCompatScrollBarMixin:OnLoad()
  if self.__auctionatorCompatScrollBarMixinLoaded then return end
  self.__auctionatorCompatScrollBarMixinLoaded = true
  -- On 3.3.5a inheriting a Slider template from a <Frame> does not morph the
  -- widget into a Slider. XML is patched to use <Slider>, but stay defensive
  -- here so one malformed/third-party frame cannot abort Auctionator startup.
  if self.SetMinMaxValues and self.SetValueStep and self.SetValue then
    self:SetMinMaxValues(0,1)
    self:SetValueStep(.01)
    self:SetValue(0)
    self:SetScript('OnValueChanged',function(slider,value)
      if slider.ScrollBox and not slider.__sync then slider.ScrollBox:SetScrollPercentage(value) end
    end)
  else
    self.__auctionatorCompatNonSlider = true
  end
end

-- Simple scroll-box event aliases used by some code paths.
ScrollBoxConstants=ScrollBoxConstants or {}
ScrollBoxConstants.UpdateImmediately=true
