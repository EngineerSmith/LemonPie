local lg = love.graphics

local isCursorSupported = love.mouse.isCursorSupported()
local cursor_sizewe, cursor_sizeall
if isCursorSupported then
  cursor_sizewe = love.mouse.getSystemCursor("sizewe")
  cursor_sizeall = love.mouse.getSystemCursor("sizeall")
end

local sysl = require("libs.SYSL-Text")

local settings = require("util.settings")
local logger = require("util.logger")
local fileUtil = require("util.file")

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
  if spriteEditor.spritesheetdroppingText then
    spriteEditor.spritesheetdroppingText:update(dt)
  end
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

local makeDroptext = function(font)
  if (spriteEditor.spritesheetdroppingText and spriteEditor.spritesheetdroppingText.maxWidth ~= scrollHitbox[3]) or 
      (not spriteEditor.spritesheetdroppingText and scrollHitbox) then
    spriteEditor.spritesheetdroppingText = sysl.new("center", {
        color = {.9,.9,.9,1},
        shadow_color = {.2,.2,.2},
        print_speed = 0,
        font = font,
      })
    spriteEditor.spritesheetdroppingText.bounce_height = 1
    spriteEditor.spritesheetdroppingText.maxWidth = scrollHitbox[3]
    spriteEditor.spritesheetdroppingText:send("[bounce=8][dropshadow=10]Drop Spritesheet[/bounce]", scrollHitbox[3], true)
  end
end

local subtitleGrey = {love.math.colorFromBytes(210,210,210)}

local drawSpriteSheetTabUI = function(x, y, width)
  local suit = spriteEditor.suit

  suit.layout:reset(x, y, 10, 10)
  local label = suit:Label("Spritesheets", {noBox = true}, suit.layout:up(width-5, lg.getFont():getHeight()))
  suit:Shape(-1, {.6,.6,.6}, {noScaleY = true}, x,label.y+label.h,width-5,2*suit.scale)

  scrollHitbox = {x, label.y+label.h, (width-5)*suit.scale, lg.getHeight()}

  makeDroptext(lg.getFont())

  if spriteEditor.isdroppingSpritesheet then
    local s = suit:Shape("droppingSpritesheet", {.1,.1,.1,.7}, {noScaleY = true}, x, label.y+label.h+2*suit.scale, width-5, lg.getHeight())
  end
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

spriteEditor.drawUAboveUI = function()
  if spriteEditor.isdroppingSpritesheet then
    local h = spriteEditor.spritesheetdroppingText.get.height
    local targetY = spriteEditor.isdroppingSpritesheet-h/2
    if targetY > lg.getHeight()-h then
      targetY = lg.getHeight() - h
    end
    if targetY < scrollHitbox[2] then
      targetY = scrollHitbox[2]
    end
    spriteEditor.spritesheetdroppingText:draw(0,targetY)
  end
  if spriteEditor.img then
    lg.draw(spriteEditor.img, 0,0)
  end
end

spriteEditor.resize = function(_, _)
  scrollHeight = 0
end

spriteEditor.directorydropped = function(directory)
  
end

spriteEditor.filedropped = function(file)
  if spriteEditor.isdroppingSpritesheet then
    if fileUtil.isImageFile(file:getFilename()) then
      local data = file:read("data")
      spriteEditor.img = lg.newImage(data)
    end
  end
end

spriteEditor.isdropping = function(mx, my)
  if scrollHitbox then
    local x,y,w,h = unpack(scrollHitbox)
    if spriteEditor.suit:mouseInRect(x,y,w,h, mx,my) then
      spriteEditor.isdroppingSpritesheet = my
    else
      spriteEditor.isdroppingSpritesheet = false
    end
  end
end

spriteEditor.stoppeddropping = function()
  spriteEditor.isdroppingSpritesheet = false
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