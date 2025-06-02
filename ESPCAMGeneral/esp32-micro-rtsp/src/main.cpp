#include "OV2640.h"
#include <WiFi.h>
#include <WebServer.h>
#include <WiFiClient.h>

#include "SimStreamer.h"
#include "OV2640Streamer.h"
#include "CRtspSession.h"

#include "wifikeys.h"

OV2640 cam;

WiFiServer rtspServer(8554);

void setup()
{
    Serial.begin(115200);
    while(!Serial);
    cam.init(esp32cam_aithinker_config);
    rtspServer.begin();

    IPAddress ip;

    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED)
    {
        delay(500);
        Serial.print(F("."));
    }
    ip = WiFi.localIP();
    Serial.println(F("WiFi connected"));
    Serial.println("");
    Serial.println(ip);
}

CStreamer *streamer;
CRtspSession *session;
WiFiClient client;

void loop()
{

    uint32_t msecPerFrame = 100;
    static uint32_t lastimage = millis();

    //If we have an active client connection, 
    //just service that until gone
    if(session) {
        session->handleRequests(0); // we don't use a timeout here,
        // instead we send only if we have new enough frames

        uint32_t now = millis();
        // handle clock rollover
        if(now > lastimage + msecPerFrame || now < lastimage) { 
            session->broadcastCurrentFrame(now);
            lastimage = now;

            // check if we are overrunning our max frame rate
            now = millis();
            if(now > lastimage + msecPerFrame)
                printf("warning exceeding max frame rate of %d ms\n", now - lastimage);
        }

        if(session->m_stopped) {
            delete session;
            delete streamer;
            session = NULL;
            streamer = NULL;
        }
    }
    else {
        client = rtspServer.accept();

        if(client) {
            // our streamer for UDP/TCP based RTP transport
            streamer = new OV2640Streamer(&client, cam); 
            // our threads RTSP session and state
            session = new CRtspSession(&client, streamer); 
        }
    }
}