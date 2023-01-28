--[[DingoCharge for Shizuku Platform - Cell Voltage Configuration Menu
https://ripitapart.com December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).
1.5.0: Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).]]

function cfgVpc()
  screen.clear()
  local voltageTable = {2.5, 2.55, 2.6, 2.7, 2.8, 2.85, 2.9, 3, 3.2, 3.4, 3.5, 3.6, 3.65, 3.7, 3.8, 3.85, 4, 4.1, 4.15, 4.2, 4.25, 4.3, 4.35, 4.4, 4.45, 4.5} -- there has to be a better way to do this...
  local vpcSel = screen.popMenu({string.format("Keep Current (%0.2fV)", voltsPerCell), "2.5V", "2.55V", "2.6V", "2.7V", "2.8V", "2.85V", "2.9V", "3.0V", "3.2V", "3.4V", "3.5V", "3.6V", "3.65V", "3.7V", "3.8V", "3.85V", "4.0V", "4.1V", "4.15V", "4.2V", "4.25V", "4.3V", "4.35V", "4.4V", "4.45V", "4.5V"})

  if ((vpcSel > 0) and (vpcSel < 255)) then
    voltsPerCell = voltageTable[vpcSel] 
  end
  if (voltsPerCell <= 3) then
    voltsPerCellPrecharge = 1.5 -- LTO/Lithium Titanate
  elseif (voltsPerCell <= 3.65) then
    voltsPerCellPrecharge = 2.5 -- LiFePO4/Lithium Iron Phosphate
  elseif ((voltsPerCell > 3.65) and (numCells > 1)) then
    voltsPerCellPrecharge = 3 -- LiCoO2, NiCoMn, NiCoAl, LiNiO2, LiMn2O4 (typical "Li-ion")
  else
    voltsPerCellPrecharge = 3.3 -- LiCoO2 and others as above, but adjusted for PPS min 3.3V
  end
  screen.popHint(string.format("%0.2fV/cell", voltsPerCell), 1000)
  -- discard temporary variables
  voltageTable = nil
  vpcSel = nil
  cfgVpc = nil
  package.loaded["lua/user/DC4S/lib/DC4S-cfgVpc"] = nil
  collectgarbage("collect") -- clean up memory
end