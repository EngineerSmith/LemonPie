local suit = require("libs.suit").new()
suit.theme = require("ui.theme_Menu")

local flux = require("libs.flux")
local sysl = require("libs.SYSL-Text")

local project = require("src.project")

local settings = require("util.settings")
local logger = require("util.logger")
local assets = require("util.assets")
local file = require("util.file")

local lg = love.graphics

local scene = { }

local getFont = function(size, name)
  local fontSize = math.floor(size * (scene.scale or 1))
  local fontName = name.."."..fontSize
  if not assets[fontName] then
    assets[fontName] = lg.newFont(assets._path[name], fontSize)
    assets[fontName]:setFilter("nearest", "nearest")
  end
  return assets[fontName], fontSize
end

getFont(18, "font.regular") -- always load font 18

local logoScale = .2

local backgroundColor = { .06, .47, .47 }
local backgroundColors, backgroundColorIndex = {
  { .12, .53, .53 },
  { .32, .53, .20 },
  { .50, .20, .30 },
}, 1

local startBackgroundTween
startBackgroundTween = function()
  flux.to(backgroundColor, 3, backgroundColors[backgroundColorIndex]):oncomplete(startBackgroundTween)
  backgroundColorIndex = backgroundColorIndex + 1
  if backgroundColorIndex > #backgroundColors then backgroundColorIndex = 1 end
end

local syslSubText =  {
  color = {.9,.9,.9,1},
  shadow_color = {.2,.2,.2},
  print_speed = 0,
}

local createDropText = function(effects, showAll)
  scene.droptext = sysl.new("center", syslSubText)
  if effects then
    scene.droptext:send("[shake][dropshadow=10]Drop a directory to get started![/shake]", nil, showAll)
  else
    scene.droptext.bounce_height = 1
    scene.droptext:send("[bounce=8][dropshadow=10] Drop a directory to get started![/bounce]", nil, showAll)
  end
end

local lastErrorMessage

scene.errortext = sysl.new("center", {
  color = {.9,.5,.5,1},
  shadow_color = {.50,.23,.23,},
})
scene.errortext:send("[dropshadow=10]An error has occurred! Click to close.", nil, true)

local showError = function(errorMessage, font)
  font = font or lg.getFont()

  scene.errormessagetext = sysl.new("left", {
      color = {1,1,1,1},
      font = font,
    })
  scene.errormessagetext:send(errorMessage, 560*scene.scale, true)
  lastErrorMessage = errorMessage
end

local closeError = function()
  scene.errormessagetext = nil
end

scene.load = function(returned)
  returned = returned and 30 or 0
  scene.introPos = { x = project.getActiveProjects() and -420 - returned or -195 - returned }
  scene.tween = nil

  assets["audio.ui.button"] = assets["audio.ui.button"] or love.audio.newSource(assets._path["audio.ui.button"], "static")
  assets["audio.ui.button"]:setVolume(0.2)
  
  assets["image.logo"] = lg.newImage(assets._path["image.logo"])
  assets["icon.import"] = lg.newImage(assets._path["icon.import"])
  
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
  
  scene.subtext = sysl.new("center", syslSubText)
  scene.subtext:send("[dropshadow=10]A 2D skeleton animator for LÖVE[/dropshadow]")
  
  createDropText(false, false)
  
  -- start tweens
  startBackgroundTween()
  
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

  local font, fontSize = getFont(18, "font.regular")
  lg.setFont(font)
  logger.info("Set font size to", fontSize) 

  scene.subtext.default_font = font
  scene.droptext.default_font = font
  scene.errortext.default_font = font
  if scene.errormessagetext then
    showError(lastErrorMessage, font)
  end

  local font = getFont(42, "font.bold")
  scene.title.default_font = font

  local numberofLemonImages = #assets["image.lemons"]

  scene.lemons = { }
  for _ = 1, math.floor(75 * scene.scale) do
    table.insert(scene.lemons, {
        image = assets["image.lemons"][love.math.random(numberofLemonImages)],
        x = love.math.random(-100, settings._default.client.windowSize.width * sw + 100),
        y = love.math.random(-100, settings._default.client.windowSize.height * sh + 100),
        speedManipulator = love.math.random(5, 8),
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


local quitButton = buttonFactory(2, "Exit", -3, -1.5, 40, 3)
local previousProjectButton = buttonFactory(1, "Open Previous Project", -3, -1.5, 40, 3)

local state = "main"
local lemonSpeedX, lemonSpeedY = 10, 30

scene.update = function(dt)
  love.keyboard.setTextInput(true)
  scene.title:update(dt)
  if scene.title:is_finished() then
    scene.subtext:update(dt)
    if not scene.tween then
      scene.tween = flux.to(scene.introPos, 1, { x = 0 }):ease("backout")
    end
    if scene.subtext:is_finished() then
      scene.droptext:update(dt)
    end
  end
  if state == "dropping" then
    scene.droptext:update(dt)
  end
  if scene.errormessagetext then
    scene.errortext:update(dt)
    scene.errormessagetext:update(dt)
  end

  local width, height = lg.getDimensions()
  width, height = width * scene.scale, height * scene.scale
  local scale = scene.scale * .3

  for _, lemon in ipairs(scene.lemons) do
    lemon.x = lemon.x + lemon.speedManipulator * dt
    lemon.y = lemon.y + lemon.speedManipulator * dt

    local lemonWidth, lemonHeight = lemon.image:getDimensions()
    lemonWidth = lemonWidth * scale
    lemonHeight = lemonHeight * scale

    local x = (lemon.x * scene.scale) + lemonWidth/2
    local y = (lemon.y * scene.scale) + lemonHeight/2

    if x >= width + lemonWidth then
      lemon.x = love.math.random(-lemonWidth*2,-lemonWidth*1.5)
      lemon.y = lemon.y + love.math.random(-lemonHeight, 0)
    end
    if y >= height + lemonHeight then
      lemon.y = love.math.random(-lemonHeight*2,-lemonHeight*1.5)
      lemon.x = lemon.x + love.math.random(-lemonWidth, 0)
    end
  end
end

scene.updateui = function()
  suit:enterFrame(1)
  suit.layout:reset(50, 520, 50, 20)
  suit.layout:translate(scene.introPos.x)
  -- Previous Project
  local projects = project.getActiveProjects()
  if projects then
    local b = suit:Button(previousProjectButton.text, previousProjectButton, suit.layout:up(365, 30))
    if b.entered then
      playEnteredSound()
    elseif b.hovered then
      local text = projects[1].name or projects[1].path
      local font = assets["font.regular.18"]
      local w = math.min(font:getWidth(text)+20, 300*math.ceil(suit.scale))
      local _, wrappedtext = font:getWrap(text, w)
      local h = (30 * #wrappedtext + font:getLineHeight() * (#wrappedtext + 1))
      local x, y, w, _ = suit.layout:right(w, 30)
      if y + h > settings._default.client.windowSize.height then
        h = h + 10
        y = settings._default.client.windowSize.height - h - 5
      else
        h = h * scene.scale
      end
      suit:Label(text, {valign = "top"}, x, y, w, h)
      suit.layout:left(365, 30)
    end
    if b.hit then
      scene.directorydropped(projects[1].path)
    end
  end
  -- quit button
  local b = suit:Button(quitButton.text, quitButton, suit.layout:up(140, 30))
  if b.hit then
    love.event.quit()
  elseif b.entered then
    playEnteredSound()
  end
end

local dropX, dropY

scene.draw = function()
  lg.push("all")
  lg.clear(backgroundColor)

  local scale = scene.scale*.3
  for _, lemon in ipairs(scene.lemons) do
    local lemonWidth, lemonHeight = lemon.image:getDimensions()
    lemonWidth = lemonWidth * scale
    lemonHeight = lemonHeight * scale
    local x = (lemon.x * scene.scale) + lemonWidth/2
    local y = (lemon.y * scene.scale) + lemonHeight/2
    lg.draw(lemon.image, x, y, 0, scale)
  end

  local x, y = lg.getDimensions()
  x, y = x/2, y/2
  y = y - 50
  local s = logoScale * scene.scale
  local iw, ih = assets["image.logo"]:getDimensions()
  iw, ih = iw*s, ih*s
  lg.draw(assets["image.logo"], x - iw/2, y - ih, 0, s)

  lg.push("all")
  scene.title:draw(x - iw/1.6, y-20*scene.scale)
  if scene.title:is_finished() then
    scene.subtext:draw(x - iw/1.2, y+60*scene.scale)
    if state ~= "dropping" and scene.title:is_finished() then
      scene.droptext:draw(x - iw/1.18, y+120*scene.scale)
    end
  end

  if scene.errormessagetext then
    lg.push("all")
    lg.setColor(.3,.3,.3,.8)
    y = y + 50

    lg.rectangle("fill", x-300*scene.scale, y-200*scene.scale, 600*scene.scale,400*scene.scale)
    scene.errortext:draw(x - iw/1.05, y-170*scene.scale)

    lg.setColor(0,0,0,.5)

    local height = scene.errormessagetext.get.height
    local posYScale = height > 310 and 3 or -20 -- make it a li'l comfy
    local lx, ly = x-280*scene.scale, y-(140+posYScale)*scene.scale
    lg.rectangle("fill", lx-5, ly, scene.errormessagetext.get.width+10, height)
    scene.errormessagetext:draw(lx, ly)

    y = y - 50
    lg.pop()
  end
  
  lg.push("all")
  lg.setColor(1,1,1)
  suit:draw(1)
  lg.pop()

  lg.setColor(0,0,0,1-(state == "main" and 1 or .3))
  lg.rectangle("fill", 0,0, lg:getDimensions())
  lg.pop()
  
  if state == "dropping" then
    scene.droptext:draw(x - iw/1.18, y+120*scene.scale)
    local iw, ih = assets["icon.import"]:getDimensions()
    lg.draw(assets["icon.import"], dropX-iw/4, dropY-ih/4, 0, 2/4)
  end
  
  lg.pop()
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

scene.mousepressed = function(_,_, button)
  if button == 1 then
    closeError()
  end
end

local _directorydroppedError = function(path, errorMessage)
  logger.error("Failed to open project at", path, ", because: ", errorMessage)
  showError(errorMessage)
end

scene.directorydropped = function(path)
  logger.info("Attempting to open project at", path)
  local project, errorMessage = project.new(path)
  if not project then
    _directorydroppedError()
    return
  end

  do -- Basic loading screen if spritesheets are large
    lg.push("all")
    lg.clear(0,0,0,1)
    lg.setColor(1,1,1,1)
    local font = lg.getFont()
    local width, height = font:getWidth("Loading Project..."), font:getHeight()
    lg.print("Loading Project...", lg.getWidth()/2-width/2, lg.getHeight()/1.2-height/2)
    lg.present()
    lg.pop()
  end

  logger.info("Project data load, start loading project")

  local start = love.timer.getTime()
  local project, errorMessage = project.loadProject(path)

  if not project then
    _directorydroppedError()
    return
  end

  scene.stoppeddropping() -- ensure stopped is called
  love.window.focus()
  require("util.sceneManager").changeScene("scene.editor", project, errorMessage, start)
end

local isDropping = false
scene.isdropping = function(x, y)
  dropX, dropY = x, y

  if not isDropping then
    state = "dropping"
    createDropText(true, true)
    isDropping = true
    closeError()
  end
end

scene.stoppeddropping = function()
  state = "main"
  isDropping = false
  createDropText(false, true)
end

return scene