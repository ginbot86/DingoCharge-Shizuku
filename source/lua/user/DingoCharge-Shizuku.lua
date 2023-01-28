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
1.1.2: Fixed issue where setting 8S configuration would result in a Config Error message (2022-10-20).
1.2.0: Added prompt to retry the compatibility test if Vbus voltage is not present, instead of outright failing (2022-11-06).
       Added CC deadband threshold tweaks to fix an issue where setting charge current overwrites the user's defaults (2022-11-06).
       Fixed issue where double-tapping Select key in "Advanced... > Chg Reg Deadband" menu does not go up a level (2022-11-06).
1.3.0: Fixed issue where 3.65Vpc was considered standard Li-ion in terms of precharge voltage instead of LiFePO4 (2022-11-17).
       Added test to verify configuration immediately upon startup (2022-12-12).
       Added memory cleanup routine after reading PDOs from adapter (2022-12-12).
       Changed internal version format (2022-12-12).
       Added statusbar override support for charge termination/faults (2022-12-13).
       Added support for TMP3x/LM35/LM50 external temperature sensor on D+ pin (2022-12-13).
       Added optional over/undertemperature protection when using external sensor (2022-12-13).
       Added charge timeout protection (2022-12-13).
       Fixed issue where resuming session timer counts time while timer was stopped (2022-12-13).
       Added second menu library file due to RAM space exhaustion (2022-12-13).
       Decreased aggressive GC threshold from 16K to 4K but added more forced GCs to mitigate RAM exhaustion (2022-12-13).
1.4.0: Split off monolithic menu library functions into individual files, reducing RAM consumption significantly (2022-12-15).
       Increased aggressive GC threshold from 4K to 16K due to RAM usage savings from modularization (2022-12-15).
       Changed charge error messages to reflect if recovery is enabled (i.e. "paused" vs. "stopped") (2022-12-18).
       Fixed issue where precharge was not subject to the safety time limit (2022-12-18).
       Added cumulative charge/energy display for the current charge session (2022-12-24).
       Updated free memory counter to specify count in bytes (2022-12-24).
       Changed how the UI calculates when to show different statusbar messages (2012-12-24).
1.5.0: Changed the low-current deadband threshold to activate if charge current is less than the threshold instead of less than/equal to (2023-01-01).
       Updated copyright string in About screen to read "(C) 2021-2023".
       Changed the default cell count to 2S for improved user experience; most PPS adapters go to 11V so a compatibility fail out of the box kinda sucks... (2023-01-06).
       Changed how aggressive GC is enabled/disabled; set aggressiveGcThreshold to 0 instead of isAggressiveGcEnabled to false (not that you should do this anyway...) (2023-01-08).
       Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).
       Added LM135/LM235/LM335 support as external temperature sensors (2023-01-21).
       Split off charge control function into a separate file which unloads upon termination to conserve memory (2023-01-27).
       Renamed "DC4S-CompileMenu" to "DC4S-CompileLibs" to reflect that non-menu libraries are also compiled here (2023-01-27).
       Changed how USB-C CC attachment errors are handled; user can retry the detection instead of needing to restart the charge setup procedure (2023-01-28).]]


scriptVerMajor = 1
scriptVerMinor = 5
scriptPatchVer = 0

-- Default settings are stored in a separate file:
require "lua/user/DC4S/UserDefaults-DC4S"

-- Configuration tools and other libraries are now stored in their own files in the "DC4S/lib" subfolder as of version 1.4.0

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

function readExternalTemperatureCelsius()
  return externalTemperatureGain * (meter.readDP() + externalTemperatureOffsetVoltage) -- offset is applied before gain
end

-- "123456789ABCDEFGHIJ" is maximum length of popYesOrNo or showDialog line, 19 chars
-- "123456789ABCDEFGHIJKLMNO" is maximum length of popMenu line, 24 chars
-- Weird spacing between words (or lack thereof) is to prevent line wrapping from occurring mid-word
-- Special characters: \1 = ºC, \2 = ºF, \3 = Ω (these glyphs only render for font.f1212)
function testCompatibility(isPdClosedOnFinish) -- can't split off into own file easily since this function is called from more than one location...
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
    
    while (meter.readVoltage() < 4.5) do
      if isSystemSoundsEnabled then
        buzzer.system(sysSound.alarm)
      end
      if screen.popYesOrNo("Adapter is not\nplugged in!\n\n* Confirm: go back\n* Cancel: retry", color.red) then
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
        return false
      end
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
  
  cumCharge = 0
  cumEnergy = 0
end

function stopSessionTimer()
  isSessionTimerEnabled = false
end

function resumeSessionTimer()
  isSessionTimerEnabled = true
  sessionTimerNow = os.clock()
end

function updateSessionTimer()
  if isSessionTimerEnabled then
    sessionTimerNow = os.clock()
  else
    sessionTimerStart = sessionTimerStart + (os.clock() - sessionTimerNow) -- advance start timer to compensate for time spent while session timer stopped
    sessionTimerNow = os.clock()
  end
end

-- Start of script

if (screen.open() ~= screen.OK) then 
  os.exit(-1)
end
resetAllDefaults()

require "lua/user/DC4S/lib/DC4S-checkConfigs"
if not checkConfigs() then -- check if configuration is valid
  os.exit(-1)
end

if isSystemSoundsEnabled then
  buzzer.system(sysSound.started)
end

screen.clear()

timerFineStart = sys.gTick()
timerFineNow = sys.gTick()
isChargeStarted = false
isStatusbarOverridden = false
statusbarOverrideColor = color.red
statusbarOverrideText = "oops uwu" -- will only appear if override text is not defined before displaying it

screen.popHint(string.format("DingoCharge v%d.%d", scriptVerMajor, scriptVerMinor), 1000)

collectgarbage("collect") -- clean up memory after all configs loaded

while true do
  screen.clear()
  mainMenuSel = screen.popMenu({"Charger Setup...", "Start Charging", "Advanced...", "About", "Exit", "Reboot"})
  screen.clear()

  if mainMenuSel == 0 then
    require "lua/user/DC4S/lib/DC4S-chargerSetup" -- load on demand; will unload when function terminates
    chargerSetup()
  elseif mainMenuSel == 1 then
    if screen.popYesOrNo(string.format("Start charging?\nVoltage: %.3fV\nCurrent: %.3fA\nTerm: %.2fC/%.3fA", (voltsPerCell * numCells), chargeCurrent, termCRate, (chargeCurrent * termCRate)), color.lightGreen) then
      require "lua/user/DC4S/lib/DC4S-startCharging"
      startCharging()
    end
  elseif mainMenuSel == 2 then
    require "lua/user/DC4S/lib/DC4S-advancedMenu"
    advancedMenu()
  elseif mainMenuSel == 3 then
    if (screen.popMenu({"<       Main Menu       ", "DingoCharge for Shizuku", "Script by Jason Gin", "ripitapart.com","(C) 2021-2023", string.format("Version: v%d.%d.%d", scriptVerMajor, scriptVerMinor, scriptPatchVer), ":3"}) == 6) then
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