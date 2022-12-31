--[[DingoCharge for Shizuku Platform - Screen Refresh Configuration Menu
https://ripitapart.com December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).]]

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
  collectgarbage("collect") -- clean up memory
end