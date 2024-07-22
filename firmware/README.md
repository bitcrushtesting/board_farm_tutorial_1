# Blink Test Firmware

This example sketch will blink an LED on the Arduino board and send a message over the serial port. This simple test will allow you to verify that the board is functioning correctly and that the automated testing setup can communicate with the board.

## Explanation

* LED Control: The LED is toggled on and off every second.
* JSON-RPC Notification: A JSON-RPC notification is sent whenever the LED state changes, with the state being either "ON" or "OFF".
* Git Hash: The firmware includes a hard-coded Git hash (replace "abc123" with the actual hash during the build process).
* JSON-RPC Request Handling: The sketch listens for JSON-RPC requests over the serial port. It handles a getVersion method, responding with the firmware version and Git hash.

## Uploading the Firmware

Use the Python script provided earlier to upload this firmware to your Arduino boards as part of the automated testing process. Here’s how you can modify the upload_and_test.py script to check for the correct serial output.
