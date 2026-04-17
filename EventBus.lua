local _, ns = ...

ns.EventBus = {
  listeners = {},
}

function ns.EventBus:Register(eventName, callback)
  if not self.listeners[eventName] then
    self.listeners[eventName] = {}
  end
  table.insert(self.listeners[eventName], callback)
end

function ns.EventBus:Fire(eventName, ...)
  local list = self.listeners[eventName]
  if not list then
    return
  end
  for _, callback in ipairs(list) do
    ns.Util:SafeCall(callback, ...)
  end
end
