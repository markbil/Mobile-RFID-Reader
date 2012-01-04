// Mobile XBee RFID reader ID-12 for Arduino 
// Based on
// - code by djmatic http://www.arduino.cc/playground/Code/ID12
// - code by BARRAGAN http://people.interaction-ivrea.it/h.barragan 
// - and code from HC Gilje - http://hcgilje.wordpress.com/resources/rfid_id12_tagreader/
// - checksum by Martijn The - http://www.martijnthe.nl/html

#include <XBee.h>
#include <NewSoftSerial.h>


NewSoftSerial mySerial(8, 9);

//---  XBEE-SETUP ---------------------------

XBee xbee = XBee();
unsigned long start = millis();
uint8_t payload[9]; // payload array lenght needs to be one higher than # bytes to be transmitted

// 16-bit addressing: Enter address of remote XBee, typically the coordinator
Tx16Request tx = Tx16Request(0x5001, payload, sizeof(payload));
TxStatusResponse txStatus = TxStatusResponse();

int readerID = 1;
int statusLed = 6;
int errorLed = 7;


void setup(void)
{

  xbee.begin(9600);  
  mySerial.begin(9600);
  Serial.begin(9600);

  // initialise xbee feedback LEDs
  pinMode(statusLed, OUTPUT);
  pinMode(errorLed, OUTPUT);

}


void loop(void)
{ 
  
  byte i = 0;
  byte val = 0;
  byte code[6];
  byte checksum = 0;
  byte bytesread = 0;
  byte tempbyte = 0;

  if(mySerial.available() > 0) {
    if((val = mySerial.read()) == 2) {                  // check for header 
      bytesread = 0; 
      while (bytesread < 12) {                        // read 10 digit code + 2 digit checksum
        if( mySerial.available() > 0) { 
          val = mySerial.read();
          if((val == 0x0D)||(val == 0x0A)||(val == 0x03)||(val == 0x02)) { // if header or stop bytes before the 10 digit reading 
            break;                                    // stop reading
          }

          // Do Ascii/Hex conversion:
          if ((val >= '0') && (val <= '9')) {
            val = val - '0';
          } else if ((val >= 'A') && (val <= 'F')) {
            val = 10 + val - 'A';
          }

          // Every two hex-digits, add byte to code:
          if (bytesread & 1 == 1) {
            // make some space for this hex-digit by
            // shifting the previous hex-digit with 4 bits to the left:
            code[bytesread >> 1] = (val | (tempbyte << 4));

            if (bytesread >> 1 != 5) {                // If we're at the checksum byte,
              checksum ^= code[bytesread >> 1];       // Calculate the checksum... (XOR)
            };
          } else {
            tempbyte = val;                           // Store the first hex digit first...
          };

          bytesread++;                                // ready to read next digit
        } 
      } 

      // Output to Serial:

      if (bytesread == 12) {                          // if 12 digit read is complete
        Serial.print("5-byte code: ");
        for (i=0; i<5; i++) {
          if (code[i] < 16) Serial.print("0");
          Serial.print(code[i], HEX);
          Serial.print(" ");
        }
        Serial.println();

        Serial.print("Checksum: ");
        Serial.print(code[5], HEX);
        if (code[5] == checksum){
          
          sendToXBee(code, 1);                       // only send through XBEE if checksum is okay
          Serial.println(" -- passed.");
          
        }
        else
          Serial.println(" -- error.");
        
        Serial.println();
      }

      bytesread = 0;
    }
  }
  
  
}


void sendToXBee(byte cardID[], int rfidreaderID){
      // start transmitting after a startup delay.  Note: this will rollover to 0 eventually so not best way to handle
    if (millis() - start > 1000) {
    
      //ID-card ID into payload      
      payload[0] = cardID[0];   
      payload[1] = cardID[1];     
      payload[2] = cardID[2];  
      payload[3] = cardID[3]; 
      payload[4] = cardID[4];
      payload[5] = cardID[5];

      //RFID-Reader ID into payload
      payload[6] = rfidreaderID >> 8 & 0xff;  // payload[0] = MSB;   
      
      xbee.send(tx);

      // flash TX indicator
      //flashLed(statusLed, 2, 100);
    }
  
    // after sending a tx request, we expect a status response
    // wait up to 5 seconds for the status response
    if (xbee.readPacket(5000)) {
        // got a response!

        // should be a znet tx status            	
    	if (xbee.getResponse().getApiId() == TX_STATUS_RESPONSE) {
    	   xbee.getResponse().getZBTxStatusResponse(txStatus);
    		
    	   // get the delivery status, the fifth byte
           if (txStatus.getStatus() == SUCCESS) {
            	// success.  time to celebrate
             	flashLed(statusLed, 5, 50);
           } else {
            	// the remote XBee did not receive our packet. is it powered on?
             	flashLed(errorLed, 3, 500);
           }
        }      
    } else {
      // local XBee did not provide a timely TX Status Response -- should not happen
      flashLed(errorLed, 2, 500);
    }
    
    delay(500);
}
  

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

    
