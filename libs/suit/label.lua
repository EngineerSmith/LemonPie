-- This file is part of SUIT, copyright (c) 2016 Matthias Richter

local BASE = (...):match('(.-)[^%.]+$')

return function(core, text, ...)
	local opt, x,y,w,h = core.getOptionsAndSize(...)
	x, y, w, h = x * core.scale, y * core.scale, w * core.scale, h * core.scale

	if not opt.x then
		opt.x, opt.y, opt.w, opt.h = 0, 0, 0, 0
	end

	opt.id = opt.id or text

	w = w or opt.font:getWidth(text) + 4
	h = h or opt.font:getHeight() + 4
	
	opt.state = core:registerHitbox(opt.id, x,y,w,h)

	local hit = core:mouseReleasedOn(opt.id)
	local hovered = core:isHovered(opt.id)
	local entered = core:isHovered(opt.id) and not core:wasHovered(opt.id)
	local left = not core:isHovered(opt.id) and core:wasHovered(opt.id)

	opt.hit, opt.hovered, opt.entered, opt.left = hit, hovered, entered, left

	core:registerDraw(opt.draw or core.theme.Label, text, opt, x,y,w,h)

	return {
		id = opt.id,
		hit = hit,
		hovered = hovered,
		entered = entered,
		left = left
	}
end