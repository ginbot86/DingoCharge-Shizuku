--[[DingoCharge for Shizuku Platform - Aggressive Garbage Collection Configuration Menu
https://ripitapart.com December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).]]

function cfgAggressiveGc()
  if not screen.popYesOrNo("Warning! Changing\nthis setting may\naffect stability", color.yellow) then
    return
  end
  
  local aggressiveGcSel = 0
  local gcMenuValue = " "
  while true do
    if isAggressiveGcEnabled then
      gcMenuValue = string.format("Keep Current (%.0fK)", aggressiveGcThreshold / 1024)
    else
      gcMenuValue = "Keep Current (Disabled)"
    end  
    screen.clear()
    aggressiveGcSel = screen.popMenu({gcMenuValue, "Disabled", "4K", "8K", "16K", "32K", "Run GC Now", "Restore Defaults"})
    if aggressiveGcSel == 1 then
      isAggressiveGcEnabled = false
      break
    elseif aggressiveGcSel == 2 then
      isAggressiveGcEnabled = true
      aggressiveGcThreshold = 4096
      break
    elseif aggressiveGcSel == 3 then
      isAggressiveGcEnabled = true
      aggressiveGcThreshold = 8192
      break
    elseif aggressiveGcSel == 4 then
      isAggressiveGcEnabled = true
      aggressiveGcThreshold = 16384
      break
    elseif aggressiveGcSel == 5 then
      isAggressiveGcEnabled = true
      aggressiveGcThreshold = 32768
      break
    elseif aggressiveGcSel == 6 then
      local oldFreeHeap = sys.gFreeHeap()
      collectgarbage("collect")
      screen.popHint(string.format("Freed %d bytes", sys.gFreeHeap() - oldFreeHeap), 1000)
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
  if isAggressiveGcEnabled then
    screen.popHint(string.format("%.0fK", aggressiveGcThreshold / 1024), 1000)
  else
    screen.popHint("Disabled", 1000)
  end
  -- discard temporary variables
  aggressiveGcSel = nil
  gcMenuValue = nil
  oldFreeHeap = nil
  collectgarbage("collect") -- clean up memory
end