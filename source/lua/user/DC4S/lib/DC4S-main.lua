--[[DC4S: DingoCharge for Shizuku Platform (YK-Lab YK001, AVHzY CT-3, Power-Z KT002, ATORCH UT18, Helpers Lab XB001A) - Main Code
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
       Changed About dialog to point to official GitHub repository (2023-12-15).
1.7.0: Fixed issue where error sound would not play if an initial PD request failed (2024-01-17).
       Fixed issue where "Ready to charge. Plug in battery now" modal dialog could cause a PD timeout if the dialog is not acknowledged in time (2026-01-10).
       Replaced aforementioned modal dialog with an interstitial "Ready to charge" screen that maintains PD requests until battery connection is detected, or automatic timeout to enter the charge session (2026-01-10).
       Fixed issue where the session timer would not restore correctly when restarting a charge session (2026-01-10).
       Removed version history from the user defaults file (2026-01-10).
       Added version mismatch checking for user defaults file (2026-01-10).
       Added PD request latency measurement in statusbar (2026-01-10).
1.8.0: Moved utility functions and miscellaneous variables out of the main DingoCharge-Shizuku.lua source (2026-01-12).
       Added bold font to active charge stage indicator (2026-01-24).
       Created palette test developer tool to visualize all available colours in the Shizuku API and demonstrate how to print bold text (2026-01-24).
       Added an extended string print function that supports limited bold text display (2026-01-28).
       Added a crash handler that will save a log and can print error information onscreen if desired (2026-01-30).
       Moved main code into a separate file; all new version changes will be recorded in DC4S-main.lua source (2026-01-30).
       Replaced main code with the crash handler to improve program robustness (2026-01-30).]]

scriptVerMajor = 1
scriptVerMinor = 8
scriptPatchVer = 0

function main() -- Main program code is now stored in its own file as of version 1.8.0
  -- Default settings are stored in a separate file:
  require "lua/user/DC4S/UserDefaults-DC4S"

  -- Configuration tools and other libraries are now stored in their own files in the "DC4S/lib" subfolder as of version 1.4.0
  require "lua/user/DC4S/lib/DC4S-libUtils"

  -- Start of script

  resetAllDefaults()

  require "lua/user/DC4S/lib/DC4S-checkConfigs"
  local isConfigValid, configError = checkConfigs() -- check if configuration is valid
  if not isConfigValid then
    error("Initial configuration check failed:\n" .. configError)
  end
  isConfigValid = nil
  configError = nil

  if (fastChgTrig.open() ~= fastChgTrig.OK) then -- check fastChgTrig at startup so the user isn't surprised after going through much of the charger setup only to end up at an error
    if isSystemSoundsEnabled then
      buzzer.system(sysSound.alarm)
    end
    screen.showDialog("Startup Failed", "Unable to open the\nfastChgTrig module!\nTry power cycling\nor rebooting tester", 5000, true, color.red)
    error("fastChgTrig.open() failed")
  end
  fastChgTrig.close()

  if isSystemSoundsEnabled then
    buzzer.system(sysSound.started)
  end

  screen.clear()

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
      if (screen.popMenu({"<       Main Menu       ", "DingoCharge for Shizuku", "github.com/ginbot86[...]", "/DingoCharge-Shizuku","(C) Jason Gin 2021-2026", string.format("Version: v%d.%d.%d", scriptVerMajor, scriptVerMinor, scriptPatchVer), ":3"}) == 6) then
        screen.popHint("OwO", 1000, color.green) -- what's this? (it's an Easter egg! :3)
      end
    elseif mainMenuSel == 4 then
      if (screen.popYesOrNo("Exit program?", color.cyan)) then
        break
      end
    elseif mainMenuSel == 5 then
      if (screen.popYesOrNo("Reboot tester?", color.red)) then
        sys.reset()
      end
    end
  end
end -- pcall() wrapper will treat implicit exit as normal