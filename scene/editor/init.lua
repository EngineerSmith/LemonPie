local suit = require("libs.suit").new()
suit.theme = require("ui.theme")

local settings = require("util.settings")
local logger = require("util.logger")
local assets = require("util.assets")

local lg = love.graphics

local scene = { 
  spriteEditor = require("scene.editor.spriteeditor"),

  active = nil,
}

scene.load = function(project)
  scene.spriteEditor.load(project)

  scene.active = scene.spriteEditor
end

scene.unload = function()
  scene.spriteEditor.unload()
end

scene.update = function(dt)
  scene.active:update(dt)
end

scene.updateui = function()
  scene.active:updateui()
end

scene.draw = function()
  lg.clear(0,0,0,1)
  scene.active:draw()
end

scene.filedropped = function(file)
  scene.active:filedropped(file)
end

return scene