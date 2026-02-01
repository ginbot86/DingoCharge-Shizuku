--[[DC4S: DingoCharge for Shizuku Platform (YK-Lab YK001, AVHzY CT-3, Power-Z KT002, ATORCH UT18, Helpers Lab XB001A) - Launcher & Crash Handler
Li-ion CC/CV Charger via USB-C PD PPS, by Jason Gin.
https://github.com/ginbot86/DingoCharge-Shizuku November 16, 2021.

Version history:
1.8.0: Moved main code into a separate file; all new version changes will be recorded in DC4S-main.lua source (2026-01-30).
       Replaced main code with a crash handler that will save a log and can print error information on-screen if desired (2026-01-30).]]

function launch() -- wrap the main code so pcall() can catch any errors that would normally crash to the Shizuku MainUI
  if (screen.open() ~= screen.OK) then 
    error("screen.open() failed") -- we can't show the error on-screen if screen.open() fails, but a log will still be saved
  end
  isScreenOpen = true
  -- Main code is stored in a separate file:
  require "lua/user/DC4S/lib/DC4S-main"
  main()
end

isScreenOpen = false
local isNormalExit, crashMessage = pcall(function() launch() end) -- run the main code and invoke crash handler if any fatal error occurs

if not isNormalExit then
  if _G.__crashActive then os.exit(-1) end -- just in case there's another background crash handler, if so then we'll back off
  _G.__crashActive = true
  local function v(x) -- just in case version variables weren't set, print a '?' instead of crashing the crash handler
    return tostring(x or "?")
  end

  -- First things first, try to save a crash log
  local logFile = io.open("DC4S-CrashLog.txt", "w")
  if logFile then
    logFile:write("DingoCharge Crash Report\n")
    logFile:write("Error message: ", tostring(crashMessage), "\n")
    logFile:write("Script: v", v(scriptVerMajor), ".", v(scriptVerMinor), ".", v(scriptPatchVer), "\n")
    logFile:write("Config: v", v(configVerMajor), ".", v(configVerMinor), ".", v(configPatchVer), "\n")
    logFile:write("HW: ", sys.verToString(sys.gHWVer()), "\n")
    logFile:write("FW: ", sys.verToString(sys.gFWVer()), "\n")
    logFile:write("API: ", sys.verToString(sys.gLuaAPIVer()), "\n")
    logFile:write("Mem (free/lowest): ", sys.gFreeHeap(), "/", sys.gFreeHeapEver(), "\n")
    logFile:write("Tick: ", sys.gTick(), "\n")
    logFile:write("Timestamp (UTC): ", os.date("%Y-%m-%d %H:%M:%S UTC"), "\n")
    logFile:close()
  else
    print("Failed to save crash log (today is not a good day x.x)")
  end

  buzzer.system(sysSound.finished) -- play sound regardless of user preference to indicate failure condition
  
  local screenLines = { -- yes, this duplicates the previous log, but this one needs to be length-limited to fit on screen
    "DingoCharge Crash Report",
    "Error message:",
    string.sub(tostring(crashMessage), 1, 52),
    "Script: v" .. v(scriptVerMajor) .. "." .. v(scriptVerMinor) .. "." .. v(scriptPatchVer),
    "Config: v" .. v(configVerMajor) .. "." .. v(configVerMinor) .. "." .. v(configPatchVer),
    "HW: " .. sys.verToString(sys.gHWVer()),
    "FW: " .. sys.verToString(sys.gFWVer()),
    "API: " .. sys.verToString(sys.gLuaAPIVer()),
    "Mem: " .. sys.gFreeHeap() .. "/" .. sys.gFreeHeapEver(),
    "Tick: " .. sys.gTick(),
    os.date("%Y-%m-%d %H:%M:%S UTC"),
    "Log: /DC4S-CrashLog.txt" }
  local crashBuffer = table.concat(screenLines, "\n")
  print(crashBuffer) -- Shizuku PC software gets a copy of the on-screen error message if it's running and connected via USB at crash time ("Lua Script" tab -> "Terminal" sub-tab)
  
  -- only attempt to present an error UI if screen.open() was successful; prevents crashing the crash handler
  if not isScreenOpen then
    print("Cannot display error prompt: screen.open() failed")
  else
    if screen.popYesOrNo(":(\nOops, DingoCharge\ncrashed!\n\nView crash details?", color.red) then
      screen.printInBox(0,0,159,127, crashBuffer, font.f0508, color.red, color.black)
      delay.ms(10000)
    else
      screen.popHint("Crash Log Saved", 1000, color.red)
      screen.popHint("/DC4S-CrashLog.txt", 1500, color.red)
    end
  end
  
  os.exit(-1)
end

screen.close()
pdSink.deinit()
os.exit(0)