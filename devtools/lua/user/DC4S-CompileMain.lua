--[[DingoCharge for Shizuku Platform - Lua to LC Converter (Main Code)
https://github.com/ginbot86/DingoCharge-Shizuku November 16, 2021.

Version history:
1.0.0: Initial public release (2022-06-30).
1.6.0: Changed header to point directly to official GitHub repository (2023-12-15).]]

filePath = "0:/lua/user/DingoCharge-Shizuku.lua"

function checkIfFileExists(filename) -- reference: https://stackoverflow.com/questions/4990990/check-if-a-file-exists-with-lua
  local file = io.open(filename, "r")
  if (file ~= nil) then
    io.close(file)
    return true
  else
    return false
  end
end

function convertLua(filename)
  if (checkIfFileExists(filename) == true) then
    sys.gByteCode(filename)
    screen.popHint("Created bytecode", 1000, color.green)
    if (os.remove(filename) == true) then
      screen.popHint("Deleted .lua", 1000, color.green)
    else
      screen.popHint(".lua delete failed", 1000, color.red)
      return false
    end
  else
    screen.popHint("Bytecode failed", 1000, color.red)
    return false
  end
  return true
end

if (screen.open() ~= screen.OK) then
  os.exit(-1)
end

screen.popHint("Compile main",1000,color.cyan)
convertLua(filePath)

os.exit(0)