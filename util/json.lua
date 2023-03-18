local json = require("libs.json")
local nfs = require("libs.nativefs")

return {
  decode = function(filePath, usenfs)
    local lfs = love.filesystem
    if usenfs then lfs = nfs end
    local content = assert(lfs.read(filePath))
    local success, json = pcall(json.decode, content)
    return success, json
  end,
  encode = function(filePath, table, usenfs)
    local lfs = love.filesystem
    local success, json = pcall(json.encode, table)
    if not success then
      return success, json
    end
    if usenfs then lfs = nfs end
    local success, message  = lfs.write(filePath, json)
    return success, message 
  end,
}