local undo = { 
  list = { }
}

undo.push = function(func, ...)
  table.insert(undo.list, {func, ...})
end

undo.pop = function()
  local i = #undo.list
  if i >= 1 then
    local func = undo.list[i][1]
    func(unpack(undo.list[i], 2))
    table.remove(undo.list, i)
  end
end

undo.reset = function()
  undo.list = { }
end

undo.hasItemsWaiting = function()
  return #undo.list > 0
end

return undo