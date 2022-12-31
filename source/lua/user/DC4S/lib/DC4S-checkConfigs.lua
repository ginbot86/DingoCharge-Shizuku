--[[DingoCharge for Shizuku Platform - Configuration Checker
https://ripitapart.com December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).]]

function checkConfigs()
  local returnStatus = false
  if (chargeCurrent <= 0) then
    screen.showDialog("Config Error",string.format("Invalid charging\ncurrent!\n\n%.3fA <= 0.000A",chargeCurrent),3000,true,color.red)
  elseif (chargeCurrent > 5) then
    screen.showDialog("Config Error",string.format("Invalid charging\ncurrent!\n\n%.3fA > 5.000A",chargeCurrent),3000,true,color.red)
  elseif (numCells > 8) then
    screen.showDialog("Config Error",string.format("Invalid cell count!\n\n%dS > 8S",numCells),3000,true,color.red)
  elseif (numCells <= 0) then
    screen.showDialog("Config Error",string.format("Invalid cell count!\n\n%dS <= 0S",numCells),3000,true,color.red)   
  elseif (termCRate > 1) then
    screen.showDialog("Config Error",string.format("Invalid term rate!\n\n%.2fC > 1C",termCRate),3000,true,color.red)
  elseif (termCRate < 0) then -- term rate of 0 will disable termination stage, effectively float charging. setting to 0.99c will effectively be constant current only
    screen.showDialog("Config Error",string.format("Invalid term rate!\n\n%.2fC < 0.00C",termCRate),3000,true,color.red)
  elseif (voltsPerCellPrecharge >= voltsPerCell) then
    screen.showDialog("Config Error",string.format("Invalid precharge\nvoltage!\n\n%.3fV >= %.3fV",voltsPerCellPrecharge,voltsPerCell),3000,true,color.red)   
  elseif (prechargeCRate <= 0) then
    screen.showDialog("Config Error",string.format("Invalid precharge\nrate!\n\n%.2fC <= 0.00C",prechargeCRate),3000,true,color.red)
  elseif (prechargeCRate >= 1) then
    screen.showDialog("Config Error",string.format("Invalid precharge\nrate!\n\n%.2fC >= 1.00C",prechargeCRate),3000,true,color.red)   
  elseif (pcDeadband >= 1) then
    screen.showDialog("Config Error",string.format("Invalid precharge\ndeadband!\n\n%.3fA >= 1.000A",pcDeadband),3000,true,color.red)
  elseif (ccDeadband >= 1) then
    screen.showDialog("Config Error",string.format("Invalid CC mode\ndeadband!\n\n%.3fA >= 1.000A",ccDeadband),3000,true,color.red)    
  elseif (cvDeadband >= 1) then
    screen.showDialog("Config Error",string.format("Invalid CV mode\ndeadband!\n\n%.3fA >= 1.000V",cvDeadband),3000,true,color.red)
  elseif (tcDeadband >= 1) then
    screen.showDialog("Config Error",string.format("Invalid charge termdeadband!\n\n%.3fA >= 1.000A",tcDeadband),3000,true,color.red) 
  elseif (cableResistance >= 1) then
    screen.showDialog("Config Error",string.format("Invalid cable\nresistance!\n\n%.3fOhm >= 1.000",cableResistance),3000,true,color.red)     
  elseif (ccFallbackRate >= 2) then
    screen.showDialog("Config Error",string.format("Invalid CC fallbackrate!\n\n%.2fC >= 2.00C",ccFallbackRate),3000,true,color.red) 
  elseif (ccFallbackRate < 1) then
    screen.showDialog("Config Error",string.format("Invalid CC fallbackrate!\n\n%.2fC < 1.00C",ccFallbackRate),3000,true,color.red)
  elseif (undertemperatureThresholdC > overtemperatureThresholdC) then
    screen.showDialog("Config Error",string.format("Invalid undertemp\nthreshold!\n(UTP > OTP)\n\n%d\1 > %d\1",undertemperatureThresholdC,overtemperatureThresholdC),5000,true,color.red)
  else
    returnStatus = true
  end
  collectgarbage("collect") -- clean up memory
  return returnStatus
end