--[[DingoCharge for Shizuku Platform - Wait-For-Battery Helper
https://github.com/ginbot86/DingoCharge-Shizuku January 10, 2026.

Version history:
1.7.0: Fixed issue where "Ready to charge. Plug in battery now" modal dialog could cause a PD timeout if the dialog is not acknowledged in time (2026-01-10).
       Replaced aforementioned modal dialog with an interstitial "Ready to charge" screen that maintains PD requests until battery connection is detected, or automatic timeout to enter the charge session (2026-01-10).]]

function waitForBattery()
  local batteryWaitTimerStart = sys.gTick() / 1000
  local batteryWaitTimerNow = sys.gTick() / 1000
  local returnStatus = true
  
  while (meter.readCurrent() < (pcDeadband / 2)) and ((batteryWaitTimerNow - batteryWaitTimerStart) < waitForBatteryTimeout) do -- use half of precharge deadband for highest sensitivity. timeout may occur if a BMS is currently in undervoltage lockout; starting charge will wake the BMS up once Vbus > Vbat
    if (pdSink.request(bestPdo, targetVoltage, maxCurrent) ~= pdSink.OK) then -- the user most likely unplugged the adapter or turned the PD COM switch off; use this to bail out of the loop
      if isSystemSoundsEnabled then
        buzzer.system(sysSound.alarm)
      end
      screen.clear()
      screen.showDialog("PD Request Failed", "Failed to receive\nready message from\nadapter!\n\nReturning to main\nmenu...", 5000, true, color.red)
      returnStatus = false
      break
    end
    
    batteryWaitTimerNow = sys.gTick() / 1000

    -- display modified version of main UI (all elements except the statusbar are greyed out but still update dynamically; colour scheme is basically the inverse of the main UI)
    screen.clear()
    -- volts, amps, watts
    drawMeter(0, 0, "Voltage", meter.readVoltage(), "V", color.grey)
    drawMeter(0, 39, "Current", readCurrentSigned(), "A", color.grey)
    drawMeter(0, 78, "Power", readPowerSigned(), "W", color.grey)
    -- charge settings
    screen.drawRect(94, 3, 159, 58, color.grey)
    screen.showString(97, 0, "-Chg. Set", font.f0508, color.grey) -- preceding hyphen creates 1 pixel space between border and title text on left
    if (((batteryWaitTimerNow - batteryWaitTimerStart) % 10) < 5) then -- alternate between showing precharge voltage and current
      screen.showString(103, 9, string.format("PC %0.3fA", prechargeCRate * chargeCurrent), font.f1212, color.grey)
    else
      if ((voltsPerCellPrecharge * numCells) < 10) then
        screen.showString(103, 9, string.format("PV %0.3fV", voltsPerCellPrecharge * numCells), font.f1212, color.grey)
      else
        screen.showString(103, 9, string.format("PV %0.2fV", voltsPerCellPrecharge * numCells), font.f1212, color.grey)
      end
    end
    screen.showString(103, 21, string.format("CC %0.3fA", chargeCurrent), font.f1212, color.grey)
    if ((voltsPerCell * numCells) < 10) then
      screen.showString(103, 33, string.format("CV %0.3fV", voltsPerCell * numCells), font.f1212, color.grey)
    else
      screen.showString(103, 33, string.format("CV %0.2fV", voltsPerCell * numCells), font.f1212, color.grey)
    end
    screen.showString(103, 45, string.format("TC %0.3fA", termCRate * chargeCurrent), font.f1212, color.grey)

    -- misc info (session timer, PD request voltage, tester temperature)
    screen.drawRect(94, 70, 159, 114, color.grey)
    screen.showString(97, 67, "-MiscInfo", font.f0508, color.grey)
    screen.showString(97, 76, string.format("-%02.0f:%02.0f:%02.0f", math.floor((waitForBatteryTimeout - (batteryWaitTimerNow - batteryWaitTimerStart)) / 3600), math.floor(((waitForBatteryTimeout - (batteryWaitTimerNow - batteryWaitTimerStart)) % 3600) / 60), math.floor((waitForBatteryTimeout - (batteryWaitTimerNow - batteryWaitTimerStart)) % 60)), font.f1212, color.grey) -- format timer seconds to hh:mm:ss. negative value denotes pending timeout before charge starts anyway

    screen.showString(103, 88, string.format("%0.2fVpd", targetVoltage), font.f1212, color.grey)
    if isTempDisplayF then
      if isExternalTemperatureEnabled then
        screen.showString(97, 101, string.format("%+0.2f\2ex", (readExternalTemperatureCelsius() * 1.8) + 32), font.f1212, color.grey)
      else
        screen.showString(97, 101, string.format("%+0.2f\2in", (sys.gBoardTempK() * 1.8) + 32), font.f1212, color.grey)
      end
    else
      if isExternalTemperatureEnabled then
        screen.showString(97, 101, string.format("%+0.2f\1ex", readExternalTemperatureCelsius()), font.f1212, color.grey)
      else  
        screen.showString(97, 101, string.format("%+0.2f\1in", sys.gBoardTempK()), font.f1212, color.grey) -- it's actually in Celsius, not Kelvin (or "kevin" according to the API docs)
      end
    end
    
    if (((batteryWaitTimerNow - batteryWaitTimerStart) % 4) < 2) then
      printStatusbar("Ready to charge", color.lightGreen, color.lightGreen)
    else
      printStatusbar("Plug in battery now", color.lightGreen, color.lightGreen)
    end
    
    if sys.gFreeHeap() < aggressiveGcThreshold then -- newer memory optimizations in DingoCharge means this probably will never need to activate, but better safe than sorry
      collectgarbage("collect")
    end
    
    -- flush updated framebuffer contents to screen
    screen.forceUpdate()
    delay.ms(refreshInterval) -- if refreshInterval is set to, e.g. 1 second, then the PD request rate will also be limited to the display rate. not a huge deal since we're not in regulation yet, just keeping PPS alive (max 10 seconds between requests)
  end

  batteryWaitTimerStart = nil
  batteryWaitTimerNow = nil
  waitForBattery = nil
  package.loaded["lua/user/DC4S/lib/DC4S-waitForBattery"] = nil
  collectgarbage("collect")    
  return returnStatus
end