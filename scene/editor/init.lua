local suit = require("libs.suit").new()
suit.theme = require("ui.theme_Editor")

local flux = require("libs.flux")

local settings = require("util.settings")
local logger = require("util.logger")
local assets = require("util.assets")

local undo = require("src.undo")

local lg = love.graphics

local scene = {
  spriteEditor = require("scene.editor.spriteeditor"),

  drop = "not dropping",
}

local loadImageAssets = function(assetID)
  assets[assetID] = assets[assetID] or lg.newImage(assets._path[assetID])
end

scene.load = function(project, projecterrors, start)
  scene.active = scene.spriteEditor
  scene.project = project

  assets["audio.ui.button"] = assets["audio.ui.button"] or love.audio.newSource(assets._path["audio.ui.button"], "static")
  assets["audio.ui.button"]:setVolume(0.2)

  loadImageAssets("icon.barsHorizontal")
  loadImageAssets("icon.barsHorizontal.inactive")
  loadImageAssets("icon.save")
  loadImageAssets("icon.undo")
  loadImageAssets("icon.trashcan")
  loadImageAssets("icon.trashcan.open")
  loadImageAssets("icon.up")
  loadImageAssets("icon.down")
  loadImageAssets("icon.left")
  loadImageAssets("icon.right")
  loadImageAssets("icon.updown")
  loadImageAssets("icon.updown.up")
  loadImageAssets("icon.updown.down")
  
  scene.spriteEditor.load(project, suit)
  scene.resize(lg.getDimensions())
  local stop = love.timer.getTime()
  
  logger.info(("Took %.4f seconds to load project"):format(stop-start))

  undo.reset()
end

scene.unload = function()
  local success, errorMessage = scene.project:close()
  if not success then error(errorMessage) end -- todo: replace with better error
  scene.spriteEditor.unload()
end

local buttonlist = {
  "Save & Close", "Don't Save", "Cancel", escapebutton = 3, enterbutton = 1,
}

scene.quit = function()
  if scene.project.dirty then
    local pressedbutton = love.window.showMessageBox("Unsaved work, are you sure you want to quit?", "Are you aure you want to quit without saving?", buttonlist)
    if pressedbutton == 1 then
      scene.project:saveProject()
    elseif pressedbutton == 3 then
      return true
    end
  end
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

  local fontSize = math.floor(12 * scene.scale)
  local fontName = "font.regular."..fontSize
  if not assets[fontName] then
    assets[fontName] = lg.newFont(assets._path["font.regular"], fontSize)
    assets[fontName]:setFilter("nearest", "nearest")
  end
  suit.subtitleFont = assets[fontName]

  scene.active.resize(w, h)
end

scene.topLeftIcon = "icon.barsHorizontal"
local timerIcon, timerTime, iconY = 0, 1, {0}

scene.update = function(dt)
  scene.active.update(dt)
  if scene.topLeftIcon ~= "icon.barsHorizontal" then
    timerIcon = timerIcon + dt
    if timerIcon > timerTime then
      scene.topLeftIcon = "icon.barsHorizontal"
      timerIcon, timerTime = 0, 1
      iconY[1] = 0
    end
  else
    iconY[1] = 0
  end
end

local bgline = {.5,.5,.5}
local b1txt = "Sprite Editor"
local b2txt = "Coming soon"

scene.updateui = function()
  suit:enterFrame(1)

  local height = 40
  local imgScale = .4

  local b = suit:ImageButton(assets[scene.topLeftIcon], { hovered = assets["icon.barsHorizontal.inactive"], scale = imgScale }, 0,iconY[1])
  
  if b.hit then
    if not scene.quit() then -- lazy hack, should change
      require("util.sceneManager").changeScene("scene.menu", true)
    end
  end

  suit:Shape("NavbarBgLine", bgline, 0, height-3, lg.getWidth(), 3)
  suit.layout:reset(100*imgScale*scene.scale+10, 5, 10)
  local b1 = suit:Button(b1txt, { noScaleX = true, r=5 }, suit.layout:right(lg.getFont():getWidth(b1txt) + 10, 35))
  if b1.hit then scene.active = scene.spriteEditor end
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
  if scene.active.drawAboveUI then
    scene.active.drawAboveUI()
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

scene.keypressed = function(key, scancode, isrepeat)
  suit:keypressed(key, scancode, isrepeat)
  if love.keyboard.isScancodeDown("rctrl", "lctrl") then
    if scancode == "s" then
      if scene.project:saveProject() then
        scene.topLeftIcon = "icon.save"
        flux.to(iconY, .3, {-4}):ease("backout"):after(iconY, .3, {-1}):ease("backout")
        timerTime = 1
      end
    elseif scancode == "z" then
      undo.pop()
      timerTime = .3
      scene.topLeftIcon = "icon.undo"
      scene.project.dirty = true
    end
  end
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