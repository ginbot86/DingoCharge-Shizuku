--[[DingoCharge for Shizuku Platform - Utility Functions
https://github.com/ginbot86/DingoCharge-Shizuku January 12, 2026.

Version history:
1.8.0: Moved utility functions out from the main DingoCharge-Shizuku.lua source into a dedicated file (2026-01-12).
       Added an extended string print function that supports limited bold text display (2026-01-28).
       Added experimental filtered ADC functions (2026-01-28).
       Added optional parameters to make drawMeter() use bold text (2026-01-29).]]

function readVoltageFiltered(numSamples)
  local sum = 0
  local iterationCount = 0
  
  while iterationCount < numSamples do
    sum = sum + meter.readVoltage()
    iterationCount = iterationCount + 1
  end
  
  return sum / numSamples
end

function readCurrentFiltered(numSamples)
  local sum = 0
  local iterationCount = 0
  
  while iterationCount < numSamples do
    sum = sum + meter.readCurrent()
    iterationCount = iterationCount + 1
  end
  
  return sum / numSamples
end

function readPowerFiltered(numSamples)
  local sum = 0
  local iterationCount = 0
  
  while iterationCount < numSamples do
    sum = sum + meter.readPower()
    iterationCount = iterationCount + 1
  end
  
  return sum / numSamples
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

function showStringExtended(x, y, text, fontType, colorForeground, colorBackground, isBold)
-- showString(), now with free bold format support! :D (some restrictions apply, see in-store for details)
-- Examples:
--   showStringExtended(6, 7, "kobold", font.f1616, color.red, color.black, true) -- prints "kobold" to the screen at (6,7) as red-on-black but in bold (syntax similar to stock screen.showString())
--   showStringExtended(6, 7, "konormal", font.f1616, color.red, color.black) -- like above, but with the text implicitly NOT bolded, maintaining compatibility with the stock screen.showString()

-- caution: not validated with non-ASCII text. bold text will not render correctly if the right-hand side of the text goes past the screen edge (line wrap issues). unlike the stock screen.showString(), background and foreground colours must be defined (I couldn't get the API's THEME_COLOR or THEME_BACK_COLOR to work >.>)

  -- normalize arguments for legacy / mistaken parameter positions
  if type(colorBackground) == "boolean" then
    isBold = colorBackground
    colorBackground = color.black
  end
  
  if type(colorForeground) == "boolean" then
    isBold = colorForeground
    colorForeground = color.white
  end

  if type(colorForeground) ~= "number" then
    colorForeground = color.white
  end

  if type(colorBackground) ~= "number" then
    colorBackground = color.black
  end

  isBold = isBold or false -- this can help deduplicate code if you need to conditionally bold text
  
  screen.showString(x, y, text, fontType, colorForeground, colorBackground)
  if isBold then
    screen.showString(x+1, y, text, fontType, colorForeground, color.transparent) -- you can simulate a bold font if you double-stamp the text but shifted horizontally by 1 pixel with a transparent background! (results may vary. dense glyphs like "m", "w", etc. will smear and look worse this way)
  end
end

function drawMeter(x, y, title, value, unit, meterColor, backColor, isTitleBold, isMeterBold)
  meterColor = meterColor or color.white
  backColor = backColor or color.black
  isTitleBold = isTitleBold or false
  isMeterBold = isMeterBold or false
  local meterText = ""
  
  screen.fillRect(x, y, x+92, y+36, backColor)
  screen.drawRect(x, y+3, x+92, y+36, meterColor)
  screen.showString(x+3, y, "-", font.f0508, meterColor, backColor) -- preceding hyphen creates 1 pixel space between border and title text on left
  showStringExtended(x+9, y, title, font.f0508, meterColor, backColor, isTitleBold)
  if (math.abs(value) < 10) then -- 1.234
    meterText = string.format("%.3f%s", value, unit)
  elseif (math.abs(value) < 100) then -- 12.34
    meterText = string.format("%.2f%s", value, unit)
  elseif (math.abs(value) < 1000) then -- 123.4
    meterText = string.format("%.1f%s", value, unit)
  else -- 1234
    meterText = string.format("%.0f%s", value, unit)
  end
  showStringExtended(x+6, y+9, meterText, font.f1424, meterColor, backColor, isMeterBold)
end

function printStatusbar(text, textColor, barColor, backColor)
  local drawTextColor = textColor or color.white
  local drawLineColor = barColor or color.white
  local drawBackColor = backColor or color.black
  screen.fillRect(0, 117, 159, 127, drawBackColor)
  screen.showString(0, 117, text, font.f1212, drawTextColor, drawBackColor)
  screen.drawRect(0, 116, 159, 116, drawLineColor) -- there is no drawLine() in the Shizuku API, so this'll have to do
end

function startSessionTimer()
  sessionTimerStart = sys.gTick() / 1000 -- Shizuku firmware v1.00.62 caused os.date() to advance 10 times faster than it should, so all calls to os.date() are now replaced with calls to sys.gTick() which has a 1ms granularity
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
  sessionTimerNow = sys.gTick() / 1000
end

function updateSessionTimer()
  if isSessionTimerEnabled then
    sessionTimerNow = sys.gTick() / 1000
  else
    sessionTimerStart = (sessionTimerStart - sessionTimerNow) + (sys.gTick() / 1000) -- advance start timer to compensate for time spent while session timer stopped
    sessionTimerNow = sys.gTick() / 1000
  end
end