

#define FLASH_LED_PIN 4

void setup() {
  // Initialize the flash LED pin as an output
  pinMode(FLASH_LED_PIN, OUTPUT);
  // Start with the flash off
  digitalWrite(FLASH_LED_PIN, LOW);
}

void loop() {
  // Turn the flash on
  digitalWrite(FLASH_LED_PIN, HIGH);
  delay(1000); 

  digitalWrite(FLASH_LED_PIN, LOW);
  delay(1000); // Keep the flash off for 1 second
}
