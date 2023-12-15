--[[DingoCharge for Shizuku Platform - Configuration Checker
https://github.com/ginbot86/DingoCharge-Shizuku December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).
1.6.0: Streamlined configuration checker to reduce redundant code and unload itself when finished (2023-11-01).
       Added error sound if a configuration error is found (2023-11-01).
       Changed header to point directly to official GitHub repository (2023-12-15).]]

function checkConfigs()
  local returnStatus = false
  local errorString = "No error?!" -- this should never be displayed
  local errorDisplayTime = 3000
  
  -- This function can only display one error at a time; the first matching error in the list will be displayed
  if (chargeCurrent <= 0) then
    errorString = string.format("Invalid charging\ncurrent!\n\n%.3fA <= 0.000A", chargeCurrent)
  elseif (chargeCurrent > 5) then
    errorString = string.format("Invalid charging\ncurrent!\n\n%.3fA > 5.000A", chargeCurrent)
  elseif (numCells > 8) then
    errorString = string.format("Invalid cell count!\n\n%dS > 8S", numCells)
  elseif (numCells <= 0) then
    errorString = string.format("Invalid cell count!\n\n%dS <= 0S", numCells)   
  elseif (termCRate > 1) then
    errorString = string.format("Invalid term rate!\n\n%.2fC > 1C", termCRate)
  elseif (termCRate < 0) then -- term rate of 0 will disable termination stage, effectively float charging. setting to 0.99c will effectively be constant current only
    errorString = string.format("Invalid term rate!\n\n%.2fC < 0.00C", termCRate)
  elseif (voltsPerCellPrecharge >= voltsPerCell) then
    errorString = string.format("Invalid precharge\nvoltage!\n\n%.3fV >= %.3fV", voltsPerCellPrecharge, voltsPerCell)   
  elseif (prechargeCRate <= 0) then
    errorString = string.format("Invalid precharge\nrate!\n\n%.2fC <= 0.00C", prechargeCRate)
  elseif (prechargeCRate >= 1) then
    errorString = string.format("Invalid precharge\nrate!\n\n%.2fC >= 1.00C", prechargeCRate)   
  elseif (pcDeadband >= 1) then
    errorString = string.format("Invalid precharge\ndeadband!\n\n%.3fA >= 1.000A", pcDeadband)
  elseif (ccDeadband >= 1) then
    errorString = string.format("Invalid CC mode\ndeadband!\n\n%.3fA >= 1.000A", ccDeadband)    
  elseif (cvDeadband >= 1) then
    errorString = string.format("Invalid CV mode\ndeadband!\n\n%.3fA >= 1.000V", cvDeadband)
  elseif (tcDeadband >= 1) then
    errorString = string.format("Invalid charge termdeadband!\n\n%.3fA >= 1.000A", tcDeadband) 
  elseif (cableResistance >= 1) then
    errorString = string.format("Invalid cable\nresistance!\n\n%.3fOhm >= 1.000", cableResistance)     
  elseif (ccFallbackRate >= 2) then
    errorString = string.format("Invalid CC fallbackrate!\n\n%.2fC >= 2.00C", ccFallbackRate) 
  elseif (ccFallbackRate < 1) then
    errorString = string.format("Invalid CC fallbackrate!\n\n%.2fC < 1.00C", ccFallbackRate)
  elseif (undertemperatureThresholdC > overtemperatureThresholdC) then
    errorString = string.format("Invalid undertemp\nthreshold!\n(UTP > OTP)\n\n%d\1 > %d\1", undertemperatureThresholdC, overtemperatureThresholdC)
    errorDisplayTime = 5000
  else
    returnStatus = true
  end
  
  if returnStatus == false then
    if isSystemSoundsEnabled then
      buzzer.system(sysSound.alarm)
    end
    screen.showDialog("Config Error", errorString, errorDisplayTime, true, color.red)
  end
  
  errorString = nil
  errorDisplayTime = nil
  checkConfigs = nil
  package.loaded["lua/user/DC4S/lib/DC4S-checkConfigs"] = nil
  collectgarbage("collect") -- clean up memory
  return returnStatus
end