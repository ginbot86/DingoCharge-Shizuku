--[[DingoCharge for Shizuku Platform - Temperature Display Configuration Menu
https://github.com/ginbot86/DingoCharge-Shizuku December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).
1.5.0: Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).
1.6.0: Changed header to point directly to official GitHub repository (2023-12-15).]]

function cfgTempDisplay()
  local cfgTempDisplaySel = 0
  local tempDisplayMenuValue = " "
  while true do
    if isTempDisplayF then
      tempDisplayMenuValue = "\2" -- ºF
    else
      tempDisplayMenuValue = "\1" -- ºC
    end
    
    cfgTempDisplaySel = screen.popMenu{string.format("Keep Current (%s)", tempDisplayMenuValue), "Show \1", "Show \2", "Restore Defaults"}
    if cfgTempDisplaySel == 1 then
      isTempDisplayF = false
      break
    elseif cfgTempDisplaySel == 2 then
      isTempDisplayF = true
      break
    elseif cfgTempDisplaySel == 3 then
      if (screen.popYesOrNo("Restore defaults?",color.yellow)) then
        setTemperatureDisplayDefaults()
        screen.popHint("Defaults Restored", 1000)    
      end
    else
      break
    end
  end
  
  if isTempDisplayF then
    screen.popHint("Show F", 1000) -- ºF or ºC symbols are not in larger font
  else
    screen.popHint("Show C", 1000)
  end
  -- discard temporary variables
  cfgTempDisplaySel = nil
  tempDisplayMenuValue = nil
  cfgTempDisplay = nil
  package.loaded["lua/user/DC4S/lib/DC4S-cfgTempDisplay"] = nil
  collectgarbage("collect") -- clean up memory
end