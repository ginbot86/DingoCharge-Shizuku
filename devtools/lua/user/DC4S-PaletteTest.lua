--[[DingoCharge for Shizuku Platform - Palette Test
https://github.com/ginbot86/DingoCharge-Shizuku January 24, 2026.

Version history:
1.8.0: Created palette test developer tool to visualize all available colours in the Shizuku API and demonstrate how to print bold text (2026-01-24).]]

function showStringExtended(x, y, text, fontType, colorForeground, colorBackground, isBold)
-- showString(), now with free bold format support! :D (some restrictions apply, see in-store for details)
-- Examples:
--   showStringExtended(6, 7, "kobold", font.f1616, color.red, color.black, true) -- prints "kobold" to the screen at (6,7) as red-on-black but in bold (syntax similar to stock screen.showString())
--   showStringExtended(6, 7, "konormal", font.f1616, color.red, color.black) -- like above, but with the text implicitly NOT bolded, maintaining compatibility with the stock screen.showString()

-- caution: not validated with non-ASCII text. bold text will not render correctly if the right-hand side of the text goes past the screen edge (line wrap issues). unlike the stock screen.showString(), background and foreground colours must be defined (I couldn't get the API's THEME_COLOR or THEME_BACK_COLOR to work >.>)

  isBold = isBold or false -- this can help deduplicate code if you need to conditionally bold text
  
  screen.showString(x, y, text, fontType, colorForeground, colorBackground)
  if isBold then
    screen.showString(x+1, y, text, fontType, colorForeground, color.transparent) -- you can simulate a bold font if you double-stamp the text but shifted horizontally by 1 pixel with a transparent background! (results may vary. dense glyphs like "m", "w", etc. will smear and look worse this way)
  end
end

screenTime = 15 -- seconds

screen.open()
screen.clear()
screen.showDialog(string.format("Palette Test (%ds)",screenTime),"",0,false,color.white) -- note: this function will blank the screen from (4,16) to (158,107) if no body text is supplied

-- Primary/Untinted Colours

-- Red: value 0, RGB(248,0,0)
screen.fillRect(9,15,18,24,color.red)
screen.showString(6,26,"RED",font.f1212,color.white)

-- Blue: value 1, RGB(0,0,248)
screen.fillRect(36,15,45,24,color.blue)
screen.showString(30,26,"BLUE",font.f1212,color.white)

-- Blue: value 2, RGB(0,216,0)
screen.fillRect(69,15,78,24,color.green)
screen.showString(60,26,"GREEN",font.f1212,color.white)

-- Cyan: value 3, RGB(0,252,248)
screen.fillRect(101,15,110,24,color.cyan)
screen.showString(95,26,"CYAN",font.f1212,color.white)

-- Black: value 4, RGB(0,0,0)
screen.fillRect(134,15,143,24,color.black)
screen.drawRect(134,15,143,24,color.white)
screen.showString(125,26,"BLACK",font.f1212,color.white)

-- White: value 5, RGB(248,252,248)
screen.fillRect(18,38,27,47,color.white)
screen.showString(8,49,"WHITE",font.f1212,color.white)

-- Purple: value 6, RGB(248,0,248)
screen.fillRect(56,38,65,47,color.purple) -- more accurately this is magenta
screen.showString(45,49,"PURPLE",font.f1212,color.white)

-- Orange: value 7, RGB(248,208,64)
screen.fillRect(98,38,107,47,color.orange)
screen.showString(86,49,"ORANGE",font.f1212,color.white)

-- Grey: value 8, RGB(88,92,88)
screen.fillRect(134,38,143,47,color.grey) -- grey with an E
screen.showString(128,49,"GREY",font.f1212,color.white)

-- Yellow: value 9, RGB(248,252,0)
screen.fillRect(18,61,27,70,color.yellow)
screen.showString(6,72,"YELLOW",font.f1212,color.white)

-- Light Colours

-- Light Green: value 10, RGB(0,252,120)
screen.fillRect(56,61,65,70,color.lightGreen)
screen.showString(46,72,"LIGHT",font.f1212,color.white)
screen.showString(46,82,"GREEN",font.f1212,color.white)

-- Light Red: value 11, RGB(248,112,112)
screen.fillRect(98,61,107,70,color.lightRed)
screen.showString(89,72,"LIGHT",font.f1212,color.white)
screen.showString(96,82,"RED",font.f1212,color.white)

-- Light Yellow: value 12, RGB(248,252,144)
screen.fillRect(134,61,143,70,color.lightYellow)
screen.showString(125,72,"LIGHT",font.f1212,color.white)
screen.showString(121,82,"YELLOW",font.f1212,color.white)

-- Light Blue: value 13, RGB(120,208,248)
screen.fillRect(15,94,24,103,color.lightBlue)
screen.showString(6,105,"LIGHT",font.f1212,color.white)
screen.showString(8,115,"BLUE",font.f1212,color.white)

-- Light Purple: value 14, RGB(248,164,248)
screen.fillRect(56,94,65,103,color.lightPurple)
screen.showString(46,105,"LIGHT",font.f1212,color.white)
screen.showString(44,115,"PURPLE",font.f1212,color.white)

-- Dark Colours

-- Dim Gray: value 15, RGB(32,32,32)
screen.fillRect(98,94,107,103,color.dimGray) -- gray with an A. yes, it's different from color.grey. don't like it? talk to "kevin" in sys.gBoardTempK(). :P
screen.showString(94,105,"DIM",font.f1212,color.white)
screen.showString(92,115,"GRAY",font.f1212,color.white)

-- Special Colours

-- Transparent: value 16, no RGB equivalent
screen.fillRect(134,94,143,103,color.white) -- draw a white-and-grey checkerboard to demonstrate transparency
screen.fillRect(134,94,138,98,color.grey)
screen.fillRect(139,99,143,103,color.grey)
screen.fillRect(134,94,143,103,color.transparent) -- since it's transparent, this should not change anything visibly
screen.showString(122,105,"TRANS-",font.f1212,color.white)
screen.showString(122,115,"PARENT",font.f1212,color.white)

while screenTime > 0 do
  screen.fillRect(0, 0, 159, 13, color.white) -- blank and print over where the title bar goes rather than redraw the whole window
  showStringExtended(3, 1, string.format("Palette Test (%ds)", screenTime), font.f1212, color.black, color.white, true)

  delay.ms(1000)
  screenTime = screenTime - 1
end
os.exit(0)