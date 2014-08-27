/*
 * Draws a set of thermometers for incoming XBee Sensor data
 * by Rob Faludi http://faludi.com
 */

// used for Mysql database 'temperature1'
//  library available from http://bezier.de/processing/libs/sql/
// fjenett 20120226
import de.bezier.data.sql.*;
import com.mysql.jdbc.*;
import java.sql.*;

// used for communication via xbee api
import processing.serial.*; 

// xbee api libraries available at http://code.google.com/p/xbee-api/
// Download the zip file, extract it, and copy the xbee-api jar file 
// and the log4j.jar file (located in the lib folder) inside a "code" 
// folder under this Processing sketch’s folder (save this sketch, then 
// click the Sketch menu and choose Show Sketch Folder).
import com.rapplogic.xbee.api.ApiId;
import com.rapplogic.xbee.api.PacketListener;
import com.rapplogic.xbee.api.XBee;
import com.rapplogic.xbee.api.XBeeResponse;
import com.rapplogic.xbee.api.zigbee.ZNetRxIoSampleResponse;

static String version = "1.04";

// *** REPLACE WITH THE SERIAL PORT (COM PORT) FOR YOUR LOCAL XBEE ***
static String mySerialPort = "COM9";

MySQL mysql;


// *** REPLACE WITH YOUR OWN MYSQL DATABASE ACCOUNT ***
static String database="temperature1";
static String user="cartemp";
static String pass="n5kwqndg";


// create and initialize a new xbee object
XBee xbee = new XBee();


int error=0;


// used to record time of last data post
float lastUpdate;

// the result of temperature data
float temperatureCelsius;

// to calculate avarage temperature
//float tempSum = 0.0;
//int tempCounter = 0;

// to calcurate processing time
float lastDraw;
float shortDelay;

// make an array list of thermometer objects for display
ArrayList thermometers = new ArrayList();
// create a font for display
PFont font;

void setup() {
  size(400, 650); // screen size
  smooth(); // anti-aliasing for graphic display


  // You’ll need to generate a font before you can run this sketch.
  // Click the Tools menu and choose Create Font. Click Sans Serif,
  // choose a size of 10, and click OK.
  font =  loadFont("SansSerif-10.vlw");
  textFont(font); // use the font for text

    // The log4j.properties file is required by the xbee api library, and 
  // needs to be in your data folder. You can find this file in the xbee
  // api library you downloaded earlier
  //PropertyConfigurator.configure(dataPath("")+"log4j.properties"); 
  PropertyConfigurator.configure(dataPath("log4j.properties")); 
  // Print a list in case the selected one doesn't work out
  println("Available serial ports:");
  println(Serial.list());
  try {
    // opens your serial port defined above, at 9600 baud
    xbee.open(mySerialPort, 9600);
  }
  catch (XBeeException e) {
    println("** Error opening XBee port: " + e + " **");
    println("Is your XBee plugged in to your computer?");
    println(
      "Did you set your COM port in the code near line 27?");
    error=1;
  }
  
  // open database file
  try {
    mysql = new MySQL( this, "localhost", database, user, pass );
    
      //java.sql.Connection conn = DriverManager.getConnection("jdbc:mysql://localhost/?user=" + user + "&password=" + pass );
      //java.sql.Statement s = conn.createStatement();
      //int result = s.executeUpdate("DESCRIBE " + database +";");
      
  } catch (Exception e) {
    println("** Error opening MySQL database: " + e + " **");
  }
  lastDraw = millis();
}


// draw loop executes continuously
void draw() {
  background(224); // draw a light gray background
  // report any serial port problems in the main window
  if (error == 1) {
    fill(0);
    text("** Error opening XBee port: **\n"+
      "Is your XBee plugged in to your computer?\n" +
      "Did you set your COM port in the code near line 20?", width/3, height/2);
  }
  SensorData data = new SensorData(); // create a data object
  data = getData(); // put data into the data object
  //data = getSimulatedData(); // uncomment this to use random data for testing

  // check that actual data came in:
  if (data.value >=0 && data.address != null) { 

    // check to see if a thermometer object already exists for this sensor
    int i;
    boolean foundIt = false;
    for (i=0; i <thermometers.size(); i++) {
      if ( ((Thermometer) thermometers.get(i)).address.equals(data.address) ) {
        foundIt = true;
        break;
      }
    }

    // *** ENABLE THIS CODE FOR LM335 temperature sensor ****
    // process the data value into a Celsius temperature reading for
    // LM335 with a 1/4 voltage divider
    //   (value as a ratio of 1023 times max ADC voltage times 
    //    4 (voltage divider value) divided by 10mV per degree
    //    minus zero Celsius in Kevin)
    if( data.address.equals("00:13:a2:00:40:78:f1:5b") ) { 
      //temperatureCelsius = (data.value/1023.0*1.20*4.0*100)-273.15;
      temperatureCelsius = (data.value/1023.0*1.30*4.0*100)-273.15 + 25.0;
      data.sensor = "LM335";
    }
    
    //    // *** ENABLE THIS CODE FOR TMP36 temperature sensor ****
    //    // process the data value into a Celsius temperature reading for
    //    // TMP36 with no voltage divider
    //    //   (value as a ratio of 1023 times max ADC voltage times 
    //    //    minus 500 mV reading at zero Celsius
    //    //    times 100 to scale for 10mv per degree C)
    // float temperatureCelsius = ((data.value/1023.0*1.25 - .5) *100); 
    
    //  LM35D with a 1/4 voltage divider
    if( data.address.equals("00:13:a2:00:40:78:f1:1d") ) { 
      temperatureCelsius = data.value/1023.0*1.20*4.0454*100;
      //temperatureCelsius = data.value;
      data.sensor = "LM35D";
    }
    
    println(" temp: " + round(temperatureCelsius) + "˚C");
 
    // to calculate average temperature
    //tempSum = tempSum + temperatureCelsius;
    //tempCounter++;
    

    // update the thermometer if it exists, otherwise create a new one
    if (foundIt) {
      ((Thermometer) thermometers.get(i)).temp = temperatureCelsius;
      //((Thermometer) thermometers.get(i)).temp = tempSum / tempCounter;
      ((Thermometer) thermometers.get(i)).sensor = data.sensor;
    }
    else if (thermometers.size() < 10) {
      thermometers.add(new Thermometer(data.address,35,450,
      (thermometers.size()) * 75 + 40, 20));
      ((Thermometer) thermometers.get(i)).temp = temperatureCelsius;
      //((Thermometer) thermometers.get(i)).temp = tempSum / tempCounter;
      ((Thermometer) thermometers.get(i)).sensor = data.sensor;
    }
    
    // draw the thermometers on the screen
    for (int j =0; j<thermometers.size(); j++) {
      ((Thermometer) thermometers.get(j)).render();
    }
    // post data to MySQL databas every minute
    if ((millis() - lastUpdate) > 900000) {
      for (int j =0; j<thermometers.size(); j++) {
        ((Thermometer) thermometers.get(j)).dataPost();
      }
      lastUpdate = millis();
      //tempSum = 0.0;
      //tempCounter = 0;
    } else if ((millis() - lastUpdate) < 0) {
      // for millis() overflow
      lastUpdate = millis();
    }
    
    //if (tempCounter > 8 ) {
    //  tempSum = 0.0;
    //  tempCounter = 0;
    //}
    
  }
  
  // to calcurate processing time
  println("  process time: " + (millis() - lastDraw ) + " milli seconds");
  if ((millis() - lastDraw) < 0) {
    // for millis() overflow
    shortDelay = 0.0;
  } else if ((millis() - lastDraw) > 28020) {
    shortDelay = millis() - lastDraw - 28020;
  }
  lastDraw = millis();
  delay(27850 - (int)shortDelay);
} // end of draw loop


// defines the data object
class SensorData {
  int value;
  String address;
  String sensor;
}


// defines the thermometer objects
class Thermometer {
  int sizeX, sizeY, posX, posY;
  int maxTemp = 90; // max of scale in degrees Celsius
  int minTemp = -10; // min of scale in degress Celsius
  float temp; // stores the temperature locally
  String address; // stores the address locally
  String sensor; // stores the sensor type locally
  int year, month, day;
  int hour, minute, second;
 

  Thermometer(String _address, int _sizeX, int _sizeY, 
  int _posX, int _posY) { // initialize thermometer object
    address = _address;
    sizeX = _sizeX;
    sizeY = _sizeY;
    posX = _posX;
    posY = _posY;
  }

  void dataPost() {
    //initialize MySQL and Feed objects
    try {
      if ( mysql.connect() )
      {
        try {
          //mysql.query( "INSERT INTO %s SET temp=%f, address='%s';", database, temp, address );
          mysql.query( "INSERT INTO " + database + " ( temp, address, sensor ) VALUES (" + temp + ", '" + address + "', '" + sensor + "' );" );
        } catch (Exception e) {
          println("** Error adding data into MySQL database: " + e + " **");
        }
      }
    } catch (Exception e) {
          println("** Error connecting MySQL database: " + e + " **");
    }
  }

  void render() { // draw thermometer on screen
    noStroke(); // remove shape edges
    ellipseMode(CENTER); // center bulb
    float bulbSize = sizeX + (sizeX * 0.5); // determine bulb size
    int stemSize = 30; // stem augments fixed red bulb 
    // to help separate it from moving mercury
    // limit display to range
    float displayTemp = round( temp );
    if (temp > maxTemp) {
      displayTemp = maxTemp + 1;
    }
    if ((int)temp < minTemp) {
      displayTemp = minTemp;
    }
    // size for variable red area:
    float mercury = ( 1 - ( (displayTemp-minTemp) / (maxTemp-minTemp) )); 
    // draw edges of objects in black
    fill(0); 
    rect(posX-3,posY-3,sizeX+5,sizeY+5); 
    ellipse(posX+sizeX/2,posY+sizeY+stemSize, bulbSize+4,bulbSize+4);
    rect(posX-3, posY+sizeY, sizeX+5,stemSize+5);
    // draw grey mercury background
    fill(64); 
    rect(posX,posY,sizeX,sizeY);
    // draw red areas
    fill(255,16,16);

    // draw mercury area:
    rect(posX,posY+(sizeY * mercury), 
    sizeX, sizeY-(sizeY * mercury));

    // draw stem area:
    rect(posX, posY+sizeY, sizeX,stemSize); 

    // draw red bulb:
    ellipse(posX+sizeX/2,posY+sizeY + stemSize, bulbSize,bulbSize); 

    // get current date & time to draw
    year = year();
    month = month();
    day = day();
    hour = hour();
    minute = minute();
    second = second();
    String strMonth, strDay, strHour, strMinute, strSecond;
    if ( month < 10 ) {
      strMonth = "0" + String.valueOf(month);
    } else {
      strMonth = String.valueOf(month);
    }
    if ( day < 10 ) {
      strDay = "0" + String.valueOf(day);
    } else {
      strDay = String.valueOf(day);
    }
    if ( hour < 10 ) {
      strHour = "0" + String.valueOf(hour);
    } else {
      strHour = String.valueOf(hour);
    }
    if ( minute < 10 ) {
      strMinute = "0" + String.valueOf(minute);
    } else {
      strMinute = String.valueOf(minute);
    }
    if ( second < 10 ) {
      strSecond = "0" + String.valueOf(second);
    } else {
      strSecond = String.valueOf(second);
    }
    String dateNow = String.valueOf(year) + "." + strMonth + "." + strDay;
    String timeNow = strHour + ":" + strMinute + ":" + strSecond;

    // show text
    textAlign(LEFT);
    fill(0);
    textSize(10);

    // show sensor address:
    //text(address, posX-10, posY + sizeY + bulbSize + stemSize + 4, 65, 40);
    text(address, posX-10, posY + sizeY + bulbSize + stemSize + 38, 65, 40);


    // show current date:
    text(dateNow, posX-10, posY + sizeY + bulbSize + stemSize + 0, 65, 11);

    // show current time:
    text(timeNow, posX-10, posY + sizeY + bulbSize + stemSize + 14, 65, 11);

    // show current time:
    text(sensor, posX-10, posY + sizeY + bulbSize + stemSize + 78, 65, 11);


    // show maximum temperature: 
    text(maxTemp + "˚C", posX+sizeX + 5, posY); 

    // show minimum temperature:
    text(minTemp + "˚C", posX+sizeX + 5, posY + sizeY); 

    // show temperature:
    text(round(temp) + " ˚C", posX+2,posY+(sizeY * mercury+ 14));
  }
}

// used only if getSimulatedData is uncommented in draw loop
//
//SensorData getSimulatedData() {
//  SensorData data = new SensorData();
//  int value = int(random(750,890));
//  String address = "00:13:A2:00:40:78:F1:58" + str( round(random(0,2)) );  // end device?
//  data.value = value;
//  data.address = address;
//  delay(200);
//  return data;
//}

// queries the XBee for incoming I/O data frames 
// and parses them into a data object
SensorData getData() {

  SensorData data = new SensorData();
  int value = -1;      // returns an impossible value if there's an error
  String address = ""; // returns a null value if there's an error

  try {
    // send a Force Sampling Request
    ZBForceSampleRequest request = new ZBForceSampleRequest(XBeeAddress64.BROADCAST);
    request.setApplyChanges(true);  // packet option
    
    int timeout = 28000;  //default timeout is 5000ms
    xbee.sendSynchronous(request, timeout);
    // Synchronous method for sending an XBeeRequest and obtaining the corresponding response
    //  (response that has same frame id).
  }
  catch (XBeeException e) {
    println("Error sending request: " + e);
  }

  try {
    // we wait here until a packet is received.
    XBeeResponse response = xbee.getResponse();
    // uncomment next line for additional debugging information
    //println("Received response " + response.toString()); 

    // check that this frame is a valid I/O sample, then parse it as such
    if (response.getApiId() == ApiId.REMOTE_AT_RESPONSE 
      && !response.isError()) {
      RemoteAtResponse ioSample = 
        (RemoteAtResponse)(AtCommandResponse)(XBeeFrameIdResponse)response;

      // get the sender's 64-bit address
      int[] addressArray = ioSample.getRemoteAddress64().getAddress();
      // parse the address int array into a formatted string
      String[] hexAddress = new String[addressArray.length];
      for (int i=0; i<addressArray.length;i++) {
        // format each address byte with leading zeros:
        hexAddress[i] = String.format("%02x", addressArray[i]);
      }

      // join the array together with colons for readability:
      String senderAddress = join(hexAddress, ":"); 
      print("  sender address: " + senderAddress);
      data.address = senderAddress;
      
      // get the value of the first input pin
      int[] valueArray = ioSample.getValue();
      String[] hexValue = new String[2];
      int k = 0;
      for (int j=valueArray.length-2; j<valueArray.length; j++) {
          hexValue[k] = String.format("%02x", valueArray[j]);
          print(" value[" + k + "] : " + hexValue[k] );
          k++;
      }
      // join the array together:
      String strHexValue = join(hexValue, ""); 
      value = Integer.parseInt(strHexValue, 16);
      print("  analog value: " + value ); 
      data.value = value;
    }
    else if (!response.isError()) {
      println("Got error in data frame");
    }
    else {
      println("Got non-i/o data frame");
    }
  }
  catch (XBeeException e) {
    println("Error receiving response: " + e);
  }
  return data; // sends the data back to the calling function
}

