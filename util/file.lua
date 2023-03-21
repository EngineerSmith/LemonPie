local lfs = love.filesystem
local file = {
    imageExtensions = {
      "png",
      "jpg",
      "jpeg",
      "bmp"
    },
  } 

-- "a/game.zip", "game.zip" "game" -> "zip", zip", nil
file.getFileExtension = function(path)
  local extension = path:match("^.+%.(.+)$")
  return extension and extension:lower() or nil
end
-- "game.json", "foo.png", "a/b/james.character" --> "game", "foo", "james"
file.getFileName = function(path)
    local name = path:gsub("\\", "/"):match("([^/]+)%..+$")
    return name and name:lower() or nil
end
-- "game", "game.zip", "a/game", "a/game.zip", "a/b/game.zip" --> "game"
file.getArchiveName = function(path)
    local name = path:match("%/?([%w_]+)%.?z?i?p?$")
    return name and name:lower() or nil
end

-- "C:\\git\\project", "/git/ImportantProject/project" --> "project"
file.getDirectoryName = function(path)
  local name = path:gsub("\\", "/"):match("([^/]+)$")
  return name and name:lower() or nil
end

file.canBeMounted = function(path)
    local info = lfs.getInfo(path)
    return info and (info.type == "directory" or (info.type == "file" and file.getFileExtension(path) == "zip"))
end

file.iterateDirectory = function(dir, path, callback, seperator)
  seperator = seperator or "/"
  local items = lfs.getDirectoryItems(dir)
  for _, item in ipairs(items) do
    local loc = dir.."/"..item
    local info = lfs.getInfo(loc)
    if info.type == "directory" then
      file.iterateDirectory(loc, (path..item..seperator):lower(), callback)
    elseif info.type == "file" then
      callback(loc, (path..item):lower())
    end
  end
end

file.isImageFile = function(path)
  local extension = file.getFileExtension(path)
  for _, e in ipairs(file.imageExtensions) do
    if e == extension then
      return true, e
    end
  end
  return false
end

return file