local json = require("libs.json")
local lfs = love.filesystem

return {
  decode = function(filePath)
    local content = assert(lfs.read(filePath))
    local success, json = pcall(json.decode, content)
    return success, json
  end,
  encode = function(filePath, table)
    local success, json = pcall(json.encode, table)
    if not success then
      return success, json
    end
    local success, message  = lfs.write(filePath, json)
    return success, message 
  end,
}