--[[DingoCharge for Shizuku Platform - Lua to LC Converter (Menus/Libraries)
https://ripitapart.com November 16, 2021.

Version history:
1.0.0: Initial public release (2022-06-30).
1.1.0: Fixed incorrect "Compile main" message. Should be "Compile menu" (2022-10-15).
1.3.0: Added compile for second menu library, with memory cleanup in between libraries (2022-12-13).
1.4.0: Removed monolithic Menu Library 1/2; now compiles from a list of files for each menu/library (2022-12-15).
1.5.0: Split off charge control function into a separate file which unloads upon termination to conserve memory (2023-01-27).
       Renamed "DC4S-CompileMenu" to "DC4S-CompileLibs" to reflect that non-menu libraries are also compiled here (2023-01-27).]]

filePath = "0:/lua/user/DC4S/lib/DC4S-"
fileNames = { "advancedMenu",
              "cfgAggressiveGc",
              "cfgCableRes",
              "cfgCcFallbackRate",
              "cfgCells",
              "cfgCRate",
              "cfgCurr",
              "cfgDeadband",
              "cfgDeadbandEntry",
              "cfgExtTemp",
              "cfgPChgCRate",
              "cfgPChgVpc",
              "cfgPreChg",
              "cfgRefreshRate",
              "cfgSounds",
              "cfgTempDisplay",
              "cfgTimeLimit",
              "cfgVpc",
              "chargerSetup",
              "checkConfigs",
              "startCharging" }
fileExtension = ".lua"


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

-- Start of script

for loopIndex, currentFile in ipairs(fileNames) do
  compileFile = filePath .. currentFile .. fileExtension
  screen.popHint(currentFile, 1000, color.cyan)
  collectgarbage("collect")
  convertLua(compileFile)
  collectgarbage("collect")
end

os.exit(0)