--[[DingoCharge for Shizuku Platform - Cell Voltage Configuration Menu
https://github.com/ginbot86/DingoCharge-Shizuku December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).
1.5.0: Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).
1.6.0: Added 3.3Vpc charge voltage for LiFePO4 storage (2023-12-11).
       Streamlined charge voltage menu code (2023-12-14).
       Changed header to point directly to official GitHub repository (2023-12-15).]]

function cfgVpc()
  screen.clear()
  local voltageTable = {2.5, 2.55, 2.6, 2.7, 2.8, 2.85, 2.9, 3, 3.2, 3.3, 3.4, 3.5, 3.6, 3.65, 3.7, 3.8, 3.85, 4, 4.1, 4.15, 4.2, 4.25, 4.3, 4.35, 4.4, 4.45, 4.5}
  
  -- Generate menu options from the voltage table
  local menuOptions = {string.format("Keep Current (%0.2fV)", voltsPerCell)}
  for _, voltage in ipairs(voltageTable) do
    local formattedVoltage
    if (10 * voltage) % 1 == 0 then -- truncate menu entry to 1 trailing digit past the decimal point if the hundredths place is zero (e.g. 4.1V vs. 4.15V)
      formattedVoltage = string.format("%0.1fV", voltage)
    else
      formattedVoltage = string.format("%0.2fV", voltage)
    end
    table.insert(menuOptions, formattedVoltage)
  end
  local vpcSel = screen.popMenu(menuOptions)

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
  menuOptions = nil
  voltage = nil
  formattedVoltage = nil
  vpcSel = nil
  cfgVpc = nil
  package.loaded["lua/user/DC4S/lib/DC4S-cfgVpc"] = nil
  collectgarbage("collect") -- clean up memory
end