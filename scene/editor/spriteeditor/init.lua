local lg, lm = love.graphics, love.mouse

local isCursorSupported = lm.isCursorSupported()
local cursor_sizewe, cursor_sizeall, cursor_ibeam
if isCursorSupported then
  cursor_sizewe = lm.getSystemCursor("sizewe")
  cursor_sizeall = lm.getSystemCursor("sizeall")
  cursor_ibeam = lm.getSystemCursor("ibeam")
end

local sysl = require("libs.SYSL-Text")
local nfs = require("libs.nativefs")

local settings = require("util.settings")
local logger = require("util.logger")
local fileUtil = require("util.file")
local assets = require("util.assets")

local undo = require("src.undo")

local movingGrid = false

local spriteEditor = { 
  gridX = 0, gridY = 0
}

spriteEditor.load = function(project, suit)
  spriteEditor.project = project
  spriteEditor.suit = suit

  local errors = nil

  spriteEditor.spritesheets = { }
  for _, spritesheet in ipairs(spriteEditor.project.spritesheets) do
    local filepath = spriteEditor.project.path..spritesheet.path
    local info = nfs.getInfo(filepath, "file")
    if info then
      local data = nfs.read("data", filepath)
      table.insert(spriteEditor.spritesheets, {
          path = spritesheet.path,
          fullpath = filepath,
          text = spritesheet.name or fileUtil.getFileName(spritesheet.path),
          image = lg.newImage(data),
          time = info.modtime,
          editing = false,
        })
    else    --- add new line, or start with nothing
      errors = (errors and errors.."\n" or "").."Could not find: "..tostring(fullpath)
    end
  end
  if errors then
    logger.error("Issues with finding spritesheets added to project:\n", errors)
  end
  logger.info("Loaded", #spriteEditor.spritesheets, "spritesheets")
  return errors
end

spriteEditor.addSpritesheet = function(path, imageData, modtime)
  local filepath = spriteEditor.project.path..path
  table.insert(spriteEditor.spritesheets, {
      path = path,
      fullpath = filepath,
      text = fileUtil.getFileName(path),
      image = lg.newImage(imageData),
      time = modtime,
      editing = false,
    })
end

spriteEditor.unload = function()
  spriteEditor.project = nil
  if isCursorSupported then
    lm.setCursor(nil)
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
spriteEditor.scrollHitbox = nil

local makeDroptext = function(font)
  if (spriteEditor.spritesheetdroppingText and spriteEditor.spritesheetdroppingText.maxWidth ~= spriteEditor.scrollHitbox[3]) or 
      (not spriteEditor.spritesheetdroppingText and spriteEditor.scrollHitbox) then
    spriteEditor.spritesheetdroppingText = sysl.new("center", {
        color = {.9,.9,.9,1},
        shadow_color = {.2,.2,.2},
        print_speed = 0,
        font = font,
      })
    spriteEditor.spritesheetdroppingText.bounce_height = 1
    spriteEditor.spritesheetdroppingText.maxWidth = spriteEditor.scrollHitbox[3]
    spriteEditor.spritesheetdroppingText:send("[bounce=8][dropshadow=10]Drop Spritesheet[/bounce]", spriteEditor.scrollHitbox[3], true)
  end
end

local subtitleGrey = {love.math.colorFromBytes(210,210,210)}

local imageOpt = { background = true, noScaleY = true, }
local inputColor = { normal = { bg = {.6,.6,.6}, fg = {1,1,1}}}

local undonaming = function(spritesheet, ss, name)
  spritesheet.text = name
  ss.name = name
end

local drawSpritesheetUi = function(spritesheet, width)
  local suit = spriteEditor.suit
  
  local spritesheetOpt = { 
    font = suit.subtitleFont,
    noScaleY = true,
    noBox = true,
    align = "left",
    oneLine = true,
    id = spritesheet,
  }
  local height = spritesheetOpt.font:getHeight()
  local x,y,w,h = suit.layout:down(width, height)
  suit.layout:padding(20,5)
  
  local state
  
  if not spritesheet.editing then
    state = suit:Label(spritesheet.text, spritesheetOpt, x,y,w,h)
    if state.hit then -- TODO hover faint shape to show hover area
      spritesheet.editing = true
      suit:grabKeyboardFocus(spritesheetOpt.id)
      spritesheet.cursor = nil
    end
  else
    spritesheetOpt.color = inputColor
    state = suit:Input(spritesheet, spritesheetOpt, x-1,y,w+2,h)
    if state.submitted or (not spritesheetOpt.hasKeyboardFocus and not suit:isActive(spritesheet)) then
      spritesheet.editing = false
      for _, ss in ipairs(spriteEditor.project.spritesheets) do
        if ss.path == spritesheet.path then
          if ss.name ~= spritesheet.text then
            undo.push(undonaming, spritesheet, ss, ss.name)
            ss.name = spritesheet.text
            spriteEditor.project.dirty = true
          end
          break
        end
      end
    end
  end

  if state.entered and cursor_ibeam then
    lm.setCursor(cursor_ibeam)
  elseif state.left then
    lm.setCursor(nil)
  end

  suit:Image(spritesheet.fullpath.."image", spritesheet.image, imageOpt, suit.layout:down(width, 120*suit.scale))

  suit.layout:padding(0,3)
  local scale, w,h = .3, assets["icon.trashcan"]:getDimensions()
  suit:ImageButton(assets["icon.right"], {hovered = assets["icon.down"],noScaleY=true,scale=scale, id=spritesheet.fullpath.."down"},suit.layout:down(width-(w*scale*2), h*scale*suit.scale))
  suit:ImageButton(assets["icon.updown"], {hovered = assets["icon.updown"],noScaleY=true, scale = scale, id=spritesheet.fullpath.."updown"}, suit.layout:right(w*scale,h*scale*suit.scale))
  suit:ImageButton(assets["icon.trashcan"], {hovered = assets["icon.trashcan.open"],noScaleY=true, scale = scale, id=spritesheet.fullpath.."trash"}, suit.layout:right())
  suit.layout:left()
  suit.layout:left(width-(w*scale*2), h*scale*suit.scale)

  suit:Shape(-1, {.5,.5,.5}, {noScaleY = true}, suit.layout:down(width, 1*(suit.scale*1.5)))

  suit.layout:padding(20,2)
end

local drawStencil = function(x,y,w,h)
  lg.setColorMask(false)
  lg.setStencilMode("replace", "always", 1)
  lg.rectangle("fill", x,y,w,h)
  lg.setStencilMode("keep", "greater", 0)
  lg.setColorMask(true)
end

local clearStencil = function()
  lg.setStencilMode()
end

local drawSpriteSheetTabUI = function(x, y, width)
  local suit = spriteEditor.suit

  suit.layout:reset(x, y, 10, 10)
  local label = suit:Label("Spritesheets", {noBox = true}, suit.layout:up(width-5, lg.getFont():getHeight()))
  suit:Shape(-1, {.6,.6,.6}, {noScaleY = true}, x,label.y+label.h,width-5,2*suit.scale)

  spriteEditor.scrollHitbox = {x, label.y+label.h, (width-5)*suit.scale, lg.getHeight()}

  suit:Draw(clearStencil, unpack(spriteEditor.scrollHitbox)) -- suit draws backwards, clear stencil first

  makeDroptext(lg.getFont())

  if spriteEditor.isdroppingSpritesheet then
    local s = suit:Shape("droppingSpritesheet", {.1,.1,.1,.7}, {noScaleY = true}, x, label.y+label.h+2*suit.scale, width-5, lg.getHeight())
  end

  suit.layout:reset(x+5, label.y+label.h+10+scrollHeight, 20,5)

  for _, spritesheet in ipairs(spriteEditor.spritesheets) do
    drawSpritesheetUi(spritesheet, width-15)
  end

  suit:Draw(drawStencil, {noScaleY=true}, unpack(spriteEditor.scrollHitbox))  -- suit draws backwards, set stencil last

  local dragBar = suit:Shape("spritesheetTabBGDragBar", {.2,.2,.2}, width-5, y, 5,lg.getHeight())
  suit:Shape("spritesheetTabBG", {.4,.4,.4}, x, y, width-5, lg.getHeight())

  local isPrimaryMousePressed = lm.isDown(1)

  if dragBar.entered and isPrimaryMousePressed and not tabWidthChanging then
    tabNotHeld = true
  end
  if dragBar.hovered and not movingGrid then
    if isCursorSupported and cursor_sizewe then lm.setCursor(cursor_sizewe) end
    if not isPrimaryMousePressed then
      tabNotHeld = false
    elseif not tabNotHeld then -- and isPrimaryMousePressed
      tabWidthChanging = true
    end
  end
  if tabWidthChanging then
    tabWidth = validateTabWidth(lm.getX() / suit.scale)
  end
  if tabWidthChanging and not isPrimaryMousePressed then
    tabWidthChanging = false
    tabWidth = math.floor(tabWidth)
    settings.client.spritesheetTabWidth = tabWidth
    if not dragBar.hovered then
      tabNotHeld = false
      if isCursorSupported then lm.setCursor(nil) end
    end
  end
  if dragBar.left and not tabWidthChanging and not movingGrid then
    tabNotHeld = false
    if isCursorSupported then lm.setCursor(nil) end
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

spriteEditor.drawAboveUI = function()
  if spriteEditor.isdroppingSpritesheet then
    local h = spriteEditor.spritesheetdroppingText.get.height
    local targetY = spriteEditor.isdroppingSpritesheet-h/2
    targetY = math.max(spriteEditor.scrollHitbox[2], math.min(targetY, lg.getHeight()-h))
    spriteEditor.spritesheetdroppingText:draw(0,targetY)
  end
end

spriteEditor.resize = function(_, _)
  scrollHeight = 0
end

require("scene.editor.spriteeditor.dropping")(spriteEditor)

spriteEditor.mousepressed = function(x,y, button)
  if button == 3 and spriteEditor.scrollHitbox and spriteEditor.suit:mouseInRect(unpack(spriteEditor.scrollHitbox)) then
    scrollHeight = 0
  end
  if button == 1 and not spriteEditor.suit:anyHovered() and not tabWidthChanging then
    movingGrid = true
    if cursor_sizeall then
      lm.setCursor(cursor_sizeall)
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
    lm.setCursor(nil)
  end
end

spriteEditor.wheelmoved = function(_, y)
  if not movingGrid and spriteEditor.scrollHitbox and spriteEditor.suit:mouseInRect(unpack(spriteEditor.scrollHitbox)) then
    scrollHeight = scrollHeight + y * settings.client.scrollspeed * spriteEditor.suit.scale
    if scrollHeight > 0 then scrollHeight = 0 end -- TODO: graphics - mask scroll area
  end
end

return spriteEditor 