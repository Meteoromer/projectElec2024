#include <Adafruit_NeoPixel.h>
// Which pin on the Arduino is connected to the NeoPixels?
#define PIN  4
// How many NeoPixels are attached to the Arduino?
#define NUMPIXELS  24
// When we setup the NeoPixel library, we tell it how many pixels, and which pin to use to send signals.
unsigned long t = millis();
int a = 0; // Timer of detectoin 
int b = 0; // Timer of opening 

Adafruit_NeoPixel strip = Adafruit_NeoPixel(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);
float distance;

int detTime = 20000;
int delayval = 500; // delay for half a second
unsigned long tUn = millis();
unsigned long tDet = millis();
unsigned long tOpen = millis();


int i = 0;

  int red = 255;
  int gre = 0;
  int blue = 0;

void setup() {
  strip.begin(); // This initializes the NeoPixel library.
  strip.clear();
  for(int i = 0; i < NUMPIXELS; i++){
    strip.setPixelColor(i, red, gre, blue);
    strip.show(); 
  }
  strip.show();   // make sure it is visible
   pinMode(3, OUTPUT); 
   pinMode(2, INPUT); 
   Serial.begin(9600); 
  pinMode(5,OUTPUT);
  delay(1000); // Wait for serial communication to stabilize

}

void loop() {
  t = millis();
  
  digitalWrite(3, LOW);
  delayMicroseconds(2);
  digitalWrite(3, HIGH);
  delayMicroseconds(10);
  digitalWrite(3, LOW);
  distance = pulseIn(2, HIGH);
  distance= distance /58;
  Serial.println(distance);
   
  if(a == 1 && t - tDet >= detTime){ // 2 = Stop from to detect // Clear
    red = 255;
    gre = 0;
    blue = 0;
    for(int i = 0; i < NUMPIXELS; i++){
      strip.setPixelColor(i, red, gre, blue);
      strip.show(); 
    }
    a = 0;
  }
  if(b == 1 && t - tDet >= detTime){ // 4 = Closing
      red = 255;
      gre = 0;
      blue = 0;
      for(int i = 0; i < NUMPIXELS; i++){
        strip.setPixelColor(i, red, gre, blue);
        strip.show(); 
      }
      digitalWrite(5,LOW);
      b = 0;
    }
    
  if (Serial.available() > 0) {
    int number = Serial.parseInt();
    Serial.println(number);

    // Read the integer from serial
    if(number%10 == 1){
      number = (int)number/10;
      if(number%10 == 1){ //1 = Tring to detect
        red = 0;
        gre = 0;
        blue = 255;
        for(int i = 0; i < NUMPIXELS; i++){
          strip.setPixelColor(i, red, gre, blue);
          strip.show(); 
        }
        a = 1;
        tDet = millis();
      }

      if(number%10 == 3){ // 3 = open
        red = 0;
        gre = 255;
        blue = 0;
        for(int i = 0; i < NUMPIXELS; i++){
          strip.setPixelColor(i, red, gre, blue);
          strip.show(); 
        }
        b = 1;
        tOpen = millis();
        digitalWrite(5,HIGH);

      }
      if(number%10 == 4){ // 4 = Closing
        red = 255;
        gre = 0;
        blue = 0;
        for(int i = 0; i < NUMPIXELS; i++){
          strip.setPixelColor(i, red, gre, blue);
          strip.show(); 
        }
        digitalWrite(5,LOW);
        b = 0;
      }
    }
  }  
}
