# Simple Sensor Network MySQL

 Draws a set of thermometers for incoming XBee Sensor data and save to MySQL

## Description

This Processing code is a modification of Rob Faludi's sample code 'Simple_Sensor_Network.pde' of "Building Wireless Sensor Networks" Book.
https://www.faludi.com/bwsn/

 ZED (ZigBee End Device) will repeat the cycle of waking up for 2 seconds and then sleeping for 26 seconds. If you prepare a MySQL account and database, ZC (ZigBee Coordinator) will receive Temperature data and write it to the database every 15 minutes.

## Getting Started

You use two XBee S2 modules. (One used for ZED, the other for ZC.) OUT of temperature sensor LM335 is connected to physical pin 20 (D0) of ZED. ZC connects to the USB port of the computer.
Start Processing 2 program. Write your COM port for ZC, ZED 64bit address, MySQL account and database to the source code. Then run your code.

### Prerequisites

* Digi X-CTU 5.2.8+
* Processing 2.2+
* [Java xbee-api](https://code.google.com/p/xbee-api/) 0.9  - include log4j, RXTXcomm library
* [BezierSQLib](http://bezier.de/processing/libs/sql/) 0.2  - Processing library
* MySQL 5.6+

Open "Simple_Sensor_Network_MySQL.pde" with Processing 2 and change the name to your own project folder and save it. Then, subfolders "code" and "data" are automatically created.
In this code subfolder, copy the three files xbee-api-0.x.jar, log4j.jar, RXTXcomm.jar from the xbee-api-0.x.zip.
Install BezierSQLib from Processing 2 menu, Sketch > Import Library > Add Library.

the ZED with a breadboard layout is  [here](https://www.faludi.com/bwsn/tmp36-instructions-simple-sensor-network/).

### Installing

#### ZED (ZigBee End Device) X-CTU Configuration
* Select XBee COM port
* Do not forget to check "Enable API" and "Use escape characters (ATAP = 2)"
Then switch to the Modem Configuration tab and press the Read button.
* Set to "XB24-ZB" in Modem
* "ZIGBEE END DEVICE API" in Function Set
* "29A7" in Version.
* Set the PAN ID with your favorite number.
* In the item of Serial Interfacing, enter "2" in AP-API Enable
* In the item of I/O Settings, select "2 - ADC" (analog input) from the list box for D0 - AD0 / DIO0 Configuration
* Be sure to check that Allways Update Firmware is unchecked
Press the Write button to write to the XBee S2 module.

#### ZC (ZigBee Coordinator) X-CTU Configuration
* Launch X-CTU anew and Select XBee COM port
* Set ATAP = 2 (use escape character) in API mode
* Set to "XB24-ZB" in Modem
* "ZIGBEE COORDINATOR API" in Function Set
* "21A​​7" in Version.
* In the item of Serial Interfacing, enter "2" in AP - API Enable
* Set the same number as ZED for PAN ID
Press the Write button to write.

#### Communication Tests
Click the Remote Configuration menu in the X-CTU window on the ZC side.
When you click Open Com Port in Network window and then open Discover, the same device as your PAN ID will be displayed.
Replace the ZED with a breadboard assembled test environment. In the breadboard assembled test environment, OUT of temperature sensor LM335 is connected to phisical pin 20 (D0).
Click the Terminal tab of the X-CTU on the ZC side, and then press the Assemble Packet button.
* Since the Send Packet window opens, change the check button from "ASCII" to "HEX" (hexadecimal number) in the lower right
* In the text box, enter the ZigBee remote AT command (17) packet to send to ZED in hexadecimal (XXXXXXXX are the last 32 bits of the 64 bit address of your XBee module. YY is a checksum.)
```
7E000F17010013A200XXXXXXXXFFFE024953YY
```
If communication with ZED is successful, ZigBee response (97) packet will be returned from ZED. (The response packet is displayed in red letters so you can see immediately.)

#### ZED X-CTU Reconfiguration for Sleep Mode
Set the sleep mode on the XBee S2 module so that the battery lasts long.
First, Change ZED to XBee Explorer USB dongle, start X-CTU and press Test / Query to recognize ZED.
* In the item of Sleep Modes, set Sleep Mode to "4: CYCLIC SLEEP"
* Rewrite ST (Time Before Sleep) as 2 seconds = 2000 (decimal number) milliseconds → 0x7D0 (hexadecimal number)
* Enter SP (Sleep Period) as 26 seconds = 26000 milliseconds = 2600 (decimal number) x 10 milliseconds → 0xA28 (hexadecimal number)
* Rewrite SO (Sleep Options) to 0x02 (cycle cycle is repeated all the time)
It is now set to repeat the cycle of waking up for 2 seconds and then sleeping for 26 seconds.
Press Write button to write to ZED. Be sure to press the Read button / Write button during the wake-up period when loading or rewriting the firmware to ZED where sleep is set.

#### ZC X-CTU Reconfiguration for Sleep Mode
Subsequently, the ZC side also sets for sleep compatibility.
The SP (Sleep Period) value of ZC or ZR (ZigBee Router) must be larger than the SP value of all sleep mode ZED participating in the network. (However, the maximum value that can be set is limited to 28000 milliseconds = 28 seconds.)
* Enter the SP (Sleep Period) value on the ZC side as 28 seconds = 28000 milliseconds = 2800 (decimal number) x 10 milliseconds → 0xAF0 (hexadecimal number)

## Authors

* **kaz@Capsellab**

## License

This project is licensed under the MIT License

## Acknowledgments

* Thank Mr. Falud for his great work.
