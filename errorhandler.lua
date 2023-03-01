local logger = require("util.logger")

local function error_printer(message, layer)
  return debug.traceback(tostring(message), 1+(layer or 1)):gsub("\n[^\n]+$", "")
end

love.errorhandler = function(message)
  message = tostring(message)
  logger.fatal(nil, error_printer(message, 2))
  if not love.window or not love.graphics or not love.event then
    return
  end
  if not love.graphics.isCreated() or not love.window.isOpen() then
    local success, status = pcall(love.window.setMode, 800, 600)
    if not success or not status then
    return
    end
  end
  if love.mouse then
    love.mouse.setVisible(true)
    love.mouse.setGrabbed(false)
    love.mouse.setRelativeMode(false)
    if love.mouse.isCursorSupported() then
    love.mouse.setCursor()
    end
  end
  if love.joystick then
    for _, joystick in ipairs(love.joystick.getJoysticks()) do
    joystick:setVibration()
    end
  end
  if love.audio then love.audio.stop() end
  love.graphics.reset()
  local font = love.graphics.setNewFont(14)
  love.graphics.setColor(1,1,1,1)
  local trace = debug.traceback()
  love.graphics.origin()
  local sanitizedMessage = {}
  for char in message:gmatch(utf8.charpattern) do
    table.insert(sanitizedMessage, char)
  end
  sanitizedMessage = table.concat(sanitizedMessage)

  local err = {}
  table.insert(err, "Custom error\n")
  table.insert(err, sanitizedMessage)
  if #sanitizedMessage ~= #message then
    table.insert(err, "Invalid UTF-8 string in error message.")
  end
  table.insert(err, "\n")
  for l in trace:gmatch("(.-)\n") do
    if not l:match("boot.lua") then
    l = l:gsub("stack traceback:", "Traceback\n")
    table.insert(err, l)
    end
  end
  local p = table.concat(err, "\n")
  p = p:gsub("\t", "")
  p = p:gsub("%[string \"(.-\"%]", "%1")
  local function draw()
    local pos = 70
    love.graphics.clear(89/255, 157/255, 220/255)
    love.graphics.printf(p, pos, pos, love.graphics.getWidth() - pos)
    love.graphics.present()
  end
  local fullErrorText = p
  local function copyToClipboard()
    if not love.system then return end
    love.system.setClipboardText(fullErrorText)
    p = p .. "\nCopied to clipboard!"
    draw()
  end
  if love.system then
    p = p .. "\n\nPress Ctrl+C to copy this error"
  end
  return function()
    love.event.pump()
    for e, a, b, c in love.event.poll() do
    if e == "quit" then
        return 1
    elseif e == "keypressed" and a == "escape" then
        return 1
    elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
        copyToClipboard()
    end
    end
    draw()
    if love.timer then
    love.timer.sleep(0.1)
    end
  end
end