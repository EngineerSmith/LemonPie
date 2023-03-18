local lm, lg = love.math, love.graphics

local flux = require("libs.flux")

local theme = {
    scale = 1,
    cornerRadius = 3,
    color = { 
        normal = {
          bg = { lm.colorFromBytes( 43, 77, 89,220) },
          fg = { lm.colorFromBytes(235,215,220) },
        },
        hovered = {
          bg = { lm.colorFromBytes( 57,153,142) },
          fg = { lm.colorFromBytes(209,190,186) },
        },
        active = {
          bg = { lm.colorFromBytes(255,220,124) },
          fg = { lm.colorFromBytes( 43, 77, 89) },
        },
        error = {
          bg = { lm.colorFromBytes(191, 39, 66) },
          fg = { lm.colorFromBytes(240,208,107) },
        },
        disable = {
          bg = { lm.colorFromBytes( 60, 78, 84) },
          fg = { lm.colorFromBytes(145,148,158) },
        }
      },
  }

theme.getColorForState = function(opt)
  local s = type(opt) == "table" and opt.state or type(opt) == "string" and opt or "normal"
  return opt and opt.color and opt.color[s] or theme.color[s]
end

theme.drawBox = function(x, y, w, h, colors, cornerRadius)
  cornerRadius = cornerRadius or theme.cornerRadius
  cornerRadius = math.max(3, cornerRadius)
  w = math.max(cornerRadius / 2, w)
  if h < cornerRadius / 2 then
    y, h = y - cornerRadius - h, cornerRadius / 2
  end

  lg.push("all")
    lg.setColor(colors.bg)
    lg.rectangle("fill", x, y, w, h, cornerRadius)
  lg.pop()
end

theme.getVerticalOffsetForAlign = function(valign, font, h)
  if valign == "top" then return 0
  elseif valign == "bottom" then return h - font:getHeight()
  elseif type(valign) == "number" then return valign
  else--[[if valign == "middle" then]] return (h - font:getHeight()) / 2
  end
end

-- Widget views

theme.Label = function(text, opt, x, y, w, h)
  local font = opt.font or lg.getFont()
  y = y + theme.getVerticalOffsetForAlign(opt.valign, font, h)
  
  -- if opt.entered then
  --   if opt.flux then opt.flux:stop() end
  --   opt.flux = flux.to(opt, .3, { x=-2, y=-2, w=4,h=4 }):ease("elasticout")
  -- end
  -- if opt.left then
  --   if opt.flux then opt.flux:stop() end
  --   opt.flux = flux.to(opt, .2, { x=0,y=0,w=0,h=0 }):ease("quadout")
  -- end
  -- if opt.flux and opt.flux.progress >= 1 and not opt.hovered then
  --   opt.x, opt.y, opt.w, opt.h = 0, 0, 0, 0
  -- end

  local c = opt.color or theme.getColorForState()
  if not opt.noBox then
    theme.drawBox(x + opt.x, y + opt.y, w + opt.w, h + opt.h, c, (opt.x ~= 0 and opt.r or -opt.x)*3)
  end
  lg.setColor(c.fg or c)
  lg.printf(text or opt.text, font, x + 2, y, w - 4, opt.align or "center")
end

theme.Button = function(text, opt, x, y, w, h)
  if opt.entered then
    if opt.flux then opt.flux:stop() end
    opt.flux = flux.to(opt, .5, {
      x = opt.targetX or -3,
      y = opt.targetY or -3,
      w = opt.targetW or  6,
      h = opt.targetH or  6 }):ease("elasticout")
  end
  if opt.left then
    if opt.flux then opt.flux:stop() end
    opt.flux = flux.to(opt, .2, { x=0,y=0,w=0,h=0 }):ease("quadout")
  end
  if opt.flux and opt.flux.progress >= 1 and not opt.hovered then
    opt.x, opt.y, opt.w, opt.h = 0, 0, 0, 0
  end

  local c = theme.getColorForState(opt.active and "active" or opt.error and "error" or opt.disable and "disable" or opt)
  theme.drawBox(x + opt.x, y + opt.y, w + opt.w, h + opt.h, c, (opt.x ~= 0 and opt.r or -opt.x)*3)

  local font = opt.font or lg.getFont()
  y = y + theme.getVerticalOffsetForAlign(opt.align, font, h)
  if type(text) == "string" then
    lg.setColor(c.fg)
    if opt.hovered then
      text = "< "..text.." >"
    end

    lg.printf(text, font, x + 2, y, w - 4, opt.align or "center")
  else
    lg.setColor(1,1,1)
    lg.draw(text, x + w/2 - text:getWidth()*theme.scale + opt.x, y-text:getHeight()*(theme.scale)/2.3 + opt.y+1.5, 0, (2+opt.w/theme.scale/(opt.targetW or 6)/2-.2)*theme.scale, (2+opt.h/theme.scale/(opt.targetH or 6)/2-.2)*theme.scale)
  end
end

theme.Checkbox = function(chk, opt, x, y, w, h)
  local font = opt.font or lg.getFont()
  lg.push("all")
    lg.translate(-5,0)
    local c = theme.getColorForState(opt)
    local th = font:getHeight()

    if opt.entered then
      if opt.flux then opt.flux:stop() end
      opt.flux = flux.to(opt, .3, { x=-2, y=-2, w=4,h=4 }):ease("elasticout")
    end
    if opt.left then
      if opt.flux then opt.flux:stop() end
      opt.flux = flux.to(opt, .2, { x=0,y=0,w=0,h=0 }):ease("quadout")
    end
    if opt.flux and opt.flux.progress >= 1 and not opt.hovered then
      opt.x, opt.y, opt.w, opt.h = 0, 0, 0, 0
    end

    theme.drawBox(x + h / 10, y + h / 10, h * .8, h * .8, c, 2)
    lg.setColor(c.fg)
    if chk.checked then
      lg.setLineStyle("smooth")
      lg.setLineWidth(5)
      lg.setLineJoin("miter")
      lg.line(x + h * .20, y + h * .55,
              x + h * .45, y + h * .75,
              x + h * .80, y + h * .20)
    end
    if chk.text then
      theme.drawBox(x + h + 7 + opt.x, y + opt.y, w - h * .8 - 7 + opt.w, h + opt.h, c, -opt.x*3)
      y = y + theme.getVerticalOffsetForAlign(opt.valign, font, h)
      lg.printf(chk.text, font, x + h, y, w - h, opt.align or "left")
    end
  lg.pop()
end

theme.Slider = function(fraction, opt, x, y, w, h)
  local xb, yb, wb, hb -- size of progress bar
  local r = math.min(w,h) / 2.1

  if opt.entered then
    if opt.flux then opt.flux:stop() end
    opt.flux = flux.to(opt, .7, { x = -1, y = -1, h = .65 }):ease("elasticout")
  end
  if opt.left then
    if opt.flux then opt.flux:stop() end
    opt.flux = flux.to(opt, .2, { x = 0, y = 0, h = .55 }):ease("quadout")
  end
  if opt.flux and opt.flux.progress >= 1 and not opt.hovered then
    opt.x, opt.y, opt.w, opt.h = 0, 0, 0, .55
  end

  local scale = opt.h

  if opt.vertical then
    x, w = x + w * .25 + opt.x, w * scale
    xb, yb, wb, hb = x, y + h * (1-fraction), w, h * fraction
  else
    y, h = y + h * .25 + opt.y, h * scale
    xb, yb, wb, hb = x, y, w * fraction, h
  end

  local c = theme.getColorForState(opt)
  theme.drawBox(x, y, w, h, c, opt.cornerRadius)
  theme.drawBox(xb, yb, wb, hb, {bg=c.fg}, opt.cornerRadius)

  if opt.state ~= nil and opt.state ~= "normal" then
    lg.setColor((opt.color and opt.color.active or { }).fg or theme.color.active.fg)
    local dx, dy
    if opt.vertical then
      dx, dy = x + wb / 2, yb
    else
      dx, dy = x + wb, yb + hb / 2
    end
    lg.circle("fill", dx, dy, r)
    if opt.img then
      lg.setColor(1,1,1)
      lg.draw(opt.img, dx-r, dy-r, 0, r*2/opt.img:getWidth(), r*2/opt.img:getHeight())
    end
  end
end

local utf8 = require("utf8")
theme.Input = function(input, opt, x, y, w, h)
  theme.drawBox(x, y, w, h, opt.color and opt.color.normal or theme.color.normal, opt.cornerRadius)
  x = x + 3
  w = w - 6
  
  local font = opt.font or lg.getFont()
  local th = font:getHeight()
  
  lg.push("all")
    -- scissor
    lg.setScissor(x - 1, y, w + 2, h)
    x = x - input.text_draw_offset
    -- text
    lg.setColor(opt.color and opt.color.normal and opt.color.fg or theme.color.normal.fg)
    lg.print(input.text, font, x, y + (h - th) / 2)
    -- candidate text
    local tw = font:getWidth(input.text)
    local ctw = font:getWidth(input.candidate_text.text)
    lg.print(input.candidate_text.text, font, x + tw, y (h - th) / 2)
    -- candidate text rect
    lg.rectangle("line", x + tw, y (h - th) / 2, ctw, th)
    -- cursor
    if opt.hasKeyboardFocus and love.timer.getTime() % 1 > .5 then
      local ct = input.candidate_text
      local ss = ct.text:sub(1, utf8.offset(ct.text, ct.start))
      local ws = font:getWidth(ss)
      if ct.start == 0 then ws = 0 end
      lg.setLineWidth(1)
      lg.setLineStyle("rough")
      lg.line(x + opt.cursor_pos + ws, y + (h - th) / 2,
              x + opt.cursor_pos + ws, y + (h + th) / 2)
    end
  lg.pop()
end

return theme
