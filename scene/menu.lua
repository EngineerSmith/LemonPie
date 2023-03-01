local suit = require("libs.suit").new()
suit.theme = require("ui.theme")

local flux = require("libs.flux")

local settings = require("util.settings")
local logger = require("util.logger")
local assets = require("util.assets")

local lg = love.graphics

local scene = { 
  introPos = { x = -100 },
}

scene.load = function()
  assets["audio.ui.button"] = love.audio.newSource(assets._path["audio.ui.button"], "static")

  scene.tween = flux.to(scene.introPos, 1, { x = 0 })

  scene.resize(lg.getDimensions()) -- init scene.scale
end

scene.resize = function(w, h)
  local wsize = settings._default.client.windowSize
  local tw, th = wsize.width, wsize.height
  local sw, sh = w / tw, h / th
  scene.scale = sw < sh and sw or sh

  suit.scale = scene.scale
  suit.theme.scale = scene.scale

  local fontSize = math.floor(18 * scene.scale)
  local fontName = "font.regular."..fontSize
  if not assets[fontName] then
    assets[fontName] = lg.newFont(assets._path["font.regular"], fontSize)
    assets[fontName]:setFilter("nearest", "nearest")
  end
  lg.setFont(assets[fontName])
  logger.info("Set font size to", fontSize)
end

local buttonFactory = function(id, text, targetX, targetY, targetW, targetH, r, active)
  return {
      id = id, text = text,
      targetX = targetX, targetY = targetY, targetW = targetW, targetH = targetH,
      r = r, active = active
    }
end

local playEnteredSound = function()
  assets["audio.ui.button"]:clone():play()
end

local backButton = buttonFactory("0", "Back", -20, -1.5, 20, 3, 3)

local quitButton = buttonFactory(2, "Exit", -3, -1.5, 40, 3)
local loadButton = buttonFactory(1, "Load", -3, -1.5, 40, 3)
local newButton  = buttonFactory(0, "New" , -3, -1.5, 40, 3)

local state = "main"
local mainTween = { x = 0 }

scene.update = function(dt)
  if state == "main" then
    suit.layout:reset(110, 520, 0, 20)
    suit.layout:translate(scene.introPos.x)
    -- quit button
    if mainTween.target then suit.layout:translate(-mainTween.x) end
    local b = suit:Button(quitButton.text, quitButton, suit.layout:up(140, 30))
    if b.hit then
      love.event.quit()
    elseif b.entered then
      playEnteredSound()
    end
    if mainTween.target then suit.layout:translate(mainTween.x) end
    suit.layout:translate(-20)
    -- load button
    if mainTween.target == "load" then
      suit.layout:translate(mainTween.x)
    else
      suit.layout:translate(-mainTween.x)
    end
    local b = suit:Button(loadButton.text, loadButton, suit.layout:up(140, 30))
    if b.hit then
      mainTween.target = "load"
      flux.to(mainTween, .25, { x = 20 }):oncomplete(function()
          state = "load"
          mainTween.target, mainTween.x = nil, 0
        end)
    elseif b.entered then
        playEnteredSound()
    end
    if mainTween.target == "load" then
      suit.layout:translate(-mainTween.x)
    else
      suit.layout:translate(mainTween.x)
    end
    suit.layout:translate(-20)
    -- new button
    if mainTween.target == "new" then
      suit.layout:translate(mainTween.x)
    else
      suit.layout:translate(-mainTween.x)
    end
    local b = suit:Button(newButton.text, newButton, suit.layout:up(140, 30))
    if b.hit then
      mainTween.target = "new"
      flux.to(mainTween, .25, { x = 20 }):oncomplete(function()
          state = "new"
          mainTween.target, mainTween.x = nil, 0
        end)
    elseif b.entered then
        playEnteredSound()
    end
    if mainTween.target == "new" then
      suit.layout:translate(-mainTween.x)
    else
      suit.layout:translate(mainTween.x)
    end
    suit.layout:translate(-20)
  else
    suit.layout:reset(50, 40, 20, 20)
    local b = suit:Button(backButton.text, backButton, suit.layout:right(140, 30))
    if b.hit then
      state = "main"
    elseif b.entered then
      playEnteredSound()
    end
  end
end

scene.draw = function()
  lg.clear(196/255,174/255,173/255,1)
  suit:draw(1)
end

scene.wheelmoved = function(...)
  suit:updateWheel(...)
end

scene.textedited = function(...)
  suit:textedited(...)
end

scene.textinput = function(...)
  suit:textinput(...)
end

scene.keypressed = function(...)
  suit:keypressed(...)
end

return scene