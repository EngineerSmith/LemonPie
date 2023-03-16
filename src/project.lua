local project = { }
project.__index = project

local json = require("util.json")
local nfs = require("libs.nativefs")

local lfs = love.filesystem

local prevPath = nil

project.new = function(path)
  if prevPath then
    lfs.unmount("project")
    project.addProject(prevPath)
  end

  if not lfs.mount(path, "project") then
    return nil, "Given path ("..tostring(path)..") could not be mounted"
  end
  prevPath = path
  
  project.addProject(path)

  return project.loadProject()
end

local projectsFile = "projects.json"

project.getActiveProjects = function()
  if lfs.getInfo(projectsFile, "file") then
    return json.decode(projectsFile)
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

project.loadProject = function()
  -- new Project
  if not lfs.getInfo("project/project.lemonpie", "file") then
    
  else -- existing Project

  end
  return true
end


return project