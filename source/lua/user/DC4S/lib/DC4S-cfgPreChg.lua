--[[DingoCharge for Shizuku Platform - Precharge Configuration Parent Menu
https://ripitapart.com December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).
1.5.0: Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).]]

function cfgPreChg()
  local preChgSel = 0
  while true do
    screen.clear()
    preChgSel = screen.popMenu({"<       Advanced...     ", string.format("PChg Volt: %0.2fV/%0.2fV",voltsPerCellPrecharge,(voltsPerCellPrecharge * numCells)), string.format("PChg Rate: %0.2fC/%.3fA",prechargeCRate, prechargeCRate * chargeCurrent), "Restore Defaults"})
    screen.clear()
    if preChgSel == 1 then
      require "lua/user/DC4S/lib/DC4S-cfgPChgVpc"
      cfgPChgVpc()
    elseif preChgSel == 2 then
      require "lua/user/DC4S/lib/DC4S-cfgPChgCRate"
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
  -- discard temporary variables
  preChgSel = nil
  cfgPreChg = nil
  package.loaded["lua/user/DC4S/lib/DC4S-cfgPreChg"] = nil
  collectgarbage("collect") -- clean up memory
end