local suit = require("libs.suit").new()
suit.theme = require("ui.theme")

local settings = require("util.settings")
local logger = require("util.logger")
local assets = require("util.assets")

local lg = love.graphics

local scene = { }

scene.load = function()
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

return scene