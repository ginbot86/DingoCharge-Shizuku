--[[DingoCharge for Shizuku Platform - Deadband Configuration Submenu
https://github.com/ginbot86/DingoCharge-Shizuku December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).
1.5.0: Changed the low-current deadband threshold to activate if charge current is less than the threshold instead of less than/equal to (2023-01-01).
1.5.0: Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).
1.6.0: Changed header to point directly to official GitHub repository (2023-12-15).]]

function cfgDeadbandEntry(varSel)
  local varValue = 0
  local varUnit = " "
  local varType = " "
  screen.clear()
  if (varSel == 1) then -- precharge
    varValue = pcDeadband
    varUnit = "A"
    varType = "Precharge Dband"
  elseif (varSel == 2) then -- constant current normal
    varValue = ccDeadbandNormal
    varUnit = "A"
    varType = "CC Norm Dband"  
  elseif (varSel == 3) then -- constant current low
    varValue = ccDeadband
    varUnit = "A"
    varType = "CC Low Dband"
  elseif (varSel == 4) then -- constant current normal/low decision threshold
    varValue = ccDeadbandThreshold
    varUnit = "A"
    varType = "CC Low Thresh"
  elseif (varSel == 5) then -- constant voltage
    varValue = cvDeadband
    varUnit = "V"
    varType = "CV Dband"
  elseif (varSel == 6) then -- terminate charge/current
    varValue = tcDeadband
    varUnit = "A"
    varType = "Chg Term Dband"
  else
    return
  end
  
  local dbndSel = screen.popMenu({string.format("Keep Current (%.3f%s)",varValue,varUnit),string.format("Set %s...",varType)})
  if dbndSel == 1 then
    -- Integer, always <1
    varValue = 0
    -- Tenths
    varValue = varValue + (0.1 * screen.popMenu({string.format("%0.1fxx%s",varValue,varUnit),string.format("%0.1fxx%s",varValue + 0.1,varUnit),string.format("%0.1fxx%s",varValue + 0.2,varUnit),string.format("%0.1fxx%s",varValue + 0.3,varUnit),string.format("%0.1fxx%s",varValue + 0.4,varUnit),string.format("%0.1fxx%s",varValue + 0.5,varUnit),string.format("%0.1fxx%s",varValue + 0.6,varUnit),string.format("%0.1fxx%s",varValue + 0.7,varUnit),string.format("%0.1fxx%s",varValue + 0.8,varUnit),string.format("%0.1fxx%s",varValue + 0.9,varUnit)}))    
   -- Hundredths
    varValue = varValue + (0.01 * screen.popMenu({string.format("%0.2fx%s",varValue,varUnit),string.format("%0.2fx%s",varValue + 0.01,varUnit),string.format("%0.2fx%s",varValue + 0.02,varUnit),string.format("%0.2fx%s",varValue + 0.03,varUnit),string.format("%0.2fx%s",varValue + 0.04,varUnit),string.format("%0.2fx%s",varValue + 0.05,varUnit),string.format("%0.2fx%s",varValue + 0.06,varUnit),string.format("%0.2fx%s",varValue + 0.07,varUnit),string.format("%0.2fx%s",varValue + 0.08,varUnit),string.format("%0.2fx%s",varValue + 0.09,varUnit)}))  
    -- Thousandths
    varValue = varValue + (0.001 * screen.popMenu({string.format("%0.3f%s",varValue,varUnit),string.format("%0.3f%s",varValue + 0.001,varUnit),string.format("%0.3f%s",varValue + 0.002,varUnit),string.format("%0.3f%s",varValue + 0.003,varUnit),string.format("%0.3f%s",varValue + 0.004,varUnit),string.format("%0.3f%s",varValue + 0.005,varUnit),string.format("%0.3f%s",varValue + 0.006,varUnit),string.format("%0.3f%s",varValue + 0.007,varUnit),string.format("%0.3f%s",varValue + 0.008,varUnit),string.format("%0.3f%s",varValue + 0.009,varUnit)}))       
  end
  screen.popHint(string.format("%0.3f%s", varValue, varUnit), 1000)
  
  if (varSel == 1) then
    pcDeadband = varValue
  elseif (varSel == 2) then
    ccDeadbandNormal = varValue
  elseif (varSel == 3) then
    ccDeadbandLow = varValue
  elseif (varSel == 4) then
    ccDeadbandThreshold = varValue
  elseif (varSel == 5) then
    cvDeadband = varValue
  elseif (varSel == 6) then
    tcDeadband = varValue
  else
    -- discard temporary variables
    varValue = nil
    varUnit = nil
    varType = nil
    cfgDeadbandEntry = nil
    collectgarbage("collect") -- clean up memory
    return
  end
  if (chargeCurrent < ccDeadbandThreshold) then
    ccDeadband = ccDeadbandLow
  else
    ccDeadband = ccDeadbandNormal
  end
  -- discard temporary variables
  varValue = nil
  varUnit = nil
  varType = nil
  cfgDeadbandEntry = nil
  package.loaded["lua/user/DC4S/lib/DC4S-cfgDeadbandEntry"] = nil
  collectgarbage("collect") -- clean up memory
end