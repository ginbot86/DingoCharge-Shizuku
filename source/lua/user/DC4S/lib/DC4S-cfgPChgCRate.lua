--[[DingoCharge for Shizuku Platform - Precharge Rate Configuration Submenu
https://ripitapart.com December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).
1.5.0: Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).]]

function cfgPChgCRate()
  screen.clear()
  local tRateSel = screen.popMenu({string.format("Keep Current (%.2fC)",prechargeCRate),"Set Precharge Rate..."})
  local tmpPCRate = prechargeCRate
  if tRateSel == 1 then
    -- Integer, always <1C
    tmpPCRate = 0
    -- Tenths
    tmpPCRate = tmpPCRate + (0.1 * screen.popMenu({string.format("%0.1fxC",tmpPCRate),string.format("%0.1fxC",tmpPCRate + 0.1),string.format("%0.1fxC",tmpPCRate + 0.2),string.format("%0.1fxC",tmpPCRate + 0.3),string.format("%0.1fxC",tmpPCRate + 0.4),string.format("%0.1fxC",tmpPCRate + 0.5),string.format("%0.1fxC",tmpPCRate + 0.6),string.format("%0.1fxC",tmpPCRate + 0.7),string.format("%0.1fxC",tmpPCRate + 0.8),string.format("%0.1fxC",tmpPCRate + 0.9)}))    
   -- Hundredths
    tmpPCRate = tmpPCRate + (0.01 * screen.popMenu({string.format("%0.2fC",tmpPCRate),string.format("%0.2fC",tmpPCRate + 0.01),string.format("%0.2fC",tmpPCRate + 0.02),string.format("%0.2fC",tmpPCRate + 0.03),string.format("%0.2fC",tmpPCRate + 0.04),string.format("%0.2fC",tmpPCRate + 0.05),string.format("%0.2fC",tmpPCRate + 0.06),string.format("%0.2fC",tmpPCRate + 0.07),string.format("%0.2fC",tmpPCRate + 0.08),string.format("%0.2fC",tmpPCRate + 0.09)}))  
  end
  prechargeCRate = tmpPCRate
  screen.popHint(string.format("%0.2fC", prechargeCRate), 1000)
  -- discard temporary variables
  tRateSel = nil
  tmpPCRate = nil
  cfgPChgCRate = nil
  package.loaded["lua/user/DC4S/lib/DC4S-cfgPChgCRate"] = nil
  collectgarbage("collect") -- clean up memory
end
