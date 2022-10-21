--[[DingoCharge for Shizuku Platform - User-Defined Default Settings
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
  numCells = 3
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
  --   than 10% for a couple minutes).
  --   This can be helpful when the adapter is unable to fully reach its
  --   maximum reported voltage (in testing, 3 of 3 "21V" capable adapters only
  --   produced 19.95V~20.5V, preventing use with 5S Li-ion packs unless 
  --   4V/cell is selected).
  pcDeadband = 0.01 -- Amps, precharge mode
  ccDeadband = 0.025 -- Amps, constant-current mode
  cvDeadband = 0.01 -- Volts, constant-voltage mode
  tcDeadband = 0.01 -- Amps, end-of-charge mode
end

function setAggressiveGcDefaults()
  -- If enabled, Lua's collectgarbage() will be forced if free RAM is below
  -- this threshold. This check occurs during every charge regulation loop
  -- iteration. (Yes, this is a pretty blunt approach, but it works and it
  -- keeps the system stable...)
  -- Note: Although the option is provided to disable this behaviour, doing
  -- so will severely impact stability (the system will likely hang, or crash
  -- with an out-of-memory dialog within minutes or hours when running the main
  -- charging/UI loop).
  aggressiveGcThreshold = 16384 -- bytes
  isAggressiveGcEnabled = true -- should be true for proper program operation
end

function setSystemSoundDefaults()
  -- The Shizuku sound API is used to sound a beep on the splash screen, if a
  -- PD request fails, and when charging is finished (transition from CV to
  -- TC charge stage).
  isSystemSoundsEnabled = true
end

function setCableResistanceDefaults()
  -- The algorithm can compensate for additional cable resistance between the
  -- tester and the battery, which will raise the CC-to-CV threshold voltage
  -- and CV voltage by (current * cableResistance). The algorithm inherently
  -- compensates for resistance and offset from the adapter to the tester
  -- without the need to define it manually.
  -- Note: it is not recommended to overcompensate for downstream resistance
  -- as it poses a risk of damaging the battery through overvoltage/overcharge.
  cableResistance = 0
end

function setCcFallbackDefaults()
  -- The algorithm can protect against excessive current draw when the charge
  -- stage moves from constant-current (CC) to constant-voltage (CV) mode. If
  -- the current flow exceeds (ccFallbackRate * chargeCurrent) then the stage
  -- is sent back to CC mode from CV mode.
  ccFallbackRate = 1.1
end

function setTemperatureDisplayDefaults()
  -- During charging, DingoCharge displays the system temperature in the
  -- MiscInfo section. The Lua API provides temperature in Celsius, but this
  -- can be converted to Fahrenheit for locales that use it (e.g. USA).
  isTempDisplayF = false
end

function resetAllDefaults()
  -- This function is called upon program initialization. All of the referenced
  -- functions above must be called here to ensure all settings are applied at
  -- startup.
  setDefaults()
  setPChgDefaults()
  setRefreshDefaults()
  setDeadbandDefaults()
  setAggressiveGcDefaults()
  setSystemSoundDefaults()
  setCableResistanceDefaults()
  setCcFallbackDefaults()
  setTemperatureDisplayDefaults()
end