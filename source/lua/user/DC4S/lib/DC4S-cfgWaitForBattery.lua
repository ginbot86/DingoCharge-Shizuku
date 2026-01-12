--[[DingoCharge for Shizuku Platform - Wait-For-Battery Configuration Menu
https://github.com/ginbot86/DingoCharge-Shizuku January 10, 2026.

Version history:
1.7.0: Added configuration panel to control wait-for-battery timeout behaviour (2026-01-10).]]

function cfgWaitForBattery()
  local waitForBatterySel = 0
  local waitForBatteryMenuValue = " "
  
  while true do
    if waitForBatteryTimeout == 0 then
      waitForBatteryMenuValue = "Keep Current (Disabled)"
    else
      waitForBatteryMenuValue = string.format("Keep Current (%ds)", waitForBatteryTimeout)
    end
    screen.clear()
    waitForBatterySel = screen.popMenu({waitForBatteryMenuValue, "Disabled", "5s", "10s", "15s", "30s", "60s", "Restore Defaults"})
    if waitForBatterySel == 1 then
      waitForBatteryTimeout = 0
      break
    elseif waitForBatterySel == 2 then
      waitForBatteryTimeout = 5
      break
    elseif waitForBatterySel == 3 then
      waitForBatteryTimeout = 10
      break
    elseif waitForBatterySel == 4 then
      waitForBatteryTimeout = 15
      break
    elseif waitForBatterySel == 5 then
      waitForBatteryTimeout = 30
      break
    elseif waitForBatterySel == 6 then
      waitForBatteryTimeout = 60
      break
    elseif waitForBatterySel == 7 then
      if (screen.popYesOrNo("Restore defaults?", color.yellow)) then
        setWaitForBatteryDefaults()
        screen.popHint("Defaults Restored", 1000)
      end
    else
      break
    end
  end
  if waitForBatteryTimeout == 0 then
    screen.popHint("Disabled", 1000)
  else
    screen.popHint(string.format("%ds", waitForBatteryTimeout), 1000)
  end
  
  -- discard temporary variables and unload function
  cfgWaitForBattery = nil
  package.loaded["lua/user/DC4S/lib/DC4S-cfgWaitForBattery"] = nil
  collectgarbage("collect") -- clean up memory
end