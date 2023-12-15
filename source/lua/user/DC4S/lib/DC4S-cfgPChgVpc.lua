--[[DingoCharge for Shizuku Platform - Cell Precharge Voltage Configuration Submenu
https://github.com/ginbot86/DingoCharge-Shizuku December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).
1.5.0: Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).
1.6.0: Streamlined charge voltage menu code (2023-12-14).
       Changed header to point directly to official GitHub repository (2023-12-15).]]

function cfgPChgVpc()
  screen.clear()
  local voltageTable = {1.5, 2.0, 2.5, 3, 3.2, 3.3, 3.6}
  
  -- Generate menu options from the voltage table
  local menuOptions = {string.format("Keep Current (%0.2fV)", voltsPerCellPrecharge)}
  for _, voltage in ipairs(voltageTable) do
    local formattedVoltage
    if (10 * voltage) % 1 == 0 then -- truncate menu entry to 1 trailing digit past the decimal point if the hundredths place is zero (e.g. 4.1V)
      formattedVoltage = string.format("%0.1fV", voltage)
    else
      formattedVoltage = string.format("%0.2fV", voltage)
    end
    table.insert(menuOptions, formattedVoltage)
  end
  local vpcSel = screen.popMenu(menuOptions)

  if ((vpcSel > 0) and (vpcSel < 255)) then
    voltsPerCellPrecharge = voltageTable[vpcSel] 
  end

  screen.popHint(string.format("%0.2fV/cell", voltsPerCellPrecharge), 1000)
  
  -- discard temporary variables
  voltageTable = nil
  menuOptions = nil
  voltage = nil
  formattedVoltage = nil
  vpcSel = nil
  cfgPChgVpc = nil
  package.loaded["lua/user/DC4S/lib/DC4S-cfgPChgVpc"] = nil
  collectgarbage("collect") -- clean up memory
end