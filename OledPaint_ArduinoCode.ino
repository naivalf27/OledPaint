#include <ESP8266WiFi.h>
#include <WiFiUDP.h>
#include <Arduino.h>
#include <U8g2lib.h>
#include <SPI.h>
#include <Wire.h>
 
#define DEBUG_MODE
#define SERIAL_BAUD             115200
 
#define UDP_TX_PACKET_MAX_SIZE  512 // 120 points max par trames
 
#define MAX_WIDTH               128
#define MAX_HEIGHT              64
#define MAX_POINTS              (MAX_WIDTH*MAX_HEIGHT)
 
#define UDP_LOCAL_PORT          8888
 
#define WIFI_LED                D0
#define UDP_LED                 D5
 
 
U8G2_SSD1306_128X64_NONAME_2_SW_I2C u8g2(U8G2_R0, D1, D2);
WiFiUDP UDP;
 
const char * SZ_SSID = "ProjetESP";
const char * SZ_PASSWORD = "aabbaabb";
 
boolean bWifiConnected = false;
boolean bUdpConnected = false;
 
char cPacketBuffer[UDP_TX_PACKET_MAX_SIZE]; //buffer to hold incoming packet,
 
unsigned int uiWidth;
unsigned int uiHeight;
 
bool bPoint[MAX_WIDTH][MAX_HEIGHT];
 
 
boolean connectUDP();
boolean connectWifi();
 
int readUdp( char * trame, unsigned int iSize  );
void clearPoints();
void drawPoints( );
 
void setup() {
  // Initialise Serial connection
  Serial.begin(SERIAL_BAUD);
  clearPoints();
 
  uiWidth = 0;
  uiHeight = 0;
 
  pinMode(WIFI_LED,OUTPUT);
  pinMode(UDP_LED,OUTPUT);
 
  u8g2.begin();
  u8g2.setFont(u8g2_font_ncenB10_tr);
 
  bWifiConnected = connectWifi();
 
  if(bWifiConnected){
    bUdpConnected = connectUDP();
  }
 
  digitalWrite(UDP_LED, bUdpConnected);
  digitalWrite(WIFI_LED, bWifiConnected);
}
 
void loop() {
  if(bWifiConnected && bUdpConnected){
    if(UDP.parsePacket()){
      unsigned int uiCount = UDP.read(cPacketBuffer,UDP_TX_PACKET_MAX_SIZE);
      readUdp( cPacketBuffer, uiCount );
    }
 
    delay(10);
  }
}
 
void clearPoints( ) {
  for( int x = 0; x < MAX_WIDTH; x ++ ) {
    for( int y = 0; y < MAX_HEIGHT; y ++ ) {
      bPoint[x][y] = false;
    }
  }
}
 
void drawPoints( ) {
  u8g2.firstPage();
 
  do {
    for( int x = 0; x < MAX_WIDTH; x ++ ) {
      for( int y = 0; y < MAX_HEIGHT; y ++ ) {
        if( bPoint[x][y] == true ) {
          u8g2.drawBox(x,y,1,1);
        }
      }
    }
  } while(u8g2.nextPage());
 
}
 
int readUdp( char * trame, unsigned int iSize  ) {
  unsigned int nbOfPointsCounted = 0;
  char flag = trame[0];
 
  switch( flag ) {
    case 0x04: { // Clear
      u8g2.clear();
      clearPoints();
      Serial.println( "clear" );
      break;
    }
    case 0x01: { // Width
      uiWidth = (trame[1]<<8)|trame[2];
 
      #ifdef DEBUG_MODE
        Serial.print( "Width : " );
        Serial.println( uiWidth );
      #endif
 
      break;
    }
    case 0x02: { // Height
      uiHeight = (trame[1]<<8)|trame[2];
 
      #ifdef DEBUG_MODE
        Serial.print( "Height : " );
        Serial.println( uiHeight );
      #endif
 
      break;
    }
    case 0x03: { // Points
      // Before drawing into the OLED with need the width+height of the device
      if( uiWidth == 0 || uiHeight == 0 ) {
        return -2;
      }
 
      unsigned int nbPoints = (trame[1]<<8)|trame[2];
      unsigned int nbOfPointsCounted = 0;
      unsigned int x, y;
 
      while( nbOfPointsCounted < nbPoints ) {
        x = (trame[3+(4*nbOfPointsCounted)]<<8)|trame[4+(4*nbOfPointsCounted)];
        y = (trame[5+(4*nbOfPointsCounted)]<<8)|trame[6+(4*nbOfPointsCounted)];
 
        x = (unsigned int)((double(x)/double(uiWidth))*double(MAX_WIDTH));
        y = (unsigned int)((double(y)/double(uiHeight))*double(MAX_HEIGHT));

        x = min(x,MAX_WIDTH);
        y = min(y,MAX_HEIGHT);
 
        nbOfPointsCounted ++;
 
        #ifdef DEBUG_MODE
          Serial.print( "Drawing point at x : " );
          Serial.print( x );
          Serial.print( " & y : " );
          Serial.println( y );
        #endif
 
        bPoint[x][y] = true;
      }

      drawPoints();
     
      break;
    }
    default: {
      return -1;
    }
  }
 
  return 0;
}
 
// connect to UDP – returns true if successful or false if not
boolean connectUDP(){
  boolean state = false;
 
  #ifdef DEBUG_MODE
    Serial.println("");
    Serial.println("Connecting to UDP");
 
    if(UDP.begin(UDP_LOCAL_PORT) == 1){
      Serial.println("Connection successful");
      state = true;
    }
    else{
      Serial.println("Connection failed");
    }
  #else
    state = (UDP.begin(localPort) == 1);
  #endif
 
  return state;
}
// connect to wifi – returns true if successful or false if not
boolean connectWifi(){
  boolean state = true;
  int i = 0;
  WiFi.begin(SZ_SSID, SZ_PASSWORD);
 
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    if (i > 100){
      state = false;
      break;
    }
    i++;
  }
 
  if (state){
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("");
    Serial.println("Connection failed.");
  }
 
  return state;
}
