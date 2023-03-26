local logger = require("util.logger")
local fileUtil = require("util.file")

local nfs = require("libs.nativefs")

return function(spriteEditor)

spriteEditor.directorydropped = function(directory)
  
end

local buttonlist = {
  "No", "Yes", escapebutton = 1, enterbutton = 2,
}
spriteEditor.filedropped = function(file)
  local x,y,w,h = unpack(spriteEditor.scrollHitbox)
  if spriteEditor.suit:mouseInRect(x,y,w,h, love.mouse.getPosition()) then
    local filepath = file:getFilename()
    local success, extension = fileUtil.isImageFile(filepath)
    if success then
      ::loopback::
      local result, shortpath = spriteEditor.project:addSpritesheet(filepath)
      if result then
        logger.warn("file dropped could not be added:", result)
        if result == "notinproject" then
          local filename = fileUtil.getFileName(filepath).."."..extension
          local slash = spriteEditor.project.path:find("\\", 1, true) and "\\" or "/"
          local newPath = spriteEditor.project.path..slash..filename
          local isFileAlready = nfs.getInfo(newPath, "file")
          love.window.focus()
          local pressedbutton = love.window.showMessageBox("Dropped image is not in your project!",
            "The dropped image ("..tostring(filepath)..") is not within the project directory.\n\nWould you like to copy it into your project?\n"..
              (isFileAlready and "\n  There is already a file with this name at this location, so it will be overwritten!\n" or "").."\t"..newPath,
            buttonlist, "warning", true)
          if buttonlist[pressedbutton] == "Yes" then
            logger.info("Image being copied into project directory")
            local newfile = nfs.newFile(newPath)
            newfile:open("w")
            local success, message = newfile:write(file:read("data"))
            file:close()
            newfile:close()
            file, newfile = newfile, nil
            if success then
              logger.info("Successfully copied image into project directory!")

              local success, message = file:open("r")
              if not success then
                logger.error("Could not open file again in read mode after closing it in write. Realistically it should never hit this point; so tell someone:", message)
                love.window.focus()
                love.window.showMessageBox("Error...",
                  "You shouldn't see this message box ever; but if you do something has gone wrong trying to open the copied file after it successfully copied.\n\nTell a programmer, or try dropping the newly copied file in.\n\n"..tostring(message),
                  "error", true)
                return
              end

              filepath = newPath
              goto loopback -- I'm lazy today; goto are fine, so go cry to someone else future me
            else
              logger.error("Could not copy file into project directory:", message)
              love.window.focus()
              love.window.showMessageBox("Could not copy", "An error occured when trying to copy image into project directory:\n\n"..tostring(message), "error", true)
              return
            end
          else
            logger.info("(user choice) image not copied to project directory")
            file:close()
            return
          end
        elseif result == "alreadyadded" then
          love.window.showMessageBox("Dropped image", "The dropped image ("..tostring(filepath)..") has already been added")
          file:close()
          return
        end
      end
      local info = nfs.getInfo(filepath)
      spriteEditor.addSpritesheet(shortpath, file:read("data", file:getSize()), info and info.modtime or os.time())

      love.window.focus()
    end
  end
  file:close()
end

spriteEditor.isdropping = function(mx, my)
  if spriteEditor.scrollHitbox then
    local x,y,w,h = unpack(spriteEditor.scrollHitbox)
    if spriteEditor.suit:mouseInRect(x,y,w,h, mx,my) then
      spriteEditor.isdroppingSpritesheet = my
    else
      spriteEditor.isdroppingSpritesheet = false
    end
  end
end

spriteEditor.stoppeddropping = function()
  spriteEditor.isdroppingSpritesheet = false
end

end