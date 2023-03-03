require("errorhandler")

local args = require("util.args")
local logger = require("util.logger")

if args["quit"] then -- triggered quit in conf
  return function ()
    return -1
  end
end

local sceneManager = require("util.sceneManager")
local utf8 = require("util.utf8")
local flux = require("libs.flux")

local le = love.event
local processEvents = function()
  le.pump()
  for name, a,b,c,d,e,f,g,h,i,j,k in le.poll() do
    if name == "quit" then
      if not love.quit or not love.quit() then
        logger.info("Quiting with", a or 0)
        return a or 0
      end
    end
    love.handlers[name](a,b,c,d,e,f,g,h,i,j,k)
  end
end

local min, max = math.min, math.max
local clamp = function(target, minimum, maximum)
  return min(max(target, minimum), maximum)
end

local lt, lg = love.timer, love.graphics

-- https://gist.github.com/1bardesign/3ed0fabfdcd2661d3308b4da7fa3076d
local manualGC = function(timeBudget, safetyNetMB)
  local limit, steps = 1000, 0
  local start = lt.getTime()
  while lt.getTime() - start < timeBudget and steps < limit do
    collectgarbage("step", 1)
    steps = steps + 1
  end
  if collectgarbage("count") / 1024 > safetyNetMB then
    collectgarbage("collect")
  end
end

love.run = function()
  logger.info("Loading menu code")
  sceneManager.changeScene("scene.menu")
  logger.info("Creating gameloop")
  local frameTime, fuzzyTime = 1/60, {1/2,1,2}
  local updateDelta = 0
  lt.step()
  return function()
    local quit = processEvents()
    if quit then 
      return quit
    end
    
    local dt = lt.step()
    -- fuzzy timing snapping
    for _, v in ipairs(fuzzyTime) do
      v = frameTime * v
      if math.abs(dt - v) < 0.002 then
        dt = v
      end
    end
    -- dt clamping
    dt = clamp(dt, 0, 2*frameTime)
    updateDelta = updateDelta + dt
    -- frameTimer clamping
    updateDelta = clamp(updateDelta, 0, 8*frameTime)
    
    local ticked = false
    while updateDelta > frameTime do
      updateDelta = updateDelta - frameTime
      flux.update(frameTime)
      love.update(frameTime)
      ticked = true
    end
    
    if ticked then
      love.drawui()
      love.draw()
      lg.present()
    end
    -- Clean up garbage
    manualGC(1e-3, 128)
    -- CPU break to avoid using up the entire processor
    lt.sleep(1e-3)
  end
end