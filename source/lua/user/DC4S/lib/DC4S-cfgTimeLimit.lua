--[[DingoCharge for Shizuku Platform - Time Limit Configuration Menu
https://ripitapart.com December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).
1.5.0: Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).]]

function cfgTimeLimit()
  local cfgTimeLimitSel = 0
  local cfgTimeLimitText = " "
  local tmpTimeLimit = 0
  while true do
    screen.clear()
    if timeLimitHours == 0 then
      cfgTimeLimitText = "Keep Current (Disabled)"
    else
      cfgTimeLimitText = string.format("Keep Current (%dh)", timeLimitHours)
    end
    cfgTimeLimitSel = screen.popMenu{cfgTimeLimitText, "Disable Time Limit", "Set Time Limit...", "Restore Defaults"}
    if cfgTimeLimitSel == 1 then
      timeLimitHours = 0
      break
    elseif cfgTimeLimitSel == 2 then
      -- Tens
      tmpTimeLimit = 10 * screen.popMenu{"0xh","1xh","2xh","3xh","4xh","5xh","6xh","7xh","8xh","9xh"}
      -- Ones
      tmpTimeLimit = tmpTimeLimit + (screen.popMenu({string.format("%dh",tmpTimeLimit),string.format("%dh",tmpTimeLimit + 1),string.format("%dh",tmpTimeLimit + 2),string.format("%dh",tmpTimeLimit + 3),string.format("%dh",tmpTimeLimit + 4),string.format("%dh",tmpTimeLimit + 5),string.format("%dh",tmpTimeLimit + 6),string.format("%dh",tmpTimeLimit + 7),string.format("%dh",tmpTimeLimit + 8),string.format("%dh",tmpTimeLimit + 9)}))
      timeLimitHours = tmpTimeLimit
      collectgarbage("collect")
      break
    elseif cfgTimeLimitSel == 3 then
      if (screen.popYesOrNo("Restore defaults?", color.yellow)) then
        setTimeLimitDefaults()
        screen.popHint("Defaults Restored", 1000)
      end
    else
      break
    end
  end
  if timeLimitHours == 0 then
    screen.popHint("Disabled", 1000)
  else
    screen.popHint(string.format("%dh", timeLimitHours), 1000)
  end
  -- discard temporary variables
  cfgTimeLimitSel = nil
  cfgTimeLimitText = nil
  tmpTimeLimit = nil
  cfgTimeLimit = nil
  package.loaded["lua/user/DC4S/lib/DC4S-cfgTimeLimit"] = nil
  collectgarbage("collect") -- clean up memory
end