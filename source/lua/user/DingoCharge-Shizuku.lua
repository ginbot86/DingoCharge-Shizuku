--[[DC4S: DingoCharge for Shizuku Platform (YK-Lab YK001, AVHzY CT-3, Power-Z KT002, ATORCH UT18)
Li-ion CC/CV Charger via USB-C PD PPS, by Jason Gin.
https://ripitapart.com November 16, 2021.

Version history:
1.0.0: Initial public release (2022-06-30).
1.1.0: Fixed issue where setting cell count does not update precharge voltage. (2022-07-22).
       Fixed issue where precharge voltage did not display (correctly) during charge. (2022-10-12).
       Added CC fallback when in CV mode and charge current overshoots too much (2022-10-12).
       Added an option to display system temperature in Fahrenheit (2022-10-12).
       Added 2.5V/cell and 8S cell configurations (2022-10-13).
1.1.1: Fixed issue where some chargers' current-limiting conflicted with CV control loop (2022-10-15).
1.1.2: Fixed issue where setting 8S configuration would result in a Config Error message (2022-10-20).]]


scriptVer = 1.1
patchVer = 2

-- Default settings are stored in a separate file:
require "lua/user/DC4S/UserDefaults-DC4S"

-- Configuration menus are stored in a separate file:
require "lua/user/DC4S/LibMenu-DC4S"

-- Functions

function endProgram()
  screen.close()
  pdSink.deinit()
  os.exit(0)
end

function readCurrentSigned()
  if meter.readCurrentDirection() then -- true if negative
    return (0 - meter.readCurrent())
  else
    return meter.readCurrent()
  end
end

function readPowerSigned()
  if meter.readCurrentDirection() then -- true if negative
    return (0 - meter.readPower())
  else
    return meter.readPower()
  end
end

function waitForSourceCap()
  local timer = 2000
  while (timer > 0) do 
    timer = timer - 1
    if (pdSink.isSrcCapReceived()) then 
      timer = nil
      return true
    end
    delay.ms(1)
  end
  return false
end

function closePdSession()
  pdSink.deinit()
  fastChgTrig.close()
end

-- "123456789ABCDEFGHIJ" is maximum length of popYesOrNo or showDialog line, 19 chars
-- "123456789ABCDEFGHIJKLMNO" is maximum length of popMenu line, 24 chars
-- Weird spacing between words (or lack thereof) is to prevent line wrapping from occurring mid-word
-- Special characters: \1 = ºC, \2 = ºF, \3 = Ω (these glyphs only render for font.f1212)
function testCompatibility(isPdClosedOnFinish)
  local isPdClosed = isPdClosedOnFinish or false
  screen.clear()
  if checkConfigs() == false then
   return false
  end
  if screen.popYesOrNo("Ready to test\ncompatibility.\nUnplug battery and\nconnect adapter now",color.yellow) then
    screen.clear()     
    if (sys.gIsUSBPowered() == false) then -- sending a PD hard reset will cause Vbus to drop to 0 volts
      -- TODO: Implement a method to retain preferences and relaunch upon reset.
      if (screen.popYesOrNo("Warning! External\npower not detected\non micro-USB port;\nmay reboot suddenly",color.yellow) == false) then
        return false
      end
    end

    screen.showDialog("Compatibility Test","", 0, true, color.cyan)
    screen.showString(12, 32, "Communicating with the", font.f1212, color.cyan)
    screen.showString(12, 46, "adapter. This may take", font.f1212, color.cyan)
    screen.showString(12, 58, "a few seconds...", font.f1212, color.cyan)
    screen.showString(12, 82, "Do not connect battery", font.f1212, color.orange)
    screen.showString(12, 94, "until prompted to!", font.f1212, color.orange)
    
    if (meter.readVoltage() < 4.5) then
      screen.showDialog("Test Failed", "Adapter is not\nplugged in!", 3000, true, color.red)
      return false
    end
    
    if (fastChgTrig.open() ~= fastChgTrig.OK) then
      screen.showDialog("Internal Error", "Failed to open\nfastChgTrig module!\nTry power cycling\nor rebooting tester", 5000, true, color.red)
      return false
    end
    
    pdSink.init()
    if (pdSink.getCCStatus() == pdSink.NO_SRC_ATTACHED) then
      screen.showDialog("Test Failed", "USB-C CC attachmentnot detected!\n\nEnsure that PD COM\nswitch is turned ON", 5000, true, color.red)
      pdSink.deinit()
      fastChgTrig.close()
      return false
    end
    if (waitForSourceCap() == false) then
      pdSink.sendHardReset()
      closePdSession()
      if (fastChgTrig.open() ~= fastChgTrig.OK) then
        screen.showDialog("Internal Error", "Failed to open\nfastChgTrig module!\nTry power cycling\nor rebooting tester", 5000, true, color.red)
        return false
      else
        pdSink.init()
        if (waitForSourceCap() == false) then
          screen.showDialog("Test Failed", "Incompatible!\nNo USB PD support\n\nUnable to retrieve\nsource capability\nlist from adapter", 5000, true, color.red)
          closePdSession()
          return false      
        elseif (pdSink.getCCStatus() == pdSink.NO_SRC_ATTACHED) then
          screen.showDialog("Test Failed", "USB-C CC attachmentnot detected!\n\nEnsure that PD COM\nswitch is turned ON", 5000, true, color.red)
          closePdSession()
          return false
        end
      end
    end
    
    numPdos = pdSink.getNumofSrcCap()
    local numPpsPdos = 0
    minVoltage = 42069 -- there is no way USB PD can go this high, so any new value is guaranteed to overwrite the placeholder
    maxVoltage = 0
    maxCurrent = 0
    local pdos = {} -- no need to keep the whole table of PDOs in memory during charge cycle
    bestPdo = -1 -- -1 if no usable PPS PDOs

    for pdoIndex = 0, numPdos - 1 do
      pdos[pdoIndex] = pdSink.getSrcCap(pdoIndex)
      if (pdos[pdoIndex].type == pdSink.AUGMENTED) then
        numPpsPdos = numPpsPdos + 1
        if (pdos[pdoIndex].voltage < minVoltage) then
          minVoltage = pdos[pdoIndex].voltage
        end
        if (pdos[pdoIndex].voltageMax > maxVoltage) then
          maxVoltage = pdos[pdoIndex].voltageMax
        end
        if (pdos[pdoIndex].currentMax > maxCurrent) then
          maxCurrent = pdos[pdoIndex].currentMax
        end
        if (((voltsPerCell * numCells) <= pdos[pdoIndex].voltageMax) and ((voltsPerCell * numCells) >= pdos[pdoIndex].voltage) and ((voltsPerCellPrecharge * numCells) >= pdos[pdoIndex].voltage) and ((voltsPerCellPrecharge * numCells) <= pdos[pdoIndex].voltageMax) and (pdos[pdoIndex].currentMax >= chargeCurrent)) then
          bestPdo = pdoIndex
          maxVoltage = pdos[pdoIndex].voltageMax
          maxCurrent = pdos[pdoIndex].currentMax
        end
      end
    end
    if (numPpsPdos > 0) then
      if (bestPdo == -1) then -- note: the "too high" or "too low" refers to the PD requested voltage/current vs. what the adapter supports as per PDO(s)
      -- if multiple incompatibilities are found, then only the first matching incompatibility in this list will be shown
        if (((voltsPerCell * numCells) < minVoltage) and ((voltsPerCellPrecharge * numCells) >= minVoltage)) then
          screen.showDialog("Test Failed", string.format("Incompatible!\nNo usable PPS PDOs\n\nVoltage too low:\n%.2fV < %.2fV", (voltsPerCell * numCells)), minVoltage, 5000, true, color.red)
        elseif (((voltsPerCell * numCells) >= minVoltage) and ((voltsPerCellPrecharge * numCells) < minVoltage)) then
          screen.showDialog("Test Failed", string.format("Incompatible!\nNo usable PPS PDOs\n\nPChgV too low:\n%.2fV < %.2fV", (voltsPerCellPrecharge * numCells), minVoltage), 5000, true, color.red)
        elseif (((voltsPerCell * numCells) < minVoltage) and ((voltsPerCellPrecharge * numCells) < minVoltage)) then
          screen.showDialog("Test Failed", string.format("Incompatible!\nNo usable PPS PDOs\nPChgV and voltage\n too low:\n%.2fV < %.2fV\n%.2fV < %.2fV", (voltsPerCellPrecharge * numCells), minVoltage, (voltsPerCell * numCells), minVoltage), 7000, true, color.red)
        elseif (((voltsPerCell * numCells) > maxVoltage) and ((voltsPerCellPrecharge * numCells) <= maxVoltage)) then
          screen.showDialog("Test Failed", string.format("Incompatible!\nNo usable PPS PDOs\n\nVoltage too high:\n%.2fV > %.2fV", voltsPerCell * numCells, maxVoltage), 5000, true, color.red)
        elseif (((voltsPerCell * numCells) <= maxVoltage) and ((voltsPerCellPrecharge * numCells) > maxVoltage)) then
          screen.showDialog("Test Failed", string.format("Incompatible!\nNo usable PPS PDOs\n\nPChgV too high:\n%.2fV > %.2fV", voltsPerCellPrecharge * numCells, maxVoltage), 5000, true, color.red)
        elseif (((voltsPerCell * numCells) > maxVoltage) and ((voltsPerCellPrecharge * numCells) > maxVoltage)) then
          screen.showDialog("Test Failed", string.format("Incompatible!\nNo usable PPS PDOs\nPChgV and voltage\n too high:\n%.2fV > %.2fV\n%.2fV > %.2fV", (voltsPerCellPrecharge * numCells), maxVoltage, (voltsPerCell * numCells), maxVoltage), 7000, true, color.red)          
        elseif (chargeCurrent > maxCurrent) and ((prechargeCRate * chargeCurrent) <= maxCurrent) then
          screen.showDialog("Test Failed", string.format("Incompatible!\nNo usable PPS PDOs\n\nCurrent too high:\n%.3fA > %.3fA", chargeCurrent, maxCurrent), 5000, true, color.red)
        elseif (chargeCurrent <= maxCurrent) and ((prechargeCRate * chargeCurrent) > maxCurrent) then -- just an extra check, as there should not be a way for only precharge current to be too high
          screen.showDialog("Test Failed", string.format("Incompatible!\nNo usable PPS PDOs\n\nPChgCur too high:\n%.3fA > %.3fA", prechargeCRate * chargeCurrent, maxCurrent), 5000, true, color.red)
        elseif (chargeCurrent > maxCurrent) and ((prechargeCRate * chargeCurrent) > maxCurrent) then
          screen.showDialog("Test Failed", string.format("Incompatible!\nNo usable PPS PDOs\nCurrent and PchgCurtoo high:\n%.3fA > %.3fA\n%.3fA > %.3fA", chargeCurrent, maxCurrent, (prechargeCRate * chargeCurrent), maxCurrent), 7000, true, color.red)
        elseif ((maxVoltage < (voltsPerCell * numCells)) and (maxCurrent >= chargeCurrent)) then
          screen.showDialog("Test Failed", string.format("Incompatible!\nNo usable PPS PDOs\n\nVoltage too low:\n%.2fV < %.2fV", maxVoltage, (voltsPerCell * numCells)), 5000, true, color.red)
        elseif ((maxVoltage < (voltsPerCell * numCells)) and (maxCurrent < chargeCurrent)) then
          screen.showDialog("Test Failed", string.format("Incompatible!\nNo usable PPS PDOs\nVoltage and currenttoo low:\n%.2fV < %.2fV\n%.3fA < %.3fA", maxVoltage, (voltsPerCell * numCells), maxCurrent, chargeCurrent), 7000, true, color.red)
        else -- if current requirement is satisfied in, e.g. PDO A but not B, and voltage is satisfied in PDO B but not A
          screen.showDialog("Test Failed", "Incompatible!\nNo usable PPS PDOs\n\nNo single PDO meetsboth volt & currentrequirements", 7000, true, color.red)
        end        
        closePdSession()
        return false
      end
    else -- if PDO table only contains fixed PDOs
      screen.showDialog("Test Failed", "Incompatible!\nNo PPS support\n\nAdapter supports\nonly fixed PDOs", 5000, true, color.red)
      closePdSession()
      return false      
    end

  else
    return false
  end
  screen.showDialog("Test Passed",string.format("Adapter compatible!PD Max Voltage:\n%.2fV >= %.2fV\nPD Max Current:\n%.2fA >= %.2fA\nBest PDO: %d/%d", maxVoltage, (voltsPerCell * numCells), maxCurrent, chargeCurrent, bestPdo+1, numPdos), 4000, true, color.green)
  if (isPdClosed) then
    closePdSession()
  end
  return true
end

function drawMeter(x, y, title, value, unit, meterColor)
  local drawColor = meterColor or color.white
  screen.drawRect(x, y+3, x+92, y+36, drawColor)
  screen.showString(x+3, y, "-" .. title, font.f0508, drawColor) -- preceding hyphen creates 1 pixel space between border and title text on left
  if (math.abs(value) < 10) then -- 1.234
    screen.showString(x+6, y+9, string.format("%.3f%s", value, unit), font.f1424, drawColor)
  elseif (math.abs(value) < 100) then -- 12.34
    screen.showString(x+6, y+9, string.format("%.2f%s", value, unit), font.f1424, drawColor)
  elseif (math.abs(value) < 1000) then -- 123.4
    screen.showString(x+6, y+9, string.format("%.1f%s", value, unit), font.f1424, drawColor)
  else -- 1234
    screen.showString(x+6, y+9, string.format("%.0f%s", value, unit), font.f1424, drawColor)
  end
end

function printStatusbar(text, textColor, barColor, backColor)
  local drawTextColor = textColor or color.white
  local drawLineColor = barColor or color.white
  local drawBackColor = backColor or color.black
  screen.fillRect(0, 117, 159, 127, drawBackColor)
  screen.showString(0, 117, text, font.f1212, drawTextColor, drawBackColor)
  screen.drawRect(0, 116, 159, 116, drawLineColor)
end

function startSessionTimer()
  sessionTimerStart = os.clock()
  sessionTimerNow = sessionTimerStart
  isSessionTimerEnabled = true
end

function stopSessionTimer()
  isSessionTimerEnabled = false
end

function resumeSessionTimer()
  isSessionTimerEnabled = true
end

function updateSessionTimer()
  if isSessionTimerEnabled then
    sessionTimerNow = os.clock()
  end
end


function startCharging()
  meter.setDataSource(meter.INSTANT) -- using the API's meter filtering modes causes regulation instability
  if screen.popYesOrNo("Unplug adapter thenplug in battery", color.cyan) then
    initialVbat = meter.readVoltage()
    screen.popHint(string.format("Vbat = %.3fV", initialVbat), 1000)
  else
    return false
  end

  if (testCompatibility(false) == true) then
    if (initialVbat < minVoltage) then
      screen.clear()
      screen.showDialog("Precharge Failed", string.format("Battery voltage toolow to precharge!\n\nVbat < PPS min out:%.3fV < %.3fV", initialVbat, minVoltage), 5000, true, color.red)
      closePdSession()
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
        screen.clear()
        screen.showDialog("PD Request Failed", "Failed to receive\nready message from\nadapter!", 5000, true, color.red)
        closePdSession()    
        return false
      end 
      
      if not (screen.popYesOrNo("Ready to charge.\nPlug in battery now", color.lightGreen)) then
        closePdSession()
        return false
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

      vbusOffset = nil
      initialVbat = nil
      initialVbus = nil
      if not isChargeStarted then
        startSessionTimer()
      else
        if screen.popYesOrNo("Detected previous\ncharge cycle. Resettimer to zero?", color.lightGreen) then
          startSessionTimer()
        else
          resumeSessionTimer()
        end
      end
      isChargeStarted = true
      timerFineStart = sys.gTick()
      timerFineNow = sys.gTick() + 2000 -- allow screen to be updated on first loop iteration
      
      while true do -- main program/UI loop

        -- charge regulation
        if regLoopMode == 0 then
          -- test for transfer to CC or CV mode
          if (meter.readVoltage() > ((regLoopVoltage - cvDeadband) + (readCurrentSigned() * cableResistance))) then 
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
          setpointDeviation = readCurrentSigned() - regLoopCurrent
        elseif regLoopMode == 1 then
        -- test for transfer to idle mode upon termination
          if (meter.readCurrent() < regLoopCurrent) then
            chargeStage = 4
            regLoopMode = 0
            regLoopCurrent = 0
            setpointDeadband = tcDeadband
            stopSessionTimer()
            if isSystemSoundsEnabled then
              buzzer.system(sysSound.finished)
            end
          end
          setpointDeviation = meter.readVoltage() - regLoopVoltage - (readCurrentSigned() * cableResistance)
        else  -- this should never happen
        regLoopMode = 0
        regLoopCurrent = 0
        end
        
        if (math.abs(setpointDeviation) > setpointDeadband) then
          if setpointDeviation > 0 then
            targetVoltage = targetVoltage - 0.02
          else
            targetVoltage = targetVoltage + 0.02
          end
        end
        
        if (chargeStage == 4 or chargeStage == 0) and meter.readVoltage() > voltsPerCell * numCells then
          targetVoltage = targetVoltage - 0.04 -- safety check? one test run allowed a 4.2Vpc 3S battery to hit 4.35Vpc after several hours of idle!!!
        end

        if chargeStage == 3 and meter.readCurrent() > (ccFallbackRate * chargeCurrent) then
          chargeStage = 2 -- safety check? see if this helps with reducing current overshoot during CC-CV transition
          regLoopMode = 0
          regLoopCurrent = chargeCurrent
          regLoopVoltage = voltsPerCell * numCells
          setpointDeadband = ccDeadband
        end
        

        -- ensure requested voltage is within PDO bounds
        if (targetVoltage > maxVoltage) then
          targetVoltage = maxVoltage
        elseif (targetVoltage < minVoltage) then
          targetVoltage = minVoltage
        end
        
        if (pdSink.request(bestPdo, targetVoltage, maxCurrent) ~= pdSink.OK) then
          if isSystemSoundsEnabled then
            buzzer.system(sysSound.alarm)
          end
          if screen.popYesOrNo("PD request failed!\n\n* Confirm: exit to\n  main menu\n* Cancel: retry", color.red) then
            break
          end
        end      
        
        if ((timerFineNow - timerFineStart) >= refreshInterval) then         
          screen.clear()
          -- volts, amps, watts
          drawMeter(0, 0, "Voltage", meter.readVoltage(), "V", color.yellow)
          drawMeter(0, 39, "Current", readCurrentSigned(), "A", color.cyan)
          drawMeter(0, 78, "Power", readPowerSigned(), "W", color.red)
          -- charge settings
          screen.drawRect(94, 3, 159, 58, color.lightGreen)
          screen.showString(97, 0, "-Chg. Set", font.f0508, color.lightGreen) -- preceding hyphen creates 1 pixel space between border and title text on left
          if ((os.clock() - sessionTimerStart) % 10) < 5 then -- alternate between showing precharge voltage and current
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
          screen.showString(103, 76, string.format("%02.0f:%02.0f:%02.0f", math.floor((sessionTimerNow - sessionTimerStart) / 3600), math.floor(((sessionTimerNow - sessionTimerStart) % 3600)/60), math.floor(sessionTimerNow - sessionTimerStart) % 60), font.f1212, color.lightPurple) -- format total seconds to hh:mm:ss
          screen.showString(103, 88, string.format("%0.2fVpd", targetVoltage), font.f1212, color.lightPurple)
          if isTempDisplayF then
            screen.showString(103, 101, string.format("%0.2f\2", (sys.gBoardTempK() * 1.8) + 32), font.f1212, color.lightPurple)
          else
            screen.showString(103, 101, string.format("%0.2f\1", sys.gBoardTempK()), font.f1212, color.lightPurple) -- it's actually in Celsius, not Kelvin (or "kevin" according to the API docs)
          end
          -- dynamic statusbar that changes periodically
          if ((os.clock() - sessionTimerStart) % 10) < 3.333 then
            printStatusbar(string.format("Free mem: %d/%d", sys.gFreeHeap(), sys.gFreeHeapEver()), color.grey, color.grey) -- testing shows that sometimes, when aggressive GC is disabled, free mem only really decrements if we're watching it?! getting real schrodinger's cat vibes here 
          elseif ((os.clock() - sessionTimerStart) % 10) < 6.667 then
            printStatusbar(string.format("IR comp: %.3fV @ %.3f\3", readCurrentSigned() * cableResistance, cableResistance), color.grey, color.grey)
          else
            if regLoopMode == 1 then
              printStatusbar(string.format("Setpoint: %.3f/%.3fV", setpointDeviation, setpointDeadband), color.grey, color.grey)
            else
              printStatusbar(string.format("Setpoint: %.3f/%.3fA", setpointDeviation, setpointDeadband), color.grey, color.grey)
            end
          end
          
          -- flush updated framebuffer contents to screen, and reset the fine timer so we can wait until it's time to update the screen again
          screen.forceUpdate()
          timerFineStart = sys.gTick()
        end
        timerFineNow = sys.gTick()  
        
        if isAggressiveGcEnabled and sys.gFreeHeap() < aggressiveGcThreshold then -- can't rely on automatic GC to save us if we run low on RAM
          collectgarbage("collect") -- YEET THE GARBAGE
        end
      end
    
    else
      screen.clear()
      screen.showDialog("PD Request Failed", "Failed to receive\nready message from\nadapter!", 5000, true, color.red)
    end
   
  else
    return false
  end
  closePdSession()
  return true
end

-- Start of script

if (screen.open() ~= screen.OK) then 
  os.exit(-1)
end
resetAllDefaults()
if isSystemSoundsEnabled then
  buzzer.system(sysSound.started)
end

screen.clear()

timerFineStart = sys.gTick()
timerFineNow = sys.gTick()
isChargeStarted = false

screen.popHint(string.format("DingoCharge v%0.1f", scriptVer), 1000)

while true do
  screen.clear()
  mainMenuSel = screen.popMenu({"Charger Setup...", "Start Charging", "Advanced...", "About", "Exit", "Reboot"})
  screen.clear()

  if mainMenuSel == 0 then
    chargerSetup()
  elseif mainMenuSel == 1 then
    if screen.popYesOrNo(string.format("Start charging?\nVoltage: %.3fV\nCurrent: %.3fA\nTerm: %.2fC/%.3fA", (voltsPerCell * numCells), chargeCurrent, termCRate, (chargeCurrent * termCRate)), color.lightGreen) then
      startCharging()
    end
  elseif mainMenuSel == 2 then
    advancedMenu()
  elseif mainMenuSel == 3 then
    if (screen.popMenu({"<       Main Menu       ", "DingoCharge for Shizuku", "Script By Jason Gin", "ripitapart.com","(C) 2021-2022", string.format("Version: v%0.1f.%d", scriptVer, patchVer), ":3"}) == 6) then
      screen.popHint("OwO", 1000, color.green) -- what's this? (it's an Easter egg! :3)
    end
  elseif mainMenuSel == 4 then
    if (screen.popYesOrNo("Exit program?", color.cyan)) then
      endProgram()
    end
  elseif mainMenuSel == 5 then
    if (screen.popYesOrNo("Reboot tester?", color.red)) then
      sys.reset()
    end
  end
end
endProgram()