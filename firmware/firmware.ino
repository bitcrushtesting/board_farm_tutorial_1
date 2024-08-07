/*
* Copyright (c) 2024 Bitcrush Testing
*/

#include <ArduinoJson.h>

// Git version hash (replace with actual hash during build process)
#ifndef VERSION
#define VERSION "0.0.0"
#endif

#ifndef GIT_HASH
#define GIT_HASH "00000000"
#endif

// Define the LED pin and state
const int ledPin = 13;  // Pin connected to the onboard LED
bool ledState = false;  // Current state of the LED

// JSON-RPC objects
StaticJsonDocument<200> doc;
char buffer[256];

void setup() {
  // Initialize the digital pin as an output
  pinMode(ledPin, OUTPUT);

  // Initialize serial communication at 9600 baud rate
  Serial.begin(9600);

  // Wait for serial port to connect (for some boards)
  while (!Serial) {
    ;  // Wait for serial port to connect. Needed for native USB port only
  }
}

void loop() {
  // Blink the LED
  ledState = !ledState;
  digitalWrite(ledPin, ledState ? HIGH : LOW);

  // Wait for a second
  delay(1000);

  // Check for incoming JSON-RPC requests
  while (Serial.available() > 0) {
    String request = Serial.readStringUntil('\n');
    handleJsonRpcRequest(request);
  }
}

void handleJsonRpcRequest(String request) {
  doc.clear();
  DeserializationError error = deserializeJson(doc, request);
  if (error) {
    return;
  }

  // Process JSON-RPC request
  if (doc["jsonrpc"] != "2.0") {
    return;
  } 

  if (doc["method"] == "getVersion") {
    sendVersionResponse(doc["id"]);
  } else if (doc["method"] == "getLedState") {
    sendLedStateResponse(doc["id"]);
  }
}

void sendVersionResponse(JsonVariant id) {
  doc.clear();
  doc["jsonrpc"] = "2.0";
  doc["result"]["version"] = VERSION;
  doc["result"]["gitHash"] = GIT_HASH;
  doc["id"] = id;

  serializeJson(doc, buffer, sizeof(buffer));
  Serial.println(buffer);
}

void sendLedStateResponse(JsonVariant id) {
  doc.clear();
  doc["jsonrpc"] = "2.0";
  doc["result"]["state"] = digitalRead(ledPin) ? "ON" : "OFF";
  doc["id"] = id;

  serializeJson(doc, buffer, sizeof(buffer));
  Serial.println(buffer);
}
