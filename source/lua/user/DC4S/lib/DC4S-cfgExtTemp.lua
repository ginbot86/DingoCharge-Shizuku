--[[DingoCharge for Shizuku Platform - External Temperature Sensor Configuration Menu
https://github.com/ginbot86/DingoCharge-Shizuku December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).
1.5.0: Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).
       Added LM135/LM235/LM335 support as external temperature sensors (2023-01-21).
1.6.0: Changed external temperature sensor setup exit display to use 'ºC' sign instead of just 'C' (2023-07-31).
       Changed header to point directly to official GitHub repository (2023-12-15).]]

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
      cfgExtTempSelSubmenu = screen.popMenu{string.format("Keep Current (%+0.3fV)", externalTemperatureOffsetVoltage), "0V (TMP35, TMP37)", "-0.5V (TMP36)", "-2.7315 (LM1/2/335)"}
      if cfgExtTempSelSubmenu == 1 then
        externalTemperatureOffsetVoltage = 0
      elseif cfgExtTempSelSubmenu == 2 then
        externalTemperatureOffsetVoltage = -0.5
      elseif cfgExtTempSelSubmenu == 3 then
        externalTemperatureOffsetVoltage = -2.7315
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
        screen.popHint(string.format("Ext Temp: %+.1f\1", readExternalTemperatureCelsius()), 100)
      end
      timer = nil
    elseif cfgExtTempSel == 10 then
      if (screen.popYesOrNo("Restore defaults?", color.yellow)) then
        setExternalTemperatureDefaults()
        screen.popHint("Defaults Restored", 1000)    
      end
    else
      break
    end
  end
  -- discard temporary variables
  cfgExtTempMenuEntryExtEnable = nil
  cfgExtTempMenuEntryOtp = nil
  cfgExtTempMenuEntryOtpRecovery = nil
  cfgExtTempMenuEntryUtp = nil
  cfgExtTempMenuEntryUtpRecovery = nil
  cfgExtTempSel = nil
  cfgExtTempSelSubmenu = nil
  cfgExtTempSelSubmenuText = nil
  cfgExtTemp = nil
  package.loaded["lua/user/DC4S/lib/DC4S-cfgExtTemp"] = nil
  collectgarbage("collect") -- clean up memory
end