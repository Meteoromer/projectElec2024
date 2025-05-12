#include <SoftwareSerial.h>
#include <Adafruit_NeoPixel.h>
// Which pin on the Arduino is connected to the NeoPixels?
#define PIN  4
// How many NeoPixels are attached to the Arduino?
#define NUMPIXELS  24
// When we setup the NeoPixel library, we tell it how many pixels, and which pin to use to send signals.
Adafruit_NeoPixel strip = Adafruit_NeoPixel(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);

int delayval = 50; // delay for half a second

// Define RX and TX pins
const int rxPin = 9;
const int txPin = 10;
const int pinLock = 5;

float distance;
float TimeDistance;
const int  trigPin = 2;
const int ecoPin = 3;

// Create a SoftwareSerial object
SoftwareSerial mySerial(rxPin, txPin);

void setup() {
  strip.begin(); // This initializes the NeoPixel library.
  strip.clear();
  strip.show();   // make sure it is visible
  int red = 10;
  int gre = 0;
  int blue = 0;
  for(int i = 0; i < NUMPIXELS; i++){
    // pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    strip.setPixelColor(i, gre, red, blue);
    strip.show(); 
    // This sends the updated pixel color to the hardware.
    delay(delayval); 
    // Delay for a period of time (in milliseconds).
  }
  pinMode(pinLock,OUTPUT); // relay on/off. when High - unlock
  
  //ultrasonic trig&eco
  pinMode(trigPin, OUTPUT);
  pinMode(ecoPin, INPUT);

  // Start hardware serial communication for debugging
  Serial.begin(9600);
  while (!Serial);

  // Start software serial communication
  mySerial.begin(9600);
  Serial.println("Full-Duplex UART Communication Initialized.");
}

void loop() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  TimeDistance = pulseIn(ecoPin, HIGH);
  distance = TimeDistance / 58;
  mySerial.println(distance);

  // Check if data is available to read from the software serial
  if (mySerial.available()) {
    
    char incomingByte = mySerial.read();
    Serial.println(incomingByte);
    while(!mySerial.available());// בשביל להתחמק משאריות של ה-אנטר במחסנית של הuart.
    while(mySerial.available()){
      mySerial.read();
    }
    if (incomingByte == '1'){
      digitalWrite(pinLock, HIGH);
      int red = 0;
      int gre = 10;
      int blue = 0;
      for(int i = 0; i < NUMPIXELS; i++){
        // pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
        strip.setPixelColor(i, gre, red, blue);
        strip.show(); 
        // This sends the updated pixel color to the hardware.
        delay(delayval); 
        // Delay for a period of time (in milliseconds).
      }
      
      delay(2000);
      
      red = 10;
      gre = 0;
      blue = 0;
      for(int i = 0; i < NUMPIXELS; i++){
        // pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
        strip.setPixelColor(i, gre, red, blue);
        strip.show(); 
        // This sends the updated pixel color to the hardware.
        delay(delayval); 
        // Delay for a period of time (in milliseconds).
      }
      digitalWrite(pinLock, LOW);
    }

    if (incomingByte == '2'){
      int red = 0;
      int gre = 0;
      int blue = 10;
      for(int i = 0; i < NUMPIXELS; i++){
        // pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
        strip.setPixelColor(i, gre, red, blue);
        strip.show(); 
        // This sends the updated pixel color to the hardware.
 
        // Delay for a period of time (in milliseconds).
        
      }
      
      delay(4000);
      
      red = 10;
      gre = 0;
      blue = 0;
      for(int i = 0; i < NUMPIXELS; i++){
        // pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
        strip.setPixelColor(i, gre, red, blue);
        strip.show(); 
        // This sends the updated pixel color to the hardware.
        // Delay for a period of time (in milliseconds).
      }
    }
    
  }

  // Check if data is available to read from the hardware serial
  if (Serial.available()) {
    char outgoingByte = Serial.read();
    mySerial.print(outgoingByte);
  } 
}
