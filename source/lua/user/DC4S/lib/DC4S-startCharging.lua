--[[DingoCharge for Shizuku Platform - Main Battery Charge Control
https://github.com/ginbot86/DingoCharge-Shizuku January 27, 2023.

Version history:
1.5.0: Split off charge control function into a separate file which unloads upon termination to conserve memory (2023-01-27).
1.6.0: Added check to verify that the battery voltage is at least 3 volts (no PPS adapter will likely support less than this) (2023-01-29).
       Removed redundant aggressive GC threshold check while charging (2023-02-02).
       Split off compatibility test into a separate file which unloads upon termination to conserve memory (2023-02-02).
       Added more system sounds for charge errors and prompts (2023-11-01).
       Added check to verify that the battery voltage does not already exceed the configured charging voltage (2023-11-01).
       Fixed issue where elapsed time (and Time Limit) advances 10x faster than intended on firmware v1.00.62 (2023-12-11).
       Fixed issue where the Chg. Set display does not flip between precharge current and voltage once the session timer stops (2023-12-11).
       Changed header to point directly to official GitHub repository (2023-12-15).
1.7.0: Fixed issue where error sound would not play if an initial PD request failed (2024-01-17).
       Fixed issue where "Ready to charge. Plug in battery now" modal dialog could cause a PD timeout if the dialog is not acknowledged in time (2026-01-10).
       Replaced aforementioned modal dialog with an interstitial "Ready to charge" screen that maintains PD requests until battery connection is detected, or automatic timeout to enter the charge session (2026-01-10).
       Added PD request latency measurement in statusbar (2026-01-10).
       Tweaked charge stage transition thresholds (2026-01-10).]]

function startCharging()

  isSessionTimerClearable = true
  if isChargeStarted then -- allow session timer to be reset before starting the actual charge cycle
    if not screen.popYesOrNo("Detected previous\ncharge cycle. Resettimer to zero?", color.lightGreen) then
      isSessionTimerClearable = false
    end
  end
  
  meter.setDataSource(meter.INSTANT) -- using the API's meter filtering modes causes regulation instability
  
  if screen.popYesOrNo("Unplug adapter thenplug in battery\n\nNo battery voltage?Plug in adapter", color.cyan) then
  
    if (meter.readVoltage() > voltsPerCell * numCells) then -- verify battery voltage does not already exceed the configured charging voltage
      if isSystemSoundsEnabled then
        buzzer.system(sysSound.alarm)
      end
      screen.showDialog("Config Error", string.format("Battery voltage toohigh!\n\n%.3fV > %.3fV", meter.readVoltage(), voltsPerCell * numCells), 3000, true, color.red)
      startCharging = nil
      package.loaded["lua/user/DC4S/lib/DC4S-startCharging"] = nil
      collectgarbage("collect")
      return false
    end
    
    while (meter.readVoltage() < 3) do -- verify battery voltage is present, otherwise a "voltage too low for precharge" error will occur after compatibility testing
      if isSystemSoundsEnabled then
        buzzer.system(sysSound.alarm)
      end
      if screen.popYesOrNo(string.format("Battery is not\nplugged in! (%.2fV)\n* Confirm: go back\n* Cancel: retry", meter.readVoltage()), color.red) then
        startCharging = nil
        package.loaded["lua/user/DC4S/lib/DC4S-startCharging"] = nil
        collectgarbage("collect")
        return false
      end
    end
    
    initialVbat = meter.readVoltage()
    screen.popHint(string.format("Vbat = %.3fV", initialVbat), 1000)
  else
    startCharging = nil
    package.loaded["lua/user/DC4S/lib/DC4S-startCharging"] = nil
    collectgarbage("collect")
    return false
  end

  require "lua/user/DC4S/lib/DC4S-testCompatibility"
  if (testCompatibility(false) == true) then
    if (initialVbat < minVoltage) then -- cannot safely control precharge current if battery voltage is less than PPS minimum
      if isSystemSoundsEnabled then
        buzzer.system(sysSound.alarm)
      end
      screen.clear()
      screen.showDialog("Precharge Failed", string.format("Battery voltage toolow to precharge!\n\nVbat < PPS min out:%.3fV < %.3fV", initialVbat, minVoltage), 5000, true, color.red)
      closePdSession()
      startCharging = nil
      package.loaded["lua/user/DC4S/lib/DC4S-startCharging"] = nil
      collectgarbage("collect")
      return false
    end
    if (pdSink.request(bestPdo, initialVbat, maxCurrent) == pdSink.OK) then
      initialVbus = meter.readVoltage()
      vbusOffset = initialVbus - initialVbat
      targetVoltage = (math.ceil((initialVbat - vbusOffset) / 0.02) * 0.02) + 0.04 -- round up to nearest 0.02 and go up 2 steps
      if (targetVoltage > maxVoltage) then
        targetVoltage = maxVoltage
      elseif (targetVoltage < minVoltage) then
        targetVoltage = minVoltage
      end
      
      if (pdSink.request(bestPdo, targetVoltage, maxCurrent) ~= pdSink.OK) then
        if isSystemSoundsEnabled then
          buzzer.system(sysSound.alarm)
        end
        screen.clear()
        screen.showDialog("PD Request Failed", "Failed to receive\nready message from\nadapter!", 5000, true, color.red)
        closePdSession()  
        startCharging = nil
        package.loaded["lua/user/DC4S/lib/DC4S-startCharging"] = nil
        collectgarbage("collect")        
        return false
      end 
      
      if isSystemSoundsEnabled then
        buzzer.system(sysSound.hint)
      end

      if (initialVbat < (voltsPerCellPrecharge * numCells)) then
        chargeStage = 1 -- precharge
        regLoopMode = 0 -- CC mode, 1 for CV
        setpointDeadband = pcDeadband
        regLoopCurrent = prechargeCRate * chargeCurrent
        regLoopVoltage = voltsPerCellPrecharge * numCells
      else
        chargeStage = 2 -- CC
        regLoopMode = 0
        regLoopCurrent = chargeCurrent
        regLoopVoltage = voltsPerCell * numCells
        setpointDeadband = ccDeadband
      end

      require "lua/user/DC4S/lib/DC4S-waitForBattery"
      if not waitForBattery() then -- display modified UI, keep PD requests alive, and wait until charge current is detected, or timer runs out
        closePdSession()
        startCharging = nil
        package.loaded["lua/user/DC4S/lib/DC4S-startCharging"] = nil
        collectgarbage("collect")
        return false
      end

      vbusOffset = nil
      initialVbat = nil
      initialVbus = nil
      
      if isSessionTimerClearable then
        startSessionTimer()
      else
        updateSessionTimer()
        resumeSessionTimer()
      end

      isChargeStarted = true
      timerFineStart = sys.gTick() 
      timerFineNow = sys.gTick() + 2000 -- allow screen to be updated on first loop iteration
      isStatusbarOverridden = false
      isOvertemperatureFault = false
      isUndertemperatureFault = false
      lastChargeStage = 0
      
      while true do -- main program/UI loop
        loopIterationTimerStart = sys.gTick()
        -- charge regulation
        if regLoopMode == 0 then -- constant-current mode
          -- test for transfer to CC or CV mode
          if (meter.readVoltage() > (regLoopVoltage + (readCurrentSigned() * cableResistance))) then -- try transitioning in the middle of the setpoint deadband range rather than as soon as possible
            if (chargeStage == 1) then -- move to CC stage
              chargeStage = 2
              regLoopCurrent = chargeCurrent
              regLoopVoltage = voltsPerCell * numCells
              setpointDeadband = ccDeadband
            elseif (chargeStage == 2) then -- move to CV stage
              chargeStage = 3
              regLoopMode = 1
              regLoopCurrent = termCRate * chargeCurrent
              regLoopVoltage = voltsPerCell * numCells
              setpointDeadband = cvDeadband
            else
              regLoopCurrent = 0
            end
          end
          -- alternate CC->CV transition check for an edge case: if we are in CC stage, our CV AND PD request voltages are maxed out, and present current going into the battery is less than 80% of CC current, then we are effectively in CV stage (so we need to start thinking like it)
          if chargeStage == 2 and voltsPerCell * numCells == maxVoltage and targetVoltage == maxVoltage and meter.readCurrent() < chargeCurrent * 0.8 then
            chargeStage = 3
            regLoopMode = 1
            regLoopCurrent = termCRate * chargeCurrent
            regLoopVoltage = voltsPerCell * numCells
            setpointDeadband = cvDeadband
          end
          setpointDeviation = readCurrentSigned() - regLoopCurrent
        elseif regLoopMode == 1 then -- constant-voltage mode
        -- test for transfer to idle mode upon termination
          if (meter.readCurrent() < (regLoopCurrent - tcDeadband)) then -- delay termination until we're at the lower edge of the deadband
            chargeStage = 4
            regLoopMode = 0
            regLoopCurrent = 0
            setpointDeadband = tcDeadband
            stopSessionTimer()
            if isSystemSoundsEnabled then
              buzzer.system(sysSound.finished)
            end
            isStatusbarOverridden = true
            statusbarOverrideColor = color.green
            statusbarOverrideText = "Stopped: Term rate reached"
          end
          setpointDeviation = meter.readVoltage() - regLoopVoltage - (readCurrentSigned() * cableResistance)
        else  -- this should never happen
          chargeStage = 0
          regLoopMode = 0
          regLoopCurrent = 0
          setpointDeadband = tcDeadband
          isStatusbarOverridden = true
          statusbarOverrideColor = color.red        
          statusbarOverrideText = "Stopped: Invalid state"
          if isSystemSoundsEnabled then
            buzzer.system(sysSound.alarm)
          end
          stopSessionTimer()
        end
        
        if (math.abs(setpointDeviation) > setpointDeadband) then
          if setpointDeviation > 0 then
            targetVoltage = targetVoltage - 0.02
          else
            targetVoltage = targetVoltage + 0.02
          end
        end
        
        if (chargeStage == 4 or chargeStage == 0) and meter.readVoltage() > voltsPerCell * numCells then -- safety check: prevent voltage from drifting too high after charge termination
          targetVoltage = targetVoltage - 0.04
        end

        if chargeStage == 3 and meter.readCurrent() > (ccFallbackRate * chargeCurrent) then -- safety check: prevent excessive current overshoot when switching from CC to CV stage
          chargeStage = 2
          regLoopMode = 0
          regLoopCurrent = chargeCurrent
          regLoopVoltage = voltsPerCell * numCells
          setpointDeadband = ccDeadband
        end
        
        if chargeStage > 0 and chargeStage < 4 and isExternalTemperatureEnabled and ((isOvertemperatureEnabled and readExternalTemperatureCelsius() > overtemperatureThresholdC) or (isUndertemperatureEnabled and readExternalTemperatureCelsius() < undertemperatureThresholdC)) then -- safety check: prevent battery from charging if temperature out of range
          lastChargeStage = chargeStage
          chargeStage = 0
          regLoopMode = 0
          regLoopCurrent = 0
          setpointDeadband = tcDeadband
          isStatusbarOverridden = true
          if readExternalTemperatureCelsius() > overtemperatureThresholdC - temperatureProtectionHysteresisC then
            isOvertemperatureFault = true
            if isOvertemperatureRecoveryEnabled then
              statusbarOverrideColor = color.orange
              statusbarOverrideText = "Paused: Overtemperature"
            else
              statusbarOverrideColor = color.red
              statusbarOverrideText = "Stopped: Overtemperature"
            end
          elseif readExternalTemperatureCelsius() < undertemperatureThresholdC + temperatureProtectionHysteresisC then
            isUndertemperatureFault = true
            if isUndertemperatureRecoveryEnabled then
              statusbarOverrideColor = color.orange
              statusbarOverrideText = "Paused: Undertemperature"
            else
              statusbarOverrideColor = color.red
              statusbarOverrideText = "Stopped: Undertemperature"
            end
          else
            statusbarOverrideText = "Stopped: Temperature fault" -- if somehow the temperature fixes itself as we try to determine what the fault was
            isOvertemperatureFault = true
            isUndertemperatureFault = true -- set both because the exact temperature fault was "forgotten"
          end
          if isSystemSoundsEnabled then
            buzzer.system(sysSound.alarm)
          end
          stopSessionTimer()
        end
        
        if chargeStage > 0 and chargeStage < 4 and termCRate > 0 and timeLimitHours > 0 and ((sessionTimerNow - sessionTimerStart) / 3600) > timeLimitHours then -- safety check: stop charging if it's taking too long to finish
          chargeStage = 0
          regLoopMode = 0
          regLoopCurrent = 0
          setpointDeadband = tcDeadband
          isStatusbarOverridden = true
          statusbarOverrideColor = color.red
          statusbarOverrideText = string.format("Stopped: Timed out (%dh)", timeLimitHours)
          if isSystemSoundsEnabled then
            buzzer.system(sysSound.alarm)
          end
          stopSessionTimer()          
        end
        
        if chargeStage == 0 and ((isOvertemperatureFault and isOvertemperatureRecoveryEnabled) or (isUndertemperatureFault and isUndertemperatureRecoveryEnabled)) then
          if (isOvertemperatureFault and readExternalTemperatureCelsius() < overtemperatureThresholdC - temperatureProtectionHysteresisC) or (isUndertemperatureFault and readExternalTemperatureCelsius() > undertemperatureThresholdC + temperatureProtectionHysteresisC) then -- if recovery is enabled, resume charging if the conditions are met
            if isOvertemperatureFault then
              isOvertemperatureFault = false
            elseif isUndertemperatureFault then
              isUndertemperatureFault = false
            end
            resumeSessionTimer()
              
            isStatusbarOverridden = false
            if lastChargeStage == 1 then
              chargeStage = 1 -- precharge
              regLoopMode = 0 -- CC mode, 1 for CV
              setpointDeadband = pcDeadband
              regLoopCurrent = prechargeCRate * chargeCurrent
              regLoopVoltage = voltsPerCellPrecharge * numCells
            elseif lastChargeStage == 2 then
              chargeStage = 2 -- CC
              regLoopMode = 0
              regLoopCurrent = chargeCurrent
              regLoopVoltage = voltsPerCell * numCells
              setpointDeadband = ccDeadband
            elseif lastChargeStage == 3 then
              chargeStage = 3
              regLoopMode = 1
              regLoopCurrent = termCRate * chargeCurrent
              regLoopVoltage = voltsPerCell * numCells
              setpointDeadband = cvDeadband
            end
          end
        end

        -- ensure requested voltage is within PDO bounds
        if (targetVoltage > maxVoltage) then
          targetVoltage = maxVoltage
        elseif (targetVoltage < minVoltage) then
          targetVoltage = minVoltage
        end
        
        pdRequestTimerStart = sys.gTick()
        if (pdSink.request(bestPdo, targetVoltage, maxCurrent) ~= pdSink.OK) then -- this is the only way to allow exiting the charge session, but also breaks the regulation since new PD requests cannot be sent while waiting for user input...
          if isSystemSoundsEnabled then
            buzzer.system(sysSound.alarm)
          end
          if screen.popYesOrNo("PD request failed!\n\n* Confirm: exit to\n  main menu\n* Cancel: retry", color.red) then
            break
          end
        end      
        pdRequestTimerNow = sys.gTick() -- technically the PD request timer will continue advancing while in the modal dialog, but that's inconsequential since we're either exiting, or the timer will get overwritten on the next loop iteration anyway, and in the worst case that would be visible for 1 display refresh interval

        
        if ((timerFineNow - timerFineStart) >= refreshInterval) then         
          screen.clear()
          -- volts, amps, watts
          drawMeter(0, 0, "Voltage", meter.readVoltage(), "V", color.yellow)
          drawMeter(0, 39, "Current", readCurrentSigned(), "A", color.cyan)
          drawMeter(0, 78, "Power", readPowerSigned(), "W", color.red)
          -- charge settings
          screen.drawRect(94, 3, 159, 58, color.lightGreen)
          screen.showString(97, 0, "-Chg. Set", font.f0508, color.lightGreen) -- preceding hyphen creates 1 pixel space between border and title text on left
          if (isSessionTimerEnabled and (((sys.gTick() / 1000) - sessionTimerStart) % 10) or ((sys.gTick() / 1000) % 10)) < 5 then -- alternate between showing precharge voltage and current. if session timer is stopped, then ignore the session timer start time (this line would otherwise freeze on either PC or PV display). there may be a transient effect where the display flips between PC and PV for a brief moment when the session timer stops, but this is purely a cosmetic glitch that occurs during the start->stop transition. Shizuku firmware v1.00.62 caused os.date() to advance 10 times faster than it should, so all calls to os.date() are now replaced with calls to sys.gTick() which has a 1ms granularity
            screen.showString(103, 9, string.format("PC %0.3fA", prechargeCRate * chargeCurrent), font.f1212, color.lightGreen)
          else
            if ((voltsPerCellPrecharge * numCells) < 10) then
              screen.showString(103, 9, string.format("PV %0.3fV", voltsPerCellPrecharge * numCells), font.f1212, color.lightGreen)
            else
              screen.showString(103, 9, string.format("PV %0.2fV", voltsPerCellPrecharge * numCells), font.f1212, color.lightGreen)
            end
          end
          screen.showString(103, 21, string.format("CC %0.3fA", chargeCurrent), font.f1212, color.lightGreen)
          if ((voltsPerCell * numCells) < 10) then
            screen.showString(103, 33, string.format("CV %0.3fV", voltsPerCell * numCells), font.f1212, color.lightGreen)
          else
            screen.showString(103, 33, string.format("CV %0.2fV", voltsPerCell * numCells), font.f1212, color.lightGreen)
          end
          screen.showString(103, 45, string.format("TC %0.3fA", termCRate * chargeCurrent), font.f1212, color.lightGreen)
          if (chargeStage > 0) then -- show marker to indicate which charge stage is active
            screen.showString(97, 9 + (12 * (chargeStage - 1)), ">", font.f1212, color.lightGreen)
          end
          -- misc info (session timer, PD request voltage, tester temperature)
          screen.drawRect(94, 70, 159, 114, color.lightPurple)
          screen.showString(97, 67, "-MiscInfo", font.f0508, color.lightPurple)
          updateSessionTimer()
          screen.showString(103, 76, string.format("%02.0f:%02.0f:%02.0f", math.floor((sessionTimerNow - sessionTimerStart) / 3600), math.floor(((sessionTimerNow - sessionTimerStart) % 3600) / 60), math.floor(sessionTimerNow - sessionTimerStart) % 60), font.f1212, color.lightPurple) -- format total seconds to hh:mm:ss
          screen.showString(103, 88, string.format("%0.2fVpd", targetVoltage), font.f1212, color.lightPurple)
          if isTempDisplayF then
            if isExternalTemperatureEnabled then
              screen.showString(97, 101, string.format("%+0.2f\2ex", (readExternalTemperatureCelsius() * 1.8) + 32), font.f1212, color.lightPurple)
            else
              screen.showString(97, 101, string.format("%+0.2f\2in", (sys.gBoardTempK() * 1.8) + 32), font.f1212, color.lightPurple)
            end
          else
            if isExternalTemperatureEnabled then
              screen.showString(97, 101, string.format("%+0.2f\1ex", readExternalTemperatureCelsius()), font.f1212, color.lightPurple)
            else  
              screen.showString(97, 101, string.format("%+0.2f\1in", sys.gBoardTempK()), font.f1212, color.lightPurple) -- it's actually in Celsius, not Kelvin (or "kevin" according to the API docs)
            end
          end
          -- dynamic statusbar that changes periodically
          if not isStatusbarOverridden then
            if (((sys.gTick() / 1000) - sessionTimerStart) % 15) < 3 then
              printStatusbar(string.format("Free mem: %d/%dB", sys.gFreeHeap(), sys.gFreeHeapEver()), color.grey, color.grey) -- testing shows that sometimes, when aggressive GC is disabled, free mem only really decrements if we're watching it?! getting real schrodinger's cat vibes here 
            elseif (((sys.gTick() / 1000) - sessionTimerStart) % 15) < 6 then
              printStatusbar(string.format("IR comp: %.3fV @ %.3f\3", readCurrentSigned() * cableResistance, cableResistance), color.grey, color.grey)
            elseif (((sys.gTick() / 1000) - sessionTimerStart) % 15) < 9 then
              printStatusbar(string.format("Cum: %.3fAh/%.3fWh", cumCharge, cumEnergy), color.grey, color.grey)
            elseif (((sys.gTick() / 1000) - sessionTimerStart) % 15) < 12 then
              if regLoopMode == 1 then
                printStatusbar(string.format("Setpoint: %.3f/%.3fV", setpointDeviation, setpointDeadband), color.grey, color.grey)
              else
                printStatusbar(string.format("Setpoint: %.3f/%.3fA", setpointDeviation, setpointDeadband), color.grey, color.grey)
              end
            else
              printStatusbar(string.format("PD req latency: %dms", pdRequestTimerNow - pdRequestTimerStart), color.grey, color.grey)
            end
          else
            if ((sys.gTick() / 1000) % 10) < 5 then -- alternate between override text and cumulative charge
              printStatusbar(statusbarOverrideText, statusbarOverrideColor, statusbarOverrideColor)
            else  
              printStatusbar(string.format("Cum: %.3fAh/%.3fWh", cumCharge, cumEnergy), statusbarOverrideColor, statusbarOverrideColor)
            end
          end
          
          -- flush updated framebuffer contents to screen, and reset the fine timer so we can wait until it's time to update the screen again
          screen.forceUpdate()
          timerFineStart = sys.gTick()
        end
        timerFineNow = sys.gTick()  
        
        if sys.gFreeHeap() < aggressiveGcThreshold then -- can't rely on automatic GC to save us if we run low on RAM
          collectgarbage("collect") -- YEET THE GARBAGE
        end
        
        if isSessionTimerEnabled then
          cumCharge = cumCharge + ((((sys.gTick() - loopIterationTimerStart) / 1000) * readCurrentSigned()) / 3600) -- Shizuku Lua API does not expose built-in accumulation group functionality; need to implement it ourselves
          cumEnergy = cumEnergy + ((((sys.gTick() - loopIterationTimerStart) / 1000) * readPowerSigned()) / 3600)
        end
      end -- end of main program/UI loop
    
    else
      if isSystemSoundsEnabled then
        buzzer.system(sysSound.alarm)
      end
      screen.clear()
      screen.showDialog("PD Request Failed", "Failed to receive\nready message from\nadapter!", 5000, true, color.red)
    end
   
  else
    startCharging = nil
    package.loaded["lua/user/DC4S/lib/DC4S-startCharging"] = nil
    collectgarbage("collect")
    return false
  end
  closePdSession()
  startCharging = nil
  package.loaded["lua/user/DC4S/lib/DC4S-startCharging"] = nil
  collectgarbage("collect")
  return true
end