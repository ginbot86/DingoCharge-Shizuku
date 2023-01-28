--[[DingoCharge for Shizuku Platform - Advanced Configuration Menu
https://ripitapart.com December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).
1.5.0: Changed how aggressive GC is enabled/disabled; set aggressiveGcThreshold to 0 instead of isAggressiveGcEnabled to false (not that you should do this anyway...) (2023-01-08).
       Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).]]

function advancedMenu()
  local advMenuSel = 0
  local gcMenuEntry = " "
  local soundMenuEntry = " "
  local tempDisplayMenuEntry = " "
  local timeLimitMenuEntry = " "
  while true do
      collectgarbage("collect") -- clean up memory before we get into the menus
    if aggressiveGcThreshold == 0 then
      gcMenuEntry = "Aggressive GC: Disabled"
    else
      gcMenuEntry = string.format("Aggressive GC: %.0fK", aggressiveGcThreshold / 1024)
    end
    if isSystemSoundsEnabled then
      soundMenuEntry = "System Sounds: On"
    else
      soundMenuEntry = "System Sounds: Off"
    end
    if isTempDisplayF then
      tempDisplayMenuEntry = "Temperature Display: \2" -- degF
    else
      tempDisplayMenuEntry = "Temperature Display: \1" -- degC
    end
    if timeLimitHours == 0 then
      timeLimitMenuEntry = "Time Limit: Disabled"
    else
      timeLimitMenuEntry = string.format("Time Limit: %dh", timeLimitHours)
    end
    screen.clear()
    advMenuSel = screen.popMenu({"<       Main Menu       ", "Battery Precharge...", string.format("Cable Resistance: %.3f\3", cableResistance), string.format("CC Fallback: %.2fC", ccFallbackRate),"Chg Reg Deadband...", tempDisplayMenuEntry, "Ext Temp Sensor...", timeLimitMenuEntry, string.format("Refresh Rate: %d ms",refreshInterval), gcMenuEntry, soundMenuEntry, "Restore All Defaults"})
    screen.clear()
    if advMenuSel == 1 then
      require "lua/user/DC4S/lib/DC4S-cfgPreChg"
      cfgPreChg()
    elseif advMenuSel == 2 then
      require "lua/user/DC4S/lib/DC4S-cfgCableRes"
      cfgCableRes()
    elseif advMenuSel == 3 then
      require "lua/user/DC4S/lib/DC4S-cfgCcFallbackRate"
      cfgCcFallbackRate()
    elseif advMenuSel == 4 then
      require "lua/user/DC4S/lib/DC4S-cfgDeadband"
      cfgDeadband() 
    elseif advMenuSel == 5 then
      require "lua/user/DC4S/lib/DC4S-cfgTempDisplay"
      cfgTempDisplay()
    elseif advMenuSel == 6 then
      require "lua/user/DC4S/lib/DC4S-cfgExtTemp"
      cfgExtTemp()
    elseif advMenuSel == 7 then
      require "lua/user/DC4S/lib/DC4S-cfgTimeLimit"
      cfgTimeLimit()
    elseif advMenuSel == 8 then
      require "lua/user/DC4S/lib/DC4S-cfgRefreshRate"
      cfgRefreshRate()
    elseif advMenuSel == 9 then
      require "lua/user/DC4S/lib/DC4S-cfgAggressiveGc"
      cfgAggressiveGc()
    elseif advMenuSel == 10 then
      require "lua/user/DC4S/lib/DC4S-cfgSounds"
      cfgSounds()
    elseif advMenuSel == 11 then
      if (screen.popYesOrNo("Restore defaults?",color.yellow)) then
        resetAllDefaults()
        screen.popHint("Defaults Restored", 1000)
      end
    else
      break
    end
  end
  advancedMenu = nil
  package.loaded["lua/user/DC4S/lib/DC4S-advancedMenu"] = nil
  collectgarbage("collect") -- clean up memory
end