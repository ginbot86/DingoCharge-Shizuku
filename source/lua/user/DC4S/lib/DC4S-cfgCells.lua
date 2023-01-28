--[[DingoCharge for Shizuku Platform - Cell Count Configuration Menu
https://ripitapart.com December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).
1.5.0: Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).]]

function cfgCells()
  screen.clear()
  local numCellsSel = screen.popMenu({string.format("Keep Current (%dS)",numCells),"1S","2S","3S","4S","5S","6S","7S","8S"})
  if ((numCellsSel > 0) and (numCellsSel < 255)) then
    numCells = numCellsSel
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
  screen.popHint(string.format("%dS", numCells), 1000)
  -- discard temporary variables
  numCellsSel = nil
  cfgCells = nil
  package.loaded["lua/user/DC4S/lib/DC4S-cfgCells"] = nil
  collectgarbage("collect") -- clean up memory
end