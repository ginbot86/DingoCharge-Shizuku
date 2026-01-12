--[[DingoCharge for Shizuku Platform - User-Defined Default Settings
https://github.com/ginbot86/DingoCharge-Shizuku November 16, 2021.

Version history is removed from this file since version 1.7.0. See the main DingoCharge-Shizuku.lua source or the GitHub project page for detailed version information.]]

configVerMajor = 1
configVerMinor = 7
configPatchVer = 0

-- I guess this is easier than trying to build a configuration file parser...
-- Note: as versions are updated, this file should be replaced with one from
--       the latest version, as some new settings may be required. Be sure to
--       copy any non-default settings from the old file to the new one.

function setDefaults()
  -- Main charge parameters.
  -- Number of cells = the number of series cells in the battery pack.
  -- Volts per cell = pack charge voltage / number of cells in series.
  -- Charge current = the charge current used during the constant-current (CC)
  --   charge stage, defined in amps (A).
  -- Termination C rate = termination current / charge current. Typically C/10
  --   or C/20 (0.1C or 0.05C, assuming that the battery is being charged at a
  --   1C rate. Not all batteries can be safely charged at 1C; C/2 is usually
  --   the maximum safe rate, with C/3 or C/5 being other safer rates. Scale up
  --   the termination rate accordingly, if desired.)
  -- Note: many PPS chargers only go up to 11 volts so a 3S Li-ion or higher
  --   config will likely cause a compatibility test attempt to fail.
  --   PPS PDOs of 3.3~5.9V work for 1S, 3.3~11V for 1-2S, 3.3~16V for 1-3S,
  --   3.3~21V for 1-5S, at least for typical Li-ion chemistries. A PPS minimum
  --   voltage of 5V is incompatible with 1S batteries.
  numCells = 2
  voltsPerCell = 4.2
  chargeCurrent = 2
  termCRate = 0.05
end

function setPChgDefaults()
  -- Precharge is only relevant for over-discharged batteries that need extra
  --   care to prevent damage while recovering from undervoltage. The threshold
  --   defines the voltage where the algorithm will transition from precharge
  --   to constant-current mode.
  -- Precharge C rate = precharge current / charge current, assuming the normal
  --   charge current is 1C; see the above notes for more information.)
  voltsPerCellPrecharge = 3
  prechargeCRate = 0.05
end

-- *** Advanced settings below. There is no need to change these settings under
--     normal circumstances. Setting these values to invalid values may result
--     in unpredictable program behaviour. ***

function setRefreshDefaults()
  -- Screen refresh interval will be limited to at least this value, but may be
  --   slower depending on system processing load.
  refreshInterval = 100 -- milliseconds per frame
end

function setDeadbandDefaults()
  -- The charge regulation algorithm will attempt to maintain the measured
  --   current/voltage to +/- [deadband value]. Transitioning from CC to CV
  --   mode is offset by -cvDeadband, and the same applies during precharge.
  --   For example, if cvDeadband is 50 mV, the algorithm will switch when the
  --   voltage is [voltsPerCell * numCells] - 50 mV. This causes a temporary
  --   overshoot in current but is limited in amount and duration (often less
  --   than 10% for a couple minutes), but if it is too high then charging will
  --   fall back to constant-current mode; see setCcFallbackDefaults() below.
  --   This can be helpful when the adapter is unable to fully reach its
  --   maximum reported voltage (in testing, 3 of 3 "21V" capable adapters only
  --   produced 19.95V~20.5V, preventing use with 5S Li-ion packs unless 
  --   4V/cell is selected).
  pcDeadband = 0.01 -- Amps, precharge mode
  ccDeadbandNormal = 0.025 -- Amps, constant-current mode
  ccDeadbandLow = 0.01 -- Amps, constant-current mode for lower currents
  ccDeadbandThreshold = 0.2 -- Amps, use low deadband if current < threshold
  cvDeadband = 0.01 -- Volts, constant-voltage mode
  tcDeadband = 0.01 -- Amps, end-of-charge mode
  
  -- CAUTION: Do not change the rest of the code in this function.
  if (chargeCurrent < ccDeadbandThreshold) then
    ccDeadband = ccDeadbandLow
  else
    ccDeadband = ccDeadbandNormal
  end
end

function setAggressiveGcDefaults()
  -- If enabled, Lua's collectgarbage() will be forced if free RAM is below
  --   this threshold. This check occurs during every charge regulation loop
  --   iteration. (Yes, this is a pretty blunt approach, but it works and it
  --   keeps the system stable...)
  -- Note: Although the option is provided to disable this behaviour, doing
  --   so will severely impact stability (the system will likely hang, or crash
  --   with an out-of-memory dialog within minutes or hours when running the
  --   main charging/UI loop).
  aggressiveGcThreshold = 16384 -- bytes, set to 0 to disable (NOT RECOMMENDED!)
end

function setSystemSoundDefaults()
  -- The Shizuku sound API is used to sound a beep on the splash screen, if a
  --   PD request fails, and when charging is finished (transition from CV to
  --   TC charge stage).
  isSystemSoundsEnabled = true
end

function setCableResistanceDefaults()
  -- The algorithm can compensate for additional cable resistance between the
  --   tester and the battery, which will raise the CC-to-CV threshold voltage
  --   and CV voltage by (current * cableResistance). The algorithm inherently
  --   compensates for resistance and offset from the adapter to the tester
  --   without the need to define it manually.
  -- Note: it is not recommended to overcompensate for downstream resistance
  --   as it poses a risk of damaging the battery through overvoltage. A safe
  --   value is about half of the calculated downstream resistance:
  --   cableResistance = (Vbus_meter - Vbat) / Icharge
  cableResistance = 0 -- ohms
end

function setCcFallbackDefaults()
  -- The algorithm can protect against excessive current draw when the charge
  --   stage moves from constant-current (CC) to constant-voltage (CV) mode. If
  --   the current flow exceeds (ccFallbackRate * chargeCurrent) then the stage
  --   is sent back to CC mode from CV mode.
  ccFallbackRate = 1.1
end

function setTemperatureDisplayDefaults()
  -- During charging, DingoCharge displays the system temperature in the
  --   MiscInfo section. The Lua API provides temperature in Celsius, but this
  --   can be converted to Fahrenheit for locales that use it (e.g. USA).
  isTempDisplayF = false
end

function setExternalTemperatureDefaults()
  -- The algorithm can stop charging if an external temperature sensor on the
  --   D+ pin (for example, a TMP35/LM35, TMP36/LM50 or TMP37) exceeds a preset
  --   threshold, and optionally resume charging once the temperature problem
  --   subsides. Hysteresis prevents the algorithm from oscillating in and out
  --   of a temperature fault state too quickly.
  -- Note: Only the TMP36/LM50 are capable of measuring below temperatures
  --   below freezing (0 degrees C/32 degrees F), since they have a +0.5 volt
  --   offset that puts cold temperatures in range of the Shizuku's D+ pin ADC
  --   (0 to 3.3V). The TMP35/LM35/TMP37 will be unable to provide negative
  --   temperature readings, and therefore will not be able to trigger the
  --   undertemperature protection features.
  isExternalTemperatureEnabled = false -- false disables all temperature protections
  externalTemperatureOffsetVoltage = -0.5 -- 0V for TMP35/TMP37, -0.5V for TMP36, -2.7315 for LM135/LM235/LM335
  externalTemperatureGain = 100 -- 100x for 10mV/degC (TMP35, TMP36), 50x for 20mV/degC (TMP37)

  temperatureProtectionHysteresisC = 10 -- temperature must cool down/warm up past the protection threshold before charge resumes
  isOvertemperatureEnabled = true -- only if isExternalTemperatureEnabled is true
  isOvertemperatureRecoveryEnabled = true
  overtemperatureThresholdC = 50 -- if external temperature is greater than this value, stop charging
  
  isUndertemperatureEnabled = true -- only if isExternalTemperatureEnabled is true
  isUndertemperatureRecoveryEnabled = true
  undertemperatureThresholdC = 0 -- if external temperature is less than this value, stop charging
end

function setTimeLimitDefaults()
  -- The algorithm can stop charging if the process takes too long. Setting the
  --   time limit to 0 will disable timeout protection, as will setting the
  --   charge termination rate to 0.
  timeLimitHours = 24 -- set to 0 to disable
end

function setWaitForBatteryDefaults()
  -- DingoCharge can wait for the battery to be connected to the tester before
  --   beginning its current ramp-up. The timeout value allows a battery that
  --   is overdischarged (BMS in undervoltage lockout) to be charged even if
  --   it does not present any voltage on its terminals.
  waitForBatteryTimeout = 15 -- seconds; set to 0 to disable (start charging immediately, not recommended)
end

function resetAllDefaults()
  -- This function is called upon program initialization. All of the referenced
  --   functions above must be called here to ensure all settings are applied
  --   during startup.
  setDefaults()
  setPChgDefaults()
  setRefreshDefaults()
  setDeadbandDefaults()
  setAggressiveGcDefaults()
  setSystemSoundDefaults()
  setCableResistanceDefaults()
  setCcFallbackDefaults()
  setTemperatureDisplayDefaults()
  setExternalTemperatureDefaults()
  setTimeLimitDefaults()
  setWaitForBatteryDefaults()
end