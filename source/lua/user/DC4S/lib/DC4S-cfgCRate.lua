--[[DingoCharge for Shizuku Platform - Charge Termination Rate Configuration Menu
https://ripitapart.com December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).]]

function cfgCRate()
  screen.clear()
  local tRateSel = screen.popMenu({string.format("Keep Current (%.2fC)",termCRate),"Set Chg Term Rate..."})
  local tmpCRate = termCRate
  if tRateSel == 1 then
    -- Integer, always <1C
    tmpCRate = 0
    -- Tenths
    tmpCRate = tmpCRate + (0.1 * screen.popMenu({string.format("%0.1fxC",tmpCRate),string.format("%0.1fxC",tmpCRate + 0.1),string.format("%0.1fxC",tmpCRate + 0.2),string.format("%0.1fxC",tmpCRate + 0.3),string.format("%0.1fxC",tmpCRate + 0.4),string.format("%0.1fxC",tmpCRate + 0.5),string.format("%0.1fxC",tmpCRate + 0.6),string.format("%0.1fxC",tmpCRate + 0.7),string.format("%0.1fxC",tmpCRate + 0.8),string.format("%0.1fxC",tmpCRate + 0.9)}))    
   -- Hundredths
    tmpCRate = tmpCRate + (0.01 * screen.popMenu({string.format("%0.2fC",tmpCRate),string.format("%0.2fC",tmpCRate + 0.01),string.format("%0.2fC",tmpCRate + 0.02),string.format("%0.2fC",tmpCRate + 0.03),string.format("%0.2fC",tmpCRate + 0.04),string.format("%0.2fC",tmpCRate + 0.05),string.format("%0.2fC",tmpCRate + 0.06),string.format("%0.2fC",tmpCRate + 0.07),string.format("%0.2fC",tmpCRate + 0.08),string.format("%0.2fC",tmpCRate + 0.09)}))  
  end
  termCRate = tmpCRate
  screen.popHint(string.format("%0.2fC", termCRate), 1000)
  -- discard temporary variables
  tRateSel = nil
  tmpCRate = nil
  collectgarbage("collect") -- clean up memory
end