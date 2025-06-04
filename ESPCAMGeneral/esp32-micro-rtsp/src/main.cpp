#include "OV2640.h"
#include <WiFi.h>
#include <ESPmDNS.h>
#include "OV2640Streamer.h"
#include "CRtspSession.h"
#include "SimStreamer.h"
#include "wifikeys.h"  // Define your ssid and password here

OV2640 cam;
WiFiServer rtspServer(554);
CStreamer *streamer = nullptr;
CRtspSession *session = nullptr;
WiFiClient client;

uint32_t lastImageTime = 0;
uint32_t msecPerFrame = 100;


void setup() {
  Serial.begin(115200);
  //while (!Serial);

  // Initialize camera with AI Thinker configuration
  cam.init(esp32cam_aithinker_config);

  // Connect to WiFi
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected");
  Serial.println(WiFi.localIP());

  if (!MDNS.begin("esp32cam")){
    Serial.println("Error setting up MDNS responder!");
  } 
  else{
    Serial.println("mDNS responder started : esp32cam.local");
  }


  // Start RTSP server
  rtspServer.begin();
}

void loop() {

  if (session) {
    session->handleRequests(0);  // Handle RTSP requests

    uint32_t now = millis();
    if (now > lastImageTime + msecPerFrame || now < lastImageTime) {
      session->broadcastCurrentFrame(now);
      lastImageTime = now;
    }

    if (session->m_stopped) {
      delete session;
      delete streamer;
      session = nullptr;
      streamer = nullptr;
    }
  } else {
    client = rtspServer.accept();
    if (client) {
      streamer = new OV2640Streamer(&client, cam);
      session = new CRtspSession(&client, streamer);
    }
  }
}
