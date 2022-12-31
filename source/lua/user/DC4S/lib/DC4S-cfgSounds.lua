--[[DingoCharge for Shizuku Platform - System Sounds Configuration Menu
https://ripitapart.com December 15, 2022.

Version history:
1.4.0: Split off monolithic menu library functions into individual files (2022-12-15).]]

function cfgSounds()
  local cfgSoundSel = 0
  local soundMenuValue = " "
  while true do
    if isSystemSoundsEnabled then
      soundMenuValue = "On"
    else
      soundMenuValue = "Off"
    end
    
    cfgSoundSel = screen.popMenu{string.format("Keep Current (%s)", soundMenuValue), "Sounds Off", "Sounds On", "Restore Defaults"}
    if cfgSoundSel == 1 then
      isSystemSoundsEnabled = false
      break
    elseif cfgSoundSel == 2 then
      isSystemSoundsEnabled = true
      break
    elseif cfgSoundSel == 3 then
      if (screen.popYesOrNo("Restore defaults?",color.yellow)) then
        setSystemSoundDefaults()
        screen.popHint("Defaults Restored", 1000)    
      end
    else
      break
    end
  end
  
  if isSystemSoundsEnabled then
    screen.popHint("Sounds On", 1000)
  else
    screen.popHint("Sounds Off", 1000)
  end
  -- discard temporary variables
  cfgSoundSel = nil
  soundMenuValue = nil
  collectgarbage("collect") -- clean up memory
end