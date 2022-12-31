--[[DingoCharge for Shizuku Platform - Constant-Current Fallback Configuration Menu
https://ripitapart.com December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).]]

function cfgCcFallbackRate()
  screen.clear()
  local cfgCcFallbackSel = 0
  local tmpCcRate = 0
  
  while true do
    cfgCcFallbackSel = screen.popMenu({string.format("Keep Current (%.2fC)",ccFallbackRate),"Set CC Fallback Rate...", "Restore Defaults"})
    tmpCcRate = ccFallbackRate
    if cfgCcFallbackSel == 1 then
      -- Integer, always >= 1C
      tmpCcRate = 1
      -- Tenths
      tmpCcRate = tmpCcRate + (0.1 * screen.popMenu({string.format("%0.1fxC",tmpCcRate),string.format("%0.1fxC",tmpCcRate + 0.1),string.format("%0.1fxC",tmpCcRate + 0.2),string.format("%0.1fxC",tmpCcRate + 0.3),string.format("%0.1fxC",tmpCcRate + 0.4),string.format("%0.1fxC",tmpCcRate + 0.5),string.format("%0.1fxC",tmpCcRate + 0.6),string.format("%0.1fxC",tmpCcRate + 0.7),string.format("%0.1fxC",tmpCcRate + 0.8),string.format("%0.1fxC",tmpCcRate + 0.9)}))    
     -- Hundredths
      tmpCcRate = tmpCcRate + (0.01 * screen.popMenu({string.format("%0.2fC",tmpCcRate),string.format("%0.2fC",tmpCcRate + 0.01),string.format("%0.2fC",tmpCcRate + 0.02),string.format("%0.2fC",tmpCcRate + 0.03),string.format("%0.2fC",tmpCcRate + 0.04),string.format("%0.2fC",tmpCcRate + 0.05),string.format("%0.2fC",tmpCcRate + 0.06),string.format("%0.2fC",tmpCcRate + 0.07),string.format("%0.2fC",tmpCcRate + 0.08),string.format("%0.2fC",tmpCcRate + 0.09)}))  
      break
    elseif cfgCcFallbackSel == 2 then
      if (screen.popYesOrNo("Restore defaults?",color.yellow)) then
        setCcFallbackDefaults()
        screen.popHint("Defaults Restored", 1000)    
      end
    else
      break
    end
  end
  ccFallbackRate = tmpCcRate
  screen.popHint(string.format("%0.2fC", ccFallbackRate), 1000)
  -- discard temporary variables
  cfgCcFallbackSel = nil
  tmpCcRate = nil
  collectgarbage("collect") -- clean up memory
end