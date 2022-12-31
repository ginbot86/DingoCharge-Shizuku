# DingoCharge for Shizuku

DingoCharge for Shizuku (simply referred to DingoCharge hereafter) is a Lua program that runs on the [YK-Lab Shizuku USB-C tester/multimeter](https://yk-lab.org:666/shizuku/manual/software/manual-pc-en-us/content.html), allowing it to become a highly customizable battery charger when connected to a compatible USB-C Power Delivery (PD) adapter that supports PPS (Programmable Power Supply) functionality. This tester is available under various names, like the YK-Lab YK001, AVHzY CT-3, Power-Z KT002, or the ATORCH UT18.

## Caution/disclaimer
Lithium-ion batteries can be dangerous if mishandled or abused! The author accepts no liability for direct or indirect damages caused by the use of this software, and absolutely no warranties or guarantees are provided. It is ultimately the user's (your) responsibility to understand the potential hazards of working with batteries and other electronics, and to correctly connect the battery to the tester to prevent damage (ensure the voltage ranges are compatible with the tester and adapter, and ensure that the correct polarity is used).

Follow the prompts in the program when they appear, and try to do them promptly (but don't rush yourself). Some steps require user intervention to connect/disconnect the battery and/or adapter, as the tester has no innate switching capabilities; in other words, you are manually performing the work of a relay/switch. :)

## How does DingoCharge work?
DingoCharge leverages the [USB PD PPS](https://www.belkin.com/us/support-article?articleNum=318878) protocol to control the amount of current that flows into a rechargeable battery (as of version 1.4.0, only lithium-ion chemistries are supported). By adjusting the difference between the battery's present voltage and the voltage being supplied from the adapter, the amount of current flowing into the battery can be controlled via closed-loop regulation; this provides software controlled constant-current and constant-voltage operation. The program also provides an easy-to-use interface to set up the required charging parameters (voltage, current, charge termination/cutoff, etc.), and also ensures that the requested settings are compatible with the adapter in use, as not all PD PPS adapters are equal.

The program is built around the [Lua API](https://yk-lab.org:666/index.php/2020/01/09/lua-programming-overview/) feature that is present on the Shizuku platform. The API provides the necessary functions to interact with a USB PD PPS adapter, as well as providing basic routines for the user interface.

## Who is DingoCharge for?
DingoCharge is meant for people with existing electronics/battery knowledge (hobbyists, technicians, technologists, engineers). The program should be relatively straightforward to operate if one knows the basics about (lithium-ion) battery charging, such as charge voltage/current, termination rate, battery precharging, and series configuration (1S, 2S, 3S...).

## Why use DingoCharge over a standalone charger?
DingoCharge takes advantage of existing features in hardware that you already purchased (the USB tester, USB-C to USB-C cable(s), and your USB-C PD adapter(s)). With a little bit of extra hardware (USB-C or USB-A plug to the various connections you may need to hook up the battery), you have a highly flexible battery charger for your projects.

## Extra hardware required
The only extra hardware required is a USB power cable that connects the VBUS and ground pins to your battery, and a microUSB cable to an external 5 volt USB power source (as of version 1.4.0), and the battery you want to charge (as of version 1.4.0, lithium-ion/lithium iron phosphate batteries with a 1S to 5S (2S to 4S recommended) configuration are supported, with experimental support for 2S-8S lithium-titanate chemistries added but untested). Examples include USB-A to 5.5x2.1mm barrel jacks, XT30/XT60, Deans, SAE, Anderson Powerpole connectors, or alligator clips. If your PD adapter supports PPS with more than 3 amps of current, you will need a suitably rated 5 amp/100 watt USB-C to USB-C cable to connect the tester to the adapter.

Since version 1.3.0, DingoCharge supports use of linear analog temperature sensors whose outputs range from 0 to 3.3 volts on the D+ pin (for example, the TMP35/LM35, TMP36/LM50, TMP37). Thermal protections are disabled unless the Ext Temp Sensor option is turned on in the Advanced menu or in the user defaults file.

DingoCharge will only work with the USB PD adapter connected to the tester's input, and the battery on the tester's output. It will not work if the connections are reversed.

### Considerations when using USB-C connectors from the tester to battery
If you are using a USB-C connector to connect the tester to the battery, ensure that the CC (configuration channel) pins are not connected to the tester, as this may interfere with USB PD communication. Because the USB-C connector has a different CC pin depending on plug orientation, it may be possible to flip the connector on the tester's output side so that the plug's CC resistor is on the opposite pin that is being used for communication between the adapter and tester.

## Software components
The program is split into:
1. Main program (charge control and status display)
2. Menu library
3. User preferences/defaults (provided as an editable Lua source file)
4. Development tools (.lua to .lc converters to compile Lua source into bytecode to conserve memory)

Only the first three components are mandatory for the program to function correctly. The menu library and user preferences/defaults are kept in a subdirectory beneath the main program so that the Shizuku operating system will not list them as executable scripts/programs.

## Installing DingoCharge
To install DingoCharge onto your tester:
1. Connect the tester's PC microUSB port to your computer using a microUSB cable.
2. Hold down the left key on the tester until a menu pops up.
   - Scroll down to select the `Mount USB Mass Storage` option. The tester should display `USB MSC Mounted`.
3. The tester should now appear as a removable USB drive with about 12 MB of capacity. Navigate to it using your computer's file browser.
4. Copy the contents of the `main` folder to the tester. The file structure inside should be as follows:
    - Drive root
	    - `lua`
		    - `user`
			    - `DingoCharge-Shizuku.lc`
			    - `DC4S`
				    - `UserDefaults-DC4S.lua`
              - `lib`
                - `DC4S-advancedMenu.lc`
                - `DC4S-cfgAggressiveGc.lc`
                - `DC4S-cfgCableRes.lc`
                - `DC4S-cfgCcFallbackRate.lc`
                - `DC4S-cfgCells.lc`
                - `DC4S-cfgCRate.lc`
                - `DC4S-cfgCurr.lc`
                - `DC4S-cfgDeadband.lc`
                - `DC4S-cfgDeadbandEntry.lc`
                - `DC4S-cfgExtTemp.lc`
                - `DC4S-cfgPChgCRate.lc`
                - `DC4S-cfgPChgVpc.lc`
                - `DC4S-cfgPreChg.lc`
                - `DC4S-cfgRefreshRate.lc`
                - `DC4S-cfgSounds.lc`
                - `DC4S-cfgTempDisplay.lc`
                - `DC4S-cfgTimeLimit.lc`
                - `DC4S-cfgVpc.lc`
                - `DC4S-chargerSetup.lc`
                - `DC4S-checkConfigs`
5. Wait a few seconds to allow the files to copy over.
5. Hold down the left key on the tester until a menu pops up again.
   - Scroll down to select the `Unmount USB Mass Storage` option. The tester should display `USB MSC Umounted`.

## How to use DingoCharge
Launching DingoCharge is the same as running any other script on the tester. If you are continuing from the previous section, skip to step 3.
1. Connect the tester's PC microUSB port to your computer, a USB power bank, or another 5V power source using a microUSB cable.
   - Ensure that the PD adapter and battery are **not** connected at this time.
2. Hold down the left key on the tester until a menu pops up.
3. Scroll down to select the `Lua Script Execute` option.
   - Select `DingoCharge-Shizuku.lc` from the list.
4. The DingoCharge main menu will appear. The most common settings for charge parameters are in the `Charger Setup...` submenu. These include:
   - Number of series cells (1S, 2S...)
   - Charge voltage per cell (3.65, 4.2, 4.35...) and total pack charge voltage
	   - Note: many PPS chargers only support a maximum of 11 volts, so a 3S or higher Li-ion configuration (4.2V/cell * 3 cells in series = 12.6V) may result in a compatibility test failure; see below for more information.
   - Charge current (amps, up to the maximum supported by the USB PD PPS adapter). Most Li-ion batteries can be safely charged at a C/5 to C/2 rate, but check with your battery's technical datasheet to be sure. For example, a 1000mAh (1Ah) battery would means a C/5 and C/2 rate would equal 0.2A and 0.5A, respectively.
   - Termination rate (relative to charge current; not to be confused with the charging C-rate of the battery)
	   - For example, if the charge current is set to 2 amps, a termination rate of 0.05C means that the charge process will stop once the current flowing into the battery is less than the termination rate (0.05 x 2 amps = 0.1 amps).
	- If desired, use the `Test Compatibility` option to verify that your desired charge settings are compatible with the PD PPS adapter. This is optional since a check will be performed before starting the charge process anyway.
    - If you want to tweak the battery precharge threshold (only applicable to overdischarged batteries), or compensate for additional resistance between the tester and the battery, these settings can be found in the `Advanced...` menu. Usually, this is not required and it is not recommended to over-compensate the resistance as it risks damaging the battery through overvoltage.
5. Once you are ready to charge the battery, select the `Start Charging` option in the main menu, and follow the prompts; you will be instructed to plug and unplug the battery and adapter a couple times. Use the `Confirm` option in the dialogs to continue, and `Cancel` to back out and return to the main menu.
   - The tester will perform a charger compatibility test, ensuring that the requested charge voltage and current is compatible with the PD PPS adapter (not all adapters will support the same levels of voltage and current, and not all PD adapters necessarily support PPS).
6. During the charging process, the main UI will display the battery's voltage, current and power flowing into the battery, as well as the present charge settings and the elapsed charging time. The tester will make a long beep when the charging process is finished.
7. When the charging process is finished, or if you need to make changes to the charge settings, unplug the USB-C cable that connects to the PD PPS adapter. The tester will display a `PD request failed!` error dialog, then select `Confirm` to return to the main menu. *(This is due to a limitation in the tester's Lua API, as there is no function available to obtain user input via the buttons outside of a menu or cancel/confirm dialog box.)*
   - If you want to quit DingoCharge, select `Exit` from the main menu.
   - If you are finished readjusting your charge settings, select `Start Charging` and complete the compatibility test process again.

## Licensing
This open-source software is licensed under the MIT License:

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Support
The author can be contacted via email at jasongin (at) jasongin (dot) com. No guarantees are provided that your email will necessarily be answered (in a timely manner), but a best-effort response can generally be anticipated.
