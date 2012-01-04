#include <XBee.h>



// XBEE setup -------------------------------
XBee xbee = XBee();
XBeeResponse response = XBeeResponse();
// create reusable response objects for responses we expect to handle 
Rx16Response rx16 = Rx16Response();
Rx64Response rx64 = Rx64Response();


int pinElwire = 13;
int speakerPin = 10;
int ledPin = 9;

// LED indicating XBee status
int statusLed = 4;
int errorLed = 3;
int dataLed = 5;

void setup(void)
{

  pinMode(statusLed, OUTPUT);
  pinMode(errorLed, OUTPUT);
  pinMode(dataLed,  OUTPUT);
  
  pinMode(pinElwire, OUTPUT);
  pinMode(speakerPin, OUTPUT);
  pinMode(ledPin, OUTPUT);
  
  xbee.begin(9600);
  flashLed(statusLed, 3, 50);
}


void loop(void)
{ 
    xbee.readPacket();
    
    if (xbee.getResponse().isAvailable()) {
      // got something
      
      if (xbee.getResponse().getApiId() == RX_16_RESPONSE || xbee.getResponse().getApiId() == RX_64_RESPONSE) {
        // got a rx packet
        
        if (xbee.getResponse().getApiId() == RX_16_RESPONSE) {
                xbee.getResponse().getRx16Response(rx16);
                
                flashLed(statusLed, 2, 50);
                
                //VALUE 1 determines which object is used (1 = elwire, 2 = led, 3 = speaker)
                uint8_t code0 = rx16.getData(0);
                uint8_t code1 = rx16.getData(1);
                uint8_t code2 = rx16.getData(2);
                uint8_t code3 = rx16.getData(3);
                uint8_t code4 = rx16.getData(4);
                uint8_t code5 = rx16.getData(5);
                uint8_t rfidreaderID = rx16.getData(6);
                
                Serial.print("ID: ");
                Serial.print(code0, HEX);
                Serial.print(code1, HEX);
                Serial.print(code2, HEX);
                Serial.print(code3, HEX);
                Serial.print(code4, HEX);
                //Serial.print(code5, HEX); don't print checksum
                //Serial.println("   / RFID-reader ID: ");
                
//                Serial.print(rfidreaderID);
                Serial.println("");
                
                flashLed(statusLed, 2, 50);
                
        } else {
                xbee.getResponse().getRx64Response(rx64);

        }
        
        flashLed(statusLed, 1, 10);
        
      } else {
      	// not something we were expecting
        flashLed(errorLed, 1, 25);    
      }
    }
 
}


// flash control LEDs to indicate status of the XBee     
void flashLed(int pin, int times, int wait) {
    
    for (int i = 0; i < times; i++) {
      digitalWrite(pin, HIGH);
      delay(wait);
      digitalWrite(pin, LOW);
      
      if (i + 1 < times) {
        delay(wait);
      }
    }
}

