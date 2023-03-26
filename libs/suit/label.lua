-- This file is part of SUIT, copyright (c) 2016 Matthias Richter

local BASE = (...):match('(.-)[^%.]+$')

return function(core, text, ...)
	local opt, x,y,w,h = core.getOptionsAndSize(...)
	local prey = y
	x, w = x * core.scale, w * core.scale

	if not opt.noScaleY then
		y = y * core.scale
	end


	if not opt.x then
		opt.x, opt.y, opt.w, opt.h = 0, 0, 0, 0
	end

	opt.id = opt.id or text

	local font = opt.font or love.graphics.getFont()

	w = w or font:getWidth(text) + 4
	h = h or font:getHeight() + 4
	
	opt.state = core:registerHitbox(opt.id, x,y,w,h)

	local hit = core:mouseReleasedOn(opt.id)
	local hovered = core:isHovered(opt.id)
	local entered = hovered and not core:wasHovered(opt.id)
	local left = not hovered and core:wasHovered(opt.id)

	opt.hit, opt.hovered, opt.entered, opt.left = hit, hovered, entered, left

	core:registerDraw(opt.draw or core.theme.Label, text, opt, x,y,w,h)
	
	return {
		id = opt.id,
		hit = hit,
		hovered = hovered,
		entered = entered,
		left = left,
		x = x, y = y, w = w, h = h, prey = prey
	}
end
