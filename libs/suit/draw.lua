return function(core, drawFunc, ...)
  local opt, x,y,w,h = core.getOptionsAndSize(...)

  if not drawFunc then error("Draw function required") end
  
  if not opt.noScaleX then
    x, w = x * core.scale, w * core.scale
  end
  if not opt.noScaleY then
    y, h  = y * core.scale, h * core.scale
  end

  core:registerDraw(drawFunc, x,y,w,h, opt)

  return
end