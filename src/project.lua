local project = { }
project.__index = project

local json = require("util.json")
local file = require("util.file")
local logger = require("util.logger")

local nfs = require("libs.nativefs")

local lfs = love.filesystem

local projectsFile = "projects.json"
local projectFile = "/project.lemonpie"

-- generic funcs

project.new = function(path)
  if not nfs.getInfo(path, "directory") then
    return nil, "Could not find the directory at "..tostring(path)
  end
  
  project.addProject(path)

  return project
end

project.getActiveProjects = function()
  if lfs.getInfo(projectsFile, "file") then
    local success, projects = json.decode(projectsFile)
    return projects
  end
end

project.addProject = function(path)
  local projects = project.getActiveProjects() or {}
  local found = false
  for i, project in ipairs(projects) do
    if project.path == path then
      project.time = os.time()
      table.remove(projects, i)
      table.insert(projects, 1, project)
      found = true
    end
  end
  if not found then
    table.insert(projects, 1, {path = path, time = os.time()})
  end
  json.encode(projectsFile, projects)
end

project.loadProject = function(path)
  -- new Project
  if not nfs.getInfo(path..projectFile, "file") then
    logger.info("New project: creating new project profile")
    love.window.setTitle("LemonPie - "..path)
    return setmetatable({
        path = path,
        spritesheets = { },
        dirty = false,
      }, project)
  else -- existing Project
    logger.info("Pre-existing project: attempting to open project profile")
    local success, self = json.decode(path..projectFile, true)
    if not success then 
      return nil, "A problem appeared trying to load the project metadata.\n"..tostring(self)
    end
    logger.info("Opened project profile")
    love.window.setTitle("LemonPie - "..(self.name or self.path))
    self.spritesheets = self.spritesheets or { }
    self.dirty = false
    return setmetatable(self, project)
  end
end

-- self funcs

project.close = function(self)
  love.window.setTitle("LemonPie")
  return true
end

project.saveProject = function(self)
  if self.dirty then
    self.dirty = nil
    local success, errorMessage = json.encode(self.path..projectFile, self, true)
    if not success then
      self.dirty = true
      return errorMessage
    end
    project.addProject(self.path)
    self.dirty = false
    return true
  end
end

project.addSpritesheet = function(self, path, sprites, name, index)
  local i, j = path:find(self.path, 1, true)
  if i ~= 1 then
    return "notinproject"
  end
  path = path:sub(j+1):gsub("\\", "/")
  for _, spritesheet in ipairs(self.spritesheets) do
    if spritesheet.path == path then
      return "alreadyadded"
    end
  end
  logger.info("Added new spritesheet", path, (index and "at"..tostring(index) or ""))
  local spritesheet = {
    path = path,
    name = name or file.getFileName(path),
  }
  if index then
    table.insert(self.spritesheets, index, spritesheet)
  else
    table.insert(self.spritesheets, spritesheet)
  end
  self.dirty = true
  return nil, path
end

project.removeSpritesheet = function(self, index)
  if index < 1 or index > #self.spritesheets then
    return "invalidindex"
  end
  table.remove(self.spritesheets, index)
  self.dirty = true
end

return project