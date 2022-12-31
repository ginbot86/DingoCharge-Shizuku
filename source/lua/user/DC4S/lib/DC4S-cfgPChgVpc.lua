--[[DingoCharge for Shizuku Platform - Cell Precharge Voltage Configuration Submenu
https://ripitapart.com December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).]]

function cfgPChgVpc()
  screen.clear()
  local voltageTable = {1.5,2.0,2.5,3,3.2,3.3,3.6}
  local vpcSel = screen.popMenu({string.format("Keep Current (%0.2fV)",voltsPerCellPrecharge),"1.5V","2.0V","2.5V","3.0V","3.2V","3.3V","3.6V"})
  if ((vpcSel > 0) and (vpcSel < 255)) then
    voltsPerCellPrecharge = voltageTable[vpcSel]
  end
  screen.popHint(string.format("%0.2fV/cell", voltsPerCellPrecharge), 1000)
  -- discard temporary variables
  voltageTable = nil
  vpcSel = nil
  collectgarbage("collect") -- clean up memory
end