--[[DingoCharge for Shizuku Platform - Menu Library
https://ripitapart.com November 16, 2021.

Version history:
1.0.0: Initial public release (2022-06-30).
1.1.0: Fixed issue where setting cell count does not update precharge voltage. (2022-07-22).
       Fixed issue where precharge voltage did not display (correctly) during charge. (2022-10-12).
       Added CC fallback when in CV mode and charge current overshoots too much (2022-10-12).
       Added an option to display system temperature in Fahrenheit (2022-10-12).
       Added 2.5V/cell and 8S cell configurations (2022-10-13).
1.1.1: Fixed issue where some chargers' current-limiting conflicted with CV control loop (2022-10-15).
1.1.2: Fixed issue where setting 8S configuration would result in a Config Error message (2022-10-20).]]

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
  else
    returnStatus = true
  end
  return returnStatus
end

function cfgCells()
  screen.clear()
  local numCellsSel = screen.popMenu({string.format("Keep Current (%dS)",numCells),"1S","2S","3S","4S","5S","6S","7S","8S"})
  if ((numCellsSel > 0) and (numCellsSel < 255)) then
    numCells = numCellsSel
  end
  if (voltsPerCell <= 3) then
    voltsPerCellPrecharge = 1.5 -- LTO/Lithium Titanate
  elseif (voltsPerCell <= 3.6) then
    voltsPerCellPrecharge = 2.5 -- LiFePO4/Lithium Iron Phosphate
  elseif ((voltsPerCell > 3.6) and (numCells > 1)) then
    voltsPerCellPrecharge = 3 -- LiCoO2, NiCoMn, NiCoAl, LiNiO2, LiMn2O4 (typical "Li-ion")
  else
    voltsPerCellPrecharge = 3.3 -- LiCoO2 and others as above, but adjusted for PPS min 3.3V
  end
  screen.popHint(string.format("%dS",numCells),1000)
end

function cfgVpc()
  screen.clear()
  local voltageTable = {2.5, 2.55, 2.6, 2.7,2.8,2.85,2.9,3,3.2,3.4,3.5,3.6,3.65,3.7,3.8,3.85,4,4.1,4.15,4.2,4.25,4.3,4.35,4.4,4.45,4.5}
  local vpcSel = screen.popMenu({string.format("Keep Current (%0.2fV)",voltsPerCell),"2.5V","2.55V","2.6V","2.7V","2.8V","2.85V","2.9V","3.0V","3.2V","3.4V","3.5V","3.6V","3.65V","3.7V","3.8V","3.85V","4.0V","4.1V","4.15V","4.2V","4.25V","4.3V","4.35V","4.4V","4.45V","4.5V"})

  if ((vpcSel > 0) and (vpcSel < 255)) then
    voltsPerCell = voltageTable[vpcSel] 
  end
  if (voltsPerCell <= 3) then
    voltsPerCellPrecharge = 1.5 -- LTO/Lithium Titanate
  elseif (voltsPerCell <= 3.6) then
    voltsPerCellPrecharge = 2.5 -- LiFePO4/Lithium Iron Phosphate
  elseif ((voltsPerCell > 3.6) and (numCells > 1)) then
    voltsPerCellPrecharge = 3 -- LiCoO2, NiCoMn, NiCoAl, LiNiO2, LiMn2O4 (typical "Li-ion")
  else
    voltsPerCellPrecharge = 3.3 -- LiCoO2 and others as above, but adjusted for PPS min 3.3V
  end
  screen.popHint(string.format("%0.2fV/cell",voltsPerCell),1000)
end

function cfgPChgVpc()
  screen.clear()
  local voltageTable = {1.5,2.0,2.5,3,3.2,3.3,3.6}
  local vpcSel = screen.popMenu({string.format("Keep Current (%0.2fV)",voltsPerCellPrecharge),"1.5V","2.0V","2.5V","3.0V","3.2V","3.3V","3.6V"})
  if ((vpcSel > 0) and (vpcSel < 255)) then
    voltsPerCellPrecharge = voltageTable[vpcSel]
  end
  screen.popHint(string.format("%0.2fV/cell",voltsPerCellPrecharge),1000)
end

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
  if (chargeCurrent <= 0.5) then -- smaller deadband for low charge currents
    ccDeadband = 0.01
  else
    ccDeadband = 0.025
  end
  screen.popHint(string.format("%0.3fA", chargeCurrent), 1000)
end

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
end

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
end

function chargerSetup()
  local chgMenuSel = 0
  while true do
    screen.clear()
    chgMenuSel = screen.popMenu({"<       Main Menu       ",string.format("Cells: %dS",numCells),string.format("Voltage: %0.2fV/%0.2fV",voltsPerCell,(voltsPerCell * numCells)),string.format("Current: %0.3fA",chargeCurrent),string.format("Term Rate: %0.2fC/%.3fA",termCRate, termCRate * chargeCurrent),"Test Compatibility","Restore Defaults"})
    screen.clear()   
    if chgMenuSel == 1 then
      cfgCells()
    elseif chgMenuSel == 2 then
      cfgVpc()
    elseif chgMenuSel == 3 then
      cfgCurr()
    elseif chgMenuSel == 4 then
      cfgCRate()
    elseif chgMenuSel == 5 then
      testCompatibility(true)
    elseif chgMenuSel == 6 then
      if (screen.popYesOrNo("Restore defaults?",color.yellow)) then
        setDefaults()
        screen.popHint("Defaults Restored", 1000)
      end
    else
      break
    end
  end
end

function cfgPreChg()
  local preChgSel = 0
  while true do
    screen.clear()
    preChgSel = screen.popMenu({"<       Advanced...     ", string.format("PChg Volt: %0.2fV/%0.2fV",voltsPerCellPrecharge,(voltsPerCellPrecharge * numCells)), string.format("PChg Rate: %0.2fC/%.3fA",prechargeCRate, prechargeCRate * chargeCurrent), "Restore Defaults"})
    screen.clear()
    if preChgSel == 1 then
      cfgPChgVpc()
    elseif preChgSel == 2 then
      cfgPChgCRate()
    elseif preChgSel == 3 then
      if (screen.popYesOrNo("Restore defaults?",color.yellow)) then
      setPChgDefaults()
      screen.popHint("Defaults Restored", 1000)
      end
    else
      break
    end
  end
end

function cfgRefreshRate()
  local refreshRateSel = 0
  local refreshRateTable = {0, 50, 100, 200, 500, 1000}
  while true do
    screen.clear()
    refreshRateSel = screen.popMenu({string.format("Keep Current (%d ms)", refreshInterval), "Instant (0 ms)","20x/sec (50 ms)","10x/sec (100 ms)","5x/sec (200 ms)","2x/sec (500 ms)","1x/sec (1000 ms)","Restore Defaults"})
    if refreshRateSel > 0 and refreshRateSel < 7 then
      refreshInterval = refreshRateTable[refreshRateSel]
      break
    elseif refreshRateSel == 7 then
      if (screen.popYesOrNo("Restore defaults?",color.yellow)) then
        setRefreshDefaults()
        screen.popHint("Defaults Restored", 1000)
      end
    else
      break
    end
  end
  screen.popHint(string.format("%d ms", refreshInterval), 1000)
end

function cfgDeadbandEntry(varSel)
  local varValue = 0
  local varUnit = " "
  local varType = " "
  screen.clear()
  if (varSel == 1) then -- precharge
    varValue = pcDeadband
    varUnit = "A"
    varType = "Precharge"
  elseif (varSel == 2) then -- constant current
    varValue = ccDeadband
    varUnit = "A"
    varType = "CC Mode"  
  elseif (varSel == 3) then -- constant voltage
    varValue = cvDeadband
    varUnit = "V"
    varType = "CV Mode"
  elseif (varSel == 4) then -- terminate charge/current
    varValue = tcDeadband
    varUnit = "A"
    varType = "Chg Term"
  else
    return
  end
  
  local dbndSel = screen.popMenu({string.format("Keep Current (%.3f%s)",varValue,varUnit),string.format("Set %s Dband...",varType)})
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
    ccDeadband = varValue
  elseif (varSel == 3) then
    cvDeadband = varValue
  elseif (varSel == 4) then
    tcDeadband = varValue
  else
    return
  end
end

function cfgDeadband()
  local hystCfgSel = 0
  while true do
    screen.clear()
    hystCfgSel = screen.popMenu({"<       Advanced...     ", string.format("Precharge Dband: %0.3fA",pcDeadband), string.format("CC Mode Dband: %0.3fA",ccDeadband), string.format("CV Mode Dband: %0.3fV",cvDeadband), string.format("Chg Term Dband: %0.3fA",tcDeadband), "Restore Defaults"})
    screen.clear()
    if (hystCfgSel == 5) then
      if (screen.popYesOrNo("Restore defaults?",color.yellow)) then
        setDeadbandDefaults()
        screen.popHint("Defaults Restored", 1000)
      end
    elseif (hystCfgSel > 0) then
      cfgDeadbandEntry(hystCfgSel)
    else
      break
    end
  end
end

function cfgAggressiveGc()
  if not screen.popYesOrNo("Warning! Changing\nthis setting may\naffect stability", color.yellow) then
    return
  end
  
  local aggressiveGcSel = 0
  local gcMenuValue = " "
  while true do
    if isAggressiveGcEnabled then
      gcMenuValue = string.format("Keep Current (%.0fK)", aggressiveGcThreshold / 1024)
    else
      gcMenuValue = "Keep Current (Disabled)"
    end  
    screen.clear()
    aggressiveGcSel = screen.popMenu({gcMenuValue, "Disabled", "4K", "8K", "16K", "32K", "Run GC Now", "Restore Defaults"})
    if aggressiveGcSel == 1 then
      isAggressiveGcEnabled = false
      break
    elseif aggressiveGcSel == 2 then
      isAggressiveGcEnabled = true
      aggressiveGcThreshold = 4096
      break
    elseif aggressiveGcSel == 3 then
      isAggressiveGcEnabled = true
      aggressiveGcThreshold = 8192
      break
    elseif aggressiveGcSel == 4 then
      isAggressiveGcEnabled = true
      aggressiveGcThreshold = 16384
      break
    elseif aggressiveGcSel == 5 then
      isAggressiveGcEnabled = true
      aggressiveGcThreshold = 32768
      break
    elseif aggressiveGcSel == 6 then
      local oldFreeHeap = sys.gFreeHeap()
      collectgarbage("collect")
      screen.popHint(string.format("Freed %d bytes", sys.gFreeHeap() - oldFreeHeap), 1000)
      screen.popHint(string.format("Free mem: %dB", sys.gFreeHeap()), 1000)
      screen.popHint(string.format("Lowest: %dB", sys.gFreeHeapEver()), 1000)
    elseif aggressiveGcSel == 7 then
      if (screen.popYesOrNo("Restore defaults?", color.yellow)) then
        setAggressiveGcDefaults()
        screen.popHint("Defaults Restored", 1000)
      end
    else
      break
    end
  end
  if isAggressiveGcEnabled then
    screen.popHint(string.format("%.0fK", aggressiveGcThreshold / 1024), 1000)
  else
    screen.popHint("Disabled", 1000)
  end
end

function cfgCableRes()
  screen.clear()
  local resSel = 0
  
  while true do
    resSel = screen.popMenu({string.format("Keep Current (%0.3f\3)", cableResistance), "Set Cable Resistance...", "Restore Defaults"})
    screen.clear()
    local tmpRes = cableResistance
    if resSel == 1 then
      -- Integer, always <1 ohm
      tmpRes = 0
      -- Tenths
      tmpRes = tmpRes + (0.1 * screen.popMenu({string.format("%0.1fxx\3",tmpRes),string.format("%0.1fxx\3",tmpRes + 0.1),string.format("%0.1fxx\3",tmpRes + 0.2),string.format("%0.1fxx\3",tmpRes + 0.3),string.format("%0.1fxx\3",tmpRes + 0.4),string.format("%0.1fxx\3",tmpRes + 0.5),string.format("%0.1fxx\3",tmpRes + 0.6),string.format("%0.1fxx\3",tmpRes + 0.7),string.format("%0.1fxx\3",tmpRes + 0.8),string.format("%0.1fxx\3",tmpRes + 0.9)}))
      -- Hundredths
      tmpRes = tmpRes + (0.01 * screen.popMenu({string.format("%0.2fx\3",tmpRes),string.format("%0.2fx\3",tmpRes + 0.01),string.format("%0.2fx\3",tmpRes + 0.02),string.format("%0.2fx\3",tmpRes + 0.03),string.format("%0.2fx\3",tmpRes + 0.04),string.format("%0.2fx\3",tmpRes + 0.05),string.format("%0.2fx\3",tmpRes + 0.06),string.format("%0.2fx\3",tmpRes + 0.07),string.format("%0.2fx\3",tmpRes + 0.08),string.format("%0.2fx\3",tmpRes + 0.09)}))
      -- Thousandths
      tmpRes = tmpRes + (0.001 * screen.popMenu({string.format("%0.3f\3",tmpRes),string.format("%0.3f\3",tmpRes + 0.001),string.format("%0.3f\3",tmpRes + 0.002),string.format("%0.3f\3",tmpRes + 0.003),string.format("%0.3f\3",tmpRes + 0.004),string.format("%0.3f\3",tmpRes + 0.005),string.format("%0.3f\3",tmpRes + 0.006),string.format("%0.3f\3",tmpRes + 0.007),string.format("%0.3f\3",tmpRes + 0.008),string.format("%0.3f\3",tmpRes + 0.009)}))
      cableResistance = tmpRes
      break
    elseif resSel == 2 then
      if (screen.popYesOrNo("Restore defaults?", color.yellow)) then
        setCableResistanceDefaults()
        screen.popHint("Defaults Restored", 1000)
      end
    else
      break
    end
  end
    
  screen.popHint(string.format("%0.3f Ohm",cableResistance), 1000) -- font.f1616 has no Ω glyph
  if (cableResistance == 0.69) or (cableResistance == 0.069) then
    screen.popHint("Nice", 1000) -- Should I keep this? Eh, why not, it's a fun little Easter egg I guess.
  end
end

function cfgSounds()
  local cfgSoundSel = 0
  local soundMenuValue = " "
  while true do
    if isSystemSoundsEnabled then
      soundMenuValue = "On"
    else
      soundMenuValue = "Off"
    end
    
    cfgSoundSel = screen.popMenu{string.format("Keep Current (%s)", soundMenuValue), "Sounds Off", "Sounds On", "Restore Defaults"}
    if cfgSoundSel == 1 then
      isSystemSoundsEnabled = false
      break
    elseif cfgSoundSel == 2 then
      isSystemSoundsEnabled = true
      break
    elseif cfgSoundSel == 3 then
      if (screen.popYesOrNo("Restore defaults?",color.yellow)) then
        setSystemSoundDefaults()
        screen.popHint("Defaults Restored", 1000)    
      end
    else
      break
    end
  end
  
  if isSystemSoundsEnabled then
    screen.popHint("Sounds On", 1000)
  else
    screen.popHint("Sounds Off", 1000)
  end
end

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
end

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
end

function advancedMenu()
  local advMenuSel = 0
  local gcMenuEntry = " "
  local soundMenuEntry = " "
  local tempDisplayMenuEntry = " "
  while true do
    if isAggressiveGcEnabled then
      gcMenuEntry = string.format("Aggressive GC: %.0fK", aggressiveGcThreshold/1024)
    else
      gcMenuEntry = "Aggressive GC: Disabled"
    end
    if isSystemSoundsEnabled then
      soundMenuEntry = "System Sounds: On"
    else
      soundMenuEntry = "System Sounds: Off"
    end
    if isTempDisplayF then
      tempDisplayMenuEntry = "Temperature Display: \2" -- degF
    else
      tempDisplayMenuEntry = "Temperature Display: \1" -- degC
    end
    screen.clear()
    advMenuSel = screen.popMenu({"<       Main Menu       ", "Battery Precharge...", string.format("Cable Resistance: %.3f\3", cableResistance), string.format("CC Fallback: %.2fC", ccFallbackRate),"Chg Reg Deadband...",  tempDisplayMenuEntry, string.format("Refresh Rate: %d ms",refreshInterval), gcMenuEntry, soundMenuEntry, "Restore All Defaults"})
    screen.clear()
    if advMenuSel == 1 then
      cfgPreChg()
    elseif advMenuSel == 2 then
      cfgCableRes()
    elseif advMenuSel == 3 then
      cfgCcFallbackRate()
    elseif advMenuSel == 4 then
      cfgDeadband() 
    elseif advMenuSel == 5 then
      cfgTempDisplay()
    elseif advMenuSel == 6 then
      cfgRefreshRate()
    elseif advMenuSel == 7 then
      cfgAggressiveGc()
    elseif advMenuSel == 8 then
      cfgSounds()
    elseif advMenuSel == 9 then
      if (screen.popYesOrNo("Restore defaults?",color.yellow)) then
        resetAllDefaults()
        screen.popHint("Defaults Restored", 1000)
      end
    else
      break
    end
  end
end