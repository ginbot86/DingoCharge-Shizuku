--[[DingoCharge for Shizuku Platform - Adapter Compatibility Checker
https://github.com/ginbot86/DingoCharge-Shizuku February 2, 2023.

Version history:
1.6.0: Split off compatibility test into a separate file which unloads upon termination to conserve memory (2023-02-02).
       Changed header to point directly to official GitHub repository (2023-12-15).]]

function testCompatibility(isPdClosedOnFinish)
  local isPdClosed = isPdClosedOnFinish or false
  screen.clear()
  require "lua/user/DC4S/lib/DC4S-checkConfigs"
  if checkConfigs() == false then
    testCompatibility = nil
    package.loaded["lua/user/DC4S/lib/DC4S-testCompatibility"] = nil
    collectgarbage("collect")
    return false
  end
  if screen.popYesOrNo("Ready to test\ncompatibility.\nUnplug battery and\nconnect adapter now",color.yellow) then
    screen.clear()     
    if (sys.gIsUSBPowered() == false) then -- sending a PD hard reset will cause Vbus to drop to 0 volts
      -- TODO: Implement a method to retain preferences and relaunch upon reset.
      if (screen.popYesOrNo("Warning! External\npower not detected\non micro-USB port;\nmay reboot suddenly",color.yellow) == false) then
        testCompatibility = nil
        package.loaded["lua/user/DC4S/lib/DC4S-testCompatibility"] = nil
        collectgarbage("collect")
        return false
      end
    end
    
    while (meter.readVoltage() < 4.5 or meter.readVoltage() > 5.5) do -- only 5 volts is expected on Vbus at this time
      if isSystemSoundsEnabled then
        buzzer.system(sysSound.alarm)
      end
      if screen.popYesOrNo("Adapter is not\nplugged in!\n\n* Confirm: go back\n* Cancel: retry", color.red) then
        testCompatibility = nil
        package.loaded["lua/user/DC4S/lib/DC4S-testCompatibility"] = nil
        collectgarbage("collect")
        return false
      end
    end
    
    screen.showDialog("Compatibility Test","", 0, true, color.cyan)
    screen.showString(12, 32, "Communicating with the", font.f1212, color.cyan)
    screen.showString(12, 46, "adapter. This may take", font.f1212, color.cyan)
    screen.showString(12, 58, "a few seconds...", font.f1212, color.cyan)
    screen.showString(12, 82, "Do not connect battery", font.f1212, color.orange)
    screen.showString(12, 94, "until prompted to!", font.f1212, color.orange)
    
    if (fastChgTrig.open() ~= fastChgTrig.OK) then
      screen.showDialog("Internal Error", "Failed to open\nfastChgTrig module!\nTry power cycling\nor rebooting tester", 5000, true, color.red)
      testCompatibility = nil
      package.loaded["lua/user/DC4S/lib/DC4S-testCompatibility"] = nil
      collectgarbage("collect")
      return false
    end
    
    pdSink.init()
    while (pdSink.getCCStatus() == pdSink.NO_SRC_ATTACHED) do
      if isSystemSoundsEnabled then
        buzzer.system(sysSound.alarm)
      end
      if screen.popYesOrNo("USB-C CC detached!\nPD COM switch on?\n\n* Confirm: go back\n* Cancel: retry", color.red) then
        pdSink.deinit()
        fastChgTrig.close()
        testCompatibility = nil
        package.loaded["lua/user/DC4S/lib/DC4S-testCompatibility"] = nil
        collectgarbage("collect")
        return false
      end
    end
    
    if (waitForSourceCap() == false) then
      pdSink.sendHardReset()
      closePdSession()
      if (fastChgTrig.open() ~= fastChgTrig.OK) then
        screen.showDialog("Internal Error", "Failed to open\nfastChgTrig module!\nTry power cycling\nor rebooting tester", 5000, true, color.red)
        testCompatibility = nil
        package.loaded["lua/user/DC4S/lib/DC4S-testCompatibility"] = nil
        collectgarbage("collect")
        return false
      else
        pdSink.init()
        if (waitForSourceCap() == false) then
          screen.showDialog("Test Failed", "Incompatible!\nNo USB PD support\n\nUnable to retrieve\nsource capability\nlist from adapter", 5000, true, color.red)
          closePdSession()
          testCompatibility = nil
          package.loaded["lua/user/DC4S/lib/DC4S-testCompatibility"] = nil
          collectgarbage("collect")
          return false      
        elseif (pdSink.getCCStatus() == pdSink.NO_SRC_ATTACHED) then
          screen.showDialog("Test Failed", "USB-C CC attachmentnot detected!\n\nEnsure that PD COM\nswitch is turned ON", 5000, true, color.red)
          closePdSession()
          testCompatibility = nil
          package.loaded["lua/user/DC4S/lib/DC4S-testCompatibility"] = nil
          collectgarbage("collect")
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
    pdos = nil -- discard the PDO table since we don't need it anymore
    collectgarbage("collect") -- clean up memory
    
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
        testCompatibility = nil
        package.loaded["lua/user/DC4S/lib/DC4S-testCompatibility"] = nil
        collectgarbage("collect")
        return false
      end
    else -- if PDO table only contains fixed PDOs
      screen.showDialog("Test Failed", "Incompatible!\nNo PPS support\n\nAdapter supports\nonly fixed PDOs", 5000, true, color.red)
      closePdSession()
      testCompatibility = nil
      package.loaded["lua/user/DC4S/lib/DC4S-testCompatibility"] = nil
      collectgarbage("collect")
      return false      
    end

  else
    testCompatibility = nil
    package.loaded["lua/user/DC4S/lib/DC4S-testCompatibility"] = nil
    collectgarbage("collect")
    return false
  end
  screen.showDialog("Test Passed",string.format("Adapter compatible!PD Max Voltage:\n%.2fV >= %.2fV\nPD Max Current:\n%.2fA >= %.2fA\nBest PDO: %d/%d", maxVoltage, (voltsPerCell * numCells), maxCurrent, chargeCurrent, bestPdo+1, numPdos), 4000, true, color.green)
  if (isPdClosed) then
    closePdSession()
  end
  testCompatibility = nil
  package.loaded["lua/user/DC4S/lib/DC4S-testCompatibility"] = nil
  collectgarbage("collect")
  return true
end