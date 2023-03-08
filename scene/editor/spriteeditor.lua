local lg = love.graphics

local isCursorSupported = love.mouse.isCursorSupported()
local cursor_sizewe 
if isCursorSupported then
  cursor_sizewe = love.mouse.getSystemCursor("sizewe")
end

local settings = require("util.settings")
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

local tabWidth = 200
local tabWidthChanging = false
local tabNotHeld = false
local scrollHeight = 0
local scrollHitbox = nil

local drawSpriteSheetTabUI = function(x, y, width)
  local suit = spriteEditor.suit

  suit.layout:reset(x, y, 10, 10)
  local label = suit:Label("Spritesheets", {noBox = true}, suit.layout:up(width-5, lg.getFont():getHeight()))
  do
    suit:Shape(-1, {.6,.6,.6}, {noScaleY = true}, x+3,label.y+label.h,width-11,2*suit.scale)
  end

  scrollHitbox = suit:Shape("spriteSheetTabScroll", {1,1,1,0}, x, label.y+label.h, width-5, lg.getHeight())

  suit.layout:reset(x, label.y+label.h+5+scrollHeight, 10,10)
  suit:Label("Hello World", {noBox = true, noScaleY = true}, suit.layout:down(width-5, lg.getFont():getHeight()))
  suit:Label("Hello World", {noBox = true, noScaleY = true}, suit.layout:down(width-5, lg.getFont():getHeight()))
  suit:Label("Hello World", {noBox = true, noScaleY = true}, suit.layout:down(width-5, lg.getFont():getHeight()))
  suit:Label("Hello World", {noBox = true, noScaleY = true}, suit.layout:down(width-5, lg.getFont():getHeight()))

  local dragBar = suit:Shape("spritesheetTabBGDragBar", {.2,.2,.2}, width-5, y, 5,lg.getHeight())
  suit:Shape("spritesheetTabBG", {.4,.4,.4}, x, y, width-5, lg.getHeight())

  local isPrimaryMousePressed = love.mouse.isDown(1)

  if dragBar.entered and isPrimaryMousePressed and not tabWidthChanging then
    tabNotHeld = true
  end
  if dragBar.hovered then
    if isCursorSupported and cursor_sizewe then love.mouse.setCursor(cursor_sizewe) end
    if not isPrimaryMousePressed then
      tabNotHeld = false
    end
  end
  if not tabNotHeld and isPrimaryMousePressed then
    tabWidthChanging = true
    tabWidth = love.mouse.getX() / suit.scale
    if tabWidth < 180 then tabWidth = 180 end
    if tabWidth > 350 then tabWidth = 350 end
  end
  if tabWidthChanging and not isPrimaryMousePressed then
    tabWidthChanging = false
    tabWidth = math.floor(tabWidth)
    if not dragBar.hovered then
      tabNotHeld = false
      if isCursorSupported then love.mouse.setCursor(nil) end
    end
  end
  if dragBar.left and not tabWidthChanging then
    tabNotHeld = false
    if isCursorSupported then love.mouse.setCursor(nil) end
  end
end

spriteEditor.updateui = function(x, y)
  drawSpriteSheetTabUI(x, y, tabWidth)
end

spriteEditor.draw = function()
  
end

spriteEditor.resize = function(_, _)
  scrollHeight = 0
end

spriteEditor.filedropped = function(file)
  
end

spriteEditor.isdropping = function(x, y)

end

spriteEditor.stoppeddropping = function()

end

spriteEditor.wheelmoved = function(_, y)
  if scrollHitbox.hovered then
    scrollHeight = scrollHeight + y * settings.client.scrollspeed
    if scrollHeight < 0 then scrollHeight = 0 end
  end
end

spriteEditor.mousepressed = function(_,_, button)
  if button == 3 and scrollHitbox.hovered then
    scrollHeight = 0
  end
end

return spriteEditor 