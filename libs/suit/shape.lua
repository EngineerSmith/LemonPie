return function(core, id, color, ...)
  local opt, x,y,w,h = core.getOptionsAndSize(...)
  x, w = x * core.scale, w * core.scale

  if not opt.noScaleY then
    y = y * core.scale
    h = h * core.scale
  end

  opt.id = opt.id or id

  opt.state = core:registerHitbox(opt.id, x,y,w,h)

  local hit = core:mouseReleasedOn(opt.id)
  local hovered = core:isHovered(opt.id)
  local entered = core:isHovered(opt.id) and not core:wasHovered(opt.id)
  local left = not core:isHovered(opt.id) and core:wasHovered(opt.id)

  opt.hit, opt.hovered, opt.entered, opt.left = hit, hovered, entered, left

  core:registerDraw(opt.draw or core.theme.Shape, color, opt, x,y,w,h)

  return {
    id = opt.id,
    hit = hit,
    hovered = hovered,
    entered = entered,
    left = left,
  }
end