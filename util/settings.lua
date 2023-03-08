local lfs = love.filesystem
local json = require("util.json")
local logger = require("util.logger")
local args = require("util.args")

local settingsFile = "settings.json"
if type(args["-settings"]) == "table" then
  settingsFile = args["-settings"][1]
end

local defaultSettings = {
  client = {
    windowSize = {
      width = 800,
      height = 600,
    },
    windowFullscreen = false,
    dyslexic = true,
    scrollspeed = 20,
  },
}
local b = require("string.buffer")
local defaultCopy = b.decode(b.encode(defaultSettings)) -- lazy man's deep copy
b = nil

local formatTable
formatTable = function(dirtyTable, cleanTable)
  for k,v in pairs(cleanTable) do
    local vType = type(v)
    if type(dirtyTable[k]) ~= vType then
        dirtyTable[k] = v
    else
      if vType == "table" then
        dirtyTable[k] = formatTable(dirtyTable[k],v)
      elseif vType == "number" then
        if dirtyTable[k] < 0 then
          dirtyTable[k] = v
        end
      end
    end
  end
  return dirtyTable
end

local settings = defaultCopy

if lfs.getInfo(settingsFile, "file") then
  local success, decodedSettings = json.decode(settingsFile)
  if success then
    settings = formatTable(decodedSettings, defaultSettings)
  end
end

local encode = function()
  local success, message = json.encode(settingsFile, settings)
  if not success then
    logger.error("Could not update", settingsFile, ":", message)
  end
end

encode()

local handlers = {}
local out = {
    client = {},
    _default = defaultSettings,
    addHandler = function(key, func)
      local h = handlers[key] or {}
      handlers[key] = h
      table.insert(h, func)
    end,
  }
setmetatable(out.client, {
    __index = function(_, key)
        return settings.client[key]
      end,
    __newindex = function(_, key, value)
        settings.client[key] = value
        encode()
        if handlers[key] then
          for _, func in ipairs(handlers[key]) do
            func()
          end
        end
      end,
  })

return out