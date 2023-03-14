local suit = require("libs.suit").new()
suit.theme = require("ui.theme_Menu")

local flux = require("libs.flux")
local sysl = require("libs.SYSL-Text")

local settings = require("util.settings")
local logger = require("util.logger")
local assets = require("util.assets")

local lg = love.graphics

local fontName = "font.regular."..18 -- always load font 18
if not assets[fontName] then
  assets[fontName] = lg.newFont(assets._path["font.regular"], 18)
  assets[fontName]:setFilter("nearest", "nearest")
end


local scene = { 
  introPos = { x = -100 },
}

scene.load = function()
  assets["audio.ui.button"] = assets["audio.ui.button"] or love.audio.newSource(assets._path["audio.ui.button"], "static")
  assets["audio.ui.button"]:setVolume(0.2)

  assets["image.logo"] = lg.newImage(assets._path["image.logo"])

  assets["image.lemons"] = { }
  local items = love.filesystem.getDirectoryItems(assets._path["image.lemons"])
  
  for _, file in ipairs(items) do
    file = assets._path["image.lemons"] .. file
    if love.filesystem.getInfo(file, "file") then
      table.insert(assets["image.lemons"], lg.newImage(file))
    end
  end
  
  scene.title = sysl.new("center", {
      color = {1,1,1,1},
      shadow_color = {1,1,1,1},
      print_speed = .075,
    })
  scene.title.effect_speed.rainbow_speed_default = 3
  scene.title:send("[dropshadow=10][rainbow]Lemon Pie[/rainbow][/dropshadow]")

  scene.subtext = sysl.new("center", {
      color = {.8,.8,.8,1},
      shadow_color = {.2,.2,.2,1},
      print_speed = 0,
    })
  scene.subtext:send("[dropshadow=10]A 2D skeleton animator for Love[/dropshadow]")

  scene.tween = flux.to(scene.introPos, 1, { x = 0 })

  scene.resize(lg.getDimensions()) -- init values, scale + lemon positions, fonts,
end

scene.unload = function()
  assets["image.logo"] = nil
  assets["image.lemons"] = nil
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
  scene.subtext.default_font = assets[fontName]
  logger.info("Set font size to", fontSize)

  local fontSize = math.floor(42 * scene.scale)
  local fontName = "font.bold."..fontSize
  if not assets[fontName] then
    assets[fontName] = lg.newFont(assets._path["font.bold"], fontSize)
    assets[fontName]:setFilter("nearest", "nearest")
  end
  scene.title.default_font = assets[fontName]

  local numberofLemonImages = #assets["image.lemons"]

  scene.lemons = { }
  for _ = 1, math.floor(50 * scene.scale) do
    table.insert(scene.lemons, {
        image = assets["image.lemons"][love.math.random(numberofLemonImages)],
        x = math.random(-400, settings._default.client.windowSize.width * sw + 200),
        y = math.random(-400, settings._default.client.windowSize.height * sh + 200),
      })
  end
  logger.info("Created", #scene.lemons, "number of background lemons")
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
local lemonSpeedX, lemonSpeedY = 10, 30

scene.update = function(dt)
  scene.title:update(dt)
  if scene.title:is_finished() then
    scene.subtext:update(dt)
  end

  local width, height = lg.getDimensions()
  local dw, dh = settings._default.client.windowSize.width, settings._default.client.windowSize.height
  for _, lemon in ipairs(scene.lemons) do
    lemon.x = lemon.x + lemonSpeedX * dt
    lemon.y = lemon.y + lemonSpeedY * dt

    local x = (lemon.x * scene.scale/1.5) + lemon.image:getWidth()/2
    local y = (lemon.y * scene.scale/1.5) + lemon.image:getHeight()/2

    if x >= width + 200 then
      lemon.x = love.math.random(-400,-200)
      lemon.y = lemon.y + love.math.random(-100, 100)
    end
    if y >= height + 200 then
      lemon.y = love.math.random(-400,-200)
      lemon.x = lemon.x + love.math.random(-100, 100)
    end
  end
end

scene.updateui = function()
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
          --state = "new"
          mainTween.target, mainTween.x = nil, 0
          logger.info("Switching to editor")
          require("util.sceneManager").changeScene("scene.editor")
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

local logoScale = .2
scene.draw = function()
  local c = state ~= "main" and .7 or 1
  lg.setColor(c,c,c)
  lg.clear(102/255*c,152/255*c,153/255*c, 1)
  lg.push("all")
  for _, lemon in ipairs(scene.lemons) do
    local x = (lemon.x * scene.scale/1.5) + lemon.image:getWidth()/2
    local y = (lemon.y * scene.scale/1.5) + lemon.image:getHeight()/2
    lg.draw(lemon.image, x, y, 0, scene.scale/1.5)
  end
  lg.pop()

  if state == "main" then
    local x, y = lg.getDimensions()
    local iw, ih = assets["image.logo"]:getDimensions()
    local s = logoScale * scene.scale
    lg.draw(assets["image.logo"], x/2 - (iw*s)/2, y/2 - (ih*s), 0, s)

    lg.push("all")
    scene.title:draw(x/2 - (iw*s)/1.6, y/2)
    if scene.title:is_finished() then
      scene.subtext:draw(x/2 - (iw*s)/1.2, y/2+60*scene.scale)
    end
    lg.pop()
  end

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