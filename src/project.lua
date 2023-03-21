local project = { }
project.__index = project

local json = require("util.json")
local file = require("util.file")
local logger = require("util.logger")

local nfs = require("libs.nativefs")

local lfs = love.filesystem

local prevPath = nil

local projectsFile = "projects.json"
local projectFile = "/project.lemonpie"

-- generic funcs

project.new = function(path)
  if not nfs.getInfo(path, "directory") then
    return nil, "Could not find the path at "..tostring(path)
  end
  if prevPath then
    project.addProject(prevPath)
  end

  prevPath = path
  project.addProject(path)

  return project.loadProject(path)
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
      }, project)
  else -- existing Project
    logger.info("Pre-existing project: attempting to open project profile")
    local success, self = json.decode(path..projectFile, true)
    if not success then 
      return nil, "A problem appeared trying to load the project metadata.\n"..tostring(self)
    end
    logger.info("Opened profile profile")
    love.window.setTitle("LemonPie - "..(self.name or self.path))
    self.spritesheets = self.spritesheets or { }
    return setmetatable(self, project)
  end
end

-- self funcs

project.close = function(self)
  local errorMessage = self:saveProject()
  if errorMessage then
    return false, errorMessage
  end
  project.addProject(prevPath)
  prevPath = nil
  love.window.setTitle("LemonPie")
  return true
end

project.saveProject = function(self)
  local success, errorMessage = json.encode(self.path..projectFile, self, true)
  if not success then
    return errorMessage
  end
end

project.addSpritesheet = function(self, path)
  local i, j = path:find(self.path, 1, true)
  if i == 1 then
    path = path:sub(j+1):gsub("\\", "/")
    for _, spritesheet in ipairs(self.spritesheets) do
      if spritesheet.path == path then
        return "alreadyadded"
      end
    end
    logger.info("Added spritesheet at", path)
    table.insert(self.spritesheets, {
        path = path,
      })
  else
    return "notinproject"
  end
end

return project