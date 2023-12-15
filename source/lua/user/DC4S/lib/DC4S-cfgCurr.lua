--[[DingoCharge for Shizuku Platform - Charge Current Configuration Menu
https://github.com/ginbot86/DingoCharge-Shizuku December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).
1.5.0: Changed the low-current deadband threshold to activate if charge current is less than the threshold instead of less than/equal to (2023-01-01).
       Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).
1.6.0: Changed header to point directly to official GitHub repository (2023-12-15).]]

-- TODO: reduce the redundant code in these menus...
function cfgCurr()
  screen.clear()
  local currSel = screen.popMenu({string.format("Keep Current (%0.3fA)",chargeCurrent),"Set Charge Current..."})
  screen.clear()
  local tmpCurr = chargeCurrent
  if currSel == 1 then
    -- Integer
    tmpCurr = screen.popMenu({"0.xxxA","1.xxxA","2.xxxA","3.xxxA","4.xxxA","5.xxxA"})
    -- Tenths
    tmpCurr = tmpCurr + (0.1 * screen.popMenu({string.format("%0.1fxxA",tmpCurr),string.format("%0.1fxxA",tmpCurr + 0.1),string.format("%0.1fxxA",tmpCurr + 0.2),string.format("%0.1fxxA",tmpCurr + 0.3),string.format("%0.1fxxA",tmpCurr + 0.4),string.format("%0.1fxxA",tmpCurr + 0.5),string.format("%0.1fxxA",tmpCurr + 0.6),string.format("%0.1fxxA",tmpCurr + 0.7),string.format("%0.1fxxA",tmpCurr + 0.8),string.format("%0.1fxxA",tmpCurr + 0.9)}))
    -- Hundredths
    tmpCurr = tmpCurr + (0.01 * screen.popMenu({string.format("%0.2fxA",tmpCurr),string.format("%0.2fxA",tmpCurr + 0.01),string.format("%0.2fxA",tmpCurr + 0.02),string.format("%0.2fxA",tmpCurr + 0.03),string.format("%0.2fxA",tmpCurr + 0.04),string.format("%0.2fxA",tmpCurr + 0.05),string.format("%0.2fxA",tmpCurr + 0.06),string.format("%0.2fxA",tmpCurr + 0.07),string.format("%0.2fxA",tmpCurr + 0.08),string.format("%0.2fxA",tmpCurr + 0.09)}))
    -- Thousandths
    tmpCurr = tmpCurr + (0.001 * screen.popMenu({string.format("%0.3fA",tmpCurr),string.format("%0.3fA",tmpCurr + 0.001),string.format("%0.3fA",tmpCurr + 0.002),string.format("%0.3fA",tmpCurr + 0.003),string.format("%0.3fA",tmpCurr + 0.004),string.format("%0.3fA",tmpCurr + 0.005),string.format("%0.3fA",tmpCurr + 0.006),string.format("%0.3fA",tmpCurr + 0.007),string.format("%0.3fA",tmpCurr + 0.008),string.format("%0.3fA",tmpCurr + 0.009)}))   
  end
  chargeCurrent = tmpCurr
  if (chargeCurrent < ccDeadbandThreshold) then -- smaller deadband for lower charge currents
    ccDeadband = ccDeadbandLow
  else
    ccDeadband = ccDeadbandNormal
  end
  screen.popHint(string.format("%0.3fA", chargeCurrent), 1000)
  -- discard temporary variables
  currSel = nil
  tmpCurr = nil
  cfgCurr = nil
  package.loaded["lua/user/DC4S/lib/DC4S-cfgCurr"] = nil
  collectgarbage("collect") -- clean up memory
end
