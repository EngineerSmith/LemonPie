-- This file is part of SUIT, copyright (c) 2016 Matthias Richter

local BASE = (...):match('(.-)[^%.]+$')

return function(core, info, ...)
	local opt, x,y,w,h = core.getOptionsAndSize(...)
	x, y, w, h = x * core.scale, y * core.scale, w * core.scale, h * core.scale

	if not opt.x then opt.x = 0 end
	if not opt.y then opt.y = 0 end
	if not opt.w then opt.w = 0 end
	if not opt.h then opt.h = 0 end

	opt.id = opt.id or info

	info.min = info.min or math.min(info.value, 0)
	info.max = info.max or math.max(info.value, 1)
	info.step = info.step or (info.max - info.min) / 10
	local fraction = (info.value - info.min) / (info.max - info.min)
	local value_changed = false

	opt.state = core:registerHitbox(opt.id, x,y,w,h)

	if core:isActive(opt.id) then
		-- mouse update
		local mx,my = core:getMousePosition()
		if opt.vertical then
			fraction = math.min(1, math.max(0, (y+h - my) / h))
		else
			fraction = math.min(1, math.max(0, (mx - x) / w))
		end
		local v = fraction * (info.max - info.min) + info.min
		if v ~= info.value then
			info.value = v
			value_changed = true
		end
	end

	local hit = core:mouseReleasedOn(opt.id)
	local hovered = core:isHovered(opt.id)
	local entered = hovered and not core:wasHovered(opt.id)
	local left = not hovered and core:wasHovered(opt.id)

	opt.hit, opt.hovered, opt.entered, opt.left = hit, hovered, entered, left

	if hovered then
		local wx, wy = core:getWheelDelta()
		if wy and wy ~= 0 then
			local value = math.min(info.max, math.max(info.value + wy * info.step * 5, info.min))
			if value ~= info.value then
				info.value = value
				value_changed = true
			end
		end

		-- keyboard update
		local key_up = opt.vertical and 'up' or 'right'
		local key_down = opt.vertical and 'down' or 'left'
		if core:getPressedKey() == key_up then
			info.value = math.min(info.max, info.value + info.step)
			value_changed = true
		elseif core:getPressedKey() == key_down then
			info.value = math.max(info.min, info.value - info.step)
			value_changed = true
		end
	end

	core:registerDraw(opt.draw or core.theme.Slider, fraction, opt, x,y,w,h)

	return {
		id = opt.id,
		hit = hit,
		changed = value_changed,
		hovered = hovered,
		entered = entered,
		left = left
	}
end
