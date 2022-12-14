--[[DingoCharge for Shizuku Platform - Menu Library 2
https://ripitapart.com December 13, 2022.

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
       Decreased aggressive GC threshold from 16K to 4K but added more forced GCs to mitigate RAM exhaustion (2022-12-13).]]

function cfgExtTemp()
  local cfgExtTempMenuEntryExtEnable = " "
  local cfgExtTempMenuEntryOtp = " "
  local cfgExtTempMenuEntryOtpRecovery = " "
  local cfgExtTempMenuEntryUtp = " "
  local cfgExtTempMenuEntryUtpRecovery = " "
  local cfgExtTempSel = 0
  local cfgExtTempSelSubmenu = 0
  local cfgExtTempSelSubmenuText = " "
  
  while true do
    collectgarbage("collect") -- clean up memory
    screen.clear()  
    if isExternalTemperatureEnabled then
      cfgExtTempMenuEntryExtEnable = "Ext Temp Sensor: On"
    else
      cfgExtTempMenuEntryExtEnable = "Ext Temp Sensor: Off"
    end
    if isOvertemperatureEnabled then
      cfgExtTempMenuEntryOtp = string.format("Overtemp Protect: %.0f\1", overtemperatureThresholdC)
    else
      cfgExtTempMenuEntryOtp = "Overtemp Protect: Off"
    end
    if isOvertemperatureRecoveryEnabled then
      cfgExtTempMenuEntryOtpRecovery = string.format("OTP Recovery: On (%.0f\1)", overtemperatureThresholdC - temperatureProtectionHysteresisC)
    else
      cfgExtTempMenuEntryOtpRecovery = "OTP Recovery: Off"
    end
    if isUndertemperatureEnabled then
      cfgExtTempMenuEntryUtp = string.format("Undertemp Protect: %.0f\1", undertemperatureThresholdC)
    else
      cfgExtTempMenuEntryUtp = "Undertemp Protect: Off"
    end
    if isUndertemperatureRecoveryEnabled then
      cfgExtTempMenuEntryUtpRecovery = string.format("UTP Recovery: On (%.0f\1)", undertemperatureThresholdC + temperatureProtectionHysteresisC)
    else
      cfgExtTempMenuEntryUtpRecovery = "UTP Recovery: Off"
    end

    cfgExtTempSel = screen.popMenu{"<       Advanced...     ", cfgExtTempMenuEntryExtEnable, string.format("Ext Offset: %+0.3fV", externalTemperatureOffsetVoltage), string.format("Ext Gain: %0.3fx", externalTemperatureGain), cfgExtTempMenuEntryOtp, cfgExtTempMenuEntryOtpRecovery, cfgExtTempMenuEntryUtp, cfgExtTempMenuEntryUtpRecovery, string.format("OTP/UTP Hyst: %.0f\1", temperatureProtectionHysteresisC), "Test Sensor...", "Restore Defaults"}
    
    if cfgExtTempSel == 1 then
      screen.clear()
      if isExternalTemperatureEnabled then
        cfgExtTempSelSubmenuText = "On"
      else
        cfgExtTempSelSubmenuText = "Off"
      end
      cfgExtTempSelSubmenu = screen.popMenu{string.format("Keep Current (%s)", cfgExtTempSelSubmenuText), "Ext Temp On", "Ext Temp Off"}
      if cfgExtTempSelSubmenu == 1 then
        isExternalTemperatureEnabled = true
      elseif cfgExtTempSelSubmenu == 2 then
        isExternalTemperatureEnabled = false
      end
      if isExternalTemperatureEnabled then
        screen.popHint("Ext Temp On", 1000)
      else
        screen.popHint("Ext Temp Off", 1000)
      end
    elseif cfgExtTempSel == 2 then
      screen.clear()
      cfgExtTempSelSubmenu = screen.popMenu{string.format("Keep Current (%+0.3fV)", externalTemperatureOffsetVoltage), "0V (TMP35, TMP37)", "-0.5V (TMP36)"}
      if cfgExtTempSelSubmenu == 1 then
        externalTemperatureOffsetVoltage = 0
      elseif cfgExtTempSelSubmenu == 2 then
        externalTemperatureOffsetVoltage = -0.5
      end
      screen.popHint(string.format("%+0.3fV", externalTemperatureOffsetVoltage), 1000)
    elseif cfgExtTempSel == 3 then
      screen.clear()
      cfgExtTempSelSubmenu = screen.popMenu{string.format("Keep Current (%0.3fx)", externalTemperatureGain), "100x (TMP35, TMP36)", "50x (TMP37)"}
      if cfgExtTempSelSubmenu == 1 then
        externalTemperatureGain = 100
      elseif cfgExtTempSelSubmenu == 2 then
        externalTemperatureGain = 50
      end
      screen.popHint(string.format("%0.3fx", externalTemperatureGain), 1000)
    elseif cfgExtTempSel == 4 then
      screen.clear()
      if isOvertemperatureEnabled then
        cfgExtTempSelSubmenuText = string.format("%d\1", overtemperatureThresholdC)
      else
        cfgExtTempSelSubmenuText = "Off"
      end
      cfgExtTempSelSubmenu = screen.popMenu{string.format("Keep Current (%s)", cfgExtTempSelSubmenuText), "40\1", "45\1", "50\1", "55\1", "60\1", "Off"}
      if cfgExtTempSelSubmenu > 0 and cfgExtTempSelSubmenu < 6 then
        overtemperatureThresholdC = 35 + (cfgExtTempSelSubmenu * 5)
        isOvertemperatureEnabled = true
      elseif cfgExtTempSelSubmenu == 6 then
        isOvertemperatureEnabled = false
        isOvertemperatureRecoveryEnabled = false -- implicitly turns off recovery if protection is disabled
      end
      if isOvertemperatureEnabled then
        screen.popHint(string.format("%d\1", overtemperatureThresholdC), 1000)
      else
        screen.popHint("Off", 1000)
      end
    elseif cfgExtTempSel == 5 then
      screen.clear()
      if isOvertemperatureRecoveryEnabled then
        cfgExtTempSelSubmenuText = "On"
      else
        cfgExtTempSelSubmenuText = "Off"
      end
      cfgExtTempSelSubmenu = screen.popMenu{string.format("Keep Current (%s)", cfgExtTempSelSubmenuText), "OTP Recovery On", "OTP Recovery Off"}
      if cfgExtTempSelSubmenu == 1 then
        isOvertemperatureRecoveryEnabled = true
        isOvertemperatureEnabled = true -- implicitly turns on protection if recovery is enabled
      elseif cfgExtTempSelSubmenu == 2 then
        isOvertemperatureRecoveryEnabled = false
      end
      if isOvertemperatureRecoveryEnabled then
        screen.popHint("OTP Recovery On", 1000)
      else
        screen.popHint("OTP Recovery Off", 1000)
      end
    elseif cfgExtTempSel == 6 then
      screen.clear()
      if isUndertemperatureEnabled then
        cfgExtTempSelSubmenuText = string.format("%d\1", undertemperatureThresholdC)
      else
        cfgExtTempSelSubmenuText = "Off"
      end
      cfgExtTempSelSubmenu = screen.popMenu{string.format("Keep Current (%s)", cfgExtTempSelSubmenuText), "-10\1", "-5\1", "0\1", "5\1", "10\1", "Off"}
      if cfgExtTempSelSubmenu > 0 and cfgExtTempSelSubmenu < 6 then
        undertemperatureThresholdC = -15 + (cfgExtTempSelSubmenu * 5)
        isUndertemperatureEnabled = true
      elseif cfgExtTempSelSubmenu == 6 then
        isUndertemperatureEnabled = false
        isUndertemperatureRecoveryEnabled = false -- implicitly turns off recovery if protection is disabled
      end
      if isUndertemperatureEnabled then
        screen.popHint(string.format("%d\1", undertemperatureThresholdC), 1000)
      else
        screen.popHint("Off", 1000)
      end
    elseif cfgExtTempSel == 7 then
      screen.clear()
      if isUndertemperatureRecoveryEnabled then
        cfgExtTempSelSubmenuText = "On"
      else
        cfgExtTempSelSubmenuText = "Off"
      end
      cfgExtTempSelSubmenu = screen.popMenu{string.format("Keep Current (%s)", cfgExtTempSelSubmenuText), "UTP Recovery On", "UTP Recovery Off"}
      if cfgExtTempSelSubmenu == 1 then
        isUndertemperatureRecoveryEnabled = true
        isUndertemperatureEnabled = true -- implicitly turns on protection if recovery is enabled
      elseif cfgExtTempSelSubmenu == 2 then
        isUndertemperatureRecoveryEnabled = false
      end
      if isUndertemperatureRecoveryEnabled then
        screen.popHint("UTP Recovery On", 1000)
      else
        screen.popHint("UTP Recovery Off", 1000)
      end
    elseif cfgExtTempSel == 8 then
      screen.clear()
      cfgExtTempSelSubmenu = screen.popMenu{string.format("Keep Current (%.0f\1)", temperatureProtectionHysteresisC), "0\1", "5\1", "10\1", "15\1", "20\1"}
      if cfgExtTempSelSubmenu < 6 and cfgExtTempSelSubmenu > 0 then
        temperatureProtectionHysteresisC = 5 * (cfgExtTempSelSubmenu - 1)
      end
      screen.popHint(string.format("%.0f\1", temperatureProtectionHysteresisC), 1000)
    elseif cfgExtTempSel == 9 then
      local timer = 30
      while (timer > 0) do 
        timer = timer - 1
         screen.popHint(string.format("Ext Temp: %+.1fC", readExternalTemperatureCelsius()), 100)
      end
    elseif cfgExtTempSel == 10 then
      if (screen.popYesOrNo("Restore defaults?", color.yellow)) then
        setExternalTemperatureDefaults()
        screen.popHint("Defaults Restored", 1000)    
      end
    else
      break
    end
  end
  collectgarbage("collect") -- clean up memory
end

function cfgTimeLimit()
  local cfgTimeLimitSel = 0
  local cfgTimeLimitText = " "
  local tmpTimeLimit = 0
  while true do
    screen.clear()
    if timeLimitHours == 0 then
      cfgTimeLimitText = "Keep Current (Disabled)"
    else
      cfgTimeLimitText = string.format("Keep Current (%dh)", timeLimitHours)
    end
    cfgTimeLimitSel = screen.popMenu{cfgTimeLimitText, "Disable Time Limit", "Set Time Limit...", "Restore Defaults"}
    if cfgTimeLimitSel == 1 then
      timeLimitHours = 0
      break
    elseif cfgTimeLimitSel == 2 then
      -- Tens
      tmpTimeLimit = 10 * screen.popMenu{"0xh","1xh","2xh","3xh","4xh","5xh","6xh","7xh","8xh","9xh"}
      -- Ones
      tmpTimeLimit = tmpTimeLimit + (screen.popMenu({string.format("%dh",tmpTimeLimit),string.format("%dh",tmpTimeLimit + 1),string.format("%dh",tmpTimeLimit + 2),string.format("%dh",tmpTimeLimit + 3),string.format("%dh",tmpTimeLimit + 4),string.format("%dh",tmpTimeLimit + 5),string.format("%dh",tmpTimeLimit + 6),string.format("%dh",tmpTimeLimit + 7),string.format("%dh",tmpTimeLimit + 8),string.format("%dh",tmpTimeLimit + 9)}))
      timeLimitHours = tmpTimeLimit
      collectgarbage("collect")
      break
    elseif cfgTimeLimitSel == 3 then
      if (screen.popYesOrNo("Restore defaults?", color.yellow)) then
        setTimeLimitDefaults()
        screen.popHint("Defaults Restored", 1000)
      end
    else
      break
    end
  end
  if timeLimitHours == 0 then
    screen.popHint("Disabled", 1000)
  else
    screen.popHint(string.format("%dh", timeLimitHours), 1000)
  end
  collectgarbage("collect") -- clean up memory
end