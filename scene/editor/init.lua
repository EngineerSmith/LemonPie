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

scene.load = function(project)
  scene.active = scene.spriteEditor
  scene.project = project

  scene.spriteEditor.load(project, suit)

  scene.resize(lg.getDimensions())
end

scene.unload = function()
  scene.spriteEditor.unload()
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

scene.update = function(dt)
  scene.active.update(dt)
end

scene.updateui = function()
  scene.active.updateui(0, 40)
end

local _x, _y = -40,-40

scene.draw = function()
  lg.origin()
  lg.clear(0,0,0,1)
  scene.active.draw()
  lg.print(tostring(scene.drop))
  lg.setColor(1,0,0,1)
  lg.circle("fill", _x, _y, 20)
  lg.setColor(1,1,1,1)
  suit:draw(1)
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