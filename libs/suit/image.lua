local lg = love.graphics

local defaultBackgroundColor = {.15,.15,.15,1}
local defaultDraw = function(image,x,y,w,h, opt, core, hovered, r,g,b,a)
  if opt.background then
    lg.setColor(opt.backgroundColor or defaultBackgroundColor)
    lg.rectangle("fill", x-2,y-2,w+4,h+4)
    if hovered and opt.hoverBoarder then
      lg.setColor(opt.hoverBoarder)
      lg.rectangle("line", x-2,y-2,w+4,h+4)
    end
  end
  lg.setColor(r,g,b,a)
  local iw, ih = image:getDimensions()
  local sw, sh = w / iw, h / ih
  local s = sw < sh and sw or sh
  lg.draw(image, x + (w-iw*s)/2, y + (h-ih*s)/2, 0, s)
end

local function isType(val, typ)
	return type(val) == "userdata" and val.typeOf and val:typeOf(typ)
end

return function(core, id, image, ...)
  assert(isType(image, "Texture"), "Given image is not a love.graphics.texture")

  local opt, x,y,w,h = core.getOptionsAndSize(...)

  if not opt.noScaleX then
    x, w = x * core.scale, w * core.scale
  end
  if not opt.noScaleY then
    y, h  = y * core.scale, h * core.scale
  end
  opt.id = id or opt.id

  opt.state = core:registerHitbox(opt.id, x,y,w,h)

  local hit = core:mouseReleasedOn(opt.id)
  local hovered = core:isHovered(opt.id)
  local entered = hovered and not core:wasHovered(opt.id)
  local left = not hovered and core:wasHovered(opt.id)

  opt.hit, opt.hovered, opt.entered, opt.left = hit, hovered, entered, left

  core:registerDraw(opt.draw or defaultDraw, image, x,y,w,h, opt, core, hovered, lg.getColor())

  return {
    id = opt.id,
    hit = hit,
    hovered = hovered,
    entered = entered,
    left = left,
  }
end