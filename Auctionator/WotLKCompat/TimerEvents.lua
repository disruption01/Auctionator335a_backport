-- Timers, event utilities, callbacks and pools for 3.3.5a
C_Timer = C_Timer or {}
if not C_Timer.After or not C_Timer.NewTicker then
  local jobs = {}
  local driver = CreateFrame('Frame')
  driver:Hide()
  driver:SetScript('OnUpdate', function(self, elapsed)
    for i=#jobs,1,-1 do
      local j=jobs[i]
      if not j.cancelled then
        j.left=j.left-elapsed
        if j.left<=0 then
          local fn=j.fn
          if j.repeating and not j.cancelled then j.left=j.delay else table.remove(jobs,i) end
          local ok,err=pcall(fn)
          if not ok and geterrorhandler then geterrorhandler()(err) end
        end
      else table.remove(jobs,i) end
    end
    if #jobs==0 then self:Hide() end
  end)
  function C_Timer.After(delay,fn)
    jobs[#jobs+1]={left=delay or 0,delay=delay or 0,fn=fn}; driver:Show()
  end
  function C_Timer.NewTicker(delay,fn,iterations)
    local j={left=delay or 0,delay=delay or 0,fn=fn,repeating=true,remaining=iterations}
    local original=fn
    if iterations then
      j.fn=function()
        if j.cancelled then return end
        original()
        j.remaining=j.remaining-1
        if j.remaining<=0 then j.cancelled=true end
      end
    end
    function j:Cancel() self.cancelled=true end
    function j:IsCancelled() return self.cancelled end
    jobs[#jobs+1]=j; driver:Show(); return j
  end
end

FrameUtil = FrameUtil or {}
function FrameUtil.RegisterFrameForEvents(frame, events)
  for _,event in ipairs(events or {}) do pcall(frame.RegisterEvent, frame, event) end
end
function FrameUtil.UnregisterFrameForEvents(frame, events)
  for _,event in ipairs(events or {}) do pcall(frame.UnregisterEvent, frame, event) end
end

EventUtil = EventUtil or {}
function EventUtil.ContinueOnAddOnLoaded(addon, callback)
  if IsAddOnLoaded and IsAddOnLoaded(addon) then callback(); return end
  local f=CreateFrame('Frame'); pcall(f.RegisterEvent,f,'ADDON_LOADED')
  f:SetScript('OnEvent',function(self,event,name) if name==addon then self:UnregisterAllEvents(); callback() end end)
end
function EventUtil.ContinueAfterAllEvents(events, callback)
  local waiting={} for _,e in ipairs(events or {}) do waiting[e]=true end
  local f=CreateFrame('Frame')
  for e in pairs(waiting) do pcall(f.RegisterEvent,f,e) end
  f:SetScript('OnEvent',function(self,event)
    waiting[event]=nil
    for _ in pairs(waiting) do return end
    self:UnregisterAllEvents(); callback()
  end)
end

CallbackRegistryMixin = CallbackRegistryMixin or {}
function CallbackRegistryMixin:OnLoad() self.__callbacks=self.__callbacks or {} end
function CallbackRegistryMixin:GenerateCallbackEvents(events)
  self.__callbacks=self.__callbacks or {}
  for _,e in ipairs(events or {}) do self.__callbacks[e]=self.__callbacks[e] or {} end
end
function CallbackRegistryMixin:RegisterCallback(event, callback, owner)
  self.__callbacks=self.__callbacks or {}
  self.__callbacks[event]=self.__callbacks[event] or {}
  -- Blizzard's registry behaves like one logical registration for the same
  -- owner/callback. 3.3.5a template lifecycle repairs may call OnShow twice,
  -- so silently de-duplicate instead of firing the same handler repeatedly.
  for _, entry in ipairs(self.__callbacks[event]) do
    if entry.fn == callback and entry.owner == owner then
      return
    end
  end
  table.insert(self.__callbacks[event], {fn=callback, owner=owner})
end
function CallbackRegistryMixin:UnregisterCallback(event, owner)
  local t=self.__callbacks and self.__callbacks[event]; if not t then return end
  for i=#t,1,-1 do if t[i].owner==owner then table.remove(t,i) end end
end
function CallbackRegistryMixin:TriggerEvent(event, ...)
  local t=self.__callbacks and self.__callbacks[event]; if not t then return end
  local snapshot={} for i,v in ipairs(t) do snapshot[i]=v end
  for _,v in ipairs(snapshot) do
    -- Blizzard CallbackRegistry does not inject the event name into the
    -- callback payload. Methods get (owner, ...), plain callbacks get (...).
    -- Injecting `event` here made BagCacheUpdated pass the string
    -- "BagCacheUpdated" where Auctionator expected the cache object.
    if v.owner then v.fn(v.owner, ...) else v.fn(...) end
  end
end

-- Object/frame pools --------------------------------------------------------
ObjectPoolMixin = ObjectPoolMixin or {}
function ObjectPoolMixin:OnLoad(create, reset) self.createFunc=create; self.resetFunc=reset; self.active={}; self.inactive={} end
function ObjectPoolMixin:Acquire(...)
  local obj=table.remove(self.inactive)
  if not obj then obj=self.createFunc(self, ...) end
  self.active[obj]=true
  return obj, not obj.__auctionatorPoolUsed
end
function ObjectPoolMixin:Release(obj)
  if not self.active[obj] then return end
  self.active[obj]=nil
  if self.resetFunc then self.resetFunc(self,obj) end
  obj.__auctionatorPoolUsed=true
  self.inactive[#self.inactive+1]=obj
end
function ObjectPoolMixin:ReleaseAll() local list={} for obj in pairs(self.active) do list[#list+1]=obj end for _,obj in ipairs(list) do self:Release(obj) end end
function ObjectPoolMixin:EnumerateActive() return pairs(self.active) end
function ObjectPoolMixin:GetNumActive() local n=0 for _ in pairs(self.active) do n=n+1 end return n end
function Pool_HideAndClearAnchors(pool,obj) if obj.Hide then obj:Hide() end if obj.ClearAllPoints then obj:ClearAllPoints() end end
FramePool_HideAndClearAnchors=FramePool_HideAndClearAnchors or Pool_HideAndClearAnchors
function CreateObjectPool(create, reset) local p=CreateFromMixins(ObjectPoolMixin); p:OnLoad(create,reset); return p end
local __auctionatorPoolFrameID=0
function CreateFramePool(frameType, parent, template, reset)
  return CreateObjectPool(function()
    __auctionatorPoolFrameID=__auctionatorPoolFrameID+1
    local f=CreateFrame(frameType or 'Frame', 'AuctionatorCompatPoolFrame'..__auctionatorPoolFrameID, parent, template)
    return f
  end, reset or Pool_HideAndClearAnchors)
end
FramePoolCollectionMixin = FramePoolCollectionMixin or {}
function FramePoolCollectionMixin:OnLoad() self.pools={} end
function FramePoolCollectionMixin:GetOrCreatePool(frameType,parent,template,reset)
  local key=(frameType or 'Frame')..'\031'..tostring(parent)..'\031'..tostring(template)
  if not self.pools[key] then self.pools[key]=CreateFramePool(frameType,parent,template,reset) end
  return self.pools[key]
end
function FramePoolCollectionMixin:ReleaseAll() for _,p in pairs(self.pools) do p:ReleaseAll() end end
function FramePoolCollectionMixin:EnumerateActive()
  local all={}
  for _,p in pairs(self.pools) do for obj in p:EnumerateActive() do all[#all+1]=obj end end
  local i=0; return function() i=i+1; return all[i] end
end
function CreateFramePoolCollection() local p=CreateFromMixins(FramePoolCollectionMixin); p:OnLoad(); return p end
