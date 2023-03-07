local lg = love.graphics

local isCursorSupported = love.mouse.isCursorSupported()
local cursor_sizewe 
if isCursorSupported then
  cursor_sizewe = love.mouse.getSystemCursor("sizewe")
end

local logger = require("util.logger")

local spriteEditor = { }

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

local spriteSheetTabWidth = 200
local spriteSheetTabWidthChanging = false

local drawSpriteSheetTabUI = function(x, y, width)
  local suit = spriteEditor.suit

  suit.layout:reset(x, y, 10, 10)
  local label = suit:Label("Spritesheets", {noBox = true}, suit.layout:up(width-5, lg.getFont():getHeight()))
  do
    suit:Shape(-1, {.6,.6,.6}, {noScaleY = true}, x+3,label.y+label.h,width-11,2*suit.scale)
  end
  local s = suit:Shape("spritesheetTabBGDragBar", {.2,.2,.2}, width-5, y, 5,lg.getHeight())
  suit:Shape("spritesheetTabBG", {.4,.4,.4}, x, y, width-5, lg.getHeight())
  if s.entered and cursor_sizewe then
    love.mouse.setCursor(cursor_sizewe)
  elseif s.left and isCursorSupported and not spriteSheetTabWidthChanging then
    love.mouse.setCursor(nil)
  end
  if s.hovered and love.mouse.isDown(1) then
    spriteSheetTabWidthChanging = true
  end
  if spriteSheetTabWidthChanging then
    if not love.mouse.isDown(1) then
      spriteSheetTabWidth = math.floor(spriteSheetTabWidth)
      spriteSheetTabWidthChanging = false
      if isCursorSupported then
        love.mouse.setCursor(nil)
      end
      return
    end
    spriteSheetTabWidth = love.mouse.getX() / suit.scale
    if spriteSheetTabWidth < 180 then spriteSheetTabWidth = 180 end
    if spriteSheetTabWidth > 350 then spriteSheetTabWidth = 350 end
  end
end

spriteEditor.updateui = function(x, y)
  drawSpriteSheetTabUI(x, y, spriteSheetTabWidth)
end

spriteEditor.draw = function()
  
end

spriteEditor.filedropped = function(file)
  
end

spriteEditor.isdropping = function(x, y)

end

spriteEditor.stoppeddropping = function()

end

return spriteEditor 