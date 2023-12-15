--[[DingoCharge for Shizuku Platform - Screen Refresh Configuration Menu
https://github.com/ginbot86/DingoCharge-Shizuku December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).
1.5.0: Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).
1.6.0: Changed header to point directly to official GitHub repository (2023-12-15).]]

function cfgRefreshRate()
  local refreshRateSel = 0
  local refreshRateTable = {0, 50, 100, 200, 500, 1000}
  while true do
    screen.clear()
    refreshRateSel = screen.popMenu({string.format("Keep Current (%d ms)", refreshInterval), "Instant (0 ms)","20x/sec (50 ms)","10x/sec (100 ms)","5x/sec (200 ms)","2x/sec (500 ms)","1x/sec (1000 ms)","Restore Defaults"})
    if refreshRateSel > 0 and refreshRateSel < 7 then
      refreshInterval = refreshRateTable[refreshRateSel]
      break
    elseif refreshRateSel == 7 then
      if (screen.popYesOrNo("Restore defaults?",color.yellow)) then
        setRefreshDefaults()
        screen.popHint("Defaults Restored", 1000)
      end
    else
      break
    end
  end
  screen.popHint(string.format("%d ms", refreshInterval), 1000)
  -- discard temporary variables
  refreshRateSel = nil
  refreshRateTable = nil
  cfgRefreshRate = nil
  package.loaded["lua/user/DC4S/lib/DC4S-cfgRefreshRate"] = nil
  collectgarbage("collect") -- clean up memory
end