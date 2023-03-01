local utf8 = require("libs.utf8"):init()
local defaultUTF8 = require("utf8")

defaultUTF8.sub = function(str,i,j)
  i = i or 1
  j = j or -1
  if i < 1 or j < 1 then
    local n = utf8.len(str)
    if not n then return nil end
    if i < 0 then i = n + 1 + i end
    if j < 0 then j = n + 1 + j end
    if i < 0 then i = 1 elseif i > n then i = n end
    if j < 0 then j = 1 elseif j > n then j = n end
  end
  if j<i then return "" end
  i = utf8.offset(str,i)
  j = utf8.offset(str,j+1)
  if i and j then return str:sub(i,j-1)
  elseif i then return str:sub(i)
  end
  return ""
end

local utf8pos, utf8len = defaultUTF8.offset, defaultUTF8.len
local sub = string.sub
local max, min = math.max, math.min

local posrelat = function(pos, len)
    if pos >= 0 then return pos end
    if -pos > len then return 0 end
    return pos + len + 1
end

defaultUTF8.sub = function(str, i, j) -- by Index five
    local len = utf8len(str)
    i, j = max(posrelat(i, len), 1), j and min(posrelat(j, len), len) or len
    if i <= j  then
        return sub(str, utf8pos(str, i), utf8pos(str, j + 1) - 1)
    end
    return ""
end

defaultUTF8.gsub = utf8.gsub
defaultUTF8.find = utf8.find
defaultUTF8.match = utf8.match
defaultUTF8.gmatch = utf8.gmatch

return utf8