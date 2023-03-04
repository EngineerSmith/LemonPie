local suit = require("libs.suit").new()
suit.theme = require("ui.theme")

local settings = require("util.settings")
local logger = require("util.logger")
local assets = require("util.assets")

local lg = love.graphics

local scene = { 
  spriteEditor = require("scene.editor.spriteeditor"),

  active = nil,

  drop = false
}

scene.load = function(project)
  scene.spriteEditor.load(project, suit)

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
  lg.print(tostring(scene.drop))
end

scene.filedropped = function(file)
  scene.active:filedropped(file)
  scene.drop = "dropped"
end

scene.dropbegan = function()
  scene.drop = true
end

scene.dropcompleted = function()
  scene.drop = false
end

return scene