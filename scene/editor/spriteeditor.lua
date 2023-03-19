local lg = love.graphics

local isCursorSupported = love.mouse.isCursorSupported()
local cursor_sizewe, cursor_sizeall
if isCursorSupported then
  cursor_sizewe = love.mouse.getSystemCursor("sizewe")
  cursor_sizeall = love.mouse.getSystemCursor("sizeall")
end

local settings = require("util.settings")
local logger = require("util.logger")

local movingGrid = false

local spriteEditor = { 
  gridX = 0, gridY = 0
}

spriteEditor.load = function(project, suit)
  spriteEditor.suit = suit
end

spriteEditor.unload = function()
  if isCursorSupported then
    love.mouse.setCursor(nil)
  end
end

spriteEditor.update = function(dt)
  
end

local validateTabWidth = function(width)
  if width < 180 then width = 180 end
  if width > 350 then width = 350 end
  return width
end

local tabWidth = validateTabWidth(settings.client.spritesheetTabWidth)
settings.client.spritesheetTabWidth = tabWidth
local tabWidthChanging = false
local tabNotHeld = false

local scrollHeight = 0
local scrollHitbox = nil

local subtitleGrey = {love.math.colorFromBytes(210,210,210)}

local drawSpriteSheetTabUI = function(x, y, width)
  local suit = spriteEditor.suit

  suit.layout:reset(x, y, 10, 10)
  local label = suit:Label("Spritesheets", {noBox = true}, suit.layout:up(width-5, lg.getFont():getHeight()))
  suit:Shape(-1, {.6,.6,.6}, {noScaleY = true}, x+3,label.y+label.h,width-11,2*suit.scale)

  scrollHitbox = {x, label.y+label.h, width-5, lg.getHeight()}

  suit.layout:reset(x, label.y+label.h+5+scrollHeight, 10,10)
  suit:Label("Hello World tooooooooooooo longggggggg?", {noBox = true, noScaleY = true, font = suit.subtitleFont, align = "left", color = subtitleGrey}, suit.layout:down(width-5, suit.subtitleFont:getHeight()))
  suit:Label("Hello World", {noBox = true, noScaleY = true, font = suit.subtitleFont, align = "left", color = subtitleGrey}, suit.layout:down(width-5, suit.subtitleFont:getHeight()))
  suit:Label("Hello World", {noBox = true, noScaleY = true, font = suit.subtitleFont, align = "left", color = subtitleGrey}, suit.layout:down(width-5, suit.subtitleFont:getHeight()))
  suit:Label("Hello World", {noBox = true, noScaleY = true, font = suit.subtitleFont, align = "left", color = subtitleGrey}, suit.layout:down(width-5, suit.subtitleFont:getHeight()))

  local dragBar = suit:Shape("spritesheetTabBGDragBar", {.2,.2,.2}, width-5, y, 5,lg.getHeight())
  suit:Shape("spritesheetTabBG", {.4,.4,.4}, x, y, width-5, lg.getHeight())

  local isPrimaryMousePressed = love.mouse.isDown(1)

  if dragBar.entered and isPrimaryMousePressed and not tabWidthChanging then
    tabNotHeld = true
  end
  if dragBar.hovered and not movingGrid then
    if isCursorSupported and cursor_sizewe then love.mouse.setCursor(cursor_sizewe) end
    if not isPrimaryMousePressed then
      tabNotHeld = false
    elseif not tabNotHeld then -- and isPrimaryMousePressed
      tabWidthChanging = true
    end
  end
  if tabWidthChanging then
    tabWidth = validateTabWidth(love.mouse.getX() / suit.scale)
  end
  if tabWidthChanging and not isPrimaryMousePressed then
    tabWidthChanging = false
    tabWidth = math.floor(tabWidth)
    settings.client.spritesheetTabWidth = tabWidth
    if not dragBar.hovered then
      tabNotHeld = false
      if isCursorSupported then love.mouse.setCursor(nil) end
    end
  end
  if dragBar.left and not tabWidthChanging and not movingGrid then
    tabNotHeld = false
    if isCursorSupported then love.mouse.setCursor(nil) end
  end
end

spriteEditor.updateui = function(x, y)
  drawSpriteSheetTabUI(x, y, tabWidth)
end

local drawGrid = function(x, y, tileW, tileH, w, h, scale)
  scale = scale or spriteEditor.suit.scale
  lg.push("all")
  lg.setLineWidth(math.min(.8 / (scale * 1.5), .4))
  lg.setColor(.6,.6,.7)

  local scaledW, scaledH = tileW * scale, tileH * scale
  local offsetX, offsetY = x % scaledW, y % scaledH

  x = x > 0 and -x or x
  y = y > 0 and -y or y
  
  for i=-scaledW + offsetX, w, scaledW do
    lg.line(i, y, i, h)
  end
  for i=-scaledH + offsetY, h, scaledH do
    lg.line(x, i, w, i)
  end
  lg.pop()
end

spriteEditor.draw = function()
  drawGrid(spriteEditor.gridX,spriteEditor.gridY, 20,20, lg.getDimensions())
end

spriteEditor.resize = function(_, _)
  scrollHeight = 0
end

spriteEditor.directorydropped = function(directory)
  
end

spriteEditor.filedropped = function(file)
  
end

spriteEditor.isdropping = function(x, y)

end

spriteEditor.stoppeddropping = function()

end

spriteEditor.mousepressed = function(x,y, button)
  if button == 3 and scrollHitbox and spriteEditor.suit:mouseInRect(unpack(scrollHitbox)) then
    scrollHeight = 0
  end
  if button == 1 and not spriteEditor.suit:anyHovered() and not tabWidthChanging then
    movingGrid = true
    if cursor_sizeall then
      love.mouse.setCursor(cursor_sizeall)
    end
  end
end

spriteEditor.mousemoved = function(_, _, dx, dy)
  if movingGrid then
    spriteEditor.gridX = spriteEditor.gridX + dx
    spriteEditor.gridY = spriteEditor.gridY + dy
  end
end

spriteEditor.mousereleased = function(_,_, button)
  if movingGrid then
    movingGrid = false
    love.mouse.setCursor(nil)
  end
end

spriteEditor.wheelmoved = function(_, y)
  if not movingGrid and scrollHitbox and spriteEditor.suit:mouseInRect(unpack(scrollHitbox)) then
    scrollHeight = scrollHeight + y * settings.client.scrollspeed
    if scrollHeight > 0 then scrollHeight = 0 end -- TODO: graphics - mask scroll area
  end
end

return spriteEditor 