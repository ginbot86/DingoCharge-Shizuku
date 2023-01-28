--[[DingoCharge for Shizuku Platform - Cable Resistance Configuration Menu
https://ripitapart.com December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).
1.5.0: Fixed issue where configuration menu libraries remain resident in memory even when no longer needed (2023-01-21).]]

function cfgCableRes()
  screen.clear()
  local resSel = 0
  
  while true do
    resSel = screen.popMenu({string.format("Keep Current (%0.3f\3)", cableResistance), "Set Cable Resistance...", "Restore Defaults"})
    screen.clear()
    local tmpRes = cableResistance
    if resSel == 1 then
      -- Integer, always <1 ohm
      tmpRes = 0
      -- Tenths
      tmpRes = tmpRes + (0.1 * screen.popMenu({string.format("%0.1fxx\3",tmpRes),string.format("%0.1fxx\3",tmpRes + 0.1),string.format("%0.1fxx\3",tmpRes + 0.2),string.format("%0.1fxx\3",tmpRes + 0.3),string.format("%0.1fxx\3",tmpRes + 0.4),string.format("%0.1fxx\3",tmpRes + 0.5),string.format("%0.1fxx\3",tmpRes + 0.6),string.format("%0.1fxx\3",tmpRes + 0.7),string.format("%0.1fxx\3",tmpRes + 0.8),string.format("%0.1fxx\3",tmpRes + 0.9)}))
      -- Hundredths
      tmpRes = tmpRes + (0.01 * screen.popMenu({string.format("%0.2fx\3",tmpRes),string.format("%0.2fx\3",tmpRes + 0.01),string.format("%0.2fx\3",tmpRes + 0.02),string.format("%0.2fx\3",tmpRes + 0.03),string.format("%0.2fx\3",tmpRes + 0.04),string.format("%0.2fx\3",tmpRes + 0.05),string.format("%0.2fx\3",tmpRes + 0.06),string.format("%0.2fx\3",tmpRes + 0.07),string.format("%0.2fx\3",tmpRes + 0.08),string.format("%0.2fx\3",tmpRes + 0.09)}))
      -- Thousandths
      tmpRes = tmpRes + (0.001 * screen.popMenu({string.format("%0.3f\3",tmpRes),string.format("%0.3f\3",tmpRes + 0.001),string.format("%0.3f\3",tmpRes + 0.002),string.format("%0.3f\3",tmpRes + 0.003),string.format("%0.3f\3",tmpRes + 0.004),string.format("%0.3f\3",tmpRes + 0.005),string.format("%0.3f\3",tmpRes + 0.006),string.format("%0.3f\3",tmpRes + 0.007),string.format("%0.3f\3",tmpRes + 0.008),string.format("%0.3f\3",tmpRes + 0.009)}))
      cableResistance = tmpRes
      break
    elseif resSel == 2 then
      if (screen.popYesOrNo("Restore defaults?", color.yellow)) then
        setCableResistanceDefaults()
        screen.popHint("Defaults Restored", 1000)
      end
    else
      break
    end
  end
    
  screen.popHint(string.format("%0.3f Ohm",cableResistance), 1000) -- font.f1616 has no Ω glyph
  if (cableResistance == 0.69) or (cableResistance == 0.069) then
    screen.popHint("Nice", 1000) -- Should I keep this? Eh, why not, it's a fun little Easter egg I guess.
  end
  -- discard temporary variables
  resSel = nil
  tmpRes = nil
  cfgCableRes = nil
  package.loaded["lua/user/DC4S/lib/DC4S-cfgCableRes"] = nil
  collectgarbage("collect") -- clean up memory
end