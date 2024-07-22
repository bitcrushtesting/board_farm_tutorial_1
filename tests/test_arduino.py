#!/usr/bin/env python3
# Copyright © 2024 Bitcrush Testing

import argparse
import json
import serial
import subprocess
import sys
import time
import pytest

# Configuration defaults
DEFAULT_BAUD_RATE = 9600
TIMEOUT = 2  # seconds

def parse_args():
    parser = argparse.ArgumentParser(description='Test Arduino JSON-RPC over serial')
    parser.add_argument('--port', required=True, help='Serial port of the Arduino (e.g., /dev/ttyUSB0 or COM3)')
    return parser.parse_args()

def get_git_hash(short=True):

    try:
        # Command to get the Git hash
        cmd = ['git', 'rev-parse', '--short' if short else 'HEAD']
        
        # Execute the command and get the output
        git_hash = subprocess.check_output(cmd).decode('utf-8').strip()
        
        return git_hash
    except subprocess.CalledProcessError as e:
        print("Error retrieving Git hash:", e)
        return None
    except FileNotFoundError:
        print("Git is not installed or not found in the system PATH.")
        return None

def get_latest_git_tag():
    try:
        # Command to get the latest Git tag
        cmd = ['git', 'describe', '--tags', '--abbrev=0']
        
        # Execute the command and get the output
        latest_tag = subprocess.check_output(cmd).decode('utf-8').strip()
        
        return latest_tag
    except subprocess.CalledProcessError as e:
        print("Error retrieving Git tag:", e)
        return None
    except FileNotFoundError:
        print("Git is not installed or not found in the system PATH.")
        return None

@pytest.fixture(scope="module")
def serial_connection(request):
    # Setup the serial connection
    args = parse_args()
    ser = serial.Serial(args.port, DEFAULT_BAUD_RATE, timeout=TIMEOUT)
    time.sleep(2)  # Wait for Arduino to reset
    yield ser
    ser.close()

def send_json_rpc_request(ser, method, params=None, id=1):
    request = {
        "jsonrpc": "2.0",
        "method": method,
        "id": id
    }
    if params:
        request["params"] = params
    ser.write((json.dumps(request) + '\n').encode('utf-8'))

def read_serial_response(ser):
    response = ser.readline().decode('utf-8').strip()
    return json.loads(response)

def test_get_version(serial_connection):
    ser = serial_connection
    send_json_rpc_request(ser, "getVersion")
    response = read_serial_response(ser)
    
    assert response["jsonrpc"] == "2.0"
    assert "result" in response
    assert "version" in response["result"]
    assert "gitHash" in response["result"]
    version = get_latest_git_tag()
    assert response["result"]["version"] == version
    git_hash = get_git_hash()
    assert response["result"]["gitHash"] == git_hash

def test_get_led_state(serial_connection):
    ser = serial_connection
    send_json_rpc_request(ser, "getLedState")
    response = read_serial_response(ser)

    assert response["jsonrpc"] == "2.0"
    assert "result" in response
    assert "state" in response["result"]
    assert response["result"]["state"] in ["ON", "OFF"]

if __name__ == "__main__":
    sys.exit(pytest.main([__file__]))

