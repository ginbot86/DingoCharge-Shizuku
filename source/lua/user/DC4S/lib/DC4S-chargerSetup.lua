--[[DingoCharge for Shizuku Platform - Charger Setup Configuration Menu
https://github.com/ginbot86/DingoCharge-Shizuku December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).
1.5.0: Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).
1.6.0: Split off compatibility test into a separate file which unloads upon termination to conserve memory (2023-02-02).
       Changed header to point directly to official GitHub repository (2023-12-15).]]

function chargerSetup()
  local chgMenuSel = 0
  while true do
    screen.clear()
    chgMenuSel = screen.popMenu({"<       Main Menu       ",string.format("Cells: %dS",numCells),string.format("Voltage: %0.2fV/%0.2fV",voltsPerCell,(voltsPerCell * numCells)),string.format("Current: %0.3fA",chargeCurrent),string.format("Term Rate: %0.2fC/%.3fA",termCRate, termCRate * chargeCurrent),"Test Compatibility","Restore Defaults"})
    screen.clear()   
    if chgMenuSel == 1 then
      require "lua/user/DC4S/lib/DC4S-cfgCells"
      cfgCells()
    elseif chgMenuSel == 2 then
      require "lua/user/DC4S/lib/DC4S-cfgVpc"
      cfgVpc()
    elseif chgMenuSel == 3 then
      require "lua/user/DC4S/lib/DC4S-cfgCurr"
      cfgCurr()
    elseif chgMenuSel == 4 then
      require "lua/user/DC4S/lib/DC4S-cfgCRate"
      cfgCRate()
    elseif chgMenuSel == 5 then
      require "lua/user/DC4S/lib/DC4S-testCompatibility"
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
  -- clean up memory
  chgMenuSel = nil
  chargerSetup = nil
  package.loaded["lua/user/DC4S/lib/DC4S-chargerSetup"] = nil
  collectgarbage("collect")
end