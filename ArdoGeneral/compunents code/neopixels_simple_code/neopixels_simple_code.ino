#include <Adafruit_NeoPixel.h>
// Which pin on the Arduino is connected to the NeoPixels?
#define PIN  4
// How many NeoPixels are attached to the Arduino?
#define NUMPIXELS  24
// When we setup the NeoPixel library, we tell it how many pixels, and which pin to use to send signals.
Adafruit_NeoPixel strip = Adafruit_NeoPixel(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);

int delayval = 500; // delay for half a second

void setup() {
  strip.begin(); // This initializes the NeoPixel library.
  strip.clear();
  strip.show();   // make sure it is visible

}

void loop() {

  // For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  int red = random(0, 10);
  int gre = random(0, 10);
  int blue = random(0, 10);
  for(int i = 0; i < NUMPIXELS; i++){
    // pixels.Color takes GRB values, from 0,0,0 up to 255,255,255 [in the order GRB]
    strip.setPixelColor(i, gre, red, blue);
    strip.show(); 
    // This sends the updated pixel color to the hardware.
    delay(delayval); 
    // Delay for a period of time (in milliseconds).
  }
}
