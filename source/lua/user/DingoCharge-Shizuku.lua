--[[DC4S: DingoCharge for Shizuku Platform (YK-Lab YK001, AVHzY CT-3, Power-Z KT002, ATORCH UT18)
Li-ion CC/CV Charger via USB-C PD PPS, by Jason Gin.
https://github.com/ginbot86/DingoCharge-Shizuku November 16, 2021.

Version history:
1.0.0: Initial public release (2022-06-30).
1.1.0: Fixed issue where setting cell count does not update precharge voltage. (2022-07-22).
       Fixed issue where precharge voltage did not display (correctly) during charge. (2022-10-12).
       Added CC fallback when in CV mode and charge current overshoots too much (2022-10-12).
       Added an option to display system temperature in Fahrenheit (2022-10-12).
       Added 2.5V/cell and 8S cell configurations (2022-10-13).
1.1.1: Fixed issue where some chargers' current-limiting conflicted with CV control loop (2022-10-15).
1.1.2: Fixed issue where setting 8S configuration would result in a Config Error message (2022-10-20).
1.2.0: Added prompt to retry the compatibility test if Vbus voltage is not present, instead of outright failing (2022-11-06).
       Added CC deadband threshold tweaks to fix an issue where setting charge current overwrites the user's defaults (2022-11-06).
       Fixed issue where double-tapping Select key in "Advanced... > Chg Reg Deadband" menu does not go up a level (2022-11-06).
1.3.0: Fixed issue where 3.65Vpc was considered standard Li-ion in terms of precharge voltage instead of LiFePO4 (2022-11-17).
       Added test to verify configuration immediately upon startup (2022-12-12).
       Added memory cleanup routine after reading PDOs from adapter (2022-12-12).
       Changed internal version format (2022-12-12).
       Added statusbar override support for charge termination/faults (2022-12-13).
       Added support for TMP3x/LM35/LM50 external temperature sensor on D+ pin (2022-12-13).
       Added optional over/undertemperature protection when using external sensor (2022-12-13).
       Added charge timeout protection (2022-12-13).
       Fixed issue where resuming session timer counts time while timer was stopped (2022-12-13).
       Added second menu library file due to RAM space exhaustion (2022-12-13).
       Decreased aggressive GC threshold from 16K to 4K but added more forced GCs to mitigate RAM exhaustion (2022-12-13).
1.4.0: Split off monolithic menu library functions into individual files, reducing RAM consumption significantly (2022-12-15).
       Increased aggressive GC threshold from 4K to 16K due to RAM usage savings from modularization (2022-12-15).
       Changed charge error messages to reflect if recovery is enabled (i.e. "paused" vs. "stopped") (2022-12-18).
       Fixed issue where precharge was not subject to the safety time limit (2022-12-18).
       Added cumulative charge/energy display for the current charge session (2022-12-24).
       Updated free memory counter to specify count in bytes (2022-12-24).
       Changed how the UI calculates when to show different statusbar messages (2012-12-24).
1.5.0: Changed the low-current deadband threshold to activate if charge current is less than the threshold instead of less than/equal to (2023-01-01).
       Updated copyright string in About screen to read "(C) 2021-2023".
       Changed the default cell count to 2S for improved user experience; most PPS adapters go to 11V so a compatibility fail out of the box kinda sucks... (2023-01-06).
       Changed how aggressive GC is enabled/disabled; set aggressiveGcThreshold to 0 instead of isAggressiveGcEnabled to false (not that you should do this anyway...) (2023-01-08).
       Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).
       Added LM135/LM235/LM335 support as external temperature sensors (2023-01-21).
       Split off charge control function into a separate file which unloads upon termination to conserve memory (2023-01-27).
       Renamed "DC4S-CompileMenu" to "DC4S-CompileLibs" to reflect that non-menu libraries are also compiled here (2023-01-27).
       Changed how USB-C CC attachment errors are handled; user can retry the detection instead of needing to restart the charge setup procedure (2023-01-28).
1.6.0: Added check to verify battery voltage is at least 3 volts (no PPS adapter will likely support less than this) (2023-01-29).
       Changed how adapter detection works during compatibility test; voltages higher than 5.5V will also trigger an "adapter is not plugged in" message (2023-02-01).
       Removed redundant aggressive GC threshold check while charging (2023-02-02).
       Split off compatibility test into a separate file which unloads upon termination to conserve memory (2023-02-02).
       Added check to ensure the Lua fastChgTrig module is available on startup (2023-02-04).
       Lowered the low/high constant-current deadband threshold from 500 to 200mA to reduce charging current oscillation at lower charging rates (2023-05-21).
       Changed external temperature sensor setup exit display to use 'ºC' sign instead of just 'C' (2023-07-31).
       Added more system sounds for charge errors and prompts (2023-11-01).
       Streamlined configuration checker to reduce redundant code and unload itself when finished (2023-11-01).
       Added error sound if a configuration error is found (2023-11-01).
       Fixed issue where elapsed time (and Time Limit) advances 10x faster than intended on firmware v1.00.62 (2023-12-11).
       Fixed issue where the Chg. Set display does not flip between precharge current and voltage once the session timer stops (2023-12-11).
       Added 3.3Vpc charge voltage for LiFePO4 storage (2023-12-11).
       Streamlined charge voltage menu code (2023-12-14).
       Changed header to point directly to official GitHub repository (2023-12-15).
       Changed About dialog to point to official GitHub repository (2023-12-15).]]



scriptVerMajor = 1
scriptVerMinor = 6
scriptPatchVer = 0

-- Default settings are stored in a separate file:
require "lua/user/DC4S/UserDefaults-DC4S"

-- Configuration tools and other libraries are now stored in their own files in the "DC4S/lib" subfolder as of version 1.4.0

-- Functions

function checkIfFileExists(filename) -- reference: https://stackoverflow.com/questions/4990990/check-if-a-file-exists-with-lua
  local file = io.open(filename, "r")
  if (file ~= nil) then
    io.close(file)
    return true
  else
    return false
  end
end

function loadLibrary(filename) -- FIXME: does not work yet
  if checkIfFileExists(filename) then
    require(filename)
    return true
  else
    print("Error: file " .. filename .. "not found!")
    screen.showDialog("Load Failed","File not found:\n" .. filename, 5000, true, color.red)
    return false
  end
end

function endProgram()
  screen.close()
  pdSink.deinit()
  os.exit(0)
end

function readCurrentSigned()
  if meter.readCurrentDirection() then -- true if negative
    return (0 - meter.readCurrent())
  else
    return meter.readCurrent()
  end
end

function readPowerSigned()
  if meter.readCurrentDirection() then -- true if negative
    return (0 - meter.readPower())
  else
    return meter.readPower()
  end
end

function waitForSourceCap()
  local timer = 2000
  while (timer > 0) do 
    timer = timer - 1
    if (pdSink.isSrcCapReceived()) then 
      timer = nil
      return true
    end
    delay.ms(1)
  end
  return false
end

function closePdSession()
  pdSink.deinit()
  fastChgTrig.close()
end

function readExternalTemperatureCelsius()
  return externalTemperatureGain * (meter.readDP() + externalTemperatureOffsetVoltage) -- offset is applied before gain
end

-- "123456789ABCDEFGHIJ" is maximum length of popYesOrNo or showDialog line, 19 chars
-- "123456789ABCDEFGHIJKLMNO" is maximum length of popMenu line, 24 chars
-- Weird spacing between words (or lack thereof) is to prevent line wrapping from occurring mid-word
-- Special characters: \1 = ºC, \2 = ºF, \3 = Ω (these glyphs only render for font.f1212)


function drawMeter(x, y, title, value, unit, meterColor)
  local drawColor = meterColor or color.white
  screen.drawRect(x, y+3, x+92, y+36, drawColor)
  screen.showString(x+3, y, "-" .. title, font.f0508, drawColor) -- preceding hyphen creates 1 pixel space between border and title text on left
  if (math.abs(value) < 10) then -- 1.234
    screen.showString(x+6, y+9, string.format("%.3f%s", value, unit), font.f1424, drawColor)
  elseif (math.abs(value) < 100) then -- 12.34
    screen.showString(x+6, y+9, string.format("%.2f%s", value, unit), font.f1424, drawColor)
  elseif (math.abs(value) < 1000) then -- 123.4
    screen.showString(x+6, y+9, string.format("%.1f%s", value, unit), font.f1424, drawColor)
  else -- 1234
    screen.showString(x+6, y+9, string.format("%.0f%s", value, unit), font.f1424, drawColor)
  end
end

function printStatusbar(text, textColor, barColor, backColor)
  local drawTextColor = textColor or color.white
  local drawLineColor = barColor or color.white
  local drawBackColor = backColor or color.black
  screen.fillRect(0, 117, 159, 127, drawBackColor)
  screen.showString(0, 117, text, font.f1212, drawTextColor, drawBackColor)
  screen.drawRect(0, 116, 159, 116, drawLineColor)
end

function startSessionTimer()
  sessionTimerStart = sys.gTick() / 1000 -- Shizuku firmware v1.00.62 caused os.date() to advance 10 times faster than it should, so all calls to os.date() are now replaced with calls to sys.gTick() which has a 1ms granularity
  sessionTimerNow = sessionTimerStart
  isSessionTimerEnabled = true
  
  cumCharge = 0
  cumEnergy = 0
end

function stopSessionTimer()
  isSessionTimerEnabled = false
end

function resumeSessionTimer()
  isSessionTimerEnabled = true
  sessionTimerNow = sys.gTick() / 1000
end

function updateSessionTimer()
  if isSessionTimerEnabled then
    sessionTimerNow = sys.gTick() / 1000
  else
    sessionTimerStart = sessionTimerStart + ((sys.gTick() / 1000) - sessionTimerNow) -- advance start timer to compensate for time spent while session timer stopped
    sessionTimerNow = sys.gTick() / 1000
  end
end

-- Start of script

if (screen.open() ~= screen.OK) then 
  os.exit(-1)
end
resetAllDefaults()

require "lua/user/DC4S/lib/DC4S-checkConfigs"
if not checkConfigs() then -- check if configuration is valid
  os.exit(-1)
end

if (fastChgTrig.open() ~= fastChgTrig.OK) then -- check fastChgTrig at startup so the user isn't surprised after going through much of the charger setup only to end up at an error
  if isSystemSoundsEnabled then
    buzzer.system(sysSound.alarm)
  end
  screen.showDialog("Startup Failed", "Unable to open the\nfastChgTrig module!\nTry power cycling\nor rebooting tester", 5000, true, color.red)
  exit(-1)
end
fastChgTrig.close()

if isSystemSoundsEnabled then
  buzzer.system(sysSound.started)
end

screen.clear()

timerFineStart = sys.gTick()
timerFineNow = sys.gTick()
isChargeStarted = false
isStatusbarOverridden = false
statusbarOverrideColor = color.red
statusbarOverrideText = "oops uwu" -- will only appear if override text is not defined before displaying it

screen.popHint(string.format("DingoCharge v%d.%d", scriptVerMajor, scriptVerMinor), 1000)

collectgarbage("collect") -- clean up memory after all configs loaded

while true do
  screen.clear()
  mainMenuSel = screen.popMenu({"Charger Setup...", "Start Charging", "Advanced...", "About", "Exit", "Reboot"})
  screen.clear()

  if mainMenuSel == 0 then
    require "lua/user/DC4S/lib/DC4S-chargerSetup" -- load on demand; will unload when function terminates
    chargerSetup()
  elseif mainMenuSel == 1 then
    if screen.popYesOrNo(string.format("Start charging?\nVoltage: %.3fV\nCurrent: %.3fA\nTerm: %.2fC/%.3fA", (voltsPerCell * numCells), chargeCurrent, termCRate, (chargeCurrent * termCRate)), color.lightGreen) then
      require "lua/user/DC4S/lib/DC4S-startCharging"
      startCharging()
    end
  elseif mainMenuSel == 2 then
    require "lua/user/DC4S/lib/DC4S-advancedMenu"
    advancedMenu()
  elseif mainMenuSel == 3 then
    if (screen.popMenu({"<       Main Menu       ", "DingoCharge for Shizuku", "github.com/ginbot86[...]", "/DingoCharge-Shizuku","(C) Jason Gin 2021-2023", string.format("Version: v%d.%d.%d", scriptVerMajor, scriptVerMinor, scriptPatchVer), ":3"}) == 6) then
      screen.popHint("OwO", 1000, color.green) -- what's this? (it's an Easter egg! :3)
    end
  elseif mainMenuSel == 4 then
    if (screen.popYesOrNo("Exit program?", color.cyan)) then
      endProgram()
    end
  elseif mainMenuSel == 5 then
    if (screen.popYesOrNo("Reboot tester?", color.red)) then
      sys.reset()
    end
  end
end
endProgram()