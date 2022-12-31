--[[DingoCharge for Shizuku Platform - Charger Setup Configuration Menu
https://ripitapart.com December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).]]

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
  collectgarbage("collect") -- clean up memory
end