local suit = require("libs.suit").new()
suit.theme = require("ui.theme_Editor")

local settings = require("util.settings")
local logger = require("util.logger")
local assets = require("util.assets")

local lg = love.graphics

local scene = {
  spriteEditor = require("scene.editor.spriteeditor"),

  drop = "not dropping",
}

local icons = { }

scene.load = function(project)
  scene.active = scene.spriteEditor
  scene.project = project

  assets["audio.ui.button"] = assets["audio.ui.button"] or love.audio.newSource(assets._path["audio.ui.button"], "static")
  assets["audio.ui.button"]:setVolume(0.2)

  icons["barsHorizontal"] = love.graphics.newImage(assets._path["icon.barsHorizontal"])
  icons["barsHorizontal.inactive"] = love.graphics.newImage(assets._path["icon.barsHorizontal.inactive"])
  
  scene.spriteEditor.load(project, suit)
  scene.resize(lg.getDimensions())
end

scene.unload = function()
  local success, errorMessage = scene.project:close()
  if not success then error(errorMessage) end -- todo: replace with better error
  scene.spriteEditor.unload()

  icons = { }
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

  local fontSize = math.floor(10 * scene.scale)
  local fontName = "font.regular."..fontSize
  if not assets[fontName] then
    assets[fontName] = lg.newFont(assets._path["font.regular"], fontSize)
    assets[fontName]:setFilter("nearest", "nearest")
  end
  suit.subtitleFont = assets[fontName]

  scene.active.resize(w, h)
end

scene.update = function(dt)
  scene.active.update(dt)
end

local bgline = {.5,.5,.5}
local b1txt = "Sprite Editor"
local b2txt = "Coming soon"

scene.updateui = function()
  suit:enterFrame(1)

  local height = 40
  local imgScale = .4
  local b = suit:ImageButton(icons["barsHorizontal.inactive"], { hovered = icons["barsHorizontal"], scale = imgScale }, 0,0)
  
  if b.hit then
    require("util.sceneManager").changeScene("scene.menu", true)
  end

  suit:Shape("NavbarBgLine", bgline, 0, height-3, lg.getWidth(), 3)
  suit.layout:reset(100*imgScale*scene.scale+10, 5, 10)
  local b1 = suit:Button(b1txt, { noScaleX = true, r=5 }, suit.layout:right(lg.getFont():getWidth(b1txt) + 10, 35))
  local b2 = suit:Button(b2txt, { noScaleX = true, disable = true, r=5}, suit.layout:right(lg.getFont():getWidth(b1txt) + 10, 35))
  if b1.hovered or b2.hovered then
    bgline[1],bgline[2],bgline[3] = .6,.6,.6
  else
    bgline[1],bgline[2],bgline[3] = .5,.5,.5
  end
  suit:Shape("NavbarBg", {.3,.3,.3}, 0,0, lg.getWidth(), height)

  scene.active.updateui(0, height)
end

local _x, _y = -40,-40

scene.draw = function()
  lg.origin()
  lg.clear(0,0,0,1)
  scene.active.draw()
  suit:draw()
  if scene.active.drawUAboveUI then
    scene.active.drawUAboveUI()
  end
  lg.setColor(1,0,0,1)
  lg.circle("fill", _x, _y, 20)
  lg.setColor(1,1,1,1)
end

scene.filedropped = function(file)
  scene.active.filedropped(file)
  scene.drop = "dropped"
end

scene.directorydropped = function(directory)
  scene.active.directorydropped(directory)
  scene.drop = "dropped"
end

scene.isdropping = function(x, y)
  scene.active.isdropping(x, y)
  scene.drop = "dropping"
end

scene.stoppeddropping = function()
  scene.active.stoppeddropping()
  scene.drop = "not dropping"
end

scene.wheelmoved = function(...)
  suit:updateWheel(...)
  scene.active.wheelmoved(...)
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

scene.mousepressed = function(...)
  scene.active.mousepressed(...)
end

scene.mousemoved = function(...)
  scene.active.mousemoved(...)
end

scene.mousereleased = function(...)
  scene.active.mousereleased(...)
end

return scene