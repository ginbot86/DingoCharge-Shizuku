--[[DingoCharge for Shizuku Platform - Deadband Configuration Parent Menu
https://github.com/ginbot86/DingoCharge-Shizuku December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).
1.5.0: Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).
1.6.0: Changed header to point directly to official GitHub repository (2023-12-15).]]

function cfgDeadband()
  local dbandCfgSel = 0
  while true do
    screen.clear()
    dbandCfgSel = screen.popMenu({"<       Advanced...     ", string.format("Precharge Dband: %0.3fA",pcDeadband), string.format("CC Norm Dband: %0.3fA",ccDeadbandNormal), string.format("CC Low Dband: %0.3fA",ccDeadbandLow), string.format("CC Low Thresh: %.3fA",ccDeadbandThreshold), string.format("CV Dband: %0.3fV",cvDeadband), string.format("Chg Term Dband: %0.3fA",tcDeadband), "Restore Defaults"})
    screen.clear()
    if (dbandCfgSel == 7) then
      if (screen.popYesOrNo("Restore defaults?",color.yellow)) then
        setDeadbandDefaults()
        screen.popHint("Defaults Restored", 1000)
      end
    elseif (dbandCfgSel > 0 and dbandCfgSel < 255) then
      require "lua/user/DC4S/lib/DC4S-cfgDeadbandEntry"
      cfgDeadbandEntry(dbandCfgSel)
    else
      break
    end
  end
  -- discard temporary variables
  dbandCfgSel = nil
  cfgDeadband = nil
  package.loaded["lua/user/DC4S/lib/DC4S-cfgDeadband"] = nil
  collectgarbage("collect") -- clean up memory
end