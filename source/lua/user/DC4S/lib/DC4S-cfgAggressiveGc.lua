--[[DingoCharge for Shizuku Platform - Aggressive Garbage Collection Configuration Menu
https://ripitapart.com December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).
1.5.0: Changed how aggressive GC is enabled/disabled; set aggressiveGcThreshold to 0 instead of isAggressiveGcEnabled to false (not that you should do this anyway...) (2023-01-08).
       Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).]]

function cfgAggressiveGc()
  if not screen.popYesOrNo("Warning! Changing\nthis setting may\naffect stability", color.yellow) then
    return
  end

  local aggressiveGcSel = 0
  local gcMenuValue = " "
  local oldFreeHeap = 0
  while true do
    if aggressiveGcThreshold == 0 then
      gcMenuValue = "Keep Current (Disabled)"
    else
      gcMenuValue = string.format("Keep Current (%.0fK)", aggressiveGcThreshold / 1024)
    end  
    screen.clear()
    aggressiveGcSel = screen.popMenu({gcMenuValue, "Disabled", "4K", "8K", "16K", "32K", "Run GC Now", "Restore Defaults"})
    if aggressiveGcSel == 1 then
      aggressiveGcThreshold = 0
      break
    elseif aggressiveGcSel == 2 then
      aggressiveGcThreshold = 4096
      break
    elseif aggressiveGcSel == 3 then
      aggressiveGcThreshold = 8192
      break
    elseif aggressiveGcSel == 4 then
      aggressiveGcThreshold = 16384
      break
    elseif aggressiveGcSel == 5 then
      aggressiveGcThreshold = 32768
      break
    elseif aggressiveGcSel == 6 then
      oldFreeHeap = sys.gFreeHeap()
      collectgarbage("collect")
      screen.popHint(string.format("Freed %dB", sys.gFreeHeap() - oldFreeHeap), 1000)
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
  if aggressiveGcThreshold == 0 then
    screen.popHint("Disabled", 1000)
  else
    screen.popHint(string.format("%.0fK", aggressiveGcThreshold / 1024), 1000)
  end
  -- discard temporary variables and unload function
  aggressiveGcSel = nil
  gcMenuValue = nil
  oldFreeHeap = nil
  cfgAggressiveGc = nil
  package.loaded["lua/user/DC4S/lib/DC4S-cfgAggressiveGc"] = nil
  collectgarbage("collect") -- clean up memory
end